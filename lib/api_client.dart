import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiException implements Exception {
  const ApiException(this.message, this.statusCode);

  final String message;
  final int statusCode;

  @override
  String toString() => message;
}

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.email,
    required this.roles,
    required this.permissions,
  });

  final String accessToken;
  final String refreshToken;
  final String email;
  final List<String> roles;
  final List<String> permissions;
}

class ApiRole {
  const ApiRole({required this.id, required this.name});

  final String id;
  final String name;
}

class ApiUser {
  const ApiUser({
    required this.id,
    required this.email,
    required this.roles,
    required this.status,
  });

  final String id;
  final String email;
  final List<String> roles;
  final String status;
}

class HrmApiClient {
  HrmApiClient({http.Client? client})
      : _client = client ?? http.Client();

  static const baseUrl = 'https://hrm-api-tjfa.onrender.com';
  final http.Client _client;
  String? _accessToken;
  String? _refreshToken;

  Map<String, String> get _jsonHeaders => {
        'Content-Type': 'application/json',
        if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
      };

  Future<AuthSession> login(String email, String password) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl/api/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': email.trim(),
            'password': password,
            'deviceInfo': 'PeopleHub web',
          }),
        )
        .timeout(const Duration(seconds: 45));
    if (response.statusCode != 200) {
      throw ApiException(
        response.statusCode == 401
            ? 'Invalid email or password.'
            : 'Unable to sign in right now.',
        response.statusCode,
      );
    }

    final data = _decode(response);
    _accessToken = data['accessToken'] as String?;
    _refreshToken = data['refreshToken'] as String?;
    if (_accessToken == null || _refreshToken == null) {
      throw const ApiException('The API returned an invalid login response.', 502);
    }

    final profile = await _getMe();
    return AuthSession(
      accessToken: _accessToken!,
      refreshToken: _refreshToken!,
      email: data['email'] as String? ?? email.trim(),
      roles: profile.roles,
      permissions: profile.permissions,
    );
  }

  Future<_Profile> _getMe() async {
    final response = await _client
        .get(
          Uri.parse('$baseUrl/api/auth/me'),
          headers: _jsonHeaders,
        )
        .timeout(const Duration(seconds: 45));
    if (response.statusCode != 200) {
      throw ApiException('Unable to load your account permissions.', response.statusCode);
    }
    final data = _decode(response);
    return _Profile(
      roles: _stringList(data['roles']),
      permissions: _stringList(data['permissions']),
    );
  }

  Future<void> logout() async {
    final token = _refreshToken;
    try {
      if (token != null && _accessToken != null) {
        await _client.post(
          Uri.parse('$baseUrl/api/auth/logout'),
          headers: _jsonHeaders,
          body: jsonEncode({'refreshToken': token}),
        );
      }
    } finally {
      _accessToken = null;
      _refreshToken = null;
    }
  }

  Future<List<ApiRole>> listRoles() async {
    final response = await _authorizedRequest(
      (headers) => _client.get(Uri.parse('$baseUrl/api/rbac/roles'), headers: headers),
    );
    _throwIfNotSuccessful(response, 'Unable to load roles.');
    final data = _decodeList(response);
    return data
        .map((item) => ApiRole(
              id: item['id'] as String,
              name: item['name'] as String,
            ))
        .toList();
  }

  Future<List<ApiUser>> listUsers() async {
    final response = await _authorizedRequest(
      (headers) => _client.get(
        Uri.parse('$baseUrl/api/rbac/users?page=1&pageSize=100'),
        headers: headers,
      ),
    );
    _throwIfNotSuccessful(response, 'Unable to load accounts.');
    final data = _decode(response)['items'] as List<dynamic>? ?? const [];
    return data
        .map((item) => ApiUser(
              id: item['id'] as String,
              email: item['email'] as String,
              roles: _stringList(item['roles']),
              status: item['status'] as String? ?? 'Unknown',
            ))
        .toList();
  }

  Future<void> assignRole(String userId, String roleId) async {
    final response = await _authorizedRequest(
      (headers) => _client.post(
        Uri.parse('$baseUrl/api/rbac/users/$userId/roles'),
        headers: headers,
        body: jsonEncode({'roleId': roleId}),
      ),
    );
    _throwIfNotSuccessful(response, 'Unable to assign this role.');
  }

  Future<void> removeRole(String userId, String roleId) async {
    final response = await _authorizedRequest(
      (headers) => _client.delete(
        Uri.parse('$baseUrl/api/rbac/users/$userId/roles/$roleId'),
        headers: headers,
      ),
    );
    _throwIfNotSuccessful(response, 'Unable to remove the previous role.');
  }

  Future<http.Response> _authorizedRequest(
    Future<http.Response> Function(Map<String, String> headers) request,
  ) async {
    var response = await request(_jsonHeaders);
    if (response.statusCode == 401 && await _refreshAccessToken()) {
      response = await request(_jsonHeaders);
    }
    return response;
  }

  Future<bool> _refreshAccessToken() async {
    if (_refreshToken == null) return false;
    final response = await _client.post(
      Uri.parse('$baseUrl/api/auth/refresh'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refreshToken': _refreshToken}),
    );
    if (response.statusCode != 200) return false;
    final data = _decode(response);
    final accessToken = data['accessToken'] as String?;
    final refreshToken = data['refreshToken'] as String?;
    if (accessToken == null || refreshToken == null) return false;
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    return true;
  }

  Map<String, dynamic> _decode(http.Response response) {
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const ApiException('The API returned an invalid response.', 502);
    }
    return decoded;
  }

  List<Map<String, dynamic>> _decodeList(http.Response response) {
    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw const ApiException('The API returned an invalid list response.', 502);
    }
    return decoded.whereType<Map<String, dynamic>>().toList();
  }

  void _throwIfNotSuccessful(http.Response response, String fallback) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        response.statusCode == 403 ? 'You do not have permission to do that.' : fallback,
        response.statusCode,
      );
    }
  }

  static List<String> _stringList(Object? value) =>
      value is List ? value.whereType<String>().toList() : const [];
}

class _Profile {
  const _Profile({required this.roles, required this.permissions});

  final List<String> roles;
  final List<String> permissions;
}
