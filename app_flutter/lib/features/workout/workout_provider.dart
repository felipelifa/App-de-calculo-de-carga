import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'workout_models.dart';
import 'pr_model.dart';
import 'pr_service.dart';
import 'workout_routine_model.dart';
import 'progression_engine.dart';
import '../exercises/exercise_model.dart';
import '../../core/services/api_service.dart';
import '../../core/services/workouts_api_service.dart';

class WorkoutProvider extends ChangeNotifier {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final ProgressionEngine _progressionEngine;
  final WorkoutsApiService _api;

  WorkoutProvider({FirebaseFirestore? db, FirebaseAuth? auth, WorkoutsApiService? api})
      : _db = db ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _api = api ?? WorkoutsApiService(),
        _progressionEngine = ProgressionEngine(
          db: db ?? FirebaseFirestore.instance,
          auth: auth ?? FirebaseAuth.instance,
        ) {
    _loadSessionFromLocal();
  }

  bool _isSessionActive = false;
  DateTime? _sessionStart;

  // ── Rest Timer State ──
  int _activeRestSeconds = 0;
  Timer? _restTimer;
  int get activeRestSeconds => _activeRestSeconds;

  void startRestTimer(int seconds) {
    _restTimer?.cancel();
    _activeRestSeconds = seconds;
    notifyListeners();
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_activeRestSeconds > 0) {
        _activeRestSeconds--;
        notifyListeners();
      } else {
        timer.cancel();
        _activeRestSeconds = 0;
        notifyListeners();
      }
    });
  }

  void stopRestTimer() {
    _restTimer?.cancel();
    _activeRestSeconds = 0;
    notifyListeners();
  }
  String? _activeSessionName;
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
  String? get activeSessionName => _activeSessionName;
  List<WorkoutExerciseEntry> get currentExercises =>
      List.unmodifiable(_currentExercises);

  double get currentTotalVolume =>
      _currentExercises.fold(0, (acc, e) => acc + e.totalVolume);

  List<WorkoutSession> _history = [];
  List<WorkoutSession> _apiHistory = [];
  List<WorkoutSession> _firestoreHistory = [];
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

  // ── Gerenciar RIR por exercício ──
  void setRirForExercise(String exerciseId, int rir) {
    _rirByExercise[exerciseId] = rir.clamp(0, 5);
    notifyListeners();
  }

  int getRirForExercise(String exerciseId) {
    return _rirByExercise[exerciseId] ?? 3;
  }

  // ── Iniciar sessão ──
  void startSession() {
    _isSessionActive = true;
    _sessionStart = DateTime.now();
    _activeSessionName = 'Treino Livre';
    _currentExercises.clear();
    _rirByExercise.clear();
    _exerciseMetadata.clear();
    _saveSessionToLocal();
    notifyListeners();
  }

  void startSessionFromRoutine(WorkoutRoutine routine) {
    _isSessionActive = true;
    _sessionStart = DateTime.now();
    _activeSessionName = routine.name;
    _currentExercises.clear();
    _rirByExercise.clear();
    _exerciseMetadata.clear();

    for (final re in routine.exercises) {
      final entry = WorkoutExerciseEntry(
        exerciseId: re.exerciseId,
        exerciseName: re.name,
        muscleGroup: re.muscleGroup,
        sets: List.generate(re.sets, (_) => WorkoutSet(reps: re.reps, weight: 0, volume: 0)),
      );
      _currentExercises.add(entry);
    }
    _saveSessionToLocal();
    notifyListeners();
  }

  void startSessionFromPrescribed({
    required String sessionId,
    required String sessionName,
    required List<Map<String, dynamic>> prescribedExercises,
  }) {
    _isSessionActive = true;
    _sessionStart = DateTime.now();
    _activeSessionName = sessionName;
    _currentExercises.clear();
    _rirByExercise.clear();
    _exerciseMetadata.clear();

    for (final pe in prescribedExercises) {
      final exId = pe['exerciseId'] as String? ?? '';
      final sets = (pe['sets'] as int?) ?? 3;
      final repsMax = (pe['repsMax'] as int?) ?? 12;
      final defaultWeight = (pe['defaultWeightKg'] as num?)?.toDouble() ?? 0.0;

      final entry = WorkoutExerciseEntry(
        exerciseId: exId,
        exerciseName: pe['exerciseName'] as String? ?? '',
        muscleGroup: pe['muscleGroup'] as String? ?? '',
        injuryNote: pe['injuryNote'] as String?,
        sets: List.generate(sets, (_) => WorkoutSet(reps: repsMax, weight: defaultWeight, volume: repsMax * defaultWeight)),
      );
      _currentExercises.add(entry);

      _exerciseMetadata[exId] = {
        'isBodyweight': pe['isBodyweight'] ?? false,
        'progressionIds': pe['progressionIds'] ?? [],
        'substituteIds': pe['substituteIds'] ?? [],
      };

      final defaultRir = (pe['rir'] as int?) ?? 3;
      _rirByExercise[exId] = defaultRir;
    }
    _saveSessionToLocal();
    notifyListeners();
  }

  // ── Adicionar/remover exercícios ──
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
      entry.sets.add(WorkoutSet(reps: defaultReps, weight: defaultWeight, volume: vol));
    }
    _currentExercises.add(entry);

    if (exerciseModel != null) {
      _exerciseMetadata[exerciseId] = {
        'isBodyweight': exerciseModel.equipment.contains('bodyweight') && exerciseModel.equipment.length == 1,
        'progressionIds': exerciseModel.progressionIds,
        'substituteIds': exerciseModel.substituteIds,
      };
    }
    _saveSessionToLocal();
    notifyListeners();
  }

  void removeExerciseFromSession(int index) {
    if (index >= 0 && index < _currentExercises.length) {
      _currentExercises.removeAt(index);
      _saveSessionToLocal();
      notifyListeners();
    }
  }

  void replaceExerciseInSession(int index, ExerciseModel newEx) {
    if (index < 0 || index >= _currentExercises.length) return;
    final oldEntry = _currentExercises[index];
    final setsCount = oldEntry.sets.length;
    final reps = newEx.repRangeMax;

    final newEntry = WorkoutExerciseEntry(
      exerciseId: newEx.id,
      exerciseName: newEx.name,
      muscleGroup: newEx.primaryMuscles.isNotEmpty ? newEx.primaryMuscles.first : 'Geral',
      sets: List.generate(setsCount, (_) => WorkoutSet(reps: reps, weight: 0, volume: 0)),
    );

    _currentExercises[index] = newEntry;
    _exerciseMetadata[newEx.id] = {
      'isBodyweight': newEx.equipment.contains('bodyweight') && newEx.equipment.length == 1,
      'progressionIds': newEx.progressionIds,
      'substituteIds': newEx.substituteIds,
    };
    _saveSessionToLocal();
    notifyListeners();
  }

  void updateSet({
    required int exerciseIndex,
    required int setIndex,
    required int reps,
    required double weight,
    bool? isWarmup,
    bool? isCompleted,
  }) {
    if (exerciseIndex >= _currentExercises.length) return;
    final exercise = _currentExercises[exerciseIndex];
    if (setIndex >= exercise.sets.length) return;
    exercise.sets[setIndex] = WorkoutSet(
      reps: reps,
      weight: weight,
      volume: reps * weight,
      isWarmup: isWarmup ?? exercise.sets[setIndex].isWarmup,
      isCompleted: isCompleted ?? exercise.sets[setIndex].isCompleted,
    );
    _saveSessionToLocal();
    notifyListeners();
  }

  void addSet(int exerciseIndex) {
    if (exerciseIndex >= _currentExercises.length) return;
    final exercise = _currentExercises[exerciseIndex];
    final last = exercise.sets.isNotEmpty ? exercise.sets.last : null;
    final reps = last?.reps ?? 10;
    final weight = last?.weight ?? 20;
    exercise.sets.add(WorkoutSet(reps: reps, weight: weight, volume: reps * weight, isWarmup: false));
    _saveSessionToLocal();
    notifyListeners();
  }

  void removeSet(int exerciseIndex, int setIndex) {
    if (exerciseIndex >= _currentExercises.length) return;
    final exercise = _currentExercises[exerciseIndex];
    if (exercise.sets.length > 1 && setIndex < exercise.sets.length) {
      exercise.sets.removeAt(setIndex);
      _saveSessionToLocal();
      notifyListeners();
    }
  }

  void addWarmupSetForExercise(String exerciseId) {
    final idx = _currentExercises.indexWhere((e) => e.exerciseId == exerciseId);
    if (idx == -1) return;
    final exercise = _currentExercises[idx];
    final lastSet = exercise.sets.isNotEmpty ? exercise.sets.last : null;
    final reps = lastSet?.reps ?? 12;
    final weight = (lastSet?.weight ?? 20) * 0.5;

    exercise.sets.insert(0, WorkoutSet(reps: reps, weight: weight, volume: reps * weight, isWarmup: true));
    _saveSessionToLocal();
    notifyListeners();
  }

  // ── Finalizar sessão ──────────────────────────────────────────

  Future<void> finishSession({
    String? notes,
    String experienceLevel = 'beginner',
    int sessionsPerWeek = 3,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Usuário não autenticado');
    if (_currentExercises.isEmpty) throw Exception('Nenhum exercício registrado');
    if (!_currentExercises.any((exercise) => exercise.hasCompletedWork)) {
      throw Exception('Marque pelo menos uma série concluída antes de salvar');
    }

    final exercisesCopy = List<WorkoutExerciseEntry>.from(_currentExercises);
    final rirCopy = Map<String, int>.from(_rirByExercise);
    final metaCopy = Map<String, Map<String, dynamic>>.from(_exerciseMetadata);

    // Tentar salvar via API própria
    bool savedViaApi = false;
    try {
      await _api.createWorkout(
        exercises: exercisesCopy,
        durationMinutes: _sessionStart != null
            ? DateTime.now().difference(_sessionStart!).inMinutes
            : null,
        notes: notes,
      );
      savedViaApi = true;
    } catch (e) {
      debugPrint('API não disponível, salvando no Firestore: $e');
    }

    // Fallback: salvar no Firestore
    if (!savedViaApi) {
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
    }

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
          sessionsPerWeek: sessionsPerWeek,
        )
        .then((decisions) {
      _progressionDecisions = decisions;
      notifyListeners();
    });

    _isSessionActive = false;
    _sessionStart = null;
    _activeSessionName = null;
    _currentExercises.clear();
    _rirByExercise.clear();
    _exerciseMetadata.clear();
    _saveSessionToLocal();
    notifyListeners();
  }

  void cancelSession() {
    _isSessionActive = false;
    _sessionStart = null;
    _activeSessionName = null;
    _currentExercises.clear();
    _rirByExercise.clear();
    _exerciseMetadata.clear();
    _saveSessionToLocal();
    notifyListeners();
  }

  void loadHistory() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    _isLoadingHistory = true;
    notifyListeners();

    // Tentar carregar da API primeiro
    _loadHistoryFromApi();

    // Também escutar Firestore como fallback
    _historySub?.cancel();
    _historySub = _db
        .collection('users/$uid/workouts')
        .orderBy('date', descending: true)
        .limit(20)
        .snapshots()
        .listen(
      (snap) {
        _firestoreHistory = snap.docs.map(WorkoutSession.fromDoc).toList();
        _publishHistory();
        _isLoadingHistory = false;
        notifyListeners();
      },
      onError: (e) {
        _isLoadingHistory = false;
        notifyListeners();
      },
    );
  }

  Future<void> _loadHistoryFromApi() async {
    try {
      final result = await _api.getWorkouts(limit: 20);
      if (result.isNotEmpty) {
        // API retornou dados — usar eles
        final sessions = result.map((w) => WorkoutSession.fromMap(w)).toList();
        _apiHistory = sessions;
        _publishHistory();
        _isLoadingHistory = false;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('API não disponível para histórico, usando Firestore: $e');
    }
  }

  void _publishHistory() {
    final byId = <String, WorkoutSession>{};
    for (final session in _apiHistory) {
      byId[session.id] = session;
    }
    for (final session in _firestoreHistory) {
      byId[session.id] = session;
    }
    _history = byId.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> deleteSession(String sessionId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    // Tentar deletar via API
    try {
      await _api.deleteWorkout(sessionId);
    } catch (_) {
      // Fallback para Firestore
    }

    try {
      await _db.collection('users/$uid/workouts').doc(sessionId).delete();
    } catch (e) {
      debugPrint('Erro ao excluir sessão: $e');
      rethrow;
    }

    // Atualizar lista local e notificar UI
    _history.removeWhere((s) => s.id == sessionId);
    _apiHistory.removeWhere((s) => s.id == sessionId);
    _firestoreHistory.removeWhere((s) => s.id == sessionId);
    _publishHistory();
    notifyListeners();
  }

  // ── Persistência Local (F5 proof) ──────────────────────────

  Future<void> _saveSessionToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!_isSessionActive) {
        await prefs.remove('active_workout_session');
        return;
      }

      final data = {
        'sessionStart': _sessionStart?.toIso8601String(),
        'activeSessionName': _activeSessionName,
        'currentExercises': _currentExercises.map((e) => e.toMap()).toList(),
        'rirByExercise': _rirByExercise,
        'exerciseMetadata': _exerciseMetadata,
      };

      await prefs.setString('active_workout_session', jsonEncode(data));
    } catch (e) {
      debugPrint('Erro ao salvar sessão localmente: $e');
    }
  }

  Future<void> _loadSessionFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('active_workout_session');
      if (saved == null) return;

      final data = jsonDecode(saved);
      _isSessionActive = true;
      _sessionStart = DateTime.tryParse(data['sessionStart'] ?? '');
      _activeSessionName = data['activeSessionName'];

      _currentExercises.clear();
      if (data['currentExercises'] != null) {
        for (var exMap in data['currentExercises']) {
          _currentExercises.add(WorkoutExerciseEntry.fromMap(Map<String, dynamic>.from(exMap)));
        }
      }

      _rirByExercise.clear();
      if (data['rirByExercise'] != null) {
        final rirMap = Map<String, dynamic>.from(data['rirByExercise']);
        rirMap.forEach((key, value) {
          _rirByExercise[key] = value as int;
        });
      }

      _exerciseMetadata.clear();
      if (data['exerciseMetadata'] != null) {
        final metaMap = Map<String, dynamic>.from(data['exerciseMetadata']);
        metaMap.forEach((key, value) {
          _exerciseMetadata[key] = Map<String, dynamic>.from(value);
        });
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao carregar sessão local: $e');
    }
  }

  @override
  void dispose() {
    _historySub?.cancel();
    super.dispose();
  }
}
