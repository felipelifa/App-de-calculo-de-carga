import '../food_model.dart';
import '../nutrition_service.dart';
import 'food_detection_model.dart';

// ─────────────────────────────────────────────
// Motor de Correspondência de Alimentos
// Conecta detecções visuais ao banco nutricional
// ─────────────────────────────────────────────

class FoodMatchResult {
  final FoodModel? food;
  final double matchConfidence; // 0.0 a 1.0
  final String? matchReason; // Por que este alimento foi selecionado
  final List<FoodModel> alternatives; // Outras opções possíveis

  const FoodMatchResult({
    this.food,
    required this.matchConfidence,
    this.matchReason,
    this.alternatives = const [],
  });
}

class FoodMatchingEngine {
  final NutritionService _nutritionService;

  FoodMatchingEngine({NutritionService? nutritionService})
      : _nutritionService = nutritionService ?? NutritionService();

  /// Tenta encontrar o alimento correspondente no banco de dados
  Future<FoodMatchResult> matchDetection(FoodDetection detection) async {
    // 1. Buscar por nome
    final searchResults = await _nutritionService.searchFoods(detection.name);
    
    if (searchResults.isEmpty) {
      return FoodMatchResult(
        matchConfidence: 0.0,
        matchReason: 'Nenhum alimento encontrado',
      );
    }

    // 2. Rankear resultados por relevância
    final ranked = _rankMatches(searchResults, detection);
    
    if (ranked.isEmpty) {
      return FoodMatchResult(
        matchConfidence: 0.0,
        matchReason: 'Nenhuma correspondência adequada',
      );
    }

    // 3. Retornar melhor match + alternativas
    final best = ranked.first;
    final alternatives = ranked.skip(1).take(5).toList();

    return FoodMatchResult(
      food: best.key,
      matchConfidence: best.value,
      matchReason: _getMatchReason(best.key, detection),
      alternatives: alternatives.map((e) => e.key).toList(),
    );
  }

  /// Rankeia os resultados por relevância
  List<MapEntry<FoodModel, double>> _rankMatches(
    List<FoodModel> results,
    FoodDetection detection,
  ) {
    final scored = <MapEntry<FoodModel, double>>[];
    
    for (final food in results) {
      double score = 0.0;
      
      // Match exato do nome
      if (_normalize(food.name) == _normalize(detection.name)) {
        score += 100.0;
      }
      // Nome começa com o termo buscado
      else if (_normalize(food.name).startsWith(_normalize(detection.name))) {
        score += 80.0;
      }
      // Nome contém o termo buscado
      else if (_normalize(food.name).contains(_normalize(detection.name))) {
        score += 60.0;
      }
      // Termo buscado contém o nome
      else if (_normalize(detection.name).contains(_normalize(food.name))) {
        score += 40.0;
      }
      
      // Bônus para fontes verificadas
      if (food.isVerified) {
        score += 20.0;
      }
      
      // Bônus para fonte TBCA (brasileira)
      if (food.source == 'tbca') {
        score += 15.0;
      }
      
      // Bônus para alimentos já consumidos
      score += food.timesConsumed * 2.0;
      
      // Bônus para categoria correspondente
      if (detection.category != null && 
          food.category.toLowerCase() == detection.category!.toLowerCase()) {
        score += 10.0;
      }
      
      if (score > 0) {
        scored.add(MapEntry(food, score / 100.0)); // Normalizar para 0-1
      }
    }
    
    // Ordenar por score decrescente
    scored.sort((a, b) => b.value.compareTo(a.value));
    
    return scored;
  }

  String _getMatchReason(FoodModel food, FoodDetection detection) {
    if (_normalize(food.name) == _normalize(detection.name)) {
      return 'Correspondência exata';
    }
    if (food.source == 'tbca') {
      return 'Tabela brasileira de composição de alimentos';
    }
    if (food.isVerified) {
      return 'Alimento verificado';
    }
    return 'Melhor correspondência disponível';
  }

  String _normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[áàâãä]'), 'a')
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[íìîï]'), 'i')
        .replaceAll(RegExp(r'[óòôõö]'), 'o')
        .replaceAll(RegExp(r'[úùûü]'), 'u')
        .replaceAll('ç', 'c')
        .trim();
  }
}
