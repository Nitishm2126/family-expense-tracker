import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../reports_screen.dart';

/// Segmented control for Daily / Weekly / Monthly / Custom report ranges.
class DateRangeSelector extends StatelessWidget {
  final ReportRange selected;
  final ValueChanged<ReportRange> onSelected;
  final ValueChanged<DateTimeRange> onCustomRangePicked;

  const DateRangeSelector({
    super.key,
    required this.selected,
    required this.onSelected,
    required this.onCustomRangePicked,
  });

  Future<void> _pickCustomRange(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: now,
      initialDateRange: DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) onCustomRangePicked(picked);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final options = {
      ReportRange.daily: 'Daily',
      ReportRange.weekly: 'Weekly',
      ReportRange.monthly: 'Monthly',
      ReportRange.custom: 'Custom',
    };

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: options.entries.map((entry) {
          final isSelected = selected == entry.key;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (entry.key == ReportRange.custom) {
                  _pickCustomRange(context);
                } else {
                  onSelected(entry.key);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(colors: AppColors.primaryGradient)
                      : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  entry.value,
                  style: TextStyle(
                    color: isSelected ? Colors.white : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

