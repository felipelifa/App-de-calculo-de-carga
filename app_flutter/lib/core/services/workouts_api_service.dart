import 'api_service.dart';
import '../../features/workout/workout_models.dart';

class WorkoutsApiService {
  final ApiService _api;

  WorkoutsApiService({ApiService? api}) : _api = api ?? ApiService();

  Future<Map<String, dynamic>> createWorkout({
    required List<WorkoutExerciseEntry> exercises,
    double? totalVolume,
    int? durationMinutes,
    String? notes,
  }) async {
    final exercisesData = exercises.map((ex) => {
      'exerciseId': ex.exerciseId,
      'exerciseName': ex.exerciseName,
      'muscleGroup': ex.muscleGroup,
      'sets': ex.sets.asMap().entries.map((entry) => {
        'setNumber': entry.key + 1,
        'reps': entry.value.reps,
        'weight': entry.value.weight,
        'isWarmup': entry.value.isWarmup,
      }).toList(),
    }).toList();

    return _api.post('/workouts', body: {
      'exercises': exercisesData,
      'durationMinutes': durationMinutes,
      'notes': notes,
    });
  }

  Future<List<dynamic>> getWorkouts({int? week, int? limit}) async {
    final params = <String, String>{};
    if (week != null) params['week'] = week.toString();
    if (limit != null) params['limit'] = limit.toString();

    return _api.get('/workouts', queryParams: params);
  }

  Future<Map<String, dynamic>> getWeeklyVolume({int? week}) async {
    final params = <String, String>{};
    if (week != null) params['week'] = week.toString();

    return _api.get('/workouts/weekly-volume', queryParams: params);
  }

  Future<List<dynamic>> getMuscleVolume({int? week}) async {
    final params = <String, String>{};
    if (week != null) params['week'] = week.toString();

    return _api.get('/workouts/muscle-volume', queryParams: params);
  }

  Future<void> deleteWorkout(String id) async {
    return _api.delete('/workouts/$id');
  }
}
