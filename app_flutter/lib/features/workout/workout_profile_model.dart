import 'training_readiness.dart';

// ─────────────────────────────────────────────
// ─────────────────────────────────────────────

class UserAdaptiveProfile {
  final String volumeTolerance; // high | medium | low
  final String recoveryCapacity; // high | medium | low
  
  // 📈 Tendências Bio-Adaptativas (Digital Twin)
  final double adherenceRate;      // 0.0 a 1.0 (Consistência real)
  final double volumeSensitivity;  // 1.0 (Normal) - quanto o usuário "quebra" com volume alto
  
  const UserAdaptiveProfile({
    this.volumeTolerance = 'medium',
    this.recoveryCapacity = 'medium',
    this.adherenceRate = 1.0,
    this.volumeSensitivity = 1.0,
  });

  factory UserAdaptiveProfile.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const UserAdaptiveProfile();
    return UserAdaptiveProfile(
      volumeTolerance: map['volumeTolerance'] as String? ?? 'medium',
      recoveryCapacity: map['recoveryCapacity'] as String? ?? 'medium',
      adherenceRate: (map['adherenceRate'] as num?)?.toDouble() ?? 1.0,
      volumeSensitivity: (map['volumeSensitivity'] as num?)?.toDouble() ?? 1.0,
    );
  }

  Map<String, dynamic> toMap() => {
    'volumeTolerance': volumeTolerance,
    'recoveryCapacity': recoveryCapacity,
    'adherenceRate': adherenceRate,
    'volumeSensitivity': volumeSensitivity,
  };
}

class WorkoutProfile {
  // Identificação
  final String uid;

  // Passo 1: Pessoal
  final int age;
  final String biologicalSex; // male | female
  final double weightKg;
  final double heightCm;

  // Passo 2: Experiência
  final String experienceLevel; // beginner | intermediate | advanced
  final int trainingAge; // em meses
  final String bodyFatCategory; // low | medium | high

  // Passo 3: Metas + Estilo
  final String primaryGoal; // hypertrophy | fat_loss | strength | endurance | general_health | athletic_performance | sport_specific | calisthenics | functional_hiit | mobility_rehab
  final String sportSubType; // run_5k | run_10k | run_half | run_marathon | mma | bjj | boxing | soccer | basketball | swimming | cycling | agility | none
  final String trainingModality; // traditional | calisthenics | hiit_tabata | functional | home_no_equip | home_dumbbells | home_bands | kettlebell_only | mobility | rehab | template_5x5 | template_gvt | template_531 | template_phat | template_phul | none
  final int availableDaysPerWeek; // 2-7
  final int sessionDurationMinutes; // 30 | 45 | 60 | 75 | 90
  final String preferredStyle; // compound_focus | isolation_focus | circuit | high_frequency | moderate_volume

  // Passo 4: Recuperação + Prioridades
  final String sleepQuality; // good | regular | poor
  final String stressLevel; // low | medium | high
  final List<String> priorityMuscles; // grupos a priorizar

  // Passo 5: Preferências + Restrições
  final String environment; // full_gym | basic_gym | home_dumbbell | home_bodyweight | outdoor
  final List<String> availableEquipment; // equipamentos específicos
  final List<String> dislikedExercises; // exercícios a evitar
  final List<String> favoriteExercises; // exercícios preferidos
  final List<String> healthRestrictions; // knee, lower_back, shoulder, etc.

  // Rastreamento de mesociclo
  final int currentWeek; // semana atual do mesociclo (1-N)
  final int exerciseRotationOffset; // seed de variação semanal

  final UserAdaptiveProfile adaptive; // perfil de adaptação
  final LifeLoad lifeLoad;
  final Map<String, ConfidenceLevel> confidenceByVariable;
  final bool calibrationActive;
  final int calibrationSessionsRemaining;

  final DateTime createdAt;
  final DateTime updatedAt;

  const WorkoutProfile({
    required this.uid,
    required this.age,
    required this.biologicalSex,
    required this.weightKg,
    required this.heightCm,
    required this.experienceLevel,
    required this.trainingAge,
    required this.bodyFatCategory,
    required this.primaryGoal,
    this.sportSubType = 'none',
    this.trainingModality = 'none',
    required this.availableDaysPerWeek,
    required this.sessionDurationMinutes,
    required this.preferredStyle,
    required this.sleepQuality,
    required this.stressLevel,
    required this.priorityMuscles,
    required this.environment,
    required this.availableEquipment,
    required this.dislikedExercises,
    required this.favoriteExercises,
    required this.healthRestrictions,
    this.currentWeek = 1,
    this.exerciseRotationOffset = 0,
    this.adaptive = const UserAdaptiveProfile(),
    this.lifeLoad = const LifeLoad(),
    this.confidenceByVariable = const {},
    this.calibrationActive = true,
    this.calibrationSessionsRemaining = 6,
    required this.createdAt,
    required this.updatedAt,
  });

  static DateTime _readDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  factory WorkoutProfile.fromMap(Map<String, dynamic> d) {
    final userId = d['uid'] as String? ?? '';

    String normalizeEquipment(String value) {
      switch (value.trim().toLowerCase()) {
        case 'dumbbells': return 'dumbbell';
        case 'cables': return 'cable';
        case 'machines': return 'machine';
        case 'bands': return 'band';
        case 'pullup_bar': return 'pull_up_bar';
        default: return value.trim().toLowerCase();
      }
    }

    return WorkoutProfile(
      uid: userId,
      age: (d['age'] as num?)?.toInt() ?? 25,
      biologicalSex: d['biologicalSex'] as String? ?? 'male',
      weightKg: (d['weightKg'] as num?)?.toDouble() ?? 70.0,
      heightCm: (d['heightCm'] as num?)?.toDouble() ?? 175.0,
      bodyFatCategory: d['bodyFatCategory'] as String? ?? 'medium',
      primaryGoal: d['primaryGoal'] as String? ?? 'hypertrophy',
      sportSubType: d['sportSubType'] as String? ?? 'none',
      trainingModality: d['trainingModality'] as String? ?? 'none',
      experienceLevel: d['experienceLevel'] as String? ?? 'beginner',
      trainingAge: (d['trainingAge'] as num?)?.toInt() ?? 0,
      availableDaysPerWeek: (d['availableDaysPerWeek'] as num?)?.toInt() ?? 3,
      sessionDurationMinutes: (d['sessionDurationMinutes'] as num?)?.toInt() ?? 60,
      preferredStyle: d['preferredStyle'] as String? ?? 'compound_focus',
      sleepQuality: d['sleepQuality'] as String? ?? 'regular',
      stressLevel: d['stressLevel'] as String? ?? 'medium',
      priorityMuscles: List<String>.from(d['priorityMuscles'] ?? [])
          .map(_normalizePriorityMuscle)
          .toSet()
          .toList(),
      environment: d['environment'] as String? ?? 'full_gym',
      availableEquipment: List<String>.from(d['availableEquipment'] ?? [])
          .map(normalizeEquipment)
          .toSet()
          .toList(),
      dislikedExercises: List<String>.from(d['dislikedExercises'] ?? []),
      favoriteExercises: List<String>.from(d['favoriteExercises'] ?? []),
      healthRestrictions: List<String>.from(d['healthRestrictions'] ?? []),
      currentWeek: (d['currentWeek'] as num?)?.toInt() ?? 1,
      exerciseRotationOffset: (d['exerciseRotationOffset'] as num?)?.toInt() ?? 0,
      adaptive: UserAdaptiveProfile.fromMap(d['adaptive'] as Map<String, dynamic>?),
      lifeLoad: LifeLoad.fromMap(d['lifeLoad'] as Map<String, dynamic>?),
      confidenceByVariable: _confidenceFromMap(d['confidenceByVariable']),
      calibrationActive: d['calibrationActive'] as bool? ?? true,
      calibrationSessionsRemaining:
          (d['calibrationSessionsRemaining'] as num?)?.toInt() ?? 6,
      createdAt: _readDate(d['createdAt']),
      updatedAt: _readDate(d['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'age': age,
        'biologicalSex': biologicalSex,
        'weightKg': weightKg,
        'heightCm': heightCm,
        'bodyFatCategory': bodyFatCategory,
        'primaryGoal': primaryGoal,
        'sportSubType': sportSubType,
        'trainingModality': trainingModality,
        'experienceLevel': experienceLevel,
        'trainingAge': trainingAge,
        'availableDaysPerWeek': availableDaysPerWeek,
        'sessionDurationMinutes': sessionDurationMinutes,
        'preferredStyle': preferredStyle,
        'sleepQuality': sleepQuality,
        'stressLevel': stressLevel,
        'priorityMuscles': priorityMuscles,
        'environment': environment,
        'availableEquipment': availableEquipment,
        'dislikedExercises': dislikedExercises,
        'favoriteExercises': favoriteExercises,
        'healthRestrictions': healthRestrictions,
        'currentWeek': currentWeek,
        'exerciseRotationOffset': exerciseRotationOffset,
        'adaptive': adaptive.toMap(),
        'lifeLoad': lifeLoad.toMap(),
        'confidenceByVariable': confidenceByVariable.map(
          (key, value) => MapEntry(key, value.name),
        ),
        'calibrationActive': calibrationActive,
        'calibrationSessionsRemaining': calibrationSessionsRemaining,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  static Map<String, ConfidenceLevel> _confidenceFromMap(dynamic value) {
    if (value is! Map) return {};
    final result = <String, ConfidenceLevel>{};
    for (final entry in value.entries) {
      final level = ConfidenceLevel.values.where((item) => item.name == entry.value).firstOrNull;
      if (level != null) result[entry.key.toString()] = level;
    }
    return result;
  }

  static String _normalizePriorityMuscle(String value) {
    const aliases = {
      'peito': 'chest',
      'costas': 'back',
      'ombro': 'shoulders',
      'ombros': 'shoulders',
      'biceps': 'biceps',
      'bíceps': 'biceps',
      'triceps': 'triceps',
      'tríceps': 'triceps',
      'bracos': 'biceps',
      'braços': 'biceps',
      'pernas': 'quads',
      'quadriceps': 'quads',
      'quadríceps': 'quads',
      'posterior': 'hamstrings',
      'posterior de coxa': 'hamstrings',
      'gluteos': 'glutes',
      'glúteos': 'glutes',
      'panturrilha': 'calves',
      'panturrilhas': 'calves',
      'abdomen': 'abs',
      'abdômen': 'abs',
    };
    return aliases[value.trim().toLowerCase()] ?? value.trim().toLowerCase();
  }
}
