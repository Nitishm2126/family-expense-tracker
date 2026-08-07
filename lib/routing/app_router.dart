import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/password_screen.dart';
import '../features/budget/budget_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/expense/add_expense_screen.dart';
import '../features/expense/expense_list_screen.dart';
import '../features/income/add_income_screen.dart';
import '../features/income/income_list_screen.dart';
import '../features/member/member_wise_screen.dart';
import '../features/pdf/pdf_preview_screen.dart';
import '../features/reports/reports_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/splash/splash_screen.dart';
import '../core/widgets/main_shell.dart';
import '../providers/auth_provider.dart';

/// Route path constants, kept together to avoid typo'd string literals
/// scattered through screens.
class AppRoutes {
  AppRoutes._();
  static const splash = '/';
  static const login = '/login';
  static const dashboard = '/dashboard';
  static const expenses = '/expenses';
  static const addExpense = '/expenses/add';
  static const income = '/income';
  static const addIncome = '/income/add';
  static const reports = '/reports';
  static const memberWise = '/reports/member-wise';
  static const budget = '/budget';
  static const settings = '/settings';
  static const pdfPreview = '/reports/pdf-preview';
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      final loggingIn = state.matchedLocation == AppRoutes.login;
      final onSplash = state.matchedLocation == AppRoutes.splash;

      if (authState.status == AuthStatus.unknown) {
        return onSplash ? null : AppRoutes.splash;
      }
      if (authState.status == AuthStatus.unauthenticated) {
        return loggingIn ? null : AppRoutes.login;
      }
      // Authenticated
      if (loggingIn || onSplash) return AppRoutes.dashboard;
      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (context, state) => const SplashScreen()),
      GoRoute(path: AppRoutes.login, builder: (context, state) => const PasswordScreen()),
      GoRoute(
        path: AppRoutes.addExpense,
        builder: (context, state) => const AddExpenseScreen(),
      ),
      GoRoute(
        path: AppRoutes.addIncome,
        builder: (context, state) => const AddIncomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.memberWise,
        builder: (context, state) => const MemberWiseScreen(),
      ),
      GoRoute(
        path: AppRoutes.pdfPreview,
        builder: (context, state) => const PdfPreviewScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: AppRoutes.dashboard, builder: (context, state) => const DashboardScreen()),
          GoRoute(path: AppRoutes.expenses, builder: (context, state) => const ExpenseListScreen()),
          GoRoute(path: AppRoutes.income, builder: (context, state) => const IncomeListScreen()),
          GoRoute(path: AppRoutes.reports, builder: (context, state) => const ReportsScreen()),
        ],
      ),
      GoRoute(path: AppRoutes.budget, builder: (context, state) => const BudgetScreen()),
      GoRoute(path: AppRoutes.settings, builder: (context, state) => const SettingsScreen()),
    ],
  );
});

