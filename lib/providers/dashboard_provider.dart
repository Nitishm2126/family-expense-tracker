import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dashboard_summary_model.dart';
import '../models/expense_model.dart';
import 'expense_provider.dart';
import 'income_provider.dart';

class DashboardState {
  final DashboardSummaryModel summary;
  final bool isLoading;
  final String? errorMessage;

  const DashboardState({
    required this.summary,
    this.isLoading = false,
    this.errorMessage,
  });
}

class DashboardController extends StateNotifier<DashboardState> {
  DashboardController() : super(DashboardState(summary: DashboardSummaryModel.empty()));

  // Kept as a no-op just in case it's called anywhere else (e.g. pull to refresh)
  Future<void> loadDashboard() async {}
}

final dashboardControllerProvider =
    StateNotifierProvider<DashboardController, DashboardState>((ref) {
  return DashboardController();
});

final dashboardSummaryProvider = Provider<DashboardSummaryModel>((ref) {
  final expenses = ref.watch(expenseControllerProvider).expenses;
  final incomes = ref.watch(incomeControllerProvider).incomes;

  double totalExpense = 0;
  double todayExpense = 0;
  double monthExpense = 0;
  double totalIncome = 0;
  Map<String, double> categoryBreakdown = {};

  final now = DateTime.now();

  for (final e in expenses) {
    totalExpense += e.amount;
    
    // Today
    if (e.date.year == now.year && e.date.month == now.month && e.date.day == now.day) {
      todayExpense += e.amount;
    }

    // Month
    if (e.date.year == now.year && e.date.month == now.month) {
      monthExpense += e.amount;
    }

    // Category breakdown
    final cat = e.category ?? 'Uncategorized';
    categoryBreakdown[cat] = (categoryBreakdown[cat] ?? 0) + e.amount;
  }

  for (final inc in incomes) {
    totalIncome += inc.amount;
  }

  // top 5 recent expenses (assuming expenses is already sorted by date descending)
  final topRecent = expenses.take(5).toList();

  return DashboardSummaryModel(
    totalIncome: totalIncome,
    totalExpense: totalExpense,
    balance: totalIncome - totalExpense,
    todayExpense: todayExpense,
    monthExpense: monthExpense,
    categoryBreakdown: categoryBreakdown,
    recentExpenses: topRecent,
  );
});

final isDashboardLoadingProvider = Provider<bool>((ref) {
  final isExpensesLoading = ref.watch(expenseControllerProvider).isLoading;
  final isIncomesLoading = ref.watch(incomeControllerProvider).isLoading;
  return isExpensesLoading || isIncomesLoading;
});

