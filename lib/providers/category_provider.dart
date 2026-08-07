import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_constants.dart';
import 'service_providers.dart';

final categoriesProvider = FutureProvider<List<String>>((ref) async {
  try {
    final api = ref.watch(apiServiceProvider);
    final raw = await api.getCategories();
    final list = raw
        .map((c) => c['CategoryName']?.toString() ?? '')
        .where((name) => name.isNotEmpty)
        .toList();
    if (list.isEmpty) {
      return AppConstants.expenseCategories;
    }
    return list;
  } catch (_) {
    return AppConstants.expenseCategories;
  }
});

