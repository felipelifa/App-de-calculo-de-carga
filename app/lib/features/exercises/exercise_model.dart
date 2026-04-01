import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────────
// Modelo de Exercício (Nível Profissional)
// ─────────────────────────────────────────────

class ExerciseModel {
  final String id;
  final String name;
  final String nameEn;
  final List<String> primaryMuscles;
  final List<String> secondaryMuscles;
  final String movementPattern;
  final List<String> equipment;
  final List<String> environment;
  final String category; // compound | isolation
  final String difficulty; // beginner | intermediate | advanced
  final List<String> restrictions;
  final int repRangeMin;
  final int repRangeMax;
  final bool isUnilateral;
  final String? gifUrl;
  final List<String> cues;
  final List<String> substituteIds;
  final List<String> progressionIds;
  final List<String> regressionIds;
  final List<String> tags;

  const ExerciseModel({
    required this.id,
    required this.name,
    this.nameEn = '',
    required this.primaryMuscles,
    this.secondaryMuscles = const [],
    this.movementPattern = 'isolation',
    this.equipment = const [],
    this.environment = const ['gym'],
    this.category = 'isolation',
    this.difficulty = 'beginner',
    this.restrictions = const [],
    this.repRangeMin = 8,
    this.repRangeMax = 12,
    this.isUnilateral = false,
    this.gifUrl,
    this.cues = const [],
    this.substituteIds = const [],
    this.progressionIds = const [],
    this.regressionIds = const [],
    this.tags = const [],
  });

  factory ExerciseModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ExerciseModel(
      id: doc.id,
      name: d['name'] as String? ?? '',
      nameEn: d['nameEn'] as String? ?? '',
      primaryMuscles: List<String>.from(d['primaryMuscles'] ?? []),
      secondaryMuscles: List<String>.from(d['secondaryMuscles'] ?? []),
      movementPattern: d['movementPattern'] as String? ?? 'isolation',
      equipment: List<String>.from(d['equipment'] ?? []),
      environment: List<String>.from(d['environment'] ?? []),
      category: d['category'] as String? ?? 'isolation',
      difficulty: d['difficulty'] as String? ?? 'beginner',
      restrictions: List<String>.from(d['restrictions'] ?? []),
      repRangeMin: (d['repRangeMin'] as num?)?.toInt() ?? 8,
      repRangeMax: (d['repRangeMax'] as num?)?.toInt() ?? 12,
      isUnilateral: d['isUnilateral'] as bool? ?? false,
      gifUrl: d['gifUrl'] as String?,
      cues: List<String>.from(d['cues'] ?? []),
      substituteIds: List<String>.from(d['substituteIds'] ?? []),
      progressionIds: List<String>.from(d['progressionIds'] ?? []),
      regressionIds: List<String>.from(d['regressionIds'] ?? []),
      tags: List<String>.from(d['tags'] ?? []),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'nameEn': nameEn,
        'primaryMuscles': primaryMuscles,
        'secondaryMuscles': secondaryMuscles,
        'movementPattern': movementPattern,
        'equipment': equipment,
        'environment': environment,
        'category': category,
        'difficulty': difficulty,
        'restrictions': restrictions,
        'repRangeMin': repRangeMin,
        'repRangeMax': repRangeMax,
        'isUnilateral': isUnilateral,
        'gifUrl': gifUrl,
        'cues': cues,
        'substituteIds': substituteIds,
        'progressionIds': progressionIds,
        'regressionIds': regressionIds,
        'tags': tags,
      };
}
