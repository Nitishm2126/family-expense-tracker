import 'package:flutter/material.dart';
import '../../models/expense_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/category_icons.dart';
import '../utils/formatters.dart';

/// A single expense row, swipeable to reveal edit/delete, used in both
/// the Dashboard's "Recent Expenses" list and the full Expense List screen.
class ExpenseTile extends StatelessWidget {
  final ExpenseModel expense;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const ExpenseTile({
    super.key,
    required this.expense,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = CategoryIcons.colorFor(expense.category);
    final tile = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(CategoryIcons.expenseIcon(expense.category), color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.description.isNotEmpty ? expense.description : expense.category,
                    style: AppTextStyles.bodyMedium(theme.colorScheme.onSurface),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${expense.member} · ${Formatters.relativeDay(expense.date)}',
                    style: AppTextStyles.caption(theme.colorScheme.onSurface.withValues(alpha: 0.55)),
                  ),
                ],
              ),
            ),
            Text(
              '- ${Formatters.currency(expense.amount)}',
              style: AppTextStyles.bodyMedium(AppColors.expense),
            ),
          ],
        ),
      ),
    );

    if (onDelete == null) return tile;

    return Dismissible(
      key: ValueKey(expense.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onDelete?.call();
        return false; // parent handles removal after confirm dialog + API call
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
      child: tile,
    );
  }
}

