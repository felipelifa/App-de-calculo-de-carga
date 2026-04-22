// ─────────────────────────────────────────────
// Modelo de Rotina/Template de Treino
// ─────────────────────────────────────────────

class WorkoutRoutine {
  final String id;
  final String name;
  final String? description;
  final List<RoutineExercise> exercises;
  final DateTime createdAt;

  const WorkoutRoutine({
    required this.id,
    required this.name,
    this.description,
    required this.exercises,
    required this.createdAt,
  });

  factory WorkoutRoutine.fromMap(String id, Map<String, dynamic> map) {
    return WorkoutRoutine(
      id: id,
      name: map['name'] as String? ?? 'Novo Treino',
      description: map['description'] as String?,
      exercises: (map['exercises'] as List? ?? [])
          .map((e) => RoutineExercise.fromMap(e as Map<String, dynamic>))
          .toList(),
      createdAt: (map['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'exercises': exercises.map((e) => e.toMap()).toList(),
        'createdAt': createdAt,
      };
}

class RoutineExercise {
  final String exerciseId;
  final String name;
  final String muscleGroup;
  final int sets;
  final int reps;

  const RoutineExercise({
    required this.exerciseId,
    required this.name,
    required this.muscleGroup,
    this.sets = 3,
    this.reps = 10,
  });

  factory RoutineExercise.fromMap(Map<String, dynamic> map) {
    return RoutineExercise(
      exerciseId: map['exerciseId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      muscleGroup: map['muscleGroup'] as String? ?? '',
      sets: (map['sets'] as num?)?.toInt() ?? 3,
      reps: (map['reps'] as num?)?.toInt() ?? 10,
    );
  }

  Map<String, dynamic> toMap() => {
        'exerciseId': exerciseId,
        'name': name,
        'muscleGroup': muscleGroup,
        'sets': sets,
        'reps': reps,
      };
}
