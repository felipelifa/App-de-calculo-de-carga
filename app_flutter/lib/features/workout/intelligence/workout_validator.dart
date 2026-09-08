import '../prescribed_workout_model.dart';
import 'training_context.dart';
import 'training_strategy_engine.dart';

/// Resultado da validação.
class ValidationResult {
  final bool isValid;
  final List<ValidationIssue> issues;

  const ValidationResult({required this.isValid, required this.issues});

  String get summary {
    if (isValid) return 'Sessão válida';
    return issues.map((i) => i.description).join('; ');
  }
}

class ValidationIssue {
  final ValidationSeverity severity;
  final String code;
  final String description;

  const ValidationIssue({
    required this.severity,
    required this.code,
    required this.description,
  });
}

enum ValidationSeverity {
  info,
  warning,
  error,
}

/// Valida a sessão montada.
class WorkoutValidator {
  const WorkoutValidator();

  ValidationResult validate({
    required PrescribedSession session,
    required TrainingContext context,
    required TrainingStrategy strategy,
  }) {
    final issues = <ValidationIssue>[];

    // 1. Equipamento
    _validateEquipment(session, context, issues);

    // 2. Ambiente
    _validateEnvironment(session, context, issues);

    // 3. Nível
    _validateLevel(session, context, issues);

    // 4. Duração
    _validateDuration(session, context, issues);

    // 5. Volume
    _validateVolume(session, strategy, issues);

    // 6. Redundância
    _validateRedundancy(session, issues);

    // 7. Padrões
    _validatePatterns(session, strategy, issues);

    // 8. Papéis
    _validateRoles(session, issues);

    final hasErrors = issues.any((i) => i.severity == ValidationSeverity.error);
    return ValidationResult(
      isValid: !hasErrors,
      issues: issues,
    );
  }

  void _validateEquipment(
    PrescribedSession session,
    TrainingContext context,
    List<ValidationIssue> issues,
  ) {
    final userEquipNames = context.availableEquipment.map((e) => e.name).toSet();
    for (final ex in session.exercises) {
      if (ex.exercise.equipment.isNotEmpty) {
        final hasAll = ex.exercise.equipment.every(userEquipNames.contains);
        if (!hasAll) {
          issues.add(ValidationIssue(
            severity: ValidationSeverity.error,
            code: 'equipment_mismatch',
            description: '${ex.exercise.name} requer equipamento não disponível',
          ));
        }
      }
    }
  }

  void _validateEnvironment(
    PrescribedSession session,
    TrainingContext context,
    List<ValidationIssue> issues,
  ) {
    for (final ex in session.exercises) {
      final envName = context.environment.name;
      if (!ex.exercise.environment.contains(envName) &&
          !ex.exercise.environment.contains('any')) {
        issues.add(ValidationIssue(
          severity: ValidationSeverity.error,
          code: 'environment_mismatch',
          description: '${ex.exercise.name} incompatível com $envName',
        ));
      }
    }
  }

  void _validateLevel(
    PrescribedSession session,
    TrainingContext context,
    List<ValidationIssue> issues,
  ) {
    for (final ex in session.exercises) {
      final diffName = ex.exercise.difficulty;
      final userLevel = context.userDifficulty.index;
      // Map difficulty string to index
      int exerciseLevel;
      switch (diffName) {
        case 'beginner':
          exerciseLevel = 1;
          break;
        case 'intermediate':
          exerciseLevel = 2;
          break;
        case 'advanced':
          exerciseLevel = 3;
          break;
        default:
          exerciseLevel = 1;
      }
      if (exerciseLevel > userLevel + 2) {
        issues.add(ValidationIssue(
          severity: ValidationSeverity.warning,
          code: 'level_too_high',
          description: '${ex.exercise.name} pode ser avançado demais',
        ));
      }
    }
  }

  void _validateDuration(
    PrescribedSession session,
    TrainingContext context,
    List<ValidationIssue> issues,
  ) {
    // Calcular tempo real baseado em sets × (execução + descanso)
    int realTimeSeconds = 300; // 5min warmup
    for (final ex in session.exercises) {
      // Execução: ~45s por série
      realTimeSeconds += ex.sets * 45;
      // Descanso entre séries
      realTimeSeconds += (ex.sets - 1) * ex.restSeconds;
      // Transição: ~30s
      realTimeSeconds += 30;
    }
    final realTimeMinutes = (realTimeSeconds / 60).ceil();

    if (realTimeMinutes > context.sessionDurationMinutes * 1.2) {
      issues.add(ValidationIssue(
        severity: ValidationSeverity.warning,
        code: 'duration_exceeded',
        description: 'Duração real estimada (${realTimeMinutes}min) '
            'excede o tempo disponível (${context.sessionDurationMinutes}min)',
      ));
    }
  }

  void _validateVolume(
    PrescribedSession session,
    TrainingStrategy strategy,
    List<ValidationIssue> issues,
  ) {
    if (session.exercises.length > strategy.volumeTarget.maxExercises + 2) {
      issues.add(ValidationIssue(
        severity: ValidationSeverity.warning,
        code: 'volume_too_high',
        description: 'Número de exercícios (${session.exercises.length}) '
            'acima do recomendado (${strategy.volumeTarget.maxExercises})',
      ));
    }
  }

  void _validateRedundancy(
    PrescribedSession session,
    List<ValidationIssue> issues,
  ) {
    final patterns = session.exercises.map((e) => e.exercise.movementPattern).toList();
    final patternCounts = <String, int>{};
    for (final p in patterns) {
      patternCounts[p] = (patternCounts[p] ?? 0) + 1;
    }

    for (final entry in patternCounts.entries) {
      if (entry.value > 3) {
        issues.add(ValidationIssue(
          severity: ValidationSeverity.warning,
          code: 'pattern_redundancy',
          description: 'Padrão ${entry.key} aparece ${entry.value} vezes',
        ));
      }
    }
  }

  void _validatePatterns(
    PrescribedSession session,
    TrainingStrategy strategy,
    List<ValidationIssue> issues,
  ) {
    final sessionPatterns = session.exercises
        .map((e) => e.exercise.movementPattern)
        .toSet();

    final requiredPatterns = strategy.requiredPatterns.toSet();
    final missing = requiredPatterns.difference(sessionPatterns);

    if (missing.length > 1) {
      issues.add(ValidationIssue(
        severity: ValidationSeverity.info,
        code: 'patterns_missing',
        description: 'Padrões ausentes: ${missing.map((p) => p.name).join(', ')}',
      ));
    }
  }

  void _validateRoles(
    PrescribedSession session,
    List<ValidationIssue> issues,
  ) {
    final hasPrincipal = session.exercises.any((e) =>
        e.decisionReason?.contains('fulfillsPrimaryPattern') == true);

    if (!hasPrincipal && session.exercises.isNotEmpty) {
      issues.add(ValidationIssue(
        severity: ValidationSeverity.info,
        code: 'no_principal_exercise',
        description: 'Nenhum exercício principal encontrado',
      ));
    }
  }
}
