import '../../core/services/api_service.dart';

class ProgressionApiService {
  final ApiService _api;

  ProgressionApiService({ApiService? api}) : _api = api ?? ApiService();

  Future<Map<String, dynamic>?> getState() async {
    try {
      return await _api.get('/progression/state');
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> updateState(Map<String, dynamic> data) async {
    return _api.put('/progression/state', body: data);
  }

  Future<List<dynamic>> getSuggestions({String? exerciseId}) async {
    final params = <String, String>{};
    if (exerciseId != null) params['exerciseId'] = exerciseId;

    return _api.get('/progression/suggestions', queryParams: params);
  }

  Future<void> saveSuggestions(List<Map<String, dynamic>> suggestions) async {
    return _api.post('/progression/suggestions', body: {
      'suggestions': suggestions,
    });
  }
}
