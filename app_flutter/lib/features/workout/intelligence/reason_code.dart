/// Reason codes for exercise selection decisions.
/// Structured codes for future UI explanation.
enum ReasonCode {
  // ── Hard filters ──
  environmentMatch,
  environmentMismatch,
  equipmentAvailable,
  equipmentNotAvailable,
  difficultyCompatible,
  difficultyTooHigh,
  userDisliked,
  safetyAlertActive,

  // ── Soft ranking ──
  goalAlignment,
  goalMismatch,
  patternMatch,
  patternMismatch,
  levelCompatible,
  levelMismatch,
  demandCapacityMatch,
  demandNeedsAdaptation,
  demandIncompatible,
  limitationCompatible,
  limitationAdaptable,
  limitationIncompatible,
  userPreferred,
  recentlyUsed,
  lowSessionRedundancy,
  highSessionRedundancy,

  // ── Session composition ──
  fulfillsPrimaryPattern,
  fulfillsSecondaryPattern,
  fitsSessionRole,
  redundancyAvoidance,
  timeConstraint,
  weeklyDistribution,

  // ── Prescription ──
  v2EngineRulesApplied,
  ageAdjusted,
  levelAdjusted,
  goalAdjusted,
}

/// Extension for converting reason codes to display strings.
extension ReasonCodeX on ReasonCode {
  String get label {
    switch (this) {
      case ReasonCode.environmentMatch:
        return 'Ambiente compatível';
      case ReasonCode.environmentMismatch:
        return 'Ambiente incompatível';
      case ReasonCode.equipmentAvailable:
        return 'Equipamento disponível';
      case ReasonCode.equipmentNotAvailable:
        return 'Equipamento não disponível';
      case ReasonCode.difficultyCompatible:
        return 'Dificuldade compatível';
      case ReasonCode.difficultyTooHigh:
        return 'Dificuldade muito alta';
      case ReasonCode.userDisliked:
        return 'Exercício evitado pelo usuário';
      case ReasonCode.safetyAlertActive:
        return 'Alerta de segurança ativo';
      case ReasonCode.goalAlignment:
        return 'Alinhado com o objetivo';
      case ReasonCode.goalMismatch:
        return 'Não alinhado com o objetivo';
      case ReasonCode.patternMatch:
        return 'Padrão de movimento necessário';
      case ReasonCode.patternMismatch:
        return 'Padrão não necessário';
      case ReasonCode.levelCompatible:
        return 'Nível compatível';
      case ReasonCode.levelMismatch:
        return 'Nível incompatível';
      case ReasonCode.demandCapacityMatch:
        return 'Demanda dentro da capacidade';
      case ReasonCode.demandNeedsAdaptation:
        return 'Demanda exige adaptação';
      case ReasonCode.demandIncompatible:
        return 'Demanda incompatível com capacidade';
      case ReasonCode.limitationCompatible:
        return 'Limitação do usuário compatível';
      case ReasonCode.limitationAdaptable:
        return 'Limitação com adaptação disponível';
      case ReasonCode.limitationIncompatible:
        return 'Limitação incompatível';
      case ReasonCode.userPreferred:
        return 'Exercício preferido pelo usuário';
      case ReasonCode.recentlyUsed:
        return 'Usado recentemente';
      case ReasonCode.lowSessionRedundancy:
        return 'Baixa redundância na sessão';
      case ReasonCode.highSessionRedundancy:
        return 'Alta redundância na sessão';
      case ReasonCode.fulfillsPrimaryPattern:
        return 'Atende padrão principal';
      case ReasonCode.fulfillsSecondaryPattern:
        return 'Atende padrão secundário';
      case ReasonCode.fitsSessionRole:
        return 'Cabe no papel da sessão';
      case ReasonCode.redundancyAvoidance:
        return 'Evita redundância';
      case ReasonCode.timeConstraint:
        return 'Restrição de tempo';
      case ReasonCode.weeklyDistribution:
        return 'Distribuição semanal';
      case ReasonCode.v2EngineRulesApplied:
        return 'Regras V2 aplicadas';
      case ReasonCode.ageAdjusted:
        return 'Ajustado por idade';
      case ReasonCode.levelAdjusted:
        return 'Ajustado por nível';
      case ReasonCode.goalAdjusted:
        return 'Ajustado por objetivo';
    }
  }
}
