import '../../core/services/api_service.dart';

class AnalyticsApiService {
  final ApiService _api;

  AnalyticsApiService({ApiService? api}) : _api = api ?? ApiService();

  Future<Map<String, dynamic>> getDashboard() async {
    return _api.get('/analytics/dashboard');
  }

  Future<List<dynamic>> getWeeklyVolume({int? weeks}) async {
    final params = <String, String>{};
    if (weeks != null) params['weeks'] = weeks.toString();

    return _api.get('/analytics/weekly-volume', queryParams: params);
  }

  Future<List<dynamic>> getMuscleVolume({String? period}) async {
    final params = <String, String>{};
    if (period != null) params['period'] = period;

    return _api.get('/analytics/muscle-volume', queryParams: params);
  }

  Future<List<dynamic>> getExerciseProgress(String exerciseId) async {
    return _api.get('/analytics/exercise-progress', queryParams: {
      'exerciseId': exerciseId,
    });
  }
}
