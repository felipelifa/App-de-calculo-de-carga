import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'workout_profile_model.dart';
import 'prescribed_workout_model.dart';
import 'prescription_engine.dart';
import '../exercises/exercise_model.dart';

// ─────────────────────────────────────────────
// Provider do Perfil do Usuário (Anamnese)
// ─────────────────────────────────────────────

class WorkoutProfileProvider extends ChangeNotifier {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  WorkoutProfileProvider({FirebaseFirestore? db, FirebaseAuth? auth})
      : _db = db ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance {
    _init();
  }

  // ── State ─────────────────────────────────
  WorkoutProfile? _profile;
  GeneratedWorkout? _currentWorkout;
  bool _isLoading = true;
  String? _error;

  // ── Getters ───────────────────────────────
  WorkoutProfile? get profile => _profile;
  GeneratedWorkout? get currentWorkout => _currentWorkout;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasProfile => _profile != null;
  bool get hasWorkout => _currentWorkout != null;

  // ── Init ──────────────────────────────────
  Future<void> _init() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final doc = await _db.collection('users').doc(uid).collection('profile').doc('current').get();
      if (doc.exists) {
        _profile = WorkoutProfile.fromDoc(doc);
      }
      
      // Load workout if exists
      // Wait, we can't instantiate it safely without the library, so we will store raw data for now?
      // Actually we must fetch library first. So this requires the exerciseProvider to be ready...
      // Let's just create a separate method to loadWorkout(List<ExerciseModel> lib) since provider injection here is tricky during init.
    } catch (e) {
      _error = 'Erro ao carregar perfil: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Actions ───────────────────────────────
  
  Future<void> saveProfile(WorkoutProfile profile) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Usuário não autenticado');

    _isLoading = true;
    notifyListeners();

    try {
      final docRef = _db.collection('users').doc(uid).collection('profile').doc('current');
      await docRef.set({
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

  Future<void> generateAndSaveWorkout(List<ExerciseModel> library) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || _profile == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final engine = WorkoutPrescriptionEngine(library);
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
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Erro ao carregar workout: $e');
    }
  }
}
