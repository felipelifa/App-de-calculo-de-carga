import 'dart:async';
import 'package:flutter/foundation.dart';
import 'exercise_model.dart';
import '../../core/data/exercise_library.dart';
import '../../core/services/api_service.dart';
import '../workout/home_workout/v2_home_source.dart';

class ExerciseProvider extends ChangeNotifier {
  final ApiService _api;

  ExerciseProvider({ApiService? api}) : _api = api ?? ApiService() {
    _init();
  }

  List<ExerciseModel> _allExercises = [];
  List<ExerciseModel> _apiExercises = [];
  final Map<String, ExerciseModel> _customExercises = {};
  String? _selectedMuscle;
  String _searchQuery = '';
  bool _isLoading = true;
  String? _error;
  Timer? _pollTimer;

  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get selectedMuscle => _selectedMuscle;
  String get searchQuery => _searchQuery;
  List<ExerciseModel> get allExercises => _allExercises;

  List<ExerciseModel> get filteredExercises {
    var list = _allExercises;
    if (_selectedMuscle != null && _selectedMuscle!.isNotEmpty) {
      list = list
          .where(
            (e) => e.primaryMuscles.any(
              (m) => m.toLowerCase() == _selectedMuscle!.toLowerCase(),
            ),
          )
          .toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((e) => e.name.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  void _init() {
    _allExercises = List.from(exerciseLibrary);
    _isLoading = false;
    notifyListeners();

    _loadFromApi();

    _pollTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _loadFromApi();
    });
  }

  Future<void> _loadFromApi() async {
    try {
      final result = await _api.get(
        '/exercises',
        queryParams: {'limit': '1000'},
      );

      final data = result['data'] as List<dynamic>?;
      if (data != null && data.isNotEmpty) {
        _apiExercises = data.map((e) => ExerciseModel.fromMap(e)).toList();
        _rebuildExerciseList();
        _isLoading = false;
        _error = null;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('API não disponível, usando dados locais: $e');
    }
  }

  void _rebuildExerciseList() {
    final byId = <String, ExerciseModel>{};
    for (final exercise in exerciseLibrary) {
      byId[exercise.id] = exercise;
    }
    for (final exercise in _apiExercises) {
      final local = byId[exercise.id];
      // Local equipment metadata is the audited source of truth. Remote
      // records may still contain the legacy bodyweight/TRX classification.
      byId[exercise.id] = local == null
          ? exercise.copyWith(equipmentMetadataVerified: false)
          : exercise.copyWith(
              equipment: local.equipment,
              equipmentMetadataVerified: local.equipmentMetadataVerified,
            );
    }
    for (final exercise in _customExercises.values) {
      byId[exercise.id] = exercise;
    }

    // Inclui exercícios V2 Home quando disponíveis
    if (V2HomeSource.isAvailable) {
      final v2HomeExercises = V2HomeSource.getAllHomeAsExerciseModel();
      for (final exercise in v2HomeExercises) {
        byId[exercise.id] = exercise;
      }
    }

    _allExercises = byId.values
        .where((e) => !e.name.trim().endsWith('(1)'))
        .toList();
  }

  Future<void> addExercise({
    required String name,
    required String muscleGroup,
    required String equipment,
    required int seriesDefault,
    required int repMin,
    required int repMax,
  }) async {
    final exercise = ExerciseModel(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      primaryMuscles: [muscleGroup],
      equipment: [equipment],
      repRangeMin: repMin,
      repRangeMax: repMax,
    );

    await _api.post(
      '/exercises',
      body: {
        'id': exercise.id,
        'name': exercise.name,
        'primaryMuscles': exercise.primaryMuscles,
        'secondaryMuscles': exercise.secondaryMuscles,
        'movementPattern': 'isolation',
        'equipment': exercise.equipment,
        'environment': ['gym'],
        'category': 'isolation',
        'difficulty': 'beginner',
        'repRangeMin': exercise.repRangeMin,
        'repRangeMax': exercise.repRangeMax,
      },
    );

    _customExercises[exercise.id] = exercise;
    _rebuildExerciseList();
    notifyListeners();
  }

  void setMuscleFilter(String? muscle) {
    _selectedMuscle = (_selectedMuscle == muscle) ? null : muscle;
    notifyListeners();
  }

  void setSearch(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  ExerciseModel? getById(String id) {
    if (id.isEmpty) return null;

    // 1. Busca na lista interna (V1 + API + custom)
    try {
      return _allExercises.firstWhere((e) => e.id == id);
    } catch (_) {}

    // 2. Busca na biblioteca local V1
    try {
      return exerciseLibrary.firstWhere((e) => e.id == id);
    } catch (_) {}

    // 3. Busca na V2ExerciseLibrary (Home V2)
    final v2Result = V2HomeSource.getById(id);
    if (v2Result != null) return v2Result;

    return null;
  }

  Future<List<VolumeHistoryEntry>> getExerciseHistory(String exerciseId) async {
    try {
      final result = await _api.get(
        '/progression/volume-history',
        queryParams: {'exerciseId': exerciseId},
      );

      final data =
          result['data'] as List<dynamic>? ?? result as List<dynamic>? ?? [];
      return data
          .map((e) => VolumeHistoryEntry.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> refresh() async {
    await _loadFromApi();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}

class VolumeHistoryEntry {
  final int weekNumber;
  final double totalVolume;

  const VolumeHistoryEntry({
    required this.weekNumber,
    required this.totalVolume,
  });

  factory VolumeHistoryEntry.fromMap(Map<String, dynamic> map) {
    return VolumeHistoryEntry(
      weekNumber: (map['weekNumber'] as num?)?.toInt() ?? 0,
      totalVolume: (map['totalVolume'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
