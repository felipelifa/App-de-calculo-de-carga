import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final ApiService _api = ApiService();

  StreamSubscription<User?>? _authSub;

  AuthService() {
    _authSub = _auth.authStateChanges().listen((_) {
      notifyListeners();
    });
  }

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);

      // Sincronizar com backend próprio
      final token = await _auth.currentUser?.getIdToken();
      if (token != null) {
        try {
          await _api.post('/auth/validate', body: {'token': token});
        } catch (_) {
          // Backend pode não estar disponível, login local funciona
        }
      }
    } catch (e) {
      throw Exception(_handleAuthError(e));
    }
  }

  Future<void> register(String name, String email, String password) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await cred.user?.updateDisplayName(name);

      if (cred.user != null) {
        // Criar no Firestore (legado) E no backend próprio
        await _db.collection('users').doc(cred.user!.uid).set({
          'name': name,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Registrar no backend próprio
        try {
          await _api.post('/auth/register', body: {
            'name': name,
            'email': email,
            'password': password,
          });
        } catch (_) {
          // Backend pode não estar disponível
        }
      }
    } catch (e) {
      throw Exception(_handleAuthError(e));
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  String _handleAuthError(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'E-mail ou senha inválidos.';
        case 'email-already-in-use':
          return 'Este e-mail já está em uso.';
        case 'weak-password':
          return 'A senha é muito fraca.';
        case 'invalid-email':
          return 'E-mail com formato inválido.';
        default:
          return 'Erro de autenticação: ${error.message}';
      }
    }
    return 'Erro desconhecido. Tente novamente.';
  }
}
