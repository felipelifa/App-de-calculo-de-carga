import '../enums/movement_pattern.dart';
import '../enums/body_region.dart';
import '../enums/joint.dart';
import '../enums/modality.dart';
import '../enums/environment.dart';
import '../enums/equipment.dart';
import '../enums/difficulty.dart';
import '../enums/exercise_category.dart';
import '../enums/exercise_block.dart';
import '../enums/exercise_role.dart';
import '../enums/goal.dart';
import '../enums/stimulus.dart';
import '../enums/stability_type.dart';
import '../enums/length_bias.dart';
import '../enums/intensity.dart';
import '../enums/relationship_type.dart';
import 'v2_demand_profile.dart';
import 'v2_relationship.dart';
import 'v2_limitation_rule.dart';
import 'v2_engine_rules.dart';

/// Modelo unificado V2 de exercício.
/// Substitui ExerciseModel, HomeExercise e GymExercise.
class V2Exercise {
  // ── Identidade ──
  final String id;
  final String name;
  final String nameEn;
  final List<String> aliases;
  final V2ExerciseBlock block;

  // ── Classificação ──
  final V2MovementPattern pattern;
  final String primaryFunction;
  final V2ExerciseCategory category;
  final List<V2ExerciseRole> defaultRoles;

  // ── Modalidade ──
  final List<V2Modality> modalities;

  // ── Equipamento e Ambiente ──
  final List<V2Equipment> requiredEquipment;
  final List<V2Environment> environments;
  final bool equipmentMetadataVerified;

  // ── Músculos ──
  final List<String> primaryMuscles;
  final List<String> secondaryMuscles;
  final List<String> stabilizers;

  // ── Região Corporal ──
  final List<V2BodyRegion> bodyRegions;

  // ── Articulações ──
  final List<V2Joint> joints;

  // ── Dificuldade e Técnica ──
  final V2Difficulty difficulty;
  final int skillLevel;
  final V2StabilityType stabilityType;
  final V2LengthBias lengthBias;
  final String position;
  final String? resistanceVector;
  final String? angle;
  final String? grip;
  final String laterality;

  // ── Demandas ──
  final V2DemandProfile demands;

  // ── Objetivos (com intensidade) ──
  final Map<V2Goal, V2Intensity> goalAffinity;

  // ── Estímulos (com intensidade) ──
  final Map<V2Stimulus, V2Intensity> stimuli;

  // ── Relações ──
  final List<V2Relationship> relatedExercises;

  // ── Limitações ──
  final List<V2LimitationRule> limitationRules;
  final List<String> relevantLimitations;
  final List<String> relativeContraindications;

  // ── Instruções ──
  final List<String> cues;
  final List<String> instructions;

  // ── Motor ──
  final V2EngineRules engineRules;

  // ── Mídia ──
  final String? videoUrl;
  final List<String> tags;

  const V2Exercise({
    required this.id,
    required this.name,
    this.nameEn = '',
    this.aliases = const [],
    required this.block,
    required this.pattern,
    this.primaryFunction = '',
    required this.category,
    this.defaultRoles = const [V2ExerciseRole.principal],
    this.modalities = const [],
    this.requiredEquipment = const [],
    required this.environments,
    this.equipmentMetadataVerified = true,
    this.primaryMuscles = const [],
    this.secondaryMuscles = const [],
    this.stabilizers = const [],
    this.bodyRegions = const [],
    this.joints = const [],
    required this.difficulty,
    this.skillLevel = 1,
    this.stabilityType = V2StabilityType.none,
    this.lengthBias = V2LengthBias.midRange,
    this.position = 'standing',
    this.resistanceVector,
    this.angle,
    this.grip,
    this.laterality = 'bilateral',
    required this.demands,
    this.goalAffinity = const {},
    this.stimuli = const {},
    this.relatedExercises = const [],
    this.limitationRules = const [],
    this.relevantLimitations = const [],
    this.relativeContraindications = const [],
    this.cues = const [],
    this.instructions = const [],
    required this.engineRules,
    this.videoUrl,
    this.tags = const [],
  });

  // ── Helpers de relação ──

  List<String> _getRelatedIds(V2RelationshipType type) =>
      relatedExercises
          .where((r) => r.type == type)
          .map((r) => r.targetId)
          .toList();

  List<String> get progressionIds => _getRelatedIds(V2RelationshipType.progression);
  List<String> get regressionIds => _getRelatedIds(V2RelationshipType.regression);
  List<String> get substituteIds => _getRelatedIds(V2RelationshipType.substitute);
  List<String> get alternativeIds => _getRelatedIds(V2RelationshipType.alternative);

  // ── Serialização ──

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'nameEn': nameEn,
    'aliases': aliases,
    'block': block.name,
    'pattern': pattern.name,
    'primaryFunction': primaryFunction,
    'category': category.name,
    'defaultRoles': defaultRoles.map((r) => r.name).toList(),
    'modalities': modalities.map((m) => m.name).toList(),
    'requiredEquipment': requiredEquipment.map((e) => e.name).toList(),
    'environments': environments.map((e) => e.name).toList(),
    'equipmentMetadataVerified': equipmentMetadataVerified,
    'primaryMuscles': primaryMuscles,
    'secondaryMuscles': secondaryMuscles,
    'stabilizers': stabilizers,
    'bodyRegions': bodyRegions.map((r) => r.name).toList(),
    'joints': joints.map((j) => j.name).toList(),
    'difficulty': difficulty.name,
    'skillLevel': skillLevel,
    'stabilityType': stabilityType.name,
    'lengthBias': lengthBias.name,
    'position': position,
    'resistanceVector': resistanceVector,
    'angle': angle,
    'grip': grip,
    'laterality': laterality,
    'demands': demands.toMap(),
    'goalAffinity': goalAffinity.map((k, v) => MapEntry(k.name, v.name)),
    'stimuli': stimuli.map((k, v) => MapEntry(k.name, v.name)),
    'relatedExercises': relatedExercises.map((r) => r.toMap()).toList(),
    'limitationRules': limitationRules.map((l) => l.toMap()).toList(),
    'relevantLimitations': relevantLimitations,
    'relativeContraindications': relativeContraindications,
    'cues': cues,
    'instructions': instructions,
    'engineRules': engineRules.toMap(),
    'videoUrl': videoUrl,
    'tags': tags,
  };

  factory V2Exercise.fromMap(Map<String, dynamic> m) => V2Exercise(
    id: m['id'] as String? ?? '',
    name: m['name'] as String? ?? '',
    nameEn: m['nameEn'] as String? ?? '',
    aliases: List<String>.from(m['aliases'] ?? []),
    block: _parseEnum(m['block'], V2ExerciseBlock.values, V2ExerciseBlock.home),
    pattern: _parseEnum(m['pattern'], V2MovementPattern.values, V2MovementPattern.squat),
    primaryFunction: m['primaryFunction'] as String? ?? '',
    category: _parseEnum(m['category'], V2ExerciseCategory.values, V2ExerciseCategory.compound),
    defaultRoles: _parseEnumList(m['defaultRoles'], V2ExerciseRole.values, V2ExerciseRole.principal),
    modalities: _parseEnumList(m['modalities'], V2Modality.values, V2Modality.strength),
    requiredEquipment: _parseEnumList(m['requiredEquipment'], V2Equipment.values, V2Equipment.none),
    environments: _parseEnumList(m['environments'], V2Environment.values, V2Environment.any),
    equipmentMetadataVerified: m['equipmentMetadataVerified'] as bool? ?? true,
    primaryMuscles: List<String>.from(m['primaryMuscles'] ?? []),
    secondaryMuscles: List<String>.from(m['secondaryMuscles'] ?? []),
    stabilizers: List<String>.from(m['stabilizers'] ?? []),
    bodyRegions: _parseEnumList(m['bodyRegions'], V2BodyRegion.values, V2BodyRegion.trunk),
    joints: _parseEnumList(m['joints'], V2Joint.values, V2Joint.knee),
    difficulty: _parseEnum(m['difficulty'], V2Difficulty.values, V2Difficulty.level3),
    skillLevel: (m['skillLevel'] as num?)?.toInt() ?? 1,
    stabilityType: _parseEnum(m['stabilityType'], V2StabilityType.values, V2StabilityType.none),
    lengthBias: _parseEnum(m['lengthBias'], V2LengthBias.values, V2LengthBias.midRange),
    position: m['position'] as String? ?? 'standing',
    resistanceVector: m['resistanceVector'] as String?,
    angle: m['angle'] as String?,
    grip: m['grip'] as String?,
    laterality: m['laterality'] as String? ?? 'bilateral',
    demands: V2DemandProfile.fromMap(Map<String, dynamic>.from(m['demands'] ?? {})),
    goalAffinity: _parseIntensityMap(m['goalAffinity'], V2Goal.values),
    stimuli: _parseIntensityMap(m['stimuli'], V2Stimulus.values),
    relatedExercises: _parseRelationships(m['relatedExercises']),
    limitationRules: _parseLimitationRules(m['limitationRules']),
    relevantLimitations: List<String>.from(m['relevantLimitations'] ?? []),
    relativeContraindications: List<String>.from(m['relativeContraindications'] ?? []),
    cues: List<String>.from(m['cues'] ?? []),
    instructions: List<String>.from(m['instructions'] ?? []),
    engineRules: V2EngineRules.fromMap(Map<String, dynamic>.from(m['engineRules'] ?? {})),
    videoUrl: m['videoUrl'] as String?,
    tags: List<String>.from(m['tags'] ?? []),
  );

  // ── Parsing helpers ──

  static T _parseEnum<T>(dynamic value, List<T> values, T fallback) {
    if (value == null) return fallback;
    for (final v in values) {
      if ((v as dynamic).name == value) return v;
    }
    return fallback;
  }

  static List<T> _parseEnumList<T>(dynamic value, List<T> values, T fallback) {
    if (value == null) return [fallback];
    return (value as List).map((e) {
      for (final v in values) {
        if ((v as dynamic).name == e) return v;
      }
      return fallback;
    }).toList();
  }

  static Map<T, V2Intensity> _parseIntensityMap<T>(dynamic value, List<T> keys) {
    if (value == null) return {};
    final map = Map<String, dynamic>.from(value);
    final result = <T, V2Intensity>{};
    for (final entry in map.entries) {
      final key = keys.firstWhere(
        (k) => (k as dynamic).name == entry.key,
        orElse: () => keys.first,
      );
      final intensity = V2Intensity.values.firstWhere(
        (i) => i.name == entry.value,
        orElse: () => V2Intensity.moderate,
      );
      result[key] = intensity;
    }
    return result;
  }

  static List<V2Relationship> _parseRelationships(dynamic value) {
    if (value == null) return const [];
    return (value as List).map((r) =>
      V2Relationship.fromMap(Map<String, dynamic>.from(r))
    ).toList();
  }

  static List<V2LimitationRule> _parseLimitationRules(dynamic value) {
    if (value == null) return const [];
    return (value as List).map((l) =>
      V2LimitationRule.fromMap(Map<String, dynamic>.from(l))
    ).toList();
  }
}
