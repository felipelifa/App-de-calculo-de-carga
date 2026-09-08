import '../../exercises/exercise_model.dart';
import '../enums/movement_pattern.dart';
import '../enums/environment.dart';
import '../enums/equipment.dart';
import '../enums/difficulty.dart';
import '../enums/exercise_category.dart';
import '../enums/exercise_block.dart';
import '../enums/stability_type.dart';
import '../enums/length_bias.dart';
import '../enums/intensity.dart';
import '../models/v2_exercise.dart';
import '../models/v2_demand_profile.dart';
import '../models/v2_engine_rules.dart';

/// Bridge entre ExerciseModel antigo e V2Exercise.
/// NÃO migra dados — apenas permite que partes antigas do app quebrem menos.
class LegacyExerciseAdapter {
  /// Converte ExerciseModel para V2Exercise.
  /// Campos ausentes recebem valores padrão.
  static V2Exercise fromLegacy(ExerciseModel legacy) {
    return V2Exercise(
      id: legacy.id,
      name: legacy.name,
      nameEn: legacy.nameEn,
      block: _inferBlock(legacy),
      pattern: _mapPattern(legacy.movementPattern),
      category: _mapCategory(legacy.category),
      primaryFunction: '',
      environments: _mapEnvironments(legacy.environment),
      requiredEquipment: _mapEquipment(legacy.equipment),
      primaryMuscles: legacy.primaryMuscles,
      secondaryMuscles: legacy.secondaryMuscles,
      difficulty: _mapDifficulty(legacy.difficulty),
      skillLevel: legacy.skillLevel,
      stabilityType: _mapStability(legacy.stabilityType),
      lengthBias: _mapLengthBias(legacy.lengthBias),
      demands: V2DemandProfile(
        strength: V2Intensity.moderate,
        stability: V2Intensity.low,
        mobility: V2Intensity.low,
      ),
      engineRules: const V2EngineRules(),
      equipmentMetadataVerified: legacy.equipmentMetadataVerified,
    );
  }

  static V2ExerciseBlock _inferBlock(ExerciseModel ex) {
    final env = ex.environment.map((e) => e.toLowerCase());
    if (env.contains('home')) return V2ExerciseBlock.home;
    return V2ExerciseBlock.gymFreeWeights;
  }

  static V2MovementPattern _mapPattern(String pattern) {
    switch (pattern.toLowerCase()) {
      case 'squat': return V2MovementPattern.squat;
      case 'hinge': return V2MovementPattern.hipHinge;
      case 'push_horizontal': return V2MovementPattern.pushHorizontal;
      case 'push_vertical': return V2MovementPattern.pushVertical;
      case 'push_incline': return V2MovementPattern.pushIncline;
      case 'pull_horizontal': return V2MovementPattern.pullHorizontal;
      case 'pull_vertical': return V2MovementPattern.pullVertical;
      case 'rotation': return V2MovementPattern.coreRotation;
      case 'carry': return V2MovementPattern.carry;
      case 'isometric': return V2MovementPattern.isometric;
      case 'isolation': return V2MovementPattern.elbowFlexion;
      default: return V2MovementPattern.squat;
    }
  }

  static V2ExerciseCategory _mapCategory(String category) {
    switch (category.toLowerCase()) {
      case 'compound': return V2ExerciseCategory.compound;
      case 'isolation': return V2ExerciseCategory.isolation;
      default: return V2ExerciseCategory.compound;
    }
  }

  static List<V2Environment> _mapEnvironments(List<String> environments) {
    return environments.map((e) {
      switch (e.toLowerCase()) {
        case 'home': return V2Environment.home;
        case 'gym': return V2Environment.gym;
        case 'outdoor': return V2Environment.outdoor;
        default: return V2Environment.any;
      }
    }).toSet().toList();
  }

  static List<V2Equipment> _mapEquipment(List<String> equipment) {
    return equipment.map((e) {
      switch (e.toLowerCase()) {
        case 'dumbbell': return V2Equipment.dumbbell;
        case 'barbell': return V2Equipment.barbell;
        case 'kettlebell': return V2Equipment.kettlebell;
        case 'cable': return V2Equipment.cable;
        case 'machine': return V2Equipment.machine;
        case 'smith': return V2Equipment.smith;
        case 'band': return V2Equipment.band;
        case 'bench': return V2Equipment.bench;
        case 'pull_up_bar': return V2Equipment.pullUpBar;
        case 'suspension': return V2Equipment.suspension;
        case 'trx': return V2Equipment.suspension;
        case 'bodyweight': return V2Equipment.none;
        case 'none': return V2Equipment.none;
        default: return V2Equipment.none;
      }
    }).where((e) => e != V2Equipment.none).toSet().toList();
  }

  static V2Difficulty _mapDifficulty(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner': return V2Difficulty.level1;
      case 'intermediate': return V2Difficulty.level3;
      case 'advanced': return V2Difficulty.level5;
      default: return V2Difficulty.level3;
    }
  }

  static V2StabilityType _mapStability(String type) {
    switch (type.toLowerCase()) {
      case 'anti_extension': return V2StabilityType.antiExtension;
      case 'anti_rotation': return V2StabilityType.antiRotation;
      case 'anti_lateral': return V2StabilityType.antiLateralFlexion;
      case 'scapular': return V2StabilityType.scapular;
      default: return V2StabilityType.none;
    }
  }

  static V2LengthBias _mapLengthBias(String bias) {
    switch (bias.toLowerCase()) {
      case 'lengthened': return V2LengthBias.lengthened;
      case 'shortened': return V2LengthBias.shortened;
      default: return V2LengthBias.midRange;
    }
  }
}
