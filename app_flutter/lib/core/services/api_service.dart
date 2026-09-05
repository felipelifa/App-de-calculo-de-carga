import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiService {
  static final ApiService _instance = ApiService._();
  factory ApiService() => _instance;

  // Use Vercel proxy to avoid CORS issues with Railway
  static const String _railwayBaseUrl = String.fromEnvironment(
    'BUILDFIT_API_URL',
    defaultValue: 'https://buildfit-api-production.up.railway.app',
  );

  // For web platform, use the Vercel proxy
  static const String _proxyBaseUrl = 'https://buildfit-woad.vercel.app/api/proxy';

  static const _requestTimeout = Duration(seconds: 30);
  static const _tokenKey = 'auth_token';

  late final http.Client _client;
  String? _cachedToken;

  ApiService._() {
    _client = http.Client();
    _loadToken();
  }

  // Determine if running on web
  static const bool _isWeb = bool.fromEnvironment('dart.library.js');

  String get _baseUrl {
    // On web, use the Vercel proxy to avoid CORS
    // On mobile/desktop, use Railway directly
    if (_isWeb) {
      return _proxyBaseUrl;
    }
    return '$_railwayBaseUrl/api';
  }

  String get baseUrl => _baseUrl;
  bool get isAuthenticated => _cachedToken != null;

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _cachedToken = prefs.getString(_tokenKey);
  }

  Future<void> saveToken(String token) async {
    _cachedToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> clearToken() async {
    _cachedToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Future<Map<String, String>> _headers() async {
    if (_cachedToken == null) {
      await _loadToken();
    }
    return {
      'Content-Type': 'application/json',
      if (_cachedToken != null) 'Authorization': 'Bearer $_cachedToken',
    };
  }

  Future<T> get<T>(String path, {Map<String, String>? queryParams}) async {
    final headers = await _headers();
    Uri uri;

    if (_isWeb) {
      // Use proxy: /api/proxy?path=api/auth/login
      final apiPath = path.startsWith('/') ? path.substring(1) : path;
      uri = Uri.parse(_proxyBaseUrl).replace(queryParameters: {'path': apiPath, ...?queryParams});
    } else {
      uri = Uri.parse('$_baseUrl$path').replace(queryParameters: queryParams);
    }

    final response = await _client.get(uri, headers: headers).timeout(_requestTimeout);
    return _handleResponse<T>(response);
  }

  Future<T> post<T>(String path, {dynamic body}) async {
    final headers = await _headers();
    Uri uri;

    if (_isWeb) {
      final apiPath = path.startsWith('/') ? path.substring(1) : path;
      uri = Uri.parse(_proxyBaseUrl).replace(queryParameters: {'path': apiPath});
    } else {
      uri = Uri.parse('$_baseUrl$path');
    }

    final response = await _client.post(
      uri,
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    ).timeout(_requestTimeout);
    return _handleResponse<T>(response);
  }

  Future<T> put<T>(String path, {dynamic body}) async {
    final headers = await _headers();
    Uri uri;

    if (_isWeb) {
      final apiPath = path.startsWith('/') ? path.substring(1) : path;
      uri = Uri.parse(_proxyBaseUrl).replace(queryParameters: {'path': apiPath});
    } else {
      uri = Uri.parse('$_baseUrl$path');
    }

    final response = await _client.put(
      uri,
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    ).timeout(_requestTimeout);
    return _handleResponse<T>(response);
  }

  Future<T> delete<T>(String path) async {
    final headers = await _headers();
    Uri uri;

    if (_isWeb) {
      final apiPath = path.startsWith('/') ? path.substring(1) : path;
      uri = Uri.parse(_proxyBaseUrl).replace(queryParameters: {'path': apiPath});
    } else {
      uri = Uri.parse('$_baseUrl$path');
    }

    final response = await _client.delete(uri, headers: headers).timeout(_requestTimeout);
    return _handleResponse<T>(response);
  }

  T _handleResponse<T>(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.trim().isEmpty) return null as T;
      return jsonDecode(response.body) as T;
    }

    String message;
    try {
      final body = jsonDecode(response.body);
      message = body['message'] ?? body['error'] ?? 'Erro desconhecido';
    } catch (_) {
      message = response.body;
    }

    throw ApiException(response.statusCode, message);
  }

  void dispose() {
    _client.close();
  }
}
