import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'workout_models.dart';
import 'pr_model.dart';
import 'pr_service.dart';
import 'workout_routine_model.dart';

class WorkoutProvider extends ChangeNotifier {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  WorkoutProvider({FirebaseFirestore? db, FirebaseAuth? auth})
      : _db = db ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  bool _isSessionActive = false;
  DateTime? _sessionStart;
  final List<WorkoutExerciseEntry> _currentExercises = [];

  // PRs conquistados na sessão mais recente
  List<PrAchievement> _newPrs = [];
  List<PrAchievement> get newPrs => List.unmodifiable(_newPrs);

  void clearNewPrs() {
    _newPrs = [];
    notifyListeners();
  }

  bool get isSessionActive => _isSessionActive;
  DateTime? get sessionStart => _sessionStart;
  List<WorkoutExerciseEntry> get currentExercises =>
      List.unmodifiable(_currentExercises);

  double get currentTotalVolume =>
      _currentExercises.fold(0, (acc, e) => acc + e.totalVolume);

  List<WorkoutSession> _history = [];
  bool _isLoadingHistory = false;
  StreamSubscription<QuerySnapshot>? _historySub;

  List<WorkoutSession> get history => List.unmodifiable(_history);
  bool get isLoadingHistory => _isLoadingHistory;

  int get currentWeekNumber {
    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1);
    final dayOfYear = now.difference(startOfYear).inDays;
    return (dayOfYear / 7).ceil();
  }

  void startSession() {
    _isSessionActive = true;
    _sessionStart = DateTime.now();
    _currentExercises.clear();
    notifyListeners();
  }

  void startSessionFromRoutine(WorkoutRoutine routine) {
    _isSessionActive = true;
    _sessionStart = DateTime.now();
    _currentExercises.clear();

    for (final re in routine.exercises) {
      final entry = WorkoutExerciseEntry(
        exerciseId: re.exerciseId,
        exerciseName: re.name,
        muscleGroup: re.muscleGroup,
        sets: List.generate(
          re.sets,
          (_) => WorkoutSet(reps: re.reps, weight: 0, volume: 0),
        ),
      );
      _currentExercises.add(entry);
    }
    notifyListeners();
  }

  void addExerciseToSession({
    required String exerciseId,
    required String exerciseName,
    required String muscleGroup,
    int defaultSeries = 3,
    int defaultReps = 10,
    double defaultWeight = 20,
  }) {
    final entry = WorkoutExerciseEntry(
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      muscleGroup: muscleGroup,
    );
    for (int i = 0; i < defaultSeries; i++) {
      final vol = defaultReps * defaultWeight;
      entry.sets.add(WorkoutSet(
        reps: defaultReps,
        weight: defaultWeight,
        volume: vol,
      ));
    }
    _currentExercises.add(entry);
    notifyListeners();
  }

  void removeExerciseFromSession(int index) {
    if (index >= 0 && index < _currentExercises.length) {
      _currentExercises.removeAt(index);
      notifyListeners();
    }
  }

  void updateSet({
    required int exerciseIndex,
    required int setIndex,
    required int reps,
    required double weight,
  }) {
    if (exerciseIndex >= _currentExercises.length) return;
    final exercise = _currentExercises[exerciseIndex];
    if (setIndex >= exercise.sets.length) return;
    exercise.sets[setIndex] = WorkoutSet(
      reps: reps,
      weight: weight,
      volume: reps * weight,
    );
    notifyListeners();
  }

  void addSet(int exerciseIndex) {
    if (exerciseIndex >= _currentExercises.length) return;
    final exercise = _currentExercises[exerciseIndex];
    final last = exercise.sets.isNotEmpty ? exercise.sets.last : null;
    final reps = last?.reps ?? 10;
    final weight = last?.weight ?? 20;
    exercise.sets.add(WorkoutSet(
      reps: reps,
      weight: weight,
      volume: reps * weight,
    ));
    notifyListeners();
  }

  void removeSet(int exerciseIndex, int setIndex) {
    if (exerciseIndex >= _currentExercises.length) return;
    final exercise = _currentExercises[exerciseIndex];
    if (exercise.sets.length > 1 && setIndex < exercise.sets.length) {
      exercise.sets.removeAt(setIndex);
      notifyListeners();
    }
  }

  Future<void> finishSession({String? notes}) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Usuário não autenticado');
    if (_currentExercises.isEmpty) throw Exception('Nenhum exercício registrado');

    // Captura cópia dos exercícios antes de limpar
    final exercisesCopy = List<WorkoutExerciseEntry>.from(_currentExercises);

    final session = {
      'date': FieldValue.serverTimestamp(),
      'weekNumber': currentWeekNumber,
      'totalVolume': currentTotalVolume,
      'exerciseCount': _currentExercises.length,
      'exercises': _currentExercises.map((e) => e.toMap()).toList(),
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };

    await _db.collection('users/$uid/workouts').add(session);

    // Detecta PRs em background (não bloqueia o UI)
    _newPrs = [];
    PrService(db: _db, uid: uid)
        .processSession(exercisesCopy)
        .then((achievements) {
      _newPrs = achievements;
      notifyListeners();
    });

    _isSessionActive = false;
    _sessionStart = null;
    _currentExercises.clear();
    notifyListeners();
  }

  void cancelSession() {
    _isSessionActive = false;
    _sessionStart = null;
    _currentExercises.clear();
    notifyListeners();
  }

  void loadHistory() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    _isLoadingHistory = true;
    notifyListeners();

    _historySub?.cancel();
    _historySub = _db
        .collection('users/$uid/workouts')
        .orderBy('date', descending: true)
        .limit(20)
        .snapshots()
        .listen(
      (snap) {
        _history = snap.docs.map(WorkoutSession.fromDoc).toList();
        _isLoadingHistory = false;
        notifyListeners();
      },
      onError: (e) {
        _isLoadingHistory = false;
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _historySub?.cancel();
    super.dispose();
  }
}
