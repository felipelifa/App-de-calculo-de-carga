import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../features/exercises/exercise_provider.dart';
import '../../features/exercises/exercise_model.dart';

// ─────────────────────────────────────────────
// Enum de tipo de sugestão
// ─────────────────────────────────────────────

enum ProgressionType {
  increaseWeight,
  increaseReps,
  decreaseWeight,
  maintain,
  deloadWeek,
}

// ─────────────────────────────────────────────
// Model de sugestão
// ─────────────────────────────────────────────

class ProgressionSuggestion {
  final ExerciseModel exercise;
  final ProgressionType type;
  final String title;
  final String reason;
  final double? suggestedWeight;
  final int? suggestedReps;
  final double? currentWeight;
  final int? currentReps;
  final int consecutiveWeeks;

  const ProgressionSuggestion({
    required this.exercise,
    required this.type,
    required this.title,
    required this.reason,
    this.suggestedWeight,
    this.suggestedReps,
    this.currentWeight,
    this.currentReps,
    this.consecutiveWeeks = 0,
  });
}

// ─────────────────────────────────────────────
// Dados históricos internos
// ─────────────────────────────────────────────

class _SetSummary {
  final int weekNumber;
  final double avgWeight;
  final int avgReps;
  final int setCount;

  const _SetSummary({
    required this.weekNumber,
    required this.avgWeight,
    required this.avgReps,
    required this.setCount,
  });
}

// ─────────────────────────────────────────────
// Serviço principal
// ─────────────────────────────────────────────

class ProgressionService {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  ProgressionService({FirebaseFirestore? db, FirebaseAuth? auth})
      : _db = db ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Gera sugestões de progressão para uma lista de exercícios
  Future<List<ProgressionSuggestion>> generateSuggestions(
    List<ExerciseModel> exercises,
  ) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || exercises.isEmpty) return [];

    final workoutsSnap = await _db
        .collection('users/$uid/workouts')
        .orderBy('date', descending: true)
        .limit(20)
        .get();

    final Map<String, List<_SetSummary>> historyMap = {};

    for (final doc in workoutsSnap.docs) {
      final d = doc.data();
      final week = (d['weekNumber'] as num?)?.toInt() ?? 0;
      final rawExercises = (d['exercises'] as List<dynamic>?) ?? [];

      for (final ex in rawExercises) {
        final em = ex as Map<String, dynamic>;
        final exId = em['exerciseId'] as String? ?? '';
        if (exId.isEmpty) continue;

        final rawSets = (em['sets'] as List<dynamic>?) ?? [];
        if (rawSets.isEmpty) continue;

        double totalWeight = 0;
        int totalReps = 0;
        for (final s in rawSets) {
          final sm = s as Map<String, dynamic>;
          totalWeight += (sm['weight'] as num?)?.toDouble() ?? 0;
          totalReps += (sm['reps'] as num?)?.toInt() ?? 0;
        }

        final summary = _SetSummary(
          weekNumber: week,
          avgWeight: totalWeight / rawSets.length,
          avgReps: (totalReps / rawSets.length).round(),
          setCount: rawSets.length,
        );

        historyMap.putIfAbsent(exId, () => []).add(summary);
      }
    }

    final suggestions = <ProgressionSuggestion>[];

    for (final ex in exercises) {
      final history = historyMap[ex.id];
      if (history == null || history.isEmpty) continue;

      history.sort((a, b) => b.weekNumber.compareTo(a.weekNumber));

      final suggestion = _analyze(ex, history);
      if (suggestion != null) suggestions.add(suggestion);
    }

    suggestions.sort((a, b) {
      const order = {
        ProgressionType.increaseWeight: 0,
        ProgressionType.increaseReps: 1,
        ProgressionType.maintain: 2,
        ProgressionType.deloadWeek: 3,
        ProgressionType.decreaseWeight: 4,
      };
      return (order[a.type] ?? 5).compareTo(order[b.type] ?? 5);
    });

    return suggestions;
  }

  ProgressionSuggestion? _analyze(
    ExerciseModel ex,
    List<_SetSummary> history,
  ) {
    if (history.isEmpty) return null;

    final latest = history.first;
    final currentWeight = latest.avgWeight;
    final currentReps = latest.avgReps;

    if (history.length < 2) {
      return ProgressionSuggestion(
        exercise: ex,
        type: ProgressionType.maintain,
        title: 'Mantenha o ritmo',
        reason:
            'Apenas uma sessão registrada. Complete mais treinos para sugestões personalizadas.',
        currentWeight: currentWeight,
        currentReps: currentReps,
        consecutiveWeeks: 1,
      );
    }

    int stagnantWeeks = 0;
    final refWeight = history.first.avgWeight;
    for (final h in history) {
      final diff = (h.avgWeight - refWeight).abs();
      if (diff < 1.0) {
        stagnantWeeks++;
      } else {
        break;
      }
    }

    final repsAtCeiling = currentReps >= ex.repRangeMax;

    if (stagnantWeeks >= 4 && history.length >= 4) {
      final deloadWeight = (currentWeight * 0.85).roundToDouble();
      return ProgressionSuggestion(
        exercise: ex,
        type: ProgressionType.deloadWeek,
        title: 'Semana de Deload',
        reason:
            '$stagnantWeeks semanas sem progressão. Reduza a carga para recuperação ativa e quebre o platô.',
        currentWeight: currentWeight,
        suggestedWeight: deloadWeight,
        currentReps: currentReps,
        consecutiveWeeks: stagnantWeeks,
      );
    }

    if (repsAtCeiling && stagnantWeeks >= 2) {
      final increment = currentWeight < 20
          ? 1.0
          : currentWeight <= 60
              ? 2.5
              : 5.0;
      final suggestedWeight = currentWeight + increment;
      final suggestedReps = ex.repRangeMin;

      return ProgressionSuggestion(
        exercise: ex,
        type: ProgressionType.increaseWeight,
        title: 'Aumente a carga',
        reason:
            'Você está completando $currentReps reps (máx: ${ex.repRangeMax}) há $stagnantWeeks semanas. Hora de progredir!',
        currentWeight: currentWeight,
        suggestedWeight: suggestedWeight,
        currentReps: currentReps,
        suggestedReps: suggestedReps,
        consecutiveWeeks: stagnantWeeks,
      );
    }

    if (stagnantWeeks >= 2 && !repsAtCeiling) {
      final suggestedReps = (currentReps + 1).clamp(ex.repRangeMin, ex.repRangeMax);
      return ProgressionSuggestion(
        exercise: ex,
        type: ProgressionType.increaseReps,
        title: 'Aumente as repetições',
        reason:
            'Carga estável há $stagnantWeeks semanas. Tente mais 1 rep por série até atingir ${ex.repRangeMax} reps.',
        currentWeight: currentWeight,
        currentReps: currentReps,
        suggestedReps: suggestedReps,
        consecutiveWeeks: stagnantWeeks,
      );
    }

    final prevWeight =
        history.length > 1 ? history[1].avgWeight : currentWeight;
    final gainedWeight = currentWeight - prevWeight;

    if (gainedWeight > 0.5) {
      return ProgressionSuggestion(
        exercise: ex,
        type: ProgressionType.maintain,
        title: 'Progressão em andamento',
        reason:
            '+${gainedWeight.toStringAsFixed(1)} kg desde a última sessão. Continue no mesmo ritmo!',
        currentWeight: currentWeight,
        currentReps: currentReps,
        consecutiveWeeks: stagnantWeeks,
      );
    }

    return ProgressionSuggestion(
      exercise: ex,
      type: ProgressionType.maintain,
      title: 'Mantenha o ritmo',
      reason:
          'Evolução constante detectada. Continue registrando para sugestões mais precisas.',
      currentWeight: currentWeight,
      currentReps: currentReps,
      consecutiveWeeks: stagnantWeeks,
    );
  }
}
