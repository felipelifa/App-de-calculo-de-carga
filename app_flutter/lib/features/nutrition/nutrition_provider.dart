import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../core/services/api_service.dart';
import '../workout/workout_profile_model.dart';
import 'nutrition_profile_model.dart';
import 'meal_model.dart';
import 'food_model.dart';
import 'nutrition_engine.dart';
import 'bio_intelligence.dart';

class NutritionProvider extends ChangeNotifier {
  final ApiService _api;

  NutritionProvider({ApiService? api})
      : _api = api ?? ApiService();

  NutritionProfile? _profile;
  List<MealEntry> _todayMeals = [];
  List<MealEntry> _selectedDayMeals = [];
  int _selectedWeekday = DateTime.now().weekday;
  bool _isLoading = false;
  String? _lastError;
  bool _isDisposed = false;
  Timer? _pollTimer;

  NutritionProfile? get profile => _profile;
  List<MealEntry> get todayMeals => _todayMeals;
  List<MealEntry> get selectedDayMeals => _selectedDayMeals;
  int get selectedWeekday => _selectedWeekday;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;

  double get consumedCalories => selectedDayMeals.fold(0, (sum, m) => sum + m.calories);
  double get remainingCalories => targetCalories - consumedCalories;
  double get consumedProtein => selectedDayMeals.fold(0, (sum, m) => sum + m.protein);
  double get consumedCarb => selectedDayMeals.fold(0, (sum, m) => sum + m.carb);
  double get consumedFat => selectedDayMeals.fold(0, (sum, m) => sum + m.fat);

  int _weeklyPlantScore = 0;
  int get weeklyPlantScore => _weeklyPlantScore;
  Set<String> _weeklyPlantSpecies = {};
  Set<String> get weeklyPlantSpecies => _weeklyPlantSpecies;

  Future<void> _fetchWeeklyPlants() async {
    try {
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final startStr = DateFormat('yyyy-MM-dd').format(startOfWeek);

      final result = await _api.get('/nutrition/weekly-plants', queryParams: {
        'startDate': startStr,
      });

      _weeklyPlantSpecies.clear();
      final species = result['species'] as List<dynamic>? ?? [];
      for (var s in species) {
        _weeklyPlantSpecies.add(s as String);
      }
      _weeklyPlantScore = _weeklyPlantSpecies.length;
    } catch (_) {}
  }

  double get adherenceScore => _profile?.adherenceScore ?? 1.0;
  int get fatigueLevel => _profile?.nutritionalFatigueLevel ?? 0;

  int get waterTarget => 2500;
  int get waterConsumed => _profile?.dailyWater[_selectedWeekday] ?? 0;

  String get smartInsight {
    if (_profile == null) return "Configure seu perfil.";
    
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

  double get activeTargetProtein => targetProtein;
  double get activeTargetCarb => targetCarb;
  double get activeTargetFat => targetFat;

  String get currentGoalLabel => _profile?.weeklyGoals[_selectedWeekday]?.label ?? 'Meta Padronizada';
  bool get isCaloriesAdjusted => targetCalories != (_profile?.targetCalories ?? 2000);
  bool get isProteinAdjusted => targetProtein != (_profile?.targetProtein ?? 150);
  bool get isCarbAdjusted => targetCarb != (_profile?.targetCarb ?? 200);
  bool get isFatAdjusted => targetFat != (_profile?.targetFat ?? 66);

  Future<void> loadExistingProfile() async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();
    try {
      final result = await _api.get('/nutrition/settings');
      if (result != null && result is Map<String, dynamic>) {
        _profile = NutritionProfile.fromMap(result, result['id'] as String? ?? 'current');
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
    if (_profile != null) return;
    
    _isLoading = true;
    notifyListeners();
    try {
      _profile = NutritionEngine.generateInitialProfile(wp, id: 'current');
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

  Future<void> saveSettings() async {
    if (_profile == null) return;
    await _api.put('/nutrition/settings', body: _profile!.toMap());
  }

  Future<void> selectWeekday(int weekday) async {
    _selectedWeekday = weekday;
    await loadSelectedDay();
    notifyListeners();
  }

  Future<void> addMeal(MealEntry entry) async {
    final dateKey = _todayFormat(entry.loggedAt);
    
    await _api.post('/nutrition/meals', body: {
      ...entry.toMap(),
      'dateKey': dateKey,
    });

    _triggerRecalibration();
    await loadSelectedDay();
  }

  Future<void> removeMeal(String mealId) async {
    await _api.delete('/nutrition/meals/$mealId');
    _triggerRecalibration();
    await loadSelectedDay();
    await _fetchWeeklyPlants();
  }

  void _triggerRecalibration() {
    if (_profile == null) return;
    
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
      _triggerRecalibration();
      saveSettings();
      notifyListeners();
    }
  }

  Future<void> copyMealFromPreviousDay(String mealType) async {
    if (_profile == null) return;
    final now = DateTime.now();
    final firstDayOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final prevDateKey = _todayFormat(firstDayOfWeek.add(Duration(days: _selectedWeekday - 2)));
    final targetDateKey = _todayFormat(firstDayOfWeek.add(Duration(days: _selectedWeekday - 1)));

    await _api.post('/nutrition/meals/copy', body: {
      'fromDate': prevDateKey,
      'toDate': targetDateKey,
      'mealType': mealType,
    });

    await loadSelectedDay();
  }

  final Set<String> _favoriteFoodsIds = {};
  bool isFoodFavorite(String id) => _favoriteFoodsIds.contains(id);

  Future<void> loadFavorites() async {
    try {
      final result = await _api.get('/nutrition/favorite-foods');
      final data = result['data'] as List<dynamic>? ?? [];
      _favoriteFoodsIds.clear();
      for (var d in data) {
        final m = d as Map<String, dynamic>;
        _favoriteFoodsIds.add(m['id'] as String? ?? '');
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> toggleFavoriteFood(FoodModel food) async {
    if (_favoriteFoodsIds.contains(food.id)) {
      await _api.delete('/nutrition/favorite-foods/${food.id}');
      _favoriteFoodsIds.remove(food.id);
    } else {
      await _api.post('/nutrition/favorite-foods', body: food.toMap());
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
    final now = DateTime.now();
    final firstDayOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final dateKey = _todayFormat(firstDayOfWeek.add(Duration(days: _selectedWeekday - 1)));

    try {
      final result = await _api.get('/nutrition/meals', queryParams: {
        'date': dateKey,
      });
      final data = result['data'] as List<dynamic>? ?? [];
      _selectedDayMeals = data.map((d) {
        final m = d as Map<String, dynamic>;
        return MealEntry.fromMap(m, m['id'] as String? ?? '');
      }).toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadToday() async {
    final dateKey = _todayFormat(DateTime.now());
    try {
      final result = await _api.get('/nutrition/meals', queryParams: {
        'date': dateKey,
      });
      final data = result['data'] as List<dynamic>? ?? [];
      _todayMeals = data.map((d) {
        final m = d as Map<String, dynamic>;
        return MealEntry.fromMap(m, m['id'] as String? ?? '');
      }).toList();
      notifyListeners();
    } catch (_) {}

    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _refreshToday();
    });
  }

  Future<void> _refreshToday() async {
    final dateKey = _todayFormat(DateTime.now());
    try {
      final result = await _api.get('/nutrition/meals', queryParams: {
        'date': dateKey,
      });
      final data = result['data'] as List<dynamic>? ?? [];
      _todayMeals = data.map((d) {
        final m = d as Map<String, dynamic>;
        return MealEntry.fromMap(m, m['id'] as String? ?? '');
      }).toList();
      notifyListeners();
    } catch (_) {}
  }

  String _todayFormat(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  @override
  void dispose() {
    _isDisposed = true;
    _pollTimer?.cancel();
    super.dispose();
  }
}
