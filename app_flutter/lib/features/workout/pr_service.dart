import '../../core/services/api_service.dart';
import '../../core/services/notification_service.dart';
import 'workout_models.dart';
import 'pr_model.dart';

// ─────────────────────────────────────────────
// PR Service — lê e salva PRs via API
// ─────────────────────────────────────────────

class PrService {
  final ApiService _api = ApiService();

  PrService();

  /// Carrega todos os PRs do usuário (mapa exerciseId → PR)
  Future<Map<String, PersonalRecord>> loadAll() async {
    try {
      final response = await _api.get('/prs');
      final list = (response as List<dynamic>?) ?? [];
      return {
        for (final item in list)
          (item['exerciseId'] as String? ?? ''): PersonalRecord.fromMap(
            item as Map<String, dynamic>,
          ),
      };
    } catch (_) {
      return {};
    }
  }

  /// Carrega PR de um exercício específico (retorna null se nunca teve)
  Future<PersonalRecord?> loadForExercise(String exerciseId) async {
    try {
      final response = await _api.get('/exercises/$exerciseId/pr');
      if (response == null) return null;
      return PersonalRecord.fromMap(response as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Analisa uma sessão, detecta PRs e os salva via API.
  /// Retorna a lista de [PrAchievement] conquistados.
  Future<List<PrAchievement>> processSession(
    List<WorkoutExerciseEntry> exercises,
  ) async {
    try {
      final exercisesData = exercises.map((e) => {
        'exerciseId': e.exerciseId,
        'exerciseName': e.exerciseName,
        'muscleGroup': e.muscleGroup,
        'sets': e.sets.map((s) => {
          'weight': s.weight,
          'reps': s.reps,
          'volume': s.volume,
        }).toList(),
      }).toList();

      final response = await _api.post('/prs/process-session', body: {
        'exercises': exercisesData,
      });

      final achievementsRaw = (response['achievements'] as List<dynamic>?) ?? [];
      return achievementsRaw.map((a) {
        final am = a as Map<String, dynamic>;
        return PrAchievement(
          exerciseId: am['exerciseId'] as String? ?? '',
          exerciseName: am['exerciseName'] as String? ?? '',
          muscleGroup: am['muscleGroup'] as String? ?? '',
          newMaxWeight: (am['newMaxWeight'] as num?)?.toDouble(),
          prevMaxWeight: (am['prevMaxWeight'] as num?)?.toDouble(),
          newMaxReps: (am['newMaxReps'] as num?)?.toInt(),
          prevMaxReps: (am['prevMaxReps'] as num?)?.toInt(),
          newMaxVolume: (am['newMaxVolume'] as num?)?.toDouble(),
          prevMaxVolume: (am['prevMaxVolume'] as num?)?.toDouble(),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }
}
