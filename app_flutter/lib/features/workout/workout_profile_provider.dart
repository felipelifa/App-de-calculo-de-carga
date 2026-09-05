import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../../core/services/supabase_service.dart';
import 'workout_profile_model.dart';
import 'prescribed_workout_model.dart';
import 'prescription_engine.dart';
import '../exercises/exercise_model.dart';
import '../exercises/exercise_provider.dart';
import '../../core/data/exercise_library.dart' show exerciseLibrary;
import 'progression_engine.dart';
import 'decision_memory.dart';

class WorkoutProfileProvider extends ChangeNotifier {
  final ApiService _api;
  final SupabaseService _supabase;
  final DecisionMemory _decisionMemory;

  WorkoutProfileProvider({ApiService? api})
      : _api = api ?? ApiService(),
        _supabase = SupabaseService(),
        _decisionMemory = DecisionMemory() {
    _init();
    _decisionMemory.load();
  }

  WorkoutProfile? _profile;
  List<GeneratedWorkout> _allWorkouts = [];
  ProgressionState? _progressionState;
  ExerciseProvider? _exerciseProvider;
  
  Timer? _pollTimer;
  bool _isLoading = true;
  String? _error;

  WorkoutProfile? get profile => _profile;
  List<GeneratedWorkout> get allWorkouts => _allWorkouts;
  GeneratedWorkout? get activeWorkout {
    for (final workout in _allWorkouts) {
      if (workout.isActive) return workout;
    }
    return null;
  }

  bool get isLoading => _isLoading;
  ProgressionState? get progressionState => _progressionState;
  String? get error => _error;
  bool get hasProfile => _profile != null;
  bool get hasWorkout => _allWorkouts.isNotEmpty;

  double getLatestWeightForExercise(String exerciseId) {
    if (_progressionState == null) return 0.0;
    final val = _progressionState!.exerciseProgress[exerciseId]?.lastWeightKg;
    return (val as num?)?.toDouble() ?? 0.0;
  }

  Future<void> _init() async {
    await _loadProfile();
    await _loadWorkouts();
    await _loadProgressionState();

    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadWorkouts();
      _loadProgressionState();
    });
  }

  Future<void> _loadProfile() async {
    try {
      final result = await _supabase.getProfile();
      if (result != null) {
        _profile = WorkoutProfile.fromMap(result);
      }
    } catch (e) {
      debugPrint('Erro no init profile: $e');
    }
  }

  void connectExerciseProvider(ExerciseProvider exerciseProvider) {
    if (_exerciseProvider == exerciseProvider) return;
    _exerciseProvider = exerciseProvider;
    _loadWorkouts();
  }

  ExerciseModel? _resolveExercise(String id) {
    final remoteExercise = _exerciseProvider?.getById(id);
    if (remoteExercise != null) return remoteExercise;
    for (final exercise in exerciseLibrary) {
      if (exercise.id == id) return exercise;
    }
    return null;
  }

  Future<void> _loadWorkouts() async {
    try {
      final data = await _supabase.getGeneratedWorkouts();
      _allWorkouts = data.map((item) {
        return GeneratedWorkout.fromMap(
          item,
          _resolveExercise,
        );
      }).toList();
      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Não foi possível carregar seus planos.';
      notifyListeners();
    }
  }

  Future<void> _loadProgressionState() async {
    try {
      final result = await _supabase.getProgressionState();
      if (result != null) {
        _progressionState = ProgressionState.fromMap(result);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('ProgressionState Error: $e');
    }
  }

  Future<void> refresh() async {
    await _loadProfile();
    await _loadWorkouts();
    await _loadProgressionState();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> saveProfile(WorkoutProfile profile) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _supabase.saveProfile(profile.toMap());
      _profile = profile;
    } catch (e) {
      _error = 'Erro ao salvar perfil: $e';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> generateAndSaveWorkout({String? customName}) async {
    if (_profile == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      // Extrair sessões recentes para fadiga residual
      final recentSessions = <PrescribedSession>[];
      if (_allWorkouts.isNotEmpty) {
        final lastWorkout = _allWorkouts.first;
        recentSessions.addAll(lastWorkout.sessions);
      }

      final engine = WorkoutPrescriptionEngine(
        _profile!,
        library: _exerciseProvider?.allExercises,
        decisionMemory: _decisionMemory,
        recentSessions: recentSessions,
      );
      final workoutRaw = engine.generate(_profile!);
      
      final name = customName ?? 'Treino ${DateTime.now().day}/${DateTime.now().month}';

      final workout = GeneratedWorkout(
        id: '',
        userId: '',
        name: name,
        splitType: workoutRaw.splitType,
        periodizationModel: workoutRaw.periodizationModel,
        sessions: workoutRaw.sessions,
        mesocycleDurationWeeks: workoutRaw.mesocycleDurationWeeks,
        preferredStyle: _profile!.preferredStyle,
        generatedAt: DateTime.now(),
        isActive: true,
        planExplanation: workoutRaw.planExplanation,
      );

      await _supabase.saveGeneratedWorkout(workout.toMap());
      await _loadWorkouts();
    } catch (e) {
      _error = 'Erro ao gerar treino: $e';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setActiveWorkout(String id) async {
    // Optimistic Update
    for (int i = 0; i < _allWorkouts.length; i++) {
        final w = _allWorkouts[i];
        if (w.id == id && !w.isActive) {
           _allWorkouts[i] = GeneratedWorkout(
             id: w.id,
             userId: w.userId,
             name: w.name,
             splitType: w.splitType,
             periodizationModel: w.periodizationModel,
             sessions: w.sessions,
             mesocycleDurationWeeks: w.mesocycleDurationWeeks,
             preferredStyle: w.preferredStyle,
             generatedAt: w.generatedAt,
             isActive: true,
             planExplanation: w.planExplanation,
           );
        } else if (w.id != id && w.isActive) {
          _allWorkouts[i] = GeneratedWorkout(
             id: w.id,
             userId: w.userId,
             name: w.name,
             splitType: w.splitType,
             periodizationModel: w.periodizationModel,
             sessions: w.sessions,
             mesocycleDurationWeeks: w.mesocycleDurationWeeks,
             preferredStyle: w.preferredStyle,
             generatedAt: w.generatedAt,
             isActive: false,
             planExplanation: w.planExplanation,
           );
        }
    }
    notifyListeners();

    try {
      await _api.put('/prescription/$id/activate');
    } catch (e) {
      debugPrint('Erro ao ativar treino: $e');
      await _loadWorkouts();
    }
  }

  Future<void> deleteWorkout(String id) async {
    final deletedWorkout = _allWorkouts.where((w) => w.id == id).firstOrNull;

    try {
      await _api.delete('/prescription/$id');

      if (deletedWorkout?.isActive == true) {
        final next = _allWorkouts.where((w) => w.id != id).firstOrNull;
        if (next != null) {
          await _api.put('/prescription/${next.id}/activate');
        }
      }
      _allWorkouts.removeWhere((w) => w.id == id);
      notifyListeners();
    } catch (e) {
      _error = 'Erro ao excluir treino: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> swapPrescribedExercise(String workoutId, String sessionId, String oldExId, ExerciseModel newEx) async {
    final workout = _allWorkouts.firstWhere((w) => w.id == workoutId);
    
    try {
      final sessionIndex = workout.sessions.indexWhere((s) => s.id == sessionId);
      if (sessionIndex == -1) return;

      final session = workout.sessions[sessionIndex];
      final exIndex = session.exercises.indexWhere((e) => e.exercise.id == oldExId);
      if (exIndex == -1) return;

      final oldEx = session.exercises[exIndex];
      
      final swappedEx = PrescribedExercise(
        exercise: newEx,
        sets: oldEx.sets,
        repsMin: newEx.repRangeMin,
        repsMax: newEx.repRangeMax,
        rir: oldEx.rir,
        restSeconds: oldEx.restSeconds,
        sessionCues: [...newEx.cues.take(2), 'Amplitude máxima controlada.'],
        tempo: oldEx.tempo,
        progressionNote: oldEx.progressionNote,
        injuryNote: null,
      );

      session.exercises[exIndex] = swappedEx;
      
      await _api.put('/prescription/$workoutId', body: workout.toMap());

      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao trocar exercício prescrito: $e');
    }
  }
}
