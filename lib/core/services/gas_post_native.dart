import 'dart:convert';
import 'package:http/http.dart' as http;

/// Non-web (Android, Windows, iOS) implementation of gasPost.
/// On non-web platforms, the Dart http.Client does NOT follow POST redirects,
/// so we intercept the 302 and manually follow with a GET.
Future<Map<String, dynamic>> gasPost(Uri uri, Map<String, dynamic> payload) async {
  final body = jsonEncode(payload);
  final client = http.Client();
  
  try {
    final response = await client
        .post(
          uri,
          headers: {'Content-Type': 'text/plain'},
          body: body,
        )
        .timeout(const Duration(seconds: 30));

    print('NATIVE POST status: ${response.statusCode}');

    if (response.statusCode == 302) {
      final location = response.headers['location'];
      print('NATIVE POST redirect: $location');
      if (location == null || location.isEmpty) {
        throw Exception('Redirect location missing');
      }
      final redirect = await client
          .get(Uri.parse(location))
          .timeout(const Duration(seconds: 30));
      print('NATIVE redirect response: ${redirect.body}');
      return jsonDecode(redirect.body) as Map<String, dynamic>;
    }

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception('Server error (${response.statusCode})');
  } finally {
    client.close();
  }
}

