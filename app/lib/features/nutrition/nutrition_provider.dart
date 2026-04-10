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
  
  bool _isTrainingDay = false;
  int? _postWorkoutBonusKcal;
  double _adherenceScore = 1.0;

  StreamSubscription? _mealsSub;

  NutritionProvider({FirebaseFirestore? db, FirebaseAuth? auth})
      : _db = db ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  // --- Getters ---
  NutritionProfile? get profile => _profile;
  List<MealEntry> get todayMeals => _todayMeals;
  bool get isLoading => _isLoading;
  bool get isTrainingDay => _isTrainingDay;
  int? get postWorkoutBonusKcal => _postWorkoutBonusKcal;
  double get adherenceScore => _adherenceScore;

  // Cálculos diários
  int get targetCalories => (_profile?.targetCalories ?? 0) + (_postWorkoutBonusKcal ?? 0);
  int get consumedCalories => _todayMeals.fold(0, (sum, m) => sum + m.calories.round());
  int get remainingCalories => targetCalories - consumedCalories;

  double get consumedProtein => _todayMeals.fold(0.0, (sum, m) => sum + m.protein);
  double get consumedCarb => _todayMeals.fold(0.0, (sum, m) => sum + m.carb);
  double get consumedFat => _todayMeals.fold(0.0, (sum, m) => sum + m.fat);

  // Metas do dia (com adaptações de Carb Cycling e Bônus)
  double get activeTargetProtein {
    if (_profile == null) return 0;
    double p = _profile!.targetProtein;
    if (_postWorkoutBonusKcal == 250) p += 15;
    else if (_postWorkoutBonusKcal == 150) p += 10;
    return p;
  }

  double get activeTargetCarb {
    if (_profile == null) return 0;
    double c = _profile!.targetCarb;
    if (_profile!.carbCyclingEnabled) {
      c = NutritionEngine.applyCarbCycling(_profile!, _isTrainingDay)['carb'];
    }
    if (_postWorkoutBonusKcal == 250) c += 50;
    else if (_postWorkoutBonusKcal == 150) c += 30;
    else if (_postWorkoutBonusKcal == 100) c += 20;
    return c;
  }

  double get activeTargetFat {
    if (_profile == null) return 0;
    double f = _profile!.targetFat;
    if (_profile!.carbCyclingEnabled) {
      f = NutritionEngine.applyCarbCycling(_profile!, _isTrainingDay)['fat'];
    }
    return f;
  }

  // --- Actions ---

  /// Inicia o perfil nutricional a partir do WorkoutProfile.
  /// (Geralmente chamado no login ou ao re-calcular metas)
  Future<void> initFromProfile(WorkoutProfile wp) async {
    _isLoading = true;
    notifyListeners();

    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      _isLoading = false;
      return;
    }

    // Tenta carregar config salva
    final doc = await _db.doc('users/$uid/nutrition/settings').get();
    if (doc.exists) {
       // Atualiza a meta caso o peso/dados mudaram, mas preserva toggles
       final savedMap = doc.data()!;
       _profile = NutritionEngine.calculateProfile(
         wp,
         macroMode: savedMap['macroMode'] ?? 'automatic',
         dynamicAdaptationEnabled: savedMap['dynamicAdaptationEnabled'] ?? false,
         carbCyclingEnabled: savedMap['carbCyclingEnabled'] ?? false,
       );
    } else {
       // Cria default e salva
       _profile = NutritionEngine.calculateProfile(wp);
       await saveSettings();
    }

    // Carrega dados do dia atual
    await loadToday();
    
    // (Opcional) calcular adherenceScore puxando summaries dos últimos 7 dias

    _isLoading = false;
    notifyListeners();
  }

  Future<void> saveSettings() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || _profile == null) return;
    await _db.doc('users/$uid/nutrition/settings').set(_profile!.toMap(), SetOptions(merge: true));
  }

  /// Chamado pelo WorkoutProvider quando finaliza uma sessão
  void applyPostWorkoutBonus({
    required int durationMinutes,
    required int exerciseCount,
    required double totalVolume,
  }) {
    if (_profile == null || !_profile!.dynamicAdaptationEnabled) return;

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
    if (_profile == null) return;
    _profile = _profile!.copyWith(dynamicAdaptationEnabled: value);
    await saveSettings();
    notifyListeners();
  }

  Future<void> toggleCarbCycling(bool value) async {
    if (_profile == null) return;
    _profile = _profile!.copyWith(carbCyclingEnabled: value);
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
      _todayMeals = snap.docs.map((d) => MealEntry.fromMap(d.data(), d.id)).toList();
      notifyListeners();
      
      // Auto-update adherence / summary logic aqui no futuro
    });
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
    _mealsSub?.cancel();
    super.dispose();
  }
}
