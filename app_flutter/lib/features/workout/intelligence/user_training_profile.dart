import '../../exercise_library_v2/enums/goal.dart';
import '../../exercise_library_v2/enums/modality.dart';
import '../../exercise_library_v2/enums/environment.dart';
import '../../exercise_library_v2/enums/equipment.dart';
import '../../exercise_library_v2/enums/joint.dart';
import '../../exercise_library_v2/enums/limitation_severity.dart';
import '../../exercise_library_v2/enums/capacity.dart';
import '../../exercise_library_v2/enums/intensity.dart';
import '../../exercise_library_v2/enums/difficulty.dart';

/// Perfil completo do usuário resultante da anamnese.
/// Contém todos os dados estruturados necessários para o motor decidir.
class UserTrainingProfile {
  final String uid;

  // ── Identidade Física ──
  final int age;
  final String biologicalSex;
  final double weightKg;
  final double heightCm;

  // ── Objetivo ──
  final V2Goal primaryGoal;
  final List<V2Goal> secondaryGoals;

  // ── Modalidade ──
  final V2Modality modality;

  // ── Local ──
  final V2Environment environment;

  // ── Equipamentos ──
  final List<V2Equipment> availableEquipment;

  // ── Frequência ──
  final int availableDaysPerWeek;

  // ── Duração ──
  final int sessionDurationMinutes;

  // ── Experiência ──
  final ExperienceLevel experienceLevel;
  final int trainingAgeMonths;

  // ── Capacidades ──
  final UserCapacityProfile capacities;

  // ── Limitações ──
  final List<UserLimitation> limitations;

  // ── Preferências ──
  final List<String> preferredExerciseIds;
  final List<String> dislikedExerciseIds;

  // ── Prioridades ──
  final List<TrainingPriority> priorities;

  // ── Segurança ──
  final List<SafetyAlert> safetyAlerts;

  const UserTrainingProfile({
    required this.uid,
    required this.age,
    this.biologicalSex = 'unknown',
    this.weightKg = 70,
    this.heightCm = 170,
    required this.primaryGoal,
    this.secondaryGoals = const [],
    required this.modality,
    required this.environment,
    this.availableEquipment = const [],
    required this.availableDaysPerWeek,
    required this.sessionDurationMinutes,
    required this.experienceLevel,
    this.trainingAgeMonths = 0,
    this.capacities = const UserCapacityProfile(),
    this.limitations = const [],
    this.preferredExerciseIds = const [],
    this.dislikedExerciseIds = const [],
    this.priorities = const [],
    this.safetyAlerts = const [],
  });

  bool get hasLimitations => limitations.isNotEmpty;
  bool get hasSafetyAlerts => safetyAlerts.isNotEmpty;
  bool get hasEquipment => availableEquipment.isNotEmpty &&
      !availableEquipment.contains(V2Equipment.none);

  V2Difficulty get derivedDifficulty {
    switch (experienceLevel) {
      case ExperienceLevel.never:
      case ExperienceLevel.little:
        return V2Difficulty.level1;
      case ExperienceLevel.regularly:
        return V2Difficulty.level2;
      case ExperienceLevel.years:
        return V2Difficulty.level3;
      case ExperienceLevel.returning:
        return V2Difficulty.level2;
    }
  }

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'age': age,
    'biologicalSex': biologicalSex,
    'weightKg': weightKg,
    'heightCm': heightCm,
    'primaryGoal': primaryGoal.name,
    'secondaryGoals': secondaryGoals.map((g) => g.name).toList(),
    'modality': modality.name,
    'environment': environment.name,
    'availableEquipment': availableEquipment.map((e) => e.name).toList(),
    'availableDaysPerWeek': availableDaysPerWeek,
    'sessionDurationMinutes': sessionDurationMinutes,
    'experienceLevel': experienceLevel.name,
    'trainingAgeMonths': trainingAgeMonths,
    'capacities': capacities.toMap(),
    'limitations': limitations.map((l) => l.toMap()).toList(),
    'preferredExerciseIds': preferredExerciseIds,
    'dislikedExerciseIds': dislikedExerciseIds,
    'priorities': priorities.map((p) => p.toMap()).toList(),
    'safetyAlerts': safetyAlerts.map((a) => a.toMap()).toList(),
  };

  factory UserTrainingProfile.fromMap(Map<String, dynamic> m) =>
      UserTrainingProfile(
        uid: m['uid'] as String? ?? '',
        age: (m['age'] as num?)?.toInt() ?? 25,
        biologicalSex: m['biologicalSex'] as String? ?? 'unknown',
        weightKg: (m['weightKg'] as num?)?.toDouble() ?? 70,
        heightCm: (m['heightCm'] as num?)?.toDouble() ?? 170,
        primaryGoal: _parseGoal(m['primaryGoal']),
        secondaryGoals: (m['secondaryGoals'] as List?)
                ?.map((g) => _parseGoal(g))
                .toList() ??
            const [],
        modality: _parseModality(m['modality']),
        environment: _parseEnvironment(m['environment']),
        availableEquipment: (m['availableEquipment'] as List?)
                ?.map((e) => _parseEquipment(e))
                .toList() ??
            const [],
        availableDaysPerWeek: (m['availableDaysPerWeek'] as num?)?.toInt() ?? 3,
        sessionDurationMinutes:
            (m['sessionDurationMinutes'] as num?)?.toInt() ?? 30,
        experienceLevel: _parseExperienceLevel(m['experienceLevel']),
        trainingAgeMonths: (m['trainingAgeMonths'] as num?)?.toInt() ?? 0,
        capacities: UserCapacityProfile.fromMap(
            m['capacities'] as Map<String, dynamic>? ?? {}),
        limitations: (m['limitations'] as List?)
                ?.map((l) => UserLimitation.fromMap(l as Map<String, dynamic>))
                .toList() ??
            const [],
        preferredExerciseIds:
            List<String>.from(m['preferredExerciseIds'] ?? const []),
        dislikedExerciseIds:
            List<String>.from(m['dislikedExerciseIds'] ?? const []),
        priorities: (m['priorities'] as List?)
                ?.map((p) => TrainingPriority.fromMap(p as Map<String, dynamic>))
                .toList() ??
            const [],
        safetyAlerts: (m['safetyAlerts'] as List?)
                ?.map((a) => SafetyAlert.fromMap(a as Map<String, dynamic>))
                .toList() ??
            const [],
      );

  // ── Parsing helpers ──

  static V2Goal _parseGoal(dynamic v) {
    if (v == null) return V2Goal.generalFitness;
    return V2Goal.values.firstWhere(
      (g) => g.name == v,
      orElse: () => V2Goal.generalFitness,
    );
  }

  static V2Modality _parseModality(dynamic v) {
    if (v == null) return V2Modality.generalPhysicalDevelopment;
    return V2Modality.values.firstWhere(
      (m) => m.name == v,
      orElse: () => V2Modality.generalPhysicalDevelopment,
    );
  }

  static V2Environment _parseEnvironment(dynamic v) {
    if (v == null) return V2Environment.home;
    return V2Environment.values.firstWhere(
      (e) => e.name == v,
      orElse: () => V2Environment.home,
    );
  }

  static V2Equipment _parseEquipment(dynamic v) {
    if (v == null) return V2Equipment.none;
    return V2Equipment.values.firstWhere(
      (e) => e.name == v,
      orElse: () => V2Equipment.none,
    );
  }

  static ExperienceLevel _parseExperienceLevel(dynamic v) {
    if (v == null) return ExperienceLevel.regularly;
    return ExperienceLevel.values.firstWhere(
      (e) => e.name == v,
      orElse: () => ExperienceLevel.regularly,
    );
  }
}

/// Níveis de experiência estruturados.
enum ExperienceLevel {
  never,      // nunca treinou
  little,     // pouco
  regularly,  // regularmente
  years,      // há vários anos
  returning,  // retorno após parada
}

/// Perfil de capacidades do usuário.
class UserCapacityProfile {
  final Map<V2Capacity, V2Intensity> values;

  const UserCapacityProfile({this.values = const {}});

  V2Intensity get strength => values[V2Capacity.strength] ?? V2Intensity.moderate;
  V2Intensity get stability => values[V2Capacity.stability] ?? V2Intensity.moderate;
  V2Intensity get mobility => values[V2Capacity.mobility] ?? V2Intensity.moderate;
  V2Intensity get balance => values[V2Capacity.balance] ?? V2Intensity.moderate;
  V2Intensity get coordination => values[V2Capacity.coordination] ?? V2Intensity.low;
  V2Intensity get cardiovascular => values[V2Capacity.cardiovascular] ?? V2Intensity.moderate;
  V2Intensity get endurance => values[V2Capacity.endurance] ?? V2Intensity.moderate;
  V2Intensity get power => values[V2Capacity.power] ?? V2Intensity.low;

  Map<String, dynamic> toMap() => {
    for (final entry in values.entries) entry.key.name: entry.value.name,
  };

  factory UserCapacityProfile.fromMap(Map<String, dynamic> m) {
    final values = <V2Capacity, V2Intensity>{};
    for (final cap in V2Capacity.values) {
      if (m.containsKey(cap.name)) {
        values[cap] = V2Intensity.values.firstWhere(
          (i) => i.name == m[cap.name],
          orElse: () => V2Intensity.moderate,
        );
      }
    }
    return UserCapacityProfile(values: values);
  }
}

/// Limitação do usuário.
class UserLimitation {
  final V2Joint joint;
  final V2LimitationSeverity severity;
  final String side; // left, right, both, na
  final String timing; // during, after, both
  final List<String> affectedMovements;
  final String? description;

  const UserLimitation({
    required this.joint,
    required this.severity,
    this.side = 'both',
    this.timing = 'during',
    this.affectedMovements = const [],
    this.description,
  });

  Map<String, dynamic> toMap() => {
    'joint': joint.name,
    'severity': severity.name,
    'side': side,
    'timing': timing,
    'affectedMovements': affectedMovements,
    'description': description,
  };

  factory UserLimitation.fromMap(Map<String, dynamic> m) => UserLimitation(
        joint: V2Joint.values.firstWhere(
          (j) => j.name == m['joint'],
          orElse: () => V2Joint.knee,
        ),
        severity: V2LimitationSeverity.values.firstWhere(
          (s) => s.name == m['severity'],
          orElse: () => V2LimitationSeverity.mild,
        ),
        side: m['side'] as String? ?? 'both',
        timing: m['timing'] as String? ?? 'during',
        affectedMovements:
            List<String>.from(m['affectedMovements'] ?? const []),
        description: m['description'] as String?,
      );
}

/// Prioridade de treinamento do usuário.
class TrainingPriority {
  final String area; // legs, glutes, back, chest, shoulders, arms, core, mobility, balance, conditioning
  final int level; // 1-5

  const TrainingPriority({required this.area, this.level = 3});

  Map<String, dynamic> toMap() => {'area': area, 'level': level};

  factory TrainingPriority.fromMap(Map<String, dynamic> m) => TrainingPriority(
        area: m['area'] as String? ?? 'general',
        level: (m['level'] as num?)?.toInt() ?? 3,
      );
}

/// Alerta de segurança.
class SafetyAlert {
  final String type; // chest_pain, breathing_difficulty, syncope, weakness, trauma, progressive_symptoms
  final String description;

  const SafetyAlert({required this.type, required this.description});

  Map<String, dynamic> toMap() => {
    'type': type,
    'description': description,
  };

  factory SafetyAlert.fromMap(Map<String, dynamic> m) => SafetyAlert(
        type: m['type'] as String? ?? 'unknown',
        description: m['description'] as String? ?? '',
      );
}
