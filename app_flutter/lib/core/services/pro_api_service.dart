import '../../core/services/api_service.dart';

class ProApiService {
  final ApiService _api;

  ProApiService({ApiService? api}) : _api = api ?? ApiService();

  Future<Map<String, dynamic>> getStatus() async {
    return _api.get('/pro/status');
  }

  Future<Map<String, dynamic>> redeemToken(String code) async {
    return _api.post('/pro/redeem', body: {'code': code});
  }
}
