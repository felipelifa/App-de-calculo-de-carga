import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────────
// Modelo de Perfil de Treino (Anamnese)
// ─────────────────────────────────────────────

class WorkoutProfile {
  final String uid;
  final int age;
  final String biologicalSex; // male | female
  final double weightKg;
  final double heightCm;
  final String bodyFatCategory; // low | medium | high
  final String primaryGoal; // hypertrophy | fat_loss | strength | endurance | general_health | athletic_performance
  final String experienceLevel; // beginner | intermediate | advanced
  final int trainingAge; // em meses
  final int availableDaysPerWeek; // 1-7
  final int sessionDurationMinutes; // 30 | 45 | 60 | 75 | 90
  final String environment; // full_gym | basic_gym | home_dumbbell | home_bodyweight | outdoor
  final List<String> availableEquipment;
  final List<String> healthRestrictions; // knee, lower_back, shoulder, wrist, elbow, hypertension, hernia
  final List<String> dislikedExercises;
  final String preferredStyle; // compound_focus | isolation_focus | circuit | high_frequency | moderate_volume
  final DateTime createdAt;
  final DateTime updatedAt;

  const WorkoutProfile({
    required this.uid,
    required this.age,
    required this.biologicalSex,
    required this.weightKg,
    required this.heightCm,
    required this.bodyFatCategory,
    required this.primaryGoal,
    required this.experienceLevel,
    required this.trainingAge,
    required this.availableDaysPerWeek,
    required this.sessionDurationMinutes,
    required this.environment,
    required this.availableEquipment,
    required this.healthRestrictions,
    required this.dislikedExercises,
    required this.preferredStyle,
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
      experienceLevel: d['experienceLevel'] as String? ?? 'beginner',
      trainingAge: (d['trainingAge'] as num?)?.toInt() ?? 0,
      availableDaysPerWeek: (d['availableDaysPerWeek'] as num?)?.toInt() ?? 3,
      sessionDurationMinutes: (d['sessionDurationMinutes'] as num?)?.toInt() ?? 60,
      environment: d['environment'] as String? ?? 'full_gym',
      availableEquipment: List<String>.from(d['availableEquipment'] ?? []),
      healthRestrictions: List<String>.from(d['healthRestrictions'] ?? []),
      dislikedExercises: List<String>.from(d['dislikedExercises'] ?? []),
      preferredStyle: d['preferredStyle'] as String? ?? 'compound_focus',
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
        'experienceLevel': experienceLevel,
        'trainingAge': trainingAge,
        'availableDaysPerWeek': availableDaysPerWeek,
        'sessionDurationMinutes': sessionDurationMinutes,
        'environment': environment,
        'availableEquipment': availableEquipment,
        'healthRestrictions': healthRestrictions,
        'dislikedExercises': dislikedExercises,
        'preferredStyle': preferredStyle,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };
}
