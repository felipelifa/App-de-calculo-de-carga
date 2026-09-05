import 'api_service.dart';

class ProService {
  static final ApiService _api = ApiService();

  static const Set<String> proFeatures = {
    'prescribed_workout',
    'analytics',
    'progression',
    'pr_celebration',
    'workout_history',
    'exercise_rotation',
    'full_dashboard',
    'nutrition',
  };

  static const Set<String> freeFeatures = {
    'basic_workout',
    'anamnese',
    'login',
    'basic_exercises',
    'basic_dashboard',
  };

  static Future<bool> isPro() async {
    if (!_api.isAuthenticated) return false;

    try {
      final result = await _api.get('/pro/status');
      return result['isPro'] == true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> canAccess(String feature) async {
    if (freeFeatures.contains(feature)) return true;
    if (proFeatures.contains(feature)) {
      return isPro();
    }
    return true;
  }

  static List<String> getProFeaturesList() => proFeatures.toList();

  static Stream<bool> isProStream() async* {
    yield await isPro();
  }

  static Future<void> setProStatus(bool isPro) async {
    try {
      await _api.put('/pro/status', body: {'isPro': isPro});
    } catch (_) {
      // Silently fail - callers should use redeemProToken for activation
    }
  }

  static Future<String> redeemProToken(String token) async {
    try {
      final result = await _api.post('/pro/redeem', body: {
        'code': token.toUpperCase().trim(),
      });

      if (result['success'] == true) {
        return 'success';
      }
      return result['message'] ?? 'Erro ao resgatar token';
    } on ApiException catch (e) {
      if (e.statusCode == 404) return 'Token inválido';
      if (e.statusCode == 400) return e.message;
      if (e.statusCode == 403) return 'Acesso negado';
      return 'Erro: ${e.message}';
    } catch (_) {
      return 'Erro de conexão';
    }
  }
}
