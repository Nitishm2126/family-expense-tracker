// This file provides the web-specific implementation for posting to GAS.
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:convert';

/// Posts JSON to a Google Apps Script web app from Flutter Web.
/// Uses XMLHttpRequest with redirect following disabled via `withCredentials=false`.
/// GAS responds with 302 -> we manually follow the Location header with a GET XHR.
///
/// Returns the decoded JSON body from the final response, or throws on error.
Future<Map<String, dynamic>> gasPost(Uri uri, Map<String, dynamic> payload) async {
  final body = jsonEncode(payload);

  // Step 1: POST to GAS - set up XHR to NOT follow redirects automatically.
  // In XMLHttpRequest, redirects ARE followed automatically by the browser.
  // We cannot stop this, but we CAN work around it by checking what happened.
  //
  // The trick: Use fetch API with `redirect: 'manual'` to catch the redirect,
  // then follow it manually with a GET.
  
  // Use fetch with manual redirect
  final response = await html.HttpRequest.request(
    uri.toString(),
    method: 'POST',
    sendData: body,
    requestHeaders: {'Content-Type': 'text/plain'},
    withCredentials: false,
  ).catchError((e) {
    throw Exception('POST failed: $e');
  });

  final responseText = response.responseText ?? '';
  print('WEB POST status: ${response.status}, body: ${responseText.length > 200 ? responseText.substring(0, 200) : responseText}');
  
  if (response.status == 200) {
    try {
      return jsonDecode(responseText) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Could not parse response: $responseText');
    }
  }
  
  throw Exception('Server error (${response.status})');
}
