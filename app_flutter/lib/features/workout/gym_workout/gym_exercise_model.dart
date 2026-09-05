// ─────────────────────────────────────────────
// Modelo de Exercício para Academia
// ─────────────────────────────────────────────

enum GymMovementPattern {
  // Membros inferiores
  squat,              // Agachamento
  hipHinge,           // Hinge
  kneeExtension,      // Extensão de joelho
  kneeFlexion,        // Flexão de joelho
  hipExtension,       // Extensão de quadril
  hipAbduction,       // Abdução de quadril
  hipAdduction,       // Adução de quadril
  plantarFlexion,     // Flexão plantar
  dorsiflexion,       // Dorsiflexão
  
  // Membros superiores
  pushHorizontal,     // Empurrar horizontal
  pushVertical,       // Empurrar vertical
  pullHorizontal,     // Puxar horizontal
  pullVertical,       // Puxar vertical
  shoulderAbduction,  // Abdução do ombro
  shoulderAdduction,  // Adução do ombro
  elbowFlexion,       // Flexão do cotovelo
  elbowExtension,     // Extensão do cotovelo
  
  // Tronco
  trunkFlexion,       // Flexão
  trunkExtension,     // Extensão
  lateralFlexion,     // Inclinação lateral
  trunkRotation,      // Rotação
  antiRotation,       // Anti-rotação
  antiExtension,      // Anti-extensão
  antiLateralFlexion, // Anti-flexão lateral
  
  // Gerais
  locomotion,         // Locomoção
  carry,              // Carregamento
  power,              // Potência
  conditioning,       // Condicionamento
}

enum GymEquipment {
  barbell,            // Barra
  dumbbell,           // Halteres
  smith,              // Smith
  machine,            // Máquina
  cable,              // Cabo/polia
  kettlebell,         // Kettlebell
  band,               // Elástico
  plate,              // Anilha/placa
  bodyweight,         // Peso corporal
  suspension,         // Argolas/suspensão
  swissBar,           // Barra suíça
  ezBar,              // Barra EZ
  trapBar,            // Barra trap
  landmine,           // Landmine
}

enum GymBodyRegion {
  chest,
  back,
  shoulders,
  biceps,
  triceps,
  forearms,
  core,
  quadriceps,
  hamstrings,
  glutes,
  calves,
  adductors,
  abductors,
  hipFlexors,
  neck,
  traps,
  lats,
  rhomboids,
  rearDeltoids,
  anteriorDeltoids,
  lateralDeltoids,
  serratus,
  erectors,
}

enum GymStabilityLevel {
  veryLow,   // Argolas, unilateral
  low,       // Halteres, barra livre
  moderate,  // Cabo, alguns exercícios
  high,      // Smith, algumas máquinas
  veryHigh,  // Máquinas guiadas
}

enum GymComplexityLevel {
  veryLow,   // Máquinas simples
  low,       // Máquinas, Smith
  moderate,  // Halteres, cabos
  high,      // Barra livre, exercícios técnicos
  veryHigh,  // Exercícios avançados, pliométricos
}

enum GymPotentialLevel {
  none,
  low,
  moderate,
  high,
  veryHigh,
}

class GymExercise {
  // Identificação
  final String id;
  final String name;
  final List<String> aliases;
  final String category;
  final GymMovementPattern pattern;
  final String function;
  
  // Equipamento e configuração
  final GymEquipment equipment;
  final String position; // deitado, sentado, em_pé, ajoelhado
  final String resistanceVector; // horizontal, vertical, diagonal
  final String? angle; // reto, inclinado_15, inclinado_30, inclinado_45, declinado
  final String? grip; // pronada, neutra, semi_neutra, fechada, média, aberta
  final String laterality; // bilateral, unilateral, alternado
  
  // Músculos
  final List<GymBodyRegion> primaryMuscles;
  final List<GymBodyRegion> secondaryMuscles;
  final List<GymBodyRegion> joints;
  
  // Demandas
  final GymStabilityLevel stability;
  final GymComplexityLevel complexity;
  final int technicalDemand; // 1-5
  
  // Potenciais
  final GymPotentialLevel hypertrophyPotential;
  final GymPotentialLevel strengthPotential;
  final GymPotentialLevel endurancePotential;
  final GymPotentialLevel powerPotential;
  final GymPotentialLevel progressionCapacity;
  
  // Níveis recomendados
  final bool recommendedForBeginner;
  final bool recommendedForIntermediate;
  final bool recommendedForAdvanced;
  
  // Limitações e adaptações
  final List<String> relevantLimitations;
  final List<String> adaptations;
  final List<String> relativeContraindications;
  
  // Substituições
  final List<String> directSubstitutions;
  final List<String> functionalSubstitutions;
  final List<String> equivalentExercises;
  
  // Custo
  final double localFatigue; // 0.0-1.0
  final double systemicFatigue; // 0.0-1.0
  final double technicalCost; // 0.0-1.0
  final double recoveryCost; // 0.0-1.0
  
  // Motor
  final String expectedFeedback;
  final String progressionRules;
  
  // Parâmetros configuráveis (não criam exercícios novos)
  final Map<String, List<String>> configurableParameters;

  const GymExercise({
    required this.id,
    required this.name,
    this.aliases = const [],
    required this.category,
    required this.pattern,
    required this.function,
    required this.equipment,
    required this.position,
    required this.resistanceVector,
    this.angle,
    this.grip,
    required this.laterality,
    required this.primaryMuscles,
    this.secondaryMuscles = const [],
    required this.joints,
    required this.stability,
    required this.complexity,
    required this.technicalDemand,
    required this.hypertrophyPotential,
    required this.strengthPotential,
    this.endurancePotential = GymPotentialLevel.moderate,
    this.powerPotential = GymPotentialLevel.none,
    required this.progressionCapacity,
    this.recommendedForBeginner = false,
    this.recommendedForIntermediate = true,
    this.recommendedForAdvanced = true,
    this.relevantLimitations = const [],
    this.adaptations = const [],
    this.relativeContraindications = const [],
    this.directSubstitutions = const [],
    this.functionalSubstitutions = const [],
    this.equivalentExercises = const [],
    this.localFatigue = 0.5,
    this.systemicFatigue = 0.3,
    this.technicalCost = 0.5,
    this.recoveryCost = 0.3,
    this.expectedFeedback = '',
    this.progressionRules = '',
    this.configurableParameters = const {},
  });

  factory GymExercise.fromMap(Map<String, dynamic> d) {
    return GymExercise(
      id: d['id'] as String? ?? '',
      name: d['name'] as String? ?? '',
      aliases: List<String>.from(d['aliases'] ?? []),
      category: d['category'] as String? ?? '',
      pattern: GymMovementPattern.values.firstWhere(
        (e) => e.name == d['pattern'],
        orElse: () => GymMovementPattern.pushHorizontal,
      ),
      function: d['function'] as String? ?? '',
      equipment: GymEquipment.values.firstWhere(
        (e) => e.name == d['equipment'],
        orElse: () => GymEquipment.machine,
      ),
      position: d['position'] as String? ?? 'deitado',
      resistanceVector: d['resistanceVector'] as String? ?? 'horizontal',
      angle: d['angle'] as String?,
      grip: d['grip'] as String?,
      laterality: d['laterality'] as String? ?? 'bilateral',
      primaryMuscles: (d['primaryMuscles'] as List?)
          ?.map((e) => GymBodyRegion.values.firstWhere(
                (r) => r.name == e,
                orElse: () => GymBodyRegion.chest,
              ))
          .toList() ?? [],
      secondaryMuscles: (d['secondaryMuscles'] as List?)
          ?.map((e) => GymBodyRegion.values.firstWhere(
                (r) => r.name == e,
                orElse: () => GymBodyRegion.chest,
              ))
          .toList() ?? [],
      joints: (d['joints'] as List?)
          ?.map((e) => GymBodyRegion.values.firstWhere(
                (r) => r.name == e,
                orElse: () => GymBodyRegion.chest,
              ))
          .toList() ?? [],
      stability: GymStabilityLevel.values.firstWhere(
        (e) => e.name == d['stability'],
        orElse: () => GymStabilityLevel.moderate,
      ),
      complexity: GymComplexityLevel.values.firstWhere(
        (e) => e.name == d['complexity'],
        orElse: () => GymComplexityLevel.moderate,
      ),
      technicalDemand: (d['technicalDemand'] as num?)?.toInt() ?? 3,
      hypertrophyPotential: GymPotentialLevel.values.firstWhere(
        (e) => e.name == d['hypertrophyPotential'],
        orElse: () => GymPotentialLevel.moderate,
      ),
      strengthPotential: GymPotentialLevel.values.firstWhere(
        (e) => e.name == d['strengthPotential'],
        orElse: () => GymPotentialLevel.moderate,
      ),
      endurancePotential: GymPotentialLevel.values.firstWhere(
        (e) => e.name == d['endurancePotential'],
        orElse: () => GymPotentialLevel.moderate,
      ),
      powerPotential: GymPotentialLevel.values.firstWhere(
        (e) => e.name == d['powerPotential'],
        orElse: () => GymPotentialLevel.none,
      ),
      progressionCapacity: GymPotentialLevel.values.firstWhere(
        (e) => e.name == d['progressionCapacity'],
        orElse: () => GymPotentialLevel.moderate,
      ),
      recommendedForBeginner: d['recommendedForBeginner'] as bool? ?? false,
      recommendedForIntermediate: d['recommendedForIntermediate'] as bool? ?? true,
      recommendedForAdvanced: d['recommendedForAdvanced'] as bool? ?? true,
      relevantLimitations: List<String>.from(d['relevantLimitations'] ?? []),
      adaptations: List<String>.from(d['adaptations'] ?? []),
      relativeContraindications: List<String>.from(d['relativeContraindications'] ?? []),
      directSubstitutions: List<String>.from(d['directSubstitutions'] ?? []),
      functionalSubstitutions: List<String>.from(d['functionalSubstitutions'] ?? []),
      equivalentExercises: List<String>.from(d['equivalentExercises'] ?? []),
      localFatigue: (d['localFatigue'] as num?)?.toDouble() ?? 0.5,
      systemicFatigue: (d['systemicFatigue'] as num?)?.toDouble() ?? 0.3,
      technicalCost: (d['technicalCost'] as num?)?.toDouble() ?? 0.5,
      recoveryCost: (d['recoveryCost'] as num?)?.toDouble() ?? 0.3,
      expectedFeedback: d['expectedFeedback'] as String? ?? '',
      progressionRules: d['progressionRules'] as String? ?? '',
      configurableParameters: Map<String, List<String>>.from(
        (d['configurableParameters'] as Map?)?.map(
          (k, v) => MapEntry(k.toString(), List<String>.from(v ?? [])),
        ) ?? {},
      ),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'aliases': aliases,
    'category': category,
    'pattern': pattern.name,
    'function': function,
    'equipment': equipment.name,
    'position': position,
    'resistanceVector': resistanceVector,
    'angle': angle,
    'grip': grip,
    'laterality': laterality,
    'primaryMuscles': primaryMuscles.map((e) => e.name).toList(),
    'secondaryMuscles': secondaryMuscles.map((e) => e.name).toList(),
    'joints': joints.map((e) => e.name).toList(),
    'stability': stability.name,
    'complexity': complexity.name,
    'technicalDemand': technicalDemand,
    'hypertrophyPotential': hypertrophyPotential.name,
    'strengthPotential': strengthPotential.name,
    'endurancePotential': endurancePotential.name,
    'powerPotential': powerPotential.name,
    'progressionCapacity': progressionCapacity.name,
    'recommendedForBeginner': recommendedForBeginner,
    'recommendedForIntermediate': recommendedForIntermediate,
    'recommendedForAdvanced': recommendedForAdvanced,
    'relevantLimitations': relevantLimitations,
    'adaptations': adaptations,
    'relativeContraindications': relativeContraindications,
    'directSubstitutions': directSubstitutions,
    'functionalSubstitutions': functionalSubstitutions,
    'equivalentExercises': equivalentExercises,
    'localFatigue': localFatigue,
    'systemicFatigue': systemicFatigue,
    'technicalCost': technicalCost,
    'recoveryCost': recoveryCost,
    'expectedFeedback': expectedFeedback,
    'progressionRules': progressionRules,
    'configurableParameters': configurableParameters,
  };
}

class GymExerciseAnalysis {
  final GymExercise exercise;
  final GymCompatibility compatibility;
  final String reason;
  final List<GymAdaptation> adaptations;
  final GymExercise? suggestedSubstitution;

  const GymExerciseAnalysis({
    required this.exercise,
    required this.compatibility,
    required this.reason,
    this.adaptations = const [],
    this.suggestedSubstitution,
  });
}

enum GymCompatibility {
  compatible,
  adaptable,
  inadequate,
}

class GymAdaptation {
  final String description;
  final GymAdaptationType type;

  const GymAdaptation({
    required this.description,
    required this.type,
  });
}

enum GymAdaptationType {
  reduceAmplitude,
  increaseAmplitude,
  changeGrip,
  changeAngle,
  changePosition,
  reduceLoad,
  changeEquipment,
  changeUnilaterality,
  reduceSpeed,
  controlSpeed,
  reduceVolume,
  changeResistanceVector,
}

class GymUserLimitation {
  final GymBodyRegion region;
  final String description;
  final GymLimitationSeverity severity;
  final List<String> symptoms;
  final String? diagnosis;

  const GymUserLimitation({
    required this.region,
    required this.description,
    required this.severity,
    this.symptoms = const [],
    this.diagnosis,
  });
}

enum GymLimitationSeverity {
  mild,
  moderate,
  severe,
}

class GymFeedback {
  final String exerciseId;
  final GymFeedbackQuality quality;
  final List<String> symptomsDuring;
  final List<String> symptomsAfter;
  final double technicalDifficulty; // 0.0-1.0
  final double perceivedEffort; // 0.0-1.0
  final String? notes;

  const GymFeedback({
    required this.exerciseId,
    required this.quality,
    this.symptomsDuring = const [],
    this.symptomsAfter = const [],
    this.technicalDifficulty = 0.5,
    this.perceivedEffort = 0.5,
    this.notes,
  });
}

enum GymFeedbackQuality {
  executedWell,
  executedWithAdaptation,
  executedWithDiscomfort,
  couldNotExecute,
  worsenedSymptoms,
}
