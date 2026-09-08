import 'package:flutter/foundation.dart';

import '../../exercise_library_v2/v2_exercise_library.dart';
import '../../exercise_library_v2/enums/exercise_block.dart';
import '../prescribed_workout_model.dart';
import 'user_training_profile.dart';
import 'training_context.dart';
import 'training_strategy_engine.dart';
import 'session_blueprint.dart';
import 'exercise_selection_engine.dart';
import 'workout_composer.dart';
import 'weekly_planner.dart';
import 'workout_validator.dart';

/// Orquestrador principal do sistema de inteligência de prescrição.
///
/// Fluxo:
/// UserTrainingProfile → TrainingContext → TrainingStrategy
/// → SessionBlueprint → ExerciseSelection → WorkoutComposer → Workout
class TrainingIntelligence {
  final TrainingStrategyEngine _strategyEngine;
  final BlueprintGenerator _blueprintGenerator;
  final WorkoutComposer _composer;
  final WeeklyPlanner _weeklyPlanner;
  final WorkoutValidator _validator;

  TrainingIntelligence()
      : _strategyEngine = const TrainingStrategyEngine(),
        _blueprintGenerator = const BlueprintGenerator(),
        _composer = const WorkoutComposer(),
        _weeklyPlanner = const WeeklyPlanner(),
        _validator = const WorkoutValidator();

  /// Gera treino completo a partir do perfil do usuário.
  ///
  /// [weekNumber] permite progressão ao longo das semanas (1-4).
  /// Semana 1 = base, Semana 4 = maior volume/intensidade.
  GeneratedWorkout generateWorkout(
    UserTrainingProfile profile, {
    int weekNumber = 1,
  }) {
    debugPrint('TRAINING_INTELLIGENCE: Iniciando geração para ${profile.uid} '
        '(semana $weekNumber)');

    // 1. Criar contexto
    final context = TrainingContext.fromProfile(profile);
    debugPrint('  Contexto: ${context.primaryGoal.name}, ${context.environment.name}, '
        '${context.availableDaysPerWeek} dias, ${context.sessionDurationMinutes}min');

    // 2. Determinar estratégia (com progressão)
    final strategy = _strategyEngine.determine(context, weekNumber: weekNumber);
    debugPrint('  Estratégia: ${strategy.goalPriority.primary.name}, '
        'complexidade: ${strategy.complexityLevel.name}, '
        'semana: $weekNumber');

    // 3. Verificar se há exercícios disponíveis
    final library = V2ExerciseLibrary();
    final available = library.getByBlock(V2ExerciseBlock.home);

    if (available.isEmpty) {
      debugPrint('  ERRO: Nenhum exercício V2 disponível');
      return _generateFallback(profile);
    }

    debugPrint('  Exercícios disponíveis: ${available.length}');

    // 4. Gerar plano semanal
    final workout = _weeklyPlanner.generate(
      exercises: available,
      context: context,
      strategy: strategy,
    );

    // 5. Validar cada sessão
    for (var i = 0; i < workout.sessions.length; i++) {
      final validation = _validator.validate(
        session: workout.sessions[i],
        context: context,
        strategy: strategy,
      );

      if (!validation.isValid) {
        debugPrint('  Sessão ${i + 1} inválida: ${validation.summary}');
      } else {
        debugPrint('  Sessão ${i + 1} válida: ${workout.sessions[i].exercises.length} exercícios');
      }
    }

    debugPrint('TRAINING_INTELLIGENCE: Geração concluída — '
        '${workout.sessions.length} sessões');

    return workout;
  }

  /// Gera apenas uma sessão (para testes).
  PrescribedSession generateSingleSession(UserTrainingProfile profile) {
    final context = TrainingContext.fromProfile(profile);
    final strategy = _strategyEngine.determine(context);

    final library = V2ExerciseLibrary();
    final available = library.getByBlock(V2ExerciseBlock.home);

    final blueprint = _blueprintGenerator.generate(
      strategy,
      context.sessionDurationMinutes,
    );

    final selectionEngine = ExerciseSelectionEngine(available);
    final selected = selectionEngine.select(
      blueprint: blueprint,
      context: context,
      strategy: strategy,
    );

    return _composer.compose(
      selected: selected,
      context: context,
      strategy: strategy,
      sessionIndex: 0,
    );
  }

  /// Gera treino de fallback quando não há exercícios V2.
  GeneratedWorkout _generateFallback(UserTrainingProfile profile) {
    debugPrint('  Usando fallback V1 (sem exercícios V2)');
    return GeneratedWorkout(
      id: 'fallback_${DateTime.now().millisecondsSinceEpoch}',
      userId: profile.uid,
      splitType: 'fallback',
      periodizationModel: 'manual',
      sessions: [],
      mesocycleDurationWeeks: 4,
      generatedAt: DateTime.now(),
      planExplanation: 'Nenhum exercício V2 disponível. Usando fallback.',
    );
  }

  /// Acessa a estratégia para um perfil (para debug/testes).
  TrainingStrategy getStrategy(UserTrainingProfile profile, {int weekNumber = 1}) {
    final context = TrainingContext.fromProfile(profile);
    return _strategyEngine.determine(context, weekNumber: weekNumber);
  }

  /// Acessa o blueprint para uma estratégia (para debug/testes).
  SessionBlueprint getBlueprint(TrainingStrategy strategy, int duration) {
    return _blueprintGenerator.generate(strategy, duration);
  }
}
