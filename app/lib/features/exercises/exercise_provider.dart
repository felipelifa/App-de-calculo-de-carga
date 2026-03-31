import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

// ─────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────

class ExerciseModel {
  final String id;
  final String name;
  final String muscleGroup;
  final String equipment;
  final int seriesDefault;
  final int repMin;
  final int repMax;
  final String? gifUrl;

  const ExerciseModel({
    required this.id,
    required this.name,
    required this.muscleGroup,
    required this.equipment,
    required this.seriesDefault,
    required this.repMin,
    required this.repMax,
    this.gifUrl,
  });

  factory ExerciseModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ExerciseModel(
      id: doc.id,
      name: d['name'] as String? ?? '',
      muscleGroup: d['muscleGroup'] as String? ?? '',
      equipment: d['equipment'] as String? ?? '',
      seriesDefault: (d['seriesDefault'] as num?)?.toInt() ?? 3,
      repMin: (d['repMin'] as num?)?.toInt() ?? 8,
      repMax: (d['repMax'] as num?)?.toInt() ?? 12,
      gifUrl: d['gifUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'muscleGroup': muscleGroup,
        'equipment': equipment,
        'seriesDefault': seriesDefault,
        'repMin': repMin,
        'repMax': repMax,
        if (gifUrl != null && gifUrl!.isNotEmpty) 'gifUrl': gifUrl,
      };
}

class VolumeHistoryEntry {
  final String exerciseId;
  final int weekNumber;
  final double totalVolume;

  const VolumeHistoryEntry({
    required this.exerciseId,
    required this.weekNumber,
    required this.totalVolume,
  });

  factory VolumeHistoryEntry.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return VolumeHistoryEntry(
      exerciseId: d['exerciseId'] as String? ?? '',
      weekNumber: (d['weekNumber'] as num?)?.toInt() ?? 0,
      totalVolume: (d['totalVolume'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

// ─────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────

class ExerciseProvider extends ChangeNotifier {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  ExerciseProvider({FirebaseFirestore? db, FirebaseAuth? auth})
      : _db = db ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance {
    _init();
  }

  // ── State ─────────────────────────────────
  List<ExerciseModel> _allExercises = [];
  String? _selectedMuscle;
  String _searchQuery = '';
  bool _isLoading = true;
  String? _error;

  StreamSubscription<QuerySnapshot>? _sub;

  // ── Getters ───────────────────────────────
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get selectedMuscle => _selectedMuscle;
  String get searchQuery => _searchQuery;

  List<ExerciseModel> get filteredExercises {
    var list = _allExercises;
    if (_selectedMuscle != null && _selectedMuscle!.isNotEmpty) {
      list = list
          .where((e) =>
              e.muscleGroup.toLowerCase() == _selectedMuscle!.toLowerCase())
          .toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((e) => e.name.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  // ── Init ──────────────────────────────────
  void _init() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    _sub = _db
        .collection('users/$uid/exercises')
        .orderBy('name')
        .snapshots()
        .listen(
      (snap) {
        _allExercises = snap.docs.map(ExerciseModel.fromDoc).toList();
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (e) {
        _error = 'Erro ao carregar exercícios: $e';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // ── Filters ───────────────────────────────
  void setMuscleFilter(String? muscle) {
    _selectedMuscle = (_selectedMuscle == muscle) ? null : muscle;
    notifyListeners();
  }

  void setSearch(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // ── Firestore writes ──────────────────────
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

    final model = ExerciseModel(
      id: '',
      name: name.trim(),
      muscleGroup: muscleGroup,
      equipment: equipment,
      seriesDefault: seriesDefault,
      repMin: repMin,
      repMax: repMax,
      gifUrl: gifUrl?.trim().isEmpty == true ? null : gifUrl?.trim(),
    );

    await _db.collection('users/$uid/exercises').add({
      ...model.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateExercise(
    String exId,
    Map<String, dynamic> fields,
  ) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Usuário não autenticado');
    await _db.doc('users/$uid/exercises/$exId').update(fields);
  }

  /// Returns the last 3 volume history entries for [exId], using the
  /// composite index on volumeHistory (exerciseId ASC, weekNumber ASC).
  /// This is O(log n) — no subcollection scanning.
  Future<List<VolumeHistoryEntry>> getExerciseHistory(String exId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return [];

    final snap = await _db
        .collection('users/$uid/volumeHistory')
        .where('exerciseId', isEqualTo: exId)
        .orderBy('weekNumber', descending: true)
        .limit(3)
        .get();

    return snap.docs.map(VolumeHistoryEntry.fromDoc).toList();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
