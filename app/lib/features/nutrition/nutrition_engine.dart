import '../workout/workout_profile_model.dart';
import 'nutrition_profile_model.dart';
import 'dart:math' as math;

class NutritionEngine {
  /// Gera o perfil nutricional inicial com Timeline Semanal
  static NutritionProfile generateInitialProfile(
    WorkoutProfile wp, {
    required String id,
    String macroMode = 'automatic',
    bool dynamicAdaptationEnabled = true,
    bool carbCyclingEnabled = true,
  }) {
    // 1. TMB e TDEE (Mifflin-St Jeor)
    double tmb = 10 * wp.weightKg + 6.25 * wp.heightCm - 5 * wp.age;
    tmb += (wp.biologicalSex == 'male') ? 5 : -161;

    // Fator de atividade adaptativo
    double activityFactor = 1.2;
    if (wp.availableDaysPerWeek >= 5) activityFactor = 1.6;
    else if (wp.availableDaysPerWeek >= 3) activityFactor = 1.4;

    final tdee = (tmb * activityFactor).round();

    // 2. Ajuste por Objetivo
    int targetCalories = tdee;
    if (wp.primaryGoal == 'fat_loss') targetCalories = (tdee * 0.82).round();
    else if (wp.primaryGoal == 'hypertrophy') targetCalories = (tdee * 1.12).round();

    // 3. Macros Base
    double protein = 2.1 * wp.weightKg;
    double fat = (targetCalories * 0.25) / 9.0;
    double carb = (targetCalories - (protein * 4) - (fat * 9)) / 4.0;

    // 4. Gerar Timeline Semanal Dinâmica
    final weeklyGoals = _generateInitialTimeline(
      targetCalories: targetCalories,
      protein: protein,
      fat: fat,
      trainingDaysPerWeek: wp.availableDaysPerWeek,
      carbCyclingEnabled: carbCyclingEnabled,
    );

    return NutritionProfile(
      id: id,
      goal: wp.primaryGoal,
      targetCalories: targetCalories,
      targetProtein: protein,
      targetCarb: carb,
      targetFat: fat,
      tmb: tmb.round(),
      tdee: tdee,
      macroMode: macroMode,
      dynamicAdaptationEnabled: dynamicAdaptationEnabled,
      carbCyclingEnabled: carbCyclingEnabled,
      weeklyBudgetKcal: targetCalories * 7,
      weeklyGoals: weeklyGoals,
      dailySpecificGoals: {},
      useDailyGoals: false,
    );
  }

  static Map<int, DailyNutritionalGoal> _generateInitialTimeline({
    required int targetCalories,
    required double protein,
    required double fat,
    required int trainingDaysPerWeek,
    required bool carbCyclingEnabled,
  }) {
    Map<int, DailyNutritionalGoal> goals = {};
    for (int i = 1; i <= 7; i++) {
        bool isHighDemand = (i <= trainingDaysPerWeek);
        double multiplier = carbCyclingEnabled ? (isHighDemand ? 1.1 : 0.85) : 1.0;
        int dailyCals = (targetCalories * multiplier).round();
        double dailyCarb = (dailyCals - (protein * 4) - (fat * 9)) / 4.0;

        goals[i] = DailyNutritionalGoal(
           calories: dailyCals,
           protein: protein,
           fat: fat,
           carb: math.max(10, dailyCarb),
           label: isHighDemand ? 'Alta Demanda' : 'Descanso',
        );
    }
    int currentSum = goals.values.fold(0, (sum, g) => sum + g.calories);
    int diff = (targetCalories * 7) - currentSum;
    int perDayDiff = diff ~/ 7;
    for (int i = 1; i <= 7; i++) {
        final g = goals[i]!;
        goals[i] = g.copyWith(calories: g.calories + perDayDiff);
    }
    return goals;
  }

  static NutritionProfile recalibrateRemainingBudget(
    NutritionProfile profile, {
    required int todayWeekday,
    required double actualCaloriesToday, // Changed to double to match provider
  }) {
    if (!profile.dynamicAdaptationEnabled) return profile;

    final todayGoal = profile.weeklyGoals[todayWeekday];
    if (todayGoal == null) return profile;

    double deviation = actualCaloriesToday - todayGoal.calories;
    int remainingDays = 7 - todayWeekday;
    
    if (remainingDays <= 0 || deviation == 0) return profile;

    Map<int, DailyNutritionalGoal> updatedGoals = Map.from(profile.weeklyGoals);
    double dailyAdjustment = -(deviation / remainingDays);
    
    for (int i = todayWeekday + 1; i <= 7; i++) {
        final g = updatedGoals[i]!;
        if (g.isManual) continue;

        int newCals = (g.calories + dailyAdjustment).round();
        bool hitTmbLimit = false;

        if (newCals < profile.tmb) {
          newCals = profile.tmb;
          hitTmbLimit = true;
        }

        double newCarb = (newCals - (g.protein * 4) - (g.fat * 9)) / 4.0;
        
        updatedGoals[i] = g.copyWith(
            calories: newCals,
            carb: math.max(10, newCarb),
            label: hitTmbLimit ? 'Trava de Segurança (TMB)' : 'Compensado',
        );
    }

    return profile.copyWith(weeklyGoals: updatedGoals);
  }
}
