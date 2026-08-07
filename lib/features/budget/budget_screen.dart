import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/state_widgets.dart';
import '../../models/budget_model.dart';
import '../../providers/budget_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/settings_provider.dart';

class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  Color _statusColor(BudgetModel budget, double warnThreshold) {
    if (budget.isOverBudget) return AppColors.danger;
    if (budget.isNearLimit(warnThreshold)) return AppColors.warning;
    return AppColors.income;
  }

  void _openSetBudgetSheet(BuildContext context, WidgetRef ref, {String? existingCategory, double? existingLimit}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _SetBudgetSheet(existingCategory: existingCategory, existingLimit: existingLimit),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgets = ref.watch(budgetModelsProvider);
    final budgetState = ref.watch(budgetControllerProvider);
    final settings = ref.watch(settingsControllerProvider);
    final theme = Theme.of(context);

    final totalLimit = budgets.fold<double>(0, (s, b) => s + b.limit);
    final totalSpent = budgets.fold<double>(0, (s, b) => s + b.spent);

    return Scaffold(
      appBar: AppBar(
        title: Text(Formatters.monthYear(DateTime.now())),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openSetBudgetSheet(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Set Budget'),
      ),
      body: budgetState.isLoading && budgets.isEmpty
          ? const ShimmerList()
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              children: [
                if (totalLimit > 0)
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Overall Monthly Budget',
                            style: AppTextStyles.captionMedium(theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(Formatters.currency(totalSpent), style: AppTextStyles.amountLarge(theme.colorScheme.onSurface)),
                            const SizedBox(width: 6),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text('/ ${Formatters.currency(totalLimit)}',
                                  style: AppTextStyles.body(theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: totalLimit == 0 ? 0 : (totalSpent / totalLimit).clamp(0.0, 1.0),
                            minHeight: 10,
                            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                            valueColor: AlwaysStoppedAnimation(
                              totalSpent > totalLimit ? AppColors.danger : AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
                Text('Category Budgets', style: AppTextStyles.title(theme.colorScheme.onSurface)),
                const SizedBox(height: 12),
                if (budgets.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: EmptyStateWidget(
                      icon: Icons.pie_chart_outline_rounded,
                      title: 'No budgets set',
                      subtitle: 'Tap "Set Budget" to define a monthly limit for a category.',
                    ),
                  )
                else
                  ...budgets.map((budget) {
                    final color = _statusColor(budget, settings.budgetAlertThreshold);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: InkWell(
                        onTap: () => _openSetBudgetSheet(
                          context,
                          ref,
                          existingCategory: budget.category,
                          existingLimit: budget.limit,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(budget.category, style: AppTextStyles.bodyMedium(theme.colorScheme.onSurface)),
                                Text(
                                  '${Formatters.currency(budget.spent)} / ${Formatters.currency(budget.limit)}',
                                  style: AppTextStyles.captionMedium(theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: budget.progress.clamp(0.0, 1.0),
                                minHeight: 8,
                                backgroundColor: color.withValues(alpha: 0.1),
                                valueColor: AlwaysStoppedAnimation(color),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              budget.isOverBudget
                                  ? 'Over budget by ${Formatters.currency(budget.spent - budget.limit)}'
                                  : 'Remaining: ${Formatters.currency(budget.remaining)}',
                              style: AppTextStyles.caption(color),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
    );
  }
}

class _SetBudgetSheet extends ConsumerStatefulWidget {
  final String? existingCategory;
  final double? existingLimit;

  const _SetBudgetSheet({this.existingCategory, this.existingLimit});

  @override
  ConsumerState<_SetBudgetSheet> createState() => _SetBudgetSheetState();
}

class _SetBudgetSheetState extends ConsumerState<_SetBudgetSheet> {
  String? _category;
  late final _limitController =
      TextEditingController(text: widget.existingLimit?.toStringAsFixed(0) ?? '');
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _category = widget.existingCategory;
  }

  Future<void> _save() async {
    final categories = ref.read(categoriesProvider).value ?? AppConstants.expenseCategories;
    final categoryToSave = _category ?? (categories.isNotEmpty ? categories.first : '');
    final limit = double.tryParse(_limitController.text.trim());
    if (limit == null || limit <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid budget amount')),
      );
      return;
    }
    setState(() => _isSaving = true);
    final ok = await ref.read(budgetControllerProvider.notifier).setBudget(categoryToSave, limit);
    if (!mounted) return;
    setState(() => _isSaving = false);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Budget saved' : 'Failed to save budget')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider).value ?? AppConstants.expenseCategories;
    final selectedCategory = _category ?? (categories.isNotEmpty ? categories.first : '');

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Set Budget', style: AppTextStyles.title(Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: selectedCategory.isNotEmpty ? selectedCategory : null,
            items: categories
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: widget.existingCategory != null
                ? null
                : (v) => setState(() => _category = v),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _limitController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(hintText: 'Monthly limit amount'),
          ),
          const SizedBox(height: 20),
          PrimaryButton(label: 'Save Budget', isLoading: _isSaving, onPressed: _save),
        ],
      ),
    );
  }
}

