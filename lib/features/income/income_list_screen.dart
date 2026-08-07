import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/category_icons.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/state_widgets.dart';
import '../../models/income_model.dart';
import '../../providers/income_provider.dart';
import 'edit_income_sheet.dart';

class IncomeListScreen extends ConsumerStatefulWidget {
  const IncomeListScreen({super.key});

  @override
  ConsumerState<IncomeListScreen> createState() => _IncomeListScreenState();
}

class _IncomeListScreenState extends ConsumerState<IncomeListScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  Future<void> _confirmDelete(IncomeModel income) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete Income',
      message: 'Delete this ${income.source} entry? This cannot be undone.',
      confirmLabel: 'Delete',
    );
    if (confirmed) {
      final ok = await ref.read(incomeControllerProvider.notifier).deleteIncome(income.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ok ? 'Income deleted' : 'Failed to delete income')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(incomeControllerProvider);
    final filtered = state.incomes.where((i) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return i.description.toLowerCase().contains(q) ||
          i.source.toLowerCase().contains(q) ||
          i.receivedBy.toLowerCase().contains(q);
    }).toList();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Income')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Search income...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Income',
                    style: AppTextStyles.caption(theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                Text(Formatters.currency(state.total),
                    style: AppTextStyles.bodyMedium(AppColors.income)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(incomeControllerProvider.notifier).loadIncomes(),
              child: state.isLoading && state.incomes.isEmpty
                  ? const ShimmerList()
                  : filtered.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 80),
                            EmptyStateWidget(
                              icon: Icons.savings_outlined,
                              title: 'No income recorded',
                              subtitle: 'Tap "Add Income" to log your first entry.',
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final income = filtered[index];
                            final color = CategoryIcons.colorFor(income.source);
                            return Dismissible(
                              key: ValueKey(income.id),
                              direction: DismissDirection.endToStart,
                              confirmDismiss: (_) async {
                                _confirmDelete(income);
                                return false;
                              },
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                decoration: BoxDecoration(
                                  color: AppColors.danger.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(Icons.delete_rounded, color: AppColors.danger),
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: theme.cardColor,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: InkWell(
                                  onTap: () => showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                                    ),
                                    builder: (_) => EditIncomeSheet(income: income),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: color.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: Icon(
                                          CategoryIcons.incomeIcon(income.source),
                                          color: color,
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              income.description.isNotEmpty
                                                  ? income.description
                                                  : income.source,
                                              style: AppTextStyles.bodyMedium(theme.colorScheme.onSurface),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${income.receivedBy} · ${Formatters.relativeDay(income.date)}',
                                              style: AppTextStyles.caption(
                                                  theme.colorScheme.onSurface.withValues(alpha: 0.55)),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        '+ ${Formatters.currency(income.amount)}',
                                        style: AppTextStyles.bodyMedium(AppColors.income),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }
}

