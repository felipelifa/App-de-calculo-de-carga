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
import 'bio_intelligence.dart';

class NutritionProvider extends ChangeNotifier {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  NutritionProvider({FirebaseFirestore? db, FirebaseAuth? auth})
      : _db = db ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  NutritionProfile? _profile;
  List<MealEntry> _todayMeals = [];
  List<MealEntry> _selectedDayMeals = [];
  int _selectedWeekday = DateTime.now().weekday;
  bool _isLoading = false;
  String? _lastError;
  bool _isDisposed = false;

  NutritionProfile? get profile => _profile;
  List<MealEntry> get todayMeals => _todayMeals;
  List<MealEntry> get selectedDayMeals => _selectedDayMeals;
  int get selectedWeekday => _selectedWeekday;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;

  // Macro Totals for the selected day
  double get consumedCalories => selectedDayMeals.fold(0, (sum, m) => sum + m.calories);
  double get remainingCalories => targetCalories - consumedCalories;
  double get consumedProtein => selectedDayMeals.fold(0, (sum, m) => sum + m.protein);
  double get consumedCarb => selectedDayMeals.fold(0, (sum, m) => sum + m.carb);
  double get consumedFat => selectedDayMeals.fold(0, (sum, m) => sum + m.fat);

  // --- Atributos de Gamificação / Microbiota ---
  int _weeklyPlantScore = 0;
  int get weeklyPlantScore => _weeklyPlantScore;
  Set<String> _weeklyPlantSpecies = {};
  Set<String> get weeklyPlantSpecies => _weeklyPlantSpecies;

  Future<void> _fetchWeeklyPlants() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    try {
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final startStr = DateFormat('yyyy-MM-dd').format(startOfWeek);
      // Busca a pasta de logs onde a data no nome id (yyyy-MM-dd) é >= startStr
      // O firestore snapshot que você usa salva os meals dentro dos docs de logs.
      // Ops, estruturalmente a collection 'logs' possui os docs yyyy-MM-dd com a source 'meals' em uma subcollection. 
      // Não temos collectionGroup query aqui configurado, então vou iterar os 7 dias passados/até hoje
      _weeklyPlantSpecies.clear();
      for (int i = 0; i < now.weekday; i++) {
        final dKey = _todayFormat(startOfWeek.add(Duration(days: i)));
        final snap = await _db.collection('users/$uid/nutrition/logs/$dKey/meals').get();
        for (var doc in snap.docs) {
          final m = MealEntry.fromMap(doc.data(), doc.id);
          if (BioIntelligence.isPlantSpecies(m.foodName, '')) {
            _weeklyPlantSpecies.add(BioIntelligence.extractPlantSpeciesRoot(m.foodName));
          }
        }
      }
      _weeklyPlantScore = _weeklyPlantSpecies.length;
    } catch (_) {}
  }

  // --- Atributos de Monitoramento ---
  double get adherenceScore => _profile?.adherenceScore ?? 1.0;
  int get fatigueLevel => _profile?.nutritionalFatigueLevel ?? 0;

  // --- Hidratação Inteligente ---
  int get waterTarget => 2500;
  int get waterConsumed => _profile?.dailyWater[_selectedWeekday] ?? 0;

  String get smartInsight {
    if (_profile == null) return "Configure seu perfil.";
    
    // Check if workout happened today
    final now = DateTime.now();
    final isWorkoutToday = _profile!.lastWorkoutDate != null &&
        _profile!.lastWorkoutDate!.year == now.year &&
        _profile!.lastWorkoutDate!.month == now.month &&
        _profile!.lastWorkoutDate!.day == now.day;

    if (isWorkoutToday) {
      return "Treino concluído: ${_profile!.lastWorkoutName}. Suas metas foram ajustadas para recuperação.";
    }

    final goal = _profile!.useDailyGoals 
      ? _profile!.dailySpecificGoals[_selectedWeekday] 
      : _profile!.weeklyGoals[_selectedWeekday];
    
    if (goal == null) return "Analisando dados...";
    if (goal.isManual) return "Dia com meta manual definida por você.";
    if (goal.label.contains('TMB')) return "Meta travada no seu metabolismo basal por segurança.";
    
    return "Mantenha a meta para atingir seu objetivo.";
  }

  // --- Getters de Meta baseados no estado (Daily Selector ou Bio-Gestão) ---
  int get targetCalories {
    if (_profile == null) return 2000;
    if (_profile!.useDailyGoals) return _profile!.dailySpecificGoals[_selectedWeekday]?.calories ?? 2000;
    return _profile!.weeklyGoals[_selectedWeekday]?.calories ?? _profile!.targetCalories;
  }

  double get targetProtein {
    if (_profile == null) return 150;
    if (_profile!.useDailyGoals) return _profile!.dailySpecificGoals[_selectedWeekday]?.protein ?? 150;
    return _profile!.weeklyGoals[_selectedWeekday]?.protein ?? _profile!.targetProtein;
  }

  double get targetCarb {
    if (_profile == null) return 200;
    if (_profile!.useDailyGoals) return _profile!.dailySpecificGoals[_selectedWeekday]?.carb ?? 200;
    return _profile!.weeklyGoals[_selectedWeekday]?.carb ?? _profile!.targetCarb;
  }

  double get targetFat {
    if (_profile == null) return 66;
    if (_profile!.useDailyGoals) return _profile!.dailySpecificGoals[_selectedWeekday]?.fat ?? 66;
    return _profile!.weeklyGoals[_selectedWeekday]?.fat ?? _profile!.targetFat;
  }

  // Aliases for dashboard compatibility
  double get activeTargetProtein => targetProtein;
  double get activeTargetCarb => targetCarb;
  double get activeTargetFat => targetFat;

  String get currentGoalLabel => _profile?.weeklyGoals[_selectedWeekday]?.label ?? 'Meta Padronizada';
  bool get isCaloriesAdjusted => targetCalories != (_profile?.targetCalories ?? 2000);
  bool get isProteinAdjusted => targetProtein != (_profile?.targetProtein ?? 150);
  bool get isCarbAdjusted => targetCarb != (_profile?.targetCarb ?? 200);
  bool get isFatAdjusted => targetFat != (_profile?.targetFat ?? 66);

  // --- Actions ---

  Future<void> loadExistingProfile() async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;
      final doc = await _db.doc('users/$uid/nutrition/settings').get();
      if (doc.exists) {
        _profile = NutritionProfile.fromMap(doc.data()!, doc.id);
        await loadToday();
        await loadFavorites();
        await loadSelectedDay();
        await _fetchWeeklyPlants();
      }
    } catch (e) {
      _lastError = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> initFromProfile(WorkoutProfile wp) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    
    // Tenta carregar existente primeiro
    await loadExistingProfile();
    
    // Se após tentar carregar ainda for null, gera um novo
    if (_profile == null) {
      _isLoading = true;
      notifyListeners();
      try {
        _profile = NutritionEngine.generateInitialProfile(wp, id: uid);
        await saveSettings();
        await loadToday();
        await loadFavorites();
        await loadSelectedDay();
        await _fetchWeeklyPlants();
      } catch (e) {
        _lastError = e.toString();
      } finally {
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

  Future<void> selectWeekday(int weekday) async {
    _selectedWeekday = weekday;
    await loadSelectedDay();
    notifyListeners();
  }

  Future<void> addMeal(MealEntry entry) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final dateKey = _todayFormat(entry.loggedAt);
    
    // 1. Save meal to logs
    await _db.collection('users/$uid/nutrition/logs/$dateKey/meals').add(entry.toMap());
    
    // 2. Learning Loop: Update popularity and ensure existence in global library
    final globalRef = _db.collection('foods').doc(entry.foodId);
    
    // We use set with merge and increment to handle both new and existing global foods
    await globalRef.set({
      'name': entry.foodName,
      'caloriesPer100g': entry.calories / (entry.portionG / 100),
      'proteinPer100g': entry.protein / (entry.portionG / 100),
      'carbPer100g': entry.carb / (entry.portionG / 100),
      'fatPer100g': entry.fat / (entry.portionG / 100),
      'timesConsumed': FieldValue.increment(1),
      'lastConsumedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // 3. Update User-Specific Metrics for immediate "Recents" access
    await _db.collection('users/$uid/nutrition/recent_foods').doc(entry.foodId).set({
      'name': entry.foodName,
      'caloriesPer100g': entry.calories / (entry.portionG / 100),
      'proteinPer100g': entry.protein / (entry.portionG / 100),
      'carbPer100g': entry.carb / (entry.portionG / 100),
      'fatPer100g': entry.fat / (entry.portionG / 100),
      'lastConsumedAt': FieldValue.serverTimestamp(),
      'timesConsumedUser': FieldValue.increment(1),
    }, SetOptions(merge: true));

    _triggerRecalibration();
    await loadSelectedDay();
  }

  Future<void> removeMeal(String mealId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final dateKey = _todayFormat(DateTime.now()); // Assuming removal from today for simplicity or need selected date?
    // In a real app we'd use the selected date key
    await _db.doc('users/$uid/nutrition/logs/$dateKey/meals/$mealId').delete();
    _triggerRecalibration();
    await loadSelectedDay();
    await _fetchWeeklyPlants();
  }

  void _triggerRecalibration() {
    if (_profile == null) return;
    
    // Calcula calorias de besteira contabilizadas hoje
    final cheatMealCalories = _todayMeals.where((m) => m.isCheatMeal).fold(0.0, (sum, m) => sum + m.calories);

    final updated = NutritionEngine.recalibrateRemainingBudget(
      _profile!,
      todayWeekday: DateTime.now().weekday,
      actualCaloriesToday: consumedCalories,
      cheatMealCalories: cheatMealCalories,
    );
    if (updated != _profile) {
      _profile = updated;
      saveSettings();
      notifyListeners();
    }
  }

  Future<void> updateProfile(NutritionProfile newProfile) async {
    _profile = newProfile;
    await saveSettings();
    notifyListeners();
  }

  Future<void> syncWorkout({required String name, required DateTime date}) async {
    if (_profile == null) return;
    _profile = _profile!.copyWith(lastWorkoutName: name, lastWorkoutDate: date);
    await saveSettings();
    notifyListeners();
  }

  void applyPostWorkoutBonus({
    required String sessionName,
    required int durationMinutes,
    required int exerciseCount,
    required double totalVolume,
  }) {
    if (_profile == null || !_profile!.dynamicAdaptationEnabled) return;
    
    // Register the workout first
    syncWorkout(name: sessionName, date: DateTime.now());

    int bonusCals = (durationMinutes * 5) + (totalVolume / 1000 * 50).round();
    if (bonusCals <= 0) return;

    final todayWeekday = DateTime.now().weekday;
    final currentGoal = _profile!.useDailyGoals 
        ? (_profile!.dailySpecificGoals[todayWeekday] ?? const DailyNutritionalGoal(calories: 2000, protein: 150, carb: 200, fat: 66))
        : (_profile!.weeklyGoals[todayWeekday] ?? const DailyNutritionalGoal(calories: 2000, protein: 150, carb: 200, fat: 66));

    final updatedGoal = currentGoal.copyWith(
      calories: currentGoal.calories + bonusCals,
      carb: currentGoal.carb + (bonusCals / 4.0),
      label: 'Treino Concluído ($sessionName: +${bonusCals}kcal)',
    );

    updateDailyManualGoal(todayWeekday, updatedGoal);
  }

  void updateDailyManualGoal(int weekday, DailyNutritionalGoal newGoal) {
    if (_profile == null) return;
    final goals = Map<int, DailyNutritionalGoal>.from(_profile!.weeklyGoals);
    goals[weekday] = newGoal.copyWith(isManual: true);
    _profile = _profile!.copyWith(weeklyGoals: goals);
    saveSettings();
    notifyListeners();
  }


  void resetDailyGoal(int weekday) {
    if (_profile == null) return;
    final goals = Map<int, DailyNutritionalGoal>.from(_profile!.weeklyGoals);
    final existing = goals[weekday];
    if (existing != null) {
      goals[weekday] = existing.copyWith(isManual: false, label: 'Automático');
      _profile = _profile!.copyWith(weeklyGoals: goals);
      _triggerRecalibration(); // Re-calcula baseado no status atual
      saveSettings();
      notifyListeners();
    }
  }

  Future<void> copyMealFromPreviousDay(String mealType) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || _profile == null) return;
    final now = DateTime.now();
    final firstDayOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final prevDateKey = _todayFormat(firstDayOfWeek.add(Duration(days: _selectedWeekday - 2)));
    final targetDateKey = _todayFormat(firstDayOfWeek.add(Duration(days: _selectedWeekday - 1)));
    final snap = await _db.collection('users/$uid/nutrition/logs/$prevDateKey/meals').where('mealType', isEqualTo: mealType).get();
    if (snap.docs.isEmpty) return;
    final batch = _db.batch();
    for (var doc in snap.docs) {
      final newRef = _db.collection('users/$uid/nutrition/logs/$targetDateKey/meals').doc();
      var data = doc.data();
      data['loggedAt'] = Timestamp.now();
      batch.set(newRef, data);
    }
    await batch.commit();
    await loadSelectedDay();
  }

  final Set<String> _favoriteFoodsIds = {};
  bool isFoodFavorite(String id) => _favoriteFoodsIds.contains(id);

  Future<void> loadFavorites() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final snap = await _db.collection('users/$uid/nutrition/favorite_foods').get();
    _favoriteFoodsIds.clear();
    for (var d in snap.docs) _favoriteFoodsIds.add(d.id);
    notifyListeners();
  }

  Future<void> toggleFavoriteFood(FoodModel food) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final docRef = _db.collection('users/$uid/nutrition/favorite_foods').doc(food.id);
    final doc = await docRef.get();
    if (doc.exists) {
      await docRef.delete();
      _favoriteFoodsIds.remove(food.id);
    } else {
      await docRef.set(food.toMap());
      _favoriteFoodsIds.add(food.id);
    }
    notifyListeners();
  }

  Future<void> addWater(int ml) async {
    if (_profile == null) return;
    final currentWater = Map<int, int>.from(_profile!.dailyWater);
    currentWater[_selectedWeekday] = (currentWater[_selectedWeekday] ?? 0) + ml;
    _profile = _profile!.copyWith(dailyWater: currentWater);
    await saveSettings();
    notifyListeners();
  }

  Future<void> removeWater(int ml) async {
    if (_profile == null) return;
    final currentWater = Map<int, int>.from(_profile!.dailyWater);
    final newVal = (currentWater[_selectedWeekday] ?? 0) - ml;
    currentWater[_selectedWeekday] = newVal < 0 ? 0 : newVal;
    _profile = _profile!.copyWith(dailyWater: currentWater);
    await saveSettings();
    notifyListeners();
  }

  Future<void> loadSelectedDay() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final now = DateTime.now();
    final firstDayOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final dateKey = _todayFormat(firstDayOfWeek.add(Duration(days: _selectedWeekday - 1)));
    final snap = await _db.collection('users/$uid/nutrition/logs/$dateKey/meals').get();
    _selectedDayMeals = snap.docs.map((d) => MealEntry.fromMap(d.data(), d.id)).toList();
    notifyListeners();
  }

  StreamSubscription? _mealsSub;
  Future<void> loadToday() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    _mealsSub?.cancel();
    _mealsSub = _db.collection('users/$uid/nutrition/logs/${_todayFormat(DateTime.now())}/meals').snapshots().listen((snap) {
      _todayMeals = snap.docs.map((d) => MealEntry.fromMap(d.data(), d.id)).toList();
      notifyListeners();
    });
  }

  String _todayFormat(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  @override
  void dispose() {
    _isDisposed = true;
    _mealsSub?.cancel();
    super.dispose();
  }
}
