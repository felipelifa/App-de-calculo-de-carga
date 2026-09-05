import 'dart:async';
import 'package:flutter/foundation.dart';
import 'supabase_service.dart';

class AuthUser {
  final String id;
  final String email;
  final String name;
  final bool isPro;

  AuthUser({
    required this.id,
    required this.email,
    required this.name,
    this.isPro = false,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      isPro: json['isPro'] ?? false,
    );
  }

  factory AuthUser.fromSupabase(String id, String email, String? name) {
    return AuthUser(
      id: id,
      email: email,
      name: name ?? email.split('@').first,
      isPro: false,
    );
  }
}

class AuthService extends ChangeNotifier {
  final SupabaseService _supabase = SupabaseService();
  final StreamController<AuthUser?> _authController = StreamController<AuthUser?>.broadcast();

  AuthUser? _currentUser;
  bool _initialized = false;

  AuthService() {
    _tryAutoLogin();
  }

  AuthUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  Stream<AuthUser?> get authStateChanges => _authController.stream;

  Future<void> _tryAutoLogin() async {
    if (_initialized) return;
    _initialized = true;

    try {
      final user = _supabase.currentUser;
      if (user != null) {
        _currentUser = AuthUser.fromSupabase(
          user.id,
          user.email ?? '',
          user.userMetadata?['name'],
        );
        _authController.add(_currentUser);
        notifyListeners();
      }
    } catch (_) {
      _currentUser = null;
      _authController.add(null);
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    try {
      final response = await _supabase.signIn(email, password);
      if (response.user != null) {
        _currentUser = AuthUser.fromSupabase(
          response.user!.id,
          response.user!.email ?? '',
          response.user!.userMetadata?['name'],
        );
        _authController.add(_currentUser);
        notifyListeners();
      } else {
        throw Exception('Login failed');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> register(String email, String password, String name) async {
    try {
      final response = await _supabase.signUp(email, password, name);
      if (response.user != null) {
        _currentUser = AuthUser.fromSupabase(
          response.user!.id,
          response.user!.email ?? '',
          name,
        );
        _authController.add(_currentUser);
        notifyListeners();
      } else {
        throw Exception('Registration failed');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    await _supabase.signOut();
    _currentUser = null;
    _authController.add(null);
    notifyListeners();
  }

  void dispose() {
    _authController.close();
    super.dispose();
  }
}
