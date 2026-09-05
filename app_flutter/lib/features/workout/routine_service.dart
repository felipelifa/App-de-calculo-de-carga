import '../../core/services/api_service.dart';
import 'workout_routine_model.dart';

// ─────────────────────────────────────────────
// Serviço de Rotinas (Templates) — via API
// ─────────────────────────────────────────────

class RoutineService {
  final ApiService _api = ApiService();

  RoutineService();

  /// Carrega todas as rotinas do usuário
  Future<List<WorkoutRoutine>> loadAll() async {
    try {
      final response = await _api.get('/routines');
      final list = (response as List<dynamic>?) ?? [];
      return list.map((item) {
        final map = item as Map<String, dynamic>;
        return WorkoutRoutine.fromMap(map['id'] as String? ?? '', map);
      }).toList();
    } catch (_) {
      return [];
    }
  }

  /// Salva ou cria uma nova rotina
  Future<void> save(WorkoutRoutine routine) async {
    if (routine.id.isEmpty || routine.id == 'new') {
      await _api.post('/routines', body: routine.toMap());
    } else {
      await _api.put('/routines/${routine.id}', body: routine.toMap());
    }
  }

  /// Deleta uma rotina
  Future<void> delete(String routineId) async {
    await _api.delete('/routines/$routineId');
  }
}
