import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

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

  // Sobrescreva com --dart-define=BUILDFIT_API_URL=... em cada ambiente.
  static const String _baseUrl = String.fromEnvironment(
    'BUILDFIT_API_URL',
    defaultValue: 'https://buildfit-api-production.up.railway.app/api',
  );

  static const _requestTimeout = Duration(seconds: 15);

  late final http.Client _client;

  ApiService._() {
    _client = http.Client();
  }

  String get baseUrl => _baseUrl;

  Future<String?> _getToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return user.getIdToken();
  }

  Future<Map<String, String>> _headers() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<T> get<T>(String path, {Map<String, String>? queryParams}) async {
    final uri = Uri.parse('$_baseUrl$path').replace(queryParameters: queryParams);
    final headers = await _headers();

    final response = await _client.get(uri, headers: headers).timeout(_requestTimeout);
    return _handleResponse<T>(response);
  }

  Future<T> post<T>(String path, {dynamic body}) async {
    final uri = Uri.parse('$_baseUrl$path');
    final headers = await _headers();

    final response = await _client.post(
      uri,
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    ).timeout(_requestTimeout);
    return _handleResponse<T>(response);
  }

  Future<T> put<T>(String path, {dynamic body}) async {
    final uri = Uri.parse('$_baseUrl$path');
    final headers = await _headers();

    final response = await _client.put(
      uri,
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    ).timeout(_requestTimeout);
    return _handleResponse<T>(response);
  }

  Future<T> delete<T>(String path) async {
    final uri = Uri.parse('$_baseUrl$path');
    final headers = await _headers();

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
