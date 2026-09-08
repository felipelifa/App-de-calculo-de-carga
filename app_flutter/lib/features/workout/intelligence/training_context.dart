import '../../exercise_library_v2/enums/goal.dart';
import '../../exercise_library_v2/enums/modality.dart';
import '../../exercise_library_v2/enums/environment.dart';
import '../../exercise_library_v2/enums/equipment.dart';
import '../../exercise_library_v2/enums/capacity.dart';
import '../../exercise_library_v2/enums/movement_pattern.dart';
import '../../exercise_library_v2/enums/difficulty.dart';
import 'user_training_profile.dart';

/// Contexto de treinamento derivado do perfil do usuário.
/// Representa o estado necessário para uma decisão do motor.
class TrainingContext {
  final String uid;
  final int age;
  final V2Goal primaryGoal;
  final List<V2Goal> secondaryGoals;
  final V2Modality modality;
  final V2Environment environment;
  final List<V2Equipment> availableEquipment;
  final int availableDaysPerWeek;
  final int sessionDurationMinutes;
  final V2Difficulty userDifficulty;
  final int trainingAgeMonths;
  final UserCapacityProfile capacities;
  final List<UserLimitation> limitations;
  final List<String> preferredExerciseIds;
  final List<String> dislikedExerciseIds;
  final List<TrainingPriority> priorities;
  final List<String> recentExerciseIds;
  final List<SafetyAlert> safetyAlerts;

  const TrainingContext({
    required this.uid,
    required this.age,
    required this.primaryGoal,
    this.secondaryGoals = const [],
    required this.modality,
    required this.environment,
    this.availableEquipment = const [],
    required this.availableDaysPerWeek,
    required this.sessionDurationMinutes,
    required this.userDifficulty,
    this.trainingAgeMonths = 0,
    this.capacities = const UserCapacityProfile(),
    this.limitations = const [],
    this.preferredExerciseIds = const [],
    this.dislikedExerciseIds = const [],
    this.priorities = const [],
    this.recentExerciseIds = const [],
    this.safetyAlerts = const [],
  });

  /// Cria contexto a partir do perfil do usuário.
  factory TrainingContext.fromProfile(UserTrainingProfile profile) {
    return TrainingContext(
      uid: profile.uid,
      age: profile.age,
      primaryGoal: profile.primaryGoal,
      secondaryGoals: profile.secondaryGoals,
      modality: profile.modality,
      environment: profile.environment,
      availableEquipment: profile.availableEquipment,
      availableDaysPerWeek: profile.availableDaysPerWeek,
      sessionDurationMinutes: profile.sessionDurationMinutes,
      userDifficulty: profile.derivedDifficulty,
      trainingAgeMonths: profile.trainingAgeMonths,
      capacities: profile.capacities,
      limitations: profile.limitations,
      preferredExerciseIds: profile.preferredExerciseIds,
      dislikedExerciseIds: profile.dislikedExerciseIds,
      priorities: profile.priorities,
      safetyAlerts: profile.safetyAlerts,
    );
  }

  bool get hasEquipment => availableEquipment.isNotEmpty &&
      !availableEquipment.contains(V2Equipment.none);

  bool get hasLimitations => limitations.isNotEmpty;

  bool get isHome => environment == V2Environment.home;
  bool get isGym => environment == V2Environment.gym;

  /// Patterns necessários para o objetivo atual.
  List<V2MovementPattern> get requiredPatterns {
    switch (primaryGoal) {
      case V2Goal.hypertrophy:
      case V2Goal.strength:
        return [
          V2MovementPattern.squat,
          V2MovementPattern.hipHinge,
          V2MovementPattern.pushHorizontal,
          V2MovementPattern.pullHorizontal,
        ];
      case V2Goal.endurance:
        return [
          V2MovementPattern.squat,
          V2MovementPattern.pushHorizontal,
          V2MovementPattern.coreAntiExtension,
          V2MovementPattern.locomotion,
        ];
      case V2Goal.conditioning:
        return [
          V2MovementPattern.conditioning,
          V2MovementPattern.squat,
          V2MovementPattern.pushHorizontal,
        ];
      case V2Goal.mobility:
        return [
          V2MovementPattern.mobility,
          V2MovementPattern.squat,
          V2MovementPattern.hipHinge,
        ];
      case V2Goal.fatLoss:
        return [
          V2MovementPattern.squat,
          V2MovementPattern.hipHinge,
          V2MovementPattern.pushHorizontal,
          V2MovementPattern.conditioning,
        ];
      case V2Goal.generalFitness:
        return [
          V2MovementPattern.squat,
          V2MovementPattern.hipHinge,
          V2MovementPattern.pushHorizontal,
          V2MovementPattern.pullHorizontal,
          V2MovementPattern.coreAntiExtension,
          V2MovementPattern.balance,
        ];
      case V2Goal.rehabilitation:
        return [
          V2MovementPattern.mobility,
          V2MovementPattern.coreAntiExtension,
          V2MovementPattern.balance,
        ];
      case V2Goal.sportPerformance:
        return [
          V2MovementPattern.squat,
          V2MovementPattern.hipHinge,
          V2MovementPattern.pushHorizontal,
          V2MovementPattern.power,
        ];
    }
  }

  /// Prioridades de capacidade para o objetivo.
  List<V2Capacity> get prioritizedCapacities {
    switch (primaryGoal) {
      case V2Goal.hypertrophy:
      case V2Goal.strength:
        return [V2Capacity.stability, V2Capacity.technical, V2Capacity.coordination];
      case V2Goal.endurance:
        return [V2Capacity.endurance, V2Capacity.cardiovascular, V2Capacity.stability];
      case V2Goal.conditioning:
        return [V2Capacity.cardiovascular, V2Capacity.endurance, V2Capacity.coordination];
      case V2Goal.mobility:
        return [V2Capacity.mobility, V2Capacity.balance, V2Capacity.stability];
      case V2Goal.fatLoss:
        return [V2Capacity.cardiovascular, V2Capacity.endurance, V2Capacity.stability];
      case V2Goal.generalFitness:
        return [V2Capacity.stability, V2Capacity.mobility, V2Capacity.balance, V2Capacity.coordination];
      case V2Goal.rehabilitation:
        return [V2Capacity.mobility, V2Capacity.stability, V2Capacity.balance];
      case V2Goal.sportPerformance:
        return [V2Capacity.power, V2Capacity.coordination, V2Capacity.technical];
    }
  }
}
