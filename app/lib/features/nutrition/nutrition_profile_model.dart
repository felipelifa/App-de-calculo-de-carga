class NutritionProfile {
  final int targetCalories;
  final double targetProtein;
  final double targetCarb;
  final double targetFat;
  final int tmb;
  final int tdee;
  final String macroMode; // 'automatic', 'percentage', 'grams', 'hybrid'
  final bool dynamicAdaptationEnabled; // Ativa a distribuição semanal preditiva (Bio-energia)
  final bool carbCyclingEnabled;
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
    DateTime? calculatedAt,
  }) : calculatedAt = calculatedAt ?? DateTime.now();

  factory NutritionProfile.fromMap(Map<String, dynamic>? map) {
    if (map == null) return NutritionProfile(targetCalories: 2000, targetProtein: 150, targetCarb: 200, targetFat: 66, tmb: 1600, tdee: 2000);
    
    DateTime? getCalcAt() {
      final val = map['calculatedAt'];
      if (val is Timestamp) return val.toDate();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return DateTime.now();
    }

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
      calculatedAt: getCalcAt(),
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
      calculatedAt: calculatedAt ?? this.calculatedAt,
    );
  }
}
