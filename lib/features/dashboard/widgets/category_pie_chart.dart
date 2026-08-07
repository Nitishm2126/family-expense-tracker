import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/category_icons.dart';
import '../../../core/utils/formatters.dart';

/// Donut chart showing the current month's expense split by category,
/// with a legend listing each category's share.
class CategoryPieChart extends StatefulWidget {
  final Map<String, double> data;
  const CategoryPieChart({super.key, required this.data});

  @override
  State<CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends State<CategoryPieChart> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final entries = widget.data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = entries.fold<double>(0, (sum, e) => sum + e.value);
    final theme = Theme.of(context);

    return Row(
      children: [
        SizedBox(
          height: 160,
          width: 160,
          child: PieChart(
            PieChartData(
              sectionsSpace: 3,
              centerSpaceRadius: 44,
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  setState(() {
                    _touchedIndex = response?.touchedSection?.touchedSectionIndex;
                  });
                },
              ),
              sections: List.generate(entries.length, (i) {
                final entry = entries[i];
                final isTouched = i == _touchedIndex;
                final color = CategoryIcons.colorFor(entry.key);
                final percent = total == 0 ? 0 : (entry.value / total * 100);
                return PieChartSectionData(
                  color: color,
                  value: entry.value,
                  title: '${percent.toStringAsFixed(0)}%',
                  radius: isTouched ? 42 : 36,
                  titleStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                );
              }),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: entries.take(5).map((entry) {
              final color = CategoryIcons.colorFor(entry.key);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.key,
                        style: AppTextStyles.caption(theme.colorScheme.onSurface),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      Formatters.currency(entry.value),
                      style: AppTextStyles.captionMedium(theme.colorScheme.onSurface),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

