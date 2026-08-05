import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../core/services/local_cache_service.dart';
import '../models/expense_model.dart';
import 'dashboard_provider.dart';
import 'service_providers.dart';

class ExpenseState {
  final List<ExpenseModel> expenses;
  final bool isLoading;
  final String? errorMessage;

  const ExpenseState({
    this.expenses = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  ExpenseState copyWith({
    List<ExpenseModel>? expenses,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ExpenseState(
      expenses: expenses ?? this.expenses,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  double get total => expenses.fold(0.0, (sum, e) => sum + e.amount);
}

class ExpenseController extends StateNotifier<ExpenseState> {
  final Ref ref;
  ExpenseController(this.ref) : super(const ExpenseState()) {
    loadExpenses();
  }

  Future<void> loadExpenses({bool forceRefresh = false}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    // Show cached data immediately so the list never looks empty while
    // the network call is in flight (offline-first UX).
    final cached = LocalCacheService.getCachedExpenses();
    if (cached.isNotEmpty) {
      state = state.copyWith(
        expenses: cached.map(ExpenseModel.fromJson).toList()
          ..sort((a, b) => b.date.compareTo(a.date)),
      );
    }

    try {
      final api = ref.read(apiServiceProvider);
      final raw = await api.getExpenses();
      await LocalCacheService.cacheExpenses(raw);
      final list = raw.map(ExpenseModel.fromJson).toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      state = state.copyWith(expenses: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: cached.isEmpty ? e.toString() : null,
      );
    }
  }

  Future<bool> addExpense({
    required String member,
    required String category,
    required String description,
    required double amount,
    required String paymentMode,
    required DateTime date,
    required String time,
    required String remarks,
  }) async {
    // Build expense with a temp local ID first.
    final localId = const Uuid().v4();
    final expense = ExpenseModel(
      id: localId,
      member: member,
      category: category,
      description: description,
      amount: amount,
      paymentMode: paymentMode,
      date: date,
      time: time,
      remarks: remarks,
      createdAt: DateTime.now(),
    );
    try {
      final api = ref.read(apiServiceProvider);
      final serverData = await api.addExpense(expense.toJson());
      // Use backend-assigned ID if available.
      final serverId = serverData['Id']?.toString() ?? serverData['id']?.toString() ?? localId;
      final savedExpense = expense.copyWith(id: serverId);
      // Reload from backend so list reflects exactly what the server has.
      await loadExpenses();
      ref.read(dashboardControllerProvider.notifier).loadDashboard();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> updateExpense(ExpenseModel updated) async {
    try {
      final api = ref.read(apiServiceProvider);
      await api.updateExpense(updated.id, updated.toJson());
      // Reload from backend to reflect real state.
      await loadExpenses();
      ref.read(dashboardControllerProvider.notifier).loadDashboard();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> deleteExpense(String id) async {
    final previous = state.expenses;
    // Optimistically remove from local list.
    state = state.copyWith(expenses: previous.where((e) => e.id != id).toList());
    try {
      final api = ref.read(apiServiceProvider);
      await api.deleteExpense(id);
      // Reload from backend to confirm deletion.
      await loadExpenses();
      ref.read(dashboardControllerProvider.notifier).loadDashboard();
      return true;
    } catch (e) {
      // Restore on error.
      state = state.copyWith(expenses: previous, errorMessage: e.toString());
      return false;
    }
  }
}

final expenseControllerProvider =
    StateNotifierProvider<ExpenseController, ExpenseState>((ref) => ExpenseController(ref));
