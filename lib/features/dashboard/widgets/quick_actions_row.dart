import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../routing/app_router.dart';

/// Row of shortcut actions shown on the dashboard, mirroring the
/// "Quick Actions" section of the reference layout.
class QuickActionsRow extends StatelessWidget {
  const QuickActionsRow({super.key});

  @override
  Widget build(BuildContext context) {
    final actions = [
      (Icons.add_shopping_cart_rounded, 'Expense', AppColors.expense,
          () => context.push(AppRoutes.addExpense)),
      (Icons.savings_rounded, 'Income', AppColors.income,
          () => context.push(AppRoutes.addIncome)),
      (Icons.pie_chart_rounded, 'Budget', AppColors.warning,
          () => context.push(AppRoutes.budget)),
      (Icons.picture_as_pdf_rounded, 'Reports', AppColors.info,
          () => context.go(AppRoutes.reports)),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: actions.map((a) {
        final (icon, label, color, onTap) = a;
        return _QuickAction(icon: icon, label: label, color: color, onTap: onTap);
      }).toList(),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(label, style: AppTextStyles.caption(theme.colorScheme.onSurface.withOpacity(0.75))),
        ],
      ),
    );
  }
}
