import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/local_cache_service.dart';
import '../core/utils/formatters.dart';
import '../models/budget_model.dart';
import 'expense_provider.dart';
import 'service_providers.dart';

class BudgetState {
  final Map<String, double> limits; // category -> monthly limit
  final bool isLoading;
  final String? errorMessage;
  final String selectedMonth; // yyyy-MM

  const BudgetState({
    this.limits = const {},
    this.isLoading = false,
    this.errorMessage,
    required this.selectedMonth,
  });

  BudgetState copyWith({
    Map<String, double>? limits,
    bool? isLoading,
    String? errorMessage,
    String? selectedMonth,
  }) {
    return BudgetState(
      limits: limits ?? this.limits,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      selectedMonth: selectedMonth ?? this.selectedMonth,
    );
  }
}

class BudgetController extends StateNotifier<BudgetState> {
  final Ref ref;
  BudgetController(this.ref)
      : super(BudgetState(selectedMonth: Formatters.monthYear(DateTime.now()))) {
    loadBudgets();
  }

  Future<void> loadBudgets() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final api = ref.read(supabaseServiceProvider);
      final raw = await api.getBudgets(state.selectedMonth);
      final limits = {
        for (final b in raw) 
          (b['categories'] != null && b['categories']['name'] != null 
            ? b['categories']['name'].toString() 
            : (b['category']?.toString() ?? 'Others')): (b['limit'] as num).toDouble()
      };
      state = state.copyWith(limits: limits, isLoading: false);
    } catch (e) {
      // Fallback to cache
      final cached = LocalCacheService.getCachedBudgets();
      final limits = {
        for (final b in cached) b['category'] as String: (b['limit'] as num).toDouble()
      };
      state = state.copyWith(limits: limits, isLoading: false);
    }
  }

  Future<bool> setBudget(String category, double limit) async {
    try {
      final api = ref.read(supabaseServiceProvider);
      await api.setBudget({
        'category': category,
        'limit': limit,
        'month': state.selectedMonth,
      });

      final limits = {...state.limits, category: limit};
      final list = limits.entries
          .map((e) => {'category': e.key, 'limit': e.value})
          .toList();
      await LocalCacheService.cacheBudgets(list);
      state = state.copyWith(limits: limits);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }
}

final budgetControllerProvider =
    StateNotifierProvider<BudgetController, BudgetState>((ref) => BudgetController(ref));

/// Combines the configured limits with actual current-month spend
/// (from the expense provider) into ready-to-render BudgetModels.
final budgetModelsProvider = Provider<List<BudgetModel>>((ref) {
  final budgetState = ref.watch(budgetControllerProvider);
  final expenseState = ref.watch(expenseControllerProvider);
  final now = DateTime.now();
  final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';

  final Map<String, double> spentByCategory = {};
  for (final e in expenseState.expenses) {
    if (e.date.year == now.year && e.date.month == now.month) {
      spentByCategory[e.category] = (spentByCategory[e.category] ?? 0) + e.amount;
    }
  }

  return budgetState.limits.entries.map((entry) {
    return BudgetModel(
      category: entry.key,
      limit: entry.value,
      spent: spentByCategory[entry.key] ?? 0,
      month: monthKey,
    );
  }).toList();
});

