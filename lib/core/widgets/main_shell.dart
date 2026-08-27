import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../../routing/app_router.dart';
import 'glass_navigation_bar.dart';

/// Hosts the four main tabs (Dashboard, Expenses, Income, Reports) with a
/// shared bottom navigation bar and a center-notched FAB for quickly
/// adding an expense — mirroring the Google Pay-style "+" action button.
class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  int _indexForLocation(String location) {
    if (location.startsWith(AppRoutes.expenses)) return 1;
    if (location.startsWith(AppRoutes.income)) return 2;
    if (location.startsWith(AppRoutes.reports)) return 3;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.dashboard);
        break;
      case 1:
        context.go(AppRoutes.expenses);
        break;
      case 2:
        context.go(AppRoutes.income);
        break;
      case 3:
        context.go(AppRoutes.reports);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _indexForLocation(location);

    return Scaffold(
      extendBody: true, // Let content scroll behind the floating bar
      body: child,
      bottomNavigationBar: GlassNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => _onTap(context, index),
        onAddPressed: () => context.push(AppRoutes.addExpense),
      ),
    );
  }
}

