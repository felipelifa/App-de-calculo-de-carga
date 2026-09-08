import '../../exercise_library_v2/enums/goal.dart';
import '../../exercise_library_v2/enums/capacity.dart';
import '../../exercise_library_v2/enums/intensity.dart';
import '../../exercise_library_v2/enums/movement_pattern.dart';
import 'training_context.dart';

/// Estratégia de treinamento determinada pelo motor.
/// Responde: "O que esse usuário precisa que o treino faça?"
class TrainingStrategy {
  final V2Goal primaryGoal;
  final List<V2Goal> secondaryGoals;

  // ── Prioridades ──
  final V2GoalPriority goalPriority;
  final List<V2Capacity> prioritizedCapacities;

  // ── Padrões necessários ──
  final List<V2MovementPattern> requiredPatterns;

  // ── Distribuição de estímulos ──
  final StimulusDistribution stimulusDistribution;

  // ── Volume e Intensidade ──
  final VolumeTarget volumeTarget;
  final IntensityTarget intensityTarget;

  // ── Estrutura da sessão ──
  final SessionStructure sessionStructure;

  // ── Necessidades ──
  final bool needsPreparation;
  final bool needsConditioning;
  final bool needsCore;
  final bool needsFinisher;
  final bool needsMobility;
  final bool needsBalance;

  // ── Complexity ──
  final ComplexityLevel complexityLevel;

  const TrainingStrategy({
    required this.primaryGoal,
    this.secondaryGoals = const [],
    required this.goalPriority,
    required this.prioritizedCapacities,
    required this.requiredPatterns,
    required this.stimulusDistribution,
    required this.volumeTarget,
    required this.intensityTarget,
    required this.sessionStructure,
    this.needsPreparation = true,
    this.needsConditioning = false,
    this.needsCore = true,
    this.needsFinisher = false,
    this.needsMobility = false,
    this.needsBalance = false,
    required this.complexityLevel,
  });
}

/// Determina a estratégia de treinamento a partir do contexto.
class TrainingStrategyEngine {
  const TrainingStrategyEngine();

  TrainingStrategy determine(TrainingContext context) {
    final goalPriority = _determineGoalPriority(context);
    final requiredPatterns = context.requiredPatterns;
    final prioritizedCapacities = context.prioritizedCapacities;
    final stimulusDistribution = _determineStimulusDistribution(context);
    final volumeTarget = _determineVolumeTarget(context);
    final intensityTarget = _determineIntensityTarget(context);
    final sessionStructure = _determineSessionStructure(context);
    final complexityLevel = _determineComplexityLevel(context);

    return TrainingStrategy(
      primaryGoal: context.primaryGoal,
      secondaryGoals: context.secondaryGoals,
      goalPriority: goalPriority,
      prioritizedCapacities: prioritizedCapacities,
      requiredPatterns: requiredPatterns,
      stimulusDistribution: stimulusDistribution,
      volumeTarget: volumeTarget,
      intensityTarget: intensityTarget,
      sessionStructure: sessionStructure,
      needsPreparation: _needsPreparation(context),
      needsConditioning: _needsConditioning(context),
      needsCore: _needsCore(context),
      needsFinisher: _needsFinisher(context),
      needsMobility: _needsMobility(context),
      needsBalance: _needsBalance(context),
      complexityLevel: complexityLevel,
    );
  }

  // ── Goal Priority ──

  V2GoalPriority _determineGoalPriority(TrainingContext context) {
    switch (context.primaryGoal) {
      case V2Goal.hypertrophy:
        return const V2GoalPriority(
          primary: V2Goal.hypertrophy,
          weights: {V2Goal.hypertrophy: 1.0, V2Goal.strength: 0.6, V2Goal.generalFitness: 0.3},
        );
      case V2Goal.strength:
        return const V2GoalPriority(
          primary: V2Goal.strength,
          weights: {V2Goal.strength: 1.0, V2Goal.hypertrophy: 0.5, V2Goal.generalFitness: 0.2},
        );
      case V2Goal.endurance:
        return const V2GoalPriority(
          primary: V2Goal.endurance,
          weights: {V2Goal.endurance: 1.0, V2Goal.conditioning: 0.7, V2Goal.generalFitness: 0.3},
        );
      case V2Goal.conditioning:
        return const V2GoalPriority(
          primary: V2Goal.conditioning,
          weights: {V2Goal.conditioning: 1.0, V2Goal.fatLoss: 0.6, V2Goal.generalFitness: 0.3},
        );
      case V2Goal.mobility:
        return const V2GoalPriority(
          primary: V2Goal.mobility,
          weights: {V2Goal.mobility: 1.0, V2Goal.generalFitness: 0.4},
        );
      case V2Goal.fatLoss:
        return const V2GoalPriority(
          primary: V2Goal.fatLoss,
          weights: {V2Goal.fatLoss: 1.0, V2Goal.conditioning: 0.7, V2Goal.generalFitness: 0.3},
        );
      case V2Goal.generalFitness:
        return const V2GoalPriority(
          primary: V2Goal.generalFitness,
          weights: {V2Goal.generalFitness: 1.0, V2Goal.strength: 0.5, V2Goal.conditioning: 0.4, V2Goal.mobility: 0.3},
        );
      case V2Goal.rehabilitation:
        return const V2GoalPriority(
          primary: V2Goal.rehabilitation,
          weights: {V2Goal.rehabilitation: 1.0, V2Goal.mobility: 0.8, V2Goal.generalFitness: 0.5},
        );
      case V2Goal.sportPerformance:
        return V2GoalPriority(
          primary: V2Goal.sportPerformance,
          weights: {V2Goal.sportPerformance: 1.0, V2Goal.strength: 0.7, V2Goal.generalFitness: 0.4},
        );
    }
  }

  // ── Stimulus Distribution ──

  StimulusDistribution _determineStimulusDistribution(TrainingContext context) {
    switch (context.primaryGoal) {
      case V2Goal.hypertrophy:
        return const StimulusDistribution(
          mechanicalTension: V2Intensity.high,
          muscularEndurance: V2Intensity.moderate,
          stability: V2Intensity.moderate,
          coordination: V2Intensity.low,
          mobility: V2Intensity.low,
          balance: V2Intensity.none,
          power: V2Intensity.none,
          cardiorespiratory: V2Intensity.low,
        );
      case V2Goal.strength:
        return const StimulusDistribution(
          mechanicalTension: V2Intensity.high,
          muscularEndurance: V2Intensity.low,
          stability: V2Intensity.moderate,
          coordination: V2Intensity.moderate,
          mobility: V2Intensity.low,
          balance: V2Intensity.low,
          power: V2Intensity.moderate,
          cardiorespiratory: V2Intensity.none,
        );
      case V2Goal.endurance:
        return const StimulusDistribution(
          mechanicalTension: V2Intensity.moderate,
          muscularEndurance: V2Intensity.high,
          stability: V2Intensity.moderate,
          coordination: V2Intensity.low,
          mobility: V2Intensity.low,
          balance: V2Intensity.none,
          power: V2Intensity.none,
          cardiorespiratory: V2Intensity.moderate,
        );
      case V2Goal.conditioning:
        return const StimulusDistribution(
          mechanicalTension: V2Intensity.low,
          muscularEndurance: V2Intensity.moderate,
          stability: V2Intensity.low,
          coordination: V2Intensity.moderate,
          mobility: V2Intensity.low,
          balance: V2Intensity.none,
          power: V2Intensity.moderate,
          cardiorespiratory: V2Intensity.high,
        );
      case V2Goal.mobility:
        return const StimulusDistribution(
          mechanicalTension: V2Intensity.none,
          muscularEndurance: V2Intensity.none,
          stability: V2Intensity.low,
          coordination: V2Intensity.low,
          mobility: V2Intensity.high,
          balance: V2Intensity.moderate,
          power: V2Intensity.none,
          cardiorespiratory: V2Intensity.none,
        );
      case V2Goal.fatLoss:
        return const StimulusDistribution(
          mechanicalTension: V2Intensity.moderate,
          muscularEndurance: V2Intensity.moderate,
          stability: V2Intensity.low,
          coordination: V2Intensity.low,
          mobility: V2Intensity.low,
          balance: V2Intensity.none,
          power: V2Intensity.moderate,
          cardiorespiratory: V2Intensity.high,
        );
      case V2Goal.generalFitness:
        return const StimulusDistribution(
          mechanicalTension: V2Intensity.moderate,
          muscularEndurance: V2Intensity.moderate,
          stability: V2Intensity.moderate,
          coordination: V2Intensity.moderate,
          mobility: V2Intensity.moderate,
          balance: V2Intensity.moderate,
          power: V2Intensity.low,
          cardiorespiratory: V2Intensity.moderate,
        );
      case V2Goal.rehabilitation:
        return const StimulusDistribution(
          mechanicalTension: V2Intensity.low,
          muscularEndurance: V2Intensity.low,
          stability: V2Intensity.moderate,
          coordination: V2Intensity.moderate,
          mobility: V2Intensity.high,
          balance: V2Intensity.moderate,
          power: V2Intensity.none,
          cardiorespiratory: V2Intensity.none,
        );
      case V2Goal.sportPerformance:
        return const StimulusDistribution(
          mechanicalTension: V2Intensity.moderate,
          muscularEndurance: V2Intensity.low,
          stability: V2Intensity.moderate,
          coordination: V2Intensity.high,
          mobility: V2Intensity.moderate,
          balance: V2Intensity.moderate,
          power: V2Intensity.high,
          cardiorespiratory: V2Intensity.moderate,
        );
    }
  }

  // ── Volume Target ──

  VolumeTarget _determineVolumeTarget(TrainingContext context) {
    int maxExercises;
    int setsPerExercise;

    // Baseado na duração
    if (context.sessionDurationMinutes <= 20) {
      maxExercises = 4;
      setsPerExercise = 2;
    } else if (context.sessionDurationMinutes <= 30) {
      maxExercises = 5;
      setsPerExercise = 2;
    } else if (context.sessionDurationMinutes <= 45) {
      maxExercises = 6;
      setsPerExercise = 3;
    } else if (context.sessionDurationMinutes <= 60) {
      maxExercises = 7;
      setsPerExercise = 3;
    } else {
      maxExercises = 8;
      setsPerExercise = 4;
    }

    // Ajuste por objetivo
    if (context.primaryGoal == V2Goal.hypertrophy) {
      setsPerExercise = (setsPerExercise + 1).clamp(2, 4);
    } else if (context.primaryGoal == V2Goal.strength) {
      setsPerExercise = (setsPerExercise + 1).clamp(3, 5);
      maxExercises = (maxExercises - 1).clamp(3, 8);
    } else if (context.primaryGoal == V2Goal.conditioning) {
      maxExercises = (maxExercises + 1).clamp(4, 8);
      setsPerExercise = 2;
    } else if (context.primaryGoal == V2Goal.mobility) {
      maxExercises = (maxExercises + 1).clamp(4, 8);
      setsPerExercise = 2;
    }

    // Ajuste por nível
    if (context.userDifficulty.index <= 1) {
      setsPerExercise = (setsPerExercise - 1).clamp(2, 4);
      maxExercises = (maxExercises - 1).clamp(3, 8);
    }

    return VolumeTarget(
      maxExercises: maxExercises,
      setsPerExercise: setsPerExercise,
    );
  }

  // ── Intensity Target ──

  IntensityTarget _determineIntensityTarget(TrainingContext context) {
    int rir;
    int restSeconds;

    switch (context.primaryGoal) {
      case V2Goal.hypertrophy:
        rir = 2;
        restSeconds = 90;
        break;
      case V2Goal.strength:
        rir = 1;
        restSeconds = 150;
        break;
      case V2Goal.endurance:
        rir = 1;
        restSeconds = 45;
        break;
      case V2Goal.conditioning:
        rir = 2;
        restSeconds = 60;
        break;
      case V2Goal.mobility:
        rir = 3;
        restSeconds = 30;
        break;
      case V2Goal.fatLoss:
        rir = 2;
        restSeconds = 60;
        break;
      case V2Goal.generalFitness:
        rir = 2;
        restSeconds = 90;
        break;
      case V2Goal.rehabilitation:
        rir = 3;
        restSeconds = 60;
        break;
      case V2Goal.sportPerformance:
        rir = 2;
        restSeconds = 120;
        break;
    }

    // Ajuste por nível
    if (context.userDifficulty.index <= 1) {
      rir = (rir + 1).clamp(1, 3);
      restSeconds = (restSeconds + 30);
    } else if (context.userDifficulty.index >= 3) {
      rir = (rir - 1).clamp(1, 3);
    }

    return IntensityTarget(
      targetRir: rir,
      defaultRestSeconds: restSeconds,
    );
  }

  // ── Session Structure ──

  SessionStructure _determineSessionStructure(TrainingContext context) {
    switch (context.primaryGoal) {
      case V2Goal.mobility:
        return SessionStructure(
          phases: [
            SessionPhase.preparation,
            SessionPhase.main,
            SessionPhase.coolDown,
          ],
          description: 'Mobilidade: preparação → mobilidade principal → relaxamento',
        );
      case V2Goal.conditioning:
        return SessionStructure(
          phases: [
            SessionPhase.preparation,
            SessionPhase.main,
            SessionPhase.conditioning,
          ],
          description: 'Condicionamento: preparação → circuito principal → condicionamento',
        );
      case V2Goal.generalFitness:
        return SessionStructure(
          phases: [
            SessionPhase.preparation,
            SessionPhase.main,
            SessionPhase.accessory,
            SessionPhase.core,
          ],
          description: 'Geral: preparação → principal → acessório → core',
        );
      default:
        return SessionStructure(
          phases: [
            SessionPhase.preparation,
            SessionPhase.main,
            SessionPhase.accessory,
            SessionPhase.core,
          ],
          description: 'Padrão: preparação → principal → acessório → core',
        );
    }
  }

  // ── Needs ──

  bool _needsPreparation(TrainingContext context) => true;

  bool _needsConditioning(TrainingContext context) =>
      context.primaryGoal == V2Goal.conditioning ||
      context.primaryGoal == V2Goal.fatLoss;

  bool _needsCore(TrainingContext context) =>
      context.primaryGoal != V2Goal.conditioning;

  bool _needsFinisher(TrainingContext context) =>
      context.primaryGoal == V2Goal.hypertrophy ||
      context.primaryGoal == V2Goal.fatLoss;

  bool _needsMobility(TrainingContext context) =>
      context.primaryGoal == V2Goal.mobility ||
      context.primaryGoal == V2Goal.rehabilitation ||
      context.limitations.isNotEmpty;

  bool _needsBalance(TrainingContext context) =>
      context.primaryGoal == V2Goal.generalFitness ||
      context.primaryGoal == V2Goal.rehabilitation ||
      context.limitations.isNotEmpty;

  // ── Complexity ──

  ComplexityLevel _determineComplexityLevel(TrainingContext context) {
    if (context.userDifficulty.index <= 1) return ComplexityLevel.simple;
    if (context.userDifficulty.index <= 2) return ComplexityLevel.moderate;
    if (context.userDifficulty.index <= 3) return ComplexityLevel.complex;
    return ComplexityLevel.advanced;
  }
}

// ── Supporting types ──

class V2GoalPriority {
  final V2Goal primary;
  final Map<V2Goal, double> weights;

  const V2GoalPriority({required this.primary, this.weights = const {}});

  double score(V2Goal goal) => weights[goal] ?? 0.0;
}

class StimulusDistribution {
  final V2Intensity mechanicalTension;
  final V2Intensity muscularEndurance;
  final V2Intensity stability;
  final V2Intensity coordination;
  final V2Intensity mobility;
  final V2Intensity balance;
  final V2Intensity power;
  final V2Intensity cardiorespiratory;

  const StimulusDistribution({
    required this.mechanicalTension,
    required this.muscularEndurance,
    required this.stability,
    required this.coordination,
    required this.mobility,
    required this.balance,
    required this.power,
    required this.cardiorespiratory,
  });
}

class VolumeTarget {
  final int maxExercises;
  final int setsPerExercise;

  const VolumeTarget({required this.maxExercises, required this.setsPerExercise});
}

class IntensityTarget {
  final int targetRir;
  final int defaultRestSeconds;

  const IntensityTarget({required this.targetRir, required this.defaultRestSeconds});
}

class SessionStructure {
  final List<SessionPhase> phases;
  final String description;

  const SessionStructure({required this.phases, required this.description});
}

enum SessionPhase {
  preparation,
  main,
  accessory,
  core,
  conditioning,
  coolDown,
}

enum ComplexityLevel {
  simple,
  moderate,
  complex,
  advanced,
}
