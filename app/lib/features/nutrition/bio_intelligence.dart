import 'package:flutter/material.dart';

enum HealthTag { amidoAmigo, escudoBio, superNutriente }

class BioIntelligence {
  static List<HealthTag> analyzeFood(String name, {String category = ''}) {
    final lowerName = name.toLowerCase();
    List<HealthTag> tags = [];

    // Amidos Resistentes
    if (lowerName.contains('feijão') ||
        lowerName.contains('arroz integral') ||
        lowerName.contains('batata doce') ||
        lowerName.contains('aveia') ||
        lowerName.contains('lentilha') ||
        lowerName.contains('grão-de-bico') ||
        lowerName.contains('mandioca') ||
        lowerName.contains('tapioca') ||
        lowerName.contains('milho')) {
      tags.add(HealthTag.amidoAmigo);
    }

    // Polifenóis e Antioxidantes
    if (lowerName.contains('açaí') ||
        lowerName.contains('laranja') ||
        lowerName.contains('limão') ||
        lowerName.contains('morango') ||
        lowerName.contains('couve') ||
        lowerName.contains('brócolis') ||
        lowerName.contains('espinafre') ||
        lowerName.contains('tomate') ||
        lowerName.contains('amora') ||
        lowerName.contains('uva') ||
        lowerName.contains('azeite')) {
      tags.add(HealthTag.escudoBio);
    }

    // Densidade Extrema
    if (lowerName.contains('acerola') ||
        lowerName.contains('castanha') ||
        lowerName.contains('ovos') ||
        lowerName.contains('salmão') ||
        lowerName.contains('fígado') ||
        lowerName.contains('amendoim')) {
      tags.add(HealthTag.superNutriente);
    }

    return tags;
  }

  static bool isPlantSpecies(String name, String category) {
    final lowerName = name.toLowerCase();
    final lowerCat = category.toLowerCase();
    if (lowerCat.contains('fruta') ||
        lowerCat.contains('vegetal') ||
        lowerCat.contains('legume') ||
        lowerCat.contains('hortaliça') ||
        lowerCat.contains('semente') ||
        lowerCat.contains('grão') ||
        lowerCat.contains('tempero')) {
      return true;
    }
    final plantKeywords = [
      'maçã', 'banana', 'tomate', 'alface', 'feijão', 'arroz', 'aveia', 'lentilha',
      'açaí', 'laranja', 'limão', 'morango', 'couve', 'brócolis', 'espinafre',
      'amora', 'uva', 'castanha', 'amendoim', 'batata', 'cenoura', 'pepino',
      'alho', 'cebola', 'salsa', 'coentro'
    ];
    for (final kw in plantKeywords) {
      if (lowerName.contains(kw)) return true;
    }
    return false;
  }

  static String extractPlantSpeciesRoot(String name) {
    // Normaliza para o contador de diversidade. Ex: "ArrozIntegral" e "ArrozBranco" -> "arroz"
    final n = name.toLowerCase();
    if (n.contains('arroz')) return 'arroz';
    if (n.contains('feijão')) return 'feijão';
    if (n.contains('batata')) return 'batata';
    return n.split(' ').first; 
  }

  static int calculateDiscountedCalories(int originalCalories, List<HealthTag> tags) {
    if (tags.contains(HealthTag.amidoAmigo)) {
      return (originalCalories * 0.9).round(); // -10% metabolic discount
    }
    return originalCalories;
  }

  static Widget buildBadge(HealthTag tag, BuildContext context) {
    Color bg;
    String label;
    String tooltip;

    switch (tag) {
      case HealthTag.amidoAmigo:
        bg = Colors.green.shade700;
        label = 'Amido Amigo';
        tooltip = 'Este alimento alimenta suas bactérias boas e tem menor impacto no seu estoque de gordura.';
        break;
      case HealthTag.escudoBio:
        bg = Colors.purple.shade600;
        label = 'Escudo Bio';
        tooltip = 'Rico em antioxidantes! Protege suas células e combate a inflamação.';
        break;
      case HealthTag.superNutriente:
        bg = Colors.orange.shade800;
        label = 'Top Nutrientes';
        tooltip = 'Alta densidade de vitaminas essenciais para performance.';
        break;
    }

    return Tooltip(
      message: tooltip,
      triggerMode: TooltipTriggerMode.tap,
      showDuration: const Duration(seconds: 4),
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: bg.withValues(alpha: 0.15),
          border: Border.all(color: bg.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(color: bg, fontSize: 9, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  static Widget buildPlantGamificationPanel(int currentScore) {
    int target = 30;
    double pct = (currentScore / target).clamp(0.0, 1.0);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('🛡️ Escudo Metabólico', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              Text('$currentScore/$target Plantas', style: TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: Colors.purple.withValues(alpha: 0.1),
              color: Colors.purpleAccent,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            pct >= 1.0 
              ? 'Incrível! Seu exército de bactérias boas atingiu o poder máximo essa semana!'
              : 'Você já desbloqueou $currentScore/$target espécies de plantas esta semana. Falta pouco para o Score Máximo da Microbiota!',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
          ),
        ],
      ),
    );
  }
}
