import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/workout/prescribed_workout_model.dart';
import 'package:app/features/workout/workout_profile_model.dart';

void main() {
  final now = DateTime(2026, 1, 1);

  test('perfil usa o contrato plano do Supabase', () {
    final profile = WorkoutProfile(
      uid: 'auth-user',
      age: 30,
      biologicalSex: 'male',
      weightKg: 80,
      heightCm: 180,
      experienceLevel: 'beginner',
      trainingAge: 0,
      bodyFatCategory: 'medium',
      primaryGoal: 'hypertrophy',
      availableDaysPerWeek: 3,
      sessionDurationMinutes: 45,
      preferredStyle: 'compound_focus',
      sleepQuality: 'regular',
      stressLevel: 'medium',
      priorityMuscles: const ['chest'],
      environment: 'full_gym',
      availableEquipment: const ['full_gym'],
      dislikedExercises: const [],
      favoriteExercises: const [],
      healthRestrictions: const [],
      createdAt: now,
      updatedAt: now,
    );

    final data = profile.toMap();

    expect(data['uid'], isNull);
    expect(data['adaptive'], isNull);
    expect(data['volumeTolerance'], isNotNull);
    expect(data['recoveryCapacity'], isNotNull);
  });

  test('treino persistido usa createdAt e não envia campos inexistentes', () {
    final workout = GeneratedWorkout(
      id: 'gen_test',
      userId: 'auth-user',
      splitType: 'full_body',
      periodizationModel: 'linear',
      sessions: const [],
      mesocycleDurationWeeks: 8,
      generatedAt: now,
      planExplanation: 'explicação local',
    );

    final data = workout.toMap();

    expect(data['createdAt'], now.toIso8601String());
    expect(data['generatedAt'], isNull);
    expect(data['planExplanation'], isNull);
    expect(data['id'], isNull);
    expect(data['userId'], isNull);
  });
}
