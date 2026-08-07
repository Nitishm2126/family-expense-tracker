import 'expense_model.dart';

/// Aggregated numbers shown at the top of the Dashboard screen.
class DashboardSummaryModel {
  final double totalIncome;
  final double totalExpense;
  final double balance;
  final double todayExpense;
  final double monthExpense;
  final Map<String, double> categoryBreakdown;
  final List<ExpenseModel> recentExpenses;

  const DashboardSummaryModel({
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    required this.todayExpense,
    required this.monthExpense,
    required this.categoryBreakdown,
    required this.recentExpenses,
  });

  factory DashboardSummaryModel.empty() => const DashboardSummaryModel(
        totalIncome: 0,
        totalExpense: 0,
        balance: 0,
        todayExpense: 0,
        monthExpense: 0,
        categoryBreakdown: {},
        recentExpenses: [],
      );

  factory DashboardSummaryModel.fromJson(Map<String, dynamic> json) {
    final Map<String, double> breakdown = {};
    final rawBreakdown = (json['categoryWiseTotals'] ?? json['categoryBreakdown']) as Map<String, dynamic>?;
    if (rawBreakdown != null) {
      rawBreakdown.forEach((key, value) {
        breakdown[key] = double.tryParse(value.toString()) ?? 0.0;
      });
    }

    final List<ExpenseModel> recent = ((json['recentExpenses'] as List?) ?? [])
        .map((e) => ExpenseModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return DashboardSummaryModel(
      totalIncome: double.tryParse(json['totalIncome'].toString()) ?? 0.0,
      totalExpense: double.tryParse(json['totalExpense'].toString()) ?? 0.0,
      balance: double.tryParse(json['balance'].toString()) ?? 0.0,
      todayExpense: double.tryParse(json['todayExpense'].toString()) ?? 0.0,
      monthExpense: double.tryParse((json['thisMonthExpense'] ?? json['monthExpense']).toString()) ?? 0.0,
      categoryBreakdown: breakdown,
      recentExpenses: recent,
    );
  }
}

