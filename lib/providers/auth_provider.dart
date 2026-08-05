import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'service_providers.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final bool isLoading;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.isLoading = false,
    this.errorMessage,
  });

  AuthState copyWith({AuthStatus? status, bool? isLoading, String? errorMessage}) {
    return AuthState(
      status: status ?? this.status,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

/// Drives the Password screen and the router's redirect logic.
class AuthController extends StateNotifier<AuthState> {
  final Ref ref;
  AuthController(this.ref) : super(const AuthState()) {
    _checkExistingSession();
  }

  Future<void> _checkExistingSession() async {
    final auth = ref.read(authServiceProvider);
    final loggedIn = await auth.isLoggedIn;
    state = state.copyWith(
      status: loggedIn ? AuthStatus.authenticated : AuthStatus.unauthenticated,
    );
  }

  Future<void> login(String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final auth = ref.read(authServiceProvider);
      final success = await auth.login(password);
      if (success) {
        state = state.copyWith(isLoading: false, status: AuthStatus.authenticated);
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Incorrect password. Please try again.',
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> loginWithBiometrics() async {
    final auth = ref.read(authServiceProvider);
    final ok = await auth.unlockWithBiometrics();
    if (ok) {
      state = state.copyWith(status: AuthStatus.authenticated);
    }
  }

  Future<void> logout() async {
    final auth = ref.read(authServiceProvider);
    await auth.logout();
    state = state.copyWith(status: AuthStatus.unauthenticated);
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) => AuthController(ref));
