import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class UserGuideScreen extends StatelessWidget {
  const UserGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Guide'),
      ),
      body: Markdown(
        data: _userGuideContent,
        styleSheet: MarkdownStyleSheet(
          h1: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Theme.of(context).colorScheme.primary),
          h2: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          h3: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          p: Theme.of(context).textTheme.bodyLarge,
          listBullet: Theme.of(context).textTheme.bodyLarge,
          h2Padding: const EdgeInsets.only(top: 24, bottom: 8),
          h3Padding: const EdgeInsets.only(top: 16, bottom: 8),
        ),
      ),
    );
  }

  static const String _userGuideContent = '''
# 🚀 WalletWise User Guide

Welcome to WalletWise! Here is everything you can do in the app:

## 1. 🎮 Gamification (Make Saving Fun)
*   **Wellness Score**: A score from 0-100 on your dashboard. It goes up when you stay under budget and save more!
*   **Streaks**: Log expenses daily to build a streak. Don't break the chain! 🔥
*   **Achievements**: Unlock badges like "First Saver" or "Budget Master" by hitting milestones.

## 2. 🔄 Recurring Expenses (Subscriptions)
*   **Auto-Track**: Add Netflix, Rent, or Gym once. The app will automatically add them every month.
*   **Reminders**: Get notified before a bill is due.
*   **How to use**: In "Add Expense", toggle **"Make this recurring"**.

## 3. 🤖 AI & Smart Scanning
*   **Receipt Scanner**: Tap the camera icon to scan a paper receipt. It extracts the Merchant, Date, and Amount automatically.
*   **AI Chat**: Go to the "AI" tab to ask questions like *"How much did I spend on food last month?"* or *"Analyze this receipt"*.

## 4. 💳 UPI Payments (New!)
*   **Direct Pay**: Pay merchants directly from the app.
*   **Scan QR**: Use the built-in QR scanner to pay at shops.
*   **Auto-Save**: No need to log manually. Paying via the app saves the expense automatically.
*   **Quick Actions**: Use the "Scan" button next to the UPI ID field.

## 5. 🔒 Security & Privacy
*   **Biometric Lock**: Secure your data with Fingerprint/Face ID (Enable in Settings).
*   **Local Data**: All your financial data stays on your phone. We don't see it.
*   **Export**: Need a backup? Export your data to CSV or PDF from the Profile screen.

## 6. 📊 Advanced Analytics
*   **Graphs**: See where your money goes with beautiful pie charts and monthly trends.
*   **Budgets**: Set monthly limits for categories (e.g., ₹5000 for Food) and get warned if you exceed them.
''';
}
