import '../workout/workout_profile_model.dart';
import 'nutrition_profile_model.dart';

class NutritionEngine {
  /// Calcula o perfil nutricional base a partir do WorkoutProfile do usuário
  static NutritionProfile calculateProfile(
    WorkoutProfile wp, {
    String macroMode = 'automatic',
    bool dynamicAdaptationEnabled = false,
    bool carbCyclingEnabled = false,
  }) {
    // 1. TMB (Mifflin-St Jeor)
    double tmb = 10 * wp.weightKg + 6.25 * wp.heightCm - 5 * wp.age;
    if (wp.biologicalSex == 'male') {
      tmb += 5;
    } else {
      tmb -= 161;
    }

    // 2. Fator de Atividade
    double activityFactor = 1.2; // Sedentário base
    if (wp.availableDaysPerWeek >= 5) {
      activityFactor = wp.sessionDurationMinutes >= 60 ? 1.725 : 1.55;
    } else if (wp.availableDaysPerWeek >= 3) {
      activityFactor = 1.55;
    } else if (wp.availableDaysPerWeek > 0) {
      activityFactor = 1.375;
    }

    final tdee = (tmb * activityFactor).round();

    // 3. Ajuste por Objetivo
    int targetCalories = tdee;
    if (wp.primaryGoal == 'hypertrophy' || wp.primaryGoal == 'strength') {
      targetCalories = (tdee * 1.10).round(); // bulking leve/moderado
    } else if (wp.primaryGoal == 'fat_loss') {
      targetCalories = (tdee * 0.80).round(); // cutting moderado (-20%)
    }

    // 4. Macros Padrões (Modo 'automatic')
    double protein = 2.0 * wp.weightKg;
    double fatCalories = targetCalories * 0.25;
    double fat = fatCalories / 9.0;
    
    double proteinCalories = protein * 4.0;
    double carbCalories = targetCalories - proteinCalories - fatCalories;
    // Evita valores absurdos se as calorias estiverem muito baixas
    if (carbCalories < 0) carbCalories = 0;
    double carb = carbCalories / 4.0;

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
      compensationStrategy: 'automatic',
      distributionMode: 'balanced',
    );
  }

  /// Calcula um bônus pontual pós-treino com base no estímulo da sessão.
  /// Essa energia extra visa suportar a recuperação imediata na camada adaptativa.
  static int calculatePostWorkoutBonus({
    required int durationMinutes,
    required int exerciseCount,
    required double totalVolume, // Caso deseje refinar no futuro
  }) {
    if (durationMinutes < 30 || exerciseCount < 5) return 100;
    if (durationMinutes > 60 && exerciseCount > 8) return 250;
    return 150; // Moderado
  }

  /// (Lógica Flexível) Aplica o bônus aos macronutrientes da meta diária
  static void applyBonusToMacros({
    required int bonusKcal,
    required double targetProtein,
    required double targetCarb,
    required double targetFat,
    required Function(double p, double c, double f) onUpdate,
  }) {
    // Alocação focada em Carbo para repor glicogênio, com leve acréscimo proteico
    double extraP = 0;
    double extraC = 0;
    
    if (bonusKcal == 250) {
      extraC = 50;
      extraP = 15;
    } else if (bonusKcal == 150) {
      extraC = 30;
      extraP = 10;
    } else {
      extraC = 20;
    }

    onUpdate(targetProtein + extraP, targetCarb + extraC, targetFat);
  }

  /// Retorna as metas diárias modificadas pelo Carb Cycling
  static Map<String, dynamic> applyCarbCycling(NutritionProfile profile, bool isTrainingDay) {
    if (!profile.carbCyclingEnabled) {
      return {
        'carb': profile.targetCarb,
        'fat': profile.targetFat,
      };
    }

    // Calcula calorias base de carbo e gordura
    double currentCarbKcal = profile.targetCarb * 4;
    double currentFatKcal = profile.targetFat * 9;
    double flexibleKcal = currentCarbKcal + currentFatKcal;

    double adjustedCarb;
    double adjustedFat;

    if (isTrainingDay) {
      // +20% carbo
      adjustedCarb = profile.targetCarb * 1.2;
      double newCarbKcal = adjustedCarb * 4;
      double leftForFat = flexibleKcal - newCarbKcal;
      adjustedFat = (leftForFat > 0) ? leftForFat / 9 : profile.targetFat * 0.8; 
    } else {
      // -20% carbo
      adjustedCarb = profile.targetCarb * 0.8;
      double newCarbKcal = adjustedCarb * 4;
      double leftForFat = flexibleKcal - newCarbKcal;
      adjustedFat = (leftForFat > 0) ? leftForFat / 9 : profile.targetFat * 1.2;
    }

    return {
      'carb': adjustedCarb,
      'fat': adjustedFat,
    };
  }

  /// --- Lógica de Orçamento Semanal Adaptativo ---

  /// Calcula quantos dias restam na semana corrente (considerando reset na segunda-feira)
  static int daysRemainingInWeek() {
    int weekday = DateTime.now().weekday; // 1 = Monday, 7 = Sunday
    return 7 - (weekday - 1);
  }

  /// Redistribui um excedente ou déficit calórico entre os dias restantes da semana.
  /// [excessKcal]: Positivo se excedeu a meta, negativo se consumiu menos.
  /// [remainingDays]: Dias que restam para compensar.
  /// [strategy]: 'automatic', 'linear'
  static int calculateAdjustmentForRemainingDays({
    required int excessKcal,
    required int remainingDays,
    String strategy = 'automatic',
  }) {
    if (remainingDays <= 0) return 0;

    if (strategy == 'linear') {
      return -(excessKcal ~/ remainingDays);
    }

    // Estratégia 'automatic': se o excesso for muito grande (>1000), 
    // tenta diluir em mais dias ou limita a redução diária a 15% para não quebrar a aderência.
    double adjustment = -(excessKcal / remainingDays);
    
    // Limite de segurança: não reduzir mais que 300kcal por dia para compensar
    if (adjustment < -300) return -300;
    if (adjustment > 300) return 300;

    return adjustment.round();
  }

  /// Alinha a distribuição semanal com a carga de treino.
  /// Se hoje foi um treino "Pesado" (bonus > 200), o sistema pode sugerir 
  /// "puxar" 150kcal dos dias de descanso da própria semana.
  static Map<String, int> redistributeForHighDemand({
    required int bonusKcal,
    required int remainingDays,
  }) {
    if (bonusKcal < 200 || remainingDays < 1) return {'today': bonusKcal, 'nextDays': 0};

    // Puxa metade do bônus de dias futuros para garantir performance hoje sem estourar a semana
    int pullFromFuture = (bonusKcal * 0.5).round();
    return {
      'today': bonusKcal,
      'nextDays': -(pullFromFuture ~/ remainingDays),
    };
  }
}
