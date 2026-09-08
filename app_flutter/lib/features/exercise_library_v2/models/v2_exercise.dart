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
    block: _parseBlock(m['block']),
    pattern: _parsePattern(m['pattern']),
    primaryFunction: m['primaryFunction'] as String? ?? '',
    category: _parseCategory(m['category']),
    defaultRoles: _parseRoles(m['defaultRoles']),
    modalities: _parseModalities(m['modalities']),
    requiredEquipment: _parseEquipment(m['requiredEquipment']),
    environments: _parseEnvironments(m['environments']),
    equipmentMetadataVerified: m['equipmentMetadataVerified'] as bool? ?? true,
    primaryMuscles: List<String>.from(m['primaryMuscles'] ?? []),
    secondaryMuscles: List<String>.from(m['secondaryMuscles'] ?? []),
    stabilizers: List<String>.from(m['stabilizers'] ?? []),
    bodyRegions: _parseBodyRegions(m['bodyRegions']),
    joints: _parseJoints(m['joints']),
    difficulty: _parseDifficulty(m['difficulty']),
    skillLevel: (m['skillLevel'] as num?)?.toInt() ?? 1,
    stabilityType: _parseStabilityType(m['stabilityType']),
    lengthBias: _parseLengthBias(m['lengthBias']),
    position: m['position'] as String? ?? 'standing',
    resistanceVector: m['resistanceVector'] as String?,
    angle: m['angle'] as String?,
    grip: m['grip'] as String?,
    laterality: m['laterality'] as String? ?? 'bilateral',
    demands: V2DemandProfile.fromMap(Map<String, dynamic>.from(m['demands'] ?? {})),
    goalAffinity: _parseGoalAffinity(m['goalAffinity']),
    stimuli: _parseStimuli(m['stimuli']),
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

  static V2ExerciseBlock _parseBlock(dynamic v) {
    if (v == null) return V2ExerciseBlock.home;
    return V2ExerciseBlock.values.firstWhere(
      (e) => e.name == v, orElse: () => V2ExerciseBlock.home);
  }

  static V2MovementPattern _parsePattern(dynamic v) {
    if (v == null) return V2MovementPattern.squat;
    return V2MovementPattern.values.firstWhere(
      (e) => e.name == v, orElse: () => V2MovementPattern.squat);
  }

  static V2ExerciseCategory _parseCategory(dynamic v) {
    if (v == null) return V2ExerciseCategory.compound;
    return V2ExerciseCategory.values.firstWhere(
      (e) => e.name == v, orElse: () => V2ExerciseCategory.compound);
  }

  static V2Difficulty _parseDifficulty(dynamic v) {
    if (v == null) return V2Difficulty.level3;
    return V2Difficulty.values.firstWhere(
      (e) => e.name == v, orElse: () => V2Difficulty.level3);
  }

  static V2StabilityType _parseStabilityType(dynamic v) {
    if (v == null) return V2StabilityType.none;
    return V2StabilityType.values.firstWhere(
      (e) => e.name == v, orElse: () => V2StabilityType.none);
  }

  static V2LengthBias _parseLengthBias(dynamic v) {
    if (v == null) return V2LengthBias.midRange;
    return V2LengthBias.values.firstWhere(
      (e) => e.name == v, orElse: () => V2LengthBias.midRange);
  }

  static List<V2ExerciseRole> _parseRoles(dynamic v) {
    if (v == null) return const [V2ExerciseRole.principal];
    return (v as List).map((e) => V2ExerciseRole.values.firstWhere(
      (r) => r.name == e, orElse: () => V2ExerciseRole.principal,
    )).toList();
  }

  static List<V2Modality> _parseModalities(dynamic v) {
    if (v == null) return const [];
    return (v as List).map((e) => V2Modality.values.firstWhere(
      (m) => m.name == e, orElse: () => V2Modality.strength,
    )).toList();
  }

  static List<V2Equipment> _parseEquipment(dynamic v) {
    if (v == null) return const [];
    return (v as List).map((e) => V2Equipment.values.firstWhere(
      (eq) => eq.name == e, orElse: () => V2Equipment.none,
    )).toList();
  }

  static List<V2Environment> _parseEnvironments(dynamic v) {
    if (v == null) return const [V2Environment.any];
    return (v as List).map((e) => V2Environment.values.firstWhere(
      (env) => env.name == e, orElse: () => V2Environment.any,
    )).toList();
  }

  static List<V2BodyRegion> _parseBodyRegions(dynamic v) {
    if (v == null) return const [];
    return (v as List).map((e) => V2BodyRegion.values.firstWhere(
      (r) => r.name == e, orElse: () => V2BodyRegion.trunk,
    )).toList();
  }

  static List<V2Joint> _parseJoints(dynamic v) {
    if (v == null) return const [];
    return (v as List).map((e) => V2Joint.values.firstWhere(
      (j) => j.name == e, orElse: () => V2Joint.knee,
    )).toList();
  }

  static Map<V2Goal, V2Intensity> _parseGoalAffinity(dynamic v) {
    if (v == null) return {};
    final map = Map<String, dynamic>.from(v);
    final result = <V2Goal, V2Intensity>{};
    for (final entry in map.entries) {
      final key = V2Goal.values.firstWhere(
        (k) => k.name == entry.key, orElse: () => V2Goal.generalFitness);
      final val = V2Intensity.values.firstWhere(
        (i) => i.name == entry.value, orElse: () => V2Intensity.moderate);
      result[key] = val;
    }
    return result;
  }

  static Map<V2Stimulus, V2Intensity> _parseStimuli(dynamic v) {
    if (v == null) return {};
    final map = Map<String, dynamic>.from(v);
    final result = <V2Stimulus, V2Intensity>{};
    for (final entry in map.entries) {
      final key = V2Stimulus.values.firstWhere(
        (k) => k.name == entry.key, orElse: () => V2Stimulus.mechanicalTension);
      final val = V2Intensity.values.firstWhere(
        (i) => i.name == entry.value, orElse: () => V2Intensity.moderate);
      result[key] = val;
    }
    return result;
  }

  static List<V2Relationship> _parseRelationships(dynamic v) {
    if (v == null) return const [];
    return (v as List).map((r) =>
      V2Relationship.fromMap(Map<String, dynamic>.from(r))
    ).toList();
  }

  static List<V2LimitationRule> _parseLimitationRules(dynamic v) {
    if (v == null) return const [];
    return (v as List).map((l) =>
      V2LimitationRule.fromMap(Map<String, dynamic>.from(l))
    ).toList();
  }
}
