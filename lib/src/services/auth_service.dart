import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';

/// Handles authentication: login, register, token storage, refresh, and logout.
///
/// Set [onAuthFailure] in main() to redirect to the login screen on 401s.
class AuthService {
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userIdKey = 'user_id';
  static const _emailKey = 'email';

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _timeout = Duration(seconds: 15);

  /// Called when a 401 is received and token refresh fails. Use to redirect to login.
  void Function()? onAuthFailure;

  // ---------------------------------------------------------------------------
  // Registration & Login
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> validateCode(String code) async {
    final resp = await http
        .get(ApiConfig.uri('/auth/validate-code?code=$code'))
        .timeout(_timeout);
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    String? fullName,
    String? registrationCode,
  }) async {
    final resp = await http
        .post(
          ApiConfig.uri('/auth/register'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': email,
            'password': password,
            if (fullName != null) 'full_name': fullName,
            if (registrationCode != null) 'registration_code': registrationCode,
          }),
        )
        .timeout(_timeout);

    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    if (resp.statusCode == 201 && body['status'] == 'registered') {
      await _saveTokens(
        accessToken: body['access_token'] as String,
        refreshToken: body['refresh_token'] as String,
        email: email,
      );
    }
    return body;
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final resp = await http
        .post(
          ApiConfig.uri('/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'password': password}),
        )
        .timeout(_timeout);

    if (resp.statusCode != 200) {
      final body = jsonDecode(resp.body) as Map<String, dynamic>;
      throw AuthException(body['detail'] as String? ?? 'Login failed');
    }

    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    await _saveTokens(
      accessToken: body['access_token'] as String,
      refreshToken: body['refresh_token'] as String,
      email: email,
    );
    return body;
  }

  // ---------------------------------------------------------------------------
  // Token management
  // ---------------------------------------------------------------------------

  Future<void> refreshAccessToken() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken == null) {
      onAuthFailure?.call();
      return;
    }

    final resp = await http
        .post(
          ApiConfig.uri('/auth/refresh'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $refreshToken',
          },
        )
        .timeout(_timeout);

    if (resp.statusCode != 200) {
      await _clearTokens();
      onAuthFailure?.call();
      return;
    }

    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    await _storage.write(
      key: _accessTokenKey,
      value: body['access_token'] as String,
    );
    await _storage.write(
      key: _refreshTokenKey,
      value: body['refresh_token'] as String,
    );
  }

  Future<String?> getAccessToken() => _storage.read(key: _accessTokenKey);
  Future<String?> getRefreshToken() => _storage.read(key: _refreshTokenKey);
  Future<String?> getUserId() => _storage.read(key: _userIdKey);
  Future<String?> getEmail() => _storage.read(key: _emailKey);

  Future<bool> isAuthenticated() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  // ---------------------------------------------------------------------------
  // User info
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> getCurrentUser() async {
    final resp = await authenticatedRequest(
      method: 'GET',
      endpoint: '/auth/me',
    );
    if (resp.statusCode != 200) {
      throw AuthException('Failed to fetch user profile');
    }
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    if (body['id'] != null) {
      await _storage.write(key: _userIdKey, value: body['id'] as String);
    }
    return body;
  }

  // ---------------------------------------------------------------------------
  // Authenticated requests (with auto-refresh on 401)
  // ---------------------------------------------------------------------------

  Future<http.Response> authenticatedRequest({
    required String method,
    required String endpoint,
    Map<String, String>? extraHeaders,
    Object? body,
  }) async {
    final token = await getAccessToken();
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
      ...?extraHeaders,
    };

    http.Response resp = await _send(
      method: method,
      uri: ApiConfig.uri(endpoint),
      headers: headers,
      body: body,
    );

    if (resp.statusCode == 401) {
      await refreshAccessToken();
      final newToken = await getAccessToken();
      if (newToken == null) return resp;
      headers['Authorization'] = 'Bearer $newToken';
      resp = await _send(
        method: method,
        uri: ApiConfig.uri(endpoint),
        headers: headers,
        body: body,
      );
    }

    return resp;
  }

  Future<http.Response> _send({
    required String method,
    required Uri uri,
    required Map<String, String> headers,
    Object? body,
  }) async {
    final encoded = body != null ? jsonEncode(body) : null;
    switch (method.toUpperCase()) {
      case 'GET':
        return http.get(uri, headers: headers).timeout(_timeout);
      case 'POST':
        return http
            .post(uri, headers: headers, body: encoded)
            .timeout(_timeout);
      case 'PATCH':
        return http
            .patch(uri, headers: headers, body: encoded)
            .timeout(_timeout);
      case 'PUT':
        return http.put(uri, headers: headers, body: encoded).timeout(_timeout);
      case 'DELETE':
        return http.delete(uri, headers: headers).timeout(_timeout);
      default:
        throw ArgumentError('Unsupported HTTP method: $method');
    }
  }

  // ---------------------------------------------------------------------------
  // Logout
  // ---------------------------------------------------------------------------

  Future<void> logout() async {
    try {
      await authenticatedRequest(method: 'POST', endpoint: '/auth/logout');
    } catch (_) {
      // Best-effort server-side logout — always clear local tokens
    }
    await _clearTokens();
  }

  // ---------------------------------------------------------------------------
  // Waitlist
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> joinWaitlist(String email) async {
    final resp = await http
        .post(
          ApiConfig.uri('/auth/register'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'password': 'placeholder'}),
        )
        .timeout(_timeout);
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Future<void> _saveTokens({
    required String accessToken,
    required String refreshToken,
    required String email,
  }) async {
    await Future.wait([
      _storage.write(key: _accessTokenKey, value: accessToken),
      _storage.write(key: _refreshTokenKey, value: refreshToken),
      _storage.write(key: _emailKey, value: email),
    ]);
  }

  Future<void> _clearTokens() async {
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
      _storage.delete(key: _userIdKey),
      _storage.delete(key: _emailKey),
    ]);
  }
}

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
  @override
  String toString() => 'AuthException: $message';
}
