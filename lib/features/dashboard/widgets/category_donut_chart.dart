import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/category_icons.dart';
import '../../../core/utils/formatters.dart';

class CategoryDonutChart extends StatefulWidget {
  final Map<String, double> data;

  const CategoryDonutChart({super.key, required this.data});

  @override
  State<CategoryDonutChart> createState() => _CategoryDonutChartState();
}

class _CategoryDonutChartState extends State<CategoryDonutChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    
    // Sort entries by highest expense first
    final entries = widget.data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
      
    final total = entries.fold<double>(0, (sum, e) => sum + e.value);

    // Get currently selected entry for center display
    final selectedEntry = _touchedIndex >= 0 && _touchedIndex < entries.length 
        ? entries[_touchedIndex] 
        : null;
        
    final selectedPercentage = selectedEntry != null && total > 0 
        ? (selectedEntry.value / total * 100) 
        : 0.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Donut Chart Area
        SizedBox(
          height: 220,
          child: Stack(
            children: [
              PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          _touchedIndex = -1;
                          return;
                        }
                        _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 3,
                  centerSpaceRadius: 65,
                  sections: _showingSections(entries, total),
                ),
                swapAnimationDuration: const Duration(milliseconds: 500),
                swapAnimationCurve: Curves.easeOutCubic,
              ),
              
              // Center Overlay
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      selectedEntry != null ? selectedEntry.key : 'Total Expense',
                      style: AppTextStyles.caption(theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      selectedEntry != null 
                          ? Formatters.currency(selectedEntry.value) 
                          : Formatters.currency(total),
                      style: AppTextStyles.title(theme.colorScheme.onSurface),
                      textAlign: TextAlign.center,
                    ),
                    if (selectedEntry != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${selectedPercentage.toStringAsFixed(1)}%',
                        style: AppTextStyles.captionMedium(CategoryIcons.colorFor(selectedEntry.key)),
                      ),
                    ]
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Clean Legend Below Chart
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: entries.asMap().entries.map((mapEntry) {
            final i = mapEntry.key;
            final entry = mapEntry.value;
            final color = CategoryIcons.colorFor(entry.key);
            final isSelected = i == _touchedIndex;
            
            return InkWell(
              onTap: () {
                setState(() {
                  _touchedIndex = isSelected ? -1 : i;
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Row(
                  children: [
                    // Indicator Dot
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: isSelected ? 14 : 10,
                      height: isSelected ? 14 : 10,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        boxShadow: isSelected 
                            ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 4, spreadRadius: 2)] 
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Category Name
                    Expanded(
                      child: Text(
                        entry.key,
                        style: isSelected
                            ? AppTextStyles.captionMedium(theme.colorScheme.onSurface).copyWith(fontWeight: FontWeight.bold)
                            : AppTextStyles.caption(theme.colorScheme.onSurface),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    // Amount
                    Text(
                      Formatters.currency(entry.value),
                      style: isSelected
                          ? AppTextStyles.captionMedium(theme.colorScheme.onSurface).copyWith(fontWeight: FontWeight.bold)
                          : AppTextStyles.captionMedium(theme.colorScheme.onSurface),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  List<PieChartSectionData> _showingSections(List<MapEntry<String, double>> entries, double total) {
    return List.generate(entries.length, (i) {
      final isTouched = i == _touchedIndex;
      final fontSize = isTouched ? 14.0 : 12.0;
      final radius = isTouched ? 45.0 : 35.0;
      final entry = entries[i];
      final percentage = total == 0 ? 0.0 : (entry.value / total * 100);
      final color = CategoryIcons.colorFor(entry.key);

      return PieChartSectionData(
        color: color,
        value: entry.value,
        title: percentage > 5 ? '${percentage.toStringAsFixed(0)}%' : '',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: const [Shadow(color: Colors.black26, blurRadius: 2)],
        ),
      );
    });
  }
}
