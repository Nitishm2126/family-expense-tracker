import 'package:http/http.dart' as http;

/// A custom http.Client that handles Google Apps Script POST redirects.
/// On native (Android, Windows, iOS), the default http.Client does NOT follow
/// POST redirects automatically, so we can intercept the 302 and do a GET.
/// This stub is for non-web platforms.
class GasHttpClient extends http.BaseClient {
  final http.Client _inner;

  GasHttpClient() : _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _inner.send(request);
  }

  @override
  void close() {
    _inner.close();
  }
}

