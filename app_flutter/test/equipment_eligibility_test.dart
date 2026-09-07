import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/data/exercise_library.dart';
import 'package:app/features/exercises/exercise_model.dart';
import 'package:app/features/workout/exercise_compatibility.dart';
import 'package:app/features/workout/home_workout/home_workout.dart';
import 'package:app/features/workout/prescribed_workout_model.dart';
import 'package:app/features/workout/prescription_engine.dart';
import 'package:app/features/workout/workout_profile_model.dart';
import 'package:app/features/workout/workout_validator.dart';

WorkoutProfile testProfile({
  required String environment,
  List<String> equipment = const [],
  String experienceLevel = 'beginner',
}) {
  final now = DateTime(2026, 1, 1);
  return WorkoutProfile(
    uid: 'equipment-test-user',
    age: 30,
    biologicalSex: 'male',
    weightKg: 80,
    heightCm: 180,
    experienceLevel: experienceLevel,
    trainingAge: 0,
    bodyFatCategory: 'medium',
    primaryGoal: 'hypertrophy',
    availableDaysPerWeek: 3,
    sessionDurationMinutes: 45,
    preferredStyle: 'compound_focus',
    sleepQuality: 'good',
    stressLevel: 'low',
    priorityMuscles: const [],
    environment: environment,
    availableEquipment: equipment,
    dislikedExercises: const [],
    favoriteExercises: const [],
    healthRestrictions: const [],
    createdAt: now,
    updatedAt: now,
  );
}

ExerciseModel exercise({
  required String id,
  required List<String> equipment,
  List<String> environment = const ['home', 'gym'],
}) {
  return ExerciseModel(
    id: id,
    name: id,
    primaryMuscles: const ['chest'],
    equipment: equipment,
    environment: environment,
  );
}

void main() {
  test('home sem equipamento aceita somente peso corporal', () {
    final profile = testProfile(environment: 'home');
    final eligible = exerciseLibrary
        .where(
          (exercise) => ExerciseCompatibility.isCompatible(profile, exercise),
        )
        .toList();

    expect(eligible, isNotEmpty);
    expect(
      eligible.every(
        (exercise) =>
            ExerciseCompatibility.requiredEquipment(exercise.equipment).isEmpty,
      ),
      isTrue,
    );
    expect(
      eligible.any((exercise) => exercise.equipment.contains('bodyweight')),
      isTrue,
    );
    expect(
      eligible.where((exercise) => exercise.equipment.contains('trx')).length,
      0,
    );
    for (final unavailable in const [
      'machine',
      'cable',
      'smith',
      'barbell',
      'dumbbell',
      'kettlebell',
      'bench',
      'band',
    ]) {
      expect(
        eligible.any(
          (exercise) => ExerciseCompatibility.requiredEquipment(
            exercise.equipment,
          ).contains(unavailable),
        ),
        isFalse,
        reason: unavailable,
      );
    }
  });

  test(
    'home com halteres permite peso corporal e halteres, mas nao infere outros',
    () {
      final profile = testProfile(
        environment: 'home',
        equipment: const ['dumbbell'],
      );

      expect(
        ExerciseCompatibility.isCompatible(
          profile,
          exercise(id: 'pushup', equipment: const ['bodyweight']),
        ),
        isTrue,
      );
      expect(
        ExerciseCompatibility.isCompatible(
          profile,
          exercise(id: 'db_press', equipment: const ['dumbbell']),
        ),
        isTrue,
      );
      for (final unavailable in const [
        'trx',
        'machine',
        'cable',
        'smith',
        'barbell',
      ]) {
        expect(
          ExerciseCompatibility.isCompatible(
            profile,
            exercise(id: unavailable, equipment: [unavailable]),
          ),
          isFalse,
          reason: unavailable,
        );
      }
    },
  );

  test('home com TRX nao libera equipamentos nao informados', () {
    final profile = testProfile(environment: 'home', equipment: const ['trx']);

    expect(
      ExerciseCompatibility.isCompatible(
        profile,
        exercise(id: 'trx_row', equipment: const ['trx']),
      ),
      isTrue,
    );
    for (final unavailable in const [
      'machine',
      'cable',
      'smith',
      'barbell',
      'dumbbell',
    ]) {
      expect(
        ExerciseCompatibility.isCompatible(
          profile,
          exercise(id: unavailable, equipment: [unavailable]),
        ),
        isFalse,
        reason: unavailable,
      );
    }
  });

  test('metadata de equipamento ausente nao vira peso corporal', () {
    final profile = testProfile(environment: 'home');
    final externalExercise = ExerciseModel.fromMap({
      'id': 'external_trx_row',
      'name': 'External TRX Row',
      'primaryMuscles': ['back'],
      'environment': ['home'],
      'equipment': [],
    });

    final result = ExerciseCompatibility.evaluate(
      profile: profile,
      exercise: externalExercise,
    );

    expect(result.allowed, isFalse);
    expect(result.code, 'equipment_metadata_unverified');
  });

  test('home engine rejeita metadata externo nao auditado na origem', () {
    final externalExercise = HomeExercise(
      id: 'external_exercise',
      name: 'External Exercise',
      pattern: HomeMovementPattern.squat,
      difficulty: HomeDifficulty.level1,
      primaryMuscles: const ['quads'],
      demandRegions: const [],
      primaryFunction: 'test',
      equipmentMetadataVerified: false,
    );
    final engine = HomeWorkoutEngine(library: [externalExercise]);

    expect(
      engine.getExercisesByPattern(HomeMovementPattern.squat),
      isEmpty,
    );
  });

  test('home engine exige requisito condicional declarado', () {
    final conditionalExercise = HomeExercise(
      id: 'conditional_pull',
      name: 'Conditional Pull',
      pattern: HomeMovementPattern.squat,
      difficulty: HomeDifficulty.level1,
      primaryMuscles: const ['back'],
      demandRegions: const [],
      primaryFunction: 'test',
      isConditional: true,
      conditionalRequirement: 'trx',
    );
    final engine = HomeWorkoutEngine(library: [conditionalExercise]);

    expect(
      engine.getExercisesByPattern(HomeMovementPattern.squat),
      isEmpty,
    );
    expect(
      engine.getExercisesByPattern(
        HomeMovementPattern.squat,
        availableEquipment: const ['trx'],
      ),
      hasLength(1),
    );
  });

  test('requisito composto exige todos os equipamentos', () {
    final profile = testProfile(
      environment: 'home',
      equipment: const ['dumbbell'],
    );
    final composite = exercise(
      id: 'db_bulgarian',
      equipment: const ['dumbbell', 'bench'],
    );

    expect(ExerciseCompatibility.isCompatible(profile, composite), isFalse);
    expect(
      ExerciseCompatibility.isCompatible(
        testProfile(
          environment: 'home',
          equipment: const ['dumbbell', 'bench'],
        ),
        composite,
      ),
      isTrue,
    );
  });

  test('biblioteca preserva requisitos compostos de exercicios no banco', () {
    final profileWithoutBench = testProfile(
      environment: 'home',
      equipment: const ['dumbbell'],
    );
    final profileWithBench = testProfile(
      environment: 'home',
      equipment: const ['dumbbell', 'bench'],
    );
    final exercise = exerciseLibrary.firstWhere(
      (item) => item.id == 'afundo_no_banco_com_halteres',
    );

    expect(
      ExerciseCompatibility.requiredEquipment(exercise.equipment),
      containsAll(const ['dumbbell', 'bench']),
    );
    expect(
      ExerciseCompatibility.isCompatible(profileWithoutBench, exercise),
      isFalse,
    );
    expect(
      ExerciseCompatibility.isCompatible(profileWithBench, exercise),
      isTrue,
    );
  });

  test('academia limitada respeita exatamente os equipamentos disponíveis', () {
    final profile = testProfile(
      environment: 'gym',
      equipment: const ['machine', 'cable', 'barbell', 'dumbbell'],
    );
    final eligible = exerciseLibrary
        .where(
          (exercise) => ExerciseCompatibility.isCompatible(profile, exercise),
        )
        .toList();

    expect(eligible, isNotEmpty);
    expect(
      eligible.every(
        (exercise) => ExerciseCompatibility.requiredEquipment(
          exercise.equipment,
        ).every(profile.availableEquipment.contains),
      ),
      isTrue,
    );
    expect(
      ExerciseCompatibility.isCompatible(
        profile,
        exercise(
          id: 'trx_row',
          equipment: const ['trx'],
          environment: const ['gym'],
        ),
      ),
      isFalse,
    );
  });

  test(
    'academia completa exige a lista explicita de equipamentos suportados',
    () {
      final profile = testProfile(
        environment: 'gym',
        equipment: const [
          'machine',
          'cable',
          'barbell',
          'dumbbell',
          'smith',
          'kettlebell',
          'bench',
          'band',
          'trx',
          'pull_up_bar',
          'dip_station',
          'stability_ball',
        ],
      );

      for (final equipment in const [
        'machine',
        'cable',
        'barbell',
        'dumbbell',
        'smith',
        'kettlebell',
        'bench',
        'band',
        'trx',
      ]) {
        expect(
          ExerciseCompatibility.isCompatible(
            profile,
            exercise(
              id: equipment,
              equipment: [equipment],
              environment: const ['gym'],
            ),
          ),
          isTrue,
          reason: equipment,
        );
      }
    },
  );

  test('validator bloqueia equipamento antes da persistencia', () {
    final profile = testProfile(environment: 'home');
    final workout = GeneratedWorkout(
      id: 'invalid-equipment',
      userId: profile.uid,
      splitType: 'full_body',
      periodizationModel: 'linear',
      sessions: [
        PrescribedSession(
          id: 'session-1',
          name: 'Session',
          objective: 'Test',
          estimatedDurationMinutes: 30,
          warmupInstructions: const [],
          exercises: [
            PrescribedExercise(
              exercise: exercise(id: 'trx_row', equipment: const ['trx']),
              sets: 2,
              repsMin: 8,
              repsMax: 10,
              rir: 3,
              restSeconds: 60,
              sessionCues: const [],
              progressionNote: '',
            ),
          ],
          progressionNote: '',
        ),
      ],
      mesocycleDurationWeeks: 4,
      generatedAt: DateTime(2026, 1, 1),
    );

    final result = WorkoutValidator.validate(
      profile: profile,
      workout: workout,
    );
    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.code),
      contains('equipment_not_available'),
    );
  });

  test('motor de casa para iniciante gera somente movimentos elegiveis', () {
    final workout = HomeWorkoutEngine().generateWorkout(
      userId: 'beginner-home',
      availableMinutes: 45,
      limitations: const [],
      experienceLevel: 'beginner',
      balanceCapability: 0.3,
      strengthCapability: 0.3,
      mobilityCapability: 0.4,
      availableEquipment: const [],
    );

    expect(workout.exercises, isNotEmpty);
    expect(
      workout.exercises.every((item) => item.exercise.equipment.isEmpty),
      isTrue,
    );
  });

  test('motor principal gera treino valido para HOME sem equipamento', () {
    final profile = testProfile(environment: 'home');
    final workout = WorkoutPrescriptionEngine(profile).generate(profile);

    expect(workout.sessions, isNotEmpty);
    expect(
      workout.sessions
          .expand((session) => session.exercises)
          .every(
            (prescribed) => ExerciseCompatibility.requiredEquipment(
              prescribed.exercise.equipment,
            ).isEmpty,
          ),
      isTrue,
    );
    expect(
      WorkoutValidator.validate(profile: profile, workout: workout).isValid,
      isTrue,
    );
  });

  test(
    'pipeline completo para HOME sem equipamento nao contem exercicio com equipamento',
    () {
      final profile = testProfile(environment: 'home');
      final engine = WorkoutPrescriptionEngine(profile);
      final workout = engine.generate(profile);

      final allExercises = workout.sessions
          .expand((session) => session.exercises)
          .toList();

      expect(allExercises, isNotEmpty);

      for (final prescribed in allExercises) {
        final ex = prescribed.exercise;

        expect(
          ExerciseCompatibility.requiredEquipment(ex.equipment),
          isEmpty,
          reason: '${ex.id} requires equipment: ${ex.equipment}',
        );

        expect(
          ex.equipment,
          isNot(contains('trx')),
          reason: '${ex.id} has TRX in equipment',
        );
        expect(
          ex.equipment,
          isNot(contains('machine')),
          reason: '${ex.id} has machine in equipment',
        );
        expect(
          ex.equipment,
          isNot(contains('cable')),
          reason: '${ex.id} has cable in equipment',
        );
        expect(
          ex.equipment,
          isNot(contains('barbell')),
          reason: '${ex.id} has barbell in equipment',
        );
        expect(
          ex.equipment,
          isNot(contains('dumbbell')),
          reason: '${ex.id} has dumbbell in equipment',
        );
        expect(
          ex.equipment,
          isNot(contains('smith')),
          reason: '${ex.id} has smith in equipment',
        );
        expect(
          ex.equipment,
          isNot(contains('kettlebell')),
          reason: '${ex.id} has kettlebell in equipment',
        );
        expect(
          ex.equipment,
          isNot(contains('bench')),
          reason: '${ex.id} has bench in equipment',
        );
        expect(
          ex.equipment,
          isNot(contains('band')),
          reason: '${ex.id} has band in equipment',
        );
      }

      final validation = WorkoutValidator.validate(
        profile: profile,
        workout: workout,
      );
      expect(validation.isValid, isTrue, reason: validation.issues.toString());
    },
  );
}
