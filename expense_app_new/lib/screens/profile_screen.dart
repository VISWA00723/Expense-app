import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_app_new/providers/database_provider.dart';
import 'package:expense_app_new/providers/auth_provider.dart';
import 'package:expense_app_new/services/auth_service.dart';
import 'package:expense_app_new/providers/theme_provider.dart';
import 'package:expense_app_new/services/notification_service.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _salaryController;
  late TextEditingController _currentPasswordController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;
  bool _isLoading = false;
  bool _showPasswordFields = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _salaryController = TextEditingController();
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = ref.read(currentUserProvider);
    if (user != null) {
      _nameController.text = user.name;
      _salaryController.text = user.monthlySalary.toString();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _salaryController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final db = ref.read(databaseProvider);
      final updatedUser = user.copyWith(
        name: _nameController.text,
        monthlySalary: double.parse(_salaryController.text),
      );

      await db.updateUser(updatedUser);
      ref.invalidate(currentUserProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _changePassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    if (_newPasswordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) return;

      final db = ref.read(databaseProvider);
      final authService = AuthService(db: db);
      
      final success = await authService.changePassword(
        email: user.email,
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Current password is incorrect')),
        );
        return;
      }

      ref.invalidate(currentUserProvider);

      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      setState(() => _showPasswordFields = false);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password changed successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout?'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      ref.invalidate(currentUserProvider);
      if (!mounted) return;
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final colorScheme = Theme.of(context).colorScheme;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            Center(
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorScheme.primary.withOpacity(0.2),
                    ),
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // App Guide Card
            Card(
              color: colorScheme.primaryContainer,
              child: ListTile(
                leading: Icon(Icons.help_outline, color: colorScheme.onPrimaryContainer),
                title: Text(
                  'App Guide',
                  style: TextStyle(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  'Learn how to use the app',
                  style: TextStyle(color: colorScheme.onPrimaryContainer.withOpacity(0.8)),
                ),
                trailing: Icon(Icons.chevron_right, color: colorScheme.onPrimaryContainer),
                onTap: () {
                  print('🔘 App Guide button tapped');
                  context.push('/onboarding');
                },
              ),
            ),
            const SizedBox(height: 32),

            // Personal Information Section
            Text(
              'Personal Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),

            // Name Field
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Full Name',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Lifestyle Display
            TextField(
              enabled: false,
              controller: TextEditingController(text: user.lifestyle.toUpperCase()),
              decoration: InputDecoration(
                labelText: 'Lifestyle',
                prefixIcon: const Icon(Icons.info_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Salary Section
            Text(
              'Financial Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),

            // Monthly Salary Field
            TextField(
              controller: _salaryController,
              decoration: InputDecoration(
                labelText: 'Monthly Salary',
                prefixIcon: const Icon(Icons.currency_rupee),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),

            // Update Profile Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: _isLoading ? null : _updateProfile,
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Update Profile'),
              ),
            ),
            const SizedBox(height: 32),

            // Appearance Section
            Text(
              'Appearance',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),
            
            Consumer(
              builder: (context, ref, child) {
                final themeState = ref.watch(themeProvider);
                final notifier = ref.read(themeProvider.notifier);
                
                return Column(
                  children: [
                    // Theme Mode
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.brightness_6),
                        title: const Text('Theme Mode'),
                        trailing: DropdownButton<ThemeMode>(
                          value: themeState.mode,
                          underline: const SizedBox(),
                          items: const [
                            DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
                            DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                            DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
                          ],
                          onChanged: (mode) {
                            if (mode != null) notifier.setMode(mode);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Dark Theme Style
                    if (themeState.mode != ThemeMode.light)
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.palette),
                          title: const Text('Dark Theme Style'),
                          trailing: DropdownButton<String>(
                            value: themeState.darkStyle,
                            underline: const SizedBox(),
                            items: const [
                              DropdownMenuItem(value: 'black', child: Text('Pure Black')),
                              DropdownMenuItem(value: 'purple', child: Text('Midnight Purple')),
                            ],
                            onChanged: (style) {
                              if (style != null) notifier.setDarkStyle(style);
                            },
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),

            // Notifications Section
            Text(
              'Notifications',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),
            
            FutureBuilder<bool>(
              future: NotificationService.isEnabled(),
              builder: (context, snapshot) {
                final isEnabled = snapshot.data ?? true;
                
                return Column(
                  children: [
                    Card(
                      child: SwitchListTile(
                        secondary: const Icon(Icons.notifications_active),
                        title: const Text('Daily Reminders'),
                        subtitle: const Text('Get reminded to track expenses'),
                        value: isEnabled,
                        onChanged: (value) async {
                          if (value) {
                            final granted = await NotificationService.requestPermission();
                            if (granted) {
                              await NotificationService.setEnabled(true);
                              await NotificationService.scheduleDailyNotifications();
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Notifications enabled! You\'ll receive 3 daily reminders.')),
                              );
                              setState(() {});
                            } else {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Permission denied. Enable in system settings.')),
                              );
                            }
                          } else {
                            await NotificationService.setEnabled(false);
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Notifications disabled')),
                            );
                            setState(() {});
                          }
                        },
                      ),
                    ),
                    if (isEnabled) ...[
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.schedule, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Notification Times',
                                    style: Theme.of(context).textTheme.titleSmall,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildTimeRow('Morning', '9:00 AM', Icons.wb_sunny),
                              const SizedBox(height: 8),
                              _buildTimeRow('Afternoon', '3:00 PM', Icons.wb_cloudy),
                              const SizedBox(height: 8),
                              _buildTimeRow('Night', '9:00 PM', Icons.nightlight_round),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 32),

            // Security Section
            Text(
              'Security',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),

            // Change Password Toggle
            Card(
              child: ListTile(
                leading: const Icon(Icons.lock_outline),
                title: const Text('Change Password'),
                trailing: Icon(
                  _showPasswordFields
                      ? Icons.expand_less
                      : Icons.expand_more,
                ),
                onTap: () {
                  setState(() => _showPasswordFields = !_showPasswordFields);
                },
              ),
            ),

            if (_showPasswordFields) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _currentPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _isLoading ? null : _changePassword,
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Change Password'),
                ),
              ),
            ],
            const SizedBox(height: 32),

            // Logout Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
              ),
            ),
          ],
        ),
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
        currentIndex: 0,
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

  Widget _buildTimeRow(String label, String time, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const Spacer(),
        Text(time, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }
}
