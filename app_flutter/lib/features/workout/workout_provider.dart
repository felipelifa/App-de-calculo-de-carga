import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'workout_models.dart';
import 'pr_model.dart';
import 'workout_routine_model.dart';
import 'progression_engine.dart';
import 'progression_provider.dart';
import 'decision_memory.dart';
import '../exercises/exercise_model.dart';
import '../../core/services/api_service.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/workouts_api_service.dart';

class WorkoutProvider extends ChangeNotifier {
  final ApiService _api;
  final SupabaseService _supabase;
  final WorkoutsApiService _workoutsApi;
  final ProgressionEngine _progressionEngine;
  final DecisionMemory _decisionMemory;
  ProgressionProvider? _progressionProvider;

  WorkoutProvider({ApiService? api, WorkoutsApiService? workoutsApi})
      : _api = api ?? ApiService(),
        _supabase = SupabaseService(),
        _workoutsApi = workoutsApi ?? WorkoutsApiService(),
        _progressionEngine = ProgressionEngine(),
        _decisionMemory = DecisionMemory() {
    _loadSessionFromLocal();
    _decisionMemory.load();
  }

  void connectProgressionProvider(ProgressionProvider provider) {
    _progressionProvider = provider;
  }

  bool _isSessionActive = false;
  DateTime? _sessionStart;

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
  String? _activeDupPhase;
  final List<WorkoutExerciseEntry> _currentExercises = [];
  final Map<String, int> _rirByExercise = {};
  final Map<String, Map<String, dynamic>> _exerciseMetadata = {};

  List<PrAchievement> _newPrs = [];
  List<PrAchievement> get newPrs => List.unmodifiable(_newPrs);

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
  String? get activeDupPhase => _activeDupPhase;
  List<WorkoutExerciseEntry> get currentExercises =>
      List.unmodifiable(_currentExercises);

  double get currentTotalVolume =>
      _currentExercises.fold(0, (acc, e) => acc + e.totalVolume);

  List<WorkoutSession> _history = [];
  bool _isLoadingHistory = false;
  Timer? _historyPollTimer;

  List<WorkoutSession> get history => List.unmodifiable(_history);
  bool get isLoadingHistory => _isLoadingHistory;

  int get currentWeekNumber {
    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1);
    final dayOfYear = now.difference(startOfYear).inDays;
    return (dayOfYear / 7).ceil();
  }

  void setRirForExercise(String exerciseId, int rir) {
    _rirByExercise[exerciseId] = rir.clamp(0, 5);
    notifyListeners();
  }

  int getRirForExercise(String exerciseId) {
    return _rirByExercise[exerciseId] ?? 3;
  }

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
    String? dupPhase,
  }) {
    _isSessionActive = true;
    _sessionStart = DateTime.now();
    _activeSessionName = sessionName;
    _activeDupPhase = dupPhase;
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

  Future<void> finishSession({
    String? notes,
    String experienceLevel = 'beginner',
    int sessionsPerWeek = 3,
  }) async {
    if (!_api.isAuthenticated) throw Exception('Usuário não autenticado');
    if (_currentExercises.isEmpty) throw Exception('Nenhum exercício registrado');
    if (!_currentExercises.any((exercise) => exercise.hasCompletedWork)) {
      throw Exception('Marque pelo menos uma série concluída antes de salvar');
    }

    final exercisesCopy = List<WorkoutExerciseEntry>.from(_currentExercises);
    final rirCopy = Map<String, int>.from(_rirByExercise);
    final metaCopy = Map<String, Map<String, dynamic>>.from(_exerciseMetadata);

    await _workoutsApi.createWorkout(
      exercises: exercisesCopy,
      durationMinutes: _sessionStart != null
          ? DateTime.now().difference(_sessionStart!).inMinutes
          : null,
      notes: notes,
    );

    _newPrs = [];
    _detectPrsLocally(exercisesCopy).then((achievements) {
      _newPrs = achievements;
      notifyListeners();
    });

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

      _progressionProvider?.processCompletedSession(
        exercises: exercisesCopy,
        rirByExercise: rirCopy,
        exerciseMetadata: metaCopy,
        experienceLevel: experienceLevel,
      );
    });

    _isSessionActive = false;
    _sessionStart = null;
    _activeSessionName = null;
    _activeDupPhase = null;
    _currentExercises.clear();
    _rirByExercise.clear();
    _exerciseMetadata.clear();
    _saveSessionToLocal();
    notifyListeners();
  }

  Future<List<PrAchievement>> _detectPrsLocally(
    List<WorkoutExerciseEntry> exercises,
  ) async {
    final achievements = <PrAchievement>[];
    try {
      final result = await _workoutsApi.getWorkouts(limit: 100);
      final sessions = result.map((w) => WorkoutSession.fromMap(w as Map<String, dynamic>)).toList();

      final bestByExercise = <String, _ExerciseBest>{};
      for (final session in sessions) {
        for (final ex in session.exercises) {
          final existing = bestByExercise[ex.exerciseId];
          double maxW = 0;
          int maxR = 0;
          double maxV = 0;
          for (final s in ex.sets) {
            if (s.weight > maxW) maxW = s.weight;
            if (s.reps > maxR) maxR = s.reps;
            if (s.volume > maxV) maxV = s.volume;
          }
          if (existing == null || maxW > existing.maxWeight || maxR > existing.maxReps || maxV > existing.maxVolume) {
            bestByExercise[ex.exerciseId] = _ExerciseBest(
              maxWeight: existing != null ? (maxW > existing.maxWeight ? maxW : existing.maxWeight) : maxW,
              maxReps: existing != null ? (maxR > existing.maxReps ? maxR : existing.maxReps) : maxR,
              maxVolume: existing != null ? (maxV > existing.maxVolume ? maxV : existing.maxVolume) : maxV,
            );
          }
        }
      }

      for (final entry in exercises) {
        if (entry.exerciseId.isEmpty || entry.sets.isEmpty) continue;
        double sessionMaxWeight = 0;
        int sessionMaxReps = 0;
        double sessionMaxVolume = 0;
        for (final s in entry.sets) {
          if (s.weight > sessionMaxWeight) sessionMaxWeight = s.weight;
          if (s.reps > sessionMaxReps) sessionMaxReps = s.reps;
          if (s.volume > sessionMaxVolume) sessionMaxVolume = s.volume;
        }

        final prev = bestByExercise[entry.exerciseId];
        if (prev == null) {
          achievements.add(PrAchievement(
            exerciseId: entry.exerciseId,
            exerciseName: entry.exerciseName,
            muscleGroup: entry.muscleGroup,
            newMaxWeight: sessionMaxWeight,
            newMaxReps: sessionMaxReps,
            newMaxVolume: sessionMaxVolume,
          ));
        } else {
          final newW = sessionMaxWeight > prev.maxWeight ? sessionMaxWeight : null;
          final newR = sessionMaxReps > prev.maxReps ? sessionMaxReps : null;
          final newV = sessionMaxVolume > prev.maxVolume ? sessionMaxVolume : null;
          if (newW != null || newR != null || newV != null) {
            achievements.add(PrAchievement(
              exerciseId: entry.exerciseId,
              exerciseName: entry.exerciseName,
              muscleGroup: entry.muscleGroup,
              newMaxWeight: newW,
              prevMaxWeight: newW != null ? prev.maxWeight : null,
              newMaxReps: newR,
              prevMaxReps: newR != null ? prev.maxReps : null,
              newMaxVolume: newV,
              prevMaxVolume: newV != null ? prev.maxVolume : null,
            ));
          }
        }
      }
    } catch (e) {
      debugPrint('Erro ao detectar PRs localmente: $e');
    }
    return achievements;
  }

  void cancelSession() {
    _isSessionActive = false;
    _sessionStart = null;
    _activeSessionName = null;
    _activeDupPhase = null;
    _currentExercises.clear();
    _rirByExercise.clear();
    _exerciseMetadata.clear();
    _saveSessionToLocal();
    notifyListeners();
  }

  void loadHistory() {
    _isLoadingHistory = true;
    notifyListeners();

    _fetchHistory();

    _historyPollTimer?.cancel();
    _historyPollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _fetchHistory();
    });
  }

  Future<void> _fetchHistory() async {
    try {
      final result = await _workoutsApi.getWorkouts(limit: 20);
      _history = result
          .map((w) => WorkoutSession.fromMap(w as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    } catch (e) {
      debugPrint('Erro ao carregar histórico: $e');
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }

  Future<void> deleteSession(String sessionId) async {
    try {
      await _workoutsApi.deleteWorkout(sessionId);
    } catch (e) {
      debugPrint('Erro ao excluir sessão: $e');
      rethrow;
    }

    _history.removeWhere((s) => s.id == sessionId);
    notifyListeners();
  }

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
    _historyPollTimer?.cancel();
    _restTimer?.cancel();
    super.dispose();
  }
}

class _ExerciseBest {
  final double maxWeight;
  final int maxReps;
  final double maxVolume;

  const _ExerciseBest({
    required this.maxWeight,
    required this.maxReps,
    required this.maxVolume,
  });
}
