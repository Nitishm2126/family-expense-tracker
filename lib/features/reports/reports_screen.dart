import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/expense_provider.dart';
import '../../providers/income_provider.dart';
import '../../routing/app_router.dart';
import '../dashboard/widgets/category_donut_chart.dart';
import 'widgets/date_range_selector.dart';
import '../../core/widgets/app_footer.dart';

enum ReportRange { daily, weekly, monthly, custom }

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  ReportRange _range = ReportRange.monthly;
  DateTimeRange? _customRange;

  DateTimeRange get _activeRange {
    final now = DateTime.now();
    switch (_range) {
      case ReportRange.daily:
        final start = DateTime(now.year, now.month, now.day);
        return DateTimeRange(start: start, end: start.add(const Duration(days: 1)));
      case ReportRange.weekly:
        final start = now.subtract(Duration(days: now.weekday - 1));
        return DateTimeRange(
          start: DateTime(start.year, start.month, start.day),
          end: now.add(const Duration(days: 1)),
        );
      case ReportRange.monthly:
        return DateTimeRange(start: DateTime(now.year, now.month, 1), end: now.add(const Duration(days: 1)));
      case ReportRange.custom:
        return _customRange ??
            DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now);
    }
  }

  @override
  Widget build(BuildContext context) {
    final expenseState = ref.watch(expenseControllerProvider);
    final incomeState = ref.watch(incomeControllerProvider);
    final range = _activeRange;
    final theme = Theme.of(context);

    final filteredExpenses = expenseState.expenses
        .where((e) => !e.date.isBefore(range.start) && e.date.isBefore(range.end))
        .toList();
    final filteredIncomes = incomeState.incomes
        .where((i) => !i.date.isBefore(range.start) && i.date.isBefore(range.end))
        .toList();

    final totalExpense = filteredExpenses.fold<double>(0, (s, e) => s + e.amount);
    final totalIncome = filteredIncomes.fold<double>(0, (s, i) => s + i.amount);

    final Map<String, double> categoryBreakdown = {};
    for (final e in filteredExpenses) {
      categoryBreakdown[e.category] = (categoryBreakdown[e.category] ?? 0) + e.amount;
    }

    final Map<String, double> memberBreakdown = {
      for (final m in AppConstants.familyMembers) m: 0.0,
    };
    for (final e in filteredExpenses) {
      memberBreakdown[e.member] = (memberBreakdown[e.member] ?? 0) + e.amount;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.people_alt_outlined),
            tooltip: 'Member Wise',
            onPressed: () => context.push(AppRoutes.memberWise),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 24),
        children: [
          DateRangeSelector(
            selected: _range,
            onSelected: (r) => setState(() => _range = r),
            onCustomRangePicked: (dr) => setState(() {
              _range = ReportRange.custom;
              _customRange = dr;
            }),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _SummaryTile(
                  label: 'Total Income',
                  amount: totalIncome,
                  color: AppColors.income,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryTile(
                  label: 'Total Expense',
                  amount: totalExpense,
                  color: AppColors.expense,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SummaryTile(
            label: 'Net Balance',
            amount: totalIncome - totalExpense,
            color: AppColors.primary,
            fullWidth: true,
          ),
          const SizedBox(height: 24),
          if (categoryBreakdown.isNotEmpty) ...[
            Text('Category Wise Summary', style: AppTextStyles.title(theme.colorScheme.onSurface)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(20)),
              child: CategoryDonutChart(data: categoryBreakdown),
            ),
            const SizedBox(height: 24),
          ],
          if (memberBreakdown.isNotEmpty) ...[
            Text('Member Wise Summary', style: AppTextStyles.title(theme.colorScheme.onSurface)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(20)),
              child: Column(
                children: memberBreakdown.entries.map((e) {
                  return ListTile(
                    dense: true,
                    title: Text(e.key, style: AppTextStyles.bodyMedium(theme.colorScheme.onSurface)),
                    trailing: Text(Formatters.currency(e.value), style: AppTextStyles.bodyMedium(AppColors.expense)),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push(AppRoutes.pdfPreview, extra: {
                    'range': range,
                    'expenses': filteredExpenses,
                    'incomes': filteredIncomes,
                    'memberBreakdown': memberBreakdown,
                  }),
                  icon: const Icon(Icons.picture_as_pdf_rounded),
                  label: const Text('Download PDF'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.push(AppRoutes.pdfPreview, extra: {
                    'range': range,
                    'expenses': filteredExpenses,
                    'incomes': filteredIncomes,
                    'memberBreakdown': memberBreakdown,
                    'shareDirectly': true,
                  }),
                  icon: const Icon(Icons.ios_share_rounded),
                  label: const Text('Share Report'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const AppFooter(),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final bool fullWidth;

  const _SummaryTile({
    required this.label,
    required this.amount,
    required this.color,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption(theme.colorScheme.onSurface.withValues(alpha: 0.6))),
          const SizedBox(height: 6),
          Text(Formatters.currency(amount), style: AppTextStyles.amountMedium(color)),
        ],
      ),
    );
  }
}

