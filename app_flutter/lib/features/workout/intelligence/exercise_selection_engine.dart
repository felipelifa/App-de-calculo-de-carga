import '../../exercise_library_v2/models/v2_exercise.dart';
import '../../exercise_library_v2/queries/compatibility_evaluator.dart';
import '../../exercise_library_v2/queries/relationship_resolver.dart';
import '../../exercise_library_v2/enums/exercise_role.dart';
import '../../exercise_library_v2/enums/intensity.dart';
import '../../exercise_library_v2/enums/environment.dart';
import '../../exercise_library_v2/enums/compatibility.dart';
import 'training_context.dart';
import 'training_strategy_engine.dart';
import 'session_blueprint.dart';

/// Resultado da seleção de um exercício.
class SelectedExercise {
  final V2Exercise exercise;
  final V2ExerciseRole role;
  final List<String> reasons;
  final double score;

  const SelectedExercise({
    required this.exercise,
    required this.role,
    required this.reasons,
    required this.score,
  });
}

/// Motor de seleção de exercícios.
/// Consulta V2ExerciseLibrary e aplica filtros + ranking.
class ExerciseSelectionEngine {
  final List<V2Exercise> _allExercises;
  final RelationshipResolver _resolver;

  ExerciseSelectionEngine(this._allExercises)
      : _resolver = RelationshipResolver(_allExercises);

  /// Seleciona exercícios para um blueprint.
  List<SelectedExercise> select({
    required SessionBlueprint blueprint,
    required TrainingContext context,
    required TrainingStrategy strategy,
    List<String> recentExerciseIds = const [],
  }) {
    final selected = <SelectedExercise>[];
    final usedIds = <String>{};

    for (final slot in blueprint.slots) {
      final result = _selectForSlot(
        slot: slot,
        context: context,
        strategy: strategy,
        usedIds: usedIds,
        recentIds: recentExerciseIds,
      );

      if (result != null) {
        selected.add(result);
        usedIds.add(result.exercise.id);
      }
    }

    return selected;
  }

  /// Seleciona o melhor exercício para um slot específico.
  SelectedExercise? _selectForSlot({
    required BlueprintSlot slot,
    required TrainingContext context,
    required TrainingStrategy strategy,
    required Set<String> usedIds,
    required List<String> recentIds,
  }) {
    // 1. Filtrar por compatibilidade (hard filters)
    var candidates = _hardFilter(_allExercises, context);

    // 2. Filtrar por padrão aceitável
    candidates = _filterByPattern(candidates, slot);

    // 3. Filtrar por uso recente (evitar repetição)
    candidates = candidates.where((ex) => !usedIds.contains(ex.id)).toList();

    if (candidates.isEmpty) return null;

    // 4. Ranquear candidatos
    final scored = candidates.map((ex) {
      final score = _scoreExercise(ex, slot, context, strategy, recentIds);
      return _ScoredExercise(exercise: ex, score: score.score, reasons: score.reasons);
    }).toList();

    scored.sort((a, b) => b.score.compareTo(a.score));

    if (scored.isEmpty) return null;

    final best = scored.first;
    return SelectedExercise(
      exercise: best.exercise,
      role: slot.role,
      reasons: best.reasons,
      score: best.score,
    );
  }

  /// Hard filters: elimina exercícios incompatíveis.
  List<V2Exercise> _hardFilter(List<V2Exercise> exercises, TrainingContext context) {
    return exercises.where((ex) {
      // Ambiente
      if (!ex.environments.contains(context.environment) &&
          !ex.environments.contains(V2Environment.any)) {
        return false;
      }

      // Equipamento
      if (ex.requiredEquipment.isNotEmpty) {
        final userSet = context.availableEquipment.toSet();
        if (!ex.requiredEquipment.every(userSet.contains)) {
          return false;
        }
      }

      // Limite de dificuldade (muito além do nível)
      if (ex.difficulty.index > context.userDifficulty.index + 2) {
        return false;
      }

      // Disliked
      if (context.dislikedExerciseIds.contains(ex.id)) {
        return false;
      }

      // Safety alerts
      if (context.safetyAlerts.isNotEmpty) {
        // Se há alertas de segurança, eliminar exercícios com alto impacto
        if (ex.demands.impact.index >= V2Intensity.high.index) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  /// Filtra por padrão de movimento aceitável.
  List<V2Exercise> _filterByPattern(List<V2Exercise> exercises, BlueprintSlot slot) {
    if (slot.preferredPattern == null) return exercises;

    // Primeiro: tentar preferred pattern
    final preferred = exercises
        .where((ex) => ex.pattern == slot.preferredPattern)
        .toList();
    if (preferred.isNotEmpty) return preferred;

    // Depois: acceptable patterns
    if (slot.acceptablePatterns.isNotEmpty) {
      final acceptable = exercises
          .where((ex) => slot.acceptablePatterns.contains(ex.pattern))
          .toList();
      if (acceptable.isNotEmpty) return acceptable;
    }

    // Fallback: retornar todos
    return exercises;
  }

  /// Pontua um exercício para um slot.
  _ScoreResult _scoreExercise(
    V2Exercise exercise,
    BlueprintSlot slot,
    TrainingContext context,
    TrainingStrategy strategy,
    List<String> recentIds,
  ) {
    double score = 0.0;
    final reasons = <String>[];

    // ── Goal alignment (0-30 pontos) ──
    final goalScore = _goalAlignmentScore(exercise, strategy);
    score += goalScore;
    if (goalScore > 20) reasons.add('strongGoalAlignment');

    // ── Pattern match (0-25 pontos) ──
    if (exercise.pattern == slot.preferredPattern) {
      score += 25;
      reasons.add('fulfillsPrimaryPattern');
    } else if (slot.acceptablePatterns.contains(exercise.pattern)) {
      score += 15;
      reasons.add('fulfillsSecondaryPattern');
    }

    // ── Level compatibility (0-20 pontos) ──
    final levelDiff = (exercise.difficulty.index - context.userDifficulty.index).abs();
    score += (20 - levelDiff * 7).clamp(0, 20);
    if (levelDiff <= 1) reasons.add('compatibleWithLevel');

    // ── Goal affinity (0-15 pontos) ──
    final affinity = exercise.goalAffinity[context.primaryGoal];
    if (affinity != null) {
      score += affinity.index * 4;
      if (affinity.index >= V2Intensity.moderate.index) {
        reasons.add('matchesTrainingGoal');
      }
    }

    // ── Equipment available (0-5 pontos) ──
    if (exercise.requiredEquipment.isEmpty) {
      score += 5;
      reasons.add('noEquipmentRequired');
    } else {
      reasons.add('equipmentAvailable');
    }

    // ── Recent use penalty (-10 pontos) ──
    if (recentIds.contains(exercise.id)) {
      score -= 10;
      reasons.add('recentlyUsed');
    }

    // ── Preferred bonus (0-10 pontos) ──
    if (context.preferredExerciseIds.contains(exercise.id)) {
      score += 10;
      reasons.add('userPreferred');
    }

    // ── Limitation compatibility (0-10 pontos) ──
    if (context.hasLimitations) {
      final compat = V2CompatibilityEvaluator.evaluate(
        exercise: exercise,
        userEnvironments: [context.environment],
        userEquipment: context.availableEquipment,
        userDifficulty: context.userDifficulty,
        userLimitations: context.limitations
            .map((l) => UserLimitationInput(
                  joint: l.joint,
                  severity: l.severity,
                  symptoms: l.affectedMovements,
                ))
            .toList(),
        dislikedExerciseIds: context.dislikedExerciseIds,
      );
      if (compat.isEligible) {
        score += 10;
        reasons.add('limitationCompatible');
      } else if (compat.status == V2Compatibility.adaptable) {
        score += 5;
        reasons.add('limitationAdaptable');
      }
    } else {
      score += 10;
      reasons.add('noLimitations');
    }

    return _ScoreResult(score: score, reasons: reasons);
  }

  /// Score de alinhamento com o objetivo.
  double _goalAlignmentScore(V2Exercise exercise, TrainingStrategy strategy) {
    double score = 0;

    for (final entry in strategy.goalPriority.weights.entries) {
      final affinity = exercise.goalAffinity[entry.key];
      if (affinity != null) {
        score += affinity.index * entry.value * 5;
      }
    }

    return score.clamp(0, 30);
  }

  /// Encontra melhor substituto para um exercício.
  V2Exercise? findSubstitute(
    String exerciseId,
    List<V2Exercise> available,
  ) {
    final availableIds = available.map((e) => e.id).toSet();
    return _resolver.findBestSubstitute(
      exerciseId,
      isEligible: (ex) => availableIds.contains(ex.id),
    );
  }

  /// Verifica redundância entre dois exercícios.
  bool wouldConflict(V2Exercise a, V2Exercise b) {
    return _resolver.wouldConflict(a.id, b.id);
  }
}

class _ScoredExercise {
  final V2Exercise exercise;
  final double score;
  final List<String> reasons;

  const _ScoredExercise({
    required this.exercise,
    required this.score,
    required this.reasons,
  });
}

class _ScoreResult {
  final double score;
  final List<String> reasons;

  const _ScoreResult({required this.score, required this.reasons});
}
