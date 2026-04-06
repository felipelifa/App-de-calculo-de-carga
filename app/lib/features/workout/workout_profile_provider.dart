import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'workout_profile_model.dart';
import 'prescribed_workout_model.dart';
import 'prescription_engine.dart';
import '../exercises/exercise_model.dart';
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
  GeneratedWorkout? _currentWorkout;
  Map<String, dynamic>? _currentWorkoutRaw;
  ProgressionState? _progressionState;
  
  StreamSubscription? _workoutSub;
  StreamSubscription? _progressionSub;
  StreamSubscription? _authSub;

  bool _isLoading = true;
  String? _error;

  WorkoutProfile? get profile => _profile;
  GeneratedWorkout? get currentWorkout => _currentWorkout;
  bool get isLoading => _isLoading;
  ProgressionState? get progressionState => _progressionState;
  String? get error => _error;
  bool get hasProfile => _profile != null;
  bool get hasWorkout => _currentWorkout != null;

  double getLatestWeightForExercise(String exerciseId) {
    if (_progressionState == null) return 0.0;
    final val = _progressionState!.exerciseProgress[exerciseId]?.lastWeightKg;
    return (val as num?)?.toDouble() ?? 0.0;
  }

  Future<void> _init() async {
    _authSub?.cancel();
    _authSub = _auth.authStateChanges().listen((user) {
       if (user != null) {
         _setupListeners(user.uid);
       } else {
         _cleanup();
       }
    });

    // Carga inicial do perfil
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }
    
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
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _setupListeners(String uid) {
    _workoutSub?.cancel();
    _progressionSub?.cancel();

    // Listener para o treino atual (GeneratedWorkout)
    _workoutSub = _db
        .collection('users')
        .doc(uid)
        .collection('generated_workouts')
        .doc('current')
        .snapshots()
        .listen((snap) {
      if (snap.exists && snap.data() != null) {
        _currentWorkoutRaw = snap.data();
        // A hidratação acontecerá quando a UI chamar loadCurrentWorkout
        _isLoading = false;
        notifyListeners();
      } else {
        _currentWorkoutRaw = null;
        _currentWorkout = null;
        _isLoading = false;
        notifyListeners();
      }
    });

    // Listener para as cargas recalculadas (ProgressionState)
    _progressionSub = _db
        .collection('users')
        .doc(uid)
        .collection('progression_state')
        .doc('current')
        .snapshots()
        .listen((snap) {
      if (snap.exists && snap.data() != null) {
        _progressionState = ProgressionState.fromMap(snap.data()!);
        notifyListeners();
      }
    });
  }

  void _cleanup() {
    _workoutSub?.cancel();
    _progressionSub?.cancel();
    _profile = null;
    _currentWorkoutRaw = null;
    _currentWorkout = null;
    _progressionState = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _workoutSub?.cancel();
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

  Future<void> loadCurrentWorkout(ExerciseModel? Function(String) getById) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    // Defer notification to after the current frame to avoid
    // calling notifyListeners() during build
    void _notifyAfter() {
      WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());
    }

    // Se temos dados brutos do listener, hidratamos imediatamente
    if (_currentWorkoutRaw != null) {
      _currentWorkout = GeneratedWorkout.fromMap(_currentWorkoutRaw!, getById);
      _notifyAfter();
      return;
    }

    try {
      final doc = await _db
          .collection('users')
          .doc(uid)
          .collection('generated_workouts')
          .doc('current')
          .get();
      if (doc.exists && doc.data() != null) {
        _currentWorkoutRaw = doc.data();
        _currentWorkout = GeneratedWorkout.fromMap(_currentWorkoutRaw!, getById);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Erro ao carregar workout: $e');
    }
  }

  Future<void> generateAndSaveWorkout([List<ExerciseModel>? _unused]) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || _profile == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final engine = WorkoutPrescriptionEngine(_profile!);
      final workout = engine.generate(_profile!);

      await _db
          .collection('users')
          .doc(uid)
          .collection('generated_workouts')
          .doc('current')
          .set(workout.toMap());

      _currentWorkout = workout;
      _currentWorkoutRaw = workout.toMap();
    } catch (e) {
      _error = 'Erro ao gerar treino: $e';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteCurrentWorkout() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      await _db
          .collection('users')
          .doc(uid)
          .collection('generated_workouts')
          .doc('current')
          .delete();
      _currentWorkout = null;
      _currentWorkoutRaw = null;
    } catch (e) {
      _error = 'Erro ao excluir treino: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
