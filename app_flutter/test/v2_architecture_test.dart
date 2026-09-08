import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/exercise_library_v2/enums/movement_pattern.dart';
import 'package:app/features/exercise_library_v2/enums/body_region.dart';
import 'package:app/features/exercise_library_v2/enums/joint.dart';
import 'package:app/features/exercise_library_v2/enums/modality.dart';
import 'package:app/features/exercise_library_v2/enums/environment.dart';
import 'package:app/features/exercise_library_v2/enums/equipment.dart';
import 'package:app/features/exercise_library_v2/enums/difficulty.dart';
import 'package:app/features/exercise_library_v2/enums/exercise_category.dart';
import 'package:app/features/exercise_library_v2/enums/exercise_block.dart';
import 'package:app/features/exercise_library_v2/enums/exercise_role.dart';
import 'package:app/features/exercise_library_v2/enums/goal.dart';
import 'package:app/features/exercise_library_v2/enums/stimulus.dart';
import 'package:app/features/exercise_library_v2/enums/compatibility.dart';
import 'package:app/features/exercise_library_v2/enums/relationship_type.dart';
import 'package:app/features/exercise_library_v2/enums/limitation_severity.dart';
import 'package:app/features/exercise_library_v2/enums/adaptation_type.dart';
import 'package:app/features/exercise_library_v2/enums/feedback_quality.dart';
import 'package:app/features/exercise_library_v2/enums/intensity.dart';
import 'package:app/features/exercise_library_v2/enums/stability_type.dart';
import 'package:app/features/exercise_library_v2/enums/length_bias.dart';
import 'package:app/features/exercise_library_v2/enums/capacity.dart';
import 'package:app/features/exercise_library_v2/models/v2_demand_profile.dart';
import 'package:app/features/exercise_library_v2/models/v2_relationship.dart';
import 'package:app/features/exercise_library_v2/models/v2_limitation_rule.dart';
import 'package:app/features/exercise_library_v2/models/v2_adaptation.dart';
import 'package:app/features/exercise_library_v2/models/v2_engine_rules.dart';
import 'package:app/features/exercise_library_v2/models/v2_feedback.dart';
import 'package:app/features/exercise_library_v2/models/v2_exercise.dart';
import 'package:app/features/exercise_library_v2/queries/exercise_query.dart';
import 'package:app/features/exercise_library_v2/queries/compatibility_evaluator.dart';
import 'package:app/features/exercise_library_v2/queries/relationship_resolver.dart';
import 'package:app/features/exercise_library_v2/v2_exercise_library.dart';

V2Exercise _testExercise({
  String id = 'test_001',
  String name = 'Teste Agachamento',
  V2ExerciseBlock block = V2ExerciseBlock.home,
  V2MovementPattern pattern = V2MovementPattern.squat,
  V2ExerciseCategory category = V2ExerciseCategory.compound,
  List<V2Equipment> equipment = const [],
  List<V2Environment> environments = const [V2Environment.home],
  V2Difficulty difficulty = V2Difficulty.level2,
  List<String> primaryMuscles = const ['quadriceps'],
}) {
  return V2Exercise(
    id: id,
    name: name,
    block: block,
    pattern: pattern,
    category: category,
    requiredEquipment: equipment,
    environments: environments,
    difficulty: difficulty,
    primaryMuscles: primaryMuscles,
    demands: const V2DemandProfile(),
    engineRules: const V2EngineRules(),
  );
}

void main() {
  group('Enums - Vocabulário Controlado', () {
    test('V2MovementPattern possui extensões de classificação', () {
      expect(V2MovementPattern.squat.loadsSpine, isTrue);
      expect(V2MovementPattern.pushHorizontal.stressesShoulder, isTrue);
      expect(V2MovementPattern.squat.stressesKnee, isTrue);
      expect(V2MovementPattern.squat.isCompoundByNature, isTrue);
      expect(V2MovementPattern.elbowFlexion.isCompoundByNature, isFalse);
    });

    test('V2BodyRegion possui values', () {
      expect(V2BodyRegion.values.length, 4);
      expect(V2BodyRegion.values, contains(V2BodyRegion.upperBody));
      expect(V2BodyRegion.values, contains(V2BodyRegion.lowerBody));
      expect(V2BodyRegion.values, contains(V2BodyRegion.trunk));
      expect(V2BodyRegion.values, contains(V2BodyRegion.pelvis));
    });

    test('V2Difficulty extensions', () {
      expect(V2Difficulty.level1.numeric, 1);
      expect(V2Difficulty.level3.numeric, 3);
    });

    test('V2Difficulty fromLevel', () {
      expect(V2DifficultyX.fromLevel(1), V2Difficulty.level1);
      expect(V2DifficultyX.fromLevel(3), V2Difficulty.level3);
      expect(V2DifficultyX.fromLevel(5), V2Difficulty.level5);
      expect(V2DifficultyX.fromLevel(0), V2Difficulty.level1);
      expect(V2DifficultyX.fromLevel(10), V2Difficulty.level5);
    });

    test('Todos os enums possuem valores', () {
      expect(V2Modality.values.length, greaterThanOrEqualTo(5));
      expect(V2Environment.values.length, greaterThanOrEqualTo(4));
      expect(V2Equipment.values.length, greaterThanOrEqualTo(10));
      expect(V2ExerciseBlock.values.length, 8);
      expect(V2MovementPattern.values.length, greaterThanOrEqualTo(25));
      expect(V2BodyRegion.values.length, 4);
      expect(V2Joint.values.length, greaterThanOrEqualTo(5));
      expect(V2Difficulty.values.length, 5);
      expect(V2ExerciseCategory.values.length, 3);
      expect(V2ExerciseRole.values.length, 7);
      expect(V2Goal.values.length, greaterThanOrEqualTo(5));
      expect(V2Stimulus.values.length, greaterThanOrEqualTo(5));
      expect(V2Compatibility.values.length, 3);
      expect(V2RelationshipType.values.length, 10);
      expect(V2LimitationSeverity.values.length, 3);
      expect(V2AdaptationType.values.length, greaterThanOrEqualTo(10));
      expect(V2FeedbackQuality.values.length, 5);
      expect(V2Intensity.values.length, 5);
      expect(V2StabilityType.values.length, greaterThanOrEqualTo(4));
      expect(V2LengthBias.values.length, 3);
      expect(V2Capacity.values.length, greaterThanOrEqualTo(5));
    });
  });

  group('Models - Serialização', () {
    test('V2DemandProfile roundtrip', () {
      const original = V2DemandProfile(
        strength: V2Intensity.high,
        stability: V2Intensity.moderate,
        mobility: V2Intensity.low,
      );
      final map = original.toMap();
      final restored = V2DemandProfile.fromMap(map);

      expect(restored.strength, V2Intensity.high);
      expect(restored.stability, V2Intensity.moderate);
      expect(restored.mobility, V2Intensity.low);
    });

    test('V2Relationship roundtrip', () {
      const original = V2Relationship(
        targetId: 'ex_002',
        type: V2RelationshipType.progression,
        note: 'Versão mais difícil',
      );
      final map = original.toMap();
      final restored = V2Relationship.fromMap(map);

      expect(restored.targetId, 'ex_002');
      expect(restored.type, V2RelationshipType.progression);
      expect(restored.note, 'Versão mais difícil');
    });

    test('V2LimitationRule roundtrip', () {
      const original = V2LimitationRule(
        joint: V2Joint.knee,
        severity: V2LimitationSeverity.moderate,
        symptoms: ['dor_patelar'],
        recommendedAdaptations: [V2AdaptationType.reduceAmplitude],
        alternativeExerciseIds: ['alt_001'],
      );
      final map = original.toMap();
      final restored = V2LimitationRule.fromMap(map);

      expect(restored.joint, V2Joint.knee);
      expect(restored.severity, V2LimitationSeverity.moderate);
      expect(restored.symptoms, ['dor_patelar']);
      expect(restored.recommendedAdaptations, [V2AdaptationType.reduceAmplitude]);
      expect(restored.alternativeExerciseIds, ['alt_001']);
    });

    test('V2LimitationRule matches', () {
      const rule = V2LimitationRule(
        joint: V2Joint.knee,
        severity: V2LimitationSeverity.moderate,
      );

      expect(rule.matches(V2Joint.knee, V2LimitationSeverity.moderate), isTrue);
      expect(rule.matches(V2Joint.knee, V2LimitationSeverity.severe), isTrue);
      expect(rule.matches(V2Joint.knee, V2LimitationSeverity.mild), isFalse);
      expect(rule.matches(V2Joint.shoulder, V2LimitationSeverity.severe), isFalse);
    });

    test('V2EngineRules roundtrip', () {
      const original = V2EngineRules(
        repRangeMin: 6,
        repRangeMax: 10,
        defaultRestSeconds: 180,
        isUnilateral: true,
        isCompound: true,
      );
      final map = original.toMap();
      final restored = V2EngineRules.fromMap(map);

      expect(restored.repRangeMin, 6);
      expect(restored.repRangeMax, 10);
      expect(restored.defaultRestSeconds, 180);
      expect(restored.isUnilateral, isTrue);
      expect(restored.isCompound, isTrue);
    });

    test('V2Feedback roundtrip', () {
      final original = V2Feedback(
        exerciseId: 'ex_001',
        quality: V2FeedbackQuality.executedWell,
        difficultyUsed: V2Difficulty.level3,
        perceivedEffort: 0.7,
        recordedAt: DateTime(2026, 1, 1),
      );
      final map = original.toMap();
      final restored = V2Feedback.fromMap(map);

      expect(restored.exerciseId, 'ex_001');
      expect(restored.quality, V2FeedbackQuality.executedWell);
      expect(restored.difficultyUsed, V2Difficulty.level3);
      expect(restored.perceivedEffort, 0.7);
    });

    test('V2Exercise roundtrip', () {
      final original = _testExercise(
        id: 'squat_001',
        name: 'Agachamento Livre',
        equipment: [V2Equipment.barbell],
        difficulty: V2Difficulty.level3,
      );
      final map = original.toMap();
      final restored = V2Exercise.fromMap(map);

      expect(restored.id, 'squat_001');
      expect(restored.name, 'Agachamento Livre');
      expect(restored.requiredEquipment, [V2Equipment.barbell]);
      expect(restored.difficulty, V2Difficulty.level3);
      expect(restored.pattern, V2MovementPattern.squat);
    });

    test('V2Exercise relationship helpers', () {
      final exercise = V2Exercise(
        id: 'ex_001',
        name: 'Teste',
        block: V2ExerciseBlock.home,
        pattern: V2MovementPattern.squat,
        category: V2ExerciseCategory.compound,
        environments: const [V2Environment.home],
        difficulty: V2Difficulty.level2,
        demands: const V2DemandProfile(),
        engineRules: const V2EngineRules(),
        relatedExercises: const [
          V2Relationship(targetId: 'ex_002', type: V2RelationshipType.progression),
          V2Relationship(targetId: 'ex_003', type: V2RelationshipType.regression),
          V2Relationship(targetId: 'ex_004', type: V2RelationshipType.substitute),
        ],
      );

      expect(exercise.progressionIds, ['ex_002']);
      expect(exercise.regressionIds, ['ex_003']);
      expect(exercise.substituteIds, ['ex_004']);
    });
  });

  group('Queries - ExerciseQuery', () {
    test('ExerciseQuery.forMuscle cria query correta', () {
      final query = ExerciseQuery.forMuscle(
        muscle: 'quadriceps',
        equipment: [V2Equipment.dumbbell],
        maxDifficulty: V2Difficulty.level3,
        compoundOnly: true,
      );

      expect(query.primaryMuscles, ['quadriceps']);
      expect(query.availableEquipment, [V2Equipment.dumbbell]);
      expect(query.maxDifficulty, V2Difficulty.level3);
      expect(query.requireCompound, isTrue);
    });
  });

  group('Queries - CompatibilityEvaluator', () {
    test('Exercício sem equipamento é compatível com casa sem equipamento', () {
      final exercise = _testExercise();
      final result = V2CompatibilityEvaluator.evaluate(
        exercise: exercise,
        userEnvironments: [V2Environment.home],
        userEquipment: const [],
        userDifficulty: V2Difficulty.level2,
        userLimitations: const [],
      );

      expect(result.isEligible, isTrue);
    });

    test('Exercício com barra NÃO é compatível com casa sem equipamento', () {
      final exercise = _testExercise(equipment: [V2Equipment.barbell]);
      final result = V2CompatibilityEvaluator.evaluate(
        exercise: exercise,
        userEnvironments: [V2Environment.home],
        userEquipment: const [],
        userDifficulty: V2Difficulty.level2,
        userLimitations: const [],
      );

      expect(result.isEligible, isFalse);
      expect(result.code, 'equipment_not_available');
    });

    test('Exercício avançado para iniciante retorna adaptable', () {
      final exercise = _testExercise(difficulty: V2Difficulty.level5);
      final result = V2CompatibilityEvaluator.evaluate(
        exercise: exercise,
        userEnvironments: [V2Environment.home],
        userEquipment: const [],
        userDifficulty: V2Difficulty.level1,
        userLimitations: const [],
      );

      expect(result.status, V2Compatibility.adaptable);
      expect(result.code, 'difficulty_too_high');
    });

    test('Limitação severa retorna inadequado', () {
      final exercise = V2Exercise(
        id: 'test_001',
        name: 'Teste',
        block: V2ExerciseBlock.home,
        pattern: V2MovementPattern.squat,
        category: V2ExerciseCategory.compound,
        environments: const [V2Environment.home],
        difficulty: V2Difficulty.level2,
        demands: const V2DemandProfile(),
        engineRules: const V2EngineRules(),
        limitationRules: const [
          V2LimitationRule(
            joint: V2Joint.knee,
            severity: V2LimitationSeverity.severe,
          ),
        ],
      );
      final result = V2CompatibilityEvaluator.evaluate(
        exercise: exercise,
        userEnvironments: [V2Environment.home],
        userEquipment: const [],
        userDifficulty: V2Difficulty.level3,
        userLimitations: const [
          UserLimitationInput(
            joint: V2Joint.knee,
            severity: V2LimitationSeverity.severe,
          ),
        ],
      );

      expect(result.status, V2Compatibility.inadequate);
      expect(result.code, 'limitation_severe');
    });

    test('Limitação leve retorna adaptable com adaptações', () {
      final exercise = V2Exercise(
        id: 'test_001',
        name: 'Teste',
        block: V2ExerciseBlock.home,
        pattern: V2MovementPattern.squat,
        category: V2ExerciseCategory.compound,
        environments: const [V2Environment.home],
        difficulty: V2Difficulty.level2,
        demands: const V2DemandProfile(),
        engineRules: const V2EngineRules(),
        limitationRules: const [
          V2LimitationRule(
            joint: V2Joint.knee,
            severity: V2LimitationSeverity.mild,
            recommendedAdaptations: [V2AdaptationType.reduceAmplitude],
          ),
        ],
      );
      final result = V2CompatibilityEvaluator.evaluate(
        exercise: exercise,
        userEnvironments: [V2Environment.home],
        userEquipment: const [],
        userDifficulty: V2Difficulty.level3,
        userLimitations: const [
          UserLimitationInput(
            joint: V2Joint.knee,
            severity: V2LimitationSeverity.moderate,
          ),
        ],
      );

      expect(result.status, V2Compatibility.adaptable);
      expect(result.suggestedAdaptations, isNotEmpty);
    });

    test('filterEligible filtra corretamente', () {
      final exercises = [
        _testExercise(id: 'bw', equipment: []),
        _testExercise(id: 'db', equipment: [V2Equipment.dumbbell]),
        _testExercise(id: 'bar', equipment: [V2Equipment.barbell]),
      ];

      final eligible = V2CompatibilityEvaluator.filterEligible(
        exercises: exercises,
        userEnvironments: [V2Environment.home],
        userEquipment: [V2Equipment.dumbbell],
        userDifficulty: V2Difficulty.level3,
        userLimitations: const [],
      );

      expect(eligible.length, 2);
      expect(eligible.map((e) => e.id).toList(), containsAll(['bw', 'db']));
      expect(eligible.map((e) => e.id).toList(), isNot(contains('bar')));
    });
  });

  group('Queries - RelationshipResolver', () {
    test('getRelated retorna exercícios do tipo correto', () {
      final resolver = RelationshipResolver([
        V2Exercise(
          id: 'a',
          name: 'A',
          block: V2ExerciseBlock.home,
          pattern: V2MovementPattern.squat,
          category: V2ExerciseCategory.compound,
          environments: const [V2Environment.home],
          difficulty: V2Difficulty.level2,
          demands: const V2DemandProfile(),
          engineRules: const V2EngineRules(),
          relatedExercises: const [
            V2Relationship(targetId: 'b', type: V2RelationshipType.progression),
            V2Relationship(targetId: 'c', type: V2RelationshipType.regression),
          ],
        ),
        _testExercise(id: 'b', name: 'B'),
        _testExercise(id: 'c', name: 'C'),
      ]);

      final progressions = resolver.getRelated('a', type: V2RelationshipType.progression);
      expect(progressions.length, 1);
      expect(progressions.first.id, 'b');

      final regressions = resolver.getRelated('a', type: V2RelationshipType.regression);
      expect(regressions.length, 1);
      expect(regressions.first.id, 'c');
    });

    test('getProgressionChain segue a cadeia', () {
      final resolver = RelationshipResolver([
        V2Exercise(
          id: 'a',
          name: 'A',
          block: V2ExerciseBlock.home,
          pattern: V2MovementPattern.squat,
          category: V2ExerciseCategory.compound,
          environments: const [V2Environment.home],
          difficulty: V2Difficulty.level1,
          demands: const V2DemandProfile(),
          engineRules: const V2EngineRules(),
          relatedExercises: const [
            V2Relationship(targetId: 'b', type: V2RelationshipType.progression),
          ],
        ),
        V2Exercise(
          id: 'b',
          name: 'B',
          block: V2ExerciseBlock.home,
          pattern: V2MovementPattern.squat,
          category: V2ExerciseCategory.compound,
          environments: const [V2Environment.home],
          difficulty: V2Difficulty.level3,
          demands: const V2DemandProfile(),
          engineRules: const V2EngineRules(),
          relatedExercises: const [
            V2Relationship(targetId: 'c', type: V2RelationshipType.progression),
          ],
        ),
        _testExercise(id: 'c', name: 'C'),
      ]);

      final chain = resolver.getProgressionChain('a');
      expect(chain.length, 3);
      expect(chain.map((e) => e.id).toList(), ['a', 'b', 'c']);
    });

    test('wouldConflict detecta redundância', () {
      final resolver = RelationshipResolver([
        V2Exercise(
          id: 'a',
          name: 'A',
          block: V2ExerciseBlock.home,
          pattern: V2MovementPattern.squat,
          category: V2ExerciseCategory.compound,
          environments: const [V2Environment.home],
          difficulty: V2Difficulty.level2,
          primaryMuscles: const ['quadriceps'],
          demands: const V2DemandProfile(),
          engineRules: const V2EngineRules(),
          relatedExercises: const [
            V2Relationship(targetId: 'b', type: V2RelationshipType.redundant),
          ],
        ),
        _testExercise(id: 'b', name: 'B', pattern: V2MovementPattern.pushHorizontal, primaryMuscles: ['chest']),
      ]);

      expect(resolver.wouldConflict('a', 'b'), isTrue);
      expect(resolver.wouldConflict('b', 'a'), isFalse);
    });
  });

  group('Biblioteca V2', () {
    test('register e query funcionam', () {
      final library = V2ExerciseLibrary();
      library.clear();

      library.register(_testExercise(id: 'home_squat', block: V2ExerciseBlock.home));
      library.register(_testExercise(id: 'gym_bench', block: V2ExerciseBlock.gymFreeWeights, pattern: V2MovementPattern.pushHorizontal, equipment: [V2Equipment.barbell]));
      library.register(_testExercise(id: 'home_pushup', block: V2ExerciseBlock.home, pattern: V2MovementPattern.pushHorizontal));

      expect(library.length, 3);

      final homeExercises = library.query(ExerciseQuery(blocks: [V2ExerciseBlock.home]));
      expect(homeExercises.length, 2);

      final squatExercises = library.query(ExerciseQuery(patterns: [V2MovementPattern.squat]));
      expect(squatExercises.length, 1);
      expect(squatExercises.first.id, 'home_squat');
    });

    test('getById retorna exercício correto', () {
      final library = V2ExerciseLibrary();
      library.clear();

      library.register(_testExercise(id: 'find_me'));
      expect(library.getById('find_me'), isNotNull);
      expect(library.getById('not_found'), isNull);
    });

    test('getByPattern agrupa por padrão', () {
      final library = V2ExerciseLibrary();
      library.clear();

      library.register(_testExercise(id: 's1', pattern: V2MovementPattern.squat));
      library.register(_testExercise(id: 's2', pattern: V2MovementPattern.squat));
      library.register(_testExercise(id: 'p1', pattern: V2MovementPattern.pushHorizontal));

      final squats = library.getByPattern(V2MovementPattern.squat);
      expect(squats.length, 2);
    });

    test('resolver funciona via biblioteca', () {
      final library = V2ExerciseLibrary();
      library.clear();

      library.register(V2Exercise(
        id: 'a',
        name: 'A',
        block: V2ExerciseBlock.home,
        pattern: V2MovementPattern.squat,
        category: V2ExerciseCategory.compound,
        environments: const [V2Environment.home],
        difficulty: V2Difficulty.level1,
        demands: const V2DemandProfile(),
        engineRules: const V2EngineRules(),
        relatedExercises: const [
          V2Relationship(targetId: 'b', type: V2RelationshipType.progression),
        ],
      ));
      library.register(_testExercise(id: 'b'));

      final related = library.getRelated('a', type: V2RelationshipType.progression);
      expect(related.length, 1);
      expect(related.first.id, 'b');
    });
  });
}
