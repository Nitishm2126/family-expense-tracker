import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../constants/app_constants.dart';

/// Wraps Hive boxes so the rest of the app can read/write cached
/// expenses, income and budgets without knowing anything about Hive.
///
/// Every list is stored as a JSON string under a single key per box —
/// simple, and avoids needing generated TypeAdapters for our models.
class LocalCacheService {
  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(AppConstants.hiveExpenseBox);
    await Hive.openBox(AppConstants.hiveIncomeBox);
    await Hive.openBox(AppConstants.hiveBudgetBox);
  }

  static Box get _expenseBox => Hive.box(AppConstants.hiveExpenseBox);
  static Box get _incomeBox => Hive.box(AppConstants.hiveIncomeBox);
  static Box get _budgetBox => Hive.box(AppConstants.hiveBudgetBox);

  static const _kList = 'list';
  static const _kLastSync = 'lastSync';

  // ---------------- Expenses ----------------

  static Future<void> cacheExpenses(List<Map<String, dynamic>> expenses) async {
    await _expenseBox.put(_kList, jsonEncode(expenses));
    await _expenseBox.put(_kLastSync, DateTime.now().toIso8601String());
  }

  static List<Map<String, dynamic>> getCachedExpenses() {
    final raw = _expenseBox.get(_kList);
    if (raw == null) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(raw));
  }

  // ---------------- Income ----------------

  static Future<void> cacheIncomes(List<Map<String, dynamic>> incomes) async {
    await _incomeBox.put(_kList, jsonEncode(incomes));
    await _incomeBox.put(_kLastSync, DateTime.now().toIso8601String());
  }

  static List<Map<String, dynamic>> getCachedIncomes() {
    final raw = _incomeBox.get(_kList);
    if (raw == null) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(raw));
  }

  // ---------------- Budgets ----------------

  static Future<void> cacheBudgets(List<Map<String, dynamic>> budgets) async {
    await _budgetBox.put(_kList, jsonEncode(budgets));
  }

  static List<Map<String, dynamic>> getCachedBudgets() {
    final raw = _budgetBox.get(_kList);
    if (raw == null) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(raw));
  }

  static DateTime? get lastExpenseSync {
    final raw = _expenseBox.get(_kLastSync);
    return raw == null ? null : DateTime.tryParse(raw);
  }
}

