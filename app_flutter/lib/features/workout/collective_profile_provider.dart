import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'collective_training.dart';
import 'collective_engine.dart';
import 'workout_profile_model.dart';
import 'training_readiness.dart';

/// Provider para treinamento coletivo (dupla/grupo).
/// Salva perfis coletivos e gera sessões usando o CollectiveTrainingEngine.
class CollectiveProfileProvider extends ChangeNotifier {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  CollectiveProfileProvider({FirebaseFirestore? db, FirebaseAuth? auth})
      : _db = db ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  DuoProfile? _currentDuo;
  GroupProfile? _currentGroup;
  List<CollectiveSessionBlock>? _currentBlocks;
  bool _isLoading = false;
  String? _error;

  DuoProfile? get currentDuo => _currentDuo;
  GroupProfile? get currentGroup => _currentGroup;
  List<CollectiveSessionBlock>? get currentBlocks => _currentBlocks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ── Dupla ──────────────────────────────────────────────

  Future<void> saveDuoProfile(DuoProfile duo) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _db.collection('users/$uid/collective_profiles').doc('current_duo').set({
        'type': 'duo',
        ...duo.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      _currentDuo = duo;
    } catch (e) {
      _error = 'Erro ao salvar perfil da dupla: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> generateDuoSession(DuoProfile duo, {int sessionDurationMinutes = 60}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final engine = CollectiveTrainingEngine();
      _currentBlocks = engine.buildDuoSession(
        duo: duo,
        sessionDurationMinutes: sessionDurationMinutes,
      );
      _currentDuo = duo;

      // Salvar no Firestore
      final uid = _auth.currentUser?.uid;
      if (uid != null) {
        await _db.collection('users/$uid/collective_profiles').doc('current_duo').set({
          'type': 'duo',
          ...duo.toMap(),
          'blocks': _currentBlocks!.map((b) => b.toMap()).toList(),
          'generatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      _error = 'Erro ao gerar sessão da dupla: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Grupo ──────────────────────────────────────────────

  Future<void> saveGroupProfile(GroupProfile group) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _db.collection('users/$uid/collective_profiles').doc('current_group').set({
        'type': 'group',
        ...group.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      _currentGroup = group;
    } catch (e) {
      _error = 'Erro ao salvar perfil do grupo: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> generateGroupSession(GroupProfile group) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final engine = CollectiveTrainingEngine();
      _currentBlocks = engine.buildGroupSession(group: group);
      _currentGroup = group;

      // Salvar no Firestore
      final uid = _auth.currentUser?.uid;
      if (uid != null) {
        await _db.collection('users/$uid/collective_profiles').doc('current_group').set({
          'type': 'group',
          ...group.toMap(),
          'blocks': _currentBlocks!.map((b) => b.toMap()).toList(),
          'generatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      _error = 'Erro ao gerar sessão do grupo: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Carregar perfis salvos ─────────────────────────────

  Future<void> loadSavedProfiles() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      final duoDoc = await _db.collection('users/$uid/collective_profiles').doc('current_duo').get();
      if (duoDoc.exists && duoDoc.data() != null) {
        final data = duoDoc.data()!;
        if (data['type'] == 'duo') {
          _currentDuo = DuoProfile.fromMap(data);
          if (data['blocks'] != null) {
            _currentBlocks = (data['blocks'] as List)
                .map((b) => CollectiveSessionBlock.fromMap(b as Map<String, dynamic>))
                .toList();
          }
        }
      }

      final groupDoc = await _db.collection('users/$uid/collective_profiles').doc('current_group').get();
      if (groupDoc.exists && groupDoc.data() != null) {
        final data = groupDoc.data()!;
        if (data['type'] == 'group') {
          _currentGroup = GroupProfile.fromMap(data);
        }
      }
    } catch (e) {
      debugPrint('Erro ao carregar perfis coletivos: $e');
    }

    notifyListeners();
  }

  // ── Converter para WorkoutProfile compatível ───────────

  /// Converte ParticipantProfile para WorkoutProfile que o motor existente entende.
  static WorkoutProfile participantToWorkoutProfile(
    ParticipantProfile participant, {
    required String uid,
  }) {
    return WorkoutProfile(
      uid: uid,
      age: participant.age,
      biologicalSex: participant.biologicalSex,
      weightKg: participant.weightKg,
      heightCm: participant.heightCm,
      experienceLevel: participant.experienceLevel,
      trainingAge: participant.trainingAge,
      bodyFatCategory: 'medium',
      primaryGoal: participant.primaryGoal,
      sportSubType: 'none',
      trainingModality: 'none',
      availableDaysPerWeek: 3,
      sessionDurationMinutes: participant.sessionDurationMinutes,
      preferredStyle: 'compound_focus',
      sleepQuality: participant.sleepQuality,
      stressLevel: participant.stressLevel,
      priorityMuscles: const [],
      environment: participant.environment,
      availableEquipment: participant.availableEquipment,
      dislikedExercises: const [],
      favoriteExercises: const [],
      healthRestrictions: participant.healthRestrictions,
      lifeLoad: const LifeLoad(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
