import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:expense_app_new/services/receipt_scanning_service.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' as drift;
import 'package:expense_app_new/database/database.dart';
import 'package:expense_app_new/providers/auth_provider.dart';
import 'package:expense_app_new/providers/database_provider.dart';
import 'package:expense_app_new/providers/api_provider.dart';
import 'package:expense_app_new/services/gamification_service.dart';
import 'package:expense_app_new/services/recurring_expense_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:expense_app_new/widgets/app_bottom_bar.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _notesController;
  int? _selectedCategoryId;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  bool _isRecurring = false;
  String _recurringFrequency = 'monthly';
  bool _autoPay = false;
  String _selectedCurrency = 'INR';
  final _receiptScanningService = ReceiptScanningService();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _amountController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    _receiptScanningService.dispose();
    super.dispose();
  }



  Future<File?> _pickReceiptImage() async {
    // Request permissions first
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.storage,
      Permission.photos, // For Android 13+
    ].request();

    // Check if any permission is granted (we need at least one source)
    final cameraGranted = statuses[Permission.camera]?.isGranted ?? false;
    final storageGranted = (statuses[Permission.storage]?.isGranted ?? false) || 
                          (statuses[Permission.photos]?.isGranted ?? false);

    if (!cameraGranted && !storageGranted) {
      if (!mounted) return null;
      
      // Show dialog to explain why permissions are needed
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Permissions Required'),
          content: const Text(
            'Camera or Gallery permission is needed to scan receipts. '
            'Please enable them in app settings.'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );
      return null;
    }

    final picker = ImagePicker();
    
    // Show modal bottom sheet to choose between Camera and Gallery
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
              enabled: cameraGranted,
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
              enabled: storageGranted,
            ),
          ],
        ),
      ),
    );

    if (source == null) return null;

    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }

  Future<void> _scanReceipt() async {
    try {
      final imageFile = await _pickReceiptImage();
      if (imageFile == null) return;

      setState(() => _isLoading = true);
      
      final receiptData = await _receiptScanningService.scanReceipt(imageFile);
      
      setState(() {
        if (receiptData.merchant != null) {
          _titleController.text = receiptData.merchant!;
        }
        if (receiptData.amount != null) {
          _amountController.text = receiptData.amount!.toStringAsFixed(2);
        }
        if (receiptData.date != null) {
          _selectedDate = receiptData.date!;
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Receipt scanned successfully!')),
        );
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error scanning receipt: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _scanReceiptWithAI() async {
    try {
      final imageFile = await _pickReceiptImage();
      if (imageFile == null) return;

      setState(() => _isLoading = true);
      
      // Stage 1: Get raw text and clean it
      final receiptData = await _receiptScanningService.scanReceipt(imageFile);
      final cleanedText = _receiptScanningService.cleanRawText(receiptData.rawText);
      
      if (!mounted) return;
      
      // Navigate to AI Assistant with the cleaned text prefixed for robust processing
      context.push('/ai', extra: 'Analyze Receipt:\n$cleanedText');
      
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error processing receipt: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _saveExpense() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategoryId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a category')),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        final user = ref.read(currentUserProvider);
        final db = ref.read(databaseProvider);
        final now = DateTime.now();

        // Auto-generate title if empty
        String finalTitle = _titleController.text.trim();
        if (finalTitle.isEmpty) {
          // Get category name for auto-generated title
          final categories = await db.getUserCategories(user!.id);
          final selectedCategory = categories.firstWhere(
            (cat) => cat.id == _selectedCategoryId,
            orElse: () => categories.first,
          );
          finalTitle = '${selectedCategory.name} expense';
        }

        final expense = ExpensesCompanion(
          userId: drift.Value(user!.id),
          title: drift.Value(finalTitle),
          amount: drift.Value(double.parse(_amountController.text)),
          categoryId: drift.Value(_selectedCategoryId!),
          notes: drift.Value(
            _notesController.text.isEmpty ? null : _notesController.text,
          ),
          date: drift.Value(DateFormat('yyyy-MM-dd').format(_selectedDate)),
          createdAt: drift.Value(DateFormat('yyyy-MM-dd HH:mm:ss').format(now)),
          currencyCode: drift.Value(_selectedCurrency),
        );

        await db.insertExpense(expense);

        if (_isRecurring) {
          final recurringService = ref.read(recurringExpenseServiceProvider);
          // Calculate next due date based on frequency
          DateTime nextDate = _selectedDate;
          switch (_recurringFrequency) {
            case 'daily': nextDate = nextDate.add(const Duration(days: 1)); break;
            case 'weekly': nextDate = nextDate.add(const Duration(days: 7)); break;
            case 'monthly': nextDate = DateTime(nextDate.year, nextDate.month + 1, nextDate.day); break;
            case 'yearly': nextDate = DateTime(nextDate.year + 1, nextDate.month, nextDate.day); break;
          }

          await recurringService.addRecurringExpense(
            userId: user.id,
            name: finalTitle,
            amount: double.parse(_amountController.text),
            categoryId: _selectedCategoryId!,
            frequency: _recurringFrequency,
            nextDueDate: nextDate,
            autoPay: _autoPay,
          );
        }

        // Check achievements and update wellness score
        final gamificationService = ref.read(gamificationServiceProvider);
        await gamificationService.checkExpenseAchievements(user.id);
        await gamificationService.calculateWellnessScore(user.id);

        // Invalidate dashboard providers to refresh data
        ref.invalidate(userExpensesProvider);
        ref.invalidate(currentMonthTotalProvider);
        ref.invalidate(recentExpensesProvider);
        ref.invalidate(spendingByCategoryProvider);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Expense added successfully')),
        );
        context.go('/dashboard');
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final userId = user?.id;

    if (userId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Check if profile setup is complete
    if (user!.monthlySalary == 0) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.info_outline, size: 64),
              const SizedBox(height: 16),
              const Text('Profile Setup Required'),
              const SizedBox(height: 8),
              const Text('Please complete your profile setup first'),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go('/profile-setup'),
                child: const Text('Go to Profile Setup'),
              ),
            ],
          ),
        ),
      );
    }

    final categories = ref.watch(userCategoriesProvider(userId));
    final colorScheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.go('/dashboard');
      },
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Add Expense'),
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.document_scanner),
            tooltip: 'Scan Options',
            enabled: !_isLoading,
            onSelected: (value) {
              if (_isLoading) return;
              if (value == 'scan') {
                _scanReceipt();
              } else if (value == 'ai') {
                _scanReceiptWithAI();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'scan',
                child: ListTile(
                  leading: Icon(Icons.qr_code_scanner),
                  title: Text('Standard Scan'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem<String>(
                value: 'ai',
                child: ListTile(
                  leading: Icon(Icons.psychology),
                  title: Text('Scan & Ask AI'),
                  subtitle: Text('Best for complex receipts'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Field
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Expense Title (Optional)',
                  hintText: 'e.g., Lunch at restaurant',
                  prefixIcon: const Icon(Icons.description_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Amount Field with Currency
              Row(
                children: [
                  Container(
                    width: 125,
                    margin: const EdgeInsets.only(right: 8),
                    child: DropdownButtonFormField<String>(
                      value: _selectedCurrency,
                      decoration: InputDecoration(
                        labelText: 'Currency',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'INR', child: Text('INR (₹)')),
                        DropdownMenuItem(value: 'USD', child: Text('USD (\$)')),
                        DropdownMenuItem(value: 'EUR', child: Text('EUR (€)')),
                        DropdownMenuItem(value: 'GBP', child: Text('GBP (£)')),
                      ],
                      onChanged: (val) => setState(() => _selectedCurrency = val!),
                    ),
                  ),
                  Expanded(
                    child: TextFormField(
                      controller: _amountController,
                      decoration: InputDecoration(
                        labelText: 'Amount',
                        hintText: '0.00',
                        prefixIcon: const Icon(Icons.attach_money),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Please enter amount';
                        }
                        if (double.tryParse(value!) == null) {
                          return 'Please enter valid amount';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Category Selection
              Text(
                'Category',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 12),
              categories.when(
                data: (cats) {
                  if (cats.isEmpty) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Icon(Icons.info_outline, size: 32),
                            const SizedBox(height: 8),
                            Text(
                              'No categories available',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Please complete profile setup first',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: cats.map((category) {
                      final isSelected = _selectedCategoryId == category.id;
                      return FilterChip(
                        label: Text('${category.icon} ${category.name}'),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategoryId =
                                selected ? category.id : null;
                          });
                        },
                        backgroundColor: Colors.transparent,
                        selectedColor: colorScheme.primary.withOpacity(0.2),
                        side: BorderSide(
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.outline,
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 12),
                      Text(
                        'Loading categories...',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                error: (err, stack) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(height: 8),
                        Text('Error loading categories: $err'),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Date Selection
              Text(
                'Date',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.calendar_today_outlined),
                  title: Text(
                    DateFormat('MMM dd, yyyy').format(_selectedDate),
                  ),
                  trailing: const Icon(Icons.edit_outlined),
                  onTap: () => _selectDate(context),
                ),
              ),
              const SizedBox(height: 16),

              // Notes Field
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: 'Notes (Optional)',
                  hintText: 'Add any notes...',
                  prefixIcon: const Icon(Icons.note_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Recurring Option
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.autorenew, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Make this recurring',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        Switch(
                          value: _isRecurring,
                          onChanged: (val) => setState(() => _isRecurring = val),
                        ),
                      ],
                    ),
                    if (_isRecurring) ...[
                      const Divider(),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _recurringFrequency,
                        decoration: const InputDecoration(
                          labelText: 'Frequency',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'daily', child: Text('Daily')),
                          DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                          DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                          DropdownMenuItem(value: 'yearly', child: Text('Yearly')),
                        ],
                        onChanged: (val) => setState(() => _recurringFrequency = val!),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Checkbox(
                            value: _autoPay,
                            onChanged: (val) => setState(() => _autoPay = val!),
                          ),
                          const Text('Enable Auto-pay'),
                          const SizedBox(width: 4),
                          Tooltip(
                            message: 'Automatically create expense when due',
                            child: Icon(Icons.info_outline, size: 16, color: Theme.of(context).colorScheme.outline),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _isLoading ? null : _saveExpense,
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Add Expense'),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/voice'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.mic, color: Colors.white),
      ),
      bottomNavigationBar: const AppBottomBar(currentIndex: 1),
      ),
    );
  }
}
