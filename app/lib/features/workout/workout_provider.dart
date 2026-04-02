import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'workout_models.dart';
import 'pr_model.dart';
import 'pr_service.dart';
import 'workout_routine_model.dart';
import 'progression_engine.dart';
import '../exercises/exercise_model.dart';

class WorkoutProvider extends ChangeNotifier {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final ProgressionEngine _progressionEngine;

  WorkoutProvider({FirebaseFirestore? db, FirebaseAuth? auth})
      : _db = db ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _progressionEngine = ProgressionEngine(
          db: db ?? FirebaseFirestore.instance,
          auth: auth ?? FirebaseAuth.instance,
        );

  bool _isSessionActive = false;
  DateTime? _sessionStart;
  final List<WorkoutExerciseEntry> _currentExercises = [];

  // RIR reportado por exercício (exerciseId → RIR 0-5)
  final Map<String, int> _rirByExercise = {};

  // Metadados dos exercícios para o motor de progressão
  final Map<String, Map<String, dynamic>> _exerciseMetadata = {};

  // PRs conquistados na sessão mais recente
  List<PrAchievement> _newPrs = [];
  List<PrAchievement> get newPrs => List.unmodifiable(_newPrs);

  // Decisões de progressão pós-sessão
  List<ProgressionDecision> _progressionDecisions = [];
  List<ProgressionDecision> get progressionDecisions =>
      List.unmodifiable(_progressionDecisions);

  void clearNewPrs() {
    _newPrs = [];
    notifyListeners();
  }

  void clearProgressionDecisions() {
    _progressionDecisions = [];
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

  // ── Gerenciar RIR por exercício ───────────────────────────────

  void setRirForExercise(String exerciseId, int rir) {
    _rirByExercise[exerciseId] = rir.clamp(0, 5);
    notifyListeners();
  }

  int getRirForExercise(String exerciseId) {
    return _rirByExercise[exerciseId] ?? 3; // default RIR 3 (moderado)
  }

  // ── Iniciar sessão ────────────────────────────────────────────

  void startSession() {
    _isSessionActive = true;
    _sessionStart = DateTime.now();
    _currentExercises.clear();
    _rirByExercise.clear();
    _exerciseMetadata.clear();
    notifyListeners();
  }

  void startSessionFromRoutine(WorkoutRoutine routine) {
    _isSessionActive = true;
    _sessionStart = DateTime.now();
    _currentExercises.clear();
    _rirByExercise.clear();
    _exerciseMetadata.clear();

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

  /// Inicia sessão a partir de uma PrescribedSession com metadados completos
  void startSessionFromPrescribed({
    required String sessionId,
    required String sessionName,
    required List<Map<String, dynamic>> prescribedExercises,
  }) {
    _isSessionActive = true;
    _sessionStart = DateTime.now();
    _currentExercises.clear();
    _rirByExercise.clear();
    _exerciseMetadata.clear();

    for (final pe in prescribedExercises) {
      final exId = pe['exerciseId'] as String? ?? '';
      final sets = (pe['sets'] as int?) ?? 3;
      final repsMax = (pe['repsMax'] as int?) ?? 12;
      final defaultWeight = (pe['defaultWeightKg'] as double?) ?? 0.0;

      final entry = WorkoutExerciseEntry(
        exerciseId: exId,
        exerciseName: pe['exerciseName'] as String? ?? '',
        muscleGroup: pe['muscleGroup'] as String? ?? '',
        sets: List.generate(
          sets,
          (_) => WorkoutSet(
            reps: repsMax,
            weight: defaultWeight,
            volume: repsMax * defaultWeight,
          ),
        ),
      );
      _currentExercises.add(entry);

      // Salva metadados para o motor de progressão
      _exerciseMetadata[exId] = {
        'isBodyweight': pe['isBodyweight'] ?? false,
        'progressionIds': pe['progressionIds'] ?? [],
        'substituteIds': pe['substituteIds'] ?? [],
      };

      // RIR padrão do exercício prescrito
      final defaultRir = (pe['rir'] as int?) ?? 3;
      _rirByExercise[exId] = defaultRir;
    }
    notifyListeners();
  }

  // ── Adicionar/remover exercícios ──────────────────────────────

  void addExerciseToSession({
    required String exerciseId,
    required String exerciseName,
    required String muscleGroup,
    int defaultSeries = 3,
    int defaultReps = 10,
    double defaultWeight = 20,
    ExerciseModel? exerciseModel,
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

    // Salva metadados se exercício model disponível
    if (exerciseModel != null) {
      _exerciseMetadata[exerciseId] = {
        'isBodyweight': exerciseModel.equipment.contains('bodyweight') &&
            exerciseModel.equipment.length == 1,
        'progressionIds': exerciseModel.progressionIds,
        'substituteIds': exerciseModel.substituteIds,
      };
    }

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

  // ── Finalizar sessão ──────────────────────────────────────────

  Future<void> finishSession({
    String? notes,
    String experienceLevel = 'beginner',
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Usuário não autenticado');
    if (_currentExercises.isEmpty) throw Exception('Nenhum exercício registrado');

    final exercisesCopy = List<WorkoutExerciseEntry>.from(_currentExercises);
    final rirCopy = Map<String, int>.from(_rirByExercise);
    final metaCopy = Map<String, Map<String, dynamic>>.from(_exerciseMetadata);

    final session = {
      'date': FieldValue.serverTimestamp(),
      'weekNumber': currentWeekNumber,
      'totalVolume': currentTotalVolume,
      'exerciseCount': _currentExercises.length,
      'exercises': _currentExercises.map((e) => e.toMap()).toList(),
      'rirByExercise': rirCopy,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };

    await _db.collection('users/$uid/workouts').add(session);

    // Detecta PRs em background
    _newPrs = [];
    PrService(db: _db, uid: uid)
        .processSession(exercisesCopy)
        .then((achievements) {
      _newPrs = achievements;
      notifyListeners();
    });

    // Motor de progressão em background
    _progressionDecisions = [];
    _progressionEngine
        .processSession(
          workoutEntries: exercisesCopy,
          rirByExercise: rirCopy,
          exerciseMetadata: metaCopy,
          experienceLevel: experienceLevel,
        )
        .then((decisions) {
      _progressionDecisions = decisions;
      notifyListeners();
    });

    _isSessionActive = false;
    _sessionStart = null;
    _currentExercises.clear();
    _rirByExercise.clear();
    _exerciseMetadata.clear();
    notifyListeners();
  }

  void cancelSession() {
    _isSessionActive = false;
    _sessionStart = null;
    _currentExercises.clear();
    _rirByExercise.clear();
    _exerciseMetadata.clear();
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
