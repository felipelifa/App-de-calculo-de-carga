import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  StreamSubscription<User?>? _authSub;

  AuthService() {
    // Escuta mudanças de estado e notifica o GoRouter imediatamente
    _authSub = _auth.authStateChanges().listen((_) {
      notifyListeners();
    });
  }

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      // notifyListeners() é chamado pelo stream acima automaticamente
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
        await _db.collection('users').doc(cred.user!.uid).set({
          'name': name,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      throw Exception(_handleAuthError(e));
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    // notifyListeners() é chamado pelo stream acima automaticamente
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
