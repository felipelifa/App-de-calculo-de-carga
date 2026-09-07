// ─────────────────────────────────────────────
// Modelo de Exercício para Casa Sem Equipamento
// ─────────────────────────────────────────────

enum HomeMovementPattern {
  squat,              // Agachamento (dominante de joelho)
  hipHinge,           // Dominante de quadril
  pushHorizontal,     // Empurrar horizontal
  pullHorizontal,     // Puxar horizontal (condicional)
  unilateral,         // Unilateral / Locomoção
  coreAntiExtension,  // Core anti-extensão
  calf,               // Panturrilha
  hipExtension,       // Extensão de quadril / Glúteo
  coreLateral,        // Core lateral / Anti-flexão lateral
  coreRotation,       // Core rotacional / Anti-rotação
  coreFlexion,        // Core flexão de tronco
  hipAbduction,       // Abdução de quadril
  hipAdduction,       // Adução de quadril
  kneeExtension,      // Extensão de joelho / Quadríceps
  kneeFlexion,        // Flexão de joelho / Posteriores
  pushVertical,       // Empurrar vertical
  pullVertical,       // Puxar vertical (condicional)
  locomotion,         // Locomoção / Deslocamento
  conditioning,       // Condicionamento cardiorrespiratório
  power,              // Potência / Movimentos explosivos
  balance,            // Equilíbrio / Controle motor
  mobility,           // Mobilidade funcional
}

enum HomeDifficulty {
  level1, // Mais fácil
  level2,
  level3,
  level4,
  level5, // Mais difícil
}

enum HomeCompatibility {
  compatible,  // Pode ser realizado conforme prescrito
  adaptable,   // Pode ser adaptado para a pessoa
  inadequate,  // Não é apropriado mesmo após adaptações
}

enum HomeBodyRegion {
  knee,
  hip,
  ankle,
  lowerBack,
  shoulder,
  elbow,
  wrist,
  neck,
  hamstring,
  groin,
}

class HomeExercise {
  final String id;
  final String name;
  final String nameEn;
  final HomeMovementPattern pattern;
  final HomeDifficulty difficulty;
  final List<String> primaryMuscles;
  final List<String> secondaryMuscles;
  final List<String> equipment; // Sempre vazio para casa sem equipamento
  /// External records must explicitly confirm their equipment metadata.
  final bool equipmentMetadataVerified;
  final List<HomeBodyRegion> demandRegions; // Regiões que o exercício demanda
  final List<String> cues;
  final String? videoUrl;

  // Progressão e regressão
  final String? regressionId; // Exercício mais fácil
  final String? progressionId; // Exercício mais difícil
  final List<String> alternativeIds; // Exercícios de função semelhante

  // Demandas do exercício
  final double strengthDemand;    // 0.0-1.0
  final double mobilityDemand;    // 0.0-1.0
  final double balanceDemand;     // 0.0-1.0
  final double stabilityDemand;   // 0.0-1.0
  final double coordinationDemand; // 0.0-1.0
  final double impactLevel;       // 0.0-1.0 (para potência/saltos)

  // Função principal do exercício
  final String primaryFunction;

  // Se o exercício é unilateral
  final bool isUnilateral;

  // Se o exercício é condicional (precisa de estrutura/equipamento)
  final bool isConditional;
  final String? conditionalRequirement;

  const HomeExercise({
    required this.id,
    required this.name,
    this.nameEn = '',
    required this.pattern,
    required this.difficulty,
    required this.primaryMuscles,
    this.secondaryMuscles = const [],
    this.equipment = const [],
    this.equipmentMetadataVerified = true,
    required this.demandRegions,
    this.cues = const [],
    this.videoUrl,
    this.regressionId,
    this.progressionId,
    this.alternativeIds = const [],
    this.strengthDemand = 0.5,
    this.mobilityDemand = 0.0,
    this.balanceDemand = 0.0,
    this.isUnilateral = false,
    this.stabilityDemand = 0.0,
    this.coordinationDemand = 0.0,
    this.impactLevel = 0.0,
    required this.primaryFunction,
    this.isConditional = false,
    this.conditionalRequirement,
  });

  factory HomeExercise.fromMap(Map<String, dynamic> d) {
    return HomeExercise(
      id: d['id'] as String? ?? '',
      name: d['name'] as String? ?? '',
      nameEn: d['nameEn'] as String? ?? '',
      pattern: HomeMovementPattern.values.firstWhere(
        (e) => e.name == d['pattern'],
        orElse: () => HomeMovementPattern.squat,
      ),
      difficulty: HomeDifficulty.values.firstWhere(
        (e) => e.name == d['difficulty'],
        orElse: () => HomeDifficulty.level1,
      ),
      primaryMuscles: List<String>.from(d['primaryMuscles'] ?? []),
      secondaryMuscles: List<String>.from(d['secondaryMuscles'] ?? []),
      equipment: List<String>.from(d['equipment'] ?? []),
      equipmentMetadataVerified: d['equipmentMetadataVerified'] as bool? ?? false,
      demandRegions: (d['demandRegions'] as List?)
          ?.map((e) => HomeBodyRegion.values.firstWhere(
                (r) => r.name == e,
                orElse: () => HomeBodyRegion.knee,
              ))
          .toList() ?? [],
      cues: List<String>.from(d['cues'] ?? []),
      videoUrl: d['videoUrl'] as String?,
      regressionId: d['regressionId'] as String?,
      progressionId: d['progressionId'] as String?,
      alternativeIds: List<String>.from(d['alternativeIds'] ?? []),
      strengthDemand: (d['strengthDemand'] as num?)?.toDouble() ?? 0.5,
      mobilityDemand: (d['mobilityDemand'] as num?)?.toDouble() ?? 0.0,
      balanceDemand: (d['balanceDemand'] as num?)?.toDouble() ?? 0.0,
      stabilityDemand: (d['stabilityDemand'] as num?)?.toDouble() ?? 0.0,
      coordinationDemand: (d['coordinationDemand'] as num?)?.toDouble() ?? 0.0,
      impactLevel: (d['impactLevel'] as num?)?.toDouble() ?? 0.0,
      primaryFunction: d['primaryFunction'] as String? ?? '',
      isConditional: d['isConditional'] as bool? ?? false,
      conditionalRequirement: d['conditionalRequirement'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'nameEn': nameEn,
    'pattern': pattern.name,
    'difficulty': difficulty.name,
    'primaryMuscles': primaryMuscles,
    'secondaryMuscles': secondaryMuscles,
    'equipment': equipment,
    'equipmentMetadataVerified': equipmentMetadataVerified,
    'demandRegions': demandRegions.map((e) => e.name).toList(),
    'cues': cues,
    'videoUrl': videoUrl,
    'regressionId': regressionId,
    'progressionId': progressionId,
    'alternativeIds': alternativeIds,
    'strengthDemand': strengthDemand,
    'mobilityDemand': mobilityDemand,
    'balanceDemand': balanceDemand,
    'stabilityDemand': stabilityDemand,
    'coordinationDemand': coordinationDemand,
    'impactLevel': impactLevel,
    'primaryFunction': primaryFunction,
    'isConditional': isConditional,
    'conditionalRequirement': conditionalRequirement,
  };
}

class HomeExerciseAnalysis {
  final HomeExercise exercise;
  final HomeCompatibility compatibility;
  final String reason;
  final List<HomeAdaptation> adaptations;
  final HomeExercise? suggestedRegression;
  final HomeExercise? suggestedAlternative;

  const HomeExerciseAnalysis({
    required this.exercise,
    required this.compatibility,
    required this.reason,
    this.adaptations = const [],
    this.suggestedRegression,
    this.suggestedAlternative,
  });
}

class HomeAdaptation {
  final String description;
  final HomeAdaptationType type;

  const HomeAdaptation({
    required this.description,
    required this.type,
  });
}

enum HomeAdaptationType {
  reduceAmplitude,
  reduceDifficulty,
  increaseStability,
  changeSupport,
  changeLeverage,
  reduceSpeed,
  reduceVolume,
  reduceComplexity,
}

class HomeUserLimitation {
  final HomeBodyRegion region;
  final String description;
  final HomeLimitationSeverity severity;
  final List<String> symptoms;
  final String? diagnosis;

  const HomeUserLimitation({
    required this.region,
    required this.description,
    required this.severity,
    this.symptoms = const [],
    this.diagnosis,
  });
}

enum HomeLimitationSeverity {
  mild,      // Leve - pode adaptar
  moderate,  // Moderado - precisa de cautela
  severe,    // Grave - pode ser inadequado
}

class HomeFeedback {
  final String exerciseId;
  final HomeDifficulty difficultyUsed;
  final HomeFeedbackQuality quality;
  final List<String> symptomsDuring;
  final List<String> symptomsAfter;
  final bool neededSupport;
  final double technicalDifficulty; // 0.0-1.0
  final String? notes;

  const HomeFeedback({
    required this.exerciseId,
    required this.difficultyUsed,
    required this.quality,
    this.symptomsDuring = const [],
    this.symptomsAfter = const [],
    this.neededSupport = false,
    this.technicalDifficulty = 0.5,
    this.notes,
  });
}

enum HomeFeedbackQuality {
  executedWell,        // EXECUTOU BEM
  executedWithAdaptation, // EXECUTOU COM ADAPTAÇÃO
  executedWithDiscomfort, // EXECUTOU COM DESCONFORTO
  couldNotExecute,     // NÃO CONSEGUIU
  worsenedSymptoms,    // PIOROU OS SINTOMAS
}
