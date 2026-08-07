import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';

class SettingsState {
  final String currency;
  final ThemeMode themeMode;
  final bool reminderEnabled;
  final double budgetAlertThreshold; // 0.0 - 1.0

  const SettingsState({
    this.currency = 'INR (₹)',
    this.themeMode = ThemeMode.light,
    this.reminderEnabled = true,
    this.budgetAlertThreshold = 0.8,
  });

  SettingsState copyWith({
    String? currency,
    ThemeMode? themeMode,
    bool? reminderEnabled,
    double? budgetAlertThreshold,
  }) {
    return SettingsState(
      currency: currency ?? this.currency,
      themeMode: themeMode ?? this.themeMode,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      budgetAlertThreshold: budgetAlertThreshold ?? this.budgetAlertThreshold,
    );
  }
}

/// Persists settings locally with SharedPreferences. These are device
/// preferences (theme, reminder toggle) rather than shared family data,
/// so they intentionally do not sync through the Apps Script backend.
class SettingsController extends StateNotifier<SettingsState> {
  SettingsController() : super(const SettingsState()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final currency = prefs.getString(AppConstants.prefsCurrency) ?? 'INR (₹)';
    final themeStr = prefs.getString(AppConstants.prefsThemeMode) ?? 'light';
    final reminder = prefs.getBool(AppConstants.prefsReminderEnabled) ?? true;
    final threshold = prefs.getDouble(AppConstants.prefsBudgetAlertThreshold) ?? 0.8;

    state = state.copyWith(
      currency: currency,
      themeMode: themeStr == 'dark'
          ? ThemeMode.dark
          : themeStr == 'system'
              ? ThemeMode.system
              : ThemeMode.light,
      reminderEnabled: reminder,
      budgetAlertThreshold: threshold,
    );
  }

  Future<void> setCurrency(String currency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefsCurrency, currency);
    state = state.copyWith(currency: currency);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefsThemeMode, mode.name);
    state = state.copyWith(themeMode: mode);
  }

  Future<void> setReminderEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefsReminderEnabled, enabled);
    state = state.copyWith(reminderEnabled: enabled);
  }

  Future<void> setBudgetAlertThreshold(double threshold) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(AppConstants.prefsBudgetAlertThreshold, threshold);
    state = state.copyWith(budgetAlertThreshold: threshold);
  }
}

final settingsControllerProvider =
    StateNotifierProvider<SettingsController, SettingsState>((ref) => SettingsController());

