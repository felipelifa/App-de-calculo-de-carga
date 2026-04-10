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
  });

  factory MealEntry.fromMap(Map<String, dynamic> map, String id) {
    return MealEntry(
      id: id,
      foodId: map['foodId'] ?? '',
      foodName: map['foodName'] ?? '',
      portionG: (map['portionG'] as num?)?.toDouble() ?? 0.0,
      calories: (map['calories'] as num?)?.toDouble() ?? 0.0,
      protein: (map['protein'] as num?)?.toDouble() ?? 0.0,
      carb: (map['carb'] as num?)?.toDouble() ?? 0.0,
      fat: (map['fat'] as num?)?.toDouble() ?? 0.0,
      mealType: map['mealType'] ?? 'snack',
      loggedAt: map['loggedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['loggedAt'])
          : DateTime.now(),
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
    };
  }
}
