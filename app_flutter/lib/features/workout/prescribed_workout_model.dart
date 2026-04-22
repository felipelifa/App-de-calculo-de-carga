import '../exercises/exercise_model.dart';

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
  }) =>
      FatigueMetrics(
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
  final int rir;         // Reps in Reserve alvo (Schoenfeld 2021)
  final int restSeconds;
  final String tempo;    // Cadência: ex '2-0-2' (conc-iso-exc)
  final List<String> sessionCues;
  final String progressionNote;
  final String? injuryNote; // Alertas de segurança baseados no histórico

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
    this.tempo = '2-0-2',
  });

  Map<String, dynamic> toMap() => {
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
        // Metadados para o motor de progressão
        'isBodyweight': exercise.equipment.contains('bodyweight') &&
            exercise.equipment.length == 1,
        'progressionIds': exercise.progressionIds,
        'substituteIds': exercise.substituteIds,
      };

  factory PrescribedExercise.fromMap(
      Map<String, dynamic> map, ExerciseModel exercise) {
    return PrescribedExercise(
      exercise: exercise,
      sets: (map['sets'] as num?)?.toInt() ?? 3,
      repsMin: (map['repsMin'] as num?)?.toInt() ?? 8,
      repsMax: (map['repsMax'] as num?)?.toInt() ?? 12,
      rir: (map['rir'] as num?)?.toInt() ?? 2,
      restSeconds: (map['restSeconds'] as num?)?.toInt() ?? 90,
      tempo: map['tempo'] as String? ?? '2-0-2',
      sessionCues: List<String>.from(map['sessionCues'] ?? []),
      progressionNote: map['progressionNote'] as String? ?? '',
      injuryNote: map['injuryNote'] as String?,
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
  final FatigueMetrics fatigue; // métricas de fadiga desta sessão

  const PrescribedSession({
    required this.id,
    required this.name,
    required this.objective,
    required this.estimatedDurationMinutes,
    required this.warmupInstructions,
    required this.exercises,
    required this.progressionNote,
    this.fatigue = const FatigueMetrics(),
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
      };

  factory PrescribedSession.fromMap(
    Map<String, dynamic> map,
    ExerciseModel? Function(String) getExerciseById,
  ) {
    final exList = (map['exercises'] as List? ?? []).map((e) {
      final data = e as Map<String, dynamic>;
      final ex = getExerciseById(data['exerciseId'] as String? ?? '');
      if (ex == null) return null;
      return PrescribedExercise.fromMap(data, ex);
    }).where((e) => e != null).cast<PrescribedExercise>().toList();

    return PrescribedSession(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      objective: map['objective'] as String? ?? '',
      estimatedDurationMinutes:
          (map['estimatedDurationMinutes'] as num?)?.toInt() ?? 60,
      warmupInstructions:
          List<String>.from(map['warmupInstructions'] ?? []),
      exercises: exList,
      progressionNote: map['progressionNote'] as String? ?? '',
      fatigue: map['fatigue'] != null
          ? FatigueMetrics.fromMap(map['fatigue'] as Map<String, dynamic>)
          : const FatigueMetrics(),
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
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'name': name,
        'splitType': splitType,
        'periodizationModel': periodizationModel,
        'sessions': sessions.map((s) => s.toMap()).toList(),
        'mesocycleDurationWeeks': mesocycleDurationWeeks,
        'preferredStyle': preferredStyle,
        'generatedAt': generatedAt.toIso8601String(),
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
          .map((s) => PrescribedSession.fromMap(
              s as Map<String, dynamic>, getExerciseById))
          .toList(),
      mesocycleDurationWeeks:
          (map['mesocycleDurationWeeks'] as num?)?.toInt() ?? 8,
      preferredStyle: map['preferredStyle'] as String?,
      generatedAt:
          DateTime.tryParse(map['generatedAt'] as String? ?? '') ??
              DateTime.now(),
      isActive: map['isActive'] as bool? ?? false,
    );
  }
}
