import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'service_providers.dart';

final membersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final api = ref.watch(supabaseServiceProvider);
  return await api.getMembers();
});
