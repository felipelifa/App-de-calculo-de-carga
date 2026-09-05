import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Memória de decisões do motor de prescrição.
///
/// Registra o que foi escolhido, por que, e o que quase foi escolhido
/// em seu lugar (contrafactual). Cada decisão é auditável e rastreável.
class PrescriptionDecision {
  final String exerciseId;
  final String exerciseName;
  final String muscle;
  final String pattern;
  final String reason;
  final String? alternativeConsidered;
  final double score;
  final DateTime timestamp;

  const PrescriptionDecision({
    required this.exerciseId,
    required this.exerciseName,
    required this.muscle,
    required this.pattern,
    required this.reason,
    this.alternativeConsidered,
    required this.score,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
    'exerciseId': exerciseId,
    'exerciseName': exerciseName,
    'muscle': muscle,
    'pattern': pattern,
    'reason': reason,
    'alternativeConsidered': alternativeConsidered,
    'score': score,
    'timestamp': timestamp.toIso8601String(),
  };

  factory PrescriptionDecision.fromMap(Map<String, dynamic> map) =>
    PrescriptionDecision(
      exerciseId: map['exerciseId'] as String? ?? '',
      exerciseName: map['exerciseName'] as String? ?? '',
      muscle: map['muscle'] as String? ?? '',
      pattern: map['pattern'] as String? ?? '',
      reason: map['reason'] as String? ?? '',
      alternativeConsidered: map['alternativeConsidered'] as String?,
      score: (map['score'] as num?)?.toDouble() ?? 0,
      timestamp: DateTime.tryParse(map['timestamp'] as String? ?? '') ??
          DateTime.now(),
    );
}

/// Registro completo de uma sessão de prescrição.
class PrescriptionRecord {
  final String workoutId;
  final String splitType;
  final String periodization;
  final List<PrescriptionDecision> decisions;
  final Map<String, dynamic> inputSnapshot;
  final DateTime timestamp;

  const PrescriptionRecord({
    required this.workoutId,
    required this.splitType,
    required this.periodization,
    required this.decisions,
    required this.inputSnapshot,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
    'workoutId': workoutId,
    'splitType': splitType,
    'periodization': periodization,
    'decisions': decisions.map((d) => d.toMap()).toList(),
    'inputSnapshot': inputSnapshot,
    'timestamp': timestamp.toIso8601String(),
  };

  factory PrescriptionRecord.fromMap(Map<String, dynamic> map) =>
    PrescriptionRecord(
      workoutId: map['workoutId'] as String? ?? '',
      splitType: map['splitType'] as String? ?? '',
      periodization: map['periodization'] as String? ?? '',
      decisions: (map['decisions'] as List? ?? [])
          .map((d) => PrescriptionDecision.fromMap(d as Map<String, dynamic>))
          .toList(),
      inputSnapshot: map['inputSnapshot'] as Map<String, dynamic>? ?? {},
      timestamp: DateTime.tryParse(map['timestamp'] as String? ?? '') ??
          DateTime.now(),
    );
}

/// Gerenciador de memória de decisões com persistência.
class DecisionMemory {
  static const _recordsKey = 'decision_memory_records';
  static const _maxRecords = 50; // Manter últimas 50 sessões

  List<PrescriptionRecord> _records = [];

  DecisionMemory();

  /// Carrega registros do SharedPreferences.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_recordsKey);
      if (json != null) {
        final data = jsonDecode(json) as List;
        _records = data
            .map((r) => PrescriptionRecord.fromMap(r as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('DecisionMemory.load error: $e');
    }
  }

  /// Salva registros no SharedPreferences.
  Future<void> save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(_records.map((r) => r.toMap()).toList());
      await prefs.setString(_recordsKey, json);
    } catch (e) {
      debugPrint('DecisionMemory.save error: $e');
    }
  }

  /// Adiciona um novo registro e persiste.
  Future<void> addRecord(PrescriptionRecord record) async {
    _records.add(record);
    
    // Limitar número de registros
    if (_records.length > _maxRecords) {
      _records = _records.sublist(_records.length - _maxRecords);
    }
    
    await save();
  }

  /// Retorna todos os registros.
  List<PrescriptionRecord> get records => List.unmodifiable(_records);

  /// Retorna registros recentes (últimas N sessões).
  List<PrescriptionRecord> getRecentRecords({int count = 5}) {
    final start = _records.length > count ? _records.length - count : 0;
    return _records.sublist(start);
  }

  /// Verifica se um exercício foi usado recentemente.
  bool wasExerciseUsedRecently(String exerciseId, {int sessionsBack = 3}) {
    final recent = getRecentRecords(count: sessionsBack);
    for (final record in recent) {
      for (final decision in record.decisions) {
        if (decision.exerciseId == exerciseId) {
          return true;
        }
      }
    }
    return false;
  }

  /// Retorna quantas vezes um exercício foi usado nas últimas N sessões.
  int getExerciseUsageCount(String exerciseId, {int sessionsBack = 5}) {
    int count = 0;
    final recent = getRecentRecords(count: sessionsBack);
    for (final record in recent) {
      for (final decision in record.decisions) {
        if (decision.exerciseId == exerciseId) {
          count++;
        }
      }
    }
    return count;
  }

  /// Retorna exercícios evitados recentemente (decisões com score baixo).
  List<String> getRecentlyAvoidedExercises({int sessionsBack = 3}) {
    final avoided = <String>[];
    final recent = getRecentRecords(count: sessionsBack);
    for (final record in recent) {
      for (final decision in record.decisions) {
        if (decision.alternativeConsidered != null && decision.score < 50) {
          avoided.add(decision.exerciseId);
        }
      }
    }
    return avoided;
  }

  /// Limpa todos os registros.
  Future<void> clear() async {
    _records.clear();
    await save();
  }
}
