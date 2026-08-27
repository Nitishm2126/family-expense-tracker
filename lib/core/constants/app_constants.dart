/// Central place for every constant used across the app.
/// Keeping these here means no magic strings scattered through the codebase.
class AppConstants {
  AppConstants._();

  static const String appName = 'Family Expense Tracker';
  static const String appTagline = 'Track Together, Save Together';

  /// The four members who share this single-household app.
  /// No per-user accounts — everyone sees and edits everything.
  static const List<String> familyMembers = [
    'T. Meenakshi Sundaran',
    'Maheswari',
    'Nitish',
    'Shenbahaa',
  ];

  static const List<String> expenseCategories = [
    'Grocery',
    'Food',
    'Transport',
    'Medical',
    'Utilities',
    'Education',
    'Entertainment',
    'Shopping',
    'Rent',
    'Recharge',
    'Petrol',
    'Others',
  ];

  static const List<String> incomeSources = [
    'Salary',
    'Business',
    'Freelance',
    'Rental',
    'Interest',
    'Gift',
    'Others',
  ];

  static const List<String> paymentModes = [
    'Cash',
    'UPI',
    'Bank Transfer',
    'Debit Card',
    'Credit Card',
    'Cheque',
  ];

  static const List<String> currencies = ['INR (₹)', 'USD (\$)', 'EUR (€)'];

  // Local cache / storage keys
  static const String hiveExpenseBox = 'expense_box';
  static const String hiveIncomeBox = 'income_box';
  static const String hiveBudgetBox = 'budget_box';
  static const String prefsPasswordHash = 'family_password_hash';
  static const String prefsIsLoggedIn = 'is_logged_in';
  static const String prefsCurrency = 'selected_currency';
  static const String prefsThemeMode = 'theme_mode';
  static const String prefsReminderEnabled = 'reminder_enabled';
  static const String prefsBudgetAlertThreshold = 'budget_alert_threshold';
  
  static const String prefsGlassTransparency = 'glass_transparency';
  static const String prefsGlassBlur = 'glass_blur';
  static const String prefsGlassBorderEnabled = 'glass_border_enabled';
  static const String prefsGlassShadowEnabled = 'glass_shadow_enabled';

  // Category icon/color mapping keys are handled in app_icons.dart
}

