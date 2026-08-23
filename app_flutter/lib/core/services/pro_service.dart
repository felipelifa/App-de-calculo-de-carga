import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/api_service.dart';

class ProService {
  static const String _docPath = 'users';
  static final ApiService _api = ApiService();

  static const Set<String> proFeatures = {
    'prescribed_workout',
    'analytics',
    'progression',
    'pr_celebration',
    'workout_history',
    'exercise_rotation',
    'full_dashboard',
  };

  static const Set<String> freeFeatures = {
    'basic_workout',
    'anamnese',
    'login',
    'basic_exercises',
    'basic_dashboard',
  };

  static Future<bool> isPro() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;

    // Tentar backend próprio primeiro
    try {
      final result = await _api.get('/pro/status');
      return result['isPro'] == true;
    } catch (_) {
      // Fallback para Firestore
    }

    final doc = await FirebaseFirestore.instance
        .collection(_docPath)
        .doc(uid)
        .get();
    return doc.data()?['isPro'] == true;
  }

  static Future<bool> canAccess(String feature) async {
    if (freeFeatures.contains(feature)) return true;
    if (proFeatures.contains(feature)) {
      return isPro();
    }
    return true;
  }

  static List<String> getProFeaturesList() => proFeatures.toList();

  static Stream<bool> isProStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value(false);

    return FirebaseFirestore.instance
        .collection(_docPath)
        .doc(uid)
        .snapshots()
        .map((snap) => snap.data()?['isPro'] == true);
  }

  static Future<void> setProStatus(bool isPro) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance
        .collection(_docPath)
        .doc(uid)
        .set({
          'isPro': isPro,
          if (isPro) 'proActivatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  static Future<String> redeemProToken(String token) async {
    // Usar backend próprio
    try {
      final result = await _api.post('/pro/redeem', body: {
        'code': token.toUpperCase().trim(),
      });

      if (result['success'] == true) {
        return 'success';
      }
      return result['message'] ?? 'Erro ao resgatar token';
    } on ApiException catch (e) {
      if (e.statusCode == 404) return 'Token inválido';
      if (e.statusCode == 400) return e.message;
      if (e.statusCode == 403) return 'Acesso negado';
      return 'Erro: ${e.message}';
    } catch (_) {
      // Fallback para Cloud Functions
      try {
        final functions = FirebaseFunctions.instance;
        final result = await functions.httpsCallable('redeemProToken').call({
          'tokenCode': token.toUpperCase().trim(),
        });
        final data = result.data as Map<String, dynamic>;
        return data['success'] == true ? 'success' : (data['error'] ?? 'Erro');
      } catch (_) {
        return 'Erro de conexão';
      }
    }
  }
}
