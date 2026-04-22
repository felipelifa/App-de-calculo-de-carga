import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/notification_service.dart';
import 'workout_models.dart';
import 'pr_model.dart';

// ─────────────────────────────────────────────
// PR Service — lê e salva PRs no Firestore
// Coleção: users/{uid}/personalRecords/{exerciseId}
// ─────────────────────────────────────────────

class PrService {
  final FirebaseFirestore _db;
  final String _uid;

  PrService({required FirebaseFirestore db, required String uid})
      : _db = db,
        _uid = uid;

  String get _col => 'users/$_uid/personalRecords';

  /// Carrega todos os PRs do usuário (mapa exerciseId → PR)
  Future<Map<String, PersonalRecord>> loadAll() async {
    final snap = await _db.collection(_col).get();
    return {for (final doc in snap.docs) doc.id: PersonalRecord.fromDoc(doc)};
  }

  /// Carrega PR de um exercício específico (retorna null se nunca teve)
  Future<PersonalRecord?> loadForExercise(String exerciseId) async {
    final doc = await _db.collection(_col).doc(exerciseId).get();
    if (!doc.exists) return null;
    return PersonalRecord.fromDoc(doc);
  }

  /// Analisa uma sessão, detecta PRs e os salva no Firestore.
  /// Retorna a lista de [PrAchievement] conquistados.
  Future<List<PrAchievement>> processSession(
    List<WorkoutExerciseEntry> exercises,
  ) async {
    // 1. Carrega PRs existentes de todos os exercícios da sessão
    final ids = exercises.map((e) => e.exerciseId).toSet().toList();
    final existingPrs = <String, PersonalRecord?>{};

    for (final id in ids) {
      if (id.isNotEmpty) {
        existingPrs[id] = await loadForExercise(id);
      }
    }

    // 2. Para cada exercício, calcula os melhores valores da sessão
    final achievements = <PrAchievement>[];
    final batch = _db.batch();

    for (final entry in exercises) {
      if (entry.exerciseId.isEmpty || entry.sets.isEmpty) continue;

      double sessionMaxWeight = 0;
      int sessionMaxReps = 0;
      double sessionMaxVolume = 0;

      for (final set in entry.sets) {
        if (set.weight > sessionMaxWeight) sessionMaxWeight = set.weight;
        if (set.reps > sessionMaxReps) sessionMaxReps = set.reps;
        if (set.volume > sessionMaxVolume) sessionMaxVolume = set.volume;
      }

      final existing = existingPrs[entry.exerciseId];

      if (existing == null) {
        // Primeiro registro — tudo é PR!
        final pr = PersonalRecord(
          exerciseId: entry.exerciseId,
          exerciseName: entry.exerciseName,
          muscleGroup: entry.muscleGroup,
          maxWeight: sessionMaxWeight,
          maxReps: sessionMaxReps,
          maxVolume: sessionMaxVolume,
          updatedAt: DateTime.now(),
        );
        batch.set(
          _db.collection(_col).doc(entry.exerciseId),
          pr.toMap(),
        );
        achievements.add(PrAchievement(
          exerciseId: entry.exerciseId,
          exerciseName: entry.exerciseName,
          muscleGroup: entry.muscleGroup,
          newMaxWeight: sessionMaxWeight,
          prevMaxWeight: null,
          newMaxReps: sessionMaxReps,
          prevMaxReps: null,
          newMaxVolume: sessionMaxVolume,
          prevMaxVolume: null,
        ));
      } else {
        // Compara com PRs anteriores
        final newWeight =
            sessionMaxWeight > existing.maxWeight ? sessionMaxWeight : null;
        final newReps =
            sessionMaxReps > existing.maxReps ? sessionMaxReps : null;
        final newVolume =
            sessionMaxVolume > existing.maxVolume ? sessionMaxVolume : null;

        if (newWeight != null || newReps != null || newVolume != null) {
          final updatedPr = PersonalRecord(
            exerciseId: entry.exerciseId,
            exerciseName: entry.exerciseName,
            muscleGroup: entry.muscleGroup,
            maxWeight: newWeight ?? existing.maxWeight,
            maxReps: newReps ?? existing.maxReps,
            maxVolume: newVolume ?? existing.maxVolume,
            updatedAt: DateTime.now(),
          );
          batch.set(
            _db.collection(_col).doc(entry.exerciseId),
            updatedPr.toMap(),
          );
          achievements.add(PrAchievement(
            exerciseId: entry.exerciseId,
            exerciseName: entry.exerciseName,
            muscleGroup: entry.muscleGroup,
            newMaxWeight: newWeight,
            prevMaxWeight: newWeight != null ? existing.maxWeight : null,
            newMaxReps: newReps,
            prevMaxReps: newReps != null ? existing.maxReps : null,
            newMaxVolume: newVolume,
            prevMaxVolume: newVolume != null ? existing.maxVolume : null,
          ));
        }
      }
    }

    if (achievements.isNotEmpty) {
      await batch.commit();

      // Disparar notificação local para o maior PR da sessão
      final best = achievements.first;
      if (best.newMaxWeight != null) {
        NotificationService.notifyPersonalRecord(
          exerciseName: best.exerciseName,
          recordType: 'Carga máxima',
          value: '${best.newMaxWeight!.toStringAsFixed(1)} kg',
        );
      } else if (best.newMaxReps != null) {
        NotificationService.notifyPersonalRecord(
          exerciseName: best.exerciseName,
          recordType: 'Máximo de reps',
          value: '${best.newMaxReps} reps',
        );
      }
    }

    return achievements;
  }
}
