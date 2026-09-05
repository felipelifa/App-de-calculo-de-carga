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
    
    // Technical demand: baseado em skillLevel do exercício
    final technical = ((exercise.skillLevel / 5) + (compound ? 0.25 : 0.0))
        .clamp(0.0, 1.0)
        .toDouble();
    
    // Mobility demand: dinâmico baseado nos músculos primários e pattern
    double mobility = 0.3; // base
    if (pattern == 'push_vertical' || pattern == 'squat') mobility = 0.6;
    if (exercise.primaryMuscles.contains('shoulders') && pattern == 'push_vertical') mobility = 0.7;
    if (exercise.primaryMuscles.contains('hip_flexors')) mobility = 0.5;
    if (exercise.isUnilateral) mobility += 0.1;
    
    // Stability demand: dinâmico baseado em equipamento e category
    double stability = compound ? 0.6 : 0.25;
    if (exercise.equipment.contains('barbell')) stability += 0.1;
    if (exercise.equipment.contains('dumbbell')) stability += 0.05;
    if (exercise.equipment.contains('machine')) stability -= 0.2;
    if (exercise.equipment.contains('cable')) stability -= 0.1;
    if (exercise.isUnilateral) stability += 0.15;
    
    // Cardiovascular demand: dinâmico baseado em pattern e unilateralidade
    double cardiovascular = 0.15;
    if (pattern == 'carry') cardiovascular = 0.5;
    if (exercise.isUnilateral) cardiovascular = 0.35;
    if (pattern == 'squat' && compound) cardiovascular = 0.25;
    if (pattern == 'hinge' && compound) cardiovascular = 0.2;
    
    // Recovery cost: dinâmico baseado nos metadados do exercício
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
      mobilityDemand: mobility.clamp(0.0, 1.0).toDouble(),
      stabilityDemand: stability.clamp(0.0, 1.0).toDouble(),
      cardiovascularDemand: cardiovascular.clamp(0.0, 1.0).toDouble(),
      recoveryCost: recovery,
      cautionContexts: [
        if (exercise.shoulderStress >= 0.7) 'shoulder_load',
        if (exercise.kneeStress >= 0.7) 'knee_load',
        if (exercise.spinalLoad >= 0.7) 'spinal_load',
        if (exercise.skillLevel >= 4) 'high_technical_demand',
        if (exercise.isUnilateral) 'unilateral_balance_demand',
      ],
    );
  }
}
