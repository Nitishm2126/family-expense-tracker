import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_config.dart';

/// Thin, typed wrapper around every HTTP call this app makes.
///
/// Google Apps Script Web Apps redirect POST responses (302) to a
/// script.googleusercontent.com URL. The Dart `http` package does NOT
/// follow redirects for POST automatically, so we extract the `Location`
/// header and perform a follow-up GET to retrieve the actual JSON body.
class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class ApiService {
  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  Uri _buildUri(String action, [Map<String, String>? extraParams]) {
    final params = {'action': action, ...?extraParams};
    return Uri.parse(ApiConfig.baseUrl).replace(queryParameters: params);
  }

  /// GET requests are used for all read operations.
  Future<Map<String, dynamic>> _get(
    String action, {
    Map<String, String>? params,
  }) async {
    try {
      final uri = _buildUri(action, params);
      print('GET $uri');
      final response = await _client.get(uri).timeout(ApiConfig.requestTimeout);
      print('GET Response [${response.statusCode}]: ${response.body.length > 300 ? response.body.substring(0, 300) : response.body}');
      return _decode(response);
    } catch (e) {
      print('GET Error: $e');
      throw ApiException(_friendlyError(e));
    }
  }

  /// POST requests to Google Apps Script.
  /// GAS always responds with a 302 redirect to script.googleusercontent.com
  /// which contains the actual JSON body. We follow that redirect manually.
  Future<Map<String, dynamic>> _post(
    String action,
    Map<String, dynamic> body,
  ) async {
    final payload = {'action': action, ...body};
    final uri = Uri.parse(ApiConfig.baseUrl);

    print('POST $uri');
    print('POST BODY: ${jsonEncode(payload)}');

    try {
      // Step 1: Send POST, do NOT follow redirects automatically.
      final response = await _client.post(
        uri,
        headers: {'Content-Type': 'text/plain'},
        body: jsonEncode(payload),
      ).timeout(ApiConfig.requestTimeout);

      print('POST initial status: ${response.statusCode}');

      // Step 2: GAS returns 302. Follow the redirect manually with a GET.
      if (response.statusCode == 302) {
        final location = response.headers['location'];
        print('POST redirect location: $location');
        if (location == null || location.isEmpty) {
          throw ApiException('Redirect location missing from server response.');
        }
        final redirectResponse = await _client
            .get(Uri.parse(location))
            .timeout(ApiConfig.requestTimeout);
        print('POST redirect response [${redirectResponse.statusCode}]: ${redirectResponse.body}');
        return _decode(redirectResponse);
      }

      // Step 3: If not a redirect (e.g. direct 200), decode normally.
      print('POST direct response [${response.statusCode}]: ${response.body}');
      return _decode(response);
    } catch (e) {
      print('POST Error: $e');
      throw ApiException(_friendlyError(e));
    }
  }

  Map<String, dynamic> _decode(http.Response response) {
    if (response.statusCode != 200) {
      throw ApiException(
          'Server error (${response.statusCode}). Please try again.');
    }
    try {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      if (decoded['status'] == false) {
        throw ApiException(
            decoded['message']?.toString() ?? 'Request failed.');
      }
      return decoded;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Could not parse server response. Please try again.');
    }
  }

  String _friendlyError(Object e) {
    if (e is ApiException) return e.message;
    final msg = e.toString();
    if (msg.contains('TimeoutException')) {
      return 'The request timed out. Check your internet connection.';
    }
    if (msg.contains('SocketException')) {
      return 'No internet connection. Showing cached data where available.';
    }
    if (msg.contains('XMLHttpRequest')) {
      return 'CORS error on web. Please check your backend configuration.';
    }
    return 'Something went wrong. Please try again.';
  }

  // ---------------- Auth ----------------

  Future<bool> login(String password) async {
    final res = await _post(ApiConfig.actionLogin, {'password': password});
    return res['status'] == true;
  }

  Future<bool> changePassword(String oldPassword, String newPassword) async {
    try {
      final res = await _post(ApiConfig.actionChangePassword, {
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      });
      return res['status'] == true;
    } catch (e) {
      return false;
    }
  }

  // ---------------- Expenses ----------------

  Future<List<Map<String, dynamic>>> getExpenses({
    String? from,
    String? to,
  }) async {
    final res = await _get(ApiConfig.actionGetExpenses, params: {
      if (from != null) 'from': from,
      if (to != null) 'to': to,
    });
    return List<Map<String, dynamic>>.from(res['data'] ?? []);
  }

  Future<Map<String, dynamic>> addExpense(Map<String, dynamic> expense) async {
    final res = await _post(ApiConfig.actionAddExpense, expense);
    return Map<String, dynamic>.from(res['data'] ?? {});
  }

  Future<void> updateExpense(String id, Map<String, dynamic> expense) async {
    // Send multiple ID field name variants since backend checks one specific key.
    await _post(ApiConfig.actionUpdateExpense, {
      'id': id,
      'ExpenseID': id,
      ...expense,
    });
  }

  Future<void> deleteExpense(String id) async {
    await _post(ApiConfig.actionDeleteExpense, {
      'id': id,
      'ExpenseID': id,
    });
  }

  // ---------------- Income ----------------

  Future<List<Map<String, dynamic>>> getIncomes({
    String? from,
    String? to,
  }) async {
    final res = await _get(ApiConfig.actionGetIncomes, params: {
      if (from != null) 'from': from,
      if (to != null) 'to': to,
    });
    return List<Map<String, dynamic>>.from(res['data'] ?? []);
  }

  Future<Map<String, dynamic>> addIncome(Map<String, dynamic> income) async {
    final res = await _post(ApiConfig.actionAddIncome, income);
    return Map<String, dynamic>.from(res['data'] ?? {});
  }

  Future<void> updateIncome(String id, Map<String, dynamic> income) async {
    await _post(ApiConfig.actionUpdateIncome, {
      'id': id,
      'IncomeID': id,
      ...income,
    });
  }

  Future<void> deleteIncome(String id) async {
    await _post(ApiConfig.actionDeleteIncome, {
      'id': id,
      'IncomeID': id,
    });
  }

  // ---------------- Dashboard ----------------

  Future<Map<String, dynamic>> getDashboard() async {
    final res = await _get(ApiConfig.actionGetDashboard);
    return Map<String, dynamic>.from(res['data'] ?? {});
  }

  // ---------------- Budget (local-only, GAS doesn't have this endpoint) ----------------

  Future<List<Map<String, dynamic>>> getBudgets(String month) async {
    // Budgets are managed locally; return empty list if endpoint not available.
    try {
      final res =
          await _get(ApiConfig.actionGetBudgets, params: {'month': month});
      return List<Map<String, dynamic>>.from(res['data'] ?? []);
    } catch (_) {
      return [];
    }
  }

  Future<void> setBudget(Map<String, dynamic> budget) async {
    try {
      await _post(ApiConfig.actionSetBudget, budget);
    } catch (_) {
      // Budget is local-only if endpoint not available.
    }
  }

  // ---------------- Settings ----------------

  Future<Map<String, dynamic>> getSettings() async {
    try {
      final res = await _get(ApiConfig.actionGetSettings);
      return Map<String, dynamic>.from(res['data'] ?? {});
    } catch (_) {
      return {};
    }
  }

  Future<void> updateSettings(Map<String, dynamic> settings) async {
    try {
      await _post(ApiConfig.actionUpdateSettings, settings);
    } catch (_) {
      // Settings are local-only if endpoint not available.
    }
  }

  // ---------------- Categories ----------------

  Future<List<Map<String, dynamic>>> getCategories() async {
    final res = await _get('getCategories');
    return List<Map<String, dynamic>>.from(res['data'] ?? []);
  }
}
