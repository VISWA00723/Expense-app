import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:expense_app_new/providers/database_provider.dart';
import 'package:expense_app_new/services/color_service.dart';
import 'package:expense_app_new/database/database.dart';

class ExpensePieChart extends ConsumerStatefulWidget {
  final int userId;
  const ExpensePieChart({super.key, required this.userId});

  @override
  ConsumerState<ExpensePieChart> createState() => _ExpensePieChartState();
}

class _ExpensePieChartState extends ConsumerState<ExpensePieChart> {
  int touchedIndex = -1;
  String _selectedFilter = 'Monthly'; // Weekly, Monthly, Yearly, All Time

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    // Calculate date range based on filter
    String? startDate;
    String? endDate;
    final now = DateTime.now();
    
    if (_selectedFilter == 'Weekly') {
      // Last 7 days
      final start = now.subtract(const Duration(days: 7));
      startDate = DateFormat('yyyy-MM-dd').format(start);
      endDate = DateFormat('yyyy-MM-dd').format(now);
    } else if (_selectedFilter == 'Monthly') {
      // Current Month
      startDate = DateFormat('yyyy-MM-01').format(now);
      // Last day of month
      final nextMonth = DateTime(now.year, now.month + 1, 1);
      final end = nextMonth.subtract(const Duration(days: 1));
      endDate = DateFormat('yyyy-MM-dd').format(end);
    } else if (_selectedFilter == 'Yearly') {
      // Current Year
      startDate = DateFormat('yyyy-01-01').format(now);
      endDate = DateFormat('yyyy-12-31').format(now);
    }
    // All Time: startDate = null, endDate = null

    final spendingAsync = ref.watch(
      spendingByCategoryWithIdProvider((widget.userId, startDate, endDate)),
    );

    return Column(
      children: [
        // Filter Toggles
        Container(
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              _buildFilterOption('Weekly'),
              _buildFilterOption('Monthly'),
              _buildFilterOption('Yearly'),
              _buildFilterOption('All'),
            ],
          ),
        ),
        
        spendingAsync.when(
          data: (data) {
            if (data.isEmpty) {
              return SizedBox(
                height: 250,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.pie_chart_outline, size: 48, color: colorScheme.outline),
                      const SizedBox(height: 16),
                      Text(
                        'No expenses for this period',
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Sort and calculate total
            final sortedData = List<CategorySpending>.from(data)
              ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
            final total = sortedData.fold<double>(0, (sum, e) => sum + e.totalAmount);

            // Center Text
            String centerLabel = 'Total Spent';
            String centerAmount = '₹${total.toStringAsFixed(0)}';
            
            if (touchedIndex != -1 && touchedIndex < sortedData.length) {
              final item = sortedData[touchedIndex];
              centerLabel = item.categoryName;
              centerAmount = '₹${item.totalAmount.toStringAsFixed(0)}';
            }

            return Column(
              children: [
                SizedBox(
                  height: 280, // Increased height for external badges
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          pieTouchData: PieTouchData(
                            touchCallback: (FlTouchEvent event, pieTouchResponse) {
                              if (!event.isInterestedForInteractions ||
                                  pieTouchResponse == null ||
                                  pieTouchResponse.touchedSection == null) {
                                if (mounted && touchedIndex != -1) {
                                  setState(() => touchedIndex = -1);
                                }
                                return;
                              }
                              if (mounted) {
                                setState(() {
                                  touchedIndex = pieTouchResponse
                                      .touchedSection!.touchedSectionIndex;
                                });
                              }
                            },
                          ),
                          sections: sortedData.asMap().entries.map((entry) {
                            final index = entry.key;
                            final item = entry.value;
                            final color = ColorService.getColorById(item.categoryId);
                            final isTouched = index == touchedIndex;
                            final radius = isTouched ? 65.0 : 55.0;
                            final percentage = (item.totalAmount / total * 100);
                            final showBadge = percentage >= 5 || isTouched;
                            
                            return PieChartSectionData(
                              value: item.totalAmount,
                              color: color,
                              radius: radius,
                              title: showBadge ? '${percentage.toStringAsFixed(0)}%' : '',
                              titleStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              titlePositionPercentageOffset: 1.5,
                              showTitle: showBadge,
                              badgeWidget: showBadge ? _buildBadge(percentage, color) : null,
                              badgePositionPercentageOffset: 1.5,
                              borderSide: const BorderSide(color: Colors.white, width: 2), // Gap between sections
                            );
                          }).toList(),
                          centerSpaceRadius: 60,
                          sectionsSpace: 4, // Space between sections
                          startDegreeOffset: -90,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            centerAmount,
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            centerLabel,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Legend (Scrollable horizontal)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: sortedData.map((item) {
                      final color = ColorService.getColorById(item.categoryId);
                      final isTouched = sortedData.indexOf(item) == touchedIndex;
                      return Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: isTouched ? Border.all(color: colorScheme.onSurface, width: 2) : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              item.categoryName,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: isTouched ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            );
          },
          loading: () => const SizedBox(height: 250, child: Center(child: CircularProgressIndicator())),
          error: (e, s) => Text('Error: $e'),
        ),
      ],
    );
  }

  Widget _buildFilterOption(String label) {
    // Map 'All' to 'All Time' for logic, but display 'All'
    final logicLabel = label == 'All' ? 'All Time' : label;
    final isSelected = _selectedFilter == logicLabel;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedFilter = logicLabel),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).colorScheme.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ] : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(double percentage, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        '${percentage.toStringAsFixed(0)}%',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color, // Use the category color for text
        ),
      ),
    );
  }
}
