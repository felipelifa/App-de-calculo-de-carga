class FoodModel {
  final String id;
  final String name;
  final String brand;
  final double caloriesPer100g;
  final double proteinPer100g;
  final double carbPer100g;
  final double fatPer100g;
  final String defaultUnit;
  final double defaultPortionG;
  final bool isVerified;
  final bool isUserCreated;
  final bool isRecipe;
  final List<Map<String, dynamic>>? recipeIngredients;
  final String? barcode;
  final String category;
  final Map<String, double> commonPortions;
  final int timesConsumed;

  FoodModel({
    required this.id,
    required this.name,
    this.brand = '',
    this.caloriesPer100g = 0,
    this.proteinPer100g = 0,
    this.carbPer100g = 0,
    this.fatPer100g = 0,
    this.defaultUnit = '100g',
    this.defaultPortionG = 100.0,
    this.isVerified = false,
    this.isUserCreated = false,
    this.isRecipe = false,
    this.recipeIngredients,
    this.barcode,
    this.category = 'Geral',
    this.commonPortions = const {},
    this.timesConsumed = 0,
  });

  factory FoodModel.fromMap(Map<String, dynamic> map, String id) {
    // Portions parsing
    Map<String, double> parsedPortions = {};
    if (map['commonPortions'] is Map) {
      (map['commonPortions'] as Map).forEach((key, value) {
        parsedPortions[key.toString()] = (value as num).toDouble();
      });
    }

    return FoodModel(
      id: id,
      name: map['name'] ?? '',
      brand: map['brand'] ?? '',
      caloriesPer100g: (map['caloriesPer100g'] as num?)?.toDouble() ?? 0.0,
      proteinPer100g: (map['proteinPer100g'] as num?)?.toDouble() ?? 0.0,
      carbPer100g: (map['carbPer100g'] as num?)?.toDouble() ?? 0.0,
      fatPer100g: (map['fatPer100g'] as num?)?.toDouble() ?? 0.0,
      defaultUnit: map['defaultUnit'] ?? '100g',
      defaultPortionG: (map['defaultPortionG'] as num?)?.toDouble() ?? 100.0,
      isVerified: map['isVerified'] ?? false,
      isUserCreated: map['isUserCreated'] as bool? ?? false,
      isRecipe: map['isRecipe'] as bool? ?? false,
      recipeIngredients: (map['recipeIngredients'] as List?)?.map((i) => i as Map<String, dynamic>).toList(),
      barcode: map['barcode'] as String?,
      category: map['category'] as String? ?? 'Geral',
      commonPortions: parsedPortions,
      timesConsumed: map['timesConsumed'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'brand': brand,
      'caloriesPer100g': caloriesPer100g,
      'proteinPer100g': proteinPer100g,
      'carbPer100g': carbPer100g,
      'fatPer100g': fatPer100g,
      'defaultUnit': defaultUnit,
      'defaultPortionG': defaultPortionG,
      'isVerified': isVerified,
      'isUserCreated': isUserCreated,
      'isRecipe': isRecipe,
      'recipeIngredients': recipeIngredients,
      'barcode': barcode,
      'category': category,
      'commonPortions': commonPortions,
      'timesConsumed': timesConsumed,
    };
  }

  FoodModel copyWith({
    String? id,
    String? name,
    String? brand,
    double? caloriesPer100g,
    double? proteinPer100g,
    double? carbPer100g,
    double? fatPer100g,
    bool? isUserCreated,
    bool? isVerified,
    bool? isRecipe,
    List<Map<String, dynamic>>? recipeIngredients,
    String? category,
  }) {
    return FoodModel(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      caloriesPer100g: caloriesPer100g ?? this.caloriesPer100g,
      proteinPer100g: proteinPer100g ?? this.proteinPer100g,
      carbPer100g: carbPer100g ?? this.carbPer100g,
      fatPer100g: fatPer100g ?? this.fatPer100g,
      isUserCreated: isUserCreated ?? this.isUserCreated,
      isVerified: isVerified ?? this.isVerified,
      isRecipe: isRecipe ?? this.isRecipe,
      recipeIngredients: recipeIngredients ?? this.recipeIngredients,
      category: category ?? this.category,
    );
  }
}
