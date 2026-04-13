import 'package:cloud_firestore/cloud_firestore.dart';

class DailyNutritionalGoal {
  final int calories;
  final double protein;
  final double carb;
  final double fat;
  final String label; // 'High Demand', 'Rest', 'Normal'
  final bool isManual; // Se o usuário editou este dia manualmente

  const DailyNutritionalGoal({
    required this.calories,
    required this.protein,
    required this.carb,
    required this.fat,
    this.label = 'Normal',
    this.isManual = false,
  });

  factory DailyNutritionalGoal.fromMap(Map<String, dynamic> map) {
    return DailyNutritionalGoal(
      calories: (map['calories'] as num?)?.toInt() ?? 2000,
      protein: (map['protein'] as num?)?.toDouble() ?? 150.0,
      carb: (map['carb'] as num?)?.toDouble() ?? 200.0,
      fat: (map['fat'] as num?)?.toDouble() ?? 66.0,
      label: map['label'] as String? ?? 'Normal',
      isManual: map['isManual'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
    'calories': calories,
    'protein': protein,
    'carb': carb,
    'fat': fat,
    'label': label,
    'isManual': isManual,
  };

  DailyNutritionalGoal copyWith({int? calories, double? protein, double? carb, double? fat, String? label, bool? isManual}) {
    return DailyNutritionalGoal(
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carb: carb ?? this.carb,
      fat: fat ?? this.fat,
      label: label ?? this.label,
      isManual: isManual ?? this.isManual,
    );
  }
}

class NutritionProfile {
  final int targetCalories;
  final double targetProtein;
  final double targetCarb;
  final double targetFat;
  final int tmb;
  final int tdee;
  final String macroMode; // 'automatic', 'percentage', 'grams'
  final bool dynamicAdaptationEnabled; // Ativa a Bio-Gestão adaptativa
  final bool carbCyclingEnabled; // Se ativa ciclagem de carbos
  
  // -- Gestão Energética Semanal --
  final int weeklyBudgetKcal;
  final String compensationStrategy; // 'automatic', 'linear', 'none'
  final Map<int, DailyNutritionalGoal> weeklyGoals; // 1 (Segunda) a 7 (Domingo)
  
  // -- Monitoramento de Evolução --
  final double adherenceScore; // 0.0 a 1.0
  final int nutritionalFatigueLevel; // 0 (Descansado) a 10 (Exausto)
  final double lastWeightKg;
  
  final DateTime calculatedAt;

  NutritionProfile({
    required this.targetCalories,
    required this.targetProtein,
    required this.targetCarb,
    required this.targetFat,
    required this.tmb,
    required this.tdee,
    this.macroMode = 'automatic',
    this.dynamicAdaptationEnabled = false,
    this.carbCyclingEnabled = false,
    this.weeklyBudgetKcal = 0,
    this.compensationStrategy = 'automatic',
    this.weeklyGoals = const {},
    this.adherenceScore = 1.0,
    this.nutritionalFatigueLevel = 0,
    this.lastWeightKg = 0,
    DateTime? calculatedAt,
  }) : calculatedAt = calculatedAt ?? DateTime.now();

  factory NutritionProfile.fromMap(Map<String, dynamic>? map) {
    if (map == null) return NutritionProfile(targetCalories: 2000, targetProtein: 150, targetCarb: 200, targetFat: 66, tmb: 1600, tdee: 2000);
    
    final goalsRaw = map['weeklyGoals'] as Map<String, dynamic>? ?? {};
    final goals = goalsRaw.map((key, value) => MapEntry(int.parse(key), DailyNutritionalGoal.fromMap(value as Map<String, dynamic>)));

    return NutritionProfile(
      targetCalories: (map['targetCalories'] as num?)?.toInt() ?? 2000,
      targetProtein: (map['targetProtein'] as num?)?.toDouble() ?? 150.0,
      targetCarb: (map['targetCarb'] as num?)?.toDouble() ?? 200.0,
      targetFat: (map['targetFat'] as num?)?.toDouble() ?? 66.0,
      tmb: (map['tmb'] as num?)?.toInt() ?? 1600,
      tdee: (map['tdee'] as num?)?.toInt() ?? 2000,
      macroMode: map['macroMode'] as String? ?? 'automatic',
      dynamicAdaptationEnabled: map['dynamicAdaptationEnabled'] as bool? ?? false,
      carbCyclingEnabled: map['carbCyclingEnabled'] as bool? ?? false,
      weeklyBudgetKcal: (map['weeklyBudgetKcal'] as num?)?.toInt() ?? 14000,
      compensationStrategy: map['compensationStrategy'] as String? ?? 'automatic',
      weeklyGoals: goals,
      adherenceScore: (map['adherenceScore'] as num?)?.toDouble() ?? 1.0,
      nutritionalFatigueLevel: (map['nutritionalFatigueLevel'] as num?)?.toInt() ?? 0,
      lastWeightKg: (map['lastWeightKg'] as num?)?.toDouble() ?? 0,
      calculatedAt: map['calculatedAt'] != null ? (map['calculatedAt'] is Timestamp ? (map['calculatedAt'] as Timestamp).toDate() : DateTime.fromMillisecondsSinceEpoch(map['calculatedAt'])) : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'targetCalories': targetCalories,
      'targetProtein': targetProtein,
      'targetCarb': targetCarb,
      'targetFat': targetFat,
      'tmb': tmb,
      'tdee': tdee,
      'macroMode': macroMode,
      'dynamicAdaptationEnabled': dynamicAdaptationEnabled,
      'carbCyclingEnabled': carbCyclingEnabled,
      'weeklyBudgetKcal': weeklyBudgetKcal,
      'compensationStrategy': compensationStrategy,
      'weeklyGoals': weeklyGoals.map((key, value) => MapEntry(key.toString(), value.toMap())),
      'adherenceScore': adherenceScore,
      'nutritionalFatigueLevel': nutritionalFatigueLevel,
      'lastWeightKg': lastWeightKg,
      'calculatedAt': calculatedAt.millisecondsSinceEpoch,
    };
  }

  NutritionProfile copyWith({
    int? targetCalories,
    double? targetProtein,
    double? targetCarb,
    double? targetFat,
    int? tmb,
    int? tdee,
    String? macroMode,
    bool? dynamicAdaptationEnabled,
    bool? carbCyclingEnabled,
    int? weeklyBudgetKcal,
    String? compensationStrategy,
    Map<int, DailyNutritionalGoal>? weeklyGoals,
    double? adherenceScore,
    int? nutritionalFatigueLevel,
    double? lastWeightKg,
    DateTime? calculatedAt,
  }) {
    return NutritionProfile(
      targetCalories: targetCalories ?? this.targetCalories,
      targetProtein: targetProtein ?? this.targetProtein,
      targetCarb: targetCarb ?? this.targetCarb,
      targetFat: targetFat ?? this.targetFat,
      tmb: tmb ?? this.tmb,
      tdee: tdee ?? this.tdee,
      macroMode: macroMode ?? this.macroMode,
      dynamicAdaptationEnabled: dynamicAdaptationEnabled ?? this.dynamicAdaptationEnabled,
      carbCyclingEnabled: carbCyclingEnabled ?? this.carbCyclingEnabled,
      weeklyBudgetKcal: weeklyBudgetKcal ?? this.weeklyBudgetKcal,
      compensationStrategy: compensationStrategy ?? this.compensationStrategy,
      weeklyGoals: weeklyGoals ?? this.weeklyGoals,
      adherenceScore: adherenceScore ?? this.adherenceScore,
      nutritionalFatigueLevel: nutritionalFatigueLevel ?? this.nutritionalFatigueLevel,
      lastWeightKg: lastWeightKg ?? this.lastWeightKg,
      calculatedAt: calculatedAt ?? this.calculatedAt,
    );
  }
}

