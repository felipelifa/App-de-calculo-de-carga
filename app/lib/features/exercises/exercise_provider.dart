import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'exercise_model.dart';
import '../../core/data/mock_exercises.dart';

// ─────────────────────────────────────────────
// Provider de Exercícios (Gera e gerencia biblioteca global)
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
          .where((e) => e.primaryMuscles.any((m) => 
               m.toLowerCase() == _selectedMuscle!.toLowerCase()))
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
    _sub = _db
        .collection('exercises')
        .orderBy('name')
        .snapshots()
        .listen(
      (snap) {
        if (snap.docs.isEmpty) {
          _allExercises = List.from(mockExercises);
          // Optional: Push to Firestore so it populates the emulator dynamically
          // snap.docs.isEmpty could mean we just started the emulator.
        } else {
          _allExercises = snap.docs.map(ExerciseModel.fromDoc).toList();
        }
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

  // ── Methods ───────────────────────────────
  
  ExerciseModel? getById(String id) {
    try {
      return _allExercises.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
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
    // Read only for user database.
    await Future.delayed(const Duration(milliseconds: 500));
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
      return snap.docs.map((d) => VolumeHistoryEntry.fromMap(d.data())).toList();
    } catch (e) {
      debugPrint('Erro ao obter histórico do exercício: $e');
      return [];
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

// ─────────────────────────────────────────────
// Histórico de Volume Local
// ─────────────────────────────────────────────

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
