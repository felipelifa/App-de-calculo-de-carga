import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'exercise_model.dart';
import '../../core/data/exercise_library.dart';
import '../../core/services/api_service.dart';

class ExerciseProvider extends ChangeNotifier {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final ApiService _api;

  ExerciseProvider({FirebaseFirestore? db, FirebaseAuth? auth, ApiService? api})
    : _db = db ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance,
      _api = api ?? ApiService() {
    _init();
  }

  List<ExerciseModel> _allExercises = [];
  String? _selectedMuscle;
  String _searchQuery = '';
  bool _isLoading = true;
  String? _error;
  StreamSubscription<QuerySnapshot>? _sub;

  static const String baseGifUrl =
      'https://app-calculo-carga.vercel.app/api/gif?ts=2';

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
    // Carrega da biblioteca local primeiro
    _allExercises = List.from(exerciseLibrary);
    _isLoading = false;
    notifyListeners();

    // Buscar do backend próprio
    _loadFromApi();

    // Escutar Firestore como fallback
    _sub = _db
        .collection('exercises')
        .orderBy('name')
        .snapshots()
        .listen(
          (snap) {
            if (snap.docs.isNotEmpty) {
              final fromFirestore = snap.docs
                  .map(ExerciseModel.fromDoc)
                  .toList();
              final firestoreIds = fromFirestore.map((e) => e.id).toSet();
              final localOnly = exerciseLibrary
                  .where((e) => !firestoreIds.contains(e.id))
                  .toList();

              var merged = [...fromFirestore, ...localOnly];
              merged = merged.where((e) => !e.name.trim().endsWith('(1)')).toList();

              _allExercises = merged;
            }
            _isLoading = false;
            _error = null;
            notifyListeners();
          },
          onError: (e) {
            _error = null;
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  Future<void> _loadFromApi() async {
    try {
      final result = await _api.get('/exercises', queryParams: {
        'limit': '1000',
      });

      final data = result['data'] as List<dynamic>;
      if (data.isNotEmpty) {
        final exercises = data.map((e) => ExerciseModel.fromMap(e)).toList();
        // Merge: API > local
        final apiIds = exercises.map((e) => e.id).toSet();
        final localOnly = exerciseLibrary
            .where((e) => !apiIds.contains(e.id))
            .toList();
        _allExercises = [...exercises, ...localOnly];
        _isLoading = false;
        _error = null;
        notifyListeners();
      }
    } catch (e) {
      // Manter dados locais se API falhar
      debugPrint('API não disponível, usando dados locais: $e');
    }
  }

  Future<void> addExercise({
    required String name,
    required String muscleGroup,
    required String equipment,
    required int seriesDefault,
    required int repMin,
    required int repMax,
    String? gifUrl,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Usuário não autenticado');

    final exercise = ExerciseModel(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      primaryMuscles: [muscleGroup],
      equipment: [equipment],
      repRangeMin: repMin,
      repRangeMax: repMax,
      gifUrl: gifUrl,
    );

    // Salvar no backend próprio
    try {
      await _api.post('/exercises', body: {
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
      });
    } catch (_) {
      // Fallback para Firestore
    }

    // Salvar no Firestore (legado)
    await _db
        .collection('users/$uid/exercises')
        .doc(exercise.id)
        .set(exercise.toMap());

    _allExercises = [...exerciseLibrary, exercise];
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
    try {
      return _allExercises.firstWhere((e) => e.id == id);
    } catch (_) {
      try {
        return exerciseLibrary.firstWhere((e) => e.id == id);
      } catch (_) {
        return null;
      }
    }
  }

  // URL do proxy GIF no Vercel (funciona em mobile e web)
  static const String _vercelGifProxy = 'https://apptreino-cyan.vercel.app/api/gif';

  String? getEffectiveGifUrl(ExerciseModel ex) {
    final rawGifUrl = ex.gifUrl?.trim();

    if (rawGifUrl != null && rawGifUrl.isNotEmpty) {
      final parsed = Uri.tryParse(rawGifUrl);
      final isAbsoluteHttp =
          parsed != null &&
          (parsed.scheme == 'http' || parsed.scheme == 'https') &&
          parsed.host.isNotEmpty;

      if (isAbsoluteHttp &&
          (rawGifUrl.contains('firebasestorage') ||
           rawGifUrl.contains('exercises_gifs') ||
           rawGifUrl.contains('biblioteca de gif') ||
           rawGifUrl.contains('/gifs/'))) {
        // Usa o proxy
      } else if (isAbsoluteHttp) {
        return rawGifUrl;
      }
    }

    final resolvedName = _extractNameFromGifUrl(rawGifUrl) ?? ex.name;
    final nameParam = Uri.encodeComponent(resolvedName);
    final idParam = Uri.encodeComponent(ex.id);
    final nameEnParam = ex.nameEn != null ? '&nameEn=${Uri.encodeComponent(ex.nameEn!)}' : '';
    return '$_vercelGifProxy?ts=9&name=$nameParam&id=$idParam$nameEnParam';
  }

  String? _extractNameFromGifUrl(String? gifUrl) {
    if (gifUrl == null || gifUrl.isEmpty) return null;

    final withoutQuery = gifUrl.split('?').first;
    final rawSegment = withoutQuery.split('/').last;
    if (rawSegment.isEmpty) return null;

    final decoded = Uri.decodeComponent(rawSegment).trim();
    if (decoded.isEmpty) return null;

    return decoded.replaceAll(RegExp(r'\.gif$', caseSensitive: false), '');
  }

  Future<List<VolumeHistoryEntry>> getExerciseHistory(String exerciseId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return [];

    // Tentar backend próprio
    try {
      final result = await _api.get('/progression/volume-history', queryParams: {
        'exerciseId': exerciseId,
      });

      return (result as List<dynamic>)
          .map((e) => VolumeHistoryEntry.fromMap(e))
          .toList();
    } catch (_) {
      // Fallback para Firestore
    }

    try {
      final snap = await _db
          .collection('users/$uid/exercises/$exerciseId/history')
          .orderBy('weekNumber', descending: true)
          .limit(10)
          .get();
      return snap.docs
          .map((d) => VolumeHistoryEntry.fromMap(d.data()))
          .toList();
    } catch (e) {
      debugPrint('Erro ao obter histórico: $e');
      return [];
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
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
