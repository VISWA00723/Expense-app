import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' as drift;
import 'package:expense_app_new/providers/database_provider.dart';
import 'package:expense_app_new/providers/api_provider.dart';
import 'package:expense_app_new/providers/auth_provider.dart';
import 'package:expense_app_new/models/expense_model.dart';
import 'package:expense_app_new/database/database.dart';
import 'package:expense_app_new/theme/app_theme.dart';
import 'package:expense_app_new/services/api_service.dart' as api;
import 'package:intl/intl.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:expense_app_new/services/gamification_service.dart';
import 'package:expense_app_new/widgets/app_bottom_bar.dart';

class AIAssistantScreen extends ConsumerStatefulWidget {
  final String? initialMessage;
  const AIAssistantScreen({Key? key, this.initialMessage}) : super(key: key);

  @override
  ConsumerState<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends ConsumerState<AIAssistantScreen> {
  late TextEditingController _questionController;
  int? _currentSessionId;
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _questionController = TextEditingController();
    
    if (widget.initialMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sendMessage(overrideText: widget.initialMessage);
      });
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _createNewSession(User user, [String title = 'New Chat']) async {
    final db = ref.read(databaseProvider);
    
    final id = await db.createChatSession(AiChatSessionsCompanion(
      userId: drift.Value(user.id),
      title: drift.Value(title),
      createdAt: drift.Value(DateTime.now().toIso8601String()),
    ));
    
    setState(() {
      _currentSessionId = id;
    });
  }

  Future<void> _sendMessage({String? overrideText}) async {
    try {
      final text = overrideText ?? _questionController.text.trim();
      if (text.isEmpty) return;

      _questionController.clear();
      setState(() => _isLoading = true);

      final db = ref.read(databaseProvider);
      final user = ref.read(currentUserProvider);

      if (user == null) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: User session not found. Please try again.')),
        );
        return;
      }

      // Create session if needed
      if (_currentSessionId == null) {
        await _createNewSession(user, text.length > 20 ? '${text.substring(0, 20)}...' : text);
      }

      // Save user message
      await db.addChatMessage(AiChatMessagesCompanion(
        sessionId: drift.Value(_currentSessionId!),
        isUser: const drift.Value(true),
        content: drift.Value(text),
        createdAt: drift.Value(DateTime.now().toIso8601String()),
      ));

      // Get context (expenses and categories)
      final expenses = await db.getRecentExpenses(user.id, 300);
      final expenseModels = expenses.map((e) => ExpenseModel(
        id: e.id,
        title: e.title,
        amount: e.amount,
        category: 'Category ${e.categoryId}', // Placeholder, ideally join with categories
        notes: e.notes,
        date: e.date,
        createdAt: e.createdAt,
      )).toList();

      // Check if user wants to add an expense
      final lowerText = text.toLowerCase();
      final isAddIntent = lowerText.contains('add expense') ||
          lowerText.contains('add expens') ||
          (lowerText.contains('add') && RegExp(r'\d+').hasMatch(text)) ||
          lowerText.startsWith('analyze receipt:');

      api.AIResponse response;
      
      if (isAddIntent) {
        // Get categories for AI to choose from
        final categoriesAsync = await ref.read(userCategoriesProvider(user.id).future);
        final categories = categoriesAsync;
        
        if (categories.isEmpty) {
          throw Exception('No categories available');
        }
        
        final categoryNames = categories.map((c) => c.name).toList();
        
        // Call add-expense endpoint
        response = await ref.read(apiServiceProvider).addExpenseWithAI(
          naturalLanguageInput: text,
          recentExpenses: expenseModels,
          availableCategories: categoryNames,
        );
        
        // If AI returned expense data, create the expense
        if (response.expenseData != null) {
          final expenseData = response.expenseData!;
          
          // Find matching category
          final category = categories.firstWhere(
            (c) => c.name.toLowerCase() == expenseData.category.toLowerCase(),
            orElse: () => categories.first,
          );
          
          // Fix: If AI returns a date from a previous year (likely hallucinated/default), use today
          final finalDate = DateTime.parse(expenseData.date).year < DateTime.now().year 
              ? DateTime.now().toIso8601String() 
              : expenseData.date;

          // Create expense in database
          print('Creating expense with date: $finalDate (Original: ${expenseData.date})');
          await db.into(db.expenses).insert(ExpensesCompanion(
            userId: drift.Value(user.id),
            title: drift.Value(expenseData.title),
            amount: drift.Value(expenseData.amount),
            categoryId: drift.Value(category.id),
            date: drift.Value(finalDate),
            notes: drift.Value(expenseData.notes),
            createdAt: drift.Value(DateTime.now().toIso8601String()),
          ));

          // Check achievements and update wellness score
          print('Updating gamification...');
          final gamificationService = ref.read(gamificationServiceProvider);
          await gamificationService.checkExpenseAchievements(user.id);
          await gamificationService.calculateWellnessScore(user.id);
          print('Gamification updated.');
          
          // Invalidate dashboard providers to refresh data
          ref.invalidate(userExpensesProvider);
          ref.invalidate(currentMonthTotalProvider);
          ref.invalidate(recentExpensesProvider);
          ref.invalidate(spendingByCategoryProvider);
          
          // Add success confirmation
          await db.addChatMessage(AiChatMessagesCompanion(
            sessionId: drift.Value(_currentSessionId!),
            isUser: const drift.Value(false),
            content: drift.Value('✅ Expense added successfully!\n\n${response.answer}'),
            createdAt: drift.Value(DateTime.now().toIso8601String()),
          ));
          
          setState(() => _isLoading = false);
          if (_scrollController.hasClients) {
            _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
          }
          return; // Exit early, we've handled the message
        }
      } else {
        // Regular analysis
        response = await ref.read(apiServiceProvider).analyzeExpenses(
          question: text,
          expenses: expenseModels,
        );
      }

      // Save AI response
      await db.addChatMessage(AiChatMessagesCompanion(
        sessionId: drift.Value(_currentSessionId!),
        isUser: const drift.Value(false),
        content: drift.Value(response.answer),
        createdAt: drift.Value(DateTime.now().toIso8601String()),
      ));

    } catch (e, stackTrace) {
      print('Error in _sendMessage: $e');
      print(stackTrace);
      
      // Try to save error message to chat if session exists
      if (_currentSessionId != null) {
        final db = ref.read(databaseProvider);
        await db.addChatMessage(AiChatMessagesCompanion(
          sessionId: drift.Value(_currentSessionId!),
          isUser: const drift.Value(false),
          content: drift.Value('Error: $e'),
          createdAt: drift.Value(DateTime.now().toIso8601String()),
        ));
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        // Scroll to bottom
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      }
    }
  }

  Future<void> _generateInvestmentPlan() async {
    final user = ref.read(currentUserProvider);
    final db = ref.read(databaseProvider);
    
    // Calculate stats
    final income = user!.monthlySalary;
    final expenses = await db.watchTotalByMonth(user.id, DateFormat('yyyy-MM').format(DateTime.now())).first;
    final savings = income - expenses;
    
    final prompt = "I have a monthly income of ₹$income and average expenses of ₹${expenses.toStringAsFixed(0)}. "
        "I have ₹${savings.toStringAsFixed(0)} available for savings/investment. "
        "Please provide a detailed investment plan including asset allocation (Stocks, Mutual Funds, Gold, FD) "
        "and risk assessment. Format it as a clear guide.";

    await _sendMessage(overrideText: prompt);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const Center(child: CircularProgressIndicator());

    final sessionsAsync = ref.watch(chatSessionsProvider(user.id));
    final messagesAsync = _currentSessionId != null 
        ? ref.watch(chatMessagesProvider(_currentSessionId!))
        : const AsyncValue.data(<AiChatMessage>[]);

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        context.go('/dashboard');
      },
      child: Scaffold(
      appBar: AppBar(
        title: const Text('AI Financial Coach'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _createNewSession(user),
            tooltip: 'New Chat',
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(user.name),
              accountEmail: Text(user.email),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(user.name[0], style: const TextStyle(fontSize: 24)),
              ),
            ),
            Expanded(
              child: sessionsAsync.when(
                data: (sessions) => ListView.builder(
                  itemCount: sessions.length,
                  itemBuilder: (context, index) {
                    final session = sessions[index];
                    return ListTile(
                      leading: const Icon(Icons.chat_bubble_outline),
                      title: Text(session.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                        DateFormat('MMM d, h:mm a').format(DateTime.parse(session.createdAt)),
                        style: const TextStyle(fontSize: 12),
                      ),
                      selected: session.id == _currentSessionId,
                      onTap: () {
                        setState(() => _currentSessionId = session.id);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Quick Actions
          if (_currentSessionId == null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Wrap(
                spacing: 8,
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.trending_up),
                    label: const Text('Generate Investment Plan'),
                    onPressed: _generateInvestmentPlan,
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.pie_chart),
                    label: const Text('Analyze Spending'),
                    onPressed: () => _sendMessage(overrideText: "Analyze my spending patterns for this month"),
                  ),
                ],
              ),
            ),

          // Chat Messages
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty && _currentSessionId == null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.psychology,
                          size: 64,
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        const Text('Start a conversation with your AI Coach'),
                      ],
                    ),
                  );
                }
                
                // Reverse list for chat view
                final reversedMessages = messages.reversed.toList();
                
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemCount: reversedMessages.length,
                  itemBuilder: (context, index) {
                    final message = reversedMessages[index];
                    return ChatBubble(
                      text: message.content,
                      isUser: message.isUser,
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error: $e')),
            ),
          ),

          // Input Area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _questionController,
                    decoration: InputDecoration(
                      hintText: 'Ask your financial coach...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _isLoading ? null : _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: _isLoading ? null : () => _sendMessage(),
                  elevation: 0,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomBar(currentIndex: 3),
      ),
    );
  }
}

class ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;

  const ChatBubble({Key? key, required this.text, required this.isUser}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 20),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: isUser 
          ? Text(
              text,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.white,
              ),
            )
          : MarkdownBody(
              data: text,
              styleSheet: MarkdownStyleSheet(
                p: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
                strong: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
      ),
    );
  }
}
