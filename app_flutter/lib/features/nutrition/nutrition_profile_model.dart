class DailyNutritionalGoal {
  final int calories;
  final double protein;
  final double carb;
  final double fat;
  final String label;
  final bool isManual;

  const DailyNutritionalGoal({
    required this.calories,
    required this.protein,
    required this.carb,
    required this.fat,
    this.label = '',
    this.isManual = false,
  });

  factory DailyNutritionalGoal.fromMap(Map<String, dynamic> map) {
    return DailyNutritionalGoal(
      calories: (map['calories'] as num?)?.toInt() ?? 2000,
      protein: (map['protein'] as num?)?.toDouble() ?? 150,
      carb: (map['carb'] as num?)?.toDouble() ?? 200,
      fat: (map['fat'] as num?)?.toDouble() ?? 66,
      label: map['label'] as String? ?? '',
      isManual: map['isManual'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'calories': calories,
      'protein': protein,
      'carb': carb,
      'fat': fat,
      'label': label,
      'isManual': isManual,
    };
  }

  DailyNutritionalGoal copyWith({
    int? calories,
    double? protein,
    double? carb,
    double? fat,
    String? label,
    bool? isManual,
  }) {
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
  final String id;
  final String goal; // 'loss', 'gain', 'maintenance'
  final int targetCalories;
  final double targetProtein;
  final double targetCarb;
  final double targetFat;
  final int tmb;
  final int tdee;
  final String macroMode;
  final bool dynamicAdaptationEnabled;
  final bool carbCyclingEnabled;
  final bool useDailyGoals;
  final Map<int, DailyNutritionalGoal> dailySpecificGoals;
  final int weeklyBudgetKcal;
  final String compensationStrategy;
  final Map<int, DailyNutritionalGoal> weeklyGoals;
  final Map<int, int> dailyWater;
  final double adherenceScore;
  final int nutritionalFatigueLevel;
  final String? lastWorkoutName;
  final DateTime? lastWorkoutDate;

  NutritionProfile({
    required this.id,
    required this.goal,
    required this.targetCalories,
    required this.targetProtein,
    required this.targetCarb,
    required this.targetFat,
    required this.tmb,
    required this.tdee,
    this.macroMode = 'automatic',
    this.dynamicAdaptationEnabled = true,
    this.useDailyGoals = false,
    this.dailySpecificGoals = const {},
    this.carbCyclingEnabled = false,
    this.weeklyBudgetKcal = 0,
    this.compensationStrategy = 'automatic',
    this.weeklyGoals = const {},
    this.dailyWater = const {},
    this.adherenceScore = 1.0,
    this.nutritionalFatigueLevel = 0,
    this.lastWorkoutName,
    this.lastWorkoutDate,
  });

  static DateTime? _readDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  factory NutritionProfile.fromMap(Map<String, dynamic> map, String id) {
    final goalsRaw = map['weeklyGoals'] as Map<String, dynamic>? ?? {};
    final goals = goalsRaw.map((key, value) => MapEntry(int.parse(key), DailyNutritionalGoal.fromMap(value as Map<String, dynamic>)));

    final specRaw = map['dailySpecificGoals'] as Map<String, dynamic>? ?? {};
    final specGoals = specRaw.map((key, value) => MapEntry(int.parse(key), DailyNutritionalGoal.fromMap(value as Map<String, dynamic>)));

    final waterRaw = map['dailyWater'] as Map<String, dynamic>? ?? {};
    final dailyWater = waterRaw.map((key, value) => MapEntry(int.parse(key), value as int));

    return NutritionProfile(
      id: id,
      goal: map['goal'] ?? 'maintenance',
      targetCalories: (map['targetCalories'] as num?)?.toInt() ?? 2000,
      targetProtein: (map['targetProtein'] as num?)?.toDouble() ?? 150,
      targetCarb: (map['targetCarb'] as num?)?.toDouble() ?? 200,
      targetFat: (map['targetFat'] as num?)?.toDouble() ?? 66,
      tmb: (map['tmb'] as num?)?.toInt() ?? 1600,
      tdee: (map['tdee'] as num?)?.toInt() ?? 2000,
      macroMode: map['macroMode'] as String? ?? 'automatic',
      dynamicAdaptationEnabled: map['dynamicAdaptationEnabled'] as bool? ?? true,
      useDailyGoals: map['useDailyGoals'] as bool? ?? false,
      dailySpecificGoals: specGoals,
      carbCyclingEnabled: map['carbCyclingEnabled'] as bool? ?? false,
      weeklyBudgetKcal: (map['weeklyBudgetKcal'] as num?)?.toInt() ?? 14000,
      compensationStrategy: map['compensationStrategy'] as String? ?? 'automatic',
      weeklyGoals: goals,
      dailyWater: dailyWater,
      adherenceScore: (map['adherenceScore'] as num?)?.toDouble() ?? 1.0,
      nutritionalFatigueLevel: map['nutritionalFatigueLevel'] as int? ?? 0,
      lastWorkoutName: map['lastWorkoutName'] as String?,
      lastWorkoutDate: _readDate(map['lastWorkoutDate']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'goal': goal,
      'targetCalories': targetCalories,
      'targetProtein': targetProtein,
      'targetCarb': targetCarb,
      'targetFat': targetFat,
      'tmb': tmb,
      'tdee': tdee,
      'macroMode': macroMode,
      'dynamicAdaptationEnabled': dynamicAdaptationEnabled,
      'useDailyGoals': useDailyGoals,
      'dailySpecificGoals': dailySpecificGoals.map((key, value) => MapEntry(key.toString(), value.toMap())),
      'carbCyclingEnabled': carbCyclingEnabled,
      'weeklyBudgetKcal': weeklyBudgetKcal,
      'compensationStrategy': compensationStrategy,
      'weeklyGoals': weeklyGoals.map((key, value) => MapEntry(key.toString(), value.toMap())),
      'dailyWater': dailyWater.map((key, value) => MapEntry(key.toString(), value)),
      'adherenceScore': adherenceScore,
      'nutritionalFatigueLevel': nutritionalFatigueLevel,
      'lastWorkoutName': lastWorkoutName,
      'lastWorkoutDate': lastWorkoutDate?.toIso8601String(),
    };
  }

  NutritionProfile copyWith({
    String? goal,
    int? targetCalories,
    double? targetProtein,
    double? targetCarb,
    double? targetFat,
    int? tmb,
    int? tdee,
    String? macroMode,
    bool? dynamicAdaptationEnabled,
    bool? useDailyGoals,
    Map<int, DailyNutritionalGoal>? dailySpecificGoals,
    bool? carbCyclingEnabled,
    int? weeklyBudgetKcal,
    String? compensationStrategy,
    Map<int, DailyNutritionalGoal>? weeklyGoals,
    Map<int, int>? dailyWater,
    double? adherenceScore,
    int? nutritionalFatigueLevel,
    String? lastWorkoutName,
    DateTime? lastWorkoutDate,
  }) {
    return NutritionProfile(
      id: this.id,
      goal: goal ?? this.goal,
      targetCalories: targetCalories ?? this.targetCalories,
      targetProtein: targetProtein ?? this.targetProtein,
      targetCarb: targetCarb ?? this.targetCarb,
      targetFat: targetFat ?? this.targetFat,
      tmb: tmb ?? this.tmb,
      tdee: tdee ?? this.tdee,
      macroMode: macroMode ?? this.macroMode,
      dynamicAdaptationEnabled: dynamicAdaptationEnabled ?? this.dynamicAdaptationEnabled,
      useDailyGoals: useDailyGoals ?? this.useDailyGoals,
      dailySpecificGoals: dailySpecificGoals ?? this.dailySpecificGoals,
      carbCyclingEnabled: carbCyclingEnabled ?? this.carbCyclingEnabled,
      weeklyBudgetKcal: weeklyBudgetKcal ?? this.weeklyBudgetKcal,
      compensationStrategy: compensationStrategy ?? this.compensationStrategy,
      weeklyGoals: weeklyGoals ?? this.weeklyGoals,
      dailyWater: dailyWater ?? this.dailyWater,
      adherenceScore: adherenceScore ?? this.adherenceScore,
      nutritionalFatigueLevel: nutritionalFatigueLevel ?? this.nutritionalFatigueLevel,
      lastWorkoutName: lastWorkoutName ?? this.lastWorkoutName,
      lastWorkoutDate: lastWorkoutDate ?? this.lastWorkoutDate,
    );
  }
}
