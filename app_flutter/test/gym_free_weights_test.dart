import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/exercise_library_v2/v2_exercise_library.dart';
import 'package:app/features/exercise_library_v2/data/home_exercises.dart';
import 'package:app/features/exercise_library_v2/data/gym_free_weights_exercises.dart';
import 'package:app/features/exercise_library_v2/bridge/v2_home_bridge.dart';
import 'package:app/features/exercise_library_v2/enums/exercise_block.dart';
import 'package:app/features/exercise_library_v2/enums/movement_pattern.dart';
import 'package:app/features/exercise_library_v2/enums/goal.dart';
import 'package:app/features/exercise_library_v2/enums/difficulty.dart';
import 'package:app/features/exercise_library_v2/enums/environment.dart';
import 'package:app/features/exercise_library_v2/enums/equipment.dart';
import 'package:app/features/exercise_library_v2/enums/relationship_type.dart';
import 'package:app/features/exercise_library_v2/queries/exercise_query.dart';
import 'package:app/features/workout/intelligence/user_training_profile.dart';
import 'package:app/features/workout/intelligence/training_intelligence.dart';
import 'package:app/features/exercise_library_v2/enums/modality.dart';

void main() {
  setUpAll(() {
    final library = V2ExerciseLibrary();
    library.registerAll(createHomeExercises());
    library.registerAll(createGymFreeWeightExercises());
    V2HomeBridge.registerAll(createHomeExercises());
    V2HomeBridge.registerAll(createGymFreeWeightExercises());
  });

  final gymExercises = createGymFreeWeightExercises();

  // ═══════════════════════════════════════════════════════════════
  // TESTE 1: Registro e Contagem
  // ═══════════════════════════════════════════════════════════════

  test('Gym Free Weights: registro e contagem', () {
    print('\n=== TESTE 1: REGISTRO E CONTAGEM ===');

    final library = V2ExerciseLibrary();
    final gymBlock = library.getByBlock(V2ExerciseBlock.gymFreeWeights);

    print('Exercícios Gym Free Weights: ${gymBlock.length}');
    expect(gymBlock.length, greaterThanOrEqualTo(20),
        reason: 'Deve haver pelo menos 20 exercícios Gym');

    for (final ex in gymBlock) {
      expect(ex.block, V2ExerciseBlock.gymFreeWeights);
      expect(ex.id, startsWith('gym_'));
      expect(ex.name, isNotEmpty);
      expect(ex.pattern, isNotNull);
      expect(ex.difficulty, isNotNull);
      expect(ex.environments, contains(V2Environment.gym));
    }

    print('✓ Todos os ${gymBlock.length} exercícios registrados corretamente');
  });

  // ═══════════════════════════════════════════════════════════════
  // TESTE 2: Cobertura por Padrão
  // ═══════════════════════════════════════════════════════════════

  test('Gym Free Weights: cobertura por padrão', () {
    print('\n=== TESTE 2: COBERTURA POR PADRÃO ===');

    final patterns = <V2MovementPattern, int>{};
    for (final ex in gymExercises) {
      patterns[ex.pattern] = (patterns[ex.pattern] ?? 0) + 1;
    }

    print('Padrões cobertos:');
    for (final entry in patterns.entries) {
      print('  ${entry.key.name}: ${entry.value} exercícios');
    }

    // Padrões obrigatórios
    expect(patterns.containsKey(V2MovementPattern.pushHorizontal), isTrue,
        reason: 'Deve ter push horizontal');
    expect(patterns.containsKey(V2MovementPattern.pushVertical), isTrue,
        reason: 'Deve ter push vertical');
    expect(patterns.containsKey(V2MovementPattern.pullHorizontal), isTrue,
        reason: 'Deve ter pull horizontal');
    expect(patterns.containsKey(V2MovementPattern.squat), isTrue,
        reason: 'Deve ter squat');
    expect(patterns.containsKey(V2MovementPattern.hipHinge), isTrue,
        reason: 'Deve ter hinge');
    expect(patterns.containsKey(V2MovementPattern.hipExtension), isTrue,
        reason: 'Deve ter hip extension');

    print('✓ Padrões obrigatórios cobertos');
  });

  // ═══════════════════════════════════════════════════════════════
  // TESTE 3: Cobertura por Objetivo
  // ═══════════════════════════════════════════════════════════════

  test('Gym Free Weights: cobertura por objetivo', () {
    print('\n=== TESTE 3: COBERTURA POR OBJETIVO ===');

    final goalCounts = <V2Goal, int>{};
    for (final ex in gymExercises) {
      for (final goal in ex.goalAffinity.keys) {
        goalCounts[goal] = (goalCounts[goal] ?? 0) + 1;
      }
    }

    print('Objetivos cobertos:');
    for (final entry in goalCounts.entries) {
      print('  ${entry.key.name}: ${entry.value} exercícios');
    }

    expect(goalCounts.containsKey(V2Goal.hypertrophy), isTrue,
        reason: 'Deve cobrir hipertrofia');
    expect(goalCounts.containsKey(V2Goal.strength), isTrue,
        reason: 'Deve cobrir força');
    expect(goalCounts.containsKey(V2Goal.generalFitness), isTrue,
        reason: 'Deve cobrir condicionamento geral');

    print('✓ Objetivos obrigatórios cobertos');
  });

  // ═══════════════════════════════════════════════════════════════
  // TESTE 4: Cobertura por Nível
  // ═══════════════════════════════════════════════════════════════

  test('Gym Free Weights: cobertura por nível', () {
    print('\n=== TESTE 4: COBERTURA POR NÍVEL ===');

    final difficultyCounts = <V2Difficulty, int>{};
    for (final ex in gymExercises) {
      difficultyCounts[ex.difficulty] = (difficultyCounts[ex.difficulty] ?? 0) + 1;
    }

    print('Níveis:');
    for (final entry in difficultyCounts.entries) {
      print('  ${entry.key.name}: ${entry.value} exercícios');
    }

    // Deve ter exercícios para iniciantes e intermediários
    expect((difficultyCounts[V2Difficulty.level1] ?? 0) +
        (difficultyCounts[V2Difficulty.level2] ?? 0), greaterThanOrEqualTo(5),
        reason: 'Deve ter exercícios para iniciantes (level1+level2)');
    expect((difficultyCounts[V2Difficulty.level3] ?? 0) +
        (difficultyCounts[V2Difficulty.level4] ?? 0), greaterThanOrEqualTo(5),
        reason: 'Deve ter exercícios para intermediários (level3+level4)');

    print('✓ Níveis cobertos');
  });

  // ═══════════════════════════════════════════════════════════════
  // TESTE 5: Equipamento e Ambiente
  // ═══════════════════════════════════════════════════════════════

  test('Gym Free Weights: equipamento e ambiente', () {
    print('\n=== TESTE 5: EQUIPAMENTO E AMBIENTE ===');

    for (final ex in gymExercises) {
      // Todos devem ser para ambiente gym
      expect(ex.environments, contains(V2Environment.gym),
          reason: '${ex.id} deve ser para ambiente gym');

      // Todos devem ter o bloco correto
      expect(ex.block, V2ExerciseBlock.gymFreeWeights);

      // Equipamento deve ser de pesos livres (não máquinas)
      final hasValidEquipment = ex.requiredEquipment.isEmpty ||
          ex.requiredEquipment.any((e) =>
              e == V2Equipment.dumbbell ||
              e == V2Equipment.barbell ||
              e == V2Equipment.bench ||
              e == V2Equipment.plate);
      expect(hasValidEquipment, isTrue,
          reason: '${ex.id} deve usar equipamento de pesos livres');
    }

    print('✓ Equipamento e ambiente validados');
  });

  // ═══════════════════════════════════════════════════════════════
  // TESTE 6: Progressões e Regressões
  // ═══════════════════════════════════════════════════════════════

  test('Gym Free Weights: progressões e regressões', () {
    print('\n=== TESTE 6: PROGRESSÕES E REGRESSÕES ===');

    var withRelationships = 0;
    final library = V2ExerciseLibrary();

    for (final ex in gymExercises) {
      if (ex.relatedExercises.isNotEmpty) {
        withRelationships++;

        // Verificar que IDs referenciados existem
        for (final rel in ex.relatedExercises) {
          final target = library.getById(rel.targetId);
          expect(target, isNotNull,
              reason: '${ex.id} referencia ${rel.targetId} que não existe');
        }
      }
    }

    print('Exercícios com relações: $withRelationships/${gymExercises.length}');
    expect(withRelationships, greaterThanOrEqualTo(gymExercises.length * 0.5),
        reason: 'Pelo menos 50% dos exercícios devem ter relações');

    print('✓ Progressões e regressões validadas');
  });

  // ═══════════════════════════════════════════════════════════════
  // TESTE 7: Exercícios Home Continuam Funcionando
  // ═══════════════════════════════════════════════════════════════

  test('Home exercises: ainda funcionam corretamente', () {
    print('\n=== TESTE 7: HOME EXERCISES ===');

    final library = V2ExerciseLibrary();
    final homeBlock = library.getByBlock(V2ExerciseBlock.home);

    print('Exercícios Home: ${homeBlock.length}');
    expect(homeBlock.length, 46, reason: 'Devem existir 46 exercícios Home');

    for (final ex in homeBlock) {
      expect(ex.block, V2ExerciseBlock.home);
      expect(ex.id, startsWith('home_'));
      expect(ex.environments, contains(V2Environment.home));
    }

    print('✓ 46 exercícios Home funcionando corretamente');
  });

  // ═══════════════════════════════════════════════════════════════
  // TESTE 8: Training Intelligence usa exercícios Gym
  // ═══════════════════════════════════════════════════════════════

  test('Training Intelligence: ambiente gym usa exercícios gym', () {
    print('\n=== TESTE 8: TRAINING INTELLIGENCE GYM ===');

    final intelligence = TrainingIntelligence();

    final gymProfile = UserTrainingProfile(
      uid: 'gym_test', age: 25, primaryGoal: V2Goal.hypertrophy,
      modality: V2Modality.hypertrophy,
      environment: V2Environment.gym,
      availableEquipment: const [V2Equipment.dumbbell, V2Equipment.barbell, V2Equipment.bench],
      availableDaysPerWeek: 3, sessionDurationMinutes: 45,
      experienceLevel: ExperienceLevel.regularly, trainingAgeMonths: 24,
    );

    final workout = intelligence.generateWorkout(gymProfile);

    print('Sessões: ${workout.sessions.length}');
    expect(workout.sessions.length, 3);

    // Verificar que ao menos alguns exercícios são do bloco gym
    final allExercises = workout.sessions
        .expand((s) => s.exercises)
        .map((e) => e.exercise)
        .toList();

    final gymExerciseCount = allExercises
        .where((e) => e.tags.contains('v2') && e.id.startsWith('gym_'))
        .length;

    print('Exercícios Gym prescritos: $gymExerciseCount/${allExercises.length}');

    // Pelo menos metade devem ser gym
    expect(gymExerciseCount, greaterThanOrEqualTo(allExercises.length ~/ 2),
        reason: ' Maioria dos exercícios devem ser do bloco gym para perfil gym');

    print('✓ Training Intelligence usa exercícios Gym corretamente');
  });

  // ═══════════════════════════════════════════════════════════════
  // TESTE 9: Home vs Gym são Distintos
  // ═══════════════════════════════════════════════════════════════

  test('Home vs Gym: blocos são distintos', () {
    print('\n=== TESTE 9: HOME VS GYM DISTINTOS ===');

    final library = V2ExerciseLibrary();
    final homeIds = library.getByBlock(V2ExerciseBlock.home).map((e) => e.id).toSet();
    final gymIds = library.getByBlock(V2ExerciseBlock.gymFreeWeights).map((e) => e.id).toSet();

    final intersection = homeIds.intersection(gymIds);
    expect(intersection, isEmpty, reason: 'IDs Home e Gym não devem se sobrepôr');

    print('Home: ${homeIds.length} exercícios');
    print('Gym: ${gymIds.length} exercícios');
    print('Interseção: ${intersection.length} (deve ser 0)');

    print('✓ Blocos Home e Gym são distintos');
  });

  // ═══════════════════════════════════════════════════════════════
  // TESTE 10: Dados V2 Completos
  // ═══════════════════════════════════════════════════════════════

  test('Gym Free Weights: dados V2 completos', () {
    print('\n=== TESTE 10: DADOS V2 COMPLETOS ===');

    for (final ex in gymExercises) {
      // Identidade
      expect(ex.id, isNotEmpty);
      expect(ex.name, isNotEmpty);

      // Classificação
      expect(ex.pattern, isNotNull);
      expect(ex.category, isNotNull);
      expect(ex.defaultRoles, isNotEmpty);

      // Equipamento
      expect(ex.environments, isNotEmpty);

      // Músculos
      expect(ex.primaryMuscles, isNotEmpty,
          reason: '${ex.id} deve ter primaryMuscles');

      // Dificuldade
      expect(ex.difficulty.index, greaterThanOrEqualTo(0));
      expect(ex.difficulty.index, lessThanOrEqualTo(4));

      // Demandas
      expect(ex.demands, isNotNull);

      // Engine rules
      expect(ex.engineRules, isNotNull);
      expect(ex.engineRules.repRangeMin, greaterThan(0));
      expect(ex.engineRules.repRangeMax, greaterThanOrEqualTo(ex.engineRules.repRangeMin));

      // Cues
      expect(ex.cues, isNotEmpty,
          reason: '${ex.id} deve ter cues');
    }

    print('✓ Todos os ${gymExercises.length} exercícios têm dados V2 completos');
  });
}
