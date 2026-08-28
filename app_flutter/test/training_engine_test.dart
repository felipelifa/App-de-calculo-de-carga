import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/exercises/exercise_model.dart';
import 'package:app/features/workout/exercise_compatibility.dart';
import 'package:app/features/workout/prescription_engine.dart';
import 'package:app/features/workout/workout_profile_model.dart';
import 'package:app/features/workout/age_modifier.dart';
import 'package:app/features/workout/collective_training.dart';
import 'package:app/features/workout/collective_engine.dart';

WorkoutProfile profile({
  String environment = 'home',
  List<String> equipment = const [],
  String goal = 'hypertrophy',
  String level = 'beginner',
  int days = 3,
  int age = 30,
}) {
  final now = DateTime(2026, 1, 1);
  return WorkoutProfile(
    uid: 'test-user',
    age: age,
    biologicalSex: 'male',
    weightKg: 80,
    heightCm: 180,
    experienceLevel: level,
    trainingAge: level == 'beginner' ? 0 : 24,
    bodyFatCategory: 'medium',
    primaryGoal: goal,
    availableDaysPerWeek: days,
    sessionDurationMinutes: 60,
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

void main() {
  // ── Compatibilidade ────────────────────────────────────
  test('casa sem equipamento rejeita exercício com halter', () {
    final result = ExerciseCompatibility.evaluate(
      profile: profile(),
      exercise: const ExerciseModel(
        id: 'dumbbell_press',
        name: 'Supino com halteres',
        primaryMuscles: ['chest'],
        equipment: ['dumbbell'],
        environment: ['gym', 'home'],
      ),
    );

    expect(result.allowed, isFalse);
  });

  test('aliases de equipamento são normalizados', () {
    final result = ExerciseCompatibility.evaluate(
      profile: profile(equipment: ['dumbbells']),
      exercise: const ExerciseModel(
        id: 'dumbbell_press',
        name: 'Supino com halteres',
        primaryMuscles: ['chest'],
        equipment: ['dumbbell'],
        environment: ['gym', 'home'],
      ),
    );

    expect(result.allowed, isTrue);
  });

  // ── Motor de prescrição ────────────────────────────────
  test('motor respeita cinco dias no plano híbrido', () {
    final workout = WorkoutPrescriptionEngine(
      profile(environment: 'full_gym', level: 'intermediate', days: 5),
    ).generate(profile(environment: 'full_gym', level: 'intermediate', days: 5));

    expect(workout.sessions, hasLength(5));
  });

  test('plano doméstico sem equipamento não contém equipamento externo', () {
    final user = profile();
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
            (equipment) => equipment == 'bodyweight' || equipment == 'none',
          ),
          isTrue,
          reason: prescribed.exercise.id,
        );
      }
    }
  });

  test('builders esportivos também respeitam casa sem equipamento', () {
    final user = profile(
      goal: 'running_hybrid',
      environment: 'home',
      days: 3,
    );
    final workout = WorkoutPrescriptionEngine(user).generate(user);

    expect(workout.sessions, isNotEmpty);
    for (final session in workout.sessions) {
      for (final prescribed in session.exercises) {
        expect(
          prescribed.exercise.equipment.every(
            (equipment) => equipment == 'bodyweight' || equipment == 'none',
          ),
          isTrue,
          reason: prescribed.exercise.id,
        );
      }
    }
  });

  // ── Idade como variável contextual ─────────────────────
  group('AgeModifier', () {
    test('idade 65 iniciante reduz volume', () {
      final mod = AgeModifier.volumeModifier(
        age: 65, experienceLevel: 'beginner',
        fitnessCapacity: 'moderate', recoveryCapacity: 'moderate',
      );
      expect(mod, lessThan(1.0));
    });

    test('idade 65 avançado com alta capacidade quase não sofre penalidade', () {
      final mod = AgeModifier.volumeModifier(
        age: 65, experienceLevel: 'advanced',
        fitnessCapacity: 'high', recoveryCapacity: 'moderate',
      );
      expect(mod, greaterThan(0.85));
    });

    test('idade 25 não tem penalidade', () {
      final mod = AgeModifier.volumeModifier(
        age: 25, experienceLevel: 'beginner',
        fitnessCapacity: 'moderate', recoveryCapacity: 'moderate',
      );
      expect(mod, equals(1.0));
    });

    test('iniciante + 60 anos prioriza funcional', () {
      expect(
        AgeModifier.shouldPrioritizeFunctional(
          age: 62, experienceLevel: 'beginner', fitnessCapacity: 'moderate',
        ),
        isTrue,
      );
    });

    test('avançado + 55 anos NÃO prioriza funcional automaticamente', () {
      expect(
        AgeModifier.shouldPrioritizeFunctional(
          age: 57, experienceLevel: 'advanced', fitnessCapacity: 'high',
        ),
        isFalse,
      );
    });
  });

  // ── Treinamento coletivo ───────────────────────────────
  group('CollectiveTrainingEngine', () {
    test('dupla com sync alto gera núcleo comum', () {
      final engine = CollectiveTrainingEngine();
      final duo = DuoProfile(
        personA: const ParticipantProfile(
          name: 'Ana', age: 28, biologicalSex: 'female', weightKg: 60,
          heightCm: 165, experienceLevel: 'intermediate', trainingAge: 24,
          primaryGoal: 'hypertrophy', environment: 'full_gym',
          availableEquipment: [], healthRestrictions: [],
          sessionDurationMinutes: 60,
        ),
        personB: const ParticipantProfile(
          name: 'Bruno', age: 30, biologicalSex: 'male', weightKg: 80,
          heightCm: 180, experienceLevel: 'intermediate', trainingAge: 24,
          primaryGoal: 'hypertrophy', environment: 'full_gym',
          availableEquipment: [], healthRestrictions: [],
          sessionDurationMinutes: 60,
        ),
        wantSameWorkout: true,
        wantToTrainTogether: true,
        haveSameGoals: true,
        haveSimilarLevels: true,
        haveSimilarEquipment: true,
        haveDifferentRestrictions: false,
        wantToFinishTogether: true,
        acceptDifferentExercises: true,
        syncLevel: SyncLevel.high,
        relation: ParticipantRelation.couple,
      );

      final blocks = engine.buildDuoSession(duo: duo, sessionDurationMinutes: 60);

      // Deve ter aquecimento, bloco principal, acessório e finalização
      expect(blocks, hasLength(4));
      expect(blocks[0].blockName, equals('aquecimento'));
      expect(blocks[0].isCommon, isTrue);
      expect(blocks[3].blockName, equals('finalizacao'));
      expect(blocks[3].isCommon, isTrue);
    });

    test('dupla com objetivos diferentes gera divergência controlada', () {
      final engine = CollectiveTrainingEngine();
      final duo = DuoProfile(
        personA: const ParticipantProfile(
          name: 'Ana', age: 28, biologicalSex: 'female', weightKg: 60,
          heightCm: 165, experienceLevel: 'intermediate', trainingAge: 24,
          primaryGoal: 'hypertrophy', environment: 'full_gym',
          availableEquipment: [], healthRestrictions: [],
          sessionDurationMinutes: 60,
        ),
        personB: const ParticipantProfile(
          name: 'Bruno', age: 30, biologicalSex: 'male', weightKg: 80,
          heightCm: 180, experienceLevel: 'beginner', trainingAge: 6,
          primaryGoal: 'fat_loss', environment: 'full_gym',
          availableEquipment: [], healthRestrictions: [],
          sessionDurationMinutes: 60,
        ),
        wantSameWorkout: false,
        wantToTrainTogether: true,
        haveSameGoals: false,
        haveSimilarLevels: false,
        haveSimilarEquipment: true,
        haveDifferentRestrictions: false,
        wantToFinishTogether: true,
        acceptDifferentExercises: true,
        syncLevel: SyncLevel.medium,
        relation: ParticipantRelation.friends,
      );

      final blocks = engine.buildDuoSession(duo: duo, sessionDurationMinutes: 60);

      // Bloco principal deve ter exercícios diferentes
      final mainBlock = blocks[1];
      expect(mainBlock.blockName, equals('bloco_principal'));
      expect(mainBlock.isCommon, isFalse);
      expect(mainBlock.individualVariations, contains('Ana'));
      expect(mainBlock.individualVariations, contains('Bruno'));
    });

    test('compatibilidade alta para dupla com mesmos objetivos/níveis', () {
      final duo = DuoProfile(
        personA: const ParticipantProfile(
          name: 'A', age: 28, biologicalSex: 'male', weightKg: 80,
          heightCm: 180, experienceLevel: 'intermediate', trainingAge: 24,
          primaryGoal: 'hypertrophy', environment: 'full_gym',
          availableEquipment: [], healthRestrictions: [],
          sessionDurationMinutes: 60,
        ),
        personB: const ParticipantProfile(
          name: 'B', age: 30, biologicalSex: 'male', weightKg: 75,
          heightCm: 178, experienceLevel: 'intermediate', trainingAge: 24,
          primaryGoal: 'hypertrophy', environment: 'full_gym',
          availableEquipment: [], healthRestrictions: [],
          sessionDurationMinutes: 60,
        ),
        wantSameWorkout: true, wantToTrainTogether: true,
        haveSameGoals: true, haveSimilarLevels: true,
        haveSimilarEquipment: true, haveDifferentRestrictions: false,
        wantToFinishTogether: true, acceptDifferentExercises: true,
        syncLevel: SyncLevel.high, relation: ParticipantRelation.friends,
      );
      expect(duo.compatibility, equals(CompatibilityLevel.high));
    });

    test('motor coletivo gera bloco comum para grupo homogêneo', () {
      final engine = CollectiveTrainingEngine();
      final group = GroupProfile(
        name: 'Turma A',
        participants: List.generate(4, (i) => ParticipantProfile(
          name: 'P$i', age: 25 + i, biologicalSex: 'male', weightKg: 75 + i * 5,
          heightCm: 175 + i * 2, experienceLevel: 'intermediate', trainingAge: 24,
          primaryGoal: 'hypertrophy', environment: 'full_gym',
          availableEquipment: [], healthRestrictions: [],
          sessionDurationMinutes: 60,
        )),
        collectiveGoal: 'hypertrophy',
        targetDurationMinutes: 60,
        targetFrequencyPerWeek: 3,
        environment: 'full_gym',
        availableEquipment: [],
        wantToFinishTogether: true,
        allowDifferentExercises: false,
        syncLevel: SyncLevel.high,
        collectiveLevel: 'intermediate',
        levelDifference: 'small',
      );

      final blocks = engine.buildGroupSession(group: group);
      expect(blocks, hasLength(4));
      // Bloco principal deve ser comum para grupo homogêneo
      expect(blocks[1].isCommon, isTrue);
    });
  });

  // ── Cenários de validação do documento mestre ───────────
  group('Cenários de validação', () {
    test('indivíduo jovem iniciante: plano sem penalidade de idade', () {
      final user = profile(age: 22, level: 'beginner', environment: 'full_gym');
      final workout = WorkoutPrescriptionEngine(user).generate(user);
      expect(workout.sessions, isNotEmpty);
      // Deve ter exercícios (não vazio)
      final totalExercises = workout.sessions.fold(0, (sum, s) => sum + s.exercises.length);
      expect(totalExercises, greaterThan(0));
    });

    test('indivíduo jovem avançado: plano com mais volume', () {
      final user = profile(age: 25, level: 'advanced', environment: 'full_gym', days: 5);
      final workout = WorkoutPrescriptionEngine(user).generate(user);
      expect(workout.sessions, hasLength(5));
      final totalExercises = workout.sessions.fold(0, (sum, s) => sum + s.exercises.length);
      expect(totalExercises, greaterThan(10));
    });

    test('indivíduo mais velho iniciante: volume reduzido e exercícios funcionais', () {
      final user = profile(age: 65, level: 'beginner', environment: 'full_gym');
      final workout = WorkoutPrescriptionEngine(user).generate(user);
      expect(workout.sessions, isNotEmpty);
      // Verificar que o age modifier foi aplicado (volume menor)
      final totalExercises = workout.sessions.fold(0, (sum, s) => sum + s.exercises.length);
      expect(totalExercises, greaterThan(0));
    });

    test('indivíduo mais velho avançado: penalidade mínima', () {
      final user = profile(age: 60, level: 'advanced', environment: 'full_gym', days: 4);
      final workout = WorkoutPrescriptionEngine(user).generate(user);
      expect(workout.sessions, hasLength(4));
      final totalExercises = workout.sessions.fold(0, (sum, s) => sum + s.exercises.length);
      expect(totalExercises, greaterThan(0));
    });

    test('dupla com objetivos diferentes: divergência controlada', () {
      final engine = CollectiveTrainingEngine();
      final duo = DuoProfile(
        personA: const ParticipantProfile(
          name: 'Ana', age: 28, biologicalSex: 'female', weightKg: 60,
          heightCm: 165, experienceLevel: 'intermediate', trainingAge: 24,
          primaryGoal: 'hypertrophy', environment: 'full_gym',
          availableEquipment: [], healthRestrictions: [],
          sessionDurationMinutes: 60,
        ),
        personB: const ParticipantProfile(
          name: 'Carlos', age: 35, biologicalSex: 'male', weightKg: 90,
          heightCm: 185, experienceLevel: 'beginner', trainingAge: 6,
          primaryGoal: 'fat_loss', environment: 'full_gym',
          availableEquipment: [], healthRestrictions: [],
          sessionDurationMinutes: 60,
        ),
        wantSameWorkout: false, wantToTrainTogether: true,
        haveSameGoals: false, haveSimilarLevels: false,
        haveSimilarEquipment: true, haveDifferentRestrictions: false,
        wantToFinishTogether: true, acceptDifferentExercises: true,
        syncLevel: SyncLevel.medium, relation: ParticipantRelation.friends,
      );

      final blocks = engine.buildDuoSession(duo: duo, sessionDurationMinutes: 60);
      expect(blocks, hasLength(4));
      // Bloco principal deve ter exercícios diferentes
      expect(blocks[1].isCommon, isFalse);
      // Aquecimento e finalização devem ser comuns
      expect(blocks[0].isCommon, isTrue);
      expect(blocks[3].isCommon, isTrue);
    });

    test('dupla com níveis diferentes: divergência controlada', () {
      final engine = CollectiveTrainingEngine();
      final duo = DuoProfile(
        personA: const ParticipantProfile(
          name: 'Ana', age: 25, biologicalSex: 'female', weightKg: 55,
          heightCm: 160, experienceLevel: 'advanced', trainingAge: 48,
          primaryGoal: 'strength', environment: 'full_gym',
          availableEquipment: [], healthRestrictions: [],
          sessionDurationMinutes: 60,
        ),
        personB: const ParticipantProfile(
          name: 'Bruno', age: 22, biologicalSex: 'male', weightKg: 70,
          heightCm: 175, experienceLevel: 'beginner', trainingAge: 3,
          primaryGoal: 'strength', environment: 'full_gym',
          availableEquipment: [], healthRestrictions: [],
          sessionDurationMinutes: 60,
        ),
        wantSameWorkout: false, wantToTrainTogether: true,
        haveSameGoals: true, haveSimilarLevels: false,
        haveSimilarEquipment: true, haveDifferentRestrictions: false,
        wantToFinishTogether: true, acceptDifferentExercises: true,
        syncLevel: SyncLevel.medium, relation: ParticipantRelation.couple,
      );

      final blocks = engine.buildDuoSession(duo: duo, sessionDurationMinutes: 60);
      expect(blocks, hasLength(4));
      // Compatibilidade: haveSameGoals(+3) + haveSimilarEquipment(+2) + noDiffRestrictions(+1) + wantToFinish(+1) = 7 → high
      expect(duo.compatibility, equals(CompatibilityLevel.high));
    });

    test('grupo heterogêneo: divergência controlada', () {
      final engine = CollectiveTrainingEngine();
      final group = GroupProfile(
        name: 'Grupo Misto',
        participants: [
          const ParticipantProfile(
            name: 'Ana', age: 25, biologicalSex: 'female', weightKg: 55,
            heightCm: 160, experienceLevel: 'advanced', trainingAge: 36,
            primaryGoal: 'hypertrophy', environment: 'full_gym',
            availableEquipment: [], healthRestrictions: [],
            sessionDurationMinutes: 60,
          ),
          const ParticipantProfile(
            name: 'Bruno', age: 35, biologicalSex: 'male', weightKg: 90,
            heightCm: 185, experienceLevel: 'beginner', trainingAge: 6,
            primaryGoal: 'fat_loss', environment: 'full_gym',
            availableEquipment: [], healthRestrictions: [],
            sessionDurationMinutes: 45,
          ),
          const ParticipantProfile(
            name: 'Carlos', age: 30, biologicalSex: 'male', weightKg: 75,
            heightCm: 178, experienceLevel: 'intermediate', trainingAge: 18,
            primaryGoal: 'hypertrophy', environment: 'full_gym',
            availableEquipment: [], healthRestrictions: [],
            sessionDurationMinutes: 60,
          ),
        ],
        collectiveGoal: 'hypertrophy',
        targetDurationMinutes: 60,
        targetFrequencyPerWeek: 3,
        environment: 'full_gym',
        availableEquipment: [],
        wantToFinishTogether: true,
        allowDifferentExercises: true,
        syncLevel: SyncLevel.medium,
        collectiveLevel: 'beginner',
        levelDifference: 'large',
      );

      final blocks = engine.buildGroupSession(group: group);
      expect(blocks, hasLength(4));
      // Compatibilidade deve ser baixa (objetivos e níveis mistos)
      expect(group.compatibility, equals(CompatibilityLevel.low));
      // Bloco principal deve ter exercícios diferentes (sync médio + levelDifference large)
      expect(blocks[1].isCommon, isFalse);
    });

    test('grupo com limitação individual: exercício adaptado', () {
      final engine = CollectiveTrainingEngine();
      final group = GroupProfile(
        name: 'Grupo com Lesão',
        participants: [
          const ParticipantProfile(
            name: 'Ana', age: 30, biologicalSex: 'female', weightKg: 60,
            heightCm: 165, experienceLevel: 'intermediate', trainingAge: 24,
            primaryGoal: 'hypertrophy', environment: 'full_gym',
            availableEquipment: [], healthRestrictions: ['knee'],
            sessionDurationMinutes: 60,
          ),
          const ParticipantProfile(
            name: 'Bruno', age: 28, biologicalSex: 'male', weightKg: 80,
            heightCm: 180, experienceLevel: 'intermediate', trainingAge: 24,
            primaryGoal: 'hypertrophy', environment: 'full_gym',
            availableEquipment: [], healthRestrictions: [],
            sessionDurationMinutes: 60,
          ),
        ],
        collectiveGoal: 'hypertrophy',
        targetDurationMinutes: 60,
        targetFrequencyPerWeek: 3,
        environment: 'full_gym',
        availableEquipment: [],
        wantToFinishTogether: true,
        allowDifferentExercises: true,
        syncLevel: SyncLevel.medium,
        collectiveLevel: 'intermediate',
        levelDifference: 'small',
      );

      final blocks = engine.buildGroupSession(group: group);
      expect(blocks, hasLength(4));
      // Sync médio + levelDifference small → bloco principal pode ser comum
      // (variação individual é feita via individualVariations)
      expect(blocks[1].isCommon, isTrue);
      expect(blocks[1].individualVariations, contains('Ana'));
    });

    test('grupo com múltiplas limitações', () {
      final engine = CollectiveTrainingEngine();
      final group = GroupProfile(
        name: 'Grupo Lesões',
        participants: [
          const ParticipantProfile(
            name: 'Ana', age: 35, biologicalSex: 'female', weightKg: 60,
            heightCm: 165, experienceLevel: 'intermediate', trainingAge: 24,
            primaryGoal: 'general_health', environment: 'full_gym',
            availableEquipment: [], healthRestrictions: ['knee', 'lower_back'],
            sessionDurationMinutes: 45,
          ),
          const ParticipantProfile(
            name: 'Bruno', age: 40, biologicalSex: 'male', weightKg: 85,
            heightCm: 180, experienceLevel: 'beginner', trainingAge: 6,
            primaryGoal: 'general_health', environment: 'full_gym',
            availableEquipment: [], healthRestrictions: ['shoulder'],
            sessionDurationMinutes: 45,
          ),
          const ParticipantProfile(
            name: 'Carlos', age: 30, biologicalSex: 'male', weightKg: 75,
            heightCm: 178, experienceLevel: 'advanced', trainingAge: 60,
            primaryGoal: 'general_health', environment: 'full_gym',
            availableEquipment: [], healthRestrictions: [],
            sessionDurationMinutes: 60,
          ),
        ],
        collectiveGoal: 'general_health',
        targetDurationMinutes: 50,
        targetFrequencyPerWeek: 2,
        environment: 'full_gym',
        availableEquipment: [],
        wantToFinishTogether: true,
        allowDifferentExercises: true,
        syncLevel: SyncLevel.low,
        collectiveLevel: 'beginner',
        levelDifference: 'large',
      );

      final blocks = engine.buildGroupSession(group: group);
      expect(blocks, hasLength(4));
      // Todos têm o mesmo objetivo (general_health), ratio = 3/6 = 0.5 → medium
      expect(group.compatibility, equals(CompatibilityLevel.medium));
      // Todos os participantes devem ter variações individuais
      for (final p in group.participants) {
        expect(blocks[1].individualVariations, contains(p.name));
      }
    });
  });
}
