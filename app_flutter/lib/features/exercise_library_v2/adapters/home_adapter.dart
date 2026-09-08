import '../home_workout/home_exercise_model.dart';
import '../enums/movement_pattern.dart';
import '../enums/environment.dart';
import '../enums/difficulty.dart';
import '../enums/exercise_category.dart';
import '../enums/exercise_block.dart';
import '../enums/exercise_role.dart';
import '../enums/intensity.dart';
import '../models/v2_exercise.dart';
import '../models/v2_demand_profile.dart';
import '../models/v2_relationship.dart';
import '../enums/relationship_type.dart';
import '../models/v2_engine_rules.dart';

/// Bridge entre HomeExercise antigo e V2Exercise.
class HomeExerciseAdapter {
  static V2Exercise fromHomeExercise(HomeExercise home) {
    return V2Exercise(
      id: home.id,
      name: home.name,
      nameEn: home.nameEn,
      block: V2ExerciseBlock.home,
      pattern: _mapPattern(home.pattern),
      category: home.strengthDemand > 0.6
          ? V2ExerciseCategory.compound
          : V2ExerciseCategory.isolation,
      primaryFunction: home.primaryFunction,
      defaultRoles: const [V2ExerciseRole.principal],
      requiredEquipment: const [],
      environments: const [V2Environment.home],
      primaryMuscles: home.primaryMuscles,
      secondaryMuscles: home.secondaryMuscles,
      difficulty: _mapDifficulty(home.difficulty),
      skillLevel: home.difficulty.index + 1,
      demands: V2DemandProfile(
        strength: _demandToV2Intensity(home.strengthDemand),
        stability: _demandToV2Intensity(home.stabilityDemand),
        mobility: _demandToV2Intensity(home.mobilityDemand),
        balance: _demandToV2Intensity(home.balanceDemand),
        coordination: _demandToV2Intensity(home.coordinationDemand),
        impact: _demandToV2Intensity(home.impactLevel),
      ),
      relatedExercises: _buildRelationships(home),
      cues: home.cues,
      equipmentMetadataVerified: home.equipmentMetadataVerified,
      engineRules: const V2EngineRules(),
    );
  }

  static V2MovementPattern _mapPattern(HomeMovementPattern pattern) {
    switch (pattern) {
      case HomeMovementPattern.squat: return V2MovementPattern.squat;
      case HomeMovementPattern.hipHinge: return V2MovementPattern.hipHinge;
      case HomeMovementPattern.pushHorizontal: return V2MovementPattern.pushHorizontal;
      case HomeMovementPattern.pullHorizontal: return V2MovementPattern.pullHorizontal;
      case HomeMovementPattern.pushVertical: return V2MovementPattern.pushVertical;
      case HomeMovementPattern.pullVertical: return V2MovementPattern.pullVertical;
      case HomeMovementPattern.unilateral: return V2MovementPattern.locomotion;
      case HomeMovementPattern.coreAntiExtension: return V2MovementPattern.coreAntiExtension;
      case HomeMovementPattern.calf: return V2MovementPattern.plantarFlexion;
      case HomeMovementPattern.hipExtension: return V2MovementPattern.hipExtension;
      case HomeMovementPattern.coreLateral: return V2MovementPattern.coreAntiLateralFlexion;
      case HomeMovementPattern.coreRotation: return V2MovementPattern.coreRotation;
      case HomeMovementPattern.coreFlexion: return V2MovementPattern.coreFlexion;
      case HomeMovementPattern.hipAbduction: return V2MovementPattern.hipAbduction;
      case HomeMovementPattern.hipAdduction: return V2MovementPattern.hipAdduction;
      case HomeMovementPattern.kneeExtension: return V2MovementPattern.kneeExtension;
      case HomeMovementPattern.kneeFlexion: return V2MovementPattern.kneeFlexion;
      case HomeMovementPattern.locomotion: return V2MovementPattern.locomotion;
      case HomeMovementPattern.conditioning: return V2MovementPattern.conditioning;
      case HomeMovementPattern.power: return V2MovementPattern.power;
      case HomeMovementPattern.balance: return V2MovementPattern.balance;
      case HomeMovementPattern.mobility: return V2MovementPattern.mobility;
    }
  }

  static V2Difficulty _mapDifficulty(HomeDifficulty difficulty) {
    switch (difficulty) {
      case HomeDifficulty.level1: return V2Difficulty.level1;
      case HomeDifficulty.level2: return V2Difficulty.level2;
      case HomeDifficulty.level3: return V2Difficulty.level3;
      case HomeDifficulty.level4: return V2Difficulty.level4;
      case HomeDifficulty.level5: return V2Difficulty.level5;
    }
  }

  static V2Intensity _demandToV2Intensity(double demand) {
    if (demand <= 0.1) return V2Intensity.none;
    if (demand <= 0.3) return V2Intensity.low;
    if (demand <= 0.6) return V2Intensity.moderate;
    if (demand <= 0.8) return V2Intensity.high;
    return V2Intensity.veryHigh;
  }

  static List<V2Relationship> _buildRelationships(HomeExercise home) {
    final relations = <V2Relationship>[];
    if (home.regressionId != null) {
      relations.add(V2Relationship(
        targetId: home.regressionId!,
        type: V2RelationshipType.regression,
      ));
    }
    if (home.progressionId != null) {
      relations.add(V2Relationship(
        targetId: home.progressionId!,
        type: V2RelationshipType.progression,
      ));
    }
    for (final altId in home.alternativeIds) {
      relations.add(V2Relationship(
        targetId: altId,
        type: V2RelationshipType.alternative,
      ));
    }
    return relations;
  }
}
