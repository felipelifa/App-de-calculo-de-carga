import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'exercise_model.dart';
import '../../core/data/exercise_library.dart';

class ExerciseProvider extends ChangeNotifier {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  ExerciseProvider({FirebaseFirestore? db, FirebaseAuth? auth})
    : _db = db ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance {
    _init();
  }

  List<ExerciseModel> _allExercises = [];
  String? _selectedMuscle;
  String _searchQuery = '';
  bool _isLoading = true;
  String? _error;
  StreamSubscription<QuerySnapshot>? _sub;

  // 🔗 PROXY DE GIFs VIA NEXT.JS API ROUTE (sem CORS issues)
  // Incrementar este timestamp força rebuild no Vercel
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
    // Carrega imediatamente da biblioteca local para não bloquear a UI
    _allExercises = List.from(exerciseLibrary);
    _isLoading = false;
    notifyListeners();

    // Em paralelo, tenta buscar do Firestore global para sobrescrever
    // (útil quando o admin popula exercícios com gifUrl no banco)
    _sub = _db
        .collection('exercises')
        .orderBy('name')
        .snapshots()
        .listen(
          (snap) {
            if (snap.docs.isNotEmpty) {
              // Merge: combina os do Firestore com os da biblioteca local
              // IDs do Firestore têm prioridade (podem ter gifUrl atualizado)
              final fromFirestore = snap.docs
                  .map(ExerciseModel.fromDoc)
                  .toList();
              final firestoreIds = fromFirestore.map((e) => e.id).toSet();
              final localOnly = exerciseLibrary
                  .where((e) => !firestoreIds.contains(e.id))
                  .toList();
              _allExercises = [...fromFirestore, ...localOnly];
            }
            // Se vazio, mantém a biblioteca local já carregada
            _isLoading = false;
            _error = null;
            notifyListeners();
          },
          onError: (e) {
            // Em caso de erro no Firestore, mantém a biblioteca local
            _error = null; // não mostra erro — biblioteca local é suficiente
            _isLoading = false;
            notifyListeners();
          },
        );
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

  /// Retorna exercício por ID — busca na biblioteca completa
  ExerciseModel? getById(String id) {
    if (id.isEmpty) return null;
    try {
      return _allExercises.firstWhere((e) => e.id == id);
    } catch (_) {
      // Fallback direto na biblioteca estática (nunca retorna null para IDs válidos)
      try {
        return exerciseLibrary.firstWhere((e) => e.id == id);
      } catch (_) {
        return null;
      }
    }
  }

  /// Resolve a URL do GIF com base no modelo ou no nome do exercício
  String? getEffectiveGifUrl(ExerciseModel ex) {
    final rawGifUrl = ex.gifUrl?.trim();

    if (rawGifUrl != null && rawGifUrl.isNotEmpty) {
      final parsed = Uri.tryParse(rawGifUrl);
      final isAbsoluteHttp =
          parsed != null &&
          (parsed.scheme == 'http' || parsed.scheme == 'https') &&
          parsed.host.isNotEmpty;

      if (isAbsoluteHttp &&
          !rawGifUrl.contains('firebasestorage') &&
          !rawGifUrl.contains('exercises_gifs')) {
        return rawGifUrl;
      }
    }

    // Sempre usa o proxy do Next.js para evitar CORS no navegador
    // Usa Uri.base.origin para funcionar em qualquer domínio (Vercel, localhost, etc)
    final origin = Uri.base.origin;
    final resolvedName = _extractNameFromGifUrl(rawGifUrl) ?? ex.name;
    final nameParam = Uri.encodeComponent(resolvedName);
    final idParam = Uri.encodeComponent(ex.id);
    final nameEnParam = ex.nameEn != null ? '&nameEn=${Uri.encodeComponent(ex.nameEn!)}' : '';
    return '$origin/api/gif?ts=9&name=$nameParam&id=$idParam$nameEnParam';
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
