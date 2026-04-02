import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  ProgressionState? _progressionState;
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
    return _progressionState!.exerciseProgress[exerciseId]?.lastWeightKg ?? 0.0;
  }

  Future<void> _init() async {
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

      // NOVO: Carregar treino e progressão imediatamente no init
      final workoutDoc = await _db
          .collection('users')
          .doc(uid)
          .collection('generated_workouts')
          .doc('current')
          .get();
      
      if (workoutDoc.exists && workoutDoc.data() != null) {
        // Nota: Precisamos do ExerciseProvider para o getById, 
        // mas aqui no init podemos carregar o mapa bruto e converter depois 
        // ou garantir que as telas chamem o loadCurrentWorkout.
        // Como o loadCurrentWorkout já existe, vamos apenas disparar ele aqui 
        // se as dependências permitirem, ou garantir que ele seja resiliente.
      }

      final progDoc = await _db
          .collection('users')
          .doc(uid)
          .collection('progression_state')
          .doc('current')
          .get();
      if (progDoc.exists && progDoc.data() != null) {
        _progressionState = ProgressionState.fromMap(progDoc.data()!);
      }

    } catch (e) {
      _error = 'Erro ao carregar dados: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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

  /// Gera e salva o treino. A biblioteca de exercícios agora é interna
  /// ao motor — não precisa ser passada externamente.
  Future<void> generateAndSaveWorkout([List<ExerciseModel>? _unused]) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || _profile == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      // Motor agora recebe o profile e usa a biblioteca interna
      final engine = WorkoutPrescriptionEngine(_profile!);
      final workout = engine.generate(_profile!);

      await _db
          .collection('users')
          .doc(uid)
          .collection('generated_workouts')
          .doc('current')
          .set(workout.toMap());

      _currentWorkout = workout;
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
    } catch (e) {
      _error = 'Erro ao excluir treino: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadCurrentWorkout(ExerciseModel? Function(String) getById) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    try {
      final doc = await _db
          .collection('users')
          .doc(uid)
          .collection('generated_workouts')
          .doc('current')
          .get();
      if (doc.exists && doc.data() != null) {
        _currentWorkout = GeneratedWorkout.fromMap(doc.data()!, getById);
        
        // Também carrega o estado de progressão para ter as cargas atuais
        final progDoc = await _db
            .collection('users')
            .doc(uid)
            .collection('progression_state')
            .doc('current')
            .get();
        if (progDoc.exists && progDoc.data() != null) {
          _progressionState = ProgressionState.fromMap(progDoc.data()!);
        }
        
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Erro ao carregar workout: $e');
    }
  }
}
