import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class ChangeHistoryService {
  final ApiService _api;
  static const String _storageKey = 'change_history';

  ChangeHistoryService({ApiService? api})
      : _api = api ?? ApiService();

  Future<void> recordChange({
    required String type,
    required String oldValue,
    required String newValue,
    String? reason,
    String? duration,
  }) async {
    final entry = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'type': type,
      'oldValue': oldValue,
      'newValue': newValue,
      'reason': reason,
      'duration': duration ?? 'permanent',
      'date': DateTime.now().toIso8601String(),
    };

    try {
      await _api.post('/users/history', body: entry);
    } catch (_) {
      // Fallback to local storage
    }

    await _saveLocal(entry);
  }

  Future<List<Map<String, dynamic>>> getHistory({int limit = 50}) async {
    try {
      final result = await _api.get<List<dynamic>>('/users/history', queryParams: {
        'limit': limit.toString(),
      });
      return result.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      return _getLocalHistory(limit: limit);
    }
  }

  Future<List<Map<String, dynamic>>> getHistoryByType(String type) async {
    try {
      final result = await _api.get<List<dynamic>>('/users/history', queryParams: {
        'type': type,
      });
      return result.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      final all = await _getLocalHistory();
      return all.where((e) => e['type'] == type).toList();
    }
  }

  Future<Map<String, dynamic>?> getLastChange(String type) async {
    try {
      final result = await _api.get<List<dynamic>>('/users/history', queryParams: {
        'type': type,
        'limit': '1',
      });
      if (result.isNotEmpty) {
        return Map<String, dynamic>.from(result.first);
      }
      return null;
    } catch (_) {
      final all = await _getLocalHistory();
      final filtered = all.where((e) => e['type'] == type).toList();
      return filtered.isNotEmpty ? filtered.first : null;
    }
  }

  Future<Map<String, dynamic>> getWeeklySummary() async {
    try {
      final result = await _api.get<Map<String, dynamic>>('/users/history/weekly-summary');
      return result;
    } catch (_) {
      final all = await _getLocalHistory();
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekStartDate = DateTime(weekStart.year, weekStart.month, weekStart.day);

      final changes = all.where((c) {
        final date = DateTime.tryParse(c['date'] ?? '');
        return date != null && date.isAfter(weekStartDate);
      }).toList();

      return {
        'totalChanges': changes.length,
        'goalChanges': changes.where((c) => c['type'] == 'goal').length,
        'workoutChanges': changes.where((c) => c['type'] == 'days' || c['type'] == 'duration').length,
        'nutritionChanges': changes.where((c) => c['type'] == 'nutrition').length,
      };
    }
  }

  String translateType(String type) {
    switch (type) {
      case 'goal': return 'Objetivo';
      case 'modality': return 'Modalidade';
      case 'level': return 'Nível';
      case 'days': return 'Dias por semana';
      case 'duration': return 'Duração do treino';
      case 'environment': return 'Ambiente';
      case 'restrictions': return 'Restrições';
      case 'nutrition': return 'Nutrição';
      case 'weight': return 'Peso';
      case 'height': return 'Altura';
      default: return type;
    }
  }

  String translateDuration(String duration) {
    switch (duration) {
      case 'today': return 'Só hoje';
      case 'this_week': return 'Esta semana';
      case 'permanent': return 'Permanentemente';
      default: return duration;
    }
  }

  Future<void> _saveLocal(Map<String, dynamic> entry) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_storageKey) ?? [];
    existing.add(jsonEncode(entry));
    if (existing.length > 200) {
      existing.removeRange(0, existing.length - 200);
    }
    await prefs.setStringList(_storageKey, existing);
  }

  Future<List<Map<String, dynamic>>> _getLocalHistory({int limit = 50}) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_storageKey) ?? [];
    final decoded = existing.map((e) => Map<String, dynamic>.from(jsonDecode(e))).toList();
    decoded.sort((a, b) => (b['date'] ?? '').compareTo(a['date'] ?? ''));
    return decoded.take(limit).toList();
  }
}
