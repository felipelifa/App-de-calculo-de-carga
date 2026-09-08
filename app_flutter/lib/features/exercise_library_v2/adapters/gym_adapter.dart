import '../gym_workout/gym_exercise_model.dart';
import '../enums/movement_pattern.dart';
import '../enums/joint.dart';
import '../enums/environment.dart';
import '../enums/equipment.dart';
import '../enums/difficulty.dart';
import '../enums/exercise_category.dart';
import '../enums/exercise_block.dart';
import '../enums/exercise_role.dart';
import '../enums/stability_type.dart';
import '../enums/intensity.dart';
import '../enums/relationship_type.dart';
import '../models/v2_exercise.dart';
import '../models/v2_demand_profile.dart';
import '../models/v2_relationship.dart';
import '../models/v2_limitation_rule.dart';
import '../models/v2_engine_rules.dart';

/// Bridge entre GymExercise antigo e V2Exercise.
class GymExerciseAdapter {
  static V2Exercise fromGymExercise(GymExercise gym) {
    return V2Exercise(
      id: gym.id,
      name: gym.name,
      nameEn: gym.aliases.isNotEmpty ? gym.aliases.first : '',
      aliases: gym.aliases,
      block: V2ExerciseBlock.gymFreeWeights,
      pattern: _mapPattern(gym.pattern),
      category: gym.category == 'compound'
          ? V2ExerciseCategory.compound
          : V2ExerciseCategory.isolation,
      primaryFunction: gym.function,
      defaultRoles: const [V2ExerciseRole.principal],
      requiredEquipment: _mapEquipment(gym.equipment),
      environments: const [V2Environment.gym],
      primaryMuscles: gym.primaryMuscles.map((m) => m.name).toList(),
      secondaryMuscles: gym.secondaryMuscles.map((m) => m.name).toList(),
      joints: _mapJoints(gym.joints),
      difficulty: _inferDifficulty(gym),
      skillLevel: gym.technicalDemand,
      stabilityType: _mapStability(gym.stability),
      demands: V2DemandProfile(
        strength: _potentialToV2Intensity(gym.strengthPotential),
        stability: _stabilityToV2Intensity(gym.stability),
        technical: _technicalToV2Intensity(gym.technicalDemand),
      ),
      relatedExercises: _buildRelationships(gym),
      limitationRules: _buildLimitationRules(gym),
      relevantLimitations: gym.relevantLimitations,
      relativeContraindications: gym.relativeContraindications,
      engineRules: const V2EngineRules(),
    );
  }

  static V2MovementPattern _mapPattern(GymMovementPattern pattern) {
    switch (pattern) {
      case GymMovementPattern.lowerSquat: return V2MovementPattern.squat;
      case GymMovementPattern.lowerHinge: return V2MovementPattern.hipHinge;
      case GymMovementPattern.lowerLunge: return V2MovementPattern.squat;
      case GymMovementPattern.lowerKneeExtension: return V2MovementPattern.kneeExtension;
      case GymMovementPattern.lowerKneeFlexion: return V2MovementPattern.kneeFlexion;
      case GymMovementPattern.lowerHipExtension: return V2MovementPattern.hipExtension;
      case GymMovementPattern.lowerHipAbduction: return V2MovementPattern.hipAbduction;
      case GymMovementPattern.lowerHipAdduction: return V2MovementPattern.hipAdduction;
      case GymMovementPattern.lowerPlantarFlexion: return V2MovementPattern.plantarFlexion;
      case GymMovementPattern.upperHorizontalPush: return V2MovementPattern.pushHorizontal;
      case GymMovementPattern.upperVerticalPush: return V2MovementPattern.pushVertical;
      case GymMovementPattern.upperInclinePush: return V2MovementPattern.pushIncline;
      case GymMovementPattern.upperHorizontalPull: return V2MovementPattern.pullHorizontal;
      case GymMovementPattern.upperVerticalPull: return V2MovementPattern.pullVertical;
      case GymMovementPattern.upperShoulderAbduction: return V2MovementPattern.shoulderAbduction;
      case GymMovementPattern.upperShoulderFlexion: return V2MovementPattern.shoulderFlexion;
      case GymMovementPattern.upperElbowFlexion: return V2MovementPattern.elbowFlexion;
      case GymMovementPattern.upperElbowExtension: return V2MovementPattern.elbowExtension;
      case GymMovementPattern.coreAntiExtension: return V2MovementPattern.coreAntiExtension;
      case GymMovementPattern.coreAntiRotation: return V2MovementPattern.coreAntiRotation;
      case GymMovementPattern.coreAntiLateralFlexion: return V2MovementPattern.coreAntiLateralFlexion;
      case GymMovementPattern.coreRotation: return V2MovementPattern.coreRotation;
      case GymMovementPattern.coreFlexion: return V2MovementPattern.coreFlexion;
      case GymMovementPattern.coreExtension: return V2MovementPattern.coreExtension;
      case GymMovementPattern.generalCarry: return V2MovementPattern.carry;
      case GymMovementPattern.generalLocomotion: return V2MovementPattern.locomotion;
      case GymMovementPattern.generalPower: return V2MovementPattern.power;
      case GymMovementPattern.generalIsolation: return V2MovementPattern.elbowFlexion;
      case GymMovementPattern.generalIsometric: return V2MovementPattern.isometric;
    }
  }

  static List<V2Equipment> _mapEquipment(GymEquipment equipment) {
    switch (equipment) {
      case GymEquipment.barbell: return [V2Equipment.barbell];
      case GymEquipment.dumbbell: return [V2Equipment.dumbbell];
      case GymEquipment.kettlebell: return [V2Equipment.kettlebell];
      case GymEquipment.cable: return [V2Equipment.cable];
      case GymEquipment.machine: return [V2Equipment.machine];
      case GymEquipment.smith: return [V2Equipment.smith];
      case GymEquipment.band: return [V2Equipment.band];
      case GymEquipment.plate: return [V2Equipment.plate];
      case GymEquipment.bodyweight: return [];
      case GymEquipment.suspension: return [V2Equipment.suspension];
      case GymEquipment.landmine: return [V2Equipment.landmine];
      case GymEquipment.ezBar: return [V2Equipment.ezBar];
      case GymEquipment.trapBar: return [V2Equipment.trapBar];
      case GymEquipment.swissBar: return [V2Equipment.swissBar];
    }
  }

  static List<V2Joint> _mapJoints(List<GymBodyRegion> regions) {
    final joints = <V2Joint>{};
    for (final r in regions) {
      switch (r) {
        case GymBodyRegion.shoulder:
        case GymBodyRegion.anteriorDeltoid:
        case GymBodyRegion.lateralDeltoid:
        case GymBodyRegion.rearDeltoid:
          joints.add(V2Joint.shoulder);
          break;
        case GymBodyRegion.triceps:
        case GymBodyRegion.biceps:
        case GymBodyRegion.forearm:
          joints.add(V2Joint.elbow);
          break;
        case GymBodyRegion.quadriceps:
        case GymBodyRegion.hamstrings:
        case GymBodyRegion.glutes:
        case GymBodyRegion.adductors:
        case GymBodyRegion.abductors:
          joints.add(V2Joint.hip);
          joints.add(V2Joint.knee);
          break;
        case GymBodyRegion.calves:
        case GymBodyRegion.tibialisAnterior:
          joints.add(V2Joint.ankle);
          break;
        case GymBodyRegion.erectorSpinae:
        case GymBodyRegion.lowerBack:
          joints.add(V2Joint.spine);
          break;
        default:
          break;
      }
    }
    return joints.toList();
  }

  static V2Difficulty _inferDifficulty(GymExercise gym) {
    if (gym.recommendedForBeginner) return V2Difficulty.level1;
    if (gym.recommendedForAdvanced) return V2Difficulty.level4;
    if (gym.recommendedForIntermediate) return V2Difficulty.level3;
    return V2Difficulty.level3;
  }

  static V2StabilityType _mapStability(GymStabilityLevel stability) {
    switch (stability) {
      case GymStabilityLevel.veryLow:
      case GymStabilityLevel.low:
        return V2StabilityType.dynamic;
      case GymStabilityLevel.moderate:
        return V2StabilityType.none;
      case GymStabilityLevel.high:
      case GymStabilityLevel.veryHigh:
        return V2StabilityType.none;
    }
  }

  static V2Intensity _potentialToV2Intensity(GymPotentialLevel level) {
    switch (level) {
      case GymPotentialLevel.none: return V2Intensity.none;
      case GymPotentialLevel.low: return V2Intensity.low;
      case GymPotentialLevel.moderate: return V2Intensity.moderate;
      case GymPotentialLevel.high: return V2Intensity.high;
      case GymPotentialLevel.veryHigh: return V2Intensity.veryHigh;
    }
  }

  static V2Intensity _stabilityToV2Intensity(GymStabilityLevel level) {
    switch (level) {
      case GymStabilityLevel.veryLow: return V2Intensity.veryHigh;
      case GymStabilityLevel.low: return V2Intensity.high;
      case GymStabilityLevel.moderate: return V2Intensity.moderate;
      case GymStabilityLevel.high: return V2Intensity.low;
      case GymStabilityLevel.veryHigh: return V2Intensity.none;
    }
  }

  static V2Intensity _technicalToV2Intensity(int technicalDemand) {
    if (technicalDemand <= 1) return V2Intensity.low;
    if (technicalDemand <= 2) return V2Intensity.moderate;
    if (technicalDemand <= 3) return V2Intensity.high;
    return V2Intensity.veryHigh;
  }

  static List<V2Relationship> _buildRelationships(GymExercise gym) {
    final relations = <V2Relationship>[];
    for (final id in gym.directSubstitutions) {
      relations.add(V2Relationship(targetId: id, type: V2RelationshipType.substitute));
    }
    for (final id in gym.functionalSubstitutions) {
      relations.add(V2Relationship(targetId: id, type: V2RelationshipType.alternative));
    }
    for (final id in gym.equivalentExercises) {
      relations.add(V2Relationship(targetId: id, type: V2RelationshipType.sameFunction));
    }
    return relations;
  }

  static List<V2LimitationRule> _buildLimitationRules(GymExercise gym) {
    return gym.relevantLimitations.map((limitation) => V2LimitationRule(
      joint: V2Joint.knee,
      severity: V2LimitationSeverity.moderate,
      symptoms: [limitation],
      alternativeExerciseIds: gym.functionalSubstitutions,
      regressionExerciseIds: gym.directSubstitutions,
    )).toList();
  }
}
