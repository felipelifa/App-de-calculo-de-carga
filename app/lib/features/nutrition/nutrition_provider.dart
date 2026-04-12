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
  Map<String, List<MealEntry>> _weeklyLogs = {}; // Data -> Refeições
  
  bool _isLoading = false;
  bool _isDisposed = false;

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

  // --- Getters Adaptativos ---
  NutritionProfile? get profile => _profile;
  List<MealEntry> get todayMeals => _todayMeals;
  bool get isLoading => _isLoading;

  int _selectedWeekday = DateTime.now().weekday;
  int get selectedWeekday => _selectedWeekday;

  void selectWeekday(int day) {
    _selectedWeekday = day;
    loadSelectedDay();
    notifyListeners();
  }

  /// Meta de calorias para o dia selecionado
  int get targetCalories {
    if (_profile == null) return 2000;
    return _profile!.weeklyGoals[_selectedWeekday]?.calories ?? _profile!.targetCalories;
  }

  double get targetProtein => _profile?.weeklyGoals[_selectedWeekday]?.protein ?? (_profile?.targetProtein ?? 150);
  double get targetCarb => _profile?.weeklyGoals[_selectedWeekday]?.carb ?? (_profile?.targetCarb ?? 200);
  double get targetFat => _profile?.weeklyGoals[_selectedWeekday]?.fat ?? (_profile?.targetFat ?? 66);

  List<MealEntry> _selectedDayMeals = [];
  List<MealEntry> get selectedDayMeals => _selectedWeekday == DateTime.now().weekday ? _todayMeals : _selectedDayMeals;

  int get consumedCalories => selectedDayMeals.fold(0, (sum, m) => sum + m.calories.round());
  int get remainingCalories => targetCalories - consumedCalories;

  double get consumedProtein => selectedDayMeals.fold(0, (sum, m) => sum + m.protein);
  double get consumedCarb => selectedDayMeals.fold(0, (sum, m) => sum + m.carb);
  double get consumedFat => selectedDayMeals.fold(0, (sum, m) => sum + m.fat);

  // --- Atributos de Monitoramento ---
  double get adherenceScore => _profile?.adherenceScore ?? 1.0;
  int get fatigueLevel => _profile?.nutritionalFatigueLevel ?? 0;

  // --- Actions ---

  Future<void> initFromProfile(WorkoutProfile wp) async {
    if (_isLoading) return;
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;

      final settingsRef = _db.doc('users/$uid/nutrition/settings');
      final doc = await settingsRef.get();
      
      if (doc.exists) {
        _profile = NutritionProfile.fromMap(doc.data());
      } else {
        // Gera o perfil inicial com a Bio-Gestão 7.0
        _profile = NutritionEngine.calculateProfile(wp);
        await saveSettings();
      }

      await loadToday();
    } catch (e) {
      _lastError = 'Erro ao carregar nutrição: $e';
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
    await _db.doc('users/$uid/nutrition/settings').set(_profile!.toMap(), SetOptions(merge: true));
  }

  /// Registra uma refeição e aciona a recalibração automática do orçamento
  Future<void> addMeal(MealEntry meal) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || _profile == null) return;

    final docRef = _db.collection('users/$uid/nutrition/logs/${_todayFormat(DateTime.now())}/meals').doc();
    await docRef.set(meal.copyWith(id: docRef.id).toMap());
    
    // Recalibra o orçamento semanal com base no novo consumo
    _triggerRecalibration();
  }

  Future<void> removeMeal(String mealId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _db.doc('users/$uid/nutrition/logs/${_todayFormat(DateTime.now())}/meals/$mealId').delete();
    _triggerRecalibration();
  }

  /// Motor de Recalibração: Ajusta dias futuros se houver desvio hoje
  void _triggerRecalibration() {
    if (_profile == null) return;
    
    final updatedProfile = NutritionEngine.recalibrateRemainingBudget(
      _profile!,
      todayWeekday: todayWeekday,
      actualCaloriesToday: consumedCalories,
    );
    
    if (updatedProfile != _profile) {
      _profile = updatedProfile;
      saveSettings();
      notifyListeners();
    }
  }

  /// Permite edição manual de um dia específico (respeita autonomia do usuário)
  void updateDailyManualGoal(int weekday, DailyNutritionalGoal newGoal) {
    if (_profile == null) return;
    
    final updatedGoals = Map<int, DailyNutritionalGoal>.from(_profile!.weeklyGoals);
    updatedGoals[weekday] = newGoal.copyWith(isManual: true);
    
    _profile = _profile!.copyWith(weeklyGoals: updatedGoals);
    saveSettings();
    notifyListeners();
  }

  Future<void> loadSelectedDay() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    // Calcula a data baseada no dia selecionado (considerando a semana atual)
    final now = DateTime.now();
    final firstDayOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final targetDate = firstDayOfWeek.add(Duration(days: _selectedWeekday - 1));
    final dateKey = _todayFormat(targetDate);

    if (_selectedWeekday == now.weekday) {
        await loadToday();
        return;
    }

    try {
      final snap = await _db
          .collection('users/$uid/nutrition/logs/$dateKey/meals')
          .get();
      _selectedDayMeals = snap.docs.map((d) => MealEntry.fromMap(d.data(), d.id)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading day $dateKey: $e');
    }
  }

  // --- Helpers e Streams ---

  String _todayFormat(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  Future<void> loadToday() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    _mealsSub?.cancel();
    _mealsSub = _db
        .collection('users/$uid/nutrition/logs/${_todayFormat(DateTime.now())}/meals')
        .snapshots()
        .listen((snap) {
      _todayMeals = snap.docs.map((d) => MealEntry.fromMap(d.data(), d.id)).toList();
      if (!_isDisposed) notifyListeners();
    });
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
