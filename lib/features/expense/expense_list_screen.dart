import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/expense_tile.dart';
import '../../core/widgets/state_widgets.dart';
import '../../models/expense_model.dart';
import '../../providers/category_provider.dart';
import '../../providers/expense_provider.dart';
import 'edit_expense_sheet.dart';
import '../../core/widgets/app_footer.dart';

enum ExpenseSort { newest, oldest, highest, lowest }

class ExpenseListScreen extends ConsumerStatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  ConsumerState<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends ConsumerState<ExpenseListScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _categoryFilter;
  String? _memberFilter;
  ExpenseSort _sort = ExpenseSort.newest;

  List<ExpenseModel> _applyFilters(List<ExpenseModel> expenses) {
    var list = expenses.where((e) {
      final matchesQuery = _query.isEmpty ||
          e.description.toLowerCase().contains(_query.toLowerCase()) ||
          e.category.toLowerCase().contains(_query.toLowerCase()) ||
          e.member.toLowerCase().contains(_query.toLowerCase());
      final matchesCategory = _categoryFilter == null || e.category == _categoryFilter;
      final matchesMember = _memberFilter == null || e.member == _memberFilter;
      return matchesQuery && matchesCategory && matchesMember;
    }).toList();

    switch (_sort) {
      case ExpenseSort.newest:
        list.sort((a, b) => b.date.compareTo(a.date));
        break;
      case ExpenseSort.oldest:
        list.sort((a, b) => a.date.compareTo(b.date));
        break;
      case ExpenseSort.highest:
        list.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case ExpenseSort.lowest:
        list.sort((a, b) => a.amount.compareTo(b.amount));
        break;
    }
    return list;
  }

  void _openFilterSheet(List<String> categories) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _FilterSortSheet(
        categoryFilter: _categoryFilter,
        memberFilter: _memberFilter,
        sort: _sort,
        categories: categories,
        onApply: (category, member, sort) {
          setState(() {
            _categoryFilter = category;
            _memberFilter = member;
            _sort = sort;
          });
        },
      ),
    );
  }

  Future<void> _confirmDelete(ExpenseModel expense) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete Expense',
      message: 'Delete "${expense.description.isEmpty ? expense.category : expense.description}"? This cannot be undone.',
      confirmLabel: 'Delete',
    );
    if (confirmed) {
      final ok = await ref.read(expenseControllerProvider.notifier).deleteExpense(expense.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ok ? 'Expense deleted' : 'Failed to delete expense')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(expenseControllerProvider);
    final filtered = _applyFilters(state.expenses);
    final total = filtered.fold<double>(0, (sum, e) => sum + e.amount);
    final theme = Theme.of(context);
    final categories = ref.watch(categoriesProvider).value ?? AppConstants.expenseCategories;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: () => _openFilterSheet(categories),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Search expenses...',
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
                Text('${filtered.length} transactions',
                    style: AppTextStyles.caption(theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                Text('Total: ${Formatters.currency(total)}',
                    style: AppTextStyles.bodyMedium(AppColors.expense)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(expenseControllerProvider.notifier).loadExpenses(),
              child: state.isLoading && state.expenses.isEmpty
                  ? const ShimmerList()
                  : filtered.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 80),
                            EmptyStateWidget(
                              icon: Icons.search_off_rounded,
                              title: 'No expenses found',
                              subtitle: 'Try adjusting your search or filters.',
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(context).padding.bottom + 24),
                          itemCount: filtered.length + 1,
                          separatorBuilder: (_, __) => const SizedBox(height: 4),
                          itemBuilder: (context, index) {
                            if (index == filtered.length) {
                              return const AppFooter();
                            }
                            final expense = filtered[index];
                            return ExpenseTile(
                              expense: expense,
                              onTap: () => showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                                ),
                                builder: (_) => EditExpenseSheet(expense: expense),
                              ),
                              onDelete: () => _confirmDelete(expense),
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

class _FilterSortSheet extends StatefulWidget {
  final String? categoryFilter;
  final String? memberFilter;
  final ExpenseSort sort;
  final List<String> categories;
  final void Function(String? category, String? member, ExpenseSort sort) onApply;

  const _FilterSortSheet({
    required this.categoryFilter,
    required this.memberFilter,
    required this.sort,
    required this.categories,
    required this.onApply,
  });

  @override
  State<_FilterSortSheet> createState() => _FilterSortSheetState();
}

class _FilterSortSheetState extends State<_FilterSortSheet> {
  late String? _category = widget.categoryFilter;
  late String? _member = widget.memberFilter;
  late ExpenseSort _sort = widget.sort;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: math.max(MediaQuery.of(context).viewInsets.bottom, MediaQuery.of(context).padding.bottom) + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Filter & Sort', style: AppTextStyles.title(Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 16),
          Text('Category', style: AppTextStyles.captionMedium(Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('All'),
                selected: _category == null,
                onSelected: (_) => setState(() => _category = null),
              ),
              ...widget.categories.map((c) => ChoiceChip(
                    label: Text(c),
                    selected: _category == c,
                    onSelected: (_) => setState(() => _category = c),
                  )),
            ],
          ),
          const SizedBox(height: 16),
          Text('Member', style: AppTextStyles.captionMedium(Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('All'),
                selected: _member == null,
                onSelected: (_) => setState(() => _member = null),
              ),
              ...AppConstants.familyMembers.map((m) => ChoiceChip(
                    label: Text(m),
                    selected: _member == m,
                    onSelected: (_) => setState(() => _member = m),
                  )),
            ],
          ),
          const SizedBox(height: 16),
          Text('Sort By', style: AppTextStyles.captionMedium(Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Newest'),
                selected: _sort == ExpenseSort.newest,
                onSelected: (_) => setState(() => _sort = ExpenseSort.newest),
              ),
              ChoiceChip(
                label: const Text('Oldest'),
                selected: _sort == ExpenseSort.oldest,
                onSelected: (_) => setState(() => _sort = ExpenseSort.oldest),
              ),
              ChoiceChip(
                label: const Text('Highest'),
                selected: _sort == ExpenseSort.highest,
                onSelected: (_) => setState(() => _sort = ExpenseSort.highest),
              ),
              ChoiceChip(
                label: const Text('Lowest'),
                selected: _sort == ExpenseSort.lowest,
                onSelected: (_) => setState(() => _sort = ExpenseSort.lowest),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onApply(_category, _member, _sort);
                Navigator.pop(context);
              },
              child: const Text('Apply'),
            ),
          ),
        ],
      ),
    );
  }
}

