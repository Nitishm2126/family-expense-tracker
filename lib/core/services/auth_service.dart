import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import 'api_service.dart';

/// Handles the single shared-password login flow plus optional
/// fingerprint/biometric unlock once the password has been verified once
/// on this device (so the family doesn't have to type it every time).
class AuthService {
  final ApiService _apiService;
  final LocalAuthentication _localAuth = LocalAuthentication();

  AuthService(this._apiService);

  String _hash(String value) => sha256.convert(utf8.encode(value)).toString();

  /// Verifies the password against the backend, and on success caches
  /// its hash locally so biometric unlock can work offline afterwards.
  Future<bool> login(String password) async {
    final ok = await _apiService.login(password);
    if (ok) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.prefsPasswordHash, _hash(password));
      await prefs.setBool(AppConstants.prefsIsLoggedIn, true);
    }
    return ok;
  }

  Future<bool> get isBiometricAvailable async {
    try {
      final supported = await _localAuth.isDeviceSupported();
      final canCheck = await _localAuth.canCheckBiometrics;
      return supported && canCheck;
    } catch (_) {
      return false;
    }
  }

  Future<bool> unlockWithBiometrics() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Unlock Family Expense Tracker',
        options: const AuthenticationOptions(biometricOnly: true),
      );
    } catch (_) {
      return false;
    }
  }

  Future<bool> get isLoggedIn async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.prefsIsLoggedIn) ?? false;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefsIsLoggedIn, false);
  }

  Future<bool> changePassword(String oldPassword, String newPassword) async {
    final ok = await _apiService.changePassword(oldPassword, newPassword);
    if (ok) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.prefsPasswordHash, _hash(newPassword));
    }
    return ok;
  }
}

