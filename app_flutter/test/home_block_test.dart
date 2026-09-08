import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/exercise_library_v2/enums/environment.dart';
import 'package:app/features/exercise_library_v2/enums/equipment.dart';
import 'package:app/features/exercise_library_v2/enums/exercise_block.dart';
import 'package:app/features/exercise_library_v2/enums/movement_pattern.dart';
import 'package:app/features/exercise_library_v2/enums/difficulty.dart';
import 'package:app/features/exercise_library_v2/enums/exercise_category.dart';
import 'package:app/features/exercise_library_v2/enums/intensity.dart';
import 'package:app/features/exercise_library_v2/models/v2_exercise.dart';
import 'package:app/features/exercise_library_v2/v2_exercise_library.dart';
import 'package:app/features/exercise_library_v2/data/home_exercises.dart';

void main() {
  late List<V2Exercise> exercises;
  late V2ExerciseLibrary library;

  setUpAll(() {
    exercises = createHomeExercises();
    library = V2ExerciseLibrary();
    library.clear();
    library.registerAll(exercises);
  });

  group('Home Block - Integridade Básica', () {
    test('Todos os exercícios pertencem ao bloco Home', () {
      for (final ex in exercises) {
        expect(ex.block, V2ExerciseBlock.home,
          reason: '${ex.id} não pertence ao bloco Home');
      }
    });

    test('Todos os exercícios têm ambiente home', () {
      for (final ex in exercises) {
        expect(ex.environments, contains(V2Environment.home),
          reason: '${ex.id} não tem ambiente home');
      }
    });

    test('Todos os exercícios funcionam sem equipamento', () {
      for (final ex in exercises) {
        expect(ex.requiredEquipment, isEmpty,
          reason: '${ex.id} requer equipamento: ${ex.requiredEquipment}');
      }
    });

    test('Nenhum exercício usa equipamento proibido (TRX, band, dumbbell, etc.)', () {
      final prohibited = {
        V2Equipment.suspension, V2Equipment.band, V2Equipment.dumbbell,
        V2Equipment.barbell, V2Equipment.kettlebell, V2Equipment.cable,
        V2Equipment.machine, V2Equipment.bench, V2Equipment.pullUpBar,
        V2Equipment.smith,
      };
      for (final ex in exercises) {
        for (final eq in ex.requiredEquipment) {
          expect(prohibited, isNot(contains(eq)),
            reason: '${ex.id} usa equipamento proibido: $eq');
        }
      }
    });

    test('Nenhum ID duplicado', () {
      final ids = exercises.map((e) => e.id).toList();
      final uniqueIds = ids.toSet();
      expect(ids.length, uniqueIds.length,
        reason: 'IDs duplicados encontrados');
    });

    test('Todos têm ID, nome, padrão, função, dificuldade', () {
      for (final ex in exercises) {
        expect(ex.id.isNotEmpty, isTrue, reason: '${ex.id} sem ID');
        expect(ex.name.isNotEmpty, isTrue, reason: '${ex.id} sem nome');
        expect(ex.nameEn.isNotEmpty, isTrue, reason: '${ex.id} sem nomeEn');
        expect(ex.primaryFunction.isNotEmpty, isTrue,
          reason: '${ex.id} sem primaryFunction');
      }
    });

    test('Todos têm demandas preenchidas', () {
      for (final ex in exercises) {
        expect(ex.demands, isNotNull, reason: '${ex.id} sem demands');
      }
    });

    test('Todos têm categorias válidas', () {
      for (final ex in exercises) {
        expect(
          [V2ExerciseCategory.compound, V2ExerciseCategory.isolation,
           V2ExerciseCategory.hybrid],
          contains(ex.category),
          reason: '${ex.id} tem categoria inválida: ${ex.category}',
        );
      }
    });

    test('Todos têm dificuldade entre level1 e level5', () {
      for (final ex in exercises) {
        expect(ex.difficulty.index, inInclusiveRange(0, 4),
          reason: '${ex.id} tem dificuldade inválida');
      }
    });
  });

  group('Home Block - Relacionamentos', () {
    test('Nenhum relacionamento aponta para ID inexistente', () {
      final validIds = exercises.map((e) => e.id).toSet();
      for (final ex in exercises) {
        for (final rel in ex.relatedExercises) {
          expect(validIds, contains(rel.targetId),
            reason: '${ex.id} referencia ${rel.targetId} que não existe');
        }
      }
    });

    test('Progressões apontam para exercícios de maior ou igual dificuldade', () {
      final exerciseMap = {for (final e in exercises) e.id: e};
      for (final ex in exercises) {
        for (final rel in ex.relatedExercises) {
          if (rel.type.name == 'progression') {
            final target = exerciseMap[rel.targetId];
            if (target != null) {
              expect(target.difficulty.index, greaterThanOrEqualTo(ex.difficulty.index),
                reason: '${ex.id} progride para ${target.id} mas dificuldade é menor');
            }
          }
        }
      }
    });

    test('Regressões apontam para exercícios de menor ou igual dificuldade', () {
      final exerciseMap = {for (final e in exercises) e.id: e};
      for (final ex in exercises) {
        for (final rel in ex.relatedExercises) {
          if (rel.type.name == 'regression') {
            final target = exerciseMap[rel.targetId];
            if (target != null) {
              expect(target.difficulty.index, lessThanOrEqualTo(ex.difficulty.index),
                reason: '${ex.id} regredde para ${target.id} mas dificuldade é maior');
            }
          }
        }
      }
    });

    test('limitationRules.regressionExerciseIds apontam para IDs existentes', () {
      final validIds = exercises.map((e) => e.id).toSet();
      for (final ex in exercises) {
        if (ex.limitationRules != null) {
          for (final rule in ex.limitationRules!) {
            for (final regId in rule.regressionExerciseIds) {
              expect(validIds, contains(regId),
                reason: '${ex.id} limitationRule referencia $regId que não existe');
            }
          }
        }
      }
    });
  });

  group('Home Block - Padrões de Movimento', () {
    test('Cobertura de padrões principais', () {
      final patterns = exercises.map((e) => e.pattern).toSet();
      expect(patterns, contains(V2MovementPattern.squat));
      expect(patterns, contains(V2MovementPattern.hipHinge));
      expect(patterns, contains(V2MovementPattern.hipExtension));
      expect(patterns, contains(V2MovementPattern.pushHorizontal));
      expect(patterns, contains(V2MovementPattern.coreAntiExtension));
      expect(patterns, contains(V2MovementPattern.coreAntiLateralFlexion));
      expect(patterns, contains(V2MovementPattern.coreAntiRotation));
      expect(patterns, contains(V2MovementPattern.coreFlexion));
      expect(patterns, contains(V2MovementPattern.pushVertical));
      expect(patterns, contains(V2MovementPattern.kneeFlexion));
      expect(patterns, contains(V2MovementPattern.plantarFlexion));
      expect(patterns, contains(V2MovementPattern.hipAbduction));
      expect(patterns, contains(V2MovementPattern.hipAdduction));
      expect(patterns, contains(V2MovementPattern.locomotion));
      expect(patterns, contains(V2MovementPattern.balance));
      expect(patterns, contains(V2MovementPattern.mobility));
      expect(patterns, contains(V2MovementPattern.conditioning));
      expect(patterns, contains(V2MovementPattern.power));
      expect(patterns, contains(V2MovementPattern.isometric));
    });

    test('Exercícios de agachamento existem', () {
      final squats = exercises.where((e) => e.pattern == V2MovementPattern.squat).toList();
      expect(squats.length, greaterThanOrEqualTo(3));
    });

    test('Exercícios de push horizontal existem', () {
      final pushH = exercises.where((e) => e.pattern == V2MovementPattern.pushHorizontal).toList();
      expect(pushH.length, greaterThanOrEqualTo(3));
    });

    test('Exercícios de core existem', () {
      final core = exercises.where((e) =>
        e.pattern == V2MovementPattern.coreAntiExtension ||
        e.pattern == V2MovementPattern.coreAntiRotation ||
        e.pattern == V2MovementPattern.coreAntiLateralFlexion ||
        e.pattern == V2MovementPattern.coreFlexion
      ).toList();
      expect(core.length, greaterThanOrEqualTo(4));
    });
  });

  group('Home Block - Biblioteca', () {
    test('Todos registrados na biblioteca', () {
      expect(library.length, exercises.length);
    });

    test('Busca por padrão funciona', () {
      final squats = library.getByPattern(V2MovementPattern.squat);
      expect(squats.isNotEmpty, isTrue);
      for (final ex in squats) {
        expect(ex.pattern, V2MovementPattern.squat);
      }
    });

    test('Busca por músculo funciona', () {
      final quadExercises = library.getByMuscle('quadriceps');
      expect(quadExercises.isNotEmpty, isTrue);
    });

    test('getById retorna exercício existente', () {
      expect(library.getById('home_squat_001'), isNotNull);
      expect(library.getById('nao_existe'), isNull);
    });

    test('Resolver funciona via biblioteca', () {
      final related = library.getRelated('home_squat_001');
      expect(related.isNotEmpty, isTrue);
    });
  });

  group('Home Block - Dificuldade', () {
    test('Exercícios fáceis (L1) são realmente básicos', () {
      final l1 = exercises.where((e) => e.difficulty == V2Difficulty.level1).toList();
      expect(l1.isNotEmpty, isTrue);
      for (final ex in l1) {
        expect(ex.skillLevel, lessThanOrEqualTo(2),
          reason: '${ex.id} é L1 mas skillLevel é ${ex.skillLevel}');
      }
    });

    test('Exercícios difíceis (L4-L5) têm demandas altas', () {
      final hard = exercises.where((e) =>
        e.difficulty == V2Difficulty.level4 ||
        e.difficulty == V2Difficulty.level5
      ).toList();
      for (final ex in hard) {
        final hasHighDemand = ex.demands.strength.index >= V2Intensity.moderate.index ||
            ex.demands.balance.index >= V2Intensity.moderate.index ||
            ex.demands.stability.index >= V2Intensity.moderate.index;
        expect(hasHighDemand, isTrue,
          reason: '${ex.id} é difícil mas não tem demandas altas');
      }
    });
  });

  group('Home Block - Qualidade dos Dados', () {
    test('Todos têm primaryMuscles não vazio', () {
      for (final ex in exercises) {
        expect(ex.primaryMuscles.isNotEmpty, isTrue,
          reason: '${ex.id} não tem primaryMuscles');
      }
    });

    test('Nenhum músculo usa nome genérico (core, shoulders, full_body)', () {
      final generic = {'core', 'shoulders', 'full_body', 'hip_abductors', 'hip_adductors', 'ankle_stabilizers', 'thoracic_spine'};
      for (final ex in exercises) {
        for (final m in ex.primaryMuscles) {
          expect(generic, isNot(contains(m)),
            reason: '${ex.id} usa músculo genérico: $m');
        }
        for (final m in ex.secondaryMuscles) {
          expect(generic, isNot(contains(m)),
            reason: '${ex.id} usa músculo genérico secundário: $m');
        }
      }
    });

    test('Todos têm joints não vazio', () {
      for (final ex in exercises) {
        expect(ex.joints.isNotEmpty, isTrue,
          reason: '${ex.id} não tem joints');
      }
    });

    test('Todos têm bodyRegions não vazio', () {
      for (final ex in exercises) {
        expect(ex.bodyRegions.isNotEmpty, isTrue,
          reason: '${ex.id} não tem bodyRegions');
      }
    });

    test('Todos têm stimuli não vazio', () {
      for (final ex in exercises) {
        expect(ex.stimuli.isNotEmpty, isTrue,
          reason: '${ex.id} não tem stimuli');
      }
    });

    test('Todos têm goalAffinity não vazio', () {
      for (final ex in exercises) {
        expect(ex.goalAffinity.isNotEmpty, isTrue,
          reason: '${ex.id} não tem goalAffinity');
      }
    });

    test('Todos têm cues não vazio', () {
      for (final ex in exercises) {
        expect(ex.cues.isNotEmpty, isTrue,
          reason: '${ex.id} não tem cues');
      }
    });

    test('Nenhum exercise usa position inválida', () {
      final valid = {'standing', 'prone', 'supine', 'sideLying', 'quadruped', 'sitting', 'hanging'};
      for (final ex in exercises) {
        expect(valid, contains(ex.position),
          reason: '${ex.id} tem position inválida: ${ex.position}');
      }
    });

    test('Todos têm defaultRoles não vazio', () {
      for (final ex in exercises) {
        expect(ex.defaultRoles.isNotEmpty, isTrue,
          reason: '${ex.id} não tem defaultRoles');
      }
    });

    test('Todos têm modalities não vazio', () {
      for (final ex in exercises) {
        expect(ex.modalities.isNotEmpty, isTrue,
          reason: '${ex.id} não tem modalities');
      }
    });
  });
}
