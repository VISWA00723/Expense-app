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
import 'package:expense_app_new/services/api_service.dart' show ExpenseData;
import 'package:intl/intl.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:expense_app_new/services/gamification_service.dart';
import 'package:expense_app_new/widgets/app_bottom_bar.dart';
import 'package:expense_app_new/providers/receipt_provider.dart';

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
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialMessage != null) {
        _sendMessage(overrideText: widget.initialMessage);
      } else {
        // Check secure provider for receipt data
        final secureText = ref.read(receiptTextProvider);
        if (secureText != null) {
          _sendMessage(overrideText: secureText);
          // Clear the provider immediately to prevent persistence
          ref.read(receiptTextProvider.notifier).state = null;
        }
      }
    });
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

  ExpenseData? _pendingExpense;

  Future<void> _confirmExpense() async {
    if (_pendingExpense == null) return;

    setState(() => _isLoading = true);
    final db = ref.read(databaseProvider);
    final user = ref.read(currentUserProvider);

    try {
      if (user == null) throw Exception('User not found');

      // Get categories to find the ID
      final categoriesAsync = await ref.read(userCategoriesProvider(user.id).future);
      final categories = categoriesAsync;
      
      final category = categories.firstWhere(
        (c) => c.name.toLowerCase() == _pendingExpense!.category.toLowerCase(),
        orElse: () => categories.first,
      );

      // Nuanced Date Validation
      String finalDate;
      try {
        final parsedDate = DateTime.parse(_pendingExpense!.date);
        final now = DateTime.now();
        final minDate = now.subtract(const Duration(days: 365));
        final maxDate = now.add(const Duration(days: 3));

        if (parsedDate.isAfter(minDate) && parsedDate.isBefore(maxDate)) {
          finalDate = _pendingExpense!.date;
        } else {
          finalDate = now.toIso8601String();
        }
      } catch (e) {
        finalDate = DateTime.now().toIso8601String();
      }

      // Create expense in database
      await db.into(db.expenses).insert(ExpensesCompanion(
        userId: drift.Value(user.id),
        title: drift.Value(_pendingExpense!.title),
        amount: drift.Value(_pendingExpense!.amount),
        categoryId: drift.Value(category.id),
        date: drift.Value(finalDate),
        notes: drift.Value(_pendingExpense!.notes),
        createdAt: drift.Value(DateTime.now().toIso8601String()),
      ));

      // Update gamification
      final gamificationService = ref.read(gamificationServiceProvider);
      await gamificationService.checkExpenseAchievements(user.id);
      await gamificationService.calculateWellnessScore(user.id);
      
      // Invalidate providers
      ref.invalidate(userExpensesProvider);
      ref.invalidate(currentMonthTotalProvider);
      ref.invalidate(recentExpensesProvider);
      ref.invalidate(spendingByCategoryProvider);
      
      // Add success message
      await db.addChatMessage(AiChatMessagesCompanion(
        sessionId: drift.Value(_currentSessionId!),
        isUser: const drift.Value(false),
        content: drift.Value('✅ Expense added successfully!'),
        createdAt: drift.Value(DateTime.now().toIso8601String()),
      ));

      setState(() {
        _pendingExpense = null;
        _isLoading = false;
      });

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding expense: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  void _cancelExpense() {
    setState(() {
      _pendingExpense = null;
    });
    // Optional: Add a system message saying cancelled
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

      // Get context
      final expenses = await db.getRecentExpenses(user.id, 300);
      final expenseModels = expenses.map((e) => ExpenseModel(
        id: e.id,
        title: e.title,
        amount: e.amount,
        category: 'Category ${e.categoryId}',
        notes: e.notes,
        date: e.date,
        createdAt: e.createdAt,
      )).toList();

      // Check intent
      final lowerText = text.toLowerCase();
      final isAddIntent = lowerText.contains('add expense') ||
          lowerText.contains('add expens') ||
          (lowerText.contains('add') && RegExp(r'\d+').hasMatch(text)) ||
          lowerText.startsWith('analyze receipt:');

      api.AIResponse response;
      
      if (isAddIntent) {
        final categoriesAsync = await ref.read(userCategoriesProvider(user.id).future);
        final categories = categoriesAsync;
        final categoryNames = categories.map((c) => c.name).toList();
        
        response = await ref.read(apiServiceProvider).addExpenseWithAI(
          naturalLanguageInput: text,
          recentExpenses: expenseModels,
          availableCategories: categoryNames,
        );
        
        if (response.expenseData != null) {
          // Instead of saving, set pending expense
          setState(() {
            _pendingExpense = response.expenseData;
          });
          
          // Add bot message asking for confirmation
          await db.addChatMessage(AiChatMessagesCompanion(
            sessionId: drift.Value(_currentSessionId!),
            isUser: const drift.Value(false),
            content: drift.Value('I found the following expense details. Please confirm to add it:\n\n${response.answer}'),
            createdAt: drift.Value(DateTime.now().toIso8601String()),
          ));
          
          setState(() => _isLoading = false);
          return;
        }
      } else {
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
      if (_currentSessionId != null) {
        final db = ref.read(databaseProvider);
        await db.addChatMessage(AiChatMessagesCompanion(
          sessionId: drift.Value(_currentSessionId!),
          isUser: const drift.Value(false),
          content: drift.Value('Error: $e'),
          createdAt: drift.Value(DateTime.now().toIso8601String()),
        ));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
      onPopInvokedWithResult: (didPop, result) {
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

          // Confirmation Card
          if (_pendingExpense != null)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).colorScheme.primary),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Confirm Expense Details',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Title:', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      Text(_pendingExpense!.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Amount:', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      Text('₹${_pendingExpense!.amount.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Category:', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      Text(_pendingExpense!.category, style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _cancelExpense,
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: _confirmExpense,
                          child: const Text('Confirm & Add'),
                        ),
                      ),
                    ],
                  ),
                ],
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
                    enabled: _pendingExpense == null, // Disable input while confirming
                    decoration: InputDecoration(
                      hintText: _pendingExpense != null ? 'Please confirm expense above...' : 'Ask your financial coach...',
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
                  onPressed: (_isLoading || _pendingExpense != null) ? null : () => _sendMessage(),
                  elevation: 0,
                  backgroundColor: (_isLoading || _pendingExpense != null) ? Colors.grey : null,
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
