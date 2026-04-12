import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../workout/workout_profile_model.dart';
import 'nutrition_profile_model.dart';
import 'meal_model.dart';
import 'nutrition_engine.dart';

class NutritionProvider extends ChangeNotifier {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  NutritionProfile? _profile;
  List<MealEntry> _todayMeals = [];
  bool _isLoading = false;
  bool _isDisposed = false;

  bool _isTrainingDay = false;
  int? _postWorkoutBonusKcal;
  double _adherenceScore = 1.0;

  String? _lastError;
  String? get lastError => _lastError;

  StreamSubscription? _mealsSub;

  NutritionProvider({FirebaseFirestore? db, FirebaseAuth? auth})
      : _db = db ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance {
    _init();
  }

  void _init() {
    _auth.authStateChanges().listen((user) {
      if (_isDisposed) return;
      if (user == null) {
        _profile = null;
        _todayMeals = [];
        _mealsSub?.cancel();
        _mealsSub = null;
        notifyListeners();
      }
    });
  }

  // --- Getters ---
  NutritionProfile? get profile => _profile;
  List<MealEntry> get todayMeals => _todayMeals;
  bool get isLoading => _isLoading;
  bool get isTrainingDay => _isTrainingDay;
  int? get postWorkoutBonusKcal => _postWorkoutBonusKcal;
  double get adherenceScore => _adherenceScore;

  // Cálculos diários
  int get targetCalories => (_profile?.targetCalories ?? 0) + (_postWorkoutBonusKcal ?? 0);
  int get consumedCalories {
    try {
      return _todayMeals.fold(0, (sum, m) => sum + m.calories.round());
    } catch (_) {
      return 0;
    }
  }
  int get remainingCalories => targetCalories - consumedCalories;

  double get consumedProtein {
    try {
      return _todayMeals.fold(0.0, (sum, m) => sum + m.protein);
    } catch (_) {
      return 0.0;
    }
  }

  double get consumedCarb {
    try {
      return _todayMeals.fold(0.0, (sum, m) => sum + m.carb);
    } catch (_) {
      return 0.0;
    }
  }

  double get consumedFat {
    try {
      return _todayMeals.fold(0.0, (sum, m) => sum + m.fat);
    } catch (_) {
      return 0.0;
    }
  }

  // Metas do dia (com adaptações de Carb Cycling e Bônus)
  double get activeTargetProtein {
    final pProfile = _profile;
    if (pProfile == null) return 0;
    double p = pProfile.targetProtein;
    if (_postWorkoutBonusKcal == 250) p += 15;
    else if (_postWorkoutBonusKcal == 150) p += 10;
    return p;
  }

  double get activeTargetCarb {
    final pProfile = _profile;
    if (pProfile == null) return 0;
    double c = pProfile.targetCarb;
    if (pProfile.carbCyclingEnabled) {
      c = NutritionEngine.applyCarbCycling(pProfile, _isTrainingDay)['carb'] as double? ?? c;
    }
    if (_postWorkoutBonusKcal == 250) c += 50;
    else if (_postWorkoutBonusKcal == 150) c += 30;
    else if (_postWorkoutBonusKcal == 100) c += 20;
    return c;
  }

  double get activeTargetFat {
    final pProfile = _profile;
    if (pProfile == null) return 0;
    double f = pProfile.targetFat;
    if (pProfile.carbCyclingEnabled) {
      f = NutritionEngine.applyCarbCycling(pProfile, _isTrainingDay)['fat'] as double? ?? f;
    }
    return f;
  }

  // --- Actions ---

  /// Inicia o perfil nutricional a partir do WorkoutProfile.
  Future<void> initFromProfile(WorkoutProfile wp) async {
    if (_isLoading) return;
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) {
        _lastError = 'Usuário não autenticado';
        return;
      }

      // Tenta carregar config salva
      final doc = await _db.doc('users/$uid/nutrition/settings').get();
      if (doc.exists) {
        final savedMap = doc.data() ?? {};
        _profile = NutritionEngine.calculateProfile(
          wp,
          macroMode: savedMap['macroMode'] as String? ?? 'automatic',
          dynamicAdaptationEnabled: savedMap['dynamicAdaptationEnabled'] as bool? ?? false,
          carbCyclingEnabled: savedMap['carbCyclingEnabled'] as bool? ?? false,
        );
      } else {
        _profile = NutritionEngine.calculateProfile(wp);
        await saveSettings();
      }

      if (_mealsSub == null) {
        await loadToday();
      }
    } catch (e) {
      debugPrint('Error initializing nutrition: $e');
      _lastError = e.toString();
    } finally {
      if (!_isDisposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> saveSettings() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || _profile == null) return;
    final prof = _profile;
    if (prof == null) return;
    await _db.doc('users/$uid/nutrition/settings').set(prof.toMap(), SetOptions(merge: true));
  }

  /// Chamado pelo WorkoutProvider quando finaliza uma sessão
  void applyPostWorkoutBonus({
    required int durationMinutes,
    required int exerciseCount,
    required double totalVolume,
  }) {
    final p = _profile;
    if (p == null || !p.dynamicAdaptationEnabled) return;

    _isTrainingDay = true;
    _postWorkoutBonusKcal = NutritionEngine.calculatePostWorkoutBonus(
      durationMinutes: durationMinutes,
      exerciseCount: exerciseCount,
      totalVolume: totalVolume,
    );
    notifyListeners();
  }

  /// Controle de Features Adaptativas
  Future<void> toggleDynamicAdaptation(bool value) async {
    final p = _profile;
    if (p == null) return;
    _profile = p.copyWith(dynamicAdaptationEnabled: value);
    await saveSettings();
    notifyListeners();
  }

  Future<void> toggleCarbCycling(bool value) async {
    final p = _profile;
    if (p == null) return;
    _profile = p.copyWith(carbCyclingEnabled: value);
    await saveSettings();
    notifyListeners();
  }

  Future<void> updateProfile(NutritionProfile newProfile) async {
    _profile = newProfile;
    await saveSettings();
    notifyListeners();
  }

  // --- Meals Logging (Dia Atual) ---

  String get _todayKey => DateFormat('yyyy-MM-dd').format(DateTime.now());

  Future<void> loadToday() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    _mealsSub?.cancel();
    _mealsSub = _db
        .collection('users/$uid/nutrition/logs/$_todayKey/meals')
        .orderBy('loggedAt', descending: true)
        .snapshots()
        .listen((snap) {
      _todayMeals = snap.docs.map((d) {
        final data = d.data();
        return MealEntry.fromMap(data, d.id);
      }).toList();
      if (!_isDisposed) notifyListeners();
    }, onError: (e) => debugPrint('Error loading meals: $e'));
  }

  Future<void> addMeal(MealEntry meal) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final docRef = _db.collection('users/$uid/nutrition/logs/$_todayKey/meals').doc();
    final newMeal = MealEntry(
      id: docRef.id,
      foodId: meal.foodId,
      foodName: meal.foodName,
      portionG: meal.portionG,
      calories: meal.calories,
      protein: meal.protein,
      carb: meal.carb,
      fat: meal.fat,
      mealType: meal.mealType,
      loggedAt: meal.loggedAt,
    );
    await docRef.set(newMeal.toMap());
  }

  Future<void> removeMeal(String mealId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _db.doc('users/$uid/nutrition/logs/$_todayKey/meals/$mealId').delete();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _mealsSub?.cancel();
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }
}
