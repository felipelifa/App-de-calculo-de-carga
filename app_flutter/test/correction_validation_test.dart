import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/workout/intelligence/user_training_profile.dart';
import 'package:app/features/workout/intelligence/training_intelligence.dart';
import 'package:app/features/workout/intelligence/training_context.dart';
import 'package:app/features/workout/intelligence/training_strategy_engine.dart';
import 'package:app/features/workout/intelligence/workout_validator.dart';
import 'package:app/features/exercise_library_v2/v2_exercise_library.dart';
import 'package:app/features/exercise_library_v2/data/home_exercises.dart';
import 'package:app/features/exercise_library_v2/data/gym_free_weights_exercises.dart';
import 'package:app/features/exercise_library_v2/bridge/v2_home_bridge.dart';
import 'package:app/features/exercise_library_v2/enums/goal.dart';
import 'package:app/features/exercise_library_v2/enums/modality.dart';
import 'package:app/features/exercise_library_v2/enums/environment.dart';
import 'package:app/features/exercise_library_v2/enums/equipment.dart';

void main() {
  setUpAll(() {
    final library = V2ExerciseLibrary();
    library.registerAll(createHomeExercises());
    library.registerAll(createGymFreeWeightExercises());
    V2HomeBridge.registerAll(createHomeExercises());
    V2HomeBridge.registerAll(createGymFreeWeightExercises());
  });

  // ═══════════════════════════════════════════════════════════════
  // WORKOUT VALIDATOR — EQUIPAMENTO
  // ═══════════════════════════════════════════════════════════════

  group('WorkoutValidator - equipamento', () {
    test('exercício com equipamento disponível → válido', () {
      final intelligence = TrainingIntelligence();
      final profile = UserTrainingProfile(
        uid: 'val_equip', age: 25, primaryGoal: V2Goal.hypertrophy,
        modality: V2Modality.hypertrophy,
        environment: V2Environment.gym,
        availableEquipment: const [V2Equipment.dumbbell, V2Equipment.barbell, V2Equipment.bench],
        availableDaysPerWeek: 3, sessionDurationMinutes: 45,
        experienceLevel: ExperienceLevel.regularly, trainingAgeMonths: 24,
      );

      final workout = intelligence.generateWorkout(profile);
      final strategy = intelligence.getStrategy(profile);
      final context = TrainingContext.fromProfile(profile);
      final validator = WorkoutValidator();

      for (final session in workout.sessions) {
        final result = validator.validate(session: session, context: context, strategy: strategy);
        final equipErrors = result.issues.where((i) => i.code == 'equipment_mismatch');
        expect(equipErrors, isEmpty,
            reason: 'Sessão ${session.name} não deve ter erro de equipamento');
      }
    });

    test('somente halteres → barra não pode passar', () {
      final intelligence = TrainingIntelligence();
      final profile = UserTrainingProfile(
        uid: 'val_db_only', age: 25, primaryGoal: V2Goal.hypertrophy,
        modality: V2Modality.hypertrophy,
        environment: V2Environment.gym,
        availableEquipment: const [V2Equipment.dumbbell, V2Equipment.bench],
        availableDaysPerWeek: 3, sessionDurationMinutes: 45,
        experienceLevel: ExperienceLevel.regularly, trainingAgeMonths: 24,
      );

      final workout = intelligence.generateWorkout(profile);

      // Nenhum exercício deve usar barra
      for (final s in workout.sessions) {
        for (final ex in s.exercises) {
          final v2 = V2HomeBridge.getV2Exercise(ex.exercise.id);
          if (v2 != null) {
            expect(v2.requiredEquipment.contains(V2Equipment.barbell), isFalse,
                reason: '${ex.exercise.name} usa barra mas perfil só tem halteres');
          }
        }
      }
    });

    test('somente barra → halteres não podem passar', () {
      final intelligence = TrainingIntelligence();
      final profile = UserTrainingProfile(
        uid: 'val_bb_only', age: 25, primaryGoal: V2Goal.hypertrophy,
        modality: V2Modality.hypertrophy,
        environment: V2Environment.gym,
        availableEquipment: const [V2Equipment.barbell, V2Equipment.bench],
        availableDaysPerWeek: 3, sessionDurationMinutes: 45,
        experienceLevel: ExperienceLevel.regularly, trainingAgeMonths: 24,
      );

      final workout = intelligence.generateWorkout(profile);

      for (final s in workout.sessions) {
        for (final ex in s.exercises) {
          final v2 = V2HomeBridge.getV2Exercise(ex.exercise.id);
          if (v2 != null) {
            expect(v2.requiredEquipment.contains(V2Equipment.dumbbell), isFalse,
                reason: '${ex.exercise.name} usa halteres mas perfil só tem barra');
          }
        }
      }
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // RIR CONTEXTUAL
  // ═══════════════════════════════════════════════════════════════

  group('RIR contextual', () {
    test('iniciante + força ≠ automaticamente RIR 1', () {
      final intelligence = TrainingIntelligence();
      final profile = UserTrainingProfile(
        uid: 'rir_beg_str', age: 25, primaryGoal: V2Goal.strength,
        modality: V2Modality.strength,
        environment: V2Environment.gym,
        availableEquipment: const [V2Equipment.dumbbell, V2Equipment.barbell, V2Equipment.bench],
        availableDaysPerWeek: 3, sessionDurationMinutes: 60,
        experienceLevel: ExperienceLevel.never, trainingAgeMonths: 0,
      );

      final workout = intelligence.generateWorkout(profile);

      // RIR médio deve ser >= 2.0 para iniciante
      final avgRir = workout.sessions
          .expand((s) => s.exercises)
          .map((e) => e.rir)
          .reduce((a, b) => a + b) /
          workout.sessions.expand((s) => s.exercises).length;

      expect(avgRir, greaterThanOrEqualTo(2.0),
          reason: 'Iniciante + força deve ter RIR >= 2.0, não 1.0');
    });

    test('avançado + força pode trabalhar com maior proximidade da falha', () {
      final intelligence = TrainingIntelligence();
      final profile = UserTrainingProfile(
        uid: 'rir_adv_str', age: 25, primaryGoal: V2Goal.strength,
        modality: V2Modality.strength,
        environment: V2Environment.gym,
        availableEquipment: const [V2Equipment.dumbbell, V2Equipment.barbell, V2Equipment.bench],
        availableDaysPerWeek: 3, sessionDurationMinutes: 60,
        experienceLevel: ExperienceLevel.years, trainingAgeMonths: 60,
      );

      final workout = intelligence.generateWorkout(profile);

      final avgRir = workout.sessions
          .expand((s) => s.exercises)
          .map((e) => e.rir)
          .reduce((a, b) => a + b) /
          workout.sessions.expand((s) => s.exercises).length;

      // Avançado deve ter RIR menor que iniciante
      expect(avgRir, lessThan(2.5),
          reason: 'Avançado + força deve ter RIR < 2.5');
    });

    test('idade pode aumentar a margem de RIR', () {
      final intelligence = TrainingIntelligence();

      final young = UserTrainingProfile(
        uid: 'young', age: 25, primaryGoal: V2Goal.hypertrophy,
        modality: V2Modality.hypertrophy,
        environment: V2Environment.gym,
        availableEquipment: const [V2Equipment.dumbbell, V2Equipment.barbell, V2Equipment.bench],
        availableDaysPerWeek: 3, sessionDurationMinutes: 45,
        experienceLevel: ExperienceLevel.regularly, trainingAgeMonths: 24,
      );

      final old = UserTrainingProfile(
        uid: 'old', age: 55, primaryGoal: V2Goal.hypertrophy,
        modality: V2Modality.hypertrophy,
        environment: V2Environment.gym,
        availableEquipment: const [V2Equipment.dumbbell, V2Equipment.barbell, V2Equipment.bench],
        availableDaysPerWeek: 3, sessionDurationMinutes: 45,
        experienceLevel: ExperienceLevel.regularly, trainingAgeMonths: 24,
      );

      final youngWorkout = intelligence.generateWorkout(young);
      final oldWorkout = intelligence.generateWorkout(old);

      final youngRir = youngWorkout.sessions
          .expand((s) => s.exercises)
          .map((e) => e.rir)
          .reduce((a, b) => a + b) /
          youngWorkout.sessions.expand((s) => s.exercises).length;

      final oldRir = oldWorkout.sessions
          .expand((s) => s.exercises)
          .map((e) => e.rir)
          .reduce((a, b) => a + b) /
          oldWorkout.sessions.expand((s) => s.exercises).length;

      expect(oldRir, greaterThanOrEqualTo(youngRir),
          reason: 'Idoso deve ter RIR >= jovem (mais conservador)');
    });

    test('hipertrofia e força continuam diferenciadas', () {
      final intelligence = TrainingIntelligence();

      final hyper = UserTrainingProfile(
        uid: 'hyper', age: 25, primaryGoal: V2Goal.hypertrophy,
        modality: V2Modality.hypertrophy,
        environment: V2Environment.gym,
        availableEquipment: const [V2Equipment.dumbbell, V2Equipment.barbell, V2Equipment.bench],
        availableDaysPerWeek: 3, sessionDurationMinutes: 45,
        experienceLevel: ExperienceLevel.regularly, trainingAgeMonths: 24,
      );

      final strength = UserTrainingProfile(
        uid: 'strength', age: 25, primaryGoal: V2Goal.strength,
        modality: V2Modality.strength,
        environment: V2Environment.gym,
        availableEquipment: const [V2Equipment.dumbbell, V2Equipment.barbell, V2Equipment.bench],
        availableDaysPerWeek: 3, sessionDurationMinutes: 45,
        experienceLevel: ExperienceLevel.regularly, trainingAgeMonths: 24,
      );

      final hyperWorkout = intelligence.generateWorkout(hyper);
      final strengthWorkout = intelligence.generateWorkout(strength);

      final hyperRir = hyperWorkout.sessions
          .expand((s) => s.exercises)
          .map((e) => e.rir)
          .reduce((a, b) => a + b) /
          hyperWorkout.sessions.expand((s) => s.exercises).length;

      final strengthRir = strengthWorkout.sessions
          .expand((s) => s.exercises)
          .map((e) => e.rir)
          .reduce((a, b) => a + b) /
          strengthWorkout.sessions.expand((s) => s.exercises).length;

      // Força deve ter RIR menor (mais intenso)
      expect(strengthRir, lessThan(hyperRir),
          reason: 'Força deve ter RIR menor que hipertrofia');
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // VOLUME POR DURAÇÃO
  // ═══════════════════════════════════════════════════════════════

  group('Volume por duração', () {
    test('60min produz mais exercícios que 30min', () {
      final intelligence = TrainingIntelligence();

      UserTrainingProfile makeProfile(int minutes) {
        return UserTrainingProfile(
          uid: 'vol_$minutes', age: 25, primaryGoal: V2Goal.hypertrophy,
          modality: V2Modality.hypertrophy,
          environment: V2Environment.gym,
          availableEquipment: const [V2Equipment.dumbbell, V2Equipment.barbell, V2Equipment.bench],
          availableDaysPerWeek: 3, sessionDurationMinutes: minutes,
          experienceLevel: ExperienceLevel.regularly, trainingAgeMonths: 24,
        );
      }

      final w30 = intelligence.generateWorkout(makeProfile(30));
      final w60 = intelligence.generateWorkout(makeProfile(60));

      final ex30 = w30.sessions.expand((s) => s.exercises).length ~/ w30.sessions.length;
      final ex60 = w60.sessions.expand((s) => s.exercises).length ~/ w60.sessions.length;

      expect(ex60, greaterThanOrEqualTo(ex30 + 1),
          reason: '60min deve ter mais exercícios que 30min');
    });

    test('iniciante +60min não tem apenas 3 exercícios', () {
      final intelligence = TrainingIntelligence();
      final profile = UserTrainingProfile(
        uid: 'beg_60', age: 25, primaryGoal: V2Goal.strength,
        modality: V2Modality.strength,
        environment: V2Environment.gym,
        availableEquipment: const [V2Equipment.dumbbell, V2Equipment.barbell, V2Equipment.bench],
        availableDaysPerWeek: 3, sessionDurationMinutes: 60,
        experienceLevel: ExperienceLevel.never, trainingAgeMonths: 0,
      );

      final workout = intelligence.generateWorkout(profile);

      for (final s in workout.sessions) {
        expect(s.exercises.length, greaterThanOrEqualTo(4),
            reason: 'Sessão de 60min deve ter pelo menos 4 exercícios');
      }
    });
  });
}
