// ═══════════════════════════════════════════════════════════════
// BUILDfit USER TRAINING PROFILE — Modelo Completo
// Dados estruturados para o motor de prescrição
// ═══════════════════════════════════════════════════════════════

class UserTrainingProfile {
  final PersonalData personal;
  final GoalsData goals;
  final TrainingData training;
  final EnvironmentData environment;
  final CapacityData capacity;
  final LimitationsData limitations;
  final PreferencesData preferences;
  final RecoveryData recovery;
  final SportData? sport;
  final NeedsData needs;
  final double profileConfidence;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserTrainingProfile({
    required this.personal,
    required this.goals,
    required this.training,
    required this.environment,
    required this.capacity,
    required this.limitations,
    required this.preferences,
    required this.recovery,
    this.sport,
    required this.needs,
    required this.profileConfidence,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
    'personal': personal.toMap(),
    'goals': goals.toMap(),
    'training': training.toMap(),
    'environment': environment.toMap(),
    'capacity': capacity.toMap(),
    'limitations': limitations.toMap(),
    'preferences': preferences.toMap(),
    'recovery': recovery.toMap(),
    'sport': sport?.toMap(),
    'needs': needs.toMap(),
    'profileConfidence': profileConfidence,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory UserTrainingProfile.fromMap(Map<String, dynamic> m) => UserTrainingProfile(
    personal: PersonalData.fromMap(m['personal'] ?? {}),
    goals: GoalsData.fromMap(m['goals'] ?? {}),
    training: TrainingData.fromMap(m['training'] ?? {}),
    environment: EnvironmentData.fromMap(m['environment'] ?? {}),
    capacity: CapacityData.fromMap(m['capacity'] ?? {}),
    limitations: LimitationsData.fromMap(m['limitations'] ?? {}),
    preferences: PreferencesData.fromMap(m['preferences'] ?? {}),
    recovery: RecoveryData.fromMap(m['recovery'] ?? {}),
    sport: m['sport'] != null ? SportData.fromMap(m['sport']) : null,
    needs: NeedsData.fromMap(m['needs'] ?? {}),
    profileConfidence: (m['profileConfidence'] as num?)?.toDouble() ?? 0.5,
    createdAt: DateTime.tryParse(m['createdAt'] ?? '') ?? DateTime.now(),
    updatedAt: DateTime.tryParse(m['updatedAt'] ?? '') ?? DateTime.now(),
  );

  UserTrainingProfile copyWith({
    PersonalData? personal,
    GoalsData? goals,
    TrainingData? training,
    EnvironmentData? environment,
    CapacityData? capacity,
    LimitationsData? limitations,
    PreferencesData? preferences,
    RecoveryData? recovery,
    SportData? sport,
    NeedsData? needs,
    double? profileConfidence,
  }) => UserTrainingProfile(
    personal: personal ?? this.personal,
    goals: goals ?? this.goals,
    training: training ?? this.training,
    environment: environment ?? this.environment,
    capacity: capacity ?? this.capacity,
    limitations: limitations ?? this.limitations,
    preferences: preferences ?? this.preferences,
    recovery: recovery ?? this.recovery,
    sport: sport ?? this.sport,
    needs: needs ?? this.needs,
    profileConfidence: profileConfidence ?? this.profileConfidence,
    createdAt: createdAt,
    updatedAt: DateTime.now(),
  );
}

// ─────────────────────────────────────────────────────────────
// 1. DADOS PESSOAIS
// ─────────────────────────────────────────────────────────────

class PersonalData {
  final int age;
  final String sex; // male | female
  final double heightCm;
  final double weightKg;

  const PersonalData({
    required this.age,
    required this.sex,
    required this.heightCm,
    required this.weightKg,
  });

  Map<String, dynamic> toMap() => {
    'age': age,
    'sex': sex,
    'heightCm': heightCm,
    'weightKg': weightKg,
  };

  factory PersonalData.fromMap(Map<String, dynamic> m) => PersonalData(
    age: (m['age'] as num?)?.toInt() ?? 25,
    sex: m['sex'] as String? ?? 'male',
    heightCm: (m['heightCm'] as num?)?.toDouble() ?? 170,
    weightKg: (m['weightKg'] as num?)?.toDouble() ?? 70,
  );
}

// ─────────────────────────────────────────────────────────────
// 2. OBJETIVOS
// ─────────────────────────────────────────────────────────────

class GoalsData {
  final String primary; // hypertrophy | fat_loss | strength | conditioning | endurance | power | sport | health | functional | recomposition | return | other
  final List<String> secondary;
  final String priority; // primary | secondary (qual receberá mais atenção)
  final List<String> musclePriorities; // chest | back | shoulders | arms | quads | hamstrings | glutes | calves | abs | full_body
  final String? strengthPriority; // movimento específico de força

  const GoalsData({
    required this.primary,
    this.secondary = const [],
    this.priority = 'primary',
    this.musclePriorities = const [],
    this.strengthPriority,
  });

  Map<String, dynamic> toMap() => {
    'primary': primary,
    'secondary': secondary,
    'priority': priority,
    'musclePriorities': musclePriorities,
    'strengthPriority': strengthPriority,
  };

  factory GoalsData.fromMap(Map<String, dynamic> m) => GoalsData(
    primary: m['primary'] as String? ?? 'hypertrophy',
    secondary: List<String>.from(m['secondary'] ?? []),
    priority: m['priority'] as String? ?? 'primary',
    musclePriorities: List<String>.from(m['musclePriorities'] ?? []),
    strengthPriority: m['strengthPriority'] as String?,
  );
}

// ─────────────────────────────────────────────────────────────
// 3. TREINO / ROTINA
// ─────────────────────────────────────────────────────────────

class TrainingData {
  final String experience; // never | starting | returning | regular | veteran
  final int? trainingAgeMonths; // tempo de treino em meses
  final int? monthsAway; // tempo parado (se retornando)
  final int availableDays;
  final List<String> preferredDays; // mon | tue | wed | thu | fri | sat | sun
  final String sessionDuration; // up_to_20 | 20_30 | 30_45 | 45_60 | 60_90 | over_90
  final String scheduleStability; // very_stable | mostly_stable | varies | never_know

  const TrainingData({
    required this.experience,
    this.trainingAgeMonths,
    this.monthsAway,
    required this.availableDays,
    this.preferredDays = const [],
    required this.sessionDuration,
    this.scheduleStability = 'mostly_stable',
  });

  Map<String, dynamic> toMap() => {
    'experience': experience,
    'trainingAgeMonths': trainingAgeMonths,
    'monthsAway': monthsAway,
    'availableDays': availableDays,
    'preferredDays': preferredDays,
    'sessionDuration': sessionDuration,
    'scheduleStability': scheduleStability,
  };

  factory TrainingData.fromMap(Map<String, dynamic> m) => TrainingData(
    experience: m['experience'] as String? ?? 'starting',
    trainingAgeMonths: (m['trainingAgeMonths'] as num?)?.toInt(),
    monthsAway: (m['monthsAway'] as num?)?.toInt(),
    availableDays: (m['availableDays'] as num?)?.toInt() ?? 3,
    preferredDays: List<String>.from(m['preferredDays'] ?? []),
    sessionDuration: m['sessionDuration'] as String? ?? '45_60',
    scheduleStability: m['scheduleStability'] as String? ?? 'mostly_stable',
  );
}

// ─────────────────────────────────────────────────────────────
// 4. AMBIENTE / EQUIPAMENTO
// ─────────────────────────────────────────────────────────────

class EnvironmentData {
  final String location; // gym | home | outdoor | gym_and_home | other
  final String equipmentAccess; // full | partial | none | unsure
  final List<String> availableEquipment;

  const EnvironmentData({
    required this.location,
    this.equipmentAccess = 'full',
    this.availableEquipment = const [],
  });

  Map<String, dynamic> toMap() => {
    'location': location,
    'equipmentAccess': equipmentAccess,
    'availableEquipment': availableEquipment,
  };

  factory EnvironmentData.fromMap(Map<String, dynamic> m) => EnvironmentData(
    location: m['location'] as String? ?? 'gym',
    equipmentAccess: m['equipmentAccess'] as String? ?? 'full',
    availableEquipment: List<String>.from(m['availableEquipment'] ?? []),
  );
}

// ─────────────────────────────────────────────────────────────
// 5. CAPACIDADE
// ─────────────────────────────────────────────────────────────

class CapacityData {
  final String selfReported; // very_low | low | regular | good | very_good | dont_know
  final List<String> knownExercises; // exercícios que domina
  final List<String> movementConfidence; // movimentos que faz com segurança

  const CapacityData({
    this.selfReported = 'regular',
    this.knownExercises = const [],
    this.movementConfidence = const [],
  });

  Map<String, dynamic> toMap() => {
    'selfReported': selfReported,
    'knownExercises': knownExercises,
    'movementConfidence': movementConfidence,
  };

  factory CapacityData.fromMap(Map<String, dynamic> m) => CapacityData(
    selfReported: m['selfReported'] as String? ?? 'regular',
    knownExercises: List<String>.from(m['knownExercises'] ?? []),
    movementConfidence: List<String>.from(m['movementConfidence'] ?? []),
  );
}

// ─────────────────────────────────────────────────────────────
// 6. LIMITAÇÕES
// ─────────────────────────────────────────────────────────────

class LimitationsData {
  final bool present;
  final List<LimitationDetail> details;

  const LimitationsData({
    this.present = false,
    this.details = const [],
  });

  Map<String, dynamic> toMap() => {
    'present': present,
    'details': details.map((d) => d.toMap()).toList(),
  };

  factory LimitationsData.fromMap(Map<String, dynamic> m) => LimitationsData(
    present: m['present'] as bool? ?? false,
    details: (m['details'] as List?)?.map((d) => LimitationDetail.fromMap(d)).toList() ?? [],
  );
}

class LimitationDetail {
  final String location; // shoulder | elbow | wrist | hand | cervical | thoracic | lumbar | hip | knee | ankle | foot | other
  final String type; // pain | weakness | stiffness | lack_of_mobility | instability | tingling | discomfort | loss_of_strength | other
  final String moment; // during_exercise | after_workout | both | daily | specific_movements | constant | unknown
  final int intensity; // 0-10
  final List<String> aggravatingMovements;
  final List<String> relievingMovements;
  final String? diagnosis;
  final bool? hasProfessionalGuidance;
  final List<String> restrictedMovements;

  const LimitationDetail({
    required this.location,
    required this.type,
    this.moment = 'unknown',
    this.intensity = 5,
    this.aggravatingMovements = const [],
    this.relievingMovements = const [],
    this.diagnosis,
    this.hasProfessionalGuidance,
    this.restrictedMovements = const [],
  });

  Map<String, dynamic> toMap() => {
    'location': location,
    'type': type,
    'moment': moment,
    'intensity': intensity,
    'aggravatingMovements': aggravatingMovements,
    'relievingMovements': relievingMovements,
    'diagnosis': diagnosis,
    'hasProfessionalGuidance': hasProfessionalGuidance,
    'restrictedMovements': restrictedMovements,
  };

  factory LimitationDetail.fromMap(Map<String, dynamic> m) => LimitationDetail(
    location: m['location'] as String? ?? 'other',
    type: m['type'] as String? ?? 'discomfort',
    moment: m['moment'] as String? ?? 'unknown',
    intensity: (m['intensity'] as num?)?.toInt() ?? 5,
    aggravatingMovements: List<String>.from(m['aggravatingMovements'] ?? []),
    relievingMovements: List<String>.from(m['relievingMovements'] ?? []),
    diagnosis: m['diagnosis'] as String?,
    hasProfessionalGuidance: m['hasProfessionalGuidance'] as bool?,
    restrictedMovements: List<String>.from(m['restrictedMovements'] ?? []),
  );
}

// ─────────────────────────────────────────────────────────────
// 7. PREFERÊNCIAS
// ─────────────────────────────────────────────────────────────

class PreferencesData {
  final String trainingStyle; // simple | varied | track_progress | try_new | no_preference
  final List<String> preferredExercises;
  final List<String> dislikedExercises;
  final List<String> excludedByPreference;

  const PreferencesData({
    this.trainingStyle = 'no_preference',
    this.preferredExercises = const [],
    this.dislikedExercises = const [],
    this.excludedByPreference = const [],
  });

  Map<String, dynamic> toMap() => {
    'trainingStyle': trainingStyle,
    'preferredExercises': preferredExercises,
    'dislikedExercises': dislikedExercises,
    'excludedByPreference': excludedByPreference,
  };

  factory PreferencesData.fromMap(Map<String, dynamic> m) => PreferencesData(
    trainingStyle: m['trainingStyle'] as String? ?? 'no_preference',
    preferredExercises: List<String>.from(m['preferredExercises'] ?? []),
    dislikedExercises: List<String>.from(m['dislikedExercises'] ?? []),
    excludedByPreference: List<String>.from(m['excludedByPreference'] ?? []),
  );
}

// ─────────────────────────────────────────────────────────────
// 8. RECUPERAÇÃO
// ─────────────────────────────────────────────────────────────

class RecoveryData {
  final String sleepQuality; // very_poor | poor | regular | good | very_good
  final String stressLevel; // very_low | low | moderate | high | very_high
  final List<OtherActivity> otherActivities;
  final String occupationalLoad; // none | little | moderate | heavy
  final String? occupationalDemand; // tipo de esforço

  const RecoveryData({
    this.sleepQuality = 'regular',
    this.stressLevel = 'moderate',
    this.otherActivities = const [],
    this.occupationalLoad = 'none',
    this.occupationalDemand,
  });

  Map<String, dynamic> toMap() => {
    'sleepQuality': sleepQuality,
    'stressLevel': stressLevel,
    'otherActivities': otherActivities.map((a) => a.toMap()).toList(),
    'occupationalLoad': occupationalLoad,
    'occupationalDemand': occupationalDemand,
  };

  factory RecoveryData.fromMap(Map<String, dynamic> m) => RecoveryData(
    sleepQuality: m['sleepQuality'] as String? ?? 'regular',
    stressLevel: m['stressLevel'] as String? ?? 'moderate',
    otherActivities: (m['otherActivities'] as List?)?.map((a) => OtherActivity.fromMap(a)).toList() ?? [],
    occupationalLoad: m['occupationalLoad'] as String? ?? 'none',
    occupationalDemand: m['occupationalDemand'] as String?,
  );
}

class OtherActivity {
  final String name;
  final int frequencyPerWeek;
  final int durationMinutes;

  const OtherActivity({
    required this.name,
    required this.frequencyPerWeek,
    required this.durationMinutes,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'frequencyPerWeek': frequencyPerWeek,
    'durationMinutes': durationMinutes,
  };

  factory OtherActivity.fromMap(Map<String, dynamic> m) => OtherActivity(
    name: m['name'] as String? ?? '',
    frequencyPerWeek: (m['frequencyPerWeek'] as num?)?.toInt() ?? 1,
    durationMinutes: (m['durationMinutes'] as num?)?.toInt() ?? 30,
  );
}

// ─────────────────────────────────────────────────────────────
// 9. ESPORTE (opcional)
// ─────────────────────────────────────────────────────────────

class SportData {
  final String modality;
  final int frequencyPerWeek;
  final String level; // recreational | amateur | competitive | professional
  final List<String> demands; // strength | power | speed | acceleration | endurance | direction_change | agility | mobility | stability | other

  const SportData({
    required this.modality,
    required this.frequencyPerWeek,
    this.level = 'amateur',
    this.demands = const [],
  });

  Map<String, dynamic> toMap() => {
    'modality': modality,
    'frequencyPerWeek': frequencyPerWeek,
    'level': level,
    'demands': demands,
  };

  factory SportData.fromMap(Map<String, dynamic> m) => SportData(
    modality: m['modality'] as String? ?? '',
    frequencyPerWeek: (m['frequencyPerWeek'] as num?)?.toInt() ?? 2,
    level: m['level'] as String? ?? 'amateur',
    demands: List<String>.from(m['demands'] ?? []),
  );
}

// ─────────────────────────────────────────────────────────────
// 10. NECESSIDADES ESPECÍFICAS
// ─────────────────────────────────────────────────────────────

class NeedsData {
  final List<String> specificNeeds; // posture | mobility | specific_region | recovery_capacity | sport_prep | conditioning | daily_activities | short_time | avoid_movements | other | none
  final String? additionalInformation; // texto livre

  const NeedsData({
    this.specificNeeds = const [],
    this.additionalInformation,
  });

  Map<String, dynamic> toMap() => {
    'specificNeeds': specificNeeds,
    'additionalInformation': additionalInformation,
  };

  factory NeedsData.fromMap(Map<String, dynamic> m) => NeedsData(
    specificNeeds: List<String>.from(m['specificNeeds'] ?? []),
    additionalInformation: m['additionalInformation'] as String?,
  );
}
