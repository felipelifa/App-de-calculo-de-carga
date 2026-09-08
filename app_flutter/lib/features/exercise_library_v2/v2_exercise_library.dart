import 'enums/movement_pattern.dart';
import 'enums/environment.dart';
import 'enums/equipment.dart';
import 'enums/difficulty.dart';
import 'enums/exercise_category.dart';
import 'enums/exercise_block.dart';
import 'enums/relationship_type.dart';
import 'models/v2_exercise.dart';
import 'queries/exercise_query.dart';
import 'queries/relationship_resolver.dart';
import 'queries/compatibility_evaluator.dart';

/// Índice central da biblioteca V2.
/// Ponto de acesso único para consultas, filtros e relações.
class V2ExerciseLibrary {
  static final V2ExerciseLibrary _instance = V2ExerciseLibrary._();
  factory V2ExerciseLibrary() => _instance;
  V2ExerciseLibrary._();

  final List<V2Exercise> _exercises = [];
  RelationshipResolver? _resolver;

  // ── Exposição ──

  List<V2Exercise> get all => List.unmodifiable(_exercises);
  int get length => _exercises.length;
  bool get isEmpty => _exercises.isEmpty;
  bool get isNotEmpty => _exercises.isNotEmpty;

  // ── Cadastro ──

  /// Registra um exercício na biblioteca.
  void register(V2Exercise exercise) {
    _exercises.add(exercise);
    _resolver = null;
  }

  /// Registra múltiplos exercícios.
  void registerAll(List<V2Exercise> exercises) {
    _exercises.addAll(exercises);
    _resolver = null;
  }

  /// Limpa todos os exercícios.
  void clear() {
    _exercises.clear();
    _resolver = null;
  }

  // ── Acesso direto ──

  V2Exercise? getById(String id) {
    try {
      return _exercises.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  List<V2Exercise> getByIds(List<String> ids) {
    return ids.map((id) => getById(id)).whereType<V2Exercise>().toList();
  }

  // ── Consulta declarativa ──

  List<V2Exercise> query(ExerciseQuery filter) {
    var result = List<V2Exercise>.from(_exercises);

    if (filter.blocks != null) {
      result = result.where((e) => filter.blocks!.contains(e.block)).toList();
    }
    if (filter.patterns != null) {
      result = result.where((e) => filter.patterns!.contains(e.pattern)).toList();
    }
    if (filter.primaryMuscles != null) {
      result = result.where((e) =>
        e.primaryMuscles.any((m) => filter.primaryMuscles!.contains(m))
      ).toList();
    }
    if (filter.secondaryMuscles != null) {
      result = result.where((e) =>
        e.secondaryMuscles.any((m) => filter.secondaryMuscles!.contains(m))
      ).toList();
    }
    if (filter.bodyRegions != null) {
      result = result.where((e) =>
        e.bodyRegions.any((r) => filter.bodyRegions!.contains(r))
      ).toList();
    }
    if (filter.avoidsJoints != null) {
      result = result.where((e) =>
        !e.joints.any((j) => filter.avoidsJoints!.contains(j))
      ).toList();
    }
    if (filter.availableEquipment != null) {
      final equipSet = filter.availableEquipment!.toSet();
      result = result.where((e) =>
        e.requiredEquipment.isEmpty || e.requiredEquipment.every(equipSet.contains)
      ).toList();
    }
    if (filter.environments != null) {
      result = result.where((e) =>
        e.environments.any((env) => filter.environments!.contains(env))
      ).toList();
    }
    if (filter.modalities != null) {
      result = result.where((e) =>
        e.modalities.any((m) => filter.modalities!.contains(m))
      ).toList();
    }
    if (filter.maxDifficulty != null) {
      result = result.where((e) =>
        e.difficulty.index <= filter.maxDifficulty!.index
      ).toList();
    }
    if (filter.minDifficulty != null) {
      result = result.where((e) =>
        e.difficulty.index >= filter.minDifficulty!.index
      ).toList();
    }
    if (filter.roles != null) {
      result = result.where((e) =>
        e.defaultRoles.any((r) => filter.roles!.contains(r))
      ).toList();
    }
    if (filter.requireCompound == true) {
      result = result.where((e) =>
        e.category == V2ExerciseCategory.compound
      ).toList();
    }
    if (filter.requireUnilateral == true) {
      result = result.where((e) =>
        e.engineRules.isUnilateral
      ).toList();
    }
    if (filter.maxStrengthDemand != null) {
      result = result.where((e) =>
        e.demands.strength.index <= filter.maxStrengthDemand!.index
      ).toList();
    }
    if (filter.excludeIds != null) {
      final excludeSet = filter.excludeIds!.toSet();
      result = result.where((e) => !excludeSet.contains(e.id)).toList();
    }
    if (filter.includeOnlyIds != null) {
      final includeSet = filter.includeOnlyIds!.toSet();
      result = result.where((e) => includeSet.contains(e.id)).toList();
    }
    if (filter.textSearch != null && filter.textSearch!.isNotEmpty) {
      final search = filter.textSearch!.toLowerCase();
      result = result.where((e) =>
        e.name.toLowerCase().contains(search) ||
        e.nameEn.toLowerCase().contains(search) ||
        e.aliases.any((a) => a.toLowerCase().contains(search))
      ).toList();
    }

    return result;
  }

  // ── Busca por padrão ──

  List<V2Exercise> getByPattern(V2MovementPattern pattern) {
    return _exercises.where((e) => e.pattern == pattern).toList();
  }

  List<V2Exercise> getByMuscle(String muscle) {
    return _exercises
        .where((e) => e.primaryMuscles.contains(muscle))
        .toList();
  }

  List<V2Exercise> getByBlock(V2ExerciseBlock block) {
    return _exercises.where((e) => e.block == block).toList();
  }

  // ── Relações ──

  RelationshipResolver get resolver {
    _resolver ??= RelationshipResolver(_exercises);
    return _resolver!;
  }

  List<V2Exercise> getRelated(
    String exerciseId, {
    V2RelationshipType? type,
  }) {
    return resolver.getRelated(exerciseId, type: type);
  }

  List<V2Exercise> getProgressionChain(String exerciseId) {
    return resolver.getProgressionChain(exerciseId);
  }

  List<V2Exercise> getRegressionChain(String exerciseId) {
    return resolver.getRegressionChain(exerciseId);
  }

  V2Exercise? findBestSubstitute(
    String exerciseId, {
    required bool Function(V2Exercise) isEligible,
  }) {
    return resolver.findBestSubstitute(exerciseId, isEligible: isEligible);
  }

  // ── Compatibilidade ──

  List<V2Exercise> filterEligible({
    required List<V2Environment> userEnvironments,
    required List<V2Equipment> userEquipment,
    required V2Difficulty userDifficulty,
    required List<UserLimitationInput> userLimitations,
    List<String> dislikedExerciseIds = const [],
  }) {
    return V2CompatibilityEvaluator.filterEligible(
      exercises: _exercises,
      userEnvironments: userEnvironments,
      userEquipment: userEquipment,
      userDifficulty: userDifficulty,
      userLimitations: userLimitations,
      dislikedExerciseIds: dislikedExerciseIds,
    );
  }
}
