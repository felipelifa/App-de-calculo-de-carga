import '../../exercise_library_v2/enums/goal.dart';
import '../../exercise_library_v2/enums/modality.dart';
import '../../exercise_library_v2/enums/environment.dart';
import '../../exercise_library_v2/enums/equipment.dart';
import '../../exercise_library_v2/enums/capacity.dart';
import '../../exercise_library_v2/enums/movement_pattern.dart';
import '../../exercise_library_v2/enums/difficulty.dart';
import '../../exercise_library_v2/enums/intensity.dart';
import 'user_training_profile.dart';

/// Contexto de treinamento derivado do perfil do usuário.
/// Transforma dados brutos em informações que o motor consiga utilizar.
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

  // ── Derived context properties ──

  bool get hasEquipment => availableEquipment.isNotEmpty &&
      !availableEquipment.contains(V2Equipment.none);

  bool get hasLimitations => limitations.isNotEmpty;

  bool get isHome => environment == V2Environment.home;
  bool get isGym => environment == V2Environment.gym;

  /// Sessão curta: menos de 30 minutos.
  bool get shortSession => sessionDurationMinutes < 30;

  /// Sessão longa: mais de 45 minutos.
  bool get longSession => sessionDurationMinutes > 45;

  /// Frequência baixa: 2 ou menos dias.
  bool get lowFrequency => availableDaysPerWeek <= 2;

  /// Frequência alta: 4 ou mais dias.
  bool get highFrequency => availableDaysPerWeek >= 4;

  /// Tolerância à complexidade baseada em idade + experiência.
  ComplexityTolerance get complexityTolerance {
    if (userDifficulty.index <= 1 && age > 50) return ComplexityTolerance.low;
    if (userDifficulty.index <= 1) return ComplexityTolerance.low;
    if (userDifficulty.index >= 3) return ComplexityTolerance.high;
    return ComplexityTolerance.moderate;
  }

  /// Capacidade de recuperação estimada (0.0–1.0).
  double get recoveryCapacity {
    double base = 1.0;
    if (age < 30) {
      base = 1.0;
    } else if (age < 40) {
      base = 0.9;
    } else if (age < 50) {
      base = 0.8;
    } else if (age < 60) {
      base = 0.7;
    } else {
      base = 0.6;
    }

    if (trainingAgeMonths > 24) {
      base = (base + 0.1).clamp(0.0, 1.0);
    } else if (trainingAgeMonths > 12) {
      base = (base + 0.05).clamp(0.0, 1.0);
    }

    if (hasLimitations) {
      base = (base - 0.1).clamp(0.0, 1.0);
    }

    return base;
  }

  /// Fator de redução de volume baseado em idade.
  double get ageVolumeFactor {
    if (age < 30) return 1.0;
    if (age < 40) return 0.95;
    if (age < 50) return 0.85;
    if (age < 60) return 0.75;
    return 0.65;
  }

  /// Fator de redução de intensidade baseado em idade.
  double get ageIntensityFactor {
    if (age < 30) return 1.0;
    if (age < 40) return 0.95;
    if (age < 50) return 0.9;
    if (age < 60) return 0.8;
    return 0.7;
  }

  /// Número máximo de exercícios baseado na duração.
  int get maxExercisesByDuration {
    if (sessionDurationMinutes <= 20) return 4;
    if (sessionDurationMinutes <= 30) return 5;
    if (sessionDurationMinutes <= 45) return 6;
    if (sessionDurationMinutes <= 60) return 7;
    return 8;
  }

  /// Estimativa de tempo por exercício (em segundos).
  int get timePerExerciseSeconds {
    // Execução (~45s) + descanso padrão (~90s) + transição (~30s)
    return 45 + 90 + 30;
  }

  /// Número máximo de exercícios que cabem no tempo disponível.
  int get maxExercisesByTime {
    return (sessionDurationMinutes * 60 / timePerExerciseSeconds).floor();
  }

  // ── Patterns necessários para o objetivo ──

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

  /// Compara demanda do exercício com capacidade do usuário.
  /// Retorna: compatible, needsAdaptation, incompatible.
  DemandComparison compareDemand({
    required V2Intensity exerciseStrength,
    required V2Intensity exerciseStability,
    required V2Intensity exerciseMobility,
    required V2Intensity exerciseBalance,
    required V2Intensity exerciseCoordination,
  }) {
    final issues = <String>[];

    if (_isDemandAboveCapacity(exerciseStrength, capacities.strength)) {
      issues.add('strength');
    }
    if (_isDemandAboveCapacity(exerciseStability, capacities.stability)) {
      issues.add('stability');
    }
    if (_isDemandAboveCapacity(exerciseMobility, capacities.mobility)) {
      issues.add('mobility');
    }
    if (_isDemandAboveCapacity(exerciseBalance, capacities.balance)) {
      issues.add('balance');
    }
    if (_isDemandAboveCapacity(exerciseCoordination, capacities.coordination)) {
      issues.add('coordination');
    }

    if (issues.isEmpty) {
      return const DemandComparison(
        status: DemandStatus.compatible,
        exceedingCapacities: [],
      );
    }

    if (issues.length <= 1) {
      return DemandComparison(
        status: DemandStatus.needsAdaptation,
        exceedingCapacities: issues,
      );
    }

    return DemandComparison(
      status: DemandStatus.incompatible,
      exceedingCapacities: issues,
    );
  }

  bool _isDemandAboveCapacity(V2Intensity demand, V2Intensity capacity) {
    // Se a demanda é 2+ níveis acima da capacidade, é problema
    return demand.index > capacity.index + 1;
  }
}

/// Tolerância à complexidade.
enum ComplexityTolerance {
  low,
  moderate,
  high,
}

/// Resultado da comparação demanda × capacidade.
class DemandComparison {
  final DemandStatus status;
  final List<String> exceedingCapacities;

  const DemandComparison({
    required this.status,
    required this.exceedingCapacities,
  });

  bool get isCompatible => status == DemandStatus.compatible;
  bool get needsAdaptation => status == DemandStatus.needsAdaptation;
  bool get isIncompatible => status == DemandStatus.incompatible;
}

enum DemandStatus {
  compatible,
  needsAdaptation,
  incompatible,
}
