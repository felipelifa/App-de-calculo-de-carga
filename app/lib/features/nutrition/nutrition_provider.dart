import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../workout/workout_profile_model.dart';
import 'nutrition_profile_model.dart';
import 'meal_model.dart';
import 'food_model.dart';
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

  // Aliases para compatibilidade com Dashboard
  double get activeTargetProtein => targetProtein;
  double get activeTargetCarb => targetCarb;
  double get activeTargetFat => targetFat;

  bool get isCaloriesAdjusted => _profile != null && targetCalories != _profile!.targetCalories;
  bool get isProteinAdjusted => _profile != null && (targetProtein - _profile!.targetProtein).abs() > 1.0;
  bool get isCarbAdjusted => _profile != null && (targetCarb - _profile!.targetCarb).abs() > 1.0;
  bool get isFatAdjusted => _profile != null && (targetFat - _profile!.targetFat).abs() > 1.0;

  String get currentGoalLabel => _profile?.weeklyGoals[_selectedWeekday]?.label ?? 'Normal';

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

  // --- Hidratação Inteligente ---
  int get waterTarget => 2500; // Valor padrão, pode ser calculado depois
  int get waterConsumed => _profile?.dailyWater[DateTime.now().weekday] ?? 0;

  String get smartInsight {
    if (_profile == null) return "Configure seu perfil para receber orientações.";
    final goal = _profile!.weeklyGoals[_selectedWeekday];
    if (goal == null) return "Analisando dados do dia...";

    if (goal.isManual) return "Dia com meta manual definida por você. Bio-Gestão parcial.";
    
    if (goal.label.contains('TMB')) {
      return "Meta travada no seu metabolismo basal (TMB) por segurança. Evite mais cortes.";
    }
    
    if (targetCalories > _profile!.targetCalories) {
      return "Sua meta está aumentada hoje (+${targetCalories - _profile!.targetCalories}kcal) para compensar treinos ou cortes anteriores.";
    }

    if (targetCalories < _profile!.targetCalories) {
      return "Meta reduzida (-${_profile!.targetCalories - targetCalories}kcal) para manter o déficit semanal ou compensar o dia anterior.";
    }

    return "Você está no caminho certo! Mantenha a meta para atingir seu objetivo.";
  }

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
      todayWeekday: DateTime.now().weekday,
      actualCaloriesToday: consumedCalories,
    );
    
    if (updatedProfile != _profile) {
      _profile = updatedProfile;
      saveSettings();
      notifyListeners();
    }
  }

  Future<void> updateProfile(NutritionProfile newProfile) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    
    _profile = newProfile;
    await saveSettings();
    notifyListeners();
  }

  /// Bônus Pós-Treino: Reajusta a meta do dia com base no esforço real
  void applyPostWorkoutBonus({
    required int durationMinutes,
    required int exerciseCount,
    required double totalVolume,
  }) {
    if (_profile == null || !_profile!.dynamicAdaptationEnabled) return;

    // Heurística de Gasto Calórico Adicional (Estimativa conservadora)
    // 5 kcal por minuto + bônus por volume (50 kcal por 1000kg)
    int bonusCals = (durationMinutes * 5) + (totalVolume / 1000 * 50).round();
    
    if (bonusCals <= 0) return;

    final todayWeekday = DateTime.now().weekday;
    final currentGoal = _profile!.weeklyGoals[todayWeekday];
    if (currentGoal == null) return;

    // Adiciona o bônus majoritariamente em carboidratos (combustível glicolítico)
    double extraCarb = bonusCals / 4.0;
    
    final updatedGoal = currentGoal.copyWith(
      calories: currentGoal.calories + bonusCals,
      carb: currentGoal.carb + extraCarb,
      label: 'Treino Concluído (+${bonusCals}kcal)',
    );

    updateDailyManualGoal(todayWeekday, updatedGoal);
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

  /// Copia refeições de uma data específica para a data selecionada
  Future<void> copyMealFromPreviousDay(String mealType) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || _profile == null) return;

    // Busca o dia anterior (ou selecionado - 1)
    final now = DateTime.now();
    final firstDayOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final prevDate = firstDayOfWeek.add(Duration(days: _selectedWeekday - 2));
    final prevDateKey = _todayFormat(prevDate);
    final targetDateKey = _todayFormat(firstDayOfWeek.add(Duration(days: _selectedWeekday - 1)));

    try {
      final snap = await _db.collection('users/$uid/nutrition/logs/$prevDateKey/meals')
          .where('mealType', isEqualTo: mealType)
          .get();
          
      if (snap.docs.isEmpty) return;

      final batch = _db.batch();
      for (var doc in snap.docs) {
        final newRef = _db.collection('users/$uid/nutrition/logs/$targetDateKey/meals').doc();
        final data = doc.data();
        data['id'] = newRef.id;
        batch.set(newRef, data);
      }

      await batch.commit();
      await loadSelectedDay();
      _triggerRecalibration();
    } catch (e) {
      debugPrint('Erro ao copiar refeição: $e');
    }
  }

  /// Gerenciamento de Alimentos Favoritos
  Future<void> toggleFavoriteFood(FoodModel food) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final docRef = _db.collection('users/$uid/nutrition/favorite_foods').doc(food.id);
    final doc = await docRef.get();

    if (doc.exists) {
      await docRef.delete();
    } else {
      await docRef.set(food.toMap());
    }
    _favoriteFoodsIds.remove(food.id);
    if (!doc.exists) _favoriteFoodsIds.add(food.id);
    notifyListeners();
  }

  final Set<String> _favoriteFoodsIds = {};
  bool isFoodFavorite(String id) => _favoriteFoodsIds.contains(id);

  Future<void> loadFavorites() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final snap = await _db.collection('users/$uid/nutrition/favorite_foods').get();
    _favoriteFoodsIds.clear();
    for (var d in snap.docs) {
      _favoriteFoodsIds.add(d.id);
    }
    notifyListeners();
  }

  /// Adiciona água ao registro diário
  Future<void> addWater(int ml) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || _profile == null) return;

    final today = DateTime.now().weekday;
    final currentWater = _profile!.dailyWater[today] ?? 0;
    
    final updatedWater = Map<int, int>.from(_profile!.dailyWater);
    updatedWater[today] = currentWater + ml;

    _profile = _profile!.copyWith(dailyWater: updatedWater);
    await saveSettings();
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
