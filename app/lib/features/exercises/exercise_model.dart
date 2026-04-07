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
  final String? videoUrl;
  final List<String> cues;
  final List<String> instructions;
  final List<String> substituteIds;
  final List<String> progressionIds;
  final List<String> regressionIds;
  final List<String> tags;

  // Perfil de fadiga (0.0–1.0)
  final double spinalLoad;       // 0.0 = sem carga lombar, 1.0 = terra pesado
  final double shoulderStress;   // 0.0 = zero impacto, 1.0 = desenvolvimento pesado
  final double kneeStress;       // 0.0 = nenhuma demanda, 1.0 = agachamento profundo
  final double cnsLoad;          // 0.0 = isolamento local, 1.0 = composto multiarticular pesado
  final String stabilityType;    // 'none' | 'anti_extension' | 'anti_rotation' | 'lateral' | 'scapular'
  final String lengthBias;       // 'lengthened' | 'shortened' | 'mid_range'
  final int skillLevel;          // 1–5 complexidade técnica/neural

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
    this.videoUrl,
    this.cues = const [],
    this.instructions = const [],
    this.substituteIds = const [],
    this.progressionIds = const [],
    this.regressionIds = const [],
    this.tags = const [],
    this.spinalLoad = 0.0,
    this.shoulderStress = 0.0,
    this.kneeStress = 0.0,
    this.cnsLoad = 0.0,
    this.stabilityType = 'none',
    this.lengthBias = 'mid_range',
    this.skillLevel = 1,
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
      videoUrl: d['videoUrl'] as String?,
      cues: List<String>.from(d['cues'] ?? []),
      instructions: List<String>.from(d['instructions'] ?? []),
      substituteIds: List<String>.from(d['substituteIds'] ?? []),
      progressionIds: List<String>.from(d['progressionIds'] ?? []),
      regressionIds: List<String>.from(d['regressionIds'] ?? []),
      tags: List<String>.from(d['tags'] ?? []),
      spinalLoad: (d['spinalLoad'] as num?)?.toDouble() ?? 0.0,
      shoulderStress: (d['shoulderStress'] as num?)?.toDouble() ?? 0.0,
      kneeStress: (d['kneeStress'] as num?)?.toDouble() ?? 0.0,
      cnsLoad: (d['cnsLoad'] as num?)?.toDouble() ?? 0.0,
      stabilityType: d['stabilityType'] as String? ?? 'none',
      lengthBias: d['lengthBias'] as String? ?? 'mid_range',
      skillLevel: (d['skillLevel'] as num?)?.toInt() ?? 1,
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
        'videoUrl': videoUrl,
        'cues': cues,
        'instructions': instructions,
        'substituteIds': substituteIds,
        'progressionIds': progressionIds,
        'regressionIds': regressionIds,
        'tags': tags,
        'spinalLoad': spinalLoad,
        'shoulderStress': shoulderStress,
        'kneeStress': kneeStress,
        'cnsLoad': cnsLoad,
        'stabilityType': stabilityType,
        'lengthBias': lengthBias,
        'skillLevel': skillLevel,
      };
}
