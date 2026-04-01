import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────────
// Modelo de Personal Record (PR)
// ─────────────────────────────────────────────

class PersonalRecord {
  final String exerciseId;
  final String exerciseName;
  final String muscleGroup;

  /// Maior carga carregada em uma única série (kg)
  final double maxWeight;

  /// Maior número de reps em uma única série
  final int maxReps;

  /// Maior volume em uma única série (reps × peso)
  final double maxVolume;

  final DateTime updatedAt;

  const PersonalRecord({
    required this.exerciseId,
    required this.exerciseName,
    required this.muscleGroup,
    required this.maxWeight,
    required this.maxReps,
    required this.maxVolume,
    required this.updatedAt,
  });

  factory PersonalRecord.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return PersonalRecord(
      exerciseId: doc.id,
      exerciseName: d['exerciseName'] as String? ?? '',
      muscleGroup: d['muscleGroup'] as String? ?? '',
      maxWeight: (d['maxWeight'] as num?)?.toDouble() ?? 0,
      maxReps: (d['maxReps'] as num?)?.toInt() ?? 0,
      maxVolume: (d['maxVolume'] as num?)?.toDouble() ?? 0,
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'exerciseName': exerciseName,
        'muscleGroup': muscleGroup,
        'maxWeight': maxWeight,
        'maxReps': maxReps,
        'maxVolume': maxVolume,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  /// Cria uma versão atualizada se os novos valores forem PRs
  PersonalRecord? mergeWith({
    required double newWeight,
    required int newReps,
    required double newVolume,
    required String exerciseName,
    required String muscleGroup,
  }) {
    final newMaxWeight = newWeight > maxWeight ? newWeight : maxWeight;
    final newMaxReps = newReps > maxReps ? newReps : maxReps;
    final newMaxVolume = newVolume > maxVolume ? newVolume : maxVolume;

    if (newMaxWeight == maxWeight &&
        newMaxReps == maxReps &&
        newMaxVolume == maxVolume) {
      return null; // nenhum PR novo
    }

    return PersonalRecord(
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      muscleGroup: muscleGroup,
      maxWeight: newMaxWeight,
      maxReps: newMaxReps,
      maxVolume: newMaxVolume,
      updatedAt: DateTime.now(),
    );
  }
}

// ─── Diferença entre PR antigo e novo (para mostrar na celebração) ──

class PrAchievement {
  final String exerciseId;
  final String exerciseName;
  final String muscleGroup;

  final double? newMaxWeight;
  final double? prevMaxWeight;

  final int? newMaxReps;
  final int? prevMaxReps;

  final double? newMaxVolume;
  final double? prevMaxVolume;

  const PrAchievement({
    required this.exerciseId,
    required this.exerciseName,
    required this.muscleGroup,
    this.newMaxWeight,
    this.prevMaxWeight,
    this.newMaxReps,
    this.prevMaxReps,
    this.newMaxVolume,
    this.prevMaxVolume,
  });

  bool get hasWeightPr => newMaxWeight != null;
  bool get hasRepsPr => newMaxReps != null;
  bool get hasVolumePr => newMaxVolume != null;
}
