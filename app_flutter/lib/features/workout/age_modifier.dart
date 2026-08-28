import 'dart:math';

/// Modificador de idade para o motor de prescrição.
///
/// A idade NÃO é uma regra rígida. É um modificador contextual
/// que atua sobre outras variáveis (recuperação, complexidade, etc.).
///
/// Modelo: IDADE + CAPACIDADE + EXPERIÊNCIA + HISTÓRICO + OBJETIVO + RECUPERAÇÃO + CONTEXTO = DECISÃO
class AgeModifier {
  /// Retorna modificadores de volume baseados em idade + experiência + capacidade.
  /// Valores > 1.0 = mais volume, < 1.0 = menos volume.
  static double volumeModifier({
    required int age,
    required String experienceLevel,
    required String fitnessCapacity,
    required String recoveryCapacity,
  }) {
    double mod = 1.0;

    // Idade: não é regra rígida, apenas modificador suave
    if (age >= 60) {
      // Maior recuperação necessária, mas não reduzir drasticamente
      mod *= 0.85;
      // Compensar se experiência/capacidade são altas
      if (experienceLevel == 'advanced' && fitnessCapacity == 'high') mod += 0.05;
    } else if (age >= 50) {
      mod *= 0.92;
    } else if (age >= 40) {
      mod *= 0.97;
    }
    // Idade < 40: sem penalidade

    // Capacidade física pode compensar idade
    if (fitnessCapacity == 'high') mod += 0.05;
    if (fitnessCapacity == 'low') mod -= 0.08;

    // Recuperação
    if (recoveryCapacity == 'low') mod -= 0.05;

    return mod.clamp(0.65, 1.15);
  }

  /// Retorna modificador de complexidade técnica.
  /// Maior idade pode justificar menor complexidade inicial,
  /// mas experiência compensa.
  static double complexityModifier({
    required int age,
    required String experienceLevel,
    required String fitnessCapacity,
  }) {
    double mod = 1.0;

    // Idade pode aumentar necessidade de controle, não reduzir complexidade
    // se a pessoa tem experiência
    if (age >= 55 && experienceLevel == 'beginner') {
      mod *= 0.7; // Iniciante + mais velho: simplificar
    } else if (age >= 55 && experienceLevel == 'intermediate') {
      mod *= 0.85;
    }
    // Avançado: idade não reduz complexidade
    if (experienceLevel == 'advanced') {
      mod = max(mod, 0.9);
    }

    if (fitnessCapacity == 'low') mod *= 0.8;

    return mod.clamp(0.5, 1.0);
  }

  /// Retorna modificador de descanso entre séries.
  /// Mais idade pode justificar descansos um pouco maiores.
  static int restSecondsModifier({
    required int age,
    required String experienceLevel,
    required int baseRestSeconds,
  }) {
    if (age >= 55 && experienceLevel != 'advanced') {
      return (baseRestSeconds * 1.15).round();
    }
    return baseRestSeconds;
  }

  /// Verifica se deve priorizar exercícios de mobilidade/equilíbrio/funcional.
  /// Idade alta + baixa experiência = priorizar capacidades funcionais.
  static bool shouldPrioritizeFunctional({
    required int age,
    required String experienceLevel,
    required String fitnessCapacity,
  }) {
    if (age >= 55 && (experienceLevel == 'beginner' || fitnessCapacity == 'low')) {
      return true;
    }
    if (age >= 65) return true;
    return false;
  }

  /// Retorna bonuses de capacidade para exercícios funcionais/unilaterais.
  /// Usado pelo motor de seleção para priorizar certos padrões.
  static double functionalBonus({
    required int age,
    required String experienceLevel,
    required String primaryGoal,
  }) {
    double bonus = 0;

    // Mais velhos: bonus para unilateral, estabilidade, mobilidade
    if (age >= 50) {
      bonus += 1.5;
      if (primaryGoal == 'general_health' || primaryGoal == 'fat_loss') {
        bonus += 1.0;
      }
    }

    // Iniciantes em qualquer idade: bonus para exercícios fundamentais
    if (experienceLevel == 'beginner') {
      bonus += 0.5;
    }

    return bonus;
  }
}
