import '../enums/joint.dart';
import '../enums/limitation_severity.dart';
import '../enums/compatibility.dart';
import '../enums/difficulty.dart';
import '../enums/environment.dart';
import '../enums/equipment.dart';
import '../models/v2_exercise.dart';
import '../models/v2_adaptation.dart';

/// Resultado da avaliação de compatibilidade.
class V2CompatibilityResult {
  final V2Compatibility status;
  final String reason;
  final String code;
  final List<V2Adaptation> suggestedAdaptations;

  const V2CompatibilityResult({
    required this.status,
    required this.reason,
    this.code = 'eligible',
    this.suggestedAdaptations = const [],
  });

  bool get isEligible => status == V2Compatibility.compatible;
}

/// Entrada simplificada de limitação do usuário.
class UserLimitationInput {
  final V2Joint joint;
  final V2LimitationSeverity severity;
  final List<String> symptoms;

  const UserLimitationInput({
    required this.joint,
    required this.severity,
    this.symptoms = const [],
  });
}

/// Avaliador de compatibilidade dinâmica entre exercício e contexto.
class V2CompatibilityEvaluator {
  /// Avaliação completa de compatibilidade.
  static V2CompatibilityResult evaluate({
    required V2Exercise exercise,
    required List<V2Environment> userEnvironments,
    required List<V2Equipment> userEquipment,
    required V2Difficulty userDifficulty,
    required List<UserLimitationInput> userLimitations,
    List<String> dislikedExerciseIds = const [],
  }) {
    if (!exercise.equipmentMetadataVerified) {
      return const V2CompatibilityResult(
        status: V2Compatibility.inadequate,
        reason: 'Metadados de equipamento não auditados.',
        code: 'equipment_metadata_unverified',
      );
    }

    if (!_hasRequiredEquipment(exercise, userEquipment)) {
      return const V2CompatibilityResult(
        status: V2Compatibility.inadequate,
        reason: 'Equipamento necessário não disponível.',
        code: 'equipment_not_available',
      );
    }

    if (!_isEnvironmentCompatible(exercise, userEnvironments)) {
      return const V2CompatibilityResult(
        status: V2Compatibility.inadequate,
        reason: 'Ambiente incompatível.',
        code: 'environment_not_supported',
      );
    }

    if (dislikedExerciseIds.contains(exercise.id)) {
      return const V2CompatibilityResult(
        status: V2Compatibility.inadequate,
        reason: 'Exercício marcado como não gostado.',
        code: 'user_disliked',
      );
    }

    if (userDifficulty.index < exercise.difficulty.index - 1) {
      return const V2CompatibilityResult(
        status: V2Compatibility.adaptable,
        reason: 'Exercício avançado demais. Regressão recomendada.',
        code: 'difficulty_too_high',
      );
    }

    final limitationResult = _evaluateLimitations(exercise, userLimitations);
    if (limitationResult != null) return limitationResult;

    return const V2CompatibilityResult(
      status: V2Compatibility.compatible,
      reason: 'Compatível com o contexto atual.',
      code: 'eligible',
    );
  }

  /// Filtra lista de exercícios aos elegíveis.
  static List<V2Exercise> filterEligible({
    required List<V2Exercise> exercises,
    required List<V2Environment> userEnvironments,
    required List<V2Equipment> userEquipment,
    required V2Difficulty userDifficulty,
    required List<UserLimitationInput> userLimitations,
    List<String> dislikedExerciseIds = const [],
  }) {
    return exercises.where((ex) {
      final result = evaluate(
        exercise: ex,
        userEnvironments: userEnvironments,
        userEquipment: userEquipment,
        userDifficulty: userDifficulty,
        userLimitations: userLimitations,
        dislikedExerciseIds: dislikedExerciseIds,
      );
      return result.isEligible;
    }).toList();
  }

  // ── Helpers internos ──

  static bool _hasRequiredEquipment(
    V2Exercise exercise,
    List<V2Equipment> userEquipment,
  ) {
    if (exercise.requiredEquipment.isEmpty) return true;
    final userSet = userEquipment.toSet();
    return exercise.requiredEquipment.every(userSet.contains);
  }

  static bool _isEnvironmentCompatible(
    V2Exercise exercise,
    List<V2Environment> userEnvironments,
  ) {
    if (userEnvironments.contains(V2Environment.any)) return true;
    return exercise.environments.any(userEnvironments.contains);
  }

  static V2CompatibilityResult? _evaluateLimitations(
    V2Exercise exercise,
    List<UserLimitationInput> userLimitations,
  ) {
    final adaptations = <V2Adaptation>[];

    for (final limitation in userLimitations) {
      for (final rule in exercise.limitationRules) {
        if (rule.matches(limitation.joint, limitation.severity)) {
          adaptations.addAll(rule.recommendedAdaptations.map((type) =>
              V2Adaptation(type: type, description: type.name)));

          if (rule.severity == V2LimitationSeverity.severe) {
            return V2CompatibilityResult(
              status: V2Compatibility.inadequate,
              reason: 'Limitação ${limitation.joint.name} com severidade ${limitation.severity.name}.',
              code: 'limitation_severe',
              suggestedAdaptations: adaptations,
            );
          }
        }
      }
    }

    if (adaptations.isNotEmpty) {
      return V2CompatibilityResult(
        status: V2Compatibility.adaptable,
        reason: 'Adaptações disponíveis para limitações atuais.',
        code: 'limitation_adaptable',
        suggestedAdaptations: adaptations,
      );
    }

    return null;
  }
}
