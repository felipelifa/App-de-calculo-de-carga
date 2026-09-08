import 'package:shared_preferences/shared_preferences.dart';
import 'supabase_service.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiService {
  static final ApiService _instance = ApiService._();
  factory ApiService() => _instance;

  static const _tokenKey = 'auth_token';

  final SupabaseService _supabase = SupabaseService();
  String? _cachedToken;

  ApiService._() {
    _loadToken();
  }

  bool get isAuthenticated => _supabase.isAuthenticated;

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _cachedToken = prefs.getString(_tokenKey);
  }

  Future<void> saveToken(String token) async {
    _cachedToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> clearToken() async {
    _cachedToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Future<T> get<T>(String path, {Map<String, String>? queryParams}) async {
    try {
      // Route to appropriate Supabase method based on path
      final result = await _routeGet(path, queryParams);
      return result as T;
    } catch (e) {
      throw ApiException(500, 'Erro ao buscar dados: $e');
    }
  }

  Future<T> post<T>(String path, {dynamic body}) async {
    try {
      final result = await _routePost(path, body);
      return result as T;
    } catch (e) {
      throw ApiException(500, 'Erro ao salvar dados: $e');
    }
  }

  Future<T> put<T>(String path, {dynamic body}) async {
    try {
      final result = await _routePut(path, body);
      return result as T;
    } catch (e) {
      throw ApiException(500, 'Erro ao atualizar dados: $e');
    }
  }

  Future<T> delete<T>(String path) async {
    try {
      await _routeDelete(path);
      return null as T;
    } catch (e) {
      throw ApiException(500, 'Erro ao deletar dados: $e');
    }
  }

  // ── Routing to Supabase ──────────────────────────────────────

  Future<dynamic> _routeGet(String path, Map<String, String>? params) async {
    // Auth
    if (path == '/auth/profile') {
      return await _supabase.getProfile();
    }

    // Users
    if (path == '/users/profile') {
      return await _supabase.getProfile();
    }

    // Prescription
    if (path == '/prescription') {
      final workouts = await _supabase.getGeneratedWorkouts();
      return {'data': workouts};
    }

    // Progression
    if (path == '/progression/state') {
      return await _supabase.getProgressionState();
    }

    // PRs
    if (path == '/pr' || path.startsWith('/pr/')) {
      return await _supabase.getPRs();
    }

    // Workouts
    if (path == '/workouts') {
      return await _supabase.getWorkouts(
        week: int.tryParse(params?['week'] ?? ''),
        limit: int.tryParse(params?['limit'] ?? ''),
      );
    }

    // Exercises
    if (path == '/exercises') {
      final exercises = await _supabase.getExercises();
      return {'data': exercises};
    }

    // Nutrition
    if (path == '/nutrition/profile') {
      return await _supabase.getNutritionProfile();
    }

    if (path == '/nutrition/daily') {
      final date =
          params?['date'] ?? DateTime.now().toIso8601String().substring(0, 10);
      final days = await _supabase.getNutritionDays(
        DateTime.parse(date),
        DateTime.parse(date).add(const Duration(days: 1)),
      );
      return days.isNotEmpty ? days.first : null;
    }

    if (path == '/nutrition/meals') {
      final date =
          params?['date'] ?? DateTime.now().toIso8601String().substring(0, 10);
      final days = await _supabase.getNutritionDays(
        DateTime.parse(date),
        DateTime.parse(date).add(const Duration(days: 1)),
      );
      return days.isNotEmpty ? days.first['meals'] ?? [] : [];
    }

    // Dashboard
    if (path == '/dashboard/summary') {
      final workouts = await _supabase.getWorkouts();
      final profile = await _supabase.getProfile();
      return {'totalWorkouts': workouts.length, 'profile': profile};
    }

    // Analytics
    if (path == '/analytics/summary') {
      final workouts = await _supabase.getWorkouts();
      return {'workouts': workouts};
    }

    throw ApiException(404, 'Rota GET não implementada: $path');
  }

  Future<dynamic> _routePost(String path, dynamic body) async {
    // Auth
    if (path == '/auth/register') {
      final result = await _supabase.signUp(
        body['email'],
        body['password'],
        body['name'],
      );
      return {'user': result.user?.toJson()};
    }

    // Prescription
    if (path == '/prescription') {
      await _supabase.saveGeneratedWorkout(body);
      return {'success': true};
    }

    // Workouts
    if (path == '/workouts') {
      await _supabase.saveWorkout(body);
      return {'success': true};
    }

    // PRs
    if (path == '/prs' || path == '/pr/check') {
      await _supabase.savePR(body);
      return {'success': true};
    }

    // Nutrition
    if (path == '/nutrition/meals') {
      await _supabase.saveMealEntry(body);
      return {'success': true};
    }

    if (path == '/nutrition/log') {
      await _supabase.saveNutritionDay(body);
      return {'success': true};
    }

    throw ApiException(404, 'Rota POST não implementada: $path');
  }

  Future<dynamic> _routePut(String path, dynamic body) async {
    // Users
    if (path == '/users/profile') {
      await _supabase.saveProfile(body);
      return {'success': true};
    }

    // Prescription
    if (path.startsWith('/prescription/') && path.endsWith('/activate')) {
      final id = path.split('/')[2];
      await _supabase.activateGeneratedWorkout(id);
      return {'success': true};
    }

    if (path.startsWith('/prescription/')) {
      final id = path.split('/')[2];
      await _supabase.updateGeneratedWorkout(id, body as Map<String, dynamic>);
      return {'success': true};
    }

    // Progression
    if (path == '/progression/state') {
      await _supabase.saveProgressionState(body);
      return {'success': true};
    }

    // Nutrition
    if (path == '/nutrition/profile') {
      await _supabase.saveNutritionProfile(body);
      return {'success': true};
    }

    // Pro
    if (path == '/pro/status') {
      // Update user pro status
      return {'success': true};
    }

    throw ApiException(404, 'Rota PUT não implementada: $path');
  }

  Future<void> _routeDelete(String path) async {
    if (path.startsWith('/prescription/')) {
      final id = path.split('/')[2];
      await _supabase.deleteGeneratedWorkout(id);
      return;
    }
    throw ApiException(404, 'Rota de exclusão não encontrada: $path');
  }
}
