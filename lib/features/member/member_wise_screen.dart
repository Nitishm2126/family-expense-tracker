import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/member_avatar.dart';
import '../../providers/expense_provider.dart';

/// Shows how much each family member has spent this month, ranked
/// highest to lowest, with a progress bar relative to the top spender.
class MemberWiseScreen extends ConsumerWidget {
  const MemberWiseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenseState = ref.watch(expenseControllerProvider);
    final now = DateTime.now();
    final theme = Theme.of(context);

    final Map<String, double> memberTotals = {
      for (final m in AppConstants.familyMembers) m: 0.0,
    };
    for (final e in expenseState.expenses) {
      if (e.date.year == now.year && e.date.month == now.month) {
        memberTotals[e.member] = (memberTotals[e.member] ?? 0) + e.amount;
      }
    }

    final entries = memberTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxAmount = entries.isEmpty ? 1.0 : (entries.first.value == 0 ? 1.0 : entries.first.value);
    final totalExpense = entries.fold<double>(0, (s, e) => s + e.value);

    return Scaffold(
      appBar: AppBar(title: const Text('Member Wise')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(Formatters.monthYear(now), style: AppTextStyles.caption(theme.colorScheme.onSurface.withValues(alpha: 0.6))),
          const SizedBox(height: 16),
          ...entries.map((entry) {
            final progress = maxAmount == 0 ? 0.0 : entry.value / maxAmount;
            final share = totalExpense == 0 ? 0.0 : entry.value / totalExpense * 100;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      MemberAvatar(name: entry.key, radius: 24),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(entry.key, style: AppTextStyles.bodyMedium(theme.colorScheme.onSurface)),
                            const SizedBox(height: 2),
                            Text('${share.toStringAsFixed(0)}% of total spend',
                                style: AppTextStyles.caption(theme.colorScheme.onSurface.withValues(alpha: 0.55))),
                          ],
                        ),
                      ),
                      Text(
                        Formatters.currency(entry.value),
                        style: AppTextStyles.amountMedium(theme.colorScheme.onSurface),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

