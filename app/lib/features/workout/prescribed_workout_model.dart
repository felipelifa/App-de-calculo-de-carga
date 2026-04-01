import '../exercises/exercise_model.dart';
import 'workout_profile_model.dart';

// ─────────────────────────────────────────────
// Modelos de Saída do Motor de Prescrição
// ─────────────────────────────────────────────

class PrescribedExercise {
  final ExerciseModel exercise;
  final int sets;
  final int repsMin;
  final int repsMax;
  final int rir; // Reps in Reserve
  final int restSeconds;
  final List<String> sessionCues; // 3 dicas específicas
  final String progressionNote;

  const PrescribedExercise({
    required this.exercise,
    required this.sets,
    required this.repsMin,
    required this.repsMax,
    required this.rir,
    required this.restSeconds,
    required this.sessionCues,
    required this.progressionNote,
  });

  Map<String, dynamic> toMap() => {
    'exerciseId': exercise.id,
    'exerciseName': exercise.name,
    'sets': sets,
    'repsMin': repsMin,
    'repsMax': repsMax,
    'rir': rir,
    'restSeconds': restSeconds,
    'sessionCues': sessionCues,
    'progressionNote': progressionNote,
  };

  factory PrescribedExercise.fromMap(Map<String, dynamic> map, ExerciseModel exercise) {
    return PrescribedExercise(
      exercise: exercise,
      sets: (map['sets'] as num?)?.toInt() ?? 3,
      repsMin: (map['repsMin'] as num?)?.toInt() ?? 8,
      repsMax: (map['repsMax'] as num?)?.toInt() ?? 12,
      rir: (map['rir'] as num?)?.toInt() ?? 2,
      restSeconds: (map['restSeconds'] as num?)?.toInt() ?? 60,
      sessionCues: List<String>.from(map['sessionCues'] ?? []),
      progressionNote: map['progressionNote'] as String? ?? '',
    );
  }
}

class PrescribedSession {
  final String id;
  final String name; // ex: 'Treino A — Superior'
  final String objective;
  final int estimatedDurationMinutes;
  final List<String> warmupInstructions;
  final List<PrescribedExercise> exercises;
  final String progressionNote;

  const PrescribedSession({
    required this.id,
    required this.name,
    required this.objective,
    required this.estimatedDurationMinutes,
    required this.warmupInstructions,
    required this.exercises,
    required this.progressionNote,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'objective': objective,
    'estimatedDurationMinutes': estimatedDurationMinutes,
    'warmupInstructions': warmupInstructions,
    'exercises': exercises.map((e) => e.toMap()).toList(),
    'progressionNote': progressionNote,
  };

  factory PrescribedSession.fromMap(Map<String, dynamic> map, ExerciseModel? Function(String) getExerciseById) {
    final exList = (map['exercises'] as List? ?? []).map((e) {
      final data = e as Map<String, dynamic>;
      final ex = getExerciseById(data['exerciseId'] as String);
      if (ex == null) return null;
      return PrescribedExercise.fromMap(data, ex);
    }).where((e) => e != null).cast<PrescribedExercise>().toList();

    return PrescribedSession(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      objective: map['objective'] as String? ?? '',
      estimatedDurationMinutes: (map['estimatedDurationMinutes'] as num?)?.toInt() ?? 60,
      warmupInstructions: List<String>.from(map['warmupInstructions'] ?? []),
      exercises: exList,
      progressionNote: map['progressionNote'] as String? ?? '',
    );
  }
}

class GeneratedWorkout {
  final String id;
  final String userId;
  final String splitType; // full_body | upper_lower | ppl | abcde
  final String periodizationModel; // linear | dup | block
  final List<PrescribedSession> sessions;
  final int mesocycleDurationWeeks;
  final DateTime generatedAt;

  const GeneratedWorkout({
    required this.id,
    required this.userId,
    required this.splitType,
    required this.periodizationModel,
    required this.sessions,
    required this.mesocycleDurationWeeks,
    required this.generatedAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'splitType': splitType,
    'periodizationModel': periodizationModel,
    'sessions': sessions.map((s) => s.toMap()).toList(),
    'mesocycleDurationWeeks': mesocycleDurationWeeks,
    'generatedAt': generatedAt.toIso8601String(),
  };

  factory GeneratedWorkout.fromMap(Map<String, dynamic> map, ExerciseModel? Function(String) getExerciseById) {
    return GeneratedWorkout(
      id: map['id'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      splitType: map['splitType'] as String? ?? 'full_body',
      periodizationModel: map['periodizationModel'] as String? ?? 'linear',
      sessions: (map['sessions'] as List? ?? [])
          .map((s) => PrescribedSession.fromMap(s as Map<String, dynamic>, getExerciseById))
          .toList(),
      mesocycleDurationWeeks: (map['mesocycleDurationWeeks'] as num?)?.toInt() ?? 8,
      generatedAt: DateTime.tryParse(map['generatedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
