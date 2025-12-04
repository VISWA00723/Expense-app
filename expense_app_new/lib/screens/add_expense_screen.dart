import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:expense_app_new/services/receipt_scanning_service.dart';
import 'package:expense_app_new/services/upi_service.dart';
import 'package:expense_app_new/services/upi_bridge.dart';
import 'package:expense_app_new/services/upi_parser.dart';
import 'package:expense_app_new/services/auto_categorizer.dart';
import 'package:expense_app_new/services/recent_payees_service.dart';
import 'package:expense_app_new/screens/qr_scanner_screen.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/drift.dart' as drift;
import 'package:expense_app_new/database/database.dart';
import 'package:expense_app_new/providers/auth_provider.dart';
import 'package:expense_app_new/providers/database_provider.dart';
import 'package:expense_app_new/providers/api_provider.dart';
import 'package:expense_app_new/services/gamification_service.dart';
import 'package:expense_app_new/services/recurring_expense_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:expense_app_new/widgets/app_bottom_bar.dart';
import 'package:expense_app_new/providers/receipt_provider.dart';

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
  late TextEditingController _vpaController;
  int? _selectedCategoryId;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  bool _isRecurring = false;
  String _recurringFrequency = 'monthly';
  bool _autoPay = false;
  String _selectedCurrency = 'INR';
  final _receiptScanningService = ReceiptScanningService();
  List<String> _recentPayees = [];
  String _paymentMethod = 'Cash'; // 'Cash' or 'UPI'
  late FocusNode _amountFocusNode;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _amountController = TextEditingController();
    _notesController = TextEditingController();
    _vpaController = TextEditingController();
    _amountFocusNode = FocusNode();
    _loadRecentPayees();
    _loadPreferences();
    
    // Auto-focus amount field after a short delay to allow transition
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _amountFocusNode.requestFocus();
      }
    });
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _paymentMethod = prefs.getString('last_payment_method') ?? 'Cash';
      });
    }
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_payment_method', _paymentMethod);
  }

  Future<void> _loadRecentPayees() async {
    final payees = await RecentPayeesService.getPayees();
    if (mounted) {
      setState(() => _recentPayees = payees);
    }
  }

  Future<void> _scanQrCode() async {
    final vpa = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const QrScannerScreen()),
    );
    
    if (vpa != null && mounted) {
      setState(() {
        _vpaController.text = vpa;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('UPI ID extracted from QR code')),
      );
    }
  }

  void _showCategorySheet(List<ExpenseCategory> categories) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Category',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.push('/add-category');
                    },
                    icon: const Icon(Icons.add_circle_outline),
                    tooltip: 'Add Category',
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: GridView.builder(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.8,
                ),
                itemCount: categories.length + 1, // +1 for Add button
                itemBuilder: (context, index) {
                  if (index == categories.length) {
                    // Add Category Button
                    return InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/add-category');
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant, style: BorderStyle.solid),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add, size: 28),
                            const SizedBox(height: 8),
                            Text(
                              'Add New',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final category = categories[index];
                  final isSelected = _selectedCategoryId == category.id;
                  final customColor = category.color != null ? Color(category.color!) : null;
                  
                  return InkWell(
                    onTap: () {
                      setState(() => _selectedCategoryId = category.id);
                      Navigator.pop(context);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? (customColor?.withOpacity(0.2) ?? Theme.of(context).colorScheme.primaryContainer)
                            : Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected 
                            ? Border.all(color: customColor ?? Theme.of(context).colorScheme.primary, width: 2)
                            : (customColor != null ? Border.all(color: customColor.withOpacity(0.5)) : null),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (category.iconPath != null)
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                image: DecorationImage(
                                  image: FileImage(File(category.iconPath!)),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            )
                          else
                            Text(
                              category.icon,
                              style: const TextStyle(fontSize: 28),
                            ),
                          const SizedBox(height: 8),
                          Text(
                            category.name,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? (customColor ?? Theme.of(context).colorScheme.primary) : null,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    _vpaController.dispose();
    _amountFocusNode.dispose();
    _receiptScanningService.dispose();
    super.dispose();
  }



  Future<File?> _pickReceiptImage() async {
    // Request permissions first
    final deviceInfo = DeviceInfoPlugin();
    bool requestStorage = false;
    
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      requestStorage = androidInfo.version.sdkInt <= 32;
    }

    List<Permission> permissions = [
      Permission.camera,
      Permission.photos, // For Android 13+
    ];

    if (requestStorage) {
      permissions.add(Permission.storage);
    }

    Map<Permission, PermissionStatus> statuses = await permissions.request();

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
    File? imageFile;
    try {
      imageFile = await _pickReceiptImage();
      if (imageFile == null) return;

      if (!mounted) return;
      setState(() => _isLoading = true);
      
      final receiptData = await _receiptScanningService.scanReceipt(imageFile);
      
      if (!mounted) return;
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
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Receipt scanned successfully!')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error scanning receipt: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      // Security: Delete temporary image file
      if (imageFile != null) {
        try {
          if (await imageFile.exists()) {
            await imageFile.delete();
          }
        } catch (e) {
          print('Error deleting temp file: $e');
        }
      }
    }
  }

  Future<void> _scanReceiptWithAI() async {
    File? imageFile;
    try {
      imageFile = await _pickReceiptImage();
      if (imageFile == null) return;

      if (!mounted) return;
      setState(() => _isLoading = true);
      
      // Stage 1: Get raw text and clean it
      final receiptData = await _receiptScanningService.scanReceipt(imageFile);
      final cleanedText = _receiptScanningService.cleanRawText(receiptData.rawText);
      
      if (!mounted) return;
      
      // Security: Pass data via provider instead of navigation arguments
      ref.read(receiptTextProvider.notifier).state = 'Analyze Receipt:\n$cleanedText';
      context.push('/ai');
      
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error processing receipt: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      // Security: Delete temporary image file
      if (imageFile != null) {
        try {
          if (await imageFile.exists()) {
            await imageFile.delete();
          }
        } catch (e) {
          print('Error deleting temp file: $e');
        }
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
    if (!mounted) return;
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
            case 'monthly': 
              // Robust month addition handling end-of-month overflow
              int year = nextDate.year;
              int month = nextDate.month + 1;
              if (month > 12) {
                year++;
                month = 1;
              }
              // Get last day of the target month
              final lastDayOfMonth = DateTime(year, month + 1, 0).day;
              final day = nextDate.day > lastDayOfMonth ? lastDayOfMonth : nextDate.day;
              nextDate = DateTime(year, month, day);
              break;
            case 'yearly': 
              // Robust year addition handling leap years (Feb 29 -> Feb 28)
              int year = nextDate.year + 1;
              int month = nextDate.month;
              int day = nextDate.day;
              if (month == 2 && day == 29 && !((year % 4 == 0 && year % 100 != 0) || year % 400 == 0)) {
                day = 28;
              }
              nextDate = DateTime(year, month, day);
              break;
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

        // Check achievements and update wellness score (fire and forget)
        final gamificationService = ref.read(gamificationServiceProvider);
        gamificationService.checkExpenseAchievements(user.id);
        gamificationService.calculateWellnessScore(user.id);

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

  Future<void> _payWithUpi() async {
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an amount')),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    // Use title as note, or default
    final note = _titleController.text.isNotEmpty ? _titleController.text : 'Expense Payment';
    
    // Get VPA
    final vpa = _vpaController.text.trim();
    if (vpa.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter Payee UPI ID')),
      );
      return;
    }

    // Construct URI
    final uri = Uri(
      scheme: 'upi',
      host: 'pay',
      queryParameters: {
        'pa': vpa,
        'pn': 'Merchant', // Required by some apps, generic fallback
        'am': amount.toStringAsFixed(2),
        'tn': note,
        'cu': 'INR',
      },
    ).toString();

    try {
      final response = await UpiBridge.makePayment(uri);
      
      if (response != null) {
        final data = UpiParser.parseResponse(response);
        
        // Check for success
        final status = (data['Status'] ?? data['status'] ?? '').toString().toUpperCase();
        
        if (status == 'SUCCESS') {
          // Save VPA for future use
          await RecentPayeesService.addPayee(vpa);
          _loadRecentPayees();

            if (!mounted) return;
            // 🧠 Smart Categorization
            await AutoCategorizer.initialize();
            
            if (!mounted) return;
            final detectedCategoryName = AutoCategorizer.detectCategory(note);
            
            // Find category ID
            final user = ref.read(currentUserProvider);
            if (user != null) {
              final categories = await ref.read(databaseProvider).getUserCategories(user.id);
              
              if (!mounted) return;
              
              if (categories.isEmpty) {
                 ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No categories found. Please create one first.')),
                );
                return;
              }
              
              // Try to find matching category
              final category = categories.firstWhere(
                (c) => c.name.toLowerCase() == detectedCategoryName.toLowerCase(),
                orElse: () => categories.firstWhere(
                  (c) => c.name == 'Miscellaneous',
                  orElse: () => categories.first,
                ),
              );
              
              // Update state for _saveExpense to use
              setState(() {
                _selectedCategoryId = category.id;
                // If title was empty, suggest one from note (which we used as note)
                if (_titleController.text.isEmpty) {
                  _titleController.text = note;
                }
              });
              
              // Save
              await _saveExpense();
            }
        } else if (status == 'FAILURE' || status == 'FAILED') {
           if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Payment Failed')),
            );
          }
        } else {
           if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Payment Status: $status')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
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
        padding: const EdgeInsets.all(16),
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
                        DropdownMenuItem(value: 'AUD', child: Text('AUD (A\$)')),
                        DropdownMenuItem(value: 'CAD', child: Text('CAD (C\$)')),
                        DropdownMenuItem(value: 'JPY', child: Text('JPY (¥)')),
                        DropdownMenuItem(value: 'CNY', child: Text('CNY (¥)')),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _selectedCurrency = val!;
                          if (_selectedCurrency != 'INR') {
                            _paymentMethod = 'Cash';
                          }
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: TextFormField(
                      controller: _amountController,
                      focusNode: _amountFocusNode,
                      decoration: InputDecoration(
                        labelText: 'Amount',
                        hintText: '0.00',
                        prefixIcon: const Icon(Icons.attach_money),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Please enter amount';
                        }
                        final parsedValue = double.tryParse(value!);
                        if (parsedValue == null) {
                          return 'Please enter valid amount';
                        }
                        if (parsedValue <= 0) {
                          return 'Please enter an amount greater than zero';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              
              if (_selectedCurrency == 'INR') ...[
                const SizedBox(height: 24),
                Text(
                  'Payment Method',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 12),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'Cash',
                      label: Text('Cash / Card'),
                      icon: Icon(Icons.money),
                    ),
                    ButtonSegment(
                      value: 'UPI',
                      label: Text('UPI'),
                      icon: Icon(Icons.qr_code),
                    ),
                  ],
                  selected: {_paymentMethod},
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() {
                      _paymentMethod = newSelection.first;
                    });
                    _savePreferences();
                  },
                  style: ButtonStyle(
                    visualDensity: VisualDensity.comfortable,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                
                if (_paymentMethod == 'UPI') ...[
                  const SizedBox(height: 16),
                  Card(
                    elevation: 0,
                    color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.verified_user_outlined, size: 20, color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 8),
                              Text(
                                'Payee Details',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _vpaController,
                                  decoration: InputDecoration(
                                    labelText: 'UPI ID (VPA)',
                                    hintText: 'merchant@upi',
                                    filled: true,
                                    fillColor: Theme.of(context).colorScheme.surface,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton.filled(
                                onPressed: _scanQrCode,
                                icon: const Icon(Icons.qr_code_scanner),
                                tooltip: 'Scan QR',
                              ),
                            ],
                          ),
                          if (_recentPayees.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              'Recent',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 32,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: _recentPayees.length,
                                separatorBuilder: (context, index) => const SizedBox(width: 8),
                                itemBuilder: (context, index) {
                                  final payee = _recentPayees[index];
                                  return ActionChip(
                                    label: Text(payee, style: const TextStyle(fontSize: 12)),
                                    onPressed: () {
                                      setState(() => _vpaController.text = payee);
                                    },
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    avatar: const Icon(Icons.history, size: 14),
                                  );
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ],
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
                  if (cats.isEmpty) return const Text('No categories found');
                  
                  final selectedCategory = _selectedCategoryId != null 
                      ? cats.firstWhere((c) => c.id == _selectedCategoryId, orElse: () => cats.first)
                      : null;

                  return InkWell(
                    onTap: () => _showCategorySheet(cats),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Theme.of(context).colorScheme.outline),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          if (selectedCategory != null) ...[
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: selectedCategory.color != null 
                                    ? Color(selectedCategory.color!).withOpacity(0.2)
                                    : Theme.of(context).colorScheme.primaryContainer,
                                shape: BoxShape.circle,
                              ),
                              child: selectedCategory.iconPath != null
                                ? Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      image: DecorationImage(
                                        image: FileImage(File(selectedCategory.iconPath!)),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  )
                                : Text(selectedCategory.icon, style: const TextStyle(fontSize: 20)),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                selectedCategory.name,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                          ] else
                            Expanded(
                              child: Text(
                                'Select Category',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          const Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (err, stack) => Text('Error: $err'),
              ),
              const SizedBox(height: 24),

              // Date Selection
              Text(
                'Date',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('Today'),
                    selected: isSameDay(_selectedDate, DateTime.now()),
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedDate = DateTime.now());
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Yesterday'),
                    selected: isSameDay(_selectedDate, DateTime.now().subtract(const Duration(days: 1))),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedDate = DateTime.now().subtract(const Duration(days: 1)));
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  ActionChip(
                    avatar: const Icon(Icons.calendar_today, size: 16),
                    label: Text(DateFormat('MMM dd').format(_selectedDate)),
                    onPressed: () => _selectDate(context),
                  ),
                ],
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

              // Primary Action Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton.icon(
                  onPressed: _isLoading 
                      ? null 
                      : ((_selectedCurrency == 'INR' && _paymentMethod == 'UPI') ? _payWithUpi : _saveExpense),
                  icon: _isLoading 
                      ? const SizedBox(
                          width: 24, 
                          height: 24, 
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        )
                      : Icon((_selectedCurrency == 'INR' && _paymentMethod == 'UPI') ? Icons.payment : Icons.check),
                  label: Text(
                    _isLoading 
                        ? 'Processing...' 
                        : ((_selectedCurrency == 'INR' && _paymentMethod == 'UPI') ? 'Pay & Save' : 'Save Expense'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: (_selectedCurrency == 'INR' && _paymentMethod == 'UPI') 
                        ? Theme.of(context).colorScheme.primary 
                        : Theme.of(context).colorScheme.tertiary,
                    foregroundColor: Colors.white,
                  ),
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
  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
