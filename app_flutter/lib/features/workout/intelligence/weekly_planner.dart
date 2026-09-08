import '../../exercise_library_v2/enums/movement_pattern.dart';
import 'training_context.dart';
import 'training_strategy_engine.dart';
import 'session_blueprint.dart';
import 'workout_composer.dart';
import 'exercise_selection_engine.dart';
import '../prescribed_workout_model.dart';
import '../../exercise_library_v2/models/v2_exercise.dart';

/// Planejador semanal de treinos.
class WeeklyPlanner {
  const WeeklyPlanner();

  /// Gera o plano semanal completo.
  GeneratedWorkout generate({
    required List<V2Exercise> exercises,
    required TrainingContext context,
    required TrainingStrategy strategy,
  }) {
    final selectionEngine = ExerciseSelectionEngine(exercises);
    final composer = WorkoutComposer();
    final blueprintGenerator = BlueprintGenerator();

    final sessions = <PrescribedSession>[];

    for (var dayIndex = 0; dayIndex < context.availableDaysPerWeek; dayIndex++) {
      // Criar estratégia variada para este dia
      final dayStrategy = _dayStrategy(strategy, dayIndex, context.availableDaysPerWeek);
      final blueprint = blueprintGenerator.generate(dayStrategy, context.sessionDurationMinutes);

      // Selecionar exercícios
      final selected = selectionEngine.select(
        blueprint: blueprint,
        context: context,
        strategy: dayStrategy,
        recentExerciseIds: sessions
            .expand((s) => s.exercises)
            .map((e) => e.exercise.id)
            .toList(),
      );

      // Compor sessão
      final session = composer.compose(
        selected: selected,
        context: context,
        strategy: dayStrategy,
        sessionIndex: dayIndex,
      );

      sessions.add(session);
    }

    return GeneratedWorkout(
      id: 'weekly_${DateTime.now().millisecondsSinceEpoch}',
      userId: context.uid,
      splitType: 'intelligent_split',
      periodizationModel: 'strategy_based',
      sessions: sessions,
      mesocycleDurationWeeks: 4,
      generatedAt: DateTime.now(),
      planExplanation: _planExplanation(strategy, context),
    );
  }

  /// Determina estratégia variada para cada dia.
  TrainingStrategy _dayStrategy(
    TrainingStrategy baseStrategy,
    int dayIndex,
    int totalDays,
  ) {
    // Para 1 dia: tudo junto
    if (totalDays == 1) return baseStrategy;

    // Para 2 dias: upper/lower ou push/pull
    if (totalDays == 2) {
      if (dayIndex == 0) {
        return _emphasisStrategy(baseStrategy, DayEmphasis.upperBody);
      } else {
        return _emphasisStrategy(baseStrategy, DayEmphasis.lowerBody);
      }
    }

    // Para 3+ dias: rotação de ênfase
    final emphases = [
      DayEmphasis.push,
      DayEmphasis.pull,
      DayEmphasis.legs,
    ];

    final emphasis = emphases[dayIndex % emphases.length];
    return _emphasisStrategy(baseStrategy, emphasis);
  }

  /// Cria estratégia com ênfase específica.
  TrainingStrategy _emphasisStrategy(TrainingStrategy base, DayEmphasis emphasis) {
    final patterns = <V2MovementPattern>[];

    switch (emphasis) {
      case DayEmphasis.upperBody:
        patterns.addAll([
          V2MovementPattern.pushHorizontal,
          V2MovementPattern.pullHorizontal,
          V2MovementPattern.pushVertical,
        ]);
        break;
      case DayEmphasis.lowerBody:
        patterns.addAll([
          V2MovementPattern.squat,
          V2MovementPattern.hipHinge,
          V2MovementPattern.hipExtension,
        ]);
        break;
      case DayEmphasis.push:
        patterns.addAll([
          V2MovementPattern.pushHorizontal,
          V2MovementPattern.pushVertical,
          V2MovementPattern.squat,
        ]);
        break;
      case DayEmphasis.pull:
        patterns.addAll([
          V2MovementPattern.pullHorizontal,
          V2MovementPattern.hipHinge,
          V2MovementPattern.coreAntiExtension,
        ]);
        break;
      case DayEmphasis.legs:
        patterns.addAll([
          V2MovementPattern.squat,
          V2MovementPattern.hipHinge,
          V2MovementPattern.hipExtension,
        ]);
        break;
    }

    return TrainingStrategy(
      primaryGoal: base.primaryGoal,
      secondaryGoals: base.secondaryGoals,
      goalPriority: base.goalPriority,
      prioritizedCapacities: base.prioritizedCapacities,
      requiredPatterns: patterns,
      stimulusDistribution: base.stimulusDistribution,
      volumeTarget: base.volumeTarget,
      intensityTarget: base.intensityTarget,
      sessionStructure: base.sessionStructure,
      needsPreparation: base.needsPreparation,
      needsConditioning: base.needsConditioning,
      needsCore: base.needsCore,
      needsFinisher: base.needsFinisher,
      needsMobility: base.needsMobility,
      needsBalance: base.needsBalance,
      complexityLevel: base.complexityLevel,
    );
  }

  /// Explicação do plano.
  String _planExplanation(TrainingStrategy strategy, TrainingContext context) {
    return 'Plano semanal de ${context.availableDaysPerWeek} dias '
        'com foco em ${strategy.primaryGoal.name}. '
        'Cada dia possui ênfase diferente para maximizar recuperação e cobertura.';
  }
}

/// Ênfase do dia.
enum DayEmphasis {
  upperBody,
  lowerBody,
  push,
  pull,
  legs,
}
