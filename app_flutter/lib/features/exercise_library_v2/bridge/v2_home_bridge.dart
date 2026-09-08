import '../../exercises/exercise_model.dart';
import '../models/v2_exercise.dart';
import '../enums/difficulty.dart';
import '../enums/stability_type.dart';
import '../enums/length_bias.dart';
import '../enums/movement_pattern.dart';
import '../enums/intensity.dart';
import '../enums/joint.dart';

/// Converte V2Exercise → ExerciseModel para integração com o motor V1.
///
/// O ID do ExerciseModel resultante é EXATAMENTE o V2Exercise.id,
/// garantindo rastreabilidade V2 → prescrição → UI → histórico.
///
/// Preserva dados V2 essenciais via tags e campos do ExerciseModel.
/// Para lookup reverso (V2Exercise original), use [V2HomeBridge.getV2Exercise].
class V2HomeBridge {
  const V2HomeBridge._();

  static final Map<String, V2Exercise> _v2Registry = {};

  /// Registra um V2Exercise para lookup reverso.
  static void register(V2Exercise v2) {
    _v2Registry[v2.id] = v2;
  }

  /// Registra uma lista de V2Exercises.
  static void registerAll(List<V2Exercise> exercises) {
    for (final ex in exercises) {
      _v2Registry[ex.id] = ex;
    }
  }

  /// Lookup reverso: obtém o V2Exercise original a partir do ID.
  static V2Exercise? getV2Exercise(String id) => _v2Registry[id];

  /// Verifica se um ID pertence a um exercício V2 registrado.
  static bool isV2Exercise(String id) => _v2Registry.containsKey(id);

  /// Limpa o registro (para testes).
  static void clearRegistry() => _v2Registry.clear();

  /// Número de exercícios registrados.
  static int get registeredCount => _v2Registry.length;

  /// Converte um V2Exercise para ExerciseModel.
  /// O ExerciseModel.id será igual ao V2Exercise.id.
  static ExerciseModel toExerciseModel(V2Exercise v2) {
    register(v2);
    return ExerciseModel(
      id: v2.id,
      name: v2.name,
      nameEn: v2.nameEn,
      primaryMuscles: v2.primaryMuscles,
      secondaryMuscles: v2.secondaryMuscles,
      movementPattern: _mapPattern(v2.pattern),
      equipment: const [],
      equipmentMetadataVerified: true,
      environment: const ['home'],
      category: v2.category.name,
      difficulty: _mapDifficulty(v2.difficulty),
      restrictions: v2.relativeContraindications,
      repRangeMin: v2.engineRules.repRangeMin,
      repRangeMax: v2.engineRules.repRangeMax,
      isUnilateral: v2.laterality == 'unilateral',
      videoUrl: v2.videoUrl,
      cues: v2.cues,
      instructions: v2.instructions,
      substituteIds: v2.substituteIds,
      progressionIds: v2.progressionIds,
      regressionIds: v2.regressionIds,
      tags: [
        ...v2.tags,
        'home',
        'bodyweight',
        'v2',
        'v2_pattern_${v2.pattern.name}',
        'v2_difficulty_${v2.difficulty.name}',
      ],
      spinalLoad: _regionStress(v2, V2Joint.spine),
      shoulderStress: _regionStress(v2, V2Joint.shoulder),
      kneeStress: _regionStress(v2, V2Joint.knee),
      cnsLoad: _intensityToDouble(v2.demands.strength),
      stabilityType: _mapStabilityType(v2.stabilityType),
      lengthBias: _mapLengthBias(v2.lengthBias),
      skillLevel: v2.skillLevel,
    );
  }

  /// Converte uma lista de V2Exercise para ExerciseModel.
  static List<ExerciseModel> toExerciseModelList(List<V2Exercise> v2List) {
    return v2List.map(toExerciseModel).toList();
  }

  // ── Mapeamento de padrões ──

  static String _mapPattern(V2MovementPattern pattern) {
    switch (pattern) {
      case V2MovementPattern.squat:
        return 'squat';
      case V2MovementPattern.hipHinge:
        return 'hinge';
      case V2MovementPattern.pushHorizontal:
        return 'push_horizontal';
      case V2MovementPattern.pushIncline:
        return 'push_incline';
      case V2MovementPattern.pushVertical:
        return 'push_vertical';
      case V2MovementPattern.pullHorizontal:
        return 'pull_horizontal';
      case V2MovementPattern.pullVertical:
        return 'pull_vertical';
      case V2MovementPattern.carry:
        return 'carry';
      case V2MovementPattern.isometric:
        return 'isometric';
      case V2MovementPattern.locomotion:
        return 'locomotion';
      case V2MovementPattern.conditioning:
        return 'conditioning';
      case V2MovementPattern.power:
        return 'power';
      case V2MovementPattern.balance:
        return 'balance';
      case V2MovementPattern.mobility:
        return 'mobility';
      case V2MovementPattern.coreAntiExtension:
        return 'core_anti_extension';
      case V2MovementPattern.coreAntiRotation:
        return 'core_anti_rotation';
      case V2MovementPattern.coreAntiLateralFlexion:
        return 'core_lateral_flexion';
      case V2MovementPattern.coreRotation:
        return 'rotation';
      case V2MovementPattern.coreFlexion:
        return 'core_flexion';
      case V2MovementPattern.coreExtension:
        return 'core_extension';
      case V2MovementPattern.hipExtension:
        return 'hip_extension';
      case V2MovementPattern.hipAbduction:
        return 'hip_abduction';
      case V2MovementPattern.hipAdduction:
        return 'hip_adduction';
      case V2MovementPattern.kneeExtension:
        return 'knee_extension';
      case V2MovementPattern.kneeFlexion:
        return 'knee_flexion';
      case V2MovementPattern.plantarFlexion:
        return 'calf_raise';
      case V2MovementPattern.shoulderAbduction:
        return 'push_vertical';
      case V2MovementPattern.shoulderFlexion:
        return 'push_vertical';
      case V2MovementPattern.elbowFlexion:
        return 'isolation';
      case V2MovementPattern.elbowExtension:
        return 'isolation';
    }
  }

  // ── Mapeamento de dificuldade ──

  static String _mapDifficulty(V2Difficulty difficulty) {
    switch (difficulty) {
      case V2Difficulty.level1:
      case V2Difficulty.level2:
        return 'beginner';
      case V2Difficulty.level3:
      case V2Difficulty.level4:
        return 'intermediate';
      case V2Difficulty.level5:
        return 'advanced';
    }
  }

  // ── Mapeamento de estabilidade ──

  static String _mapStabilityType(V2StabilityType type) {
    switch (type) {
      case V2StabilityType.none:
        return 'none';
      case V2StabilityType.antiExtension:
        return 'anti_extension';
      case V2StabilityType.antiRotation:
        return 'anti_rotation';
      case V2StabilityType.antiLateralFlexion:
        return 'lateral';
      case V2StabilityType.scapular:
        return 'scapular';
      case V2StabilityType.hip:
        return 'none';
      case V2StabilityType.dynamic:
        return 'none';
    }
  }

  // ── Mapeamento de viés de comprimento ──

  static String _mapLengthBias(V2LengthBias bias) {
    switch (bias) {
      case V2LengthBias.lengthened:
        return 'lengthened';
      case V2LengthBias.shortened:
        return 'shortened';
      case V2LengthBias.midRange:
        return 'mid_range';
    }
  }

  // ── Conversão de intensidade para double (0.0–1.0) ──

  static double _intensityToDouble(V2Intensity intensity) {
    switch (intensity) {
      case V2Intensity.none:
        return 0.0;
      case V2Intensity.low:
        return 0.25;
      case V2Intensity.moderate:
        return 0.5;
      case V2Intensity.high:
        return 0.75;
      case V2Intensity.veryHigh:
        return 1.0;
    }
  }

  // ── Estresse por articulação (graduado) ──

  static double _regionStress(V2Exercise v2, V2Joint joint) {
    final joints = v2.joints;
    if (!joints.contains(joint)) return 0.0;

    final idx = joints.indexOf(joint);
  final total = joints.length;
    if (total <= 1) return 0.5;

    final position = idx / (total - 1);
    if (position <= 0.33) return 0.75;
    if (position <= 0.66) return 0.5;
    return 0.25;
  }
}
