import '../../core/services/api_service.dart';

class PrescriptionApiService {
  final ApiService _api;

  PrescriptionApiService({ApiService? api}) : _api = api ?? ApiService();

  Future<Map<String, dynamic>?> getActiveWorkout() async {
    try {
      return await _api.get('/prescription');
    } catch (_) {
      return null;
    }
  }

  Future<List<dynamic>> getAllWorkouts() async {
    return _api.get('/prescription/all');
  }

  Future<Map<String, dynamic>> saveWorkout(Map<String, dynamic> data) async {
    return _api.post('/prescription', body: data);
  }

  Future<void> activateWorkout(String id) async {
    return _api.put('/prescription/$id/activate');
  }

  Future<void> deleteWorkout(String id) async {
    return _api.delete('/prescription/$id');
  }
}
