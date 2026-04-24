import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────────
// Modelos da sessão de treino
// ─────────────────────────────────────────────

class WorkoutSet {
  final int reps;
  final double weight;
  final double volume;
  final bool isWarmup;
  final bool isCompleted;

  const WorkoutSet({
    required this.reps,
    required this.weight,
    required this.volume,
    this.isWarmup = false,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() => {
        'reps': reps,
        'weight': weight,
        'volume': volume,
        'isWarmup': isWarmup,
        'isCompleted': isCompleted,
      };

  factory WorkoutSet.fromMap(Map<String, dynamic> m) => WorkoutSet(
        reps: (m['reps'] as num?)?.toInt() ?? 0,
        weight: (m['weight'] as num?)?.toDouble() ?? 0,
        volume: (m['volume'] as num?)?.toDouble() ?? 0,
        isWarmup: (m['isWarmup'] as bool?) ?? false,
        isCompleted: (m['isCompleted'] as bool?) ?? false,
      );
}

class WorkoutExerciseEntry {
  final String exerciseId;
  final String exerciseName;
  final String muscleGroup;
  List<WorkoutSet> sets;
  final String? injuryNote;

  WorkoutExerciseEntry({
    required this.exerciseId,
    required this.exerciseName,
    required this.muscleGroup,
    List<WorkoutSet>? sets,
    this.injuryNote,
  }) : sets = sets ?? [];

  double get totalVolume =>
      sets.where((s) => !s.isWarmup).fold(0, (acc, s) => acc + s.volume);

  Map<String, dynamic> toMap() => {
        'exerciseId': exerciseId,
        'exerciseName': exerciseName,
        'muscleGroup': muscleGroup,
        'sets': sets.map((s) => s.toMap()).toList(),
        'volume': totalVolume,
        'injuryNote': injuryNote,
      };

  factory WorkoutExerciseEntry.fromMap(Map<String, dynamic> m) {
    final rawSets = (m['sets'] as List<dynamic>?) ?? [];
    return WorkoutExerciseEntry(
      exerciseId: m['exerciseId'] as String? ?? '',
      exerciseName: m['exerciseName'] as String? ?? '',
      muscleGroup: m['muscleGroup'] as String? ?? '',
      injuryNote: m['injuryNote'] as String?,
      sets: rawSets
          .map((s) => WorkoutSet.fromMap(Map<String, dynamic>.from(s)))
          .toList(),
    );
  }
}

class WorkoutSession {
  final String id;
  final DateTime date;
  final int weekNumber;
  final List<WorkoutExerciseEntry> exercises;
  final String? notes;

  const WorkoutSession({
    required this.id,
    required this.date,
    required this.weekNumber,
    required this.exercises,
    this.notes,
  });

  double get totalVolume =>
      exercises.fold(0, (acc, e) => acc + e.totalVolume);

  factory WorkoutSession.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    final rawExercises = (d['exercises'] as List<dynamic>?) ?? [];
    return WorkoutSession(
      id: doc.id,
      date: (d['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      weekNumber: (d['weekNumber'] as num?)?.toInt() ?? 1,
      notes: d['notes'] as String?,
      exercises: rawExercises.map((e) {
        final em = e as Map<String, dynamic>;
        final rawSets = (em['sets'] as List<dynamic>?) ?? [];
        return WorkoutExerciseEntry(
          exerciseId: em['exerciseId'] as String? ?? '',
          exerciseName: em['exerciseName'] as String? ?? '',
          muscleGroup: em['muscleGroup'] as String? ?? '',
          sets: rawSets
              .map((s) => WorkoutSet.fromMap(s as Map<String, dynamic>))
              .toList(),
          injuryNote: em['injuryNote'] as String?,
        );
      }).toList(),
    );
  }
}
