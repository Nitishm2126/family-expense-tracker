/// Google Apps Script backend configuration.
///
/// Deploy your Apps Script project as a Web App (Execute as: Me,
/// Who has access: Anyone with the link) and paste the /exec URL below.
/// Keeping it isolated here means redeploying the script only requires
/// changing one line, never hunting through the codebase.
class ApiConfig {
  ApiConfig._();

  /// Replace with your deployed Apps Script Web App URL, e.g.:
  /// https://script.google.com/macros/s/AKfycbXXXXXXXXXXXXXXXXXX/exec
  static const String baseUrl =
      'https://script.google.com/macros/s/AKfycbzFjufgDACateagI5E0aWXdm6_8J4MUYtYb4mGefaZL_gGf6Um8xuUI6jot9aBo/exec';

  static const Duration requestTimeout = Duration(seconds: 20);

  // Action query params — the Apps Script doGet/doPost dispatches on `action`.
  static const String actionLogin = 'login';
  static const String actionChangePassword = 'changePassword';

  static const String actionGetExpenses = 'getExpenses';
  static const String actionAddExpense = 'addExpense';
  static const String actionUpdateExpense = 'updateExpense';
  static const String actionDeleteExpense = 'deleteExpense';

  static const String actionGetIncomes = 'getIncome';
  static const String actionAddIncome = 'addIncome';
  static const String actionUpdateIncome = 'updateIncome';
  static const String actionDeleteIncome = 'deleteIncome';

  static const String actionGetDashboard = 'getDashboard';
  static const String actionGetBudgets = 'getBudgets';
  static const String actionSetBudget = 'setBudget';
  static const String actionGetSettings = 'getSettings';
  static const String actionUpdateSettings = 'updateSettings';
}

