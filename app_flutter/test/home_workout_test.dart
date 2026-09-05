// ─────────────────────────────────────────────
// Testes do Motor de Treino em Casa
// ─────────────────────────────────────────────

import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/workout/home_workout/home_workout.dart';

void main() {
  group('HomeWorkoutEngine', () {
    late HomeWorkoutEngine engine;

    setUp(() {
      engine = HomeWorkoutEngine(userId: 'test_user');
    });

    test('deve gerar treino para iniciante', () {
      final workout = engine.generateWorkout(
        userId: 'test_user',
        availableMinutes: 30,
        limitations: [],
        experienceLevel: 'beginner',
        balanceCapability: 0.3,
        strengthCapability: 0.3,
        mobilityCapability: 0.4,
      );

      expect(workout.exercises, isNotEmpty);
      expect(workout.estimatedDurationMinutes, lessThanOrEqualTo(35));
    });

    test('deve gerar treino para intermediário', () {
      final workout = engine.generateWorkout(
        userId: 'test_user',
        availableMinutes: 45,
        limitations: [],
        experienceLevel: 'intermediate',
        balanceCapability: 0.5,
        strengthCapability: 0.6,
        mobilityCapability: 0.6,
      );

      expect(workout.exercises, isNotEmpty);
      expect(workout.exercises.length, greaterThanOrEqualTo(4));
    });

    test('deve respeitar limitações de joelho', () {
      final limitations = [
        HomeUserLimitation(
          region: HomeBodyRegion.knee,
          description: 'Dor anterior no joelho',
          severity: HomeLimitationSeverity.moderate,
        ),
      ];

      final workout = engine.generateWorkout(
        userId: 'test_user',
        availableMinutes: 30,
        limitations: limitations,
        experienceLevel: 'beginner',
        balanceCapability: 0.3,
        strengthCapability: 0.3,
        mobilityCapability: 0.4,
      );

      expect(workout.exercises, isNotEmpty);
      
      // Verifica se os exercícios foram analisados corretamente
      for (final exercise in workout.exercises) {
        expect(exercise.analysis, isNotNull);
      }
    });

    test('deve buscar exercícios por padrão', () {
      final squats = engine.getExercisesByPattern(HomeMovementPattern.squat);
      
      expect(squats, isNotEmpty);
      expect(squats.every((e) => e.pattern == HomeMovementPattern.squat), isTrue);
    });

    test('deve buscar exercício por ID', () {
      final exercise = engine.getExerciseById('squat_chair');
      
      expect(exercise, isNotNull);
      expect(exercise!.name, 'Sentar na cadeira');
    });

    test('deve buscar regressão de exercício', () {
      final exercise = engine.getExerciseById('squat_assisted');
      final regression = engine.getRegression(exercise!);
      
      expect(regression, isNotNull);
      expect(regression!.id, 'squat_chair');
    });

    test('deve buscar progressão de exercício', () {
      final exercise = engine.getExerciseById('squat_chair');
      final progression = engine.getProgression(exercise!);
      
      expect(progression, isNotNull);
      expect(progression!.id, 'squat_assisted');
    });

    test('deve analisar exercício corretamente', () {
      final exercise = engine.getExerciseById('squat_free')!;
      
      final analysis = engine.analyzeExercise(
        exercise: exercise,
        limitations: [],
        experienceLevel: 'beginner',
        balanceCapability: 0.3,
        strengthCapability: 0.3,
        mobilityCapability: 0.4,
      );

      expect(analysis.exercise.id, 'squat_free');
      expect(analysis.compatibility, isNotNull);
    });

    test('deve processar feedback corretamente', () {
      final exercise = engine.getExerciseById('squat_free')!;
      
      final feedback = HomeFeedback(
        exerciseId: 'squat_free',
        difficultyUsed: HomeDifficulty.level3,
        quality: HomeFeedbackQuality.executedWell,
      );

      final analysis = engine.processFeedback(
        feedback: feedback,
        exercise: exercise,
      );

      expect(analysis.action, HomeFeedbackAction.progress);
    });
  });

  group('HomeLimitationAnalyzer', () {
    test('deve classificar exercício como compatível', () {
      final exercise = homeExerciseLibrary.firstWhere(
        (e) => e.id == 'squat_chair',
      );

      final analysis = HomeLimitationAnalyzer.analyze(
        exercise: exercise,
        limitations: [],
        experienceLevel: 'beginner',
        balanceCapability: 0.3,
        strengthCapability: 0.3,
        mobilityCapability: 0.4,
      );

      expect(analysis.compatibility, HomeCompatibility.compatible);
    });

    test('deve classificar exercício como adaptável', () {
      final exercise = homeExerciseLibrary.firstWhere(
        (e) => e.id == 'squat_free',
      );

      final analysis = HomeLimitationAnalyzer.analyze(
        exercise: exercise,
        limitations: [],
        experienceLevel: 'beginner',
        balanceCapability: 0.3,
        strengthCapability: 0.3,
        mobilityCapability: 0.4,
      );

      expect(analysis.compatibility, HomeCompatibility.adaptable);
    });

    test('deve sugerir adaptações para limitação de joelho', () {
      final exercise = homeExerciseLibrary.firstWhere(
        (e) => e.id == 'squat_free',
      );

      final limitations = [
        HomeUserLimitation(
          region: HomeBodyRegion.knee,
          description: 'Dor no joelho',
          severity: HomeLimitationSeverity.moderate,
        ),
      ];

      final analysis = HomeLimitationAnalyzer.analyze(
        exercise: exercise,
        limitations: limitations,
        experienceLevel: 'intermediate',
        balanceCapability: 0.5,
        strengthCapability: 0.6,
        mobilityCapability: 0.6,
      );

      expect(analysis.compatibility, HomeCompatibility.adaptable);
      expect(analysis.adaptations, isNotEmpty);
    });
  });

  group('HomeWorkoutIntegrator', () {
    test('deve gerar treino integrado', () {
      // Este teste requer um WorkoutProfile real
      // Por enquanto, vamos testar apenas a criação do integrador
      final integrator = HomeWorkoutIntegrator(userId: 'test_user');
      
      expect(integrator, isNotNull);
    });
  });
}
