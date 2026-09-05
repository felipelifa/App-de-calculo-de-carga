import 'dart:async';
import 'package:flutter/foundation.dart';
import 'athlete_rank.dart';
import '../../core/services/api_service.dart';
import '../../core/services/workouts_api_service.dart';

class AthleteRankProvider extends ChangeNotifier {
  final ApiService _api;
  final WorkoutsApiService _workoutsApi;
  Timer? _pollTimer;

  int _totalXP = 0;
  int _totalSessions = 0;
  double _bestSessionVolume = 0;
  RankResult? _rankResult;
  bool _isLoading = true;

  int get totalXP => _totalXP;
  int get totalSessions => _totalSessions;
  double get bestSessionVolume => _bestSessionVolume;
  RankResult? get rankResult => _rankResult;
  bool get isLoading => _isLoading;

  AthleteRankProvider({ApiService? api, WorkoutsApiService? workoutsApi})
      : _api = api ?? ApiService(),
        _workoutsApi = workoutsApi ?? WorkoutsApiService();

  void startListening() {
    if (!_api.isAuthenticated) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    _fetchXp();

    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _fetchXp();
    });
  }

  Future<void> _fetchXp() async {
    try {
      final result = await _workoutsApi.getWorkouts(limit: 500);
      double totalVolume = 0;
      double bestVolume = 0;

      for (final w in result) {
        final data = w as Map<String, dynamic>;
        final vol = (data['totalVolume'] as num?)?.toDouble() ?? 0;
        totalVolume += vol;
        if (vol > bestVolume) bestVolume = vol;
      }

      _totalXP = totalVolume.toInt();
      _totalSessions = result.length;
      _bestSessionVolume = bestVolume;
      _rankResult = calculateRank(_totalXP);
    } catch (e) {
      debugPrint('Erro ao carregar XP do atleta: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();
    await _fetchXp();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}
