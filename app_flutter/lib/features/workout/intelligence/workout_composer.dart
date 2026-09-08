import '../../exercise_library_v2/enums/exercise_role.dart';
import '../../exercise_library_v2/enums/goal.dart';
import '../../exercise_library_v2/bridge/v2_home_bridge.dart';
import '../prescribed_workout_model.dart';
import 'training_context.dart';
import 'training_strategy_engine.dart';
import 'exercise_selection_engine.dart';

/// Compõe a sessão final a partir dos exercícios selecionados.
class WorkoutComposer {
  const WorkoutComposer();

  /// Compõe uma sessão de treino.
  PrescribedSession compose({
    required List<SelectedExercise> selected,
    required TrainingContext context,
    required TrainingStrategy strategy,
    required int sessionIndex,
  }) {
    // 1. Ordenar por papel (preparação → principal → acessório → core)
    final ordered = _orderByRole(selected);

    // 2. Prescrever cada exercício
    final prescribed = ordered.map((sel) {
      return _prescribeExercise(
        selected: sel,
        context: context,
        strategy: strategy,
      );
    }).toList();

    // 3. Estimar duração
    final estimatedMinutes = _estimateDuration(prescribed, strategy);

    // 4. Gerar warmup
    final warmup = _generateWarmup(strategy, context);

    return PrescribedSession(
      id: 'session_${sessionIndex + 1}',
      name: _sessionName(strategy, sessionIndex),
      objective: _sessionObjective(strategy, context),
      estimatedDurationMinutes: estimatedMinutes,
      warmupInstructions: warmup,
      exercises: prescribed,
      progressionNote: _progressionNote(strategy, context),
    );
  }

  /// Prescreve um exercício individual.
  PrescribedExercise _prescribeExercise({
    required SelectedExercise selected,
    required TrainingContext context,
    required TrainingStrategy strategy,
  }) {
    final exercise = selected.exercise;
    final v2Exercise = V2HomeBridge.getV2Exercise(exercise.id);
    final engineRules = v2Exercise?.engineRules;

    // Usar V2EngineRules como base
    var repsMin = engineRules?.repRangeMin ?? 8;
    var repsMax = engineRules?.repRangeMax ?? 12;
    var restSeconds = engineRules?.defaultRestSeconds ?? strategy.intensityTarget.defaultRestSeconds;

    // Para condicionamento, limitar descanso ao máximo da estratégia
    if (context.primaryGoal == V2Goal.conditioning ||
        context.primaryGoal == V2Goal.fatLoss) {
      if (restSeconds > strategy.intensityTarget.defaultRestSeconds) {
        restSeconds = strategy.intensityTarget.defaultRestSeconds;
      }
    }

    // Ajustar séries pela estratégia + idade
    var sets = strategy.volumeTarget.setsPerExercise;
    if (context.age >= 50) sets = (sets - 1).clamp(2, 4);

    // Ajustar RIR pelo contexto + idade
    var rir = _adjustRir(strategy.intensityTarget.targetRir, selected.role);
    if (context.age >= 50) rir = (rir + 1).clamp(1, 3);

    // Ajustar reps por duração
    if (context.shortSession) {
      repsMax = (repsMax - 2).clamp(repsMin, 20);
      restSeconds = (restSeconds - 15).clamp(30, 180);
    }

    // Tempo baseado no objetivo
    final tempo = _determineTempo(context, strategy);

    // Cues do exercício
    final sessionCues = exercise.cues;

    return PrescribedExercise(
      exercise: V2HomeBridge.toExerciseModel(exercise),
      sets: sets,
      repsMin: repsMin,
      repsMax: repsMax,
      rir: rir,
      restSeconds: restSeconds,
      tempo: tempo,
      sessionCues: sessionCues,
      progressionNote: _exerciseProgressionNote(selected, strategy),
      decisionReason: selected.reasons.join(', '),
      selectionScore: selected.score,
    );
  }

  /// Ajusta RIR pelo papel do exercício.
  int _adjustRir(int baseRir, V2ExerciseRole role) {
    switch (role) {
      case V2ExerciseRole.principal:
        return (baseRir - 1).clamp(0, 3);
      case V2ExerciseRole.complementary:
        return baseRir;
      case V2ExerciseRole.accessory:
        return (baseRir + 1).clamp(0, 3);
      case V2ExerciseRole.conditioning:
        return baseRir;
      case V2ExerciseRole.preparation:
        return 3;
      case V2ExerciseRole.mobility:
        return 3;
      case V2ExerciseRole.finisher:
        return (baseRir - 1).clamp(0, 3);
    }
  }

  /// Determina tempo baseado no objetivo.
  String _determineTempo(TrainingContext context, TrainingStrategy strategy) {
    switch (context.primaryGoal) {
      case V2Goal.hypertrophy:
        return '3-0-2';
      case V2Goal.strength:
        return '2-1-1';
      case V2Goal.endurance:
        return '2-0-1';
      case V2Goal.conditioning:
        return '2-0-1';
      case V2Goal.mobility:
        return '3-2-3';
      case V2Goal.generalFitness:
        return '2-0-2';
      default:
        return '2-0-2';
    }
  }

  /// Ordena exercícios por papel.
  List<SelectedExercise> _orderByRole(List<SelectedExercise> exercises) {
    final order = {
      V2ExerciseRole.preparation: 0,
      V2ExerciseRole.principal: 1,
      V2ExerciseRole.complementary: 2,
      V2ExerciseRole.accessory: 3,
      V2ExerciseRole.mobility: 4,
      V2ExerciseRole.conditioning: 5,
      V2ExerciseRole.finisher: 6,
    };

    return List<SelectedExercise>.from(exercises)
      ..sort((a, b) => (order[a.role] ?? 5).compareTo(order[b.role] ?? 5));
  }

  /// Estima duração total.
  int _estimateDuration(List<PrescribedExercise> exercises, TrainingStrategy strategy) {
    int totalSeconds = 0;
    for (final ex in exercises) {
      // Tempo de execução: ~45s por série
      totalSeconds += (ex.sets * 45).toInt();
      // Descanso entre séries
      totalSeconds += ((ex.sets - 1) * ex.restSeconds).toInt();
    }
    // Transições: ~30s por exercício
    totalSeconds += (exercises.length * 30).toInt();
    // Warmup: ~5 minutos
    totalSeconds += 300;

    return (totalSeconds / 60).ceil();
  }

  /// Gera instruções de aquecimento.
  List<String> _generateWarmup(TrainingStrategy strategy, TrainingContext context) {
    final warmup = <String>[
      '5 minutos de mobilidade articular geral',
    ];

    if (strategy.needsMobility) {
      warmup.add('Alongamento dinâmico das regiões de maior necessidade');
    }

    if (strategy.needsBalance) {
      warmup.add('Ativação de core: prancha leve por 30 segundos');
    }

    warmup.add('Ativação dos padrões que serão utilizados na sessão');

    return warmup;
  }

  /// Nome da sessão.
  String _sessionName(TrainingStrategy strategy, int index) {
    final goalName = strategy.primaryGoal.name;
    return 'Treino $goalName — Sessão ${index + 1}';
  }

  /// Objetivo da sessão.
  String _sessionObjective(TrainingStrategy strategy, TrainingContext context) {
    return 'Treino de ${strategy.primaryGoal.name} '
        'para ${context.environment.name} '
        'com foco em ${strategy.requiredPatterns.length} padrões de movimento';
  }

  /// Nota de progressão da sessão.
  String _progressionNote(TrainingStrategy strategy, TrainingContext context) {
    return 'Progressão baseada em: ${strategy.goalPriority.primary.name}. '
        'Aumente carga, repetições ou complexidade conforme dominar.';
  }

  /// Nota de progressão do exercício.
  String _exerciseProgressionNote(SelectedExercise selected, TrainingStrategy strategy) {
    final reasons = selected.reasons.join(', ');
    return 'Selecionado por: $reasons';
  }
}
