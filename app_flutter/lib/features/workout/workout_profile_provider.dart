import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../../core/services/supabase_service.dart';
import 'workout_profile_model.dart';
import 'prescribed_workout_model.dart';
import 'prescription_engine.dart';
import 'exercise_compatibility.dart';
import '../exercises/exercise_model.dart';
import '../exercises/exercise_provider.dart';
import '../../core/data/exercise_library.dart' show exerciseLibrary;
import 'progression_engine.dart';
import 'decision_memory.dart';
import 'workout_validator.dart';
import 'session_fatigue_accumulator.dart';
import 'home_workout/home_workout_integrator.dart';

class WorkoutProfileProvider extends ChangeNotifier {
  final ApiService _api;
  final SupabaseService _supabase;
  final DecisionMemory _decisionMemory;
  final HomeWorkoutIntegrator _homeWorkoutIntegrator = HomeWorkoutIntegrator();
  late final Future<void> _decisionMemoryReady;

  WorkoutProfileProvider({ApiService? api, ExerciseProvider? exerciseProvider})
    : _api = api ?? ApiService(),
      _supabase = SupabaseService(),
      _decisionMemory = DecisionMemory(),
      _exerciseProvider = exerciseProvider {
    _decisionMemoryReady = _decisionMemory.load();
    _init();
  }

  WorkoutProfile? _profile;
  List<GeneratedWorkout> _allWorkouts = [];
  ProgressionState? _progressionState;
  ExerciseProvider? _exerciseProvider;

  Timer? _pollTimer;
  bool _isLoading = true;
  bool _workoutsRequestInFlight = false;
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
    _loadWorkouts(force: true);
  }

  ExerciseModel? _resolveExercise(String id) {
    if (id.isEmpty) return null;
    final remoteExercise = _exerciseProvider?.getById(id);
    if (remoteExercise != null) return remoteExercise;
    final homeExercise = _homeWorkoutIntegrator.getExerciseModelById(id);
    if (homeExercise != null) return homeExercise;
    for (final exercise in exerciseLibrary) {
      if (exercise.id == id) return exercise;
    }
    debugPrint(
      'RESOLUÇÃO FALHOU: exercício "$id" não encontrado. '
      'Provider: ${_exerciseProvider != null ? "conectado" : "null"}, '
      'Library: ${exerciseLibrary.length} exercícios.',
    );
    return null;
  }

  Future<void> _loadWorkouts({bool force = false}) async {
    if (_workoutsRequestInFlight && !force) return;
    _workoutsRequestInFlight = true;
    try {
      final data = await _supabase.getGeneratedWorkouts();
      debugPrint('═══ DIAGNÓSTICO LOAD ═══');
      debugPrint('Workouts do Supabase: ${data.length}');
      for (int i = 0; i < data.length; i++) {
        final item = data[i];
        final sessions = item['sessions'] as List? ?? [];
        int totalEx = 0;
        for (final s in sessions) {
          final exList =
              (s as Map<String, dynamic>)['exercises'] as List? ?? [];
          totalEx += exList.length;
        }
        debugPrint(
          '  Workout $i: id=${item['id']}, '
          'sessions=${sessions.length}, '
          'exercises=$totalEx, '
          'isActive=${item['isActive']}',
        );
      }
      debugPrint('═══════════════════════');

      final loadedWorkouts = data.map((item) {
        return GeneratedWorkout.fromMap(item, _resolveExercise);
      }).toList();

      final validWorkouts = <GeneratedWorkout>[];
      final invalidWorkouts = <String>[];
      for (final workout in loadedWorkouts) {
        if (_profile == null) {
          validWorkouts.add(workout);
          continue;
        }
        final validation = WorkoutValidator.validate(
          profile: _profile!,
          workout: workout,
          requireExpectedSessionCount: false,
        );
        if (validation.isValid) {
          validWorkouts.add(workout);
        } else {
          invalidWorkouts.add(workout.name);
          debugPrint('PLANO INVÁLIDO ${workout.name}: ${validation.summary}');
        }
      }
      _allWorkouts = validWorkouts;
      if (invalidWorkouts.isNotEmpty && validWorkouts.isEmpty) {
        _error = 'Seus planos antigos precisam ser regenerados.';
      } else if (invalidWorkouts.isEmpty) {
        _error = null;
      }

      // Log pós-resolução
      for (int i = 0; i < _allWorkouts.length; i++) {
        final w = _allWorkouts[i];
        final resolvedEx = w.sessions.fold(
          0,
          (sum, s) => sum + s.exercises.length,
        );
        debugPrint(
          '  Resolvido $i: ${w.sessions.length} sessões, '
          '$resolvedEx exercícios',
        );
      }

      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Não foi possível carregar seus planos.';
      debugPrint('ERRO LOAD WORKOUTS: $e');
      notifyListeners();
    } finally {
      _workoutsRequestInFlight = false;
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
    if (_profile == null) {
      throw StateError('Complete a anamnese antes de gerar o treino');
    }

    _isLoading = true;
    notifyListeners();

    try {
      await _decisionMemoryReady;
      final recentSessions = await _loadRecentCompletedSessions();

      final engine = WorkoutPrescriptionEngine(
        _profile!,
        library: _exerciseProvider?.allExercises.isNotEmpty == true
            ? _exerciseProvider!.allExercises
            : null,
        decisionMemory: _decisionMemory,
        recentSessions: recentSessions,
        progressionState: _progressionState,
      );
      final workoutRaw = engine.generate(_profile!);

      // ── VALIDAÇÃO OBRIGATÓRIA ──
      final validation = WorkoutValidator.validate(
        profile: _profile!,
        workout: workoutRaw,
      );
      if (!validation.isValid) {
        throw StateError(
          'O treino gerado não passou na validação: ${validation.summary}',
        );
      }
      final totalExercises = workoutRaw.sessions.fold(
        0,
        (sum, s) => sum + s.exercises.length,
      );
      debugPrint(
        'TREINO GERADO: ${workoutRaw.sessions.length} sessões, '
        '$totalExercises exercícios totais.',
      );

      final name =
          customName ?? 'Treino ${DateTime.now().day}/${DateTime.now().month}';

      final workout = GeneratedWorkout(
        id: workoutRaw.id,
        userId: _profile!.uid,
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

      final persistenceValidation = WorkoutValidator.validate(
        profile: _profile!,
        workout: workout,
      );
      if (!persistenceValidation.isValid) {
        throw StateError(
          'NO_COMPATIBLE_EXERCISES: o treino foi rejeitado antes da persistência: '
          '${persistenceValidation.summary}',
        );
      }

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

  Future<List<PrescribedSession>> _loadRecentCompletedSessions() async {
    try {
      final rawWorkouts = await _supabase.getWorkouts(limit: 3);
      final sessions = <PrescribedSession>[];
      for (final raw in rawWorkouts) {
        final rawExercises = List<Map<String, dynamic>>.from(
          raw['exercises'] ?? const [],
        );
        final prescribed = <PrescribedExercise>[];
        var spinal = 0.0;
        var shoulder = 0.0;
        var knee = 0.0;
        var cns = 0.0;
        for (final rawExercise in rawExercises) {
          final exercise = _resolveExercise(
            rawExercise['exerciseId']?.toString() ?? '',
          );
          if (exercise == null) continue;
          final sets = List<Map<String, dynamic>>.from(
            rawExercise['sets'] ?? const [],
          );
          final setCount = sets.length.clamp(1, 20).toInt();
          final reps = sets.isEmpty
              ? exercise.repRangeMin
              : (sets.first['reps'] as num?)?.toInt() ?? exercise.repRangeMin;
          prescribed.add(
            PrescribedExercise(
              exercise: exercise,
              sets: setCount,
              repsMin: reps,
              repsMax: reps,
              rir: 3,
              restSeconds: 90,
              sessionCues: const [],
              progressionNote: 'Histórico da sessão realizada.',
            ),
          );
          spinal += exercise.spinalLoad * setCount;
          shoulder += exercise.shoulderStress * setCount;
          knee += exercise.kneeStress * setCount;
          cns += exercise.cnsLoad * setCount;
        }
        if (prescribed.isEmpty) continue;
        sessions.add(
          PrescribedSession(
            id: raw['id']?.toString() ?? 'completed_session',
            name: raw['sessionType']?.toString() ?? 'Sessão realizada',
            objective: 'Histórico de fadiga',
            estimatedDurationMinutes:
                (raw['durationMinutes'] as num?)?.toInt() ?? 60,
            warmupInstructions: const [],
            exercises: prescribed,
            progressionNote: 'Dados coletados da sessão realizada.',
            fatigue: FatigueMetrics(
              spinalLoad: (spinal / SessionFatigueAccumulator.maxSpinalLoad)
                  .clamp(0.0, 1.0),
              shoulderStress:
                  (shoulder / SessionFatigueAccumulator.maxShoulderStress)
                      .clamp(0.0, 1.0),
              kneeStress: (knee / SessionFatigueAccumulator.maxKneeStress)
                  .clamp(0.0, 1.0),
              cnsLoad: (cns / SessionFatigueAccumulator.maxCnsLoad).clamp(
                0.0,
                1.0,
              ),
            ),
          ),
        );
      }
      return sessions;
    } catch (e) {
      debugPrint('Histórico de fadiga indisponível: $e');
      return const [];
    }
  }

  Future<void> setActiveWorkout(String id) async {
    try {
      await _api.put('/prescription/$id/activate');
      await _loadWorkouts();
    } catch (e) {
      _error = 'Erro ao ativar treino: $e';
      notifyListeners();
      rethrow;
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

  Future<void> swapPrescribedExercise(
    String workoutId,
    String sessionId,
    String oldExId,
    ExerciseModel newEx,
  ) async {
    final workout = _allWorkouts.firstWhere((w) => w.id == workoutId);

    if (_profile != null &&
        !ExerciseCompatibility.isCompatible(_profile!, newEx)) {
      throw StateError(
        'O exercício escolhido não é compatível com seu contexto.',
      );
    }

    try {
      final sessionIndex = workout.sessions.indexWhere(
        (s) => s.id == sessionId,
      );
      if (sessionIndex == -1) return;

      final session = workout.sessions[sessionIndex];
      final exIndex = session.exercises.indexWhere(
        (e) => e.exercise.id == oldExId,
      );
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
        selectionScore: null,
      );

      session.exercises[exIndex] = swappedEx;

      await _api.put('/prescription/$workoutId', body: workout.toMap());

      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao trocar exercício prescrito: $e');
    }
  }
}
