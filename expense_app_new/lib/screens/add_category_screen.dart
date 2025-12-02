import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:drift/drift.dart' as drift;
import 'package:expense_app_new/database/database.dart';
import 'package:expense_app_new/providers/database_provider.dart';
import 'package:expense_app_new/providers/auth_provider.dart';

class AddCategoryScreen extends ConsumerStatefulWidget {
  const AddCategoryScreen({super.key});

  @override
  ConsumerState<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends ConsumerState<AddCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  Color _selectedColor = Colors.blue;
  String _selectedIcon = '🏷️'; // Default emoji
  File? _selectedImage;
  bool _isLoading = false;
  List<Color> _usedColors = [];

  // Preset emojis for categories
  final List<String> _presetIcons = [
    '🍔', '🛒', '🚗', '🏠', '🎬', '💊', '✈️', '🎓', 
    '🎁', '🔧', '💻', '🏋️', '🐶', '👶', '📚', '🎨',
    '🏷️', '💸', '💼', '🍷', '☕', '🍕', '⛽', '💡'
  ];

  @override
  void initState() {
    super.initState();
    _fetchUsedColors();
  }

  Future<void> _fetchUsedColors() async {
    final user = ref.read(currentUserProvider);
    if (user != null) {
      final categories = await ref.read(userCategoriesProvider(user.id).future);
      if (mounted) {
        setState(() {
          _usedColors = categories
              .where((c) => c.color != null)
              .map((c) => Color(c.color!))
              .toList();
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _selectedIcon = ''; // Clear emoji if image selected
      });
    }
  }

  bool _isColorUsed(Color color) {
    // Check if color is close to any used color
    for (final usedColor in _usedColors) {
      if (usedColor.value == color.value) return true;
      // Optional: Check for similarity distance if needed, but exact match is safer for now
    }
    return false;
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isColorUsed(_selectedColor)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This color is already used by another category. Please pick a different one.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) return;

      final db = ref.read(databaseProvider);
      
      String? iconPath;
      if (_selectedImage != null) {
        // Save image to app storage
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = 'cat_${DateTime.now().millisecondsSinceEpoch}.png';
        final savedImage = await _selectedImage!.copy(p.join(appDir.path, fileName));
        iconPath = savedImage.path;
      }

      final category = ExpenseCategoriesCompanion(
        userId: drift.Value(user.id),
        name: drift.Value(_nameController.text.trim()),
        icon: drift.Value(_selectedIcon.isEmpty ? '🏷️' : _selectedIcon), // Fallback emoji
        color: drift.Value(_selectedColor.value),
        iconPath: drift.Value(iconPath),
        isCustom: const drift.Value(true),
        createdAt: drift.Value(DateTime.now().toIso8601String()),
      );

      await db.addCategory(category);
      
      // Invalidate categories provider
      ref.invalidate(userCategoriesProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category added successfully')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isColorUsed = _isColorUsed(_selectedColor);

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Category'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Preview
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: _selectedColor.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: _selectedColor, width: 2),
                        image: _selectedImage != null 
                          ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover)
                          : null,
                      ),
                      alignment: Alignment.center,
                      child: _selectedImage == null
                          ? Text(_selectedIcon, style: const TextStyle(fontSize: 40))
                          : null,
                    ),
                    const SizedBox(height: 8),
                    const Text('Preview'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Name Field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Category Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.label_outline),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Color Picker
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Color', style: Theme.of(context).textTheme.titleMedium),
                  if (isColorUsed)
                    Text(
                      'Color already used',
                      style: TextStyle(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.bold),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(8),
                child: ColorPicker(
                  pickerColor: _selectedColor,
                  onColorChanged: (color) => setState(() => _selectedColor = color),
                  colorPickerWidth: 300,
                  pickerAreaHeightPercent: 0.7,
                  enableAlpha: false,
                  displayThumbColor: true,
                  paletteType: PaletteType.hsvWithHue,
                  labelTypes: const [],
                  pickerAreaBorderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Icon Picker
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Icon', style: Theme.of(context).textTheme.titleMedium),
                  TextButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.image),
                    label: const Text('Upload Image'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _presetIcons.length,
                itemBuilder: (context, index) {
                  final icon = _presetIcons[index];
                  final isSelected = _selectedIcon == icon && _selectedImage == null;
                  return InkWell(
                    onTap: () => setState(() {
                      _selectedIcon = icon;
                      _selectedImage = null; // Clear image if emoji selected
                    }),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? _selectedColor.withOpacity(0.2) : null,
                        border: isSelected ? Border.all(color: _selectedColor) : null,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(icon, style: const TextStyle(fontSize: 24)),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: (_isLoading || isColorUsed) ? null : _saveCategory,
                  child: _isLoading 
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator())
                    : const Text('Create Category'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
