import 'dart:io';

// ─────────────────────────────────────────────
// Modelo de Detecção de Alimento
// Resultado da análise de imagem
// ─────────────────────────────────────────────

class FoodDetection {
  final String id;
  final String name;
  final double confidence; // 0.0 a 1.0
  final String? category; // proteína, carboidrato, leguminosa, etc.
  final String? preparationMethod; // grelhado, cozido, frito, etc.
  final PortionEstimate? portionEstimate;
  final BoundingBox? boundingBox;
  final Map<String, dynamic>? metadata;

  const FoodDetection({
    required this.id,
    required this.name,
    required this.confidence,
    this.category,
    this.preparationMethod,
    this.portionEstimate,
    this.boundingBox,
    this.metadata,
  });

  ConfidenceLevel get confidenceLevel {
    if (confidence >= 0.85) return ConfidenceLevel.high;
    if (confidence >= 0.60) return ConfidenceLevel.medium;
    if (confidence >= 0.30) return ConfidenceLevel.low;
    return ConfidenceLevel.unknown;
  }

  FoodDetection copyWith({
    String? id,
    String? name,
    double? confidence,
    String? category,
    String? preparationMethod,
    PortionEstimate? portionEstimate,
    BoundingBox? boundingBox,
    Map<String, dynamic>? metadata,
  }) {
    return FoodDetection(
      id: id ?? this.id,
      name: name ?? this.name,
      confidence: confidence ?? this.confidence,
      category: category ?? this.category,
      preparationMethod: preparationMethod ?? this.preparationMethod,
      portionEstimate: portionEstimate ?? this.portionEstimate,
      boundingBox: boundingBox ?? this.boundingBox,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'confidence': confidence,
    'category': category,
    'preparationMethod': preparationMethod,
    'portionEstimate': portionEstimate?.toJson(),
    'boundingBox': boundingBox?.toJson(),
    'metadata': metadata,
  };

  factory FoodDetection.fromJson(Map<String, dynamic> json) {
    return FoodDetection(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      category: json['category'],
      preparationMethod: json['preparationMethod'],
      portionEstimate: json['portionEstimate'] != null
          ? PortionEstimate.fromJson(json['portionEstimate'])
          : null,
      boundingBox: json['boundingBox'] != null
          ? BoundingBox.fromJson(json['boundingBox'])
          : null,
      metadata: json['metadata'],
    );
  }
}

// ─────────────────────────────────────────────
// Estimativa de Porção
// ─────────────────────────────────────────────

class PortionEstimate {
  final double? grams; // Estimativa em gramas
  final PortionSize? sizeCategory; // pequeno, normal, grande
  final double confidence; // 0.0 a 1.0
  final String? referenceObject; // prato, talher, copo, etc.

  const PortionEstimate({
    this.grams,
    this.sizeCategory,
    required this.confidence,
    this.referenceObject,
  });

  Map<String, dynamic> toJson() => {
    'grams': grams,
    'sizeCategory': sizeCategory?.name,
    'confidence': confidence,
    'referenceObject': referenceObject,
  };

  factory PortionEstimate.fromJson(Map<String, dynamic> json) {
    return PortionEstimate(
      grams: (json['grams'] as num?)?.toDouble(),
      sizeCategory: json['sizeCategory'] != null
          ? PortionSize.values.byName(json['sizeCategory'])
          : null,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      referenceObject: json['referenceObject'],
    );
  }
}

// ─────────────────────────────────────────────
// Bounding Box (para segmentação visual)
// ─────────────────────────────────────────────

class BoundingBox {
  final double x; // 0.0 a 1.0 (relativo à imagem)
  final double y; // 0.0 a 1.0
  final double width; // 0.0 a 1.0
  final double height; // 0.0 a 1.0

  const BoundingBox({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  Map<String, dynamic> toJson() => {
    'x': x,
    'y': y,
    'width': width,
    'height': height,
  };

  factory BoundingBox.fromJson(Map<String, dynamic> json) {
    return BoundingBox(
      x: (json['x'] as num?)?.toDouble() ?? 0.0,
      y: (json['y'] as num?)?.toDouble() ?? 0.0,
      width: (json['width'] as num?)?.toDouble() ?? 0.0,
      height: (json['height'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

// ─────────────────────────────────────────────
// Enums
// ─────────────────────────────────────────────

enum ConfidenceLevel {
  high,    // >= 85%
  medium,  // >= 60%
  low,     // >= 30%
  unknown, // < 30%
}

enum PortionSize {
  small,  // pouco
  normal, // normal
  large,  // bastante
}

// ─────────────────────────────────────────────
// Resultado da Análise Completa
// ─────────────────────────────────────────────

class MealAnalysisResult {
  final String id;
  final String? imagePath;
  final List<FoodDetection> detections;
  final DateTime analyzedAt;
  final String? visionModelVersion;
  final double overallConfidence;
  final bool requiresConfirmation;

  const MealAnalysisResult({
    required this.id,
    this.imagePath,
    required this.detections,
    required this.analyzedAt,
    this.visionModelVersion,
    required this.overallConfidence,
    required this.requiresConfirmation,
  });

  List<FoodDetection> get highConfidenceDetections =>
      detections.where((d) => d.confidenceLevel == ConfidenceLevel.high).toList();

  List<FoodDetection> get mediumConfidenceDetections =>
      detections.where((d) => d.confidenceLevel == ConfidenceLevel.medium).toList();

  List<FoodDetection> get lowConfidenceDetections =>
      detections.where((d) => d.confidenceLevel == ConfidenceLevel.low).toList();

  Map<String, dynamic> toJson() => {
    'id': id,
    'imagePath': imagePath,
    'detections': detections.map((d) => d.toJson()).toList(),
    'analyzedAt': analyzedAt.toIso8601String(),
    'visionModelVersion': visionModelVersion,
    'overallConfidence': overallConfidence,
    'requiresConfirmation': requiresConfirmation,
  };
}
