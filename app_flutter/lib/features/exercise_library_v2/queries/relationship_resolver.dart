import '../enums/relationship_type.dart';
import '../enums/movement_pattern.dart';
import '../models/v2_exercise.dart';

/// Resolve o grafo de relações entre exercícios.
class RelationshipResolver {
  final Map<String, V2Exercise> _index;

  RelationshipResolver(List<V2Exercise> exercises)
      : _index = {for (final ex in exercises) ex.id: ex};

  V2Exercise? getById(String id) => _index[id];

  /// Busca exercícios relacionados, opcionalmente filtrados por tipo.
  List<V2Exercise> getRelated(
    String exerciseId, {
    V2RelationshipType? type,
  }) {
    final exercise = _index[exerciseId];
    if (exercise == null) return [];

    final ids = exercise.relatedExercises
        .where((r) => type == null || r.type == type)
        .map((r) => r.targetId)
        .toList();

    return ids.map((id) => _index[id]).whereType<V2Exercise>().toList();
  }

  /// Encontra o melhor substituto dado um filtro de elegibilidade.
  V2Exercise? findBestSubstitute(
    String exerciseId, {
    required bool Function(V2Exercise) isEligible,
    int maxDepth = 2,
  }) {
    if (maxDepth <= 0) return null;

    final priorities = [
      V2RelationshipType.substitute,
      V2RelationshipType.alternative,
      V2RelationshipType.samePattern,
      V2RelationshipType.sameFunction,
    ];

    for (final type in priorities) {
      final candidates = getRelated(exerciseId, type: type);
      for (final candidate in candidates) {
        if (isEligible(candidate)) return candidate;
        final nested = findBestSubstitute(
          candidate.id,
          isEligible: isEligible,
          maxDepth: maxDepth - 1,
        );
        if (nested != null) return nested;
      }
    }

    return null;
  }

  /// Cadeia de progressão: [original, nível1, nível2, ...]
  List<V2Exercise> getProgressionChain(String exerciseId) {
    final chain = <V2Exercise>[];
    final visited = <String>{};
    String? currentId = exerciseId;

    while (currentId != null && !visited.contains(currentId)) {
      visited.add(currentId);
      final ex = _index[currentId];
      if (ex == null) break;
      chain.add(ex);
      final next = ex.progressionIds;
      currentId = next.isNotEmpty ? next.first : null;
    }

    return chain;
  }

  /// Cadeia de regressão: [original, mais_fácil1, mais_fácil2, ...]
  List<V2Exercise> getRegressionChain(String exerciseId) {
    final chain = <V2Exercise>[];
    final visited = <String>{};
    String? currentId = exerciseId;

    while (currentId != null && !visited.contains(currentId)) {
      visited.add(currentId);
      final ex = _index[currentId];
      if (ex == null) break;
      chain.add(ex);
      final prev = ex.regressionIds;
      currentId = prev.isNotEmpty ? prev.first : null;
    }

    return chain;
  }

  /// Busca exercícios redundantes (não devem aparecer na mesma sessão).
  List<V2Exercise> getRedundants(String exerciseId) {
    return getRelated(exerciseId, type: V2RelationshipType.redundant);
  }

  /// Verifica se dois exercícios conflitariam na mesma sessão.
  bool wouldConflict(String exerciseAId, String exerciseBId) {
    final a = _index[exerciseAId];
    final b = _index[exerciseBId];
    if (a == null || b == null) return false;

    final aRedundants = a.relatedExercises
        .where((r) => r.type == V2RelationshipType.redundant)
        .map((r) => r.targetId)
        .toList();
    if (aRedundants.contains(exerciseBId)) return true;

    if (a.pattern == b.pattern &&
        a.primaryMuscles.toSet().intersection(b.primaryMuscles.toSet()).isNotEmpty) {
      return true;
    }

    return false;
  }

  /// Busca por padrão de movimento.
  List<V2Exercise> getByPattern(V2MovementPattern pattern) {
    return _index.values.where((ex) => ex.pattern == pattern).toList();
  }

  /// Busca por músculo principal.
  List<V2Exercise> getByMuscle(String muscle) {
    return _index.values
        .where((ex) => ex.primaryMuscles.contains(muscle))
        .toList();
  }
}
