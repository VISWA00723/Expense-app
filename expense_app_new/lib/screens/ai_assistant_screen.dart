import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' as drift;
import 'package:expense_app_new/providers/database_provider.dart';
import 'package:expense_app_new/providers/api_provider.dart';
import 'package:expense_app_new/providers/auth_provider.dart';
import 'package:expense_app_new/models/expense_model.dart';
import 'package:expense_app_new/database/database.dart';

class AIAssistantScreen extends ConsumerStatefulWidget {
  const AIAssistantScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends ConsumerState<AIAssistantScreen> {
  late TextEditingController _questionController;
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _questionController = TextEditingController();
  }

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  void _sendQuestion() async {
    if (_questionController.text.isEmpty) return;

    final question = _questionController.text;
    _questionController.clear();

    // Add user message
    setState(() {
      _messages.add(ChatMessage(
        text: question,
        isUser: true,
      ));
      _isLoading = true;
    });

    try {
      // Get last 300 expenses for context
      final db = ref.read(databaseProvider);
      final user = ref.read(currentUserProvider);
      final expenses = await db.getRecentExpenses(user!.id, 300);

      // Convert to ExpenseModel
      final expenseModels = expenses
          .map((e) => ExpenseModel(
                id: e.id,
                title: e.title,
                amount: e.amount,
                category: 'Category ${e.categoryId}',
                notes: e.notes,
                date: e.date,
                createdAt: e.createdAt,
              ))
          .toList();

      // Check if user wants to add an expense (natural language detection)
      final isAddExpenseRequest = _isAddExpenseRequest(question);

      if (isAddExpenseRequest) {
        // Get available categories
        final categories = await db.getUserCategories(user.id);
        final categoryNames = categories.map((c) => c.name).toList();

        // Use AI to parse the natural language input
        final response = await ref.read(apiServiceProvider).addExpenseWithAI(
          naturalLanguageInput: question,
          recentExpenses: expenseModels,
          availableCategories: categoryNames,
        );

        // If expense data was parsed, add it to database
        if (response.expenseData != null) {
          final expenseData = response.expenseData!;
          
          // Find category ID by name
          final category = categories.firstWhere(
            (c) => c.name.toLowerCase() == expenseData.category.toLowerCase(),
            orElse: () => categories.first,
          );

          // Add expense to database
          await db.insertExpense(
            ExpensesCompanion(
              userId: drift.Value(user.id),
              title: drift.Value(expenseData.title),
              amount: drift.Value(expenseData.amount),
              categoryId: drift.Value(category.id),
              notes: expenseData.notes != null ? drift.Value(expenseData.notes) : drift.Value(null),
              date: drift.Value(expenseData.date),
              createdAt: drift.Value(DateTime.now().toIso8601String()),
            ),
          );

          // Invalidate providers to refresh dashboard
          ref.invalidate(spendingByCategoryProvider);
          ref.invalidate(currentMonthTotalProvider);
          ref.invalidate(recentExpensesProvider);

          setState(() {
            _messages.add(ChatMessage(
              text: '✅ ${response.answer}\n\nExpense added: ${expenseData.title} - ₹${expenseData.amount} in ${expenseData.category}',
              isUser: false,
            ));
            _isLoading = false;
          });
        } else {
          setState(() {
            _messages.add(ChatMessage(
              text: response.answer,
              isUser: false,
            ));
            _isLoading = false;
          });
        }
      } else {
        // Regular analysis or chat
        final response = await ref.read(apiServiceProvider).analyzeExpenses(
          question: question,
          expenses: expenseModels,
        );

        setState(() {
          _messages.add(ChatMessage(
            text: response.answer,
            isUser: false,
          ));
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        String errorMessage = 'Error processing your request';
        if (e.toString().contains('Connection refused') ||
            e.toString().contains('Failed host lookup') ||
            e.toString().contains('Connection errored')) {
          errorMessage =
              'Backend server not connected. Please ensure the backend is running.';
        }
        _messages.add(ChatMessage(
          text: errorMessage,
          isUser: false,
        ));
        _isLoading = false;
      });
    }
  }

  // Detect if user wants to add an expense
  bool _isAddExpenseRequest(String input) {
    final lowerInput = input.toLowerCase();
    return lowerInput.contains('add') ||
        lowerInput.contains('spent') ||
        lowerInput.contains('expense') ||
        lowerInput.contains('paid') ||
        lowerInput.contains('cost') ||
        lowerInput.contains('₹') ||
        (lowerInput.contains('rupees') || lowerInput.contains('rs'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Assistant'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Chat Messages
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.smart_toy_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        const Text('Ask me about your expenses!'),
                        const SizedBox(height: 8),
                        const Text(
                          'Note: Backend required for AI features',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[_messages.length - 1 - index];
                      return ChatBubble(message: message);
                    },
                  ),
          ),

          // Input Area with padding for bottom nav
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _questionController,
                    decoration: InputDecoration(
                      hintText: 'Ask anything or about your expenses...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    enabled: !_isLoading,
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: _isLoading ? null : _sendQuestion,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle),
            label: 'Add',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Expenses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.smart_toy),
            label: 'AI',
          ),
        ],
        currentIndex: 3,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Theme.of(context).colorScheme.surface,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/dashboard');
              break;
            case 1:
              context.go('/add');
              break;
            case 2:
              context.go('/list');
              break;
            case 3:
              context.go('/ai');
              break;
          }
        },
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({
    required this.text,
    required this.isUser,
  });
}

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: message.isUser ? Colors.blue : Colors.grey[300],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: message.isUser ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}
