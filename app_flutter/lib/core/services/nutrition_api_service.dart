import '../../core/services/api_service.dart';

class NutritionApiService {
  final ApiService _api;

  NutritionApiService({ApiService? api}) : _api = api ?? ApiService();

  Future<Map<String, dynamic>?> getProfile() async {
    try {
      return await _api.get('/nutrition/profile');
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    return _api.put('/nutrition/profile', body: data);
  }

  Future<Map<String, dynamic>?> getDailyLog(String date) async {
    try {
      return await _api.get('/nutrition/daily', queryParams: {'date': date});
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> logMeal({
    required String date,
    required Map<String, dynamic> meal,
  }) async {
    return _api.post('/nutrition/log', body: {
      'date': date,
      'meal': meal,
    });
  }

  Future<void> deleteMeal(String mealId) async {
    return _api.delete('/nutrition/log/$mealId');
  }

  Future<List<dynamic>> getWeeklyLog(String startDate) async {
    return _api.get('/nutrition/weekly', queryParams: {
      'startDate': startDate,
    });
  }
}
