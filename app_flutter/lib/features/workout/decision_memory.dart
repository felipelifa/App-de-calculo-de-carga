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
