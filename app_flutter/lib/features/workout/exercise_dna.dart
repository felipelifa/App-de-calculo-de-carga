import '../exercises/exercise_model.dart';

/// Perfil funcional derivado dos metadados do exercício.
///
/// Os campos são deliberadamente relativos. Eles não classificam um
/// exercício como bom ou ruim; descrevem o tipo de demanda que será cruzado
/// com o perfil e o estado atual do usuário.
class ExerciseDna {
  final List<String> functions;
  final List<String> capabilities;
  final List<String> joints;
  final double technicalDemand;
  final double mobilityDemand;
  final double stabilityDemand;
  final double cardiovascularDemand;
  final double recoveryCost;
  final List<String> cautionContexts;

  const ExerciseDna({
    required this.functions,
    required this.capabilities,
    required this.joints,
    required this.technicalDemand,
    required this.mobilityDemand,
    required this.stabilityDemand,
    required this.cardiovascularDemand,
    required this.recoveryCost,
    required this.cautionContexts,
  });

  factory ExerciseDna.fromExercise(ExerciseModel exercise) {
    final pattern = exercise.movementPattern;
    final functions = <String>[];
    final capabilities = <String>[];
    final joints = <String>[];

    void addAll(Iterable<String> values, List<String> target) {
      for (final value in values) {
        if (!target.contains(value)) target.add(value);
      }
    }

    if (pattern == 'squat') {
      addAll(['knee_extension', 'hip_extension', 'trunk_control'], functions);
      addAll(['strength', 'lower_limb_control'], capabilities);
      addAll(['ankle', 'knee', 'hip', 'trunk'], joints);
    } else if (pattern == 'hinge') {
      addAll(['hip_extension', 'trunk_control'], functions);
      addAll(['strength', 'posterior_chain_control'], capabilities);
      addAll(['hip', 'pelvis', 'lumbar_spine'], joints);
    } else if (pattern == 'push_horizontal' || pattern == 'push_incline') {
      addAll(['horizontal_push', 'elbow_extension', 'scapular_control'], functions);
      addAll(['strength', 'upper_limb_control'], capabilities);
      addAll(['shoulder', 'scapula', 'elbow'], joints);
    } else if (pattern == 'push_vertical') {
      addAll(['vertical_push', 'scapular_control'], functions);
      addAll(['strength', 'overhead_control'], capabilities);
      addAll(['shoulder', 'scapula', 'elbow', 'trunk'], joints);
    } else if (pattern == 'pull_horizontal') {
      addAll(['horizontal_pull', 'scapular_retraction'], functions);
      addAll(['strength', 'scapular_control'], capabilities);
      addAll(['shoulder', 'scapula', 'elbow'], joints);
    } else if (pattern == 'pull_vertical') {
      addAll(['vertical_pull', 'scapular_depression'], functions);
      addAll(['strength', 'upper_limb_control'], capabilities);
      addAll(['shoulder', 'scapula', 'elbow', 'trunk'], joints);
    } else if (pattern == 'rotation') {
      addAll(['trunk_rotation', 'force_transfer'], functions);
      addAll(['rotation_control', 'coordination'], capabilities);
      addAll(['trunk', 'hip', 'shoulder'], joints);
    } else if (pattern == 'carry') {
      addAll(['locomotion', 'load_transfer', 'trunk_control'], functions);
      addAll(['grip', 'stability', 'coordination'], capabilities);
      addAll(['shoulder', 'spine', 'hip', 'knee', 'ankle'], joints);
    } else if (pattern == 'isometric') {
      addAll(['position_control', 'joint_stability'], functions);
      addAll(['isometric_strength', 'stability'], capabilities);
      addAll(['trunk', 'shoulder', 'hip'], joints);
    } else {
      addAll(['local_force_production'], functions);
      addAll(['local_strength', 'motor_control'], capabilities);
      addAll(exercise.primaryMuscles.map((m) => '${m}_related_joint'), joints);
    }

    final compound = exercise.category == 'compound';
    final technical = ((exercise.skillLevel / 5) + (compound ? 0.25 : 0.0))
        .clamp(0.0, 1.0)
        .toDouble();
    final mobility = pattern == 'push_vertical' || pattern == 'squat' ? 0.6 : 0.3;
    final stability = compound ? 0.6 : 0.25;
    final cardiovascular = pattern == 'carry' || exercise.isUnilateral ? 0.4 : 0.15;
    final recovery = ((exercise.spinalLoad +
                exercise.shoulderStress +
                exercise.kneeStress +
                exercise.cnsLoad) /
            4)
        .clamp(0.0, 1.0)
        .toDouble();

    return ExerciseDna(
      functions: functions,
      capabilities: capabilities,
      joints: joints,
      technicalDemand: technical,
      mobilityDemand: mobility,
      stabilityDemand: stability,
      cardiovascularDemand: cardiovascular,
      recoveryCost: recovery,
      cautionContexts: [
        if (exercise.shoulderStress >= 0.7) 'shoulder_load',
        if (exercise.kneeStress >= 0.7) 'knee_load',
        if (exercise.spinalLoad >= 0.7) 'spinal_load',
        if (exercise.skillLevel >= 4) 'high_technical_demand',
      ],
    );
  }
}
