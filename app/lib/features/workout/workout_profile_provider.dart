import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'; // Add material for SnackBar if needed or types
import 'workout_profile_model.dart';
import 'prescribed_workout_model.dart';
import 'prescription_engine.dart';
import '../exercises/exercise_model.dart';
import '../exercises/exercise_provider.dart';
import 'progression_engine.dart';

class WorkoutProfileProvider extends ChangeNotifier {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  WorkoutProfileProvider({FirebaseFirestore? db, FirebaseAuth? auth})
      : _db = db ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance {
    _init();
  }

  WorkoutProfile? _profile;
  List<GeneratedWorkout> _allWorkouts = [];
  ProgressionState? _progressionState;
  ExerciseProvider? _exerciseProvider;
  
  StreamSubscription? _workoutsSub;
  StreamSubscription? _progressionSub;
  StreamSubscription? _authSub;

  bool _isLoading = true;
  String? _error;

  WorkoutProfile? get profile => _profile;
  List<GeneratedWorkout> get allWorkouts => _allWorkouts;
  GeneratedWorkout? get activeWorkout {
    if (_allWorkouts.isEmpty) return null;
    try {
      return _allWorkouts.firstWhere((w) => w.isActive);
    } catch (_) {
      return _allWorkouts.first;
    }
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
    _authSub?.cancel();
    _authSub = _auth.authStateChanges().listen((user) async {
       if (user != null) {
          await _loadProfile(user.uid);
          _setupListeners(user.uid);
       } else {
          _cleanup();
       }
    });

    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      await _loadProfile(uid);
      _setupListeners(uid);
    } else {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadProfile(String uid) async {
    try {
      final profileDoc = await _db
          .collection('users')
          .doc(uid)
          .collection('profile')
          .doc('current')
          .get();
      if (profileDoc.exists) {
        _profile = WorkoutProfile.fromDoc(profileDoc);
      }
    } catch (e) {
      debugPrint('Erro no init profile: $e');
    }
  }

  /// Conecta o ExerciseProvider para hidratação dos exercícios prescritos.
  /// Deve ser chamado assim que ambos os providers estiverem disponíveis.
  void connectExerciseProvider(ExerciseProvider exerciseProvider) {
    if (_exerciseProvider == exerciseProvider) return;
    _exerciseProvider = exerciseProvider;
    // Re-hidratar se já temos dados carregados
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      _setupListeners(uid);
    }
  }

  ExerciseModel? _resolveExercise(String id) {
    return _exerciseProvider?.getById(id);
  }

  void _setupListeners(String uid) {
    _workoutsSub?.cancel();
    _progressionSub?.cancel();

    _workoutsSub = _db
        .collection('users')
        .doc(uid)
        .collection('generated_workouts')
        .orderBy('generatedAt', descending: true)
        .snapshots()
        .listen((snap) {
      _allWorkouts = snap.docs.map((doc) {
        return GeneratedWorkout.fromMap(doc.data(), _resolveExercise); 
      }).toList();
      _isLoading = false;
      notifyListeners();
    });

    _progressionSub = _db
        .collection('users')
        .doc(uid)
        .collection('progression_state')
        .doc('current')
        .snapshots()
        .listen((snap) {
      if (snap.exists && snap.data() != null) {
        _progressionState = ProgressionState.fromMap(snap.data() ?? {});
        notifyListeners();
      }
    }, onError: (e) => debugPrint('ProgressionSub Error: $e'));
  }

  void _cleanup() {
    _workoutsSub?.cancel();
    _progressionSub?.cancel();
    _profile = null;
    _allWorkouts = [];
    _progressionState = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _workoutsSub?.cancel();
    _progressionSub?.cancel();
    super.dispose();
  }

  Future<void> saveProfile(WorkoutProfile profile) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Usuário não autenticado');

    _isLoading = true;
    notifyListeners();

    try {
      await _db
          .collection('users')
          .doc(uid)
          .collection('profile')
          .doc('current')
          .set({
        ...profile.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
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
    final uid = _auth.currentUser?.uid;
    if (uid == null || _profile == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final engine = WorkoutPrescriptionEngine(_profile!);
      final workoutRaw = engine.generate(_profile!);
      
      final id = _db.collection('users').doc(uid).collection('generated_workouts').doc().id;
      final name = customName ?? 'Treino ${DateTime.now().day}/${DateTime.now().month}';

      // Set all others to inactive if this is the first one, or just set this as active
      final workout = GeneratedWorkout(
        id: id,
        userId: uid,
        name: name,
        splitType: workoutRaw.splitType,
        periodizationModel: workoutRaw.periodizationModel,
        sessions: workoutRaw.sessions,
        mesocycleDurationWeeks: workoutRaw.mesocycleDurationWeeks,
        generatedAt: DateTime.now(),
        isActive: _allWorkouts.isEmpty, // Auto-active if it's the first
      );

      await _db
          .collection('users')
          .doc(uid)
          .collection('generated_workouts')
          .doc(id)
          .set(workout.toMap());

    } catch (e) {
      _error = 'Erro ao gerar treino: $e';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setActiveWorkout(String id) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

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
             generatedAt: w.generatedAt,
             isActive: true,
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
             generatedAt: w.generatedAt,
             isActive: false,
           );
        }
    }
    notifyListeners();

    final batch = _db.batch();
    
    // We only need to update the documents that actually changed
    // But for safety and simplicity, we can update all or just the involved ones
    for (var w in _allWorkouts) {
      final ref = _db.collection('users').doc(uid).collection('generated_workouts').doc(w.id);
      batch.update(ref, {'isActive': w.id == id});
    }

    try {
      await batch.commit();
      debugPrint('Treino $id ativado com sucesso no Firestore.');
    } catch (e) {
      debugPrint('Erro crítico ao ativar treino no Firestore: $e');
      // If it fails, the next snapshot from Firestore will revert the local state
    }
  }

  Future<void> deleteWorkout(String id) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      await _db
          .collection('users')
          .doc(uid)
          .collection('generated_workouts')
          .doc(id)
          .delete();
    } catch (e) {
      _error = 'Erro ao excluir treino: $e';
    } finally {
      notifyListeners();
    }
  }

  Future<void> swapPrescribedExercise(String workoutId, String sessionId, String oldExId, ExerciseModel newEx) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

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
      
      await _db
          .collection('users')
          .doc(uid)
          .collection('generated_workouts')
          .doc(workoutId)
          .set(workout.toMap());

      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao trocar exercício prescrito: $e');
    }
  }
}
