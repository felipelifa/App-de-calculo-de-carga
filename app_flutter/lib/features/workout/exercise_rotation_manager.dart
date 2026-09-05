import 'dart:math';
import '../../features/exercises/exercise_model.dart';
import 'decision_memory.dart';

// ═══════════════════════════════════════════════════════════════
// EXERCISE ROTATION MANAGER
//
// Baseado em:
// - Schoenfeld IUSCA 2021: variar cargas/patterns entre semanas
//   amplifica desenvolvimento muscular
// - Bompa Periodization: exercícios devem mudar conforme fase
//   para evitar platô de adaptação e lesões por repetição
//
// FUNCIONAMENTO:
// - A cada semana, 1-2 exercícios de cada grupo muscular são
//   trocados por equivalentes do mesmo movement pattern
// - Usa substitutesIds do ExerciseModel como "pool seguro"
// - Mantém consistência: mesmo exercício volta no ciclo
// - Não troca exercícios favoritos (aderência)
// - Consulta DecisionMemory para evitar exercícios rejeitados
// ═══════════════════════════════════════════════════════════════

class ExerciseSwapCandidate {
  final String originalId;
  final String swapId;
  final String muscleGroup;
  final int position; // posição na sessão

  const ExerciseSwapCandidate({
    required this.originalId,
    required this.swapId,
    required this.muscleGroup,
    required this.position,
  });
}

class ExerciseRotationManager {
  final List<ExerciseModel> _library;
  DecisionMemory? _decisionMemory;

  // Map: original exercise ID -> pool de alternativas ordenadas
  Map<String, List<String>> _substitutePools = {};

  ExerciseRotationManager(this._library, {DecisionMemory? decisionMemory}) {
    _decisionMemory = decisionMemory;
    _buildSubstitutePools();
  }

  /// Define o DecisionMemory para consultas de histórico.
  void setDecisionMemory(DecisionMemory decisionMemory) {
    _decisionMemory = decisionMemory;
  }

  // Constrói pools de substituição agrupando por pattern + muscle
  // Combina substituteIds declarado + exercícios similares da library
  void _buildSubstitutePools() {
    // 1. Agrupar todos os exercícios por muscle + pattern
    final byGroup = <String, List<ExerciseModel>>{};
    for (final ex in _library) {
      final key = '${ex.primaryMuscles.join(',')}_${ex.movementPattern}';
      byGroup.putIfAbsent(key, () => []).add(ex);
    }

    // 2. Para cada exercício, adicionar seus declared substitutes + group peers
    for (final ex in _library) {
      final pool = <String>{};
      // Declared substitutes
      pool.addAll(ex.substituteIds);

      // Group peers (mesmo muscle + pattern, excluindo o próprio + favoritos)
      final key = '${ex.primaryMuscles.join(',')}_${ex.movementPattern}';
      for (final peer in byGroup[key] ?? []) {
        if (peer.id != ex.id && pool.contains(peer.id)) {
          // Já tem, manter
        } else if (peer.id != ex.id) {
          pool.add(peer.id);
        }
      }
      _substitutePools[ex.id] = pool.toList();
    }
  }

  /// Retorna o exercício alternativo baseado na rotação semanal.
  /// Se a semana atual + offset não indicar troca, retorna o original.
  /// Se indicar, retorna alternativa do pool.
  /// NUNCA troca exercícios favoritos (aderência > variação).
  /// Consulta DecisionMemory para evitar exercícios rejeitados.
  String resolveExercise(
    String originalId, {
    required int weekNumber,
    List<String> favorites = const [],
    List<String> disliked = const [],
    int rotationSeed = 0,
    bool Function(ExerciseModel)? filter,
  }) {
    // Não trocar favoritos
    if (favorites.contains(originalId)) return originalId;

    // Se não tem substitutos disponíveis, manter original
    final pool = _substitutePools[originalId];
    if (pool == null || pool.isEmpty) return originalId;

    // Filtrar disliked e usar o filter opcional (para ambiente/equipamentos)
    var availablePool = pool.where((s) {
      if (disliked.contains(s)) return false;
      if (filter != null) {
        final ex = _library.firstWhere((e) => e.id == s, orElse: () => _library.first);
        if (!filter(ex)) return false;
      }
      return true;
    }).toList();
    
    // Filtrar exercícios evitados recentemente pelo DecisionMemory
    if (_decisionMemory != null) {
      final avoided = _decisionMemory!.getRecentlyAvoidedExercises(sessionsBack: 3);
      availablePool = availablePool.where((s) => !avoided.contains(s)).toList();
    }
    
    if (availablePool.isEmpty) return originalId;

    // A cada 2 semanas, trocar exercício
    // (Schoenfeld: variar entre semanas; Bompa: não mudar toda semana demais)
    final rotationBlock = (weekNumber - 1) ~/ 2;
    final rng = Random(rotationSeed + rotationBlock * 31 + originalId.hashCode);

    // Determinar se esta semana deve trocar:
    // ~50% dos exercícios trocam a cada bloco de 2 semanas
    final shouldSwap = (weekNumber > 1) &&
        ((rotationBlock + originalId.hashCode.abs()) % 3 != 0);

    if (!shouldSwap) return originalId;

    // Escolher alternativa baseada no seed semanal
    final index = rng.nextInt(availablePool.length);
    return availablePool[index];
  }

  /// Retorna quantos exercícios serão trocados na semana atual
  /// (para informar ao usuário antes de gerar o treino)
  int swapCountEstimate(List<ExerciseModel> exercises, int weekNumber) {
    var count = 0;
    for (final ex in exercises) {
      if (resolveExercise(ex.id, weekNumber: weekNumber) != ex.id) {
        count++;
      }
    }
    return count;
  }

  /// Retorna uma nota explicativa sobre a rotação
  String rotationNote(int weekNumber, int swappedCount) {
    if (weekNumber <= 1 || swappedCount == 0) {
      return 'Semana de base — exercícios padrão.';
    }
    if (swappedCount == 1) {
      return '1 exercício variado para estimular ângulos diferentes (Schoenfeld 2021).';
    }
    return '$swappedCount exercícios variados. Rotação para evitar platô de adaptação e lesão por repetição (Bompa 2015).';
  }

  /// Obter a alternativa atual para um exercício específico
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

  /// Retorna os pools disponíveis para debug/UI
  Map<String, List<String>> get substitutePools => _substitutePools;
}
