import 'food_detection_model.dart';

// ─────────────────────────────────────────────
// Motor de Confiança
// Calcula e gerencia níveis de confiança
// ─────────────────────────────────────────────

class ConfidenceEngine {
  /// Calcula confiança geral de uma análise
  static double calculateOverallConfidence(List<FoodDetection> detections) {
    if (detections.isEmpty) return 0.0;
    
    final sum = detections.fold<double>(0, (acc, d) => acc + d.confidence);
    return sum / detections.length;
  }
  
  /// Determina se precisa de confirmação do usuário
  static bool requiresConfirmation(List<FoodDetection> detections) {
    // Se algum item tem confiança baixa, precisa confirmar
    if (detections.any((d) => d.confidenceLevel == ConfidenceLevel.low)) {
      return true;
    }
    
    // Se a confiança geral é média, precisa confirmar
    final overall = calculateOverallConfidence(detections);
    if (overall < 0.75) {
      return true;
    }
    
    return false;
  }
  
  /// Retorna mensagem amigável baseada no nível de confiança
  static String getConfidenceMessage(ConfidenceLevel level) {
    switch (level) {
      case ConfidenceLevel.high:
        return 'Identifiquei com bastante segurança.';
      case ConfidenceLevel.medium:
        return 'Tenho uma dúvida sobre este alimento.';
      case ConfidenceLevel.low:
        return 'Pode confirmar este item?';
      case ConfidenceLevel.unknown:
        return 'Não consegui identificar este alimento.';
    }
  }
  
  /// Retorna cor para indicar confiança
  static int getConfidenceColor(ConfidenceLevel level) {
    switch (level) {
      case ConfidenceLevel.high:
        return 0xFF22C55E; // Verde
      case ConfidenceLevel.medium:
        return 0xFFF59E0B; // Amarelo
      case ConfidenceLevel.low:
        return 0xFFEF4444; // Vermelho
      case ConfidenceLevel.unknown:
        return 0xFF6B7280; // Cinza
    }
  }
  
  /// Retorna ícone para indicar confiança
  static String getConfidenceIcon(ConfidenceLevel level) {
    switch (level) {
      case ConfidenceLevel.high:
        return '🟢';
      case ConfidenceLevel.medium:
        return '🟡';
      case ConfidenceLevel.low:
        return '🔴';
      case ConfidenceLevel.unknown:
        return '⚪';
    }
  }
  
  /// Filtra detecções por nível mínimo de confiança
  static List<FoodDetection> filterByConfidence(
    List<FoodDetection> detections,
    ConfidenceLevel minLevel,
  ) {
    return detections.where((d) {
      switch (minLevel) {
        case ConfidenceLevel.high:
          return d.confidence >= 0.85;
        case ConfidenceLevel.medium:
          return d.confidence >= 0.60;
        case ConfidenceLevel.low:
          return d.confidence >= 0.30;
        case ConfidenceLevel.unknown:
          return true;
      }
    }).toList();
  }
}
