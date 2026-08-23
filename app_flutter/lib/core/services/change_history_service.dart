import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ─────────────────────────────────────────────
// Serviço de Histórico de Alterações
// Registra mudanças feitas pelo usuário
// ─────────────────────────────────────────────

class ChangeHistoryService {
  final FirebaseFirestore _db;
  final String _uid;

  ChangeHistoryService({FirebaseFirestore? db, String? uid})
      : _db = db ?? FirebaseFirestore.instance,
        _uid = uid ?? FirebaseAuth.instance.currentUser?.uid ?? '';

  /// Registra uma alteração no histórico
  Future<void> recordChange({
    required String type, // 'goal', 'modality', 'level', 'days', 'duration', 'environment', 'restrictions', 'nutrition'
    required String oldValue,
    required String newValue,
    String? reason,
    String? duration, // 'today', 'this_week', 'permanent'
  }) async {
    await _db.collection('users/$_uid/change_history').add({
      'type': type,
      'oldValue': oldValue,
      'newValue': newValue,
      'reason': reason,
      'duration': duration ?? 'permanent',
      'timestamp': FieldValue.serverTimestamp(),
      'date': DateTime.now().toIso8601String(),
    });
  }

  /// Retorna o histórico de alterações
  Future<List<Map<String, dynamic>>> getHistory({int limit = 50}) async {
    final snap = await _db
        .collection('users/$_uid/change_history')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();

    return snap.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'type': data['type'],
        'oldValue': data['oldValue'],
        'newValue': data['newValue'],
        'reason': data['reason'],
        'duration': data['duration'],
        'date': data['date'],
        'timestamp': data['timestamp'],
      };
    }).toList();
  }

  /// Retorna alterações por tipo
  Future<List<Map<String, dynamic>>> getHistoryByType(String type) async {
    final snap = await _db
        .collection('users/$_uid/change_history')
        .where('type', isEqualTo: type)
        .orderBy('timestamp', descending: true)
        .get();

    return snap.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'type': data['type'],
        'oldValue': data['oldValue'],
        'newValue': data['newValue'],
        'reason': data['reason'],
        'duration': data['duration'],
        'date': data['date'],
        'timestamp': data['timestamp'],
      };
    }).toList();
  }

  /// Retorna a última alteração de um tipo
  Future<Map<String, dynamic>?> getLastChange(String type) async {
    final snap = await _db
        .collection('users/$_uid/change_history')
        .where('type', isEqualTo: type)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;

    final data = snap.docs.first.data();
    return {
      'id': snap.docs.first.id,
      'type': data['type'],
      'oldValue': data['oldValue'],
      'newValue': data['newValue'],
      'reason': data['reason'],
      'duration': data['duration'],
      'date': data['date'],
      'timestamp': data['timestamp'],
    };
  }

  /// Retorna resumo das alterações da semana
  Future<Map<String, dynamic>> getWeeklySummary() async {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartDate = DateTime(weekStart.year, weekStart.month, weekStart.day);

    final snap = await _db
        .collection('users/$_uid/change_history')
        .where('timestamp', isGreaterThanOrEqualTo: weekStartDate)
        .get();

    final changes = snap.docs.map((doc) => doc.data()).toList();

    return {
      'totalChanges': changes.length,
      'goalChanges': changes.where((c) => c['type'] == 'goal').length,
      'workoutChanges': changes.where((c) => c['type'] == 'days' || c['type'] == 'duration').length,
      'nutritionChanges': changes.where((c) => c['type'] == 'nutrition').length,
    };
  }

  /// Traduz tipo de alteração para português
  String translateType(String type) {
    switch (type) {
      case 'goal': return 'Objetivo';
      case 'modality': return 'Modalidade';
      case 'level': return 'Nível';
      case 'days': return 'Dias por semana';
      case 'duration': return 'Duração do treino';
      case 'environment': return 'Ambiente';
      case 'restrictions': return 'Restrições';
      case 'nutrition': return 'Nutrição';
      case 'weight': return 'Peso';
      case 'height': return 'Altura';
      default: return type;
    }
  }

  /// Traduz duração para português
  String translateDuration(String duration) {
    switch (duration) {
      case 'today': return 'Só hoje';
      case 'this_week': return 'Esta semana';
      case 'permanent': return 'Permanentemente';
      default: return duration;
    }
  }
}
