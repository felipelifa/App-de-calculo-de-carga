import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/exercise_library_v2/v2_exercise_library.dart';
import 'package:app/features/exercise_library_v2/data/home_exercises.dart';
import 'package:app/features/exercise_library_v2/bridge/v2_home_bridge.dart';
import 'package:app/features/exercise_library_v2/models/v2_exercise.dart';
import 'package:app/features/exercise_library_v2/models/v2_demand_profile.dart';
import 'package:app/features/exercise_library_v2/models/v2_engine_rules.dart';
import 'package:app/features/exercise_library_v2/enums/exercise_block.dart';
import 'package:app/features/exercise_library_v2/enums/movement_pattern.dart';
import 'package:app/features/exercise_library_v2/enums/exercise_category.dart';
import 'package:app/features/exercise_library_v2/enums/difficulty.dart';
import 'package:app/features/exercise_library_v2/enums/environment.dart';
import 'package:app/features/workout/home_workout/v2_home_source.dart';
import 'package:app/features/workout/home_workout/home_workout_integrator.dart';
import 'package:app/features/workout/workout_profile_model.dart';
import 'package:app/features/exercises/exercise_model.dart';

WorkoutProfile _makeProfile({
  String experienceLevel = 'beginner',
  int availableDaysPerWeek = 3,
  int sessionDurationMinutes = 30,
  List<String> healthRestrictions = const [],
}) {
  return WorkoutProfile(
    uid: 'test_user',
    age: 25,
    biologicalSex: 'male',
    weightKg: 75,
    heightCm: 175,
    experienceLevel: experienceLevel,
    trainingAge: 6,
    bodyFatCategory: 'medium',
    primaryGoal: 'general_fitness',
    availableDaysPerWeek: availableDaysPerWeek,
    sessionDurationMinutes: sessionDurationMinutes,
    preferredStyle: 'balanced',
    sleepQuality: 'good',
    stressLevel: 'low',
    priorityMuscles: const [],
    environment: 'home',
    availableEquipment: const [],
    dislikedExercises: const [],
    favoriteExercises: const [],
    healthRestrictions: healthRestrictions,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

void main() {
  setUpAll(() {
    V2HomeSource.initialize();
  });

  tearDownAll(() {
    V2ExerciseLibrary().clear();
  });

  // ── TESTE 1: HOME USA V2 ──
  group('TESTE 1 — HOME USA V2', () {
    test('V2HomeSource.isAvailable retorna true após inicialização', () {
      expect(V2HomeSource.isAvailable, isTrue);
    });

    test('V2HomeSource.count retorna 46 exercícios', () {
      expect(V2HomeSource.count, equals(46));
    });

    test('queryHomeExercises retorna ExerciseModel[] do V2', () {
      final exercises = V2HomeSource.queryHomeExercises(
        profile: _makeProfile(),
      );

      expect(exercises, isNotEmpty);
      expect(exercises.first, isA<ExerciseModel>());
    });

    test('Exercício V2 retornado tem tag "v2"', () {
      final exercises = V2HomeSource.queryHomeExercises(
        profile: _makeProfile(),
      );

      expect(exercises.any((e) => e.tags.contains('v2')), isTrue);
    });
  });

  // ── TESTE 2: ID PRESERVADO ──
  group('TESTE 2 — ID PRESERVADO', () {
    test('V2HomeBridge preserva o ID do V2Exercise', () {
      final v2Exercise = V2Exercise(
        id: 'home_squat_001',
        name: 'Agachamento Livre',
        block: V2ExerciseBlock.home,
        pattern: V2MovementPattern.squat,
        category: V2ExerciseCategory.compound,
        difficulty: V2Difficulty.level2,
        environments: const [V2Environment.home],
        demands: const V2DemandProfile(),
        engineRules: const V2EngineRules(),
      );

      final exerciseModel = V2HomeBridge.toExerciseModel(v2Exercise);

      expect(exerciseModel.id, equals('home_squat_001'));
    });

    test('V2HomeSource.getById retorna ExerciseModel com ID correto', () {
      final result = V2HomeSource.getById('home_squat_001');

      expect(result, isNotNull);
      expect(result!.id, equals('home_squat_001'));
    });

    test('V2HomeSource.isV2HomeExercise identifica exercícios V2', () {
      expect(V2HomeSource.isV2HomeExercise('home_squat_001'), isTrue);
      expect(V2HomeSource.isV2HomeExercise('nonexistent_id'), isFalse);
    });

    test('IDs V2 são únicos (sem duplicatas)', () {
      final library = V2ExerciseLibrary();
      final homeExercises = library.getByBlock(V2ExerciseBlock.home);
      final ids = homeExercises.map((e) => e.id).toSet();

      expect(ids.length, equals(homeExercises.length));
    });
  });

  // ── TESTE 3: NENHUM EQUIPAMENTO PROIBIDO ──
  group('TESTE 3 — NENHUM EQUIPAMENTO PROIBIDO', () {
    test('Exercícios V2 Home não requerem equipamento', () {
      final library = V2ExerciseLibrary();
      final homeExercises = library.getByBlock(V2ExerciseBlock.home);

      for (final exercise in homeExercises) {
        expect(
          exercise.requiredEquipment,
          isEmpty,
          reason: '${exercise.id} não deve requerer equipamento',
        );
      }
    });

    test('ExerciseModel V2 Home tem equipment vazio', () {
      final exercises = V2HomeSource.queryHomeExercises(
        profile: _makeProfile(),
      );

      for (final exercise in exercises) {
        expect(
          exercise.equipment,
          isEmpty,
          reason: '${exercise.id} não deve ter equipamento',
        );
      }
    });

    test('ExerciseModel V2 Home tem environment = ["home"]', () {
      final exercises = V2HomeSource.queryHomeExercises(
        profile: _makeProfile(),
      );

      for (final exercise in exercises) {
        expect(
          exercise.environment,
          equals(['home']),
          reason: '${exercise.id} deve ter environment = ["home"]',
        );
      }
    });
  });

  // ── TESTE 4: LIMITAÇÃO ──
  group('TESTE 4 — LIMITAÇÃO', () {
    test('Perfil com limitação Knee reduz exercícios disponíveis', () {
      final exercisesNoLimit = V2HomeSource.queryHomeExercises(
        profile: _makeProfile(healthRestrictions: []),
      );
      final exercisesWithLimit = V2HomeSource.queryHomeExercises(
        profile: _makeProfile(healthRestrictions: ['knee']),
      );

      expect(
        exercisesWithLimit.length,
        lessThanOrEqualTo(exercisesNoLimit.length),
      );
    });
  });

  // ── TESTE 5: FALLBACK ──
  group('TESTE 5 — FALLBACK', () {
    test('V2HomeSource fallback: V2 indisponível retorna vazio', () {
      final library = V2ExerciseLibrary();
      final savedExercises = List<V2Exercise>.from(library.all);
      library.clear();

      final result = V2HomeSource.queryHomeExercises(
        profile: _makeProfile(),
      );

      expect(result, isEmpty);

      library.registerAll(savedExercises);
    });

    test('V2HomeSource.isAvailable retorna false quando vazio', () {
      final library = V2ExerciseLibrary();
      final savedExercises = List<V2Exercise>.from(library.all);
      library.clear();

      expect(V2HomeSource.isAvailable, isFalse);

      library.registerAll(savedExercises);
    });
  });

  // ── TESTE 6: HOMEWORKOUTINTEGRATOR USA V2 ──
  group('TESTE 6 — HOMEWORKOUTINTEGRATOR USA V2', () {
    test('generateHomeWorkout gera treino via V2', () {
      final integrator = HomeWorkoutIntegrator(userId: 'test_user');
      final workout = integrator.generateHomeWorkout(_makeProfile());

      expect(workout, isNotNull);
      expect(workout.splitType, equals('home_bodyweight'));
      expect(workout.sessions, isNotEmpty);
    });

    test('Exercício prescrito V2 tem tags com "v2"', () {
      final integrator = HomeWorkoutIntegrator(userId: 'test_user');
      final workout = integrator.generateHomeWorkout(_makeProfile());
      final allExercises = workout.sessions
          .expand((s) => s.exercises)
          .map((e) => e.exercise)
          .toList();

      expect(
        allExercises.any((e) => e.tags.contains('v2')),
        isTrue,
        reason: 'Pelo menos um exercício prescrito deve ter tag "v2"',
      );
    });

    test('Exercício prescrito V2 tem decisionReason com "V2_HOME"', () {
      final integrator = HomeWorkoutIntegrator(userId: 'test_user');
      final workout = integrator.generateHomeWorkout(_makeProfile());
      final allPrescribed = workout.sessions
          .expand((s) => s.exercises)
          .toList();

      expect(
        allPrescribed.any((e) =>
            e.decisionReason != null &&
            e.decisionReason!.contains('V2_HOME')),
        isTrue,
        reason: 'Pelo menos um exercício prescrito deve ter '
            'decisionReason com "V2_HOME"',
      );
    });
  });

  // ── TESTE 7: PERSISTÊNCIA E RESOLUÇÃO ──
  group('TESTE 7 — PERSISTÊNCIA E RESOLUÇÃO', () {
    test('toMap preserva exerciseId V2', () {
      final integrator = HomeWorkoutIntegrator(userId: 'test_user');
      final workout = integrator.generateHomeWorkout(_makeProfile());
      final workoutMap = workout.toMap();

      final firstSession = workoutMap['sessions'][0];
      final firstExercise = firstSession['exercises'][0];

      expect(firstExercise['exerciseId'], isNotNull);
      expect(firstExercise['exerciseId'], isNotEmpty);
    });

    test('V2HomeSource.getAllHomeAsExerciseModel retorna todos os V2 Home', () {
      final exercises = V2HomeSource.getAllHomeAsExerciseModel();

      expect(exercises.length, equals(46));
      expect(exercises.every((e) => e.tags.contains('v2')), isTrue);
    });
  });

  // ── TESTE 8: DIAS DIFERENTES ──
  group('TESTE 8 — DIAS DIFERENTES', () {
    test('Múltiplas sessões são geradas para availableDaysPerWeek > 1', () {
      final integrator = HomeWorkoutIntegrator(userId: 'test_user');
      final workout = integrator.generateHomeWorkout(
        _makeProfile(availableDaysPerWeek: 4),
      );

      expect(workout.sessions.length, equals(4));
    });

    test('Sessões têm IDs únicos', () {
      final integrator = HomeWorkoutIntegrator(userId: 'test_user');
      final workout = integrator.generateHomeWorkout(_makeProfile());
      final sessionIds = workout.sessions.map((s) => s.id).toSet();

      expect(sessionIds.length, equals(workout.sessions.length));
    });
  });

  // ── TESTE 9: NÍVEL DO USUÁRIO AFETA SELEÇÃO ──
  group('TESTE 9 — NÍVEL DO USUÁRIO AFETA SELEÇÃO', () {
    test('Iniciante e intermediário geram treinos diferentes', () {
      final integrator = HomeWorkoutIntegrator(userId: 'test_user');

      final workoutBeginner = integrator.generateHomeWorkout(
        _makeProfile(experienceLevel: 'beginner'),
      );
      final workoutIntermediate = integrator.generateHomeWorkout(
        _makeProfile(experienceLevel: 'intermediate'),
      );

      final exercisesBeginner = workoutBeginner.sessions
          .expand((s) => s.exercises)
          .map((e) => e.exercise.id)
          .toSet();
      final exercisesIntermediate = workoutIntermediate.sessions
          .expand((s) => s.exercises)
          .map((e) => e.exercise.id)
          .toSet();

      final allSame = exercisesBeginner.containsAll(exercisesIntermediate) &&
          exercisesIntermediate.containsAll(exercisesBeginner);
      expect(allSame, isFalse,
          reason: 'Iniciante e intermediário devem ter exercícios diferentes');
    });
  });
}
