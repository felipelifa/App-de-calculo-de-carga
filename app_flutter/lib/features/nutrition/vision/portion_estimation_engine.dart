import 'food_detection_model.dart';

// ─────────────────────────────────────────────
// Motor de Estimativa de Porção
// Estima quantidades baseado em referências visuais
// ─────────────────────────────────────────────

class PortionEstimationEngine {
  /// Gramas padrão por categoria de alimento
  static const Map<String, Map<PortionSize, double>> _defaultPortions = {
    'carboidrato': {
      PortionSize.small: 80.0,
      PortionSize.normal: 150.0,
      PortionSize.large: 220.0,
    },
    'proteina': {
      PortionSize.small: 80.0,
      PortionSize.normal: 150.0,
      PortionSize.large: 220.0,
    },
    'leguminosa': {
      PortionSize.small: 60.0,
      PortionSize.normal: 120.0,
      PortionSize.large: 180.0,
    },
    'vegetal': {
      PortionSize.small: 40.0,
      PortionSize.normal: 80.0,
      PortionSize.large: 120.0,
    },
    'fruta': {
      PortionSize.small: 80.0,
      PortionSize.normal: 150.0,
      PortionSize.large: 200.0,
    },
    'laticinio': {
      PortionSize.small: 30.0,
      PortionSize.normal: 60.0,
      PortionSize.large: 100.0,
    },
    'gordura': {
      PortionSize.small: 5.0,
      PortionSize.normal: 10.0,
      PortionSize.large: 20.0,
    },
    'bebida': {
      PortionSize.small: 150.0,
      PortionSize.normal: 250.0,
      PortionSize.large: 400.0,
    },
  };

  /// Estima porção baseado na categoria e tamanho visual
  static PortionEstimate estimate({
    required String? category,
    required PortionSize? sizeCategory,
    double? visualArea, // 0.0 a 1.0 (área relativa na imagem)
    String? referenceObject,
  }) {
    // Se temos tamanho visual, usar ele
    if (sizeCategory != null) {
      final grams = _getGramsForCategory(category, sizeCategory);
      return PortionEstimate(
        grams: grams,
        sizeCategory: sizeCategory,
        confidence: 0.7,
        referenceObject: referenceObject,
      );
    }

    // Se temos área visual, estimar tamanho
    if (visualArea != null) {
      final size = _estimateSizeFromArea(visualArea);
      final grams = _getGramsForCategory(category, size);
      return PortionEstimate(
        grams: grams,
        sizeCategory: size,
        confidence: 0.5,
        referenceObject: referenceObject,
      );
    }

    // Fallback: porção normal
    final grams = _getGramsForCategory(category, PortionSize.normal);
    return PortionEstimate(
      grams: grams,
      sizeCategory: PortionSize.normal,
      confidence: 0.3,
      referenceObject: referenceObject,
    );
  }

  /// Retorna gramas para uma categoria e tamanho
  static double _getGramsForCategory(String? category, PortionSize size) {
    final normalizedCategory = _normalizeCategory(category);
    final portions = _defaultPortions[normalizedCategory];
    
    if (portions != null) {
      return portions[size] ?? portions[PortionSize.normal]!;
    }
    
    // Fallback: usar valores genéricos
    switch (size) {
      case PortionSize.small:
        return 80.0;
      case PortionSize.normal:
        return 150.0;
      case PortionSize.large:
        return 220.0;
    }
  }

  /// Estima tamanho baseado na área visual
  static PortionSize _estimateSizeFromArea(double area) {
    if (area < 0.15) return PortionSize.small;
    if (area < 0.40) return PortionSize.normal;
    return PortionSize.large;
  }

  /// Normaliza nome da categoria
  static String _normalizeCategory(String? category) {
    if (category == null) return 'outros';
    
    final normalized = category.toLowerCase().trim();
    
    // Mapear variações para categorias padrão
    if (normalized.contains('arroz') || 
        normalized.contains('massa') || 
        normalized.contains('batata') ||
        normalized.contains('pão') ||
        normalized.contains('macarrão')) {
      return 'carboidrato';
    }
    if (normalized.contains('frango') || 
        normalized.contains('carne') || 
        normalized.contains('peixe') ||
        normalized.contains('ovo') ||
        normalized.contains('porco')) {
      return 'proteina';
    }
    if (normalized.contains('feijão') || 
        normalized.contains('lentilha') || 
        normalized.contains('grão')) {
      return 'leguminosa';
    }
    if (normalized.contains('salada') || 
        normalized.contains('alface') || 
        normalized.contains('tomate') ||
        normalized.contains('cenoura') ||
        normalized.contains('brócolis')) {
      return 'vegetal';
    }
    if (normalized.contains('banana') || 
        normalized.contains('maçã') || 
        normalized.contains('laranja') ||
        normalized.contains('fruta')) {
      return 'fruta';
    }
    if (normalized.contains('leite') || 
        normalized.contains('queijo') || 
        normalized.contains('iogurte')) {
      return 'laticinio';
    }
    if (normalized.contains('óleo') || 
        normalized.contains('manteiga') || 
        normalized.contains('azeite')) {
      return 'gordura';
    }
    if (normalized.contains('suco') || 
        normalized.contains('refrigerante') || 
        normalized.contains('água') ||
        normalized.contains('café') ||
        normalized.contains('chá')) {
      return 'bebida';
    }
    
    return 'outros';
  }

  /// Retorna mensagem amigável para o tamanho
  static String getSizeMessage(PortionSize size) {
    switch (size) {
      case PortionSize.small:
        return 'Pouco';
      case PortionSize.normal:
        return 'Normal';
      case PortionSize.large:
        return 'Bastante';
    }
  }

  /// Retorna ícone para o tamanho
  static String getSizeIcon(PortionSize size) {
    switch (size) {
      case PortionSize.small:
        return '🔽';
      case PortionSize.normal:
        return '➡️';
      case PortionSize.large:
        return '🔼';
    }
  }
}
