import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/exercises/exercise_model.dart';
import 'package:app/features/workout/exercise_compatibility.dart';
import 'package:app/features/workout/prescribed_workout_model.dart';
import 'package:app/features/workout/prescription_engine.dart';
import 'package:app/features/workout/workout_profile_model.dart';
import 'package:app/features/workout/workout_validator.dart';

WorkoutProfile profile({
  String environment = 'full_gym',
  List<String> equipment = const [],
  int days = 3,
}) {
  final now = DateTime(2026, 1, 1);
  return WorkoutProfile(
    uid: 'v2-test-user',
    age: 30,
    biologicalSex: 'male',
    weightKg: 80,
    heightCm: 180,
    experienceLevel: 'beginner',
    trainingAge: 0,
    bodyFatCategory: 'medium',
    primaryGoal: 'hypertrophy',
    availableDaysPerWeek: days,
    sessionDurationMinutes: 60,
    preferredStyle: 'compound_focus',
    sleepQuality: 'good',
    stressLevel: 'low',
    priorityMuscles: const ['chest'],
    environment: environment,
    availableEquipment: equipment,
    dislikedExercises: const [],
    favoriteExercises: const [],
    healthRestrictions: const [],
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  test('casa sem equipamento rejeita TRX e academia', () {
    final user = profile(environment: 'home_bodyweight');
    const trx = ExerciseModel(
      id: 'trx_row',
      name: 'TRX Row',
      primaryMuscles: ['back'],
      equipment: ['trx'],
      environment: ['home', 'gym'],
    );
    const machine = ExerciseModel(
      id: 'machine_press',
      name: 'Machine Press',
      primaryMuscles: ['chest'],
      equipment: ['machine'],
      environment: ['gym'],
    );

    expect(
      ExerciseCompatibility.evaluate(profile: user, exercise: trx).allowed,
      isFalse,
    );
    expect(
      ExerciseCompatibility.evaluate(profile: user, exercise: machine).allowed,
      isFalse,
    );
  });

  test('casa com halteres aceita halteres e rejeita Smith/TRX', () {
    final user = profile(
      environment: 'home_dumbbell',
      equipment: const ['dumbbell'],
    );
    const dumbbell = ExerciseModel(
      id: 'db_press',
      name: 'DB Press',
      primaryMuscles: ['chest'],
      equipment: ['dumbbell'],
      environment: ['home', 'gym'],
    );
    const smith = ExerciseModel(
      id: 'smith_press',
      name: 'Smith Press',
      primaryMuscles: ['chest'],
      equipment: ['smith'],
      environment: ['gym'],
    );

    expect(ExerciseCompatibility.isCompatible(user, dumbbell), isTrue);
    expect(ExerciseCompatibility.isCompatible(user, smith), isFalse);
  });

  test('academia limitada gera somente exercícios compatíveis', () {
    final user = profile(
      environment: 'basic_gym',
      equipment: const ['dumbbell', 'band'],
    );
    final workout = WorkoutPrescriptionEngine(user).generate(user);

    for (final session in workout.sessions) {
      for (final prescribed in session.exercises) {
        expect(
          ExerciseCompatibility.isCompatible(user, prescribed.exercise),
          isTrue,
          reason: prescribed.exercise.id,
        );
        expect(
          prescribed.exercise.equipment.every(
            (equipment) =>
                equipment == 'bodyweight' ||
                equipment == 'none' ||
                equipment == 'dumbbell' ||
                equipment == 'band',
          ),
          isTrue,
          reason: prescribed.exercise.id,
        );
      }
    }
  });

  test('geração padrão não repete o mesmo exercício na sessão', () {
    final user = profile();
    final workout = WorkoutPrescriptionEngine(user).generate(user);

    for (final session in workout.sessions) {
      final ids = session.exercises.map((e) => e.exercise.id).toList();
      expect(ids.toSet().length, ids.length, reason: session.name);
    }
  });

  test('validator rejeita exercício incompatível e treino vazio', () {
    final user = profile(environment: 'home_bodyweight');
    final workout = GeneratedWorkout(
      id: 'invalid',
      userId: user.uid,
      splitType: 'full_body',
      periodizationModel: 'linear',
      sessions: const [],
      mesocycleDurationWeeks: 8,
      generatedAt: DateTime(2026, 1, 1),
    );

    final result = WorkoutValidator.validate(profile: user, workout: workout);
    expect(result.isValid, isFalse);
    expect(result.issues.map((issue) => issue.code), contains('no_exercises'));
  });
}
