// ─────────────────────────────────────────────
// Analisador de Limitações para Casa Sem Equipamento
// ─────────────────────────────────────────────

import 'home_exercise_model.dart';

class HomeLimitationAnalyzer {
  
  // Analisa se um exercício é compatível, adaptável ou inadequado para uma pessoa
  static HomeExerciseAnalysis analyze({
    required HomeExercise exercise,
    required List<HomeUserLimitation> limitations,
    required String experienceLevel, // beginner, intermediate, advanced
    required double balanceCapability, // 0.0-1.0
    required double strengthCapability, // 0.0-1.0
    required double mobilityCapability, // 0.0-1.0
  }) {
    // ETAPA 1 — IDENTIFICAR DEMANDA (feito internamente em _compareCapabilities)
    
    // ETAPA 2 — IDENTIFICAR LIMITAÇÕES
    final relevantLimitations = _identifyRelevantLimitations(
      exercise: exercise,
      limitations: limitations,
    );
    
    // ETAPA 3 — COMPARAR
    final compatibility = _compareCapabilities(
      exercise: exercise,
      limitations: relevantLimitations,
      experienceLevel: experienceLevel,
      balanceCapability: balanceCapability,
      strengthCapability: strengthCapability,
      mobilityCapability: mobilityCapability,
    );
    
    // ETAPA 4 — TESTAR COMPATIBILIDADE
    if (compatibility == HomeCompatibility.compatible) {
      return HomeExerciseAnalysis(
        exercise: exercise,
        compatibility: HomeCompatibility.compatible,
        reason: 'Exercício compatível com a capacidade atual.',
      );
    }
    
    // ETAPA 5 — ADAPTAR
    final adaptations = _suggestAdaptations(
      exercise: exercise,
      limitations: relevantLimitations,
      strengthCapability: strengthCapability,
      mobilityCapability: mobilityCapability,
      balanceCapability: balanceCapability,
    );
    
    if (adaptations.isNotEmpty) {
      return HomeExerciseAnalysis(
        exercise: exercise,
        compatibility: HomeCompatibility.adaptable,
        reason: 'Exercício pode ser adaptado para a capacidade atual.',
        adaptations: adaptations,
      );
    }
    
    // ETAPA 6 — REGREDIR
    final regression = _findRegression(exercise);
    
    if (regression != null) {
      return HomeExerciseAnalysis(
        exercise: exercise,
        compatibility: HomeCompatibility.adaptable,
        reason: 'Exercício pode ser regredido para menor demanda.',
        suggestedRegression: regression,
      );
    }
    
    // ETAPA 7 — SUBSTITUIR
    final alternative = _findAlternative(exercise);
    
    if (alternative != null) {
      return HomeExerciseAnalysis(
        exercise: exercise,
        compatibility: HomeCompatibility.adaptable,
        reason: 'Exercício pode ser substituído por alternativa mais adequada.',
        suggestedAlternative: alternative,
      );
    }
    
    // ETAPA 8 — PRESERVAR FUNÇÃO
    // Se chegou aqui, o exercício é inadequado
    return HomeExerciseAnalysis(
      exercise: exercise,
      compatibility: HomeCompatibility.inadequate,
      reason: 'Demanda do exercício não é apropriada para a capacidade ou resposta atual.',
    );
  }
  
  // Identifica limitações relevantes para o exercício
  static List<HomeUserLimitation> _identifyRelevantLimitations({
    required HomeExercise exercise,
    required List<HomeUserLimitation> limitations,
  }) {
    return limitations.where((limitation) {
      // Verifica se a limitação afeta alguma região que o exercício demanda
      return exercise.demandRegions.contains(limitation.region);
    }).toList();
  }
  
  // Compara capacidades com demandas do exercício
  static HomeCompatibility _compareCapabilities({
    required HomeExercise exercise,
    required List<HomeUserLimitation> limitations,
    required String experienceLevel,
    required double balanceCapability,
    required double strengthCapability,
    required double mobilityCapability,
  }) {
    // Verifica se há limitações graves
    final hasSevereLimitation = limitations.any(
      (l) => l.severity == HomeLimitationSeverity.severe,
    );
    
    if (hasSevereLimitation) {
      return HomeCompatibility.inadequate;
    }
    
    // Verifica se há limitações moderadas
    final hasModerateLimitation = limitations.any(
      (l) => l.severity == HomeLimitationSeverity.moderate,
    );
    
    // Verifica capacidades vs demandas
    final meetsStrength = strengthCapability >= exercise.strengthDemand * 0.7;
    final meetsMobility = mobilityCapability >= exercise.mobilityDemand * 0.7;
    final meetsBalance = balanceCapability >= exercise.balanceDemand * 0.7;
    
    // Se não atende requisitos básicos
    if (!meetsStrength || !meetsMobility || !meetsBalance) {
      if (hasModerateLimitation) {
      return HomeCompatibility.inadequate;
      }
      return HomeCompatibility.adaptable;
    }
    
    // Verifica nível de experiência
    if (experienceLevel == 'beginner' && exercise.difficulty.index >= 3) {
      return HomeCompatibility.adaptable;
    }
    
    // Se há limitações leves
    if (limitations.isNotEmpty) {
      return HomeCompatibility.adaptable;
    }
    
    return HomeCompatibility.compatible;
  }
  
  // Sugere adaptações para o exercício
  static List<HomeAdaptation> _suggestAdaptations({
    required HomeExercise exercise,
    required List<HomeUserLimitation> limitations,
    required double strengthCapability,
    required double mobilityCapability,
    required double balanceCapability,
  }) {
    final adaptations = <HomeAdaptation>[];
    
    // Adaptações baseadas em limitações
    for (final limitation in limitations) {
      switch (limitation.region) {
        case HomeBodyRegion.knee:
          adaptations.add(const HomeAdaptation(
            description: 'Reduzir amplitude do movimento',
            type: HomeAdaptationType.reduceAmplitude,
          ));
          adaptations.add(const HomeAdaptation(
            description: 'Utilizar apoio para estabilidade',
            type: HomeAdaptationType.increaseStability,
          ));
          break;
          
        case HomeBodyRegion.hip:
          adaptations.add(const HomeAdaptation(
            description: 'Ajustar amplitude do quadril',
            type: HomeAdaptationType.reduceAmplitude,
          ));
          adaptations.add(const HomeAdaptation(
            description: 'Reduzir velocidade do movimento',
            type: HomeAdaptationType.reduceSpeed,
          ));
          break;
          
        case HomeBodyRegion.ankle:
          adaptations.add(const HomeAdaptation(
            description: 'Utilizar apoio para equilíbrio',
            type: HomeAdaptationType.increaseStability,
          ));
          adaptations.add(const HomeAdaptation(
            description: 'Reduzir amplitude',
            type: HomeAdaptationType.reduceAmplitude,
          ));
          break;
          
        case HomeBodyRegion.lowerBack:
          adaptations.add(const HomeAdaptation(
            description: 'Manter posição neutra da coluna',
            type: HomeAdaptationType.reduceComplexity,
          ));
          adaptations.add(const HomeAdaptation(
            description: 'Reduzir amplitude do movimento',
            type: HomeAdaptationType.reduceAmplitude,
          ));
          break;
          
        case HomeBodyRegion.shoulder:
          adaptations.add(const HomeAdaptation(
            description: 'Reduzir amplitude de elevação do braço',
            type: HomeAdaptationType.reduceAmplitude,
          ));
          adaptations.add(const HomeAdaptation(
            description: 'Modificar posição das mãos',
            type: HomeAdaptationType.changeSupport,
          ));
          break;
          
        case HomeBodyRegion.elbow:
          adaptations.add(const HomeAdaptation(
            description: 'Reduzir amplitude de extensão do cotovelo',
            type: HomeAdaptationType.reduceAmplitude,
          ));
          adaptations.add(const HomeAdaptation(
            description: 'Reduzir volume de repetições',
            type: HomeAdaptationType.reduceVolume,
          ));
          break;
          
        case HomeBodyRegion.wrist:
          adaptations.add(const HomeAdaptation(
            description: 'Modificar apoio das mãos',
            type: HomeAdaptationType.changeSupport,
          ));
          adaptations.add(const HomeAdaptation(
            description: 'Reduzir carga no punho',
            type: HomeAdaptationType.reduceDifficulty,
          ));
          break;
          
        case HomeBodyRegion.neck:
          adaptations.add(const HomeAdaptation(
            description: 'Manter posição neutra do pescoço',
            type: HomeAdaptationType.reduceComplexity,
          ));
          break;
          
        case HomeBodyRegion.hamstring:
          adaptations.add(const HomeAdaptation(
            description: 'Reduzir amplitude de alongamento',
            type: HomeAdaptationType.reduceAmplitude,
          ));
          adaptations.add(const HomeAdaptation(
            description: 'Controlar velocidade do movimento',
            type: HomeAdaptationType.reduceSpeed,
          ));
          break;
          
        case HomeBodyRegion.groin:
          adaptations.add(const HomeAdaptation(
            description: 'Reduzir amplitude de abdução',
            type: HomeAdaptationType.reduceAmplitude,
          ));
          adaptations.add(const HomeAdaptation(
            description: 'Começar com isometria',
            type: HomeAdaptationType.reduceComplexity,
          ));
          break;
      }
    }
    
    // Adaptações baseadas em capacidades
    if (strengthCapability < exercise.strengthDemand) {
      adaptations.add(const HomeAdaptation(
        description: 'Reduzir dificuldade do exercício',
        type: HomeAdaptationType.reduceDifficulty,
      ));
    }
    
    if (balanceCapability < exercise.balanceDemand) {
      adaptations.add(const HomeAdaptation(
        description: 'Aumentar estabilidade com apoio',
        type: HomeAdaptationType.increaseStability,
      ));
    }
    
    if (mobilityCapability < exercise.mobilityDemand) {
      adaptations.add(const HomeAdaptation(
        description: 'Reduzir amplitude conforme mobilidade',
        type: HomeAdaptationType.reduceAmplitude,
      ));
    }
    
    return adaptations;
  }
  
  // Encontra exercício de regressão
  static HomeExercise? _findRegression(HomeExercise exercise) {
    if (exercise.regressionId == null) return null;
    
    // Busca na biblioteca pelo ID de regressão
    // Nota: Esta é uma implementação simplificada
    // Na implementação completa, deve-se buscar na biblioteca
    return null;
  }
  
  // Encontra exercício alternativo
  static HomeExercise? _findAlternative(HomeExercise exercise) {
    if (exercise.alternativeIds.isEmpty) return null;
    
    // Busca na biblioteca pelo ID alternativo
    // Nota: Esta é uma implementação simplificada
    // Na implementação completa, deve-se buscar na biblioteca
    return null;
  }
  
  // Analisa feedback do usuário e sugere próximos passos
  static HomeFeedbackAnalysis analyzeFeedback({
    required HomeFeedback feedback,
    required HomeExercise exercise,
  }) {
    switch (feedback.quality) {
      case HomeFeedbackQuality.executedWell:
        return HomeFeedbackAnalysis(
          action: HomeFeedbackAction.progress,
          reason: 'Executou bem. Pode progredir conforme capacidade.',
          suggestedExercise: exercise.progressionId != null ? 'progression' : null,
        );
        
      case HomeFeedbackQuality.executedWithAdaptation:
        return HomeFeedbackAnalysis(
          action: HomeFeedbackAction.maintain,
          reason: 'Executou com adaptação. Manter adaptação ou testar pequena progressão.',
          suggestedExercise: null,
        );
        
      case HomeFeedbackQuality.executedWithDiscomfort:
        return HomeFeedbackAnalysis(
          action: HomeFeedbackAction.adapt,
          reason: 'Executou com desconforto. Reavaliar e adaptar.',
          suggestedExercise: exercise.regressionId,
        );
        
      case HomeFeedbackQuality.couldNotExecute:
        return HomeFeedbackAnalysis(
          action: HomeFeedbackAction.regress,
          reason: 'Não conseguiu executar. Regredir para exercício mais fácil.',
          suggestedExercise: exercise.regressionId,
        );
        
      case HomeFeedbackQuality.worsenedSymptoms:
        return HomeFeedbackAnalysis(
          action: HomeFeedbackAction.avoid,
          reason: 'Piorou os sintomas. Evitar esta variação e procurar alternativa.',
          suggestedExercise: exercise.alternativeIds.isNotEmpty 
            ? exercise.alternativeIds.first 
            : null,
        );
    }
  }
}

class HomeFeedbackAnalysis {
  final HomeFeedbackAction action;
  final String reason;
  final String? suggestedExercise;

  const HomeFeedbackAnalysis({
    required this.action,
    required this.reason,
    this.suggestedExercise,
  });
}

enum HomeFeedbackAction {
  progress,   // Manter ou progredir
  maintain,   // Manter a adaptação
  adapt,      // Reavaliar e adaptar
  regress,    // Regredir
  avoid,      // Evitar aquela variação
}
