/// Padrões de movimento unificados.
/// Substitui HomeMovementPattern (22), GymMovementPattern (29) e String livre.
enum V2MovementPattern {
  squat,
  hipHinge,
  kneeExtension,
  kneeFlexion,
  hipExtension,
  hipAbduction,
  hipAdduction,
  plantarFlexion,

  pushHorizontal,
  pushVertical,
  pushIncline,

  pullHorizontal,
  pullVertical,

  shoulderAbduction,
  shoulderFlexion,
  elbowFlexion,
  elbowExtension,

  coreAntiExtension,
  coreAntiRotation,
  coreAntiLateralFlexion,
  coreRotation,
  coreFlexion,
  coreExtension,

  locomotion,
  carry,
  power,
  conditioning,
  balance,
  mobility,
  isometric,
}

extension V2MovementPatternX on V2MovementPattern {
  bool get loadsSpine =>
      this == V2MovementPattern.squat ||
      this == V2MovementPattern.hipHinge ||
      this == V2MovementPattern.carry;

  bool get stressesShoulder =>
      this == V2MovementPattern.pushHorizontal ||
      this == V2MovementPattern.pushVertical ||
      this == V2MovementPattern.pushIncline ||
      this == V2MovementPattern.pullHorizontal ||
      this == V2MovementPattern.pullVertical;

  bool get stressesKnee =>
      this == V2MovementPattern.squat ||
      this == V2MovementPattern.kneeExtension ||
      this == V2MovementPattern.kneeFlexion;

  bool get isCompoundByNature =>
      this == V2MovementPattern.squat ||
      this == V2MovementPattern.hipHinge ||
      this == V2MovementPattern.pushHorizontal ||
      this == V2MovementPattern.pushVertical ||
      this == V2MovementPattern.pushIncline ||
      this == V2MovementPattern.pullHorizontal ||
      this == V2MovementPattern.pullVertical ||
      this == V2MovementPattern.carry ||
      this == V2MovementPattern.power ||
      this == V2MovementPattern.locomotion;
}
