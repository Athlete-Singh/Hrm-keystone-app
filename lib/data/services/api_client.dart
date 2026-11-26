import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform, SocketException;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.code});

  final String message;
  final int? statusCode;
  final String? code;

  @override
  String toString() => message;
}

/// Thin HTTP client talking to `hrm-backend` with `Authorization: Bearer` + `X-Workspace-Id`.
class ApiClient {
  ApiClient({http.Client? httpClient}) : _client = httpClient ?? http.Client();

  final http.Client _client;

  static const String _envApiUrl = String.fromEnvironment('KEYSTONE_API_URL');

  static const String _tokenKey = 'keystone_auth_token';
  static const String _workspaceKey = 'keystone_workspace_id';
  static const String _baseUrlKey = 'keystone_backend_url';

  String? _token;
  String? _workspaceId;
  String _baseUrl = defaultBaseUrl();

  String? get token => _token;
  String? get workspaceId => _workspaceId;
  String get baseUrl => _baseUrl;
  bool get hasSession => _token != null && _token!.isNotEmpty;

  static String defaultBaseUrl() {
    final envUrl = _envApiUrl.trim().replaceAll(RegExp(r'/+$'), '');
    if (envUrl.isNotEmpty) {
      return envUrl;
    }
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:3000';
    }
    return 'http://localhost:3000';
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    _workspaceId = prefs.getString(_workspaceKey);
    final savedUrl = prefs.getString(_baseUrlKey);
    if (savedUrl != null && savedUrl.trim().isNotEmpty) {
      _baseUrl = savedUrl.trim();
    }
  }

  Future<void> setBaseUrl(String url) async {
    final normalized = url.trim().replaceAll(RegExp(r'/+$'), '');
    _baseUrl = normalized.isEmpty ? defaultBaseUrl() : normalized;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, _baseUrl);
  }

  Future<void> setAuthSession({required String? token, required String? workspaceId}) async {
    _token = token;
    _workspaceId = workspaceId;
    final prefs = await SharedPreferences.getInstance();
    if (token != null && token.isNotEmpty) {
      await prefs.setString(_tokenKey, token);
    } else {
      await prefs.remove(_tokenKey);
    }
    if (workspaceId != null && workspaceId.isNotEmpty) {
      await prefs.setString(_workspaceKey, workspaceId);
    } else {
      await prefs.remove(_workspaceKey);
    }
  }

  Future<void> setWorkspaceId(String workspaceId) async {
    _workspaceId = workspaceId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_workspaceKey, workspaceId);
  }

  Map<String, String> _headers() {
    return <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (_token != null && _token!.isNotEmpty) 'Authorization': 'Bearer $_token',
      if (_workspaceId != null && _workspaceId!.isNotEmpty) 'X-Workspace-Id': _workspaceId!,
    };
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$_baseUrl$normalizedPath').replace(
      queryParameters: query != null && query.isNotEmpty ? query : null,
    );
  }

  Uri buildUri(String path, [Map<String, String>? query]) {
    final params = Map<String, String>.from(query ?? {});
    if (_token != null && _token!.isNotEmpty && !params.containsKey('token')) {
      params['token'] = _token!;
    }
    if (_workspaceId != null && _workspaceId!.isNotEmpty && !params.containsKey('workspaceId')) {
      params['workspaceId'] = _workspaceId!;
    }
    return _uri(path, params);
  }

  Future<Uint8List> getBytes(String path, {Map<String, String>? query}) async {
    try {
      final response = await _client
          .get(_uri(path, query), headers: {
            ..._headers(),
            'Accept': 'application/pdf, application/octet-stream, */*',
          })
          .timeout(const Duration(seconds: 12));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response.bodyBytes;
      }
      throw ApiException('Failed to download file (${response.statusCode})');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to download file: $e');
    }
  }

  Future<dynamic> get(String path, {Map<String, String>? query}) async {
    try {
      final response = await _client
          .get(_uri(path, query), headers: _headers())
          .timeout(const Duration(seconds: 7));
      return _decodeResponse(response);
    } on TimeoutException {
      throw const ApiException('Connection timed out. Server is unreachable at this address.');
    } on SocketException {
      throw const ApiException('Cannot connect to server. Check your network or server URL.');
    } on http.ClientException catch (e) {
      throw ApiException('Network error: ${e.message}');
    }
  }

  Future<dynamic> post(String path, {Object? body, bool captureAuthToken = false}) async {
    try {
      final response = await _client
          .post(
            _uri(path),
            headers: _headers(),
            body: body == null ? null : jsonEncode(body),
          )
          .timeout(const Duration(seconds: 7));
      if (captureAuthToken) {
        final headerToken = response.headers['x-auth-token'];
        if (headerToken != null && headerToken.isNotEmpty) {
          _token = headerToken;
        }
      }
      return _decodeResponse(response);
    } on TimeoutException {
      throw const ApiException('Connection timed out. Server is unreachable at this address.');
    } on SocketException {
      throw const ApiException('Cannot connect to server. Check your network or server URL.');
    } on http.ClientException catch (e) {
      throw ApiException('Network error: ${e.message}');
    }
  }

  Future<dynamic> patch(String path, {Object? body}) async {
    try {
      final response = await _client
          .patch(
            _uri(path),
            headers: _headers(),
            body: body == null ? null : jsonEncode(body),
          )
          .timeout(const Duration(seconds: 7));
      return _decodeResponse(response);
    } on TimeoutException {
      throw const ApiException('Connection timed out. Server is unreachable at this address.');
    } on SocketException {
      throw const ApiException('Cannot connect to server. Check your network or server URL.');
    } on http.ClientException catch (e) {
      throw ApiException('Network error: ${e.message}');
    }
  }

  dynamic _decodeResponse(http.Response response) {
    final raw = response.body.trim();
    dynamic parsed;
    if (raw.isNotEmpty) {
      try {
        parsed = jsonDecode(raw);
      } catch (_) {
        parsed = raw;
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return parsed;
    }

    String message = 'Request failed (${response.statusCode})';
    String? code;
    if (parsed is Map<String, dynamic>) {
      final err = parsed['message'];
      if (err is List && err.isNotEmpty) {
        message = err.first.toString();
      } else if (err != null) {
        message = err.toString();
      }
      if (parsed['code'] != null) {
        code = parsed['code'].toString();
      }
    }
    throw ApiException(message, statusCode: response.statusCode, code: code);
  }
}

