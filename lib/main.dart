import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/services/local_cache_service.dart';
import 'core/theme/app_theme.dart';
import 'providers/settings_provider.dart';
import 'routing/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalCacheService.init();
  runApp(const ProviderScope(child: FamilyExpenseTrackerApp()));
}

class FamilyExpenseTrackerApp extends ConsumerWidget {
  const FamilyExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(settingsControllerProvider).themeMode;

    return MaterialApp.router(
      title: 'Family Expense Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}

