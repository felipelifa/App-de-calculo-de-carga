import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ═══════════════════════════════════════════════════════════════
// PRO SERVICE — Free + Pro Freemium
//
// Gerencia status Pro do usuário.
// - isPro é armazenado em users/{uid}.isPro
// - Features FREE: workout manual, dashboard, histórico, login
// - Features PRO: prescrição inteligente, analytics, progressão,
//   PR, rotação semanal, deload automático
// - Pro via token: código de liberação resgatável via Cloud Function
// ═══════════════════════════════════════════════════════════════

class ProService {
  static const String _docPath = 'users';

  // Features que são PRO
  static const Set<String> proFeatures = {
    'prescribed_workout',     // Prescrição inteligente com motor DUP
    'analytics',              // Gráficos avançados Syncfusion
    'progression',            // Motor de progressão RIR + deload
    'pr_celebration',         // Sistema de recordes pessoais
    'workout_history',        // Histórico avançado
    'exercise_rotation',      // Rotação semanal de exercícios
    'full_dashboard',         // Dashboard completo com volume por músculo
  };

  // Features que são FREE
  static const Set<String> freeFeatures = {
    'basic_workout',          // Sessão ativa com timer
    'anamnese',               // Anamnese
    'login',                  // Auth
    'basic_exercises',        // Lista de exercícios
    'basic_dashboard',        // Dashboard básico
  };

  /// Verifica se usuário é Pro
  static Future<bool> isPro() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;

    final doc = await FirebaseFirestore.instance
        .collection(_docPath)
        .doc(uid)
        .get();

    return doc.data()?['isPro'] == true;
  }

  /// Verifica se pode acessar uma feature (true = pode usar)
  static Future<bool> canAccess(String feature) async {
    if (freeFeatures.contains(feature)) return true;
    if (proFeatures.contains(feature)) {
      return isPro();
    }
    // Feature não listada = assume FREE
    return true;
  }

  /// Retorna lista de features bloqueadas se não for Pro
  static List<String> getProFeaturesList() => proFeatures.toList();

  /// Stream para observar mudanças de status Pro
  static Stream<bool> isProStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value(false);

    return FirebaseFirestore.instance
        .collection(_docPath)
        .doc(uid)
        .snapshots()
        .map((snap) => snap.data()?['isPro'] == true);
  }

  /// Definir isPro (apenas server/admin deveria chamar, mas exposto para testes)
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

  /// Resgatar token Pro via Cloud Function
  /// Retorna 'success' ou mensagem de erro
  static Future<String> redeemProToken(String token) async {
    try {
      final functions = FirebaseFunctions.instance;
      final result = await functions.httpsCallable('redeemProToken').call({
        'tokenCode': token.toUpperCase().trim(),
      });

      final data = result.data as Map<String, dynamic>;
      return data['success'] == true ? 'success' : (data['error'] ?? 'Erro desconhecido');
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'unauthenticated') return 'Faça login primeiro';
      if (e.code == 'invalid-argument') return 'Token inválido';
      if (e.code == 'already-used') return 'Token já utilizado';
      if (e.code == 'expired') return 'Token expirado';
      return 'Erro ao resgatar: ${e.message}';
    } catch (_) {
      return 'Erro de conexão';
    }
  }
}
