import '../enums/joint.dart';
import '../enums/limitation_severity.dart';
import '../enums/adaptation_type.dart';

/// Mapeia uma limitação do usuário a como ela afeta um exercício.
class V2LimitationRule {
  final V2Joint joint;
  final V2LimitationSeverity severity;
  final List<String> symptoms;
  final String? diagnosis;
  final List<V2AdaptationType> recommendedAdaptations;
  final List<String> alternativeExerciseIds;
  final List<String> regressionExerciseIds;

  const V2LimitationRule({
    required this.joint,
    required this.severity,
    this.symptoms = const [],
    this.diagnosis,
    this.recommendedAdaptations = const [],
    this.alternativeExerciseIds = const [],
    this.regressionExerciseIds = const [],
  });

  bool matches(V2Joint userJoint, V2LimitationSeverity userSeverity) {
    return joint == userJoint && userSeverity.index >= severity.index;
  }

  Map<String, dynamic> toMap() => {
    'joint': joint.name,
    'severity': severity.name,
    'symptoms': symptoms,
    'diagnosis': diagnosis,
    'recommendedAdaptations': recommendedAdaptations.map((e) => e.name).toList(),
    'alternativeExerciseIds': alternativeExerciseIds,
    'regressionExerciseIds': regressionExerciseIds,
  };

  factory V2LimitationRule.fromMap(Map<String, dynamic> m) => V2LimitationRule(
    joint: _parseJoint(m['joint']),
    severity: _parseSeverity(m['severity']),
    symptoms: List<String>.from(m['symptoms'] ?? []),
    diagnosis: m['diagnosis'] as String?,
    recommendedAdaptations: _parseAdaptations(m['recommendedAdaptations']),
    alternativeExerciseIds: List<String>.from(m['alternativeExerciseIds'] ?? []),
    regressionExerciseIds: List<String>.from(m['regressionExerciseIds'] ?? []),
  );

  static V2Joint _parseJoint(dynamic value) {
    if (value == null) return V2Joint.knee;
    return V2Joint.values.firstWhere(
      (e) => e.name == value,
      orElse: () => V2Joint.knee,
    );
  }

  static V2LimitationSeverity _parseSeverity(dynamic value) {
    if (value == null) return V2LimitationSeverity.mild;
    return V2LimitationSeverity.values.firstWhere(
      (e) => e.name == value,
      orElse: () => V2LimitationSeverity.mild,
    );
  }

  static List<V2AdaptationType> _parseAdaptations(dynamic value) {
    if (value == null) return const [];
    return (value as List).map((e) => V2AdaptationType.values.firstWhere(
      (a) => a.name == e,
      orElse: () => V2AdaptationType.reduceAmplitude,
    )).toList();
  }
}
