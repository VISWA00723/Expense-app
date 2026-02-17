import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppBottomBar extends StatelessWidget {
  final int currentIndex;

  const AppBottomBar({
    Key? key,
    required this.currentIndex,
  }) : super(key: key);

  void _onItemTapped(BuildContext context, int index) {
    if (index == currentIndex) return;
    
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
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (index) => _onItemTapped(context, index),
      backgroundColor: colorScheme.surface,
      elevation: 3,
      indicatorColor: colorScheme.primaryContainer,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.add_circle_outline),
          selectedIcon: Icon(Icons.add_circle),
          label: 'Add',
        ),
        NavigationDestination(
          icon: Icon(Icons.list_alt),
          selectedIcon: Icon(Icons.list),
          label: 'Expenses',
        ),
        NavigationDestination(
          icon: Icon(Icons.smart_toy_outlined),
          selectedIcon: Icon(Icons.smart_toy),
          label: 'AI Coach',
        ),
      ],
    );
  }
}
