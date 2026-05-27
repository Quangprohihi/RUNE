import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiClient {
  ApiClient({String? baseUrl, http.Client? httpClient})
    : baseUrl = baseUrl ?? _defaultBaseUrl,
      _http = httpClient ?? http.Client();

  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
  );

  static String get _defaultBaseUrl {
    if (_configuredBaseUrl.isNotEmpty) return _configuredBaseUrl;
    return 'http://10.0.2.2:3000';
  }

  final String baseUrl;
  final http.Client _http;
  String? userId;

  Map<String, String> get _headers => {
    'content-type': 'application/json',
    if (userId != null && userId!.isNotEmpty) 'x-user-id': userId!,
  };

  Future<dynamic> get(String path, {Map<String, String>? query}) async {
    final response = await _http.get(_uri(path, query), headers: _headers);
    return _decode(response);
  }

  Future<dynamic> post(String path, {Object? body}) async {
    final response = await _http.post(
      _uri(path),
      headers: _headers,
      body: jsonEncode(body ?? const {}),
    );
    return _decode(response);
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$baseUrl$normalizedPath').replace(queryParameters: query);
  }

  dynamic _decode(http.Response response) {
    final body = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = body is Map<String, dynamic>
          ? body['message'] as String? ?? 'Request failed'
          : 'Request failed';
      throw ApiException(message, response.statusCode);
    }
    return body;
  }
}

class ApiException implements Exception {
  const ApiException(this.message, this.statusCode);

  final String message;
  final int statusCode;

  @override
  String toString() => message;
}
