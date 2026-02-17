import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:expense_app_new/providers/auth_provider.dart';
import 'package:expense_app_new/services/analytics_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:expense_app_new/services/biometric_service.dart';
import 'package:expense_app_new/database/database.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _canCheckBiometrics = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool('biometric_enabled') ?? false;
    if (!isEnabled) return;

    final canCheck = await ref.read(biometricServiceProvider).isDeviceSupported();
    if (mounted) {
      setState(() => _canCheckBiometrics = canCheck);
      if (canCheck) {
        // Auto-trigger biometric prompt if enabled
        _handleBiometricLogin();
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _completeLogin(User user, String loginMethod) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Save email for biometric login
    await prefs.setString('last_email', user.email);

    // Update global state
    ref.read(currentUserProvider.notifier).state = user;
    
    // Log analytics
    await AnalyticsService.logLogin(loginMethod);
    
    if (!mounted) return;

    // Check if user has seen onboarding
    final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;

    if (!hasSeenOnboarding) {
      context.go('/onboarding');
    } else {
      context.go('/dashboard');
    }
  }

  Future<void> _handleBiometricLogin() async {
    final authenticated = await ref.read(biometricServiceProvider).authenticate();
    if (authenticated) {
      final prefs = await SharedPreferences.getInstance();
      final savedEmail = prefs.getString('last_email');
      
      if (savedEmail != null && savedEmail.isNotEmpty) {
        setState(() => _isLoading = true);
        final authService = ref.read(authServiceProvider);
        final user = await authService.getUserByEmail(savedEmail);
        
        if (user != null) {
          await _completeLogin(user, 'biometric');
        } else {
          setState(() => _isLoading = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('User not found. Please login with password first.')),
            );
          }
        }
      } else {
         if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please login with password once to enable biometric login.')),
            );
          }
      }
    }
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final authService = ref.read(authServiceProvider);
    final success = await authService.login(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (success && authService.currentUser != null) {
      await _completeLogin(authService.currentUser!, 'email');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid email or password')),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Logo
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colorScheme.primary.withOpacity(0.05),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Image.asset(
                          'assets/Gemini_Generated_Image_vzm726vzm726vzm7-removebg-preview.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Header
                    Text(
                      'Expense Tracker',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in to your account',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),

                    // Email Field
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        hintText: 'you@example.com',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),

                    // Password Field
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: 'Enter your password',
                        prefixIcon: const Icon(Icons.lock_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: () {
                            setState(() => _obscurePassword = !_obscurePassword);
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Login Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: FilledButton(
                        onPressed: _isLoading ? null : _handleLogin,
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
                            : const Text('Sign In'),
                      ),
                    ),
                    
                    // Biometric Button
                    if (_canCheckBiometrics) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton.icon(
                          onPressed: _isLoading ? null : _handleBiometricLogin,
                          icon: const Icon(Icons.fingerprint),
                          label: const Text('Login with Biometrics'),
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Sign Up Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        TextButton(
                          onPressed: () => context.go('/signup'),
                          child: const Text('Sign Up'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Footer
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: colorScheme.outlineVariant,
                ),
              ),
            ),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () async {
                    final url = Uri.parse('https://mindapt.in/');
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url);
                    }
                  },
                  child: Text(
                    'Powered by MindApt',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.primary,
                          decoration: TextDecoration.underline,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Copyright © Mindapt 2025',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
