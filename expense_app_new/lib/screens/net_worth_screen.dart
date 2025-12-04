import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' as drift;
import 'package:expense_app_new/database/database.dart';
import 'package:expense_app_new/providers/database_provider.dart';
import 'package:expense_app_new/providers/auth_provider.dart';

class NetWorthScreen extends ConsumerStatefulWidget {
  const NetWorthScreen({super.key});

  @override
  ConsumerState<NetWorthScreen> createState() => _NetWorthScreenState();
}

class _NetWorthScreenState extends ConsumerState<NetWorthScreen> {
  final _currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const Center(child: CircularProgressIndicator());

    final assetsAsync = ref.watch(assetsProvider(user.id));
    final liabilitiesAsync = ref.watch(liabilitiesProvider(user.id));
    final historyAsync = ref.watch(netWorthHistoryProvider(user.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Net Worth'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Net Worth Card
            _buildNetWorthCard(assetsAsync, liabilitiesAsync),
            const SizedBox(height: 24),

            // Chart
            const Text('History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: _buildChart(historyAsync),
            ),
            const SizedBox(height: 24),

            // Assets Section
            _buildSectionHeader('Assets', () => _showAssetDialog(context, user.id)),
            const SizedBox(height: 8),
            _buildAssetsList(assetsAsync, user.id),
            const SizedBox(height: 24),

            // Liabilities Section
            _buildSectionHeader('Liabilities', () => _showLiabilityDialog(context, user.id)),
            const SizedBox(height: 8),
            _buildLiabilitiesList(liabilitiesAsync, user.id),
          ],
        ),
      ),
    );
  }

  Widget _buildNetWorthCard(AsyncValue<List<Asset>> assetsAsync, AsyncValue<List<Liability>> liabilitiesAsync) {
    if (assetsAsync.isLoading || liabilitiesAsync.isLoading) {
      return const Card(
        elevation: 4,
        child: SizedBox(
          height: 200,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (assetsAsync.hasError || liabilitiesAsync.hasError) {
      return Card(
        elevation: 4,
        color: Theme.of(context).colorScheme.errorContainer,
        child: const SizedBox(
          height: 200,
          child: Center(child: Text('Error loading data')),
        ),
      );
    }

    final assets = assetsAsync.valueOrNull ?? [];
    final liabilities = liabilitiesAsync.valueOrNull ?? [];

    final totalAssets = assets.fold(0.0, (sum, item) => sum + item.value);
    final totalLiabilities = liabilities.fold(0.0, (sum, item) => sum + item.remainingAmount);
    final netWorth = totalAssets - totalLiabilities;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.tertiary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            const Text('Total Net Worth', style: TextStyle(color: Colors.white70, fontSize: 16)),
            const SizedBox(height: 8),
            Text(
              _currencyFormat.format(netWorth),
              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text('Assets', style: TextStyle(color: Colors.white70)),
                    Text(_currencyFormat.format(totalAssets), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
                Container(width: 1, height: 40, color: Colors.white24),
                Column(
                  children: [
                    const Text('Liabilities', style: TextStyle(color: Colors.white70)),
                    Text(_currencyFormat.format(totalLiabilities), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(AsyncValue<List<NetWorthHistoryData>> historyAsync) {
    return historyAsync.when(
      data: (history) {
        if (history.isEmpty) return const Center(child: Text('No history yet'));
        
        // Prepare spots
        final spots = history.asMap().entries.map((e) {
          return FlSpot(e.key.toDouble(), e.value.netWorth);
        }).toList();

        return LineChart(
          LineChartData(
            gridData: const FlGridData(show: false),
            titlesData: const FlTitlesData(show: false),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: Theme.of(context).colorScheme.primary,
                barWidth: 3,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Error loading chart')),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onAdd) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        IconButton.filledTonal(
          onPressed: onAdd,
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }

  Widget _buildAssetsList(AsyncValue<List<Asset>> assetsAsync, int userId) {
    return assetsAsync.when(
      data: (assets) {
        if (assets.isEmpty) return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No assets added')));
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: assets.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final asset = assets[index];
            return ListTile(
              tileColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              leading: CircleAvatar(
                backgroundColor: Colors.green.withOpacity(0.2),
                child: const Icon(Icons.account_balance, color: Colors.green),
              ),
              title: Text(asset.name),
              subtitle: Text(asset.type.toUpperCase()),
              trailing: Text(
                _currencyFormat.format(asset.value),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              onTap: () => _showAssetDialog(context, userId, asset: asset),
            );
          },
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (_, __) => const Text('Error loading assets'),
    );
  }

  Widget _buildLiabilitiesList(AsyncValue<List<Liability>> liabilitiesAsync, int userId) {
    return liabilitiesAsync.when(
      data: (liabilities) {
        if (liabilities.isEmpty) return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No liabilities added')));
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: liabilities.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final liability = liabilities[index];
            return ListTile(
              tileColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              leading: CircleAvatar(
                backgroundColor: Colors.red.withOpacity(0.2),
                child: const Icon(Icons.credit_card, color: Colors.red),
              ),
              title: Text(liability.name),
              subtitle: Text(liability.type.toUpperCase()),
              trailing: Text(
                _currencyFormat.format(liability.remainingAmount),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red),
              ),
              onTap: () => _showLiabilityDialog(context, userId, liability: liability),
            );
          },
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (_, __) => const Text('Error loading liabilities'),
    );
  }

  void _showAssetDialog(BuildContext context, int userId, {Asset? asset}) {
    final nameController = TextEditingController(text: asset?.name);
    final valueController = TextEditingController(text: asset?.value.toString());
    String type = asset?.type ?? 'bank';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(asset == null ? 'Add Asset' : 'Edit Asset'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name (e.g., HDFC Bank)'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: type,
                  items: const [
                    DropdownMenuItem(value: 'bank', child: Text('Bank Account')),
                    DropdownMenuItem(value: 'cash', child: Text('Cash')),
                    DropdownMenuItem(value: 'stock', child: Text('Stocks/MF')),
                    DropdownMenuItem(value: 'real_estate', child: Text('Real Estate')),
                    DropdownMenuItem(value: 'gold', child: Text('Gold')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (val) => setState(() => type = val!),
                  decoration: const InputDecoration(labelText: 'Type'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: valueController,
                  decoration: const InputDecoration(labelText: 'Value'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  final name = nameController.text.trim();
                  final valueStr = valueController.text.trim();

                  if (name.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a name')),
                    );
                    return;
                  }

                  final value = double.tryParse(valueStr);
                  if (value == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a valid number')),
                    );
                    return;
                  }

                  try {
                    final db = ref.read(databaseProvider);
                    final now = DateTime.now().toIso8601String();

                    if (asset == null) {
                      await db.addAsset(AssetsCompanion(
                        userId: drift.Value(userId),
                        name: drift.Value(name),
                        type: drift.Value(type),
                        value: drift.Value(value),
                        updatedAt: drift.Value(now),
                      ));
                    } else {
                      await db.updateAsset(asset.copyWith(
                        name: name,
                        type: type,
                        value: value,
                        updatedAt: now,
                      ));
                    }
                    
                    // Update History Snapshot
                    await _updateHistorySnapshot(userId);
                    
                    if (context.mounted) Navigator.pop(context);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error saving asset: $e')),
                      );
                    }
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showLiabilityDialog(BuildContext context, int userId, {Liability? liability}) {
    final nameController = TextEditingController(text: liability?.name);
    final totalController = TextEditingController(text: liability?.totalAmount.toString());
    final remainingController = TextEditingController(text: liability?.remainingAmount.toString());
    String type = liability?.type ?? 'loan';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(liability == null ? 'Add Liability' : 'Edit Liability'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Name (e.g., Home Loan)'),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: type,
                    items: const [
                      DropdownMenuItem(value: 'loan', child: Text('Personal Loan')),
                      DropdownMenuItem(value: 'credit_card', child: Text('Credit Card')),
                      DropdownMenuItem(value: 'mortgage', child: Text('Mortgage')),
                      DropdownMenuItem(value: 'other', child: Text('Other')),
                    ],
                    onChanged: (val) => setState(() => type = val!),
                    decoration: const InputDecoration(labelText: 'Type'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: totalController,
                    decoration: const InputDecoration(labelText: 'Total Amount'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: remainingController,
                    decoration: const InputDecoration(labelText: 'Remaining Amount'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  final name = nameController.text.trim();
                  final totalStr = totalController.text.trim();
                  final remainingStr = remainingController.text.trim();

                  if (name.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a name')),
                    );
                    return;
                  }

                  final remaining = double.tryParse(remainingStr);
                  if (remaining == null || remaining < 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a valid remaining amount')),
                    );
                    return;
                  }

                  final total = double.tryParse(totalStr) ?? 0.0;

                  try {
                    final db = ref.read(databaseProvider);
                    final now = DateTime.now().toIso8601String();

                    if (liability == null) {
                      await db.addLiability(LiabilitiesCompanion(
                        userId: drift.Value(userId),
                        name: drift.Value(name),
                        type: drift.Value(type),
                        totalAmount: drift.Value(total),
                        remainingAmount: drift.Value(remaining),
                        updatedAt: drift.Value(now),
                      ));
                    } else {
                      await db.updateLiability(liability.copyWith(
                        name: name,
                        type: type,
                        totalAmount: total,
                        remainingAmount: remaining,
                        updatedAt: now,
                      ));
                    }

                    // Update History Snapshot
                    await _updateHistorySnapshot(userId);

                    if (context.mounted) Navigator.pop(context);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error saving liability: $e')),
                      );
                    }
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _updateHistorySnapshot(int userId) async {
    try {
      final db = ref.read(databaseProvider);
      final assets = await db.getAssets(userId);
      final liabilities = await db.getLiabilities(userId);

      double totalAssets = assets.fold(0, (sum, item) => sum + item.value);
      double totalLiabilities = liabilities.fold(0, (sum, item) => sum + item.remainingAmount);

      await db.addNetWorthSnapshot(NetWorthHistoryCompanion(
        userId: drift.Value(userId),
        totalAssets: drift.Value(totalAssets),
        totalLiabilities: drift.Value(totalLiabilities),
        netWorth: drift.Value(totalAssets - totalLiabilities),
        date: drift.Value(DateTime.now().toIso8601String()),
      ));
    } catch (e, stackTrace) {
      debugPrint('Error updating net worth snapshot: $e\n$stackTrace');
    } finally {
      ref.invalidate(netWorthHistoryProvider);
      ref.invalidate(assetsProvider);
      ref.invalidate(liabilitiesProvider);
    }
  }
}
