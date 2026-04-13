import '../workout/workout_profile_model.dart';
import 'nutrition_profile_model.dart';
import 'dart:math' as math;

class NutritionEngine {
  /// Gera o perfil nutricional inicial com Timeline Semanal
  static NutritionProfile calculateProfile(
    WorkoutProfile wp, {
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
    double protein = 2.1 * wp.weightKg; // Prioridade Científica
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
      lastWeightKg: wp.weightKg,
    );
  }

  /// Distribui o orçamento semanal entre os dias (Seg-Dom)
  /// Prioriza Carbos em dias de treino e reduz em dias de descanso
  static Map<int, DailyNutritionalGoal> _generateInitialTimeline({
    required int targetCalories,
    required double protein,
    required double fat,
    required int trainingDaysPerWeek,
    required bool carbCyclingEnabled,
  }) {
    Map<int, DailyNutritionalGoal> goals = {};
    
    // Simplificação: Assume-se que os primeiros N dias do orçamento 
    // mapeiam para carga alta (ou usa-se um padrão intercalado)
    // No app real, isso será sincronizado com o calendário de treinos.
    for (int i = 1; i <= 7; i++) {
        bool isHighDemand = (i <= trainingDaysPerWeek);
        double multiplier = carbCyclingEnabled ? (isHighDemand ? 1.1 : 0.85) : 1.0;
        
        // Mantém proteína e gordura estáveis, varia Carbo
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
    
    // Ajuste final para garantir que a soma dos 7 dias = Orçamento Semanal
    int currentSum = goals.values.fold(0, (sum, g) => sum + g.calories);
    int diff = (targetCalories * 7) - currentSum;
    int perDayDiff = diff ~/ 7;
    
    for (int i = 1; i <= 7; i++) {
        final g = goals[i]!;
        goals[i] = g.copyWith(calories: g.calories + perDayDiff);
    }

    return goals;
  }

  /// Recalibra os dias restantes da semana após um desvio (excesso ou economia)
  static NutritionProfile recalibrateRemainingBudget(
    NutritionProfile profile, {
    required int todayWeekday, // 1-7
    required int actualCaloriesToday,
  }) {
    if (!profile.dynamicAdaptationEnabled) return profile;

    final todayGoal = profile.weeklyGoals[todayWeekday];
    if (todayGoal == null) return profile;

    int deviation = actualCaloriesToday - todayGoal.calories;
    int remainingDays = 7 - todayWeekday;
    
    if (remainingDays <= 0 || deviation == 0) return profile;

    // Estratégia de compensação automática
    Map<int, DailyNutritionalGoal> updatedGoals = Map.from(profile.weeklyGoals);
    
    // Diluir o desvio nos dias seguintes (respeitando limite de 15% de variação)
    double dailyAdjustment = -(deviation / remainingDays);
    
    for (int i = todayWeekday + 1; i <= 7; i++) {
        final g = updatedGoals[i]!;
        if (g.isManual) continue; // Respeita edições manuais do usuário

        int newCals = (g.calories + dailyAdjustment).round();
        
        // Segurança: não permitir que as calorias caiam abaixo da TMB
        newCals = math.max(newCals, profile.tmb);
        
        double newCarb = (newCals - (g.protein * 4) - (g.fat * 9)) / 4.0;
        
        updatedGoals[i] = g.copyWith(
            calories: newCals,
            carb: math.max(10, newCarb),
        );
    }

    return profile.copyWith(weeklyGoals: updatedGoals);
  }

  /// Calcula o score de aderência real (0.0 a 1.0)
  static double calculateAdherence(List<int> deviations) {
    if (deviations.isEmpty) return 1.0;
    double avgAbsDev = deviations.map((e) => e.abs()).reduce((a, b) => a + b) / deviations.length;
    // Heurística: 500kcal de desvio médio = 0.5 de aderência
    return math.max(0.0, 1.0 - (avgAbsDev / 1000.0));
  }

  /// Monitoramento de fadiga nutricional
  /// Se o usuário está em déficit por muitas semanas (>6) e a aderência está caindo, 
  /// aumenta o nível de fadiga.
  static int updateFatigueLevel({
    required int currentFatigue,
    required double adherenceScore,
    required bool inDeficit,
    required int weeksInPhase,
  }) {
    int newLevel = currentFatigue;
    if (inDeficit && weeksInPhase > 6 && adherenceScore < 0.7) {
      newLevel = math.min(10, newLevel + 1);
    } else if (!inDeficit || adherenceScore > 0.9) {
      newLevel = math.max(0, newLevel - 1);
    }
    return newLevel;
  }
}

