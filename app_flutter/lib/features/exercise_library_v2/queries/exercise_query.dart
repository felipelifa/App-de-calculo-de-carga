import '../enums/movement_pattern.dart';
import '../enums/body_region.dart';
import '../enums/joint.dart';
import '../enums/modality.dart';
import '../enums/environment.dart';
import '../enums/equipment.dart';
import '../enums/difficulty.dart';
import '../enums/exercise_block.dart';
import '../enums/exercise_role.dart';
import '../enums/goal.dart';
import '../enums/stimulus.dart';
import '../enums/intensity.dart';

/// Consulta declarativa para filtrar exercícios da biblioteca V2.
class ExerciseQuery {
  final List<V2ExerciseBlock>? blocks;
  final List<V2MovementPattern>? patterns;
  final List<String>? primaryMuscles;
  final List<String>? secondaryMuscles;
  final List<V2BodyRegion>? bodyRegions;
  final List<V2Joint>? avoidsJoints;
  final List<V2Equipment>? availableEquipment;
  final List<V2Environment>? environments;
  final List<V2Modality>? modalities;
  final V2Difficulty? maxDifficulty;
  final V2Difficulty? minDifficulty;
  final List<V2ExerciseRole>? roles;
  final List<V2Goal>? goals;
  final List<V2Stimulus>? stimuli;
  final bool? requireCompound;
  final bool? requireUnilateral;
  final V2Intensity? maxStrengthDemand;
  final V2Intensity? maxStabilityDemand;
  final V2Intensity? maxMobilityDemand;
  final List<String>? excludeIds;
  final List<String>? includeOnlyIds;
  final List<String>? tags;
  final String? textSearch;

  const ExerciseQuery({
    this.blocks,
    this.patterns,
    this.primaryMuscles,
    this.secondaryMuscles,
    this.bodyRegions,
    this.avoidsJoints,
    this.availableEquipment,
    this.environments,
    this.modalities,
    this.maxDifficulty,
    this.minDifficulty,
    this.roles,
    this.goals,
    this.stimuli,
    this.requireCompound,
    this.requireUnilateral,
    this.maxStrengthDemand,
    this.maxStabilityDemand,
    this.maxMobilityDemand,
    this.excludeIds,
    this.includeOnlyIds,
    this.tags,
    this.textSearch,
  });

  factory ExerciseQuery.forMuscle({
    required String muscle,
    required List<V2Equipment> equipment,
    V2Difficulty? maxDifficulty,
    bool compoundOnly = false,
  }) => ExerciseQuery(
    primaryMuscles: [muscle],
    availableEquipment: equipment,
    maxDifficulty: maxDifficulty,
    requireCompound: compoundOnly ? true : null,
  );
}
