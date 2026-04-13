class MealEntry {
  final String id;
  final String foodId;
  final String foodName;
  final double portionG;
  final double calories;
  final double protein;
  final double carb;
  final double fat;
  final String mealType; // 'breakfast', 'lunch', 'dinner', 'snack'
  final DateTime loggedAt;
  final bool isCheatMeal;

  MealEntry({
    required this.id,
    required this.foodId,
    required this.foodName,
    required this.portionG,
    required this.calories,
    required this.protein,
    required this.carb,
    required this.fat,
    required this.mealType,
    required this.loggedAt,
    this.isCheatMeal = false,
  });

  factory MealEntry.fromMap(Map<String, dynamic>? map, String id) {
    if (map == null) return MealEntry(id: id, foodId: '', foodName: 'Desconhecido', portionG: 0, calories: 0, protein: 0, carb: 0, fat: 0, mealType: 'snack', loggedAt: DateTime.now());
    
    DateTime getLoggedAt() {
      final val = map['loggedAt'];
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      try {
        if (val != null) return (val as dynamic).toDate();
      } catch (_) {}
      return DateTime.now();
    }

    return MealEntry(
      id: id,
      foodId: map['foodId'] as String? ?? '',
      foodName: map['foodName'] as String? ?? '',
      portionG: (map['portionG'] as num?)?.toDouble() ?? 0.0,
      calories: (map['calories'] as num?)?.toDouble() ?? 0.0,
      protein: (map['protein'] as num?)?.toDouble() ?? 0.0,
      carb: (map['carb'] as num?)?.toDouble() ?? 0.0,
      fat: (map['fat'] as num?)?.toDouble() ?? 0.0,
      mealType: map['mealType'] as String? ?? 'snack',
      loggedAt: getLoggedAt(),
      isCheatMeal: map['isCheatMeal'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'foodId': foodId,
      'foodName': foodName,
      'portionG': portionG,
      'calories': calories,
      'protein': protein,
      'carb': carb,
      'fat': fat,
      'mealType': mealType,
      'loggedAt': loggedAt.millisecondsSinceEpoch,
      'isCheatMeal': isCheatMeal,
    };
  }

  MealEntry copyWith({
    String? id,
    String? foodId,
    String? foodName,
    double? portionG,
    double? calories,
    double? protein,
    double? carb,
    double? fat,
    String? mealType,
    DateTime? loggedAt,
    bool? isCheatMeal,
  }) {
    return MealEntry(
      id: id ?? this.id,
      foodId: foodId ?? this.foodId,
      foodName: foodName ?? this.foodName,
      portionG: portionG ?? this.portionG,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carb: carb ?? this.carb,
      fat: fat ?? this.fat,
      mealType: mealType ?? this.mealType,
      loggedAt: loggedAt ?? this.loggedAt,
      isCheatMeal: isCheatMeal ?? this.isCheatMeal,
    );
  }
}
