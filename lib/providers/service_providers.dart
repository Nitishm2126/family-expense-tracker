import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/auth_service.dart';
import '../core/services/supabase_service.dart';

/// Root service providers. Everything else (data providers, screen
/// providers) is built on top of these.
final supabaseServiceProvider = Provider<SupabaseService>((ref) => SupabaseService());

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

