import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/expense_tile.dart';
import '../../core/widgets/gradient_card.dart';
import '../../core/widgets/state_widgets.dart';
import '../../core/widgets/stat_card.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/income_provider.dart';
import '../../routing/app_router.dart';
import '../../core/widgets/app_footer.dart';

import 'widgets/category_donut_chart.dart';
import 'widgets/quick_actions_row.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(dashboardSummaryProvider);
    final isLoading = ref.watch(isDashboardLoadingProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(expenseControllerProvider.notifier).loadExpenses();
          await ref.read(incomeControllerProvider.notifier).loadIncomes();
        },
        child: (isLoading && summary.recentExpenses.isEmpty)
            ? const ShimmerList()
            : ListView(
                padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 24),
                children: [
                  GradientCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total Balance',
                            style: AppTextStyles.body(Colors.white.withValues(alpha: 0.85))),
                        const SizedBox(height: 6),
                        Text(
                          Formatters.currency(summary.balance),
                          style: AppTextStyles.displayLarge(Colors.white).copyWith(fontSize: 34),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: _HeroMetric(
                                label: 'Income',
                                amount: summary.totalIncome,
                                icon: Icons.arrow_downward_rounded,
                              ),
                            ),
                            Container(width: 1, height: 32, color: Colors.white24),
                            Expanded(
                              child: _HeroMetric(
                                label: 'Expense',
                                amount: summary.totalExpense,
                                icon: Icons.arrow_upward_rounded,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          label: "Today's Expense",
                          amount: summary.todayExpense,
                          icon: Icons.today_rounded,
                          accentColor: AppColors.expense,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          label: 'This Month',
                          amount: summary.monthExpense,
                          icon: Icons.calendar_month_rounded,
                          accentColor: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const QuickActionsRow(),
                  const SizedBox(height: 24),
                  if (summary.categoryBreakdown.isNotEmpty) ...[
                    Text('Category Wise Expense', style: AppTextStyles.title(theme.colorScheme.onSurface)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: CategoryDonutChart(data: summary.categoryBreakdown),
                    ),
                    const SizedBox(height: 24),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Recent Expenses', style: AppTextStyles.title(theme.colorScheme.onSurface)),
                      TextButton(
                        onPressed: () => context.go(AppRoutes.expenses),
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: summary.recentExpenses.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(24),
                            child: EmptyStateWidget(
                              icon: Icons.receipt_long_rounded,
                              title: 'No expenses yet',
                              subtitle: 'Tap the + button to add your first expense.',
                            ),
                          )
                        : Column(
                            children: summary.recentExpenses
                                .map((e) => ExpenseTile(expense: e))
                                .toList(),
                          ),
                  ),
                  const AppFooter(),
                ],
              ),

      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  final String label;
  final double amount;
  final IconData icon;

  const _HeroMetric({required this.label, required this.amount, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.caption(Colors.white.withValues(alpha: 0.8))),
              Text(
                Formatters.currency(amount),
                style: AppTextStyles.amountMedium(Colors.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

