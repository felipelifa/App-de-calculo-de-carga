import '../enums/feedback_quality.dart';
import '../enums/difficulty.dart';

/// Feedback do usuário sobre execução de um exercício.
class V2Feedback {
  final String exerciseId;
  final V2FeedbackQuality quality;
  final V2Difficulty difficultyUsed;
  final List<String> symptomsDuring;
  final List<String> symptomsAfter;
  final bool neededSupport;
  final double technicalDifficulty;
  final double perceivedEffort;
  final String? notes;
  final DateTime recordedAt;

  const V2Feedback({
    required this.exerciseId,
    required this.quality,
    required this.difficultyUsed,
    this.symptomsDuring = const [],
    this.symptomsAfter = const [],
    this.neededSupport = false,
    this.technicalDifficulty = 0.5,
    this.perceivedEffort = 0.5,
    this.notes,
    required this.recordedAt,
  });

  Map<String, dynamic> toMap() => {
    'exerciseId': exerciseId,
    'quality': quality.name,
    'difficultyUsed': difficultyUsed.name,
    'symptomsDuring': symptomsDuring,
    'symptomsAfter': symptomsAfter,
    'neededSupport': neededSupport,
    'technicalDifficulty': technicalDifficulty,
    'perceivedEffort': perceivedEffort,
    'notes': notes,
    'recordedAt': recordedAt.toIso8601String(),
  };

  factory V2Feedback.fromMap(Map<String, dynamic> m) => V2Feedback(
    exerciseId: m['exerciseId'] as String? ?? '',
    quality: _parseQuality(m['quality']),
    difficultyUsed: _parseDifficulty(m['difficultyUsed']),
    symptomsDuring: List<String>.from(m['symptomsDuring'] ?? []),
    symptomsAfter: List<String>.from(m['symptomsAfter'] ?? []),
    neededSupport: m['neededSupport'] as bool? ?? false,
    technicalDifficulty: (m['technicalDifficulty'] as num?)?.toDouble() ?? 0.5,
    perceivedEffort: (m['perceivedEffort'] as num?)?.toDouble() ?? 0.5,
    notes: m['notes'] as String?,
    recordedAt: DateTime.tryParse(m['recordedAt'] as String? ?? '') ?? DateTime.now(),
  );

  static V2FeedbackQuality _parseQuality(dynamic value) {
    if (value == null) return V2FeedbackQuality.executedWell;
    return V2FeedbackQuality.values.firstWhere(
      (e) => e.name == value,
      orElse: () => V2FeedbackQuality.executedWell,
    );
  }

  static V2Difficulty _parseDifficulty(dynamic value) {
    if (value == null) return V2Difficulty.level3;
    return V2Difficulty.values.firstWhere(
      (e) => e.name == value,
      orElse: () => V2Difficulty.level3,
    );
  }
}
