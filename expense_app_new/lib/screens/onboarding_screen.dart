import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:expense_app_new/theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingItem> _items = [
    OnboardingItem(
      title: 'Track Expenses Effortlessly',
      description: 'Keep track of your daily spending with just a few taps. Stay organized and in control of your finances.',
      icon: Icons.account_balance_wallet,
    ),
    OnboardingItem(
      title: 'Visual Dashboard',
      description: 'See where your money goes with beautiful charts and graphs. Understand your spending habits at a glance.',
      icon: Icons.pie_chart,
    ),
    OnboardingItem(
      title: 'AI Financial Assistant',
      description: 'Chat with our AI to add expenses naturally ("Spent 500 on lunch") or get personalized financial advice.',
      icon: Icons.smart_toy,
    ),
    OnboardingItem(
      title: 'Smart Notifications',
      description: 'Get timely reminders to log your expenses. Never forget to track a transaction again.',
      icon: Icons.notifications_active,
    ),
  ];

  @override
  void initState() {
    super.initState();
    print('🚀 OnboardingScreen initialized');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    print('➡️ Next page requested. Current: $_currentPage');
    if (_currentPage < _items.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  Future<void> _finishOnboarding() async {
    print('✅ Finishing onboarding');
    
    // Save that user has seen onboarding
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);

    if (!mounted) return;

    if (context.canPop()) {
      print('🔙 Popping context');
      context.pop();
    } else {
      print('🏠 Going to dashboard');
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                    },
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer.withOpacity(0.3),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                item.icon,
                                size: 80,
                                color: colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 48),
                            Text(
                              item.title,
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              item.description,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    height: 1.5,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Page Indicators
                      Row(
                        children: List.generate(
                          _items.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(right: 8),
                            height: 8,
                            width: _currentPage == index ? 24 : 8,
                            decoration: BoxDecoration(
                              color: _currentPage == index
                                  ? colorScheme.primary
                                  : colorScheme.primary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                      // Next/Done Button
                      FloatingActionButton(
                        onPressed: _nextPage,
                        elevation: 0,
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        child: Icon(
                          _currentPage == _items.length - 1
                              ? Icons.check
                              : Icons.arrow_forward,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Close Button
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                onPressed: _finishOnboarding,
                icon: const Icon(Icons.close),
                tooltip: 'Close',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingItem {
  final String title;
  final String description;
  final IconData icon;

  OnboardingItem({
    required this.title,
    required this.description,
    required this.icon,
  });
}
