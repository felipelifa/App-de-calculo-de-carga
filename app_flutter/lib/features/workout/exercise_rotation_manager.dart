import 'dart:math';
import '../../features/exercises/exercise_model.dart';

// ═══════════════════════════════════════════════════════════════
// EXERCISE ROTATION MANAGER
//
// Baseado em:
// - Schoenfeld IUSCA 2021: variar cargas/patterns entre semanas
//   amplifica desenvolvimento muscular
// - Bompa Periodization: exercícios devem mudar conforme fase
//   para evitar plat de adaptao e leses por repetio
//
// FUNCIONAMENTO:
// - A cada semana, 1-2 exerccios de cada grupo muscular so
//   trocados por equivalentes do mesmo movement pattern
// - Usa substitutesIds do ExerciseModel como "pool seguro"
// - Mantm consistncia: mesmo exercise volta no ciclo
// - No troca exerccios favoritos (aderncia)
// ═══════════════════════════════════════════════════════════════

class ExerciseSwapCandidate {
  final String originalId;
  final String swapId;
  final String muscleGroup;
  final int position; // posio na sesso

  const ExerciseSwapCandidate({
    required this.originalId,
    required this.swapId,
    required this.muscleGroup,
    required this.position,
  });
}

class ExerciseRotationManager {
  final List<ExerciseModel> _library;

  // Map: original exercise ID -> pool de alternativas ordenadas
  Map<String, List<String>> _substitutePools = {};

  ExerciseRotationManager(this._library) {
    _buildSubstitutePools();
  }

  // Constri pools de substituio agrupando por pattern + muscle
  // Combina substituteIds declarado + exerccios similares da library
  void _buildSubstitutePools() {
    // 1. Agrupar todos os exerccios por muscle + pattern
    final byGroup = <String, List<ExerciseModel>>{};
    for (final ex in _library) {
      final key = '${ex.primaryMuscles.join(',')}_${ex.movementPattern}';
      byGroup.putIfAbsent(key, () => []).add(ex);
    }

    // 2. Para cada exerccio, adicionar seus declared substitutes + group peers
    for (final ex in _library) {
      final pool = <String>{};
      // Declared substitutes
      pool.addAll(ex.substituteIds);

      // Group peers (mesmo muscle + pattern, excluindo o prprio + favoritos)
      final key = '${ex.primaryMuscles.join(',')}_${ex.movementPattern}';
      for (final peer in byGroup[key] ?? []) {
        if (peer.id != ex.id && pool.contains(peer.id)) {
          // Ja tem, manter
        } else if (peer.id != ex.id) {
          pool.add(peer.id);
        }
      }
      _substitutePools[ex.id] = pool.toList();
    }
  }

  /// Retorna o exerccio alternativo baseado na rotao semanal.
  /// Se a semana atual + offset no indicar troca, retorna o original.
  /// Se indicar, retorna alternativa do pool.
  /// NUNCA troca exerccios favoritos (aderncia > variao).
  String resolveExercise(
    String originalId, {
    required int weekNumber,
    List<String> favorites = const [],
    List<String> disliked = const [],
    int rotationSeed = 0,
  }) {
    // No trocar favoritos
    if (favorites.contains(originalId)) return originalId;

    // Se no tem substitutos disponveis, manter original
    final pool = _substitutePools[originalId];
    if (pool == null || pool.isEmpty) return originalId;

    // Filtrar disliked
    final availablePool = pool.where((s) => !disliked.contains(s)).toList();
    if (availablePool.isEmpty) return originalId;

    // A cada 2 semanas, trocar exerccio
    // (Schoenfeld: variar entre semanas; Bompa: no mudar toda semana demais)
    final rotationBlock = (weekNumber - 1) ~/ 2;
    final rng = Random(rotationSeed + rotationBlock * 31 + originalId.hashCode);

    // Determinar se esta semana deve trocar:
    // ~50% dos exerccios trocam a cada bloco de 2 semanas
    final shouldSwap = (weekNumber > 1) &&
        ((rotationBlock + originalId.hashCode.abs()) % 3 != 0);

    if (!shouldSwap) return originalId;

    // Escolher alternativa baseada no seed semanal
    final index = rng.nextInt(availablePool.length);
    return availablePool[index];
  }

  /// Retorna quantos exerccios sero trocados na semana atual
  /// (para informar ao usurio antes de gerar o treino)
  int swapCountEstimate(List<ExerciseModel> exercises, int weekNumber) {
    var count = 0;
    for (final ex in exercises) {
      if (resolveExercise(ex.id, weekNumber: weekNumber) != ex.id) {
        count++;
      }
    }
    return count;
  }

  /// Retorna uma nota explicativa sobre a rotao
  String rotationNote(int weekNumber, int swappedCount) {
    if (weekNumber <= 1 || swappedCount == 0) {
      return 'Semana de base — exerccios padro.';
    }
    if (swappedCount == 1) {
      return '1 exerccio variado para estimular ngulos diferentes (Schoenfeld 2021).';
    }
    return '$swappedCount exerccios variados. Rota para evitar plat de adaptao e leso por repetio (Bompa 2015).';
  }

  /// Obter a alternativa atual para um exerccio especfico
  ExerciseModel? getSubstitute(
    String exerciseId, {
    required int weekNumber,
    List<String> favorites = const [],
    List<String> disliked = const [],
    int rotationSeed = 0,
  }) {
    final swapId = resolveExercise(
      exerciseId,
      weekNumber: weekNumber,
      favorites: favorites,
      disliked: disliked,
      rotationSeed: rotationSeed,
    );

    if (swapId == exerciseId) return null;

    return _library.firstWhere(
      (e) => e.id == swapId,
      orElse: () => _library.firstWhere((e) => e.id == exerciseId),
    );
  }

  /// Retorna os pools disponveis para debug/UI
  Map<String, List<String>> get substitutePools => _substitutePools;
}
