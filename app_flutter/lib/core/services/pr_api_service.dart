import '../../core/services/api_service.dart';

class PrApiService {
  final ApiService _api;

  PrApiService({ApiService? api}) : _api = api ?? ApiService();

  Future<List<dynamic>> getAll() async {
    return _api.get('/pr');
  }

  Future<Map<String, dynamic>?> getForExercise(String exerciseId) async {
    try {
      return await _api.get('/pr/$exerciseId');
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> checkPR({
    required String exerciseId,
    required String exerciseName,
    required String muscleGroup,
    required double weight,
    required int reps,
  }) async {
    return _api.post('/pr/check', body: {
      'exerciseId': exerciseId,
      'exerciseName': exerciseName,
      'muscleGroup': muscleGroup,
      'weight': weight,
      'reps': reps,
    });
  }

  Future<List<dynamic>> getRecent({int? limit}) async {
    final params = <String, String>{};
    if (limit != null) params['limit'] = limit.toString();

    return _api.get('/pr/recent/list', queryParams: params);
  }
}
