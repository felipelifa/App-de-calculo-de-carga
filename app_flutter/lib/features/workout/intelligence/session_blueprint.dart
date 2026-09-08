import '../../exercise_library_v2/enums/movement_pattern.dart';
import '../../exercise_library_v2/enums/exercise_role.dart';
import 'training_strategy_engine.dart';

/// Blueprint da sessão de treino.
/// Define o que a sessão precisa, sem escolher exercícios.
class SessionBlueprint {
  final List<BlueprintSlot> slots;
  final int estimatedDurationMinutes;
  final String description;

  const SessionBlueprint({
    required this.slots,
    required this.estimatedDurationMinutes,
    required this.description,
  });

  /// Número total de exercícios necessários.
  int get totalExercises => slots.length;

  /// Número de slots por papel.
  int get principalCount => slots.where((s) => s.role == V2ExerciseRole.principal).length;
  int get complementaryCount => slots.where((s) => s.role == V2ExerciseRole.complementary).length;
  int get accessoryCount => slots.where((s) => s.role == V2ExerciseRole.accessory).length;
  int get preparationCount => slots.where((s) => s.role == V2ExerciseRole.preparation).length;
  int get coreCount => slots.where((s) => s.role == V2ExerciseRole.mobility).length;
}

/// Slot individual do blueprint.
class BlueprintSlot {
  final V2ExerciseRole role;
  final V2MovementPattern? preferredPattern;
  final List<V2MovementPattern> acceptablePatterns;
  final String targetMuscleGroup;
  final int priority; // 1 = obrigatório, 2 = importante, 3 = opcional

  const BlueprintSlot({
    required this.role,
    this.preferredPattern,
    this.acceptablePatterns = const [],
    this.targetMuscleGroup = '',
    this.priority = 2,
  });
}

/// Gera blueprints a partir da estratégia.
class BlueprintGenerator {
  const BlueprintGenerator();

  SessionBlueprint generate(TrainingStrategy strategy, int sessionDurationMinutes) {
    final slots = <BlueprintSlot>[];

    // ── FASE 1: Preparação ──
    if (strategy.needsPreparation) {
      slots.add(BlueprintSlot(
        role: V2ExerciseRole.preparation,
        preferredPattern: V2MovementPattern.mobility,
        targetMuscleGroup: 'full_body',
        priority: 3,
      ));
    }

    // ── FASE 2: Principal ──
    // Adicionar slots para cada padrão necessário
    for (final pattern in strategy.requiredPatterns) {
      slots.add(BlueprintSlot(
        role: V2ExerciseRole.principal,
        preferredPattern: pattern,
        acceptablePatterns: _relatedPatterns(pattern),
        targetMuscleGroup: _patternToMuscleGroup(pattern),
        priority: 1,
      ));
    }

    // ── FASE 3: Complementar/Acessório ──
    if (strategy.sessionStructure.phases.contains(SessionPhase.accessory)) {
      slots.add(BlueprintSlot(
        role: V2ExerciseRole.accessory,
        preferredPattern: V2MovementPattern.hipAbduction,
        targetMuscleGroup: 'glutes',
        priority: 2,
      ));
    }

    // ── FASE 4: Core ──
    if (strategy.needsCore) {
      slots.add(BlueprintSlot(
        role: V2ExerciseRole.accessory,
        preferredPattern: V2MovementPattern.coreAntiExtension,
        targetMuscleGroup: 'core',
        priority: 2,
      ));
    }

    // ── FASE 5: Condicionamento ──
    if (strategy.needsConditioning) {
      slots.add(BlueprintSlot(
        role: V2ExerciseRole.conditioning,
        preferredPattern: V2MovementPattern.conditioning,
        targetMuscleGroup: 'full_body',
        priority: 2,
      ));
    }

    // ── Limitar pelo tempo e volume ──
    final limitedSlots = _limitByDuration(slots, sessionDurationMinutes, strategy);

    return SessionBlueprint(
      slots: limitedSlots,
      estimatedDurationMinutes: sessionDurationMinutes,
      description: strategy.sessionStructure.description,
    );
  }

  List<BlueprintSlot> _limitByDuration(
    List<BlueprintSlot> slots,
    int durationMinutes,
    TrainingStrategy strategy,
  ) {
    // Usar volume target como limite máximo
    final maxByVolume = strategy.volumeTarget.maxExercises;

    // Estimar tempo por exercício: execução + descanso
    final timePerExercise = strategy.intensityTarget.defaultRestSeconds + 45; // ~45s execução
    final maxByTime = (durationMinutes * 60 / timePerExercise).floor();

    // Usar o menor dos dois limites
    final maxExercises = maxByVolume < maxByTime ? maxByVolume : maxByTime;

    if (slots.length <= maxExercises) return slots;

    // Priorizar: principal > complementar > acessório > preparação
    final sorted = List<BlueprintSlot>.from(slots)
      ..sort((a, b) => a.priority.compareTo(b.priority));

    return sorted.take(maxExercises).toList();
  }

  List<V2MovementPattern> _relatedPatterns(V2MovementPattern pattern) {
    switch (pattern) {
      case V2MovementPattern.squat:
        return [V2MovementPattern.kneeExtension, V2MovementPattern.hipExtension];
      case V2MovementPattern.hipHinge:
        return [V2MovementPattern.hipExtension, V2MovementPattern.kneeFlexion];
      case V2MovementPattern.pushHorizontal:
        return [V2MovementPattern.pushVertical, V2MovementPattern.pushIncline];
      case V2MovementPattern.pullHorizontal:
        return [V2MovementPattern.pullVertical];
      case V2MovementPattern.coreAntiExtension:
        return [V2MovementPattern.coreAntiRotation, V2MovementPattern.coreAntiLateralFlexion];
      default:
        return [];
    }
  }

  String _patternToMuscleGroup(V2MovementPattern pattern) {
    switch (pattern) {
      case V2MovementPattern.squat:
      case V2MovementPattern.kneeExtension:
        return 'quadriceps';
      case V2MovementPattern.hipHinge:
      case V2MovementPattern.hipExtension:
      case V2MovementPattern.kneeFlexion:
        return 'posterior_chain';
      case V2MovementPattern.pushHorizontal:
      case V2MovementPattern.pushVertical:
      case V2MovementPattern.pushIncline:
        return 'push';
      case V2MovementPattern.pullHorizontal:
      case V2MovementPattern.pullVertical:
        return 'pull';
      case V2MovementPattern.coreAntiExtension:
      case V2MovementPattern.coreAntiRotation:
      case V2MovementPattern.coreAntiLateralFlexion:
      case V2MovementPattern.coreFlexion:
      case V2MovementPattern.coreRotation:
        return 'core';
      case V2MovementPattern.conditioning:
        return 'full_body';
      case V2MovementPattern.mobility:
        return 'full_body';
      case V2MovementPattern.balance:
        return 'stability';
      default:
        return 'general';
    }
  }
}
