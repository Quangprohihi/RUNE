import 'dart:convert';

import 'package:http/http.dart' as http;

import '../repositories/auth_token_repository.dart';

class ApiClient {
  ApiClient({
    String? baseUrl,
    http.Client? httpClient,
    AuthTokenRepository? tokenRepository,
  }) : baseUrl = baseUrl ?? _defaultBaseUrl,
       _http = httpClient ?? http.Client(),
       _tokenRepository = tokenRepository;

  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
  );

  static String get _defaultBaseUrl {
    if (_configuredBaseUrl.isNotEmpty) return _configuredBaseUrl;
    return 'http://10.0.2.2:3000';
  }

  final String baseUrl;
  final http.Client _http;
  final AuthTokenRepository? _tokenRepository;
  String? accessToken;
  String? userId;
  int _sessionEpoch = 0;

  /// Marks the current auth session as ended so an in-flight token refresh
  /// that resolves after logout cannot re-save the previous user's tokens.
  void invalidateSession() {
    _sessionEpoch++;
    accessToken = null;
    userId = null;
  }

  Map<String, String> _headers({bool includeAuth = true}) {
    final headers = <String, String>{'content-type': 'application/json'};
    if (!includeAuth) return headers;

    if (accessToken != null && accessToken!.isNotEmpty) {
      headers['authorization'] = 'Bearer $accessToken';
    } else if (userId != null && userId!.isNotEmpty) {
      headers['x-user-id'] = userId!;
    }
    return headers;
  }

  Future<dynamic> get(String path, {Map<String, String>? query}) {
    return _send(() => _http.get(_uri(path, query), headers: _headers()));
  }

  Future<dynamic> post(String path, {Object? body}) {
    return _send(
      () => _http.post(
        _uri(path),
        headers: _headers(),
        body: jsonEncode(body ?? const {}),
      ),
    );
  }

  Future<dynamic> patch(String path, {Object? body}) {
    return _send(
      () => _http.patch(
        _uri(path),
        headers: _headers(),
        body: jsonEncode(body ?? const {}),
      ),
    );
  }

  Future<dynamic> _send(
    Future<http.Response> Function() request, {
    bool allowRefresh = true,
  }) async {
    var response = await request();
    if (response.statusCode == 401 &&
        allowRefresh &&
        _tokenRepository != null) {
      final refreshed = await _refreshAccessToken();
      if (refreshed) {
        response = await request();
      }
    }
    return _decode(response);
  }

  Future<bool> _refreshAccessToken() async {
    final repository = _tokenRepository;
    if (repository == null) return false;

    final epochAtStart = _sessionEpoch;
    final refreshToken = await repository.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;

    try {
      final response = await _http.post(
        _uri('/auth/refresh'),
        headers: const {'content-type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return false;
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final nextAccess = body['accessToken'] as String?;
      final nextRefresh = body['refreshToken'] as String?;
      if (nextAccess == null ||
          nextRefresh == null ||
          nextAccess.isEmpty ||
          nextRefresh.isEmpty) {
        return false;
      }

      // The user logged out (or switched accounts) while this refresh was in
      // flight — discard the minted tokens instead of resurrecting the old
      // session.
      if (epochAtStart != _sessionEpoch) return false;

      accessToken = nextAccess;
      await repository.saveTokens(
        accessToken: nextAccess,
        refreshToken: nextRefresh,
      );
      return true;
    } catch (_) {
      return false;
    }
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
