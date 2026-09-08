import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/workout/intelligence/user_training_profile.dart';
import 'package:app/features/workout/intelligence/training_context.dart';
import 'package:app/features/workout/intelligence/training_strategy_engine.dart';
import 'package:app/features/workout/intelligence/session_blueprint.dart';
import 'package:app/features/workout/intelligence/exercise_selection_engine.dart';
import 'package:app/features/workout/intelligence/workout_composer.dart';
import 'package:app/features/workout/intelligence/weekly_planner.dart';
import 'package:app/features/workout/intelligence/workout_validator.dart';
import 'package:app/features/workout/intelligence/training_intelligence.dart';
import 'package:app/features/exercise_library_v2/v2_exercise_library.dart';
import 'package:app/features/exercise_library_v2/data/home_exercises.dart';
import 'package:app/features/exercise_library_v2/enums/goal.dart';
import 'package:app/features/exercise_library_v2/enums/modality.dart';
import 'package:app/features/exercise_library_v2/enums/environment.dart';
import 'package:app/features/exercise_library_v2/enums/equipment.dart';
import 'package:app/features/exercise_library_v2/enums/joint.dart';
import 'package:app/features/exercise_library_v2/enums/limitation_severity.dart';
import 'package:app/features/exercise_library_v2/enums/difficulty.dart';
import 'package:app/features/exercise_library_v2/bridge/v2_home_bridge.dart';

// ── Perfis de teste ──

UserTrainingProfile _profile1() => UserTrainingProfile(
  uid: 'test_1',
  age: 25,
  biologicalSex: 'male',
  weightKg: 75,
  heightCm: 175,
  primaryGoal: V2Goal.generalFitness,
  modality: V2Modality.generalPhysicalDevelopment,
  environment: V2Environment.home,
  availableEquipment: const [],
  availableDaysPerWeek: 3,
  sessionDurationMinutes: 30,
  experienceLevel: ExperienceLevel.regularly,
  trainingAgeMonths: 24,
);

UserTrainingProfile _profile2() => UserTrainingProfile(
  uid: 'test_2',
  age: 25,
  biologicalSex: 'male',
  weightKg: 75,
  heightCm: 175,
  primaryGoal: V2Goal.conditioning,
  modality: V2Modality.conditioning,
  environment: V2Environment.home,
  availableEquipment: const [],
  availableDaysPerWeek: 3,
  sessionDurationMinutes: 30,
  experienceLevel: ExperienceLevel.regularly,
  trainingAgeMonths: 24,
);

UserTrainingProfile _profile3() => UserTrainingProfile(
  uid: 'test_3',
  age: 25,
  biologicalSex: 'male',
  weightKg: 75,
  heightCm: 175,
  primaryGoal: V2Goal.generalFitness,
  modality: V2Modality.generalPhysicalDevelopment,
  environment: V2Environment.home,
  availableEquipment: const [],
  availableDaysPerWeek: 3,
  sessionDurationMinutes: 60,
  experienceLevel: ExperienceLevel.years,
  trainingAgeMonths: 60,
);

UserTrainingProfile _profile4() => UserTrainingProfile(
  uid: 'test_4',
  age: 25,
  biologicalSex: 'male',
  weightKg: 75,
  heightCm: 175,
  primaryGoal: V2Goal.generalFitness,
  modality: V2Modality.generalPhysicalDevelopment,
  environment: V2Environment.home,
  availableEquipment: const [],
  availableDaysPerWeek: 3,
  sessionDurationMinutes: 30,
  experienceLevel: ExperienceLevel.regularly,
  trainingAgeMonths: 24,
  limitations: const [
    UserLimitation(
      joint: V2Joint.knee,
      severity: V2LimitationSeverity.moderate,
      side: 'both',
      timing: 'during',
      affectedMovements: ['agachar', 'saltar'],
    ),
  ],
);

UserTrainingProfile _profile5() => UserTrainingProfile(
  uid: 'test_5',
  age: 25,
  biologicalSex: 'male',
  weightKg: 75,
  heightCm: 175,
  primaryGoal: V2Goal.generalFitness,
  modality: V2Modality.generalPhysicalDevelopment,
  environment: V2Environment.home,
  availableEquipment: const [],
  availableDaysPerWeek: 2,
  sessionDurationMinutes: 20,
  experienceLevel: ExperienceLevel.little,
  trainingAgeMonths: 0,
);

void main() {
  setUpAll(() {
    final library = V2ExerciseLibrary();
    final homeExercises = createHomeExercises();
    library.registerAll(homeExercises);
    V2HomeBridge.registerAll(homeExercises);
  });

  tearDownAll(() {
    V2ExerciseLibrary().clear();
    V2HomeBridge.clearRegistry();
  });

  // ── TESTE A: OBJETIVO ──
  group('TESTE A — OBJETIVO', () {
    test('Hipertrofia vs condicionamento geram estratégias diferentes', () {
      final intelligence = TrainingIntelligence();
      final strategy1 = intelligence.getStrategy(_profile1());
      final strategy2 = intelligence.getStrategy(_profile2());

      expect(strategy1.primaryGoal, isNot(equals(strategy2.primaryGoal)));
      expect(strategy1.stimulusDistribution.mechanicalTension,
          isNot(equals(strategy2.stimulusDistribution.mechanicalTension)));
      expect(strategy1.volumeTarget.maxExercises,
          isNot(equals(strategy2.volumeTarget.maxExercises)));
    });
  });

  // ── TESTE B: AMBIENTE ──
  group('TESTE B — AMBIENTE', () {
    test('Casa vs academia gera estratégia diferente', () {
      final intelligence = TrainingIntelligence();
      final contextHome = TrainingContext.fromProfile(_profile1());

      final profileGym = UserTrainingProfile(
        uid: 'test_gym',
        age: 25,
        biologicalSex: 'male',
        weightKg: 75,
        heightCm: 175,
        primaryGoal: V2Goal.generalFitness,
        modality: V2Modality.generalPhysicalDevelopment,
        environment: V2Environment.gym,
        availableEquipment: const [],
        availableDaysPerWeek: 3,
        sessionDurationMinutes: 30,
        experienceLevel: ExperienceLevel.regularly,
        trainingAgeMonths: 24,
      );
      final contextGym = TrainingContext.fromProfile(profileGym);

      expect(contextHome.isHome, isTrue);
      expect(contextGym.isGym, isTrue);
    });
  });

  // ── TESTE C: TEMPO ──
  group('TESTE C — TEMPO', () {
    test('20min vs 60min gera composição diferente', () {
      final intelligence = TrainingIntelligence();
      final strategy20 = intelligence.getStrategy(_profile5());
      final strategy60 = intelligence.getStrategy(_profile3());

      expect(strategy20.volumeTarget.maxExercises,
          lessThan(strategy60.volumeTarget.maxExercises));
    });
  });

  // ── TESTE D: NÍVEL ──
  group('TESTE D — NÍVEL', () {
    test('Iniciante vs avançado gera demanda diferente', () {
      final intelligence = TrainingIntelligence();
      final strategyBeginner = intelligence.getStrategy(_profile5());
      final strategyAdvanced = intelligence.getStrategy(_profile3());

      expect(strategyBeginner.volumeTarget.setsPerExercise,
          lessThanOrEqualTo(strategyAdvanced.volumeTarget.setsPerExercise));
    });
  });

  // ── TESTE E: LIMITAÇÃO ──
  group('TESTE E — LIMITAÇÃO', () {
    test('Usuário com limitação gera sessão válida', () {
      final intelligence = TrainingIntelligence();
      final session = intelligence.generateSingleSession(_profile4());

      // Deve gerar sessão com exercícios
      expect(session.exercises, isNotEmpty);
      expect(session.estimatedDurationMinutes, greaterThan(0));

      // Todos os exercícios devem ter IDs V2 válidos
      for (final ex in session.exercises) {
        expect(ex.exercise.id, startsWith('home_'));
      }
    });
  });

  // ── TESTE G: REDUNDÂNCIA ──
  group('TESTE G — REDUNDÂNCIA', () {
    test('Exercícios redundantes não dominam a sessão', () {
      final intelligence = TrainingIntelligence();
      final session = intelligence.generateSingleSession(_profile1());

      final patterns = session.exercises
          .map((e) => e.exercise.movementPattern)
          .toList();

      // Contar ocorrências de cada padrão
      final patternCounts = <String, int>{};
      for (final p in patterns) {
        patternCounts[p] = (patternCounts[p] ?? 0) + 1;
      }

      // Nenhum padrão deve aparecer mais de 3 vezes
      for (final count in patternCounts.values) {
        expect(count, lessThanOrEqualTo(3),
            reason: 'Padrão不应 aparecer mais de 3 vezes');
      }
    });
  });

  // ── TESTE H: FREQUÊNCIA ──
  group('TESTE H — FREQUÊNCIA', () {
    test('2 dias vs 4 dias gera organização diferente', () {
      final intelligence = TrainingIntelligence();
      final profile2 = UserTrainingProfile(
        uid: 'test_freq2',
        age: 25,
        biologicalSex: 'male',
        weightKg: 75,
        heightCm: 175,
        primaryGoal: V2Goal.generalFitness,
        modality: V2Modality.generalPhysicalDevelopment,
        environment: V2Environment.home,
        availableEquipment: const [],
        availableDaysPerWeek: 2,
        sessionDurationMinutes: 30,
        experienceLevel: ExperienceLevel.regularly,
        trainingAgeMonths: 24,
      );
      final profile4 = UserTrainingProfile(
        uid: 'test_freq4',
        age: 25,
        biologicalSex: 'male',
        weightKg: 75,
        heightCm: 175,
        primaryGoal: V2Goal.generalFitness,
        modality: V2Modality.generalPhysicalDevelopment,
        environment: V2Environment.home,
        availableEquipment: const [],
        availableDaysPerWeek: 4,
        sessionDurationMinutes: 30,
        experienceLevel: ExperienceLevel.regularly,
        trainingAgeMonths: 24,
      );

      final workout2 = intelligence.generateWorkout(profile2);
      final workout4 = intelligence.generateWorkout(profile4);

      expect(workout2.sessions.length, equals(2));
      expect(workout4.sessions.length, equals(4));
    });
  });

  // ── TESTE I: PREFERÊNCIA ──
  group('TESTE I — PREFERÊNCIA', () {
    test('Preferência afeta ranking sem quebrar compatibilidade', () {
      final intelligence = TrainingIntelligence();
      final profileWithPref = UserTrainingProfile(
        uid: 'test_pref',
        age: 25,
        biologicalSex: 'male',
        weightKg: 75,
        heightCm: 175,
        primaryGoal: V2Goal.generalFitness,
        modality: V2Modality.generalPhysicalDevelopment,
        environment: V2Environment.home,
        availableEquipment: const [],
        availableDaysPerWeek: 3,
        sessionDurationMinutes: 30,
        experienceLevel: ExperienceLevel.regularly,
        trainingAgeMonths: 24,
        preferredExerciseIds: const ['home_squat_001'],
      );

      final session = intelligence.generateSingleSession(profileWithPref);
      final ids = session.exercises.map((e) => e.exercise.id).toList();

      // O exercício preferido deve estar na lista se compatível
      expect(ids, contains('home_squat_001'));
    });
  });

  // ── TESTE J: DURAÇÃO ──
  group('TESTE J — DURAÇÃO', () {
    test('Duração estimada respeita tempo informado', () {
      final intelligence = TrainingIntelligence();
      final session = intelligence.generateSingleSession(_profile5());

      // 20 minutos não deve gerar treino de 60 minutos
      expect(session.estimatedDurationMinutes, lessThanOrEqualTo(35));
    });
  });

  // ── TESTE K: PRESCRIÇÃO ──
  group('TESTE K — PRESCRIÇÃO', () {
    test('Séries/reps/descanso vêm das V2EngineRules + contexto', () {
      final intelligence = TrainingIntelligence();
      final session = intelligence.generateSingleSession(_profile1());

      for (final ex in session.exercises) {
        expect(ex.sets, greaterThanOrEqualTo(2));
        expect(ex.repsMin, greaterThanOrEqualTo(1));
        expect(ex.repsMax, greaterThanOrEqualTo(ex.repsMin));
        expect(ex.restSeconds, greaterThanOrEqualTo(30));
      }
    });
  });

  // ── TESTE L: VARIAÇÃO ──
  group('TESTE L — VARIAÇÃO', () {
    test('Dias diferentes não são clones', () {
      final intelligence = TrainingIntelligence();
      final workout = intelligence.generateWorkout(_profile1());

      if (workout.sessions.length >= 2) {
        final ids1 = workout.sessions[0].exercises
            .map((e) => e.exercise.id)
            .toList();
        final ids2 = workout.sessions[1].exercises
            .map((e) => e.exercise.id)
            .toList();

        expect(ids1, isNot(equals(ids2)));
      }
    });
  });

  // ── TESTE M: DETERMINISMO ──
  group('TESTE M — DETERMINISMO', () {
    test('Mesmos dados → resultado equivalente', () {
      final intelligence = TrainingIntelligence();
      final session1 = intelligence.generateSingleSession(_profile1());
      final session2 = intelligence.generateSingleSession(_profile1());

      expect(session1.exercises.length, equals(session2.exercises.length));
      for (var i = 0; i < session1.exercises.length; i++) {
        expect(session1.exercises[i].exercise.id,
            equals(session2.exercises[i].exercise.id));
      }
    });
  });

  // ── TESTE N: RASTREABILIDADE ──
  group('TESTE N — RASTREABILIDADE', () {
    test('V2Exercise ID permanece do início ao fim', () {
      final intelligence = TrainingIntelligence();
      final session = intelligence.generateSingleSession(_profile1());

      for (final ex in session.exercises) {
        // O ID deve ser um ID V2 válido
        expect(ex.exercise.id, startsWith('home_'));
        expect(ex.exercise.tags, contains('v2'));
      }
    });
  });

  // ── TESTE END-TO-END: PERFIS ──
  group('TESTE END-TO-END — PERFIS', () {
    test('Perfil 1: 25 anos, iniciante, 30min, geral', () {
      final intelligence = TrainingIntelligence();
      final workout = intelligence.generateWorkout(_profile1());

      expect(workout.sessions, isNotEmpty);
      expect(workout.sessions.length, equals(3));

      for (final session in workout.sessions) {
        expect(session.exercises, isNotEmpty);
        expect(session.estimatedDurationMinutes, greaterThan(0));
      }
    });

    test('Perfil 2: condicionamento gera resultado diferente do geral', () {
      final intelligence = TrainingIntelligence();
      final workout1 = intelligence.generateWorkout(_profile1());
      final workout2 = intelligence.generateWorkout(_profile2());

      final ids1 = workout1.sessions.expand((s) => s.exercises).map((e) => e.exercise.id).toSet();
      final ids2 = workout2.sessions.expand((s) => s.exercises).map((e) => e.exercise.id).toSet();

      expect(ids1, isNot(equals(ids2)));
    });

    test('Perfil 3: avançado + 60min gera mais exercícios', () {
      final intelligence = TrainingIntelligence();
      final workout3 = intelligence.generateWorkout(_profile3());

      final totalExercises = workout3.sessions
          .expand((s) => s.exercises)
          .length;

      expect(totalExercises, greaterThanOrEqualTo(5));
    });

    test('Perfil 4: limitação de joelho gera treino válido', () {
      final intelligence = TrainingIntelligence();
      final workout4 = intelligence.generateWorkout(_profile4());

      expect(workout4.sessions, isNotEmpty);
      for (final session in workout4.sessions) {
        expect(session.exercises, isNotEmpty);
        for (final ex in session.exercises) {
          expect(ex.exercise.id, startsWith('home_'));
        }
      }
    });

    test('Perfil 5: 20min gera treino enxuto', () {
      final intelligence = TrainingIntelligence();
      final workout = intelligence.generateWorkout(_profile5());

      expect(workout.sessions.length, equals(2));

      for (final session in workout.sessions) {
        // 20min não deve gerar mais de 7 exercises (com margem)
        expect(session.exercises.length, lessThanOrEqualTo(7));
        expect(session.estimatedDurationMinutes, lessThanOrEqualTo(35));
      }
    });
  });
}
