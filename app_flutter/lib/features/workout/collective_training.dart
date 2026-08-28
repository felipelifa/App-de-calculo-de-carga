/// Modo de treinamento: Individual, Dupla ou Grupo.
enum TrainingMode { individual, duo, group }

/// Nível de sincronização desejado entre participantes.
enum SyncLevel { low, medium, high }

/// Relação entre os participantes (contextual, não determina o treino).
enum ParticipantRelation {
  couple,        // casal
  friends,       // amigos
  family,        // familiares
  trainingPartner, // parceiros de treino
  athletes,      // atletas
  other,         // outro
}

/// Compatibilidade entre participantes.
enum CompatibilityLevel { high, medium, low }

/// Perfil individual de um participante (pessoa A, B, C...).
/// Mantém dados pessoais, capacidades, limitações e preferências próprias.
class ParticipantProfile {
  final String name;
  final int age;
  final String biologicalSex;
  final double weightKg;
  final double heightCm;
  final String experienceLevel; // beginner | intermediate | advanced
  final int trainingAge; // meses
  final String primaryGoal;
  final String environment;
  final List<String> availableEquipment;
  final List<String> healthRestrictions;
  final int sessionDurationMinutes;
  final String sleepQuality;
  final String stressLevel;
  final String fitnessCapacity; // low | moderate | high
  final String recoveryCapacity; // low | moderate | high
  final String preferences; // notas livres

  const ParticipantProfile({
    required this.name,
    required this.age,
    required this.biologicalSex,
    required this.weightKg,
    required this.heightCm,
    required this.experienceLevel,
    required this.trainingAge,
    required this.primaryGoal,
    required this.environment,
    required this.availableEquipment,
    required this.healthRestrictions,
    required this.sessionDurationMinutes,
    this.sleepQuality = 'regular',
    this.stressLevel = 'medium',
    this.fitnessCapacity = 'moderate',
    this.recoveryCapacity = 'moderate',
    this.preferences = '',
  });

  /// Converte para o formato que o motor existente entende.
  /// Não substitui — apenas gera um WorkoutProfile compatível.
  /// Chamador deve decidir como integrar.
  Map<String, dynamic> toEngineCompatibleMap() => {
    'age': age,
    'biologicalSex': biologicalSex,
    'weightKg': weightKg,
    'heightCm': heightCm,
    'experienceLevel': experienceLevel,
    'trainingAge': trainingAge,
    'primaryGoal': primaryGoal,
    'environment': environment,
    'availableEquipment': availableEquipment,
    'healthRestrictions': healthRestrictions,
    'sessionDurationMinutes': sessionDurationMinutes,
    'sleepQuality': sleepQuality,
    'stressLevel': stressLevel,
  };

  Map<String, dynamic> toMap() => {
    'name': name,
    'age': age,
    'biologicalSex': biologicalSex,
    'weightKg': weightKg,
    'heightCm': heightCm,
    'experienceLevel': experienceLevel,
    'trainingAge': trainingAge,
    'primaryGoal': primaryGoal,
    'environment': environment,
    'availableEquipment': availableEquipment,
    'healthRestrictions': healthRestrictions,
    'sessionDurationMinutes': sessionDurationMinutes,
    'sleepQuality': sleepQuality,
    'stressLevel': stressLevel,
    'fitnessCapacity': fitnessCapacity,
    'recoveryCapacity': recoveryCapacity,
    'preferences': preferences,
  };

  factory ParticipantProfile.fromMap(Map<String, dynamic> map) =>
    ParticipantProfile(
      name: map['name'] as String? ?? '',
      age: (map['age'] as num?)?.toInt() ?? 25,
      biologicalSex: map['biologicalSex'] as String? ?? 'male',
      weightKg: (map['weightKg'] as num?)?.toDouble() ?? 70.0,
      heightCm: (map['heightCm'] as num?)?.toDouble() ?? 175.0,
      experienceLevel: map['experienceLevel'] as String? ?? 'beginner',
      trainingAge: (map['trainingAge'] as num?)?.toInt() ?? 0,
      primaryGoal: map['primaryGoal'] as String? ?? 'hypertrophy',
      environment: map['environment'] as String? ?? 'full_gym',
      availableEquipment: List<String>.from(map['availableEquipment'] ?? []),
      healthRestrictions: List<String>.from(map['healthRestrictions'] ?? []),
      sessionDurationMinutes: (map['sessionDurationMinutes'] as num?)?.toInt() ?? 60,
      sleepQuality: map['sleepQuality'] as String? ?? 'regular',
      stressLevel: map['stressLevel'] as String? ?? 'medium',
      fitnessCapacity: map['fitnessCapacity'] as String? ?? 'moderate',
      recoveryCapacity: map['recoveryCapacity'] as String? ?? 'moderate',
      preferences: map['preferences'] as String? ?? '',
    );
}

/// Perfil coletivo de uma dupla.
class DuoProfile {
  final ParticipantProfile personA;
  final ParticipantProfile personB;
  final bool wantSameWorkout; // querem fazer o mesmo treino
  final bool wantToTrainTogether; // objetivo principal é treinar juntos
  final bool haveSameGoals;
  final bool haveSimilarLevels;
  final bool haveSimilarEquipment;
  final bool haveDifferentRestrictions;
  final bool wantToFinishTogether;
  final bool acceptDifferentExercises;
  final SyncLevel syncLevel;
  final ParticipantRelation relation;

  const DuoProfile({
    required this.personA,
    required this.personB,
    required this.wantSameWorkout,
    required this.wantToTrainTogether,
    required this.haveSameGoals,
    required this.haveSimilarLevels,
    required this.haveSimilarEquipment,
    required this.haveDifferentRestrictions,
    required this.wantToFinishTogether,
    required this.acceptDifferentExercises,
    required this.syncLevel,
    required this.relation,
  });

  /// Calcula compatibilidade entre os dois participantes.
  CompatibilityLevel get compatibility {
    int score = 0;
    if (haveSameGoals) score += 3;
    if (haveSimilarLevels) score += 2;
    if (haveSimilarEquipment) score += 2;
    if (!haveDifferentRestrictions) score += 1;
    if (acceptDifferentExercises) score += 1;
    if (wantToFinishTogether) score += 1;

    if (score >= 7) return CompatibilityLevel.high;
    if (score >= 4) return CompatibilityLevel.medium;
    return CompatibilityLevel.low;
  }

  Map<String, dynamic> toMap() => {
    'personA': personA.toMap(),
    'personB': personB.toMap(),
    'wantSameWorkout': wantSameWorkout,
    'wantToTrainTogether': wantToTrainTogether,
    'haveSameGoals': haveSameGoals,
    'haveSimilarLevels': haveSimilarLevels,
    'haveSimilarEquipment': haveSimilarEquipment,
    'haveDifferentRestrictions': haveDifferentRestrictions,
    'wantToFinishTogether': wantToFinishTogether,
    'acceptDifferentExercises': acceptDifferentExercises,
    'syncLevel': syncLevel.name,
    'relation': relation.name,
  };

  factory DuoProfile.fromMap(Map<String, dynamic> map) => DuoProfile(
    personA: ParticipantProfile.fromMap(map['personA'] as Map<String, dynamic>),
    personB: ParticipantProfile.fromMap(map['personB'] as Map<String, dynamic>),
    wantSameWorkout: map['wantSameWorkout'] as bool? ?? false,
    wantToTrainTogether: map['wantToTrainTogether'] as bool? ?? true,
    haveSameGoals: map['haveSameGoals'] as bool? ?? false,
    haveSimilarLevels: map['haveSimilarLevels'] as bool? ?? false,
    haveSimilarEquipment: map['haveSimilarEquipment'] as bool? ?? false,
    haveDifferentRestrictions: map['haveDifferentRestrictions'] as bool? ?? false,
    wantToFinishTogether: map['wantToFinishTogether'] as bool? ?? true,
    acceptDifferentExercises: map['acceptDifferentExercises'] as bool? ?? false,
    syncLevel: SyncLevel.values.firstWhere(
      (e) => e.name == map['syncLevel'],
      orElse: () => SyncLevel.medium,
    ),
    relation: ParticipantRelation.values.firstWhere(
      (e) => e.name == map['relation'],
      orElse: () => ParticipantRelation.other,
    ),
  );
}

/// Perfil coletivo de um grupo.
class GroupProfile {
  final String name;
  final List<ParticipantProfile> participants;
  final String collectiveGoal;
  final int targetDurationMinutes;
  final int targetFrequencyPerWeek;
  final String environment;
  final List<String> availableEquipment;
  final bool wantToFinishTogether;
  final bool allowDifferentExercises;
  final SyncLevel syncLevel;
  final String collectiveLevel; // overall group level
  final String levelDifference; // small | moderate | large

  const GroupProfile({
    required this.name,
    required this.participants,
    required this.collectiveGoal,
    required this.targetDurationMinutes,
    required this.targetFrequencyPerWeek,
    required this.environment,
    required this.availableEquipment,
    required this.wantToFinishTogether,
    required this.allowDifferentExercises,
    required this.syncLevel,
    required this.collectiveLevel,
    required this.levelDifference,
  });

  /// Calcula compatibilidade geral do grupo.
  CompatibilityLevel get compatibility {
    if (participants.length < 2) return CompatibilityLevel.high;

    int matchCount = 0;
    int totalPairs = 0;

    for (int i = 0; i < participants.length; i++) {
      for (int j = i + 1; j < participants.length; j++) {
        totalPairs++;
        if (participants[i].primaryGoal == participants[j].primaryGoal) matchCount++;
        if (participants[i].experienceLevel == participants[j].experienceLevel) matchCount++;
      }
    }

    if (totalPairs == 0) return CompatibilityLevel.high;
    final ratio = matchCount / (totalPairs * 2);
    if (ratio >= 0.7) return CompatibilityLevel.high;
    if (ratio >= 0.4) return CompatibilityLevel.medium;
    return CompatibilityLevel.low;
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'participants': participants.map((p) => p.toMap()).toList(),
    'collectiveGoal': collectiveGoal,
    'targetDurationMinutes': targetDurationMinutes,
    'targetFrequencyPerWeek': targetFrequencyPerWeek,
    'environment': environment,
    'availableEquipment': availableEquipment,
    'wantToFinishTogether': wantToFinishTogether,
    'allowDifferentExercises': allowDifferentExercises,
    'syncLevel': syncLevel.name,
    'collectiveLevel': collectiveLevel,
    'levelDifference': levelDifference,
  };

  factory GroupProfile.fromMap(Map<String, dynamic> map) => GroupProfile(
    name: map['name'] as String? ?? '',
    participants: (map['participants'] as List? ?? [])
        .map((p) => ParticipantProfile.fromMap(p as Map<String, dynamic>))
        .toList(),
    collectiveGoal: map['collectiveGoal'] as String? ?? 'hypertrophy',
    targetDurationMinutes: (map['targetDurationMinutes'] as num?)?.toInt() ?? 60,
    targetFrequencyPerWeek: (map['targetFrequencyPerWeek'] as num?)?.toInt() ?? 3,
    environment: map['environment'] as String? ?? 'full_gym',
    availableEquipment: List<String>.from(map['availableEquipment'] ?? []),
    wantToFinishTogether: map['wantToFinishTogether'] as bool? ?? true,
    allowDifferentExercises: map['allowDifferentExercises'] as bool? ?? false,
    syncLevel: SyncLevel.values.firstWhere(
      (e) => e.name == map['syncLevel'],
      orElse: () => SyncLevel.medium,
    ),
    collectiveLevel: map['collectiveLevel'] as String? ?? 'beginner',
    levelDifference: map['levelDifference'] as String? ?? 'small',
  );
}

/// Sessão coletiva: contém núcleo comum + variações individuais.
class CollectiveSessionBlock {
  final String blockName; // "aquecimento", "bloco_1", "bloco_2", "finalizacao"
  final bool isCommon; // se True, todos fazem o mesmo exercício
  final String commonExerciseId; // ID do exercício comum (se isCommon)
  final String commonExerciseName;
  final Map<String, String> individualVariations; // participantName → exerciseId
  final Map<String, int> individualSets; // participantName → séries
  final Map<String, int> individualReps; // participantName → reps

  const CollectiveSessionBlock({
    required this.blockName,
    required this.isCommon,
    this.commonExerciseId = '',
    this.commonExerciseName = '',
    this.individualVariations = const {},
    this.individualSets = const {},
    this.individualReps = const {},
  });

  Map<String, dynamic> toMap() => {
    'blockName': blockName,
    'isCommon': isCommon,
    'commonExerciseId': commonExerciseId,
    'commonExerciseName': commonExerciseName,
    'individualVariations': individualVariations,
    'individualSets': individualSets,
    'individualReps': individualReps,
  };

  factory CollectiveSessionBlock.fromMap(Map<String, dynamic> map) =>
    CollectiveSessionBlock(
      blockName: map['blockName'] as String? ?? '',
      isCommon: map['isCommon'] as bool? ?? true,
      commonExerciseId: map['commonExerciseId'] as String? ?? '',
      commonExerciseName: map['commonExerciseName'] as String? ?? '',
      individualVariations: Map<String, String>.from(map['individualVariations'] ?? {}),
      individualSets: Map<String, int>.from(map['individualSets'] ?? {}),
      individualReps: Map<String, int>.from(map['individualReps'] ?? {}),
    );
}
