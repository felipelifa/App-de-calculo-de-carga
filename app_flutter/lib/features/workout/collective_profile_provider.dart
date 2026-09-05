import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'collective_training.dart';
import 'collective_engine.dart';
import 'workout_profile_model.dart';
import 'training_readiness.dart';

class CollectiveProfileProvider extends ChangeNotifier {
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

  Future<void> saveDuoProfile(DuoProfile duo) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'type': 'duo',
        ...duo.toMap(),
        'createdAt': DateTime.now().toIso8601String(),
      };
      await prefs.setString('collective_duo', jsonEncode(data));
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

      final prefs = await SharedPreferences.getInstance();
      final data = {
        'type': 'duo',
        ...duo.toMap(),
        'blocks': _currentBlocks!.map((b) => b.toMap()).toList(),
        'generatedAt': DateTime.now().toIso8601String(),
      };
      await prefs.setString('collective_duo', jsonEncode(data));
    } catch (e) {
      _error = 'Erro ao gerar sessão da dupla: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveGroupProfile(GroupProfile group) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'type': 'group',
        ...group.toMap(),
        'createdAt': DateTime.now().toIso8601String(),
      };
      await prefs.setString('collective_group', jsonEncode(data));
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

      final prefs = await SharedPreferences.getInstance();
      final data = {
        'type': 'group',
        ...group.toMap(),
        'blocks': _currentBlocks!.map((b) => b.toMap()).toList(),
        'generatedAt': DateTime.now().toIso8601String(),
      };
      await prefs.setString('collective_group', jsonEncode(data));
    } catch (e) {
      _error = 'Erro ao gerar sessão do grupo: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadSavedProfiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final duoJson = prefs.getString('collective_duo');
      if (duoJson != null) {
        final data = jsonDecode(duoJson) as Map<String, dynamic>;
        if (data['type'] == 'duo') {
          _currentDuo = DuoProfile.fromMap(data);
          if (data['blocks'] != null) {
            _currentBlocks = (data['blocks'] as List)
                .map((b) => CollectiveSessionBlock.fromMap(b as Map<String, dynamic>))
                .toList();
          }
        }
      }

      final groupJson = prefs.getString('collective_group');
      if (groupJson != null) {
        final data = jsonDecode(groupJson) as Map<String, dynamic>;
        if (data['type'] == 'group') {
          _currentGroup = GroupProfile.fromMap(data);
        }
      }
    } catch (e) {
      debugPrint('Erro ao carregar perfis coletivos: $e');
    }

    notifyListeners();
  }

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
