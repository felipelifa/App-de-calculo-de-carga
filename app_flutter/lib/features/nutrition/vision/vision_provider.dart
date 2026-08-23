import 'dart:io';
import 'food_detection_model.dart';

// ─────────────────────────────────────────────
// Interface abstrata para detecção de alimentos
// Permite trocar implementação sem afetar o resto do sistema
// ─────────────────────────────────────────────

abstract class VisionProvider {
  /// Nome do provider para debug/logging
  String get name;
  
  /// Versão do modelo
  String get version;
  
  /// Se está disponível para uso
  Future<bool> get isAvailable;
  
  /// Detectar alimentos em uma imagem
  Future<MealAnalysisResult> detectFoods(File image);
  
  /// Detectar alimentos por barcode
  Future<FoodDetection?> detectByBarcode(String barcode);
}

// ─────────────────────────────────────────────
// Implementação com Gemini Vision
// ─────────────────────────────────────────────

class GeminiVisionProvider implements VisionProvider {
  final String apiKey;
  
  GeminiVisionProvider({required this.apiKey});
  
  @override
  String get name => 'Gemini Vision';
  
  @override
  String get version => '1.0.0';
  
  @override
  Future<bool> get isAvailable async => apiKey.isNotEmpty;
  
  @override
  Future<MealAnalysisResult> detectFoods(File image) async {
    // TODO: Implementar com google_generative_ai
    // Por enquanto retorna resultado vazio
    return MealAnalysisResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      imagePath: image.path,
      detections: [],
      analyzedAt: DateTime.now(),
      visionModelVersion: version,
      overallConfidence: 0.0,
      requiresConfirmation: true,
    );
  }
  
  @override
  Future<FoodDetection?> detectByBarcode(String barcode) async {
    // Barcode scanning não usa Gemini
    return null;
  }
}

// ─────────────────────────────────────────────
// Implementação local (sem IA)
// Usa apenas análise de cor/textura básica
// ─────────────────────────────────────────────

class LocalVisionProvider implements VisionProvider {
  @override
  String get name => 'Local Analysis';
  
  @override
  String get version => '1.0.0';
  
  @override
  Future<bool> get isAvailable async => true;
  
  @override
  Future<MealAnalysisResult> detectFoods(File image) async {
    // Análise local básica (placeholder)
    // Futuramente pode usar OpenCV ou ML Kit
    return MealAnalysisResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      imagePath: image.path,
      detections: [],
      analyzedAt: DateTime.now(),
      visionModelVersion: version,
      overallConfidence: 0.0,
      requiresConfirmation: true,
    );
  }
  
  @override
  Future<FoodDetection?> detectByBarcode(String barcode) async {
    return null;
  }
}

// ─────────────────────────────────────────────
// Factory para criar o provider adequado
// ─────────────────────────────────────────────

class VisionProviderFactory {
  static VisionProvider create({
    String? geminiApiKey,
  }) {
    if (geminiApiKey != null && geminiApiKey.isNotEmpty) {
      return GeminiVisionProvider(apiKey: geminiApiKey);
    }
    return LocalVisionProvider();
  }
}
