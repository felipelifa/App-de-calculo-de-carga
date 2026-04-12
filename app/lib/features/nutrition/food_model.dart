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
  final String? barcode;
  final int timesConsumed;

  FoodModel({
    required this.id,
    required this.name,
    this.brand = '',
    required this.caloriesPer100g,
    required this.proteinPer100g,
    required this.carbPer100g,
    required this.fatPer100g,
    this.defaultUnit = '100g',
    this.defaultPortionG = 100.0,
    this.isVerified = false,
    this.isUserCreated = false,
    this.barcode,
    this.timesConsumed = 0,
  });

  factory FoodModel.fromMap(Map<String, dynamic> map, String id) {
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
      isUserCreated: map['isUserCreated'] ?? false,
      barcode: map['barcode'] as String?,
      timesConsumed: (map['timesConsumed'] as num?)?.toInt() ?? 0,
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
      'barcode': barcode,
      'timesConsumed': timesConsumed,
    };
  }
}
