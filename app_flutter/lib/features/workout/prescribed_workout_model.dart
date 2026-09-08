import '../exercises/exercise_model.dart';
import 'exercise_dna.dart';

// ═══════════════════════════════════════════════════════════════
// Modelos do Treino Prescrito
// ═══════════════════════════════════════════════════════════════

// Métricas de fadiga acumulada por sessão (0.0 a 1.0 normalizado)
class FatigueMetrics {
  final double spinalLoad;
  final double shoulderStress;
  final double kneeStress;
  final double cnsLoad;

  const FatigueMetrics({
    this.spinalLoad = 0.0,
    this.shoulderStress = 0.0,
    this.kneeStress = 0.0,
    this.cnsLoad = 0.0,
  });

  FatigueMetrics copyWith({
    double? spinalLoad,
    double? shoulderStress,
    double? kneeStress,
    double? cnsLoad,
  }) => FatigueMetrics(
    spinalLoad: spinalLoad ?? this.spinalLoad,
    shoulderStress: shoulderStress ?? this.shoulderStress,
    kneeStress: kneeStress ?? this.kneeStress,
    cnsLoad: cnsLoad ?? this.cnsLoad,
  );

  String status(double value) {
    if (value > 0.85) return 'crítico';
    if (value > 0.65) return 'alto';
    if (value > 0.4) return 'moderado';
    return 'ok';
  }

  Map<String, dynamic> toMap() => {
    'spinalLoad': spinalLoad,
    'shoulderStress': shoulderStress,
    'kneeStress': kneeStress,
    'cnsLoad': cnsLoad,
  };

  factory FatigueMetrics.fromMap(Map<String, dynamic> map) => FatigueMetrics(
    spinalLoad: (map['spinalLoad'] as num?)?.toDouble() ?? 0.0,
    shoulderStress: (map['shoulderStress'] as num?)?.toDouble() ?? 0.0,
    kneeStress: (map['kneeStress'] as num?)?.toDouble() ?? 0.0,
    cnsLoad: (map['cnsLoad'] as num?)?.toDouble() ?? 0.0,
  );
}

class PrescribedExercise {
  final ExerciseModel exercise;
  final int sets;
  final int repsMin;
  final int repsMax;
  final int rir; // Reps in Reserve alvo (Schoenfeld 2021)
  final int restSeconds;
  final String tempo; // Cadência: ex '2-0-2' (conc-iso-exc)
  final List<String> sessionCues;
  final String progressionNote;
  final String? injuryNote; // Alertas de segurança baseados no histórico
  final double defaultWeightKg;
  final String? decisionReason;
  final double? selectionScore;

  const PrescribedExercise({
    required this.exercise,
    required this.sets,
    required this.repsMin,
    required this.repsMax,
    required this.rir,
    required this.restSeconds,
    required this.sessionCues,
    required this.progressionNote,
    this.injuryNote,
    this.defaultWeightKg = 0.0,
    this.tempo = '2-0-2',
    this.decisionReason,
    this.selectionScore,
  });

  Map<String, dynamic> toMap() => {
    'functions': ExerciseDna.fromExercise(exercise).functions,
    'capabilities': ExerciseDna.fromExercise(exercise).capabilities,
    'joints': ExerciseDna.fromExercise(exercise).joints,
    'recoveryCost': ExerciseDna.fromExercise(exercise).recoveryCost,
    'exerciseId': exercise.id,
    'exerciseName': exercise.name,
    'muscleGroup': exercise.primaryMuscles.isNotEmpty
        ? exercise.primaryMuscles.first
        : '',
    'sets': sets,
    'repsMin': repsMin,
    'repsMax': repsMax,
    'rir': rir,
    'restSeconds': restSeconds,
    'tempo': tempo,
    'sessionCues': sessionCues,
    'progressionNote': progressionNote,
    'injuryNote': injuryNote,
    'defaultWeightKg': defaultWeightKg,
    'decisionReason': decisionReason,
    'selectionScore': selectionScore,
    // Metadados para o motor de progressão
    'isBodyweight':
        exercise.equipment.contains('bodyweight') &&
        exercise.equipment.length == 1,
    'progressionIds': exercise.progressionIds,
    'substituteIds': exercise.substituteIds,
  };

  factory PrescribedExercise.fromMap(
    Map<String, dynamic> map,
    ExerciseModel exercise,
  ) {
    return PrescribedExercise(
      exercise: exercise,
      sets: (map['sets'] as num?)?.toInt() ?? 3,
      repsMin: (map['repsMin'] as num?)?.toInt() ?? 8,
      repsMax: (map['repsMax'] as num?)?.toInt() ?? 12,
      rir: (map['rir'] as num?)?.toInt() ?? 2,
      restSeconds: (map['restSeconds'] as num?)?.toInt() ?? 90,
      tempo: map['tempo'] as String? ?? '2-0-2',
      sessionCues: (map['sessionCues'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      progressionNote: map['progressionNote'] as String? ?? '',
      injuryNote: map['injuryNote'] as String?,
      defaultWeightKg: (map['defaultWeightKg'] as num?)?.toDouble() ?? 0.0,
      decisionReason: map['decisionReason'] as String?,
      selectionScore: (map['selectionScore'] as num?)?.toDouble(),
    );
  }
}

class PrescribedSession {
  final String id;
  final String name;
  final String objective;
  final int estimatedDurationMinutes;
  final List<String> warmupInstructions;
  final List<PrescribedExercise> exercises;
  final String progressionNote;
  final FatigueMetrics fatigue;
  final String? userExplanation;
  final List<String> unresolvedExerciseIds;

  const PrescribedSession({
    required this.id,
    required this.name,
    required this.objective,
    required this.estimatedDurationMinutes,
    required this.warmupInstructions,
    required this.exercises,
    required this.progressionNote,
    this.fatigue = const FatigueMetrics(),
    this.userExplanation,
    this.unresolvedExerciseIds = const [],
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'objective': objective,
    'estimatedDurationMinutes': estimatedDurationMinutes,
    'warmupInstructions': warmupInstructions,
    'exercises': exercises.map((e) => e.toMap()).toList(),
    'progressionNote': progressionNote,
    if (fatigue != const FatigueMetrics()) 'fatigue': fatigue.toMap(),
    if (userExplanation != null) 'userExplanation': userExplanation,
    if (unresolvedExerciseIds.isNotEmpty)
      'unresolvedExerciseIds': unresolvedExerciseIds,
  };

  factory PrescribedSession.fromMap(
    Map<String, dynamic> map,
    ExerciseModel? Function(String) getExerciseById,
  ) {
    final unresolved = <String>[];
    final exList = (map['exercises'] as List? ?? [])
        .map((e) {
          final data = Map<String, dynamic>.from(e as Map);
          final exerciseId = data['exerciseId'] as String? ?? '';
          final ex = getExerciseById(exerciseId);
          if (ex == null) {
            if (exerciseId.isNotEmpty) unresolved.add(exerciseId);
            return null;
          }
          return PrescribedExercise.fromMap(data, ex);
        })
        .where((e) => e != null)
        .cast<PrescribedExercise>()
        .toList();

    return PrescribedSession(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      objective: map['objective'] as String? ?? '',
      estimatedDurationMinutes:
          (map['estimatedDurationMinutes'] as num?)?.toInt() ?? 60,
      warmupInstructions: (map['warmupInstructions'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      exercises: exList,
      progressionNote: map['progressionNote'] as String? ?? '',
      fatigue: map['fatigue'] != null
          ? FatigueMetrics.fromMap(map['fatigue'] as Map<String, dynamic>)
          : const FatigueMetrics(),
      userExplanation: map['userExplanation'] as String?,
      unresolvedExerciseIds: [
        ...unresolved,
        ...List<String>.from(map['unresolvedExerciseIds'] ?? const []),
      ],
    );
  }
}

class GeneratedWorkout {
  final String id;
  final String userId;
  final String name;
  final String splitType;
  final String periodizationModel;
  final List<PrescribedSession> sessions;
  final int mesocycleDurationWeeks;
  final String? preferredStyle;
  final DateTime generatedAt;
  final bool isActive;
  final String? planExplanation;

  const GeneratedWorkout({
    required this.id,
    required this.userId,
    this.name = 'Plano de Treino',
    required this.splitType,
    required this.periodizationModel,
    required this.sessions,
    required this.mesocycleDurationWeeks,
    this.preferredStyle,
    required this.generatedAt,
    this.isActive = false,
    this.planExplanation,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'splitType': splitType,
    'periodizationModel': periodizationModel,
    'sessions': sessions.map((s) => s.toMap()).toList(),
    'mesocycleDurationWeeks': mesocycleDurationWeeks,
    'preferredStyle': preferredStyle,
    'createdAt': generatedAt.toIso8601String(),
    'isActive': isActive,
  };

  factory GeneratedWorkout.fromMap(
    Map<String, dynamic> map,
    ExerciseModel? Function(String) getExerciseById,
  ) {
    return GeneratedWorkout(
      id: map['id'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      name: map['name'] as String? ?? 'Plano de Treino',
      splitType: map['splitType'] as String? ?? 'full_body',
      periodizationModel: map['periodizationModel'] as String? ?? 'linear',
      sessions: (map['sessions'] as List? ?? [])
          .map(
            (s) => PrescribedSession.fromMap(
              Map<String, dynamic>.from(s as Map),
              getExerciseById,
            ),
          )
          .toList(),
      mesocycleDurationWeeks:
          (map['mesocycleDurationWeeks'] as num?)?.toInt() ?? 8,
      preferredStyle: map['preferredStyle'] as String?,
      generatedAt: _readDate(map['generatedAt'] ?? map['createdAt']),
      isActive: map['isActive'] as bool? ?? false,
      planExplanation: map['planExplanation'] as String?,
    );
  }

  static DateTime _readDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}
