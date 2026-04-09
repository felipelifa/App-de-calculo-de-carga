import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────────
// ─────────────────────────────────────────────

class UserAdaptiveProfile {
  final String volumeTolerance; // high | medium | low
  final String recoveryCapacity; // high | medium | low
  
  const UserAdaptiveProfile({
    this.volumeTolerance = 'medium',
    this.recoveryCapacity = 'medium',
  });

  factory UserAdaptiveProfile.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const UserAdaptiveProfile();
    return UserAdaptiveProfile(
      volumeTolerance: map['volumeTolerance'] as String? ?? 'medium',
      recoveryCapacity: map['recoveryCapacity'] as String? ?? 'medium',
    );
  }

  Map<String, dynamic> toMap() => {
    'volumeTolerance': volumeTolerance,
    'recoveryCapacity': recoveryCapacity,
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
    required this.createdAt,
    required this.updatedAt,
  });

  factory WorkoutProfile.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return WorkoutProfile(
      uid: doc.id,
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
      priorityMuscles: List<String>.from(d['priorityMuscles'] ?? []),
      environment: d['environment'] as String? ?? 'full_gym',
      availableEquipment: List<String>.from(d['availableEquipment'] ?? []),
      dislikedExercises: List<String>.from(d['dislikedExercises'] ?? []),
      favoriteExercises: List<String>.from(d['favoriteExercises'] ?? []),
      healthRestrictions: List<String>.from(d['healthRestrictions'] ?? []),
      currentWeek: (d['currentWeek'] as num?)?.toInt() ?? 1,
      exerciseRotationOffset: (d['exerciseRotationOffset'] as num?)?.toInt() ?? 0,
      adaptive: UserAdaptiveProfile.fromMap(d['adaptive'] as Map<String, dynamic>?),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
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
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };
}
