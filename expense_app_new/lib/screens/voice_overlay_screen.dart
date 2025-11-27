import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_app_new/services/voice_service.dart';
import 'package:expense_app_new/providers/api_provider.dart';
import 'package:expense_app_new/providers/auth_provider.dart';
import 'package:expense_app_new/providers/database_provider.dart';
import 'package:expense_app_new/models/expense_model.dart';
import 'package:expense_app_new/database/database.dart';
import 'package:expense_app_new/services/gamification_service.dart';
import 'package:drift/drift.dart' as drift;

class VoiceOverlayScreen extends ConsumerStatefulWidget {
  const VoiceOverlayScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<VoiceOverlayScreen> createState() => _VoiceOverlayScreenState();
}

class _VoiceOverlayScreenState extends ConsumerState<VoiceOverlayScreen> with SingleTickerProviderStateMixin {
  String _status = 'Tap to Speak';
  String _recognizedText = '';
  bool _isProcessing = false;
  bool _continuousMode = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    
    // Auto-start listening
    WidgetsBinding.instance.addPostFrameCallback((_) => _startListening());
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _startListening() async {
    setState(() {
      _status = 'Listening...';
      _recognizedText = '';
    });

    final voiceService = ref.read(voiceServiceProvider);
    await voiceService.startListening(
      onResult: (text) {
        setState(() => _recognizedText = text);
        _processCommand(text);
      },
      onStatus: (status) {
        // Map internal status to user-friendly messages
        String displayStatus = status;
        if (status == 'notListening') displayStatus = 'Tap to Speak';
        if (status == 'done') displayStatus = 'Processing...';
        
        if (mounted) setState(() => _status = displayStatus);
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _status = error == 'error_no_match' ? 'Didn\'t catch that' : 'Error: $error';
            _isProcessing = false;
          });
          
          // Auto-restart if it was just a no-match and we are in continuous mode
          if (error == 'error_no_match' && _continuousMode) {
             Future.delayed(const Duration(seconds: 2), () {
               if (mounted) _startListening();
             });
          }
        }
      },
    );
  }

  Future<void> _processCommand(String text) async {
    setState(() {
      _status = 'Processing...';
      _isProcessing = true;
    });

    try {
      final user = ref.read(currentUserProvider);
      final db = ref.read(databaseProvider);
      
      // Get context
      final expenses = await db.getRecentExpenses(user!.id, 50);
      final expenseModels = expenses.map((e) => ExpenseModel(
        id: e.id,
        title: e.title,
        amount: e.amount,
        category: 'Category ${e.categoryId}',
        notes: e.notes,
        date: e.date,
        createdAt: e.createdAt,
      )).toList();

      final categoriesAsync = await ref.read(userCategoriesProvider(user.id).future);
      final categoryNames = categoriesAsync.map((c) => c.name).toList();

      // Call AI
      final response = await ref.read(apiServiceProvider).addExpenseWithAI(
        naturalLanguageInput: text,
        recentExpenses: expenseModels,
        availableCategories: categoryNames,
      );

      if (response.expenseData != null) {
        final expenseData = response.expenseData!;
        
        // Find category
        final category = categoriesAsync.firstWhere(
          (c) => c.name.toLowerCase() == expenseData.category.toLowerCase(),
          orElse: () => categoriesAsync.first,
        );

        // Fix date
        final finalDate = DateTime.parse(expenseData.date).year < DateTime.now().year 
            ? DateTime.now().toIso8601String() 
            : expenseData.date;

        // Save
        await db.into(db.expenses).insert(ExpensesCompanion(
          userId: drift.Value(user.id),
          title: drift.Value(expenseData.title),
          amount: drift.Value(expenseData.amount),
          categoryId: drift.Value(category.id),
          date: drift.Value(finalDate),
          notes: drift.Value(expenseData.notes),
          createdAt: drift.Value(DateTime.now().toIso8601String()),
        ));

        // Gamification
        final gamificationService = ref.read(gamificationServiceProvider);
        await gamificationService.checkExpenseAchievements(user.id);
        await gamificationService.calculateWellnessScore(user.id);

        // Refresh providers
        ref.invalidate(userExpensesProvider);
        ref.invalidate(currentMonthTotalProvider);
        ref.invalidate(recentExpensesProvider);

        if (mounted) {
          setState(() {
            _status = 'Success!';
            _isProcessing = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Added: ${expenseData.title} - ₹${expenseData.amount}')),
          );

          if (!_continuousMode) {
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) context.pop();
            });
          } else {
            // Restart listening for continuous mode
            Future.delayed(const Duration(seconds: 1), () {
              if (mounted) _startListening();
            });
          }
        }
      } else {
        throw Exception('AI could not understand the expense');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = 'Error: Try again';
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isListening = _status == 'Listening...';
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.8),
      body: SafeArea(
        child: Stack(
          children: [
            // Close Button
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
                onPressed: () => context.pop(),
              ),
            ),

            // Continuous Mode Toggle
            Positioned(
              top: 16,
              left: 16,
              child: Row(
                children: [
                  Switch(
                    value: _continuousMode,
                    onChanged: (val) => setState(() => _continuousMode = val),
                    activeColor: colorScheme.primary,
                  ),
                  const Text(
                    'Continuous Mode',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),

            // Main Content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Status Text
                  Text(
                    _status,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Recognized Text
                  if (_recognizedText.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        '"$_recognizedText"',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 18,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 48),

                  // Mic Button
                  GestureDetector(
                    onTap: _isProcessing ? null : _startListening,
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isListening 
                                ? Colors.red.withOpacity(0.8) 
                                : colorScheme.primary,
                            boxShadow: [
                              BoxShadow(
                                color: (isListening ? Colors.red : colorScheme.primary)
                                    .withOpacity(0.5 * _pulseController.value),
                                blurRadius: 20 + (20 * _pulseController.value),
                                spreadRadius: 10 * _pulseController.value,
                              ),
                            ],
                          ),
                          child: Icon(
                            isListening ? Icons.mic : Icons.mic_none,
                            color: Colors.white,
                            size: 48,
                          ),
                        );
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  if (_isProcessing)
                    const CircularProgressIndicator(color: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
