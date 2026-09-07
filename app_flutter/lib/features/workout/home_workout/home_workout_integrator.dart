// ─────────────────────────────────────────────
// Integrador do Motor de Casa com o Sistema Principal
// ─────────────────────────────────────────────

import '../workout_profile_model.dart';
import '../prescribed_workout_model.dart';
import '../../exercises/exercise_model.dart';
import 'home_workout_engine.dart';
import 'home_exercise_model.dart';
import 'limitation_analyzer.dart';
import '../exercise_compatibility.dart';

class HomeWorkoutIntegrator {
  final HomeWorkoutEngine _engine;

  HomeWorkoutIntegrator({String? userId})
    : _engine = HomeWorkoutEngine(userId: userId);

  // Gera um treino para casa sem equipamento
  GeneratedWorkout generateHomeWorkout(WorkoutProfile profile) {
    // Converte limitações do perfil para o formato do motor de casa
    final limitations = _convertLimitations(profile);

    // Calcula capacidades baseadas no perfil
    final capabilities = _calculateCapabilities(profile);

    // Gera o treino
    final homeWorkout = _engine.generateWorkout(
      userId: profile.uid,
      availableMinutes: profile.sessionDurationMinutes,
      limitations: limitations,
      experienceLevel: profile.experienceLevel,
      balanceCapability: capabilities['balance']!,
      strengthCapability: capabilities['strength']!,
      mobilityCapability: capabilities['mobility']!,
      availableEquipment: profile.availableEquipment,
      dayOfWeek: DateTime.now().weekday,
    );

    if (homeWorkout.exercises.isEmpty) {
      throw StateError(
        'NO_COMPATIBLE_EXERCISES: nenhum exercício de casa atende ao ambiente, '
        'equipamentos e restrições informados.',
      );
    }

    // Converte para o formato do sistema principal
    final workout = _convertToGeneratedWorkout(homeWorkout, profile);
    final incompatible = workout.sessions
        .expand((session) => session.exercises)
        .where(
          (prescribed) =>
              !ExerciseCompatibility.isCompatible(profile, prescribed.exercise),
        )
        .toList();
    if (incompatible.isNotEmpty) {
      throw StateError(
        'NO_COMPATIBLE_EXERCISES: a validação final rejeitou exercícios '
        'incompatíveis com o perfil.',
      );
    }
    return workout;
  }

  // Analisa um exercício específico
  HomeExerciseAnalysis analyzeExercise({
    required String exerciseId,
    required WorkoutProfile profile,
  }) {
    final exercise = _engine.getExerciseById(exerciseId);
    if (exercise == null) {
      throw ArgumentError('Exercício não encontrado: $exerciseId');
    }

    final limitations = _convertLimitations(profile);
    final capabilities = _calculateCapabilities(profile);

    return _engine.analyzeExercise(
      exercise: exercise,
      limitations: limitations,
      experienceLevel: profile.experienceLevel,
      balanceCapability: capabilities['balance']!,
      strengthCapability: capabilities['strength']!,
      mobilityCapability: capabilities['mobility']!,
    );
  }

  // Processa feedback do usuário
  HomeFeedbackAnalysis processFeedback({
    required String exerciseId,
    required HomeFeedback feedback,
  }) {
    final exercise = _engine.getExerciseById(exerciseId);
    if (exercise == null) {
      throw ArgumentError('Exercício não encontrado: $exerciseId');
    }

    return _engine.processFeedback(feedback: feedback, exercise: exercise);
  }

  // Busca exercícios por padrão
  List<HomeExercise> getExercisesByPattern(
    HomeMovementPattern pattern, {
    List<String> availableEquipment = const [],
  }) {
    return _engine.getExercisesByPattern(
      pattern,
      availableEquipment: availableEquipment,
    );
  }

  // Busca exercício por ID
  HomeExercise? getExerciseById(String id) {
    return _engine.getExerciseById(id);
  }

  // Resolve exercícios de casa no mesmo formato usado pelos treinos salvos.
  ExerciseModel? getExerciseModelById(String id) {
    final exercise = _engine.getExerciseById(id);
    return exercise == null ? null : _convertToExerciseModel(exercise);
  }

  // Busca regressão de um exercício
  HomeExercise? getRegression(String exerciseId) {
    final exercise = _engine.getExerciseById(exerciseId);
    if (exercise == null) return null;
    return _engine.getRegression(exercise);
  }

  // Busca progressão de um exercício
  HomeExercise? getProgression(String exerciseId) {
    final exercise = _engine.getExerciseById(exerciseId);
    if (exercise == null) return null;
    return _engine.getProgression(exercise);
  }

  // Busca alternativas de um exercício
  List<HomeExercise> getAlternatives(String exerciseId) {
    final exercise = _engine.getExerciseById(exerciseId);
    if (exercise == null) return [];
    return _engine.getAlternatives(exercise);
  }

  // ── Métodos Privados ──────────────────────────────────────────

  // Converte restrições de saúde para limitações do motor de casa
  List<HomeUserLimitation> _convertLimitations(WorkoutProfile profile) {
    final limitations = <HomeUserLimitation>[];

    for (final restriction in profile.healthRestrictions) {
      final region = _mapRestrictionToRegion(restriction);
      if (region != null) {
        limitations.add(
          HomeUserLimitation(
            region: region,
            description: restriction,
            severity: HomeLimitationSeverity.moderate,
          ),
        );
      }
    }

    return limitations;
  }

  // Mapeia restrição de saúde para região do corpo
  HomeBodyRegion? _mapRestrictionToRegion(String restriction) {
    final restrictionLower = restriction.toLowerCase();

    if (restrictionLower.contains('knee') ||
        restrictionLower.contains('joelho')) {
      return HomeBodyRegion.knee;
    }
    if (restrictionLower.contains('hip') ||
        restrictionLower.contains('quadril')) {
      return HomeBodyRegion.hip;
    }
    if (restrictionLower.contains('ankle') ||
        restrictionLower.contains('tornozelo')) {
      return HomeBodyRegion.ankle;
    }
    if (restrictionLower.contains('lower_back') ||
        restrictionLower.contains('lombar')) {
      return HomeBodyRegion.lowerBack;
    }
    if (restrictionLower.contains('shoulder') ||
        restrictionLower.contains('ombro')) {
      return HomeBodyRegion.shoulder;
    }
    if (restrictionLower.contains('elbow') ||
        restrictionLower.contains('cotovelo')) {
      return HomeBodyRegion.elbow;
    }
    if (restrictionLower.contains('wrist') ||
        restrictionLower.contains('punho')) {
      return HomeBodyRegion.wrist;
    }
    if (restrictionLower.contains('neck') ||
        restrictionLower.contains('cervical')) {
      return HomeBodyRegion.neck;
    }
    if (restrictionLower.contains('hamstring') ||
        restrictionLower.contains('posterior')) {
      return HomeBodyRegion.hamstring;
    }
    if (restrictionLower.contains('groin') ||
        restrictionLower.contains('virilha')) {
      return HomeBodyRegion.groin;
    }

    return null;
  }

  // Calcula capacidades baseadas no perfil
  Map<String, double> _calculateCapabilities(WorkoutProfile profile) {
    // Capacidade baseada no nível de experiência
    double baseStrength;
    double baseBalance;
    double baseMobility;

    switch (profile.experienceLevel) {
      case 'beginner':
        baseStrength = 0.3;
        baseBalance = 0.3;
        baseMobility = 0.4;
        break;
      case 'intermediate':
        baseStrength = 0.6;
        baseBalance = 0.5;
        baseMobility = 0.6;
        break;
      case 'advanced':
        baseStrength = 0.8;
        baseBalance = 0.7;
        baseMobility = 0.8;
        break;
      default:
        baseStrength = 0.5;
        baseBalance = 0.5;
        baseMobility = 0.5;
    }

    // Ajusta baseado na idade
    final ageFactor = _ageFactor(profile.age);
    baseStrength *= ageFactor;
    baseBalance *= ageFactor;
    baseMobility *= ageFactor;

    // Ajusta baseado em restrições de saúde
    final restrictionFactor = _restrictionFactor(profile.healthRestrictions);
    baseStrength *= restrictionFactor;
    baseBalance *= restrictionFactor;
    baseMobility *= restrictionFactor;

    return {
      'strength': baseStrength.clamp(0.0, 1.0),
      'balance': baseBalance.clamp(0.0, 1.0),
      'mobility': baseMobility.clamp(0.0, 1.0),
    };
  }

  // Fator de ajuste baseado na idade
  double _ageFactor(int age) {
    if (age < 30) return 1.0;
    if (age < 40) return 0.9;
    if (age < 50) return 0.8;
    if (age < 60) return 0.7;
    if (age < 70) return 0.6;
    return 0.5;
  }

  // Fator de ajuste baseado em restrições
  double _restrictionFactor(List<String> restrictions) {
    if (restrictions.isEmpty) return 1.0;
    if (restrictions.length == 1) return 0.8;
    if (restrictions.length == 2) return 0.6;
    return 0.5;
  }

  // Converte treino de casa para o formato do sistema principal
  GeneratedWorkout _convertToGeneratedWorkout(
    HomeWorkout homeWorkout,
    WorkoutProfile profile,
  ) {
    // Cria uma sessão principal
    final mainSession = PrescribedSession(
      id: 'home_session_main',
      name: 'Treino em Casa — Sem Equipamento',
      objective: 'Treino funcional baseado em padrões de movimento',
      estimatedDurationMinutes: homeWorkout.estimatedDurationMinutes,
      warmupInstructions: [
        '5 minutos de mobilidade articular',
        'Marcha no lugar por 2 minutos',
        'Ativação de core: prancha leve por 30 segundos',
      ],
      exercises: homeWorkout.exercises.map((e) {
        return PrescribedExercise(
          exercise: _convertToExerciseModel(e.exercise),
          sets: e.sets,
          repsMin: e.reps,
          repsMax: e.reps + 2,
          restSeconds: e.restSeconds,
          rir: _calculateRir(e.exercise, profile.experienceLevel),
          sessionCues: e.exercise.cues,
          progressionNote: _generateProgressionNote(e),
        );
      }).toList(),
      progressionNote:
          'Treino baseado em padrões de movimento. '
          'Progrida conforme dominar cada exercício.',
    );

    final sessionCount = profile.availableDaysPerWeek.clamp(2, 7);
    final sessions = List<PrescribedSession>.generate(
      sessionCount,
      (index) => index == 0
          ? mainSession
          : PrescribedSession(
              id: 'home_session_${index + 1}',
              name: 'Treino em Casa — Sessão ${index + 1}',
              objective: mainSession.objective,
              estimatedDurationMinutes: mainSession.estimatedDurationMinutes,
              warmupInstructions: mainSession.warmupInstructions,
              exercises: List<PrescribedExercise>.from(mainSession.exercises),
              progressionNote: mainSession.progressionNote,
            ),
    );

    return GeneratedWorkout(
      id: homeWorkout.id,
      userId: homeWorkout.userId,
      splitType: 'home_bodyweight',
      periodizationModel: 'functional_patterns',
      sessions: sessions,
      mesocycleDurationWeeks: 4,
      generatedAt: homeWorkout.generatedAt,
      planExplanation:
          'Plano de treino em casa sem equipamento, '
          'baseado em ${homeWorkout.patterns.length} padrões de movimento. '
          'Duração estimada: ${homeWorkout.estimatedDurationMinutes} minutos.',
    );
  }

  // Converte exercício de casa para o modelo principal
  ExerciseModel _convertToExerciseModel(HomeExercise homeExercise) {
    return ExerciseModel(
      id: homeExercise.id,
      name: homeExercise.name,
      nameEn: homeExercise.nameEn,
      primaryMuscles: homeExercise.primaryMuscles,
      secondaryMuscles: homeExercise.secondaryMuscles,
      movementPattern: homeExercise.pattern.name,
      equipment: const [], // Sem equipamento
      environment: const ['home'],
      category: homeExercise.strengthDemand > 0.6 ? 'compound' : 'isolation',
      difficulty: _mapDifficulty(homeExercise.difficulty),
      restrictions: const [],
      repRangeMin: 8,
      repRangeMax: 15,
      isUnilateral: homeExercise.isUnilateral,
      cues: homeExercise.cues,
      instructions: const [],
      substituteIds: homeExercise.alternativeIds,
      progressionIds: homeExercise.progressionId != null
          ? [homeExercise.progressionId!]
          : const [],
      regressionIds: homeExercise.regressionId != null
          ? [homeExercise.regressionId!]
          : const [],
      tags: [homeExercise.pattern.name, 'home', 'bodyweight'],
      spinalLoad: homeExercise.stabilityDemand,
      shoulderStress:
          homeExercise.demandRegions.contains(HomeBodyRegion.shoulder)
          ? 0.5
          : 0.0,
      kneeStress: homeExercise.demandRegions.contains(HomeBodyRegion.knee)
          ? 0.5
          : 0.0,
      cnsLoad: homeExercise.strengthDemand,
      stabilityType: homeExercise.stabilityDemand > 0.5
          ? 'anti_extension'
          : 'none',
      lengthBias: 'mid_range',
      skillLevel: homeExercise.difficulty.index + 1,
    );
  }

  // Mapeia dificuldade de casa para o modelo principal
  String _mapDifficulty(HomeDifficulty difficulty) {
    switch (difficulty) {
      case HomeDifficulty.level1:
      case HomeDifficulty.level2:
        return 'beginner';
      case HomeDifficulty.level3:
      case HomeDifficulty.level4:
        return 'intermediate';
      case HomeDifficulty.level5:
        return 'advanced';
    }
  }

  // Calcula RIR baseado no exercício e nível
  int _calculateRir(HomeExercise exercise, String experienceLevel) {
    switch (experienceLevel) {
      case 'beginner':
        return 3;
      case 'intermediate':
        return 2;
      case 'advanced':
        return 1;
      default:
        return 2;
    }
  }

  // Gera nota de progressão para o exercício
  String _generateProgressionNote(HomeWorkoutExercise workoutExercise) {
    final analysis = workoutExercise.analysis;

    if (analysis.compatibility == HomeCompatibility.compatible) {
      return 'Exercício compatível. Progrida conforme dominar.';
    }

    if (analysis.compatibility == HomeCompatibility.adaptable) {
      final adaptations = analysis.adaptations
          .map((a) => a.description)
          .join('; ');
      return 'Adaptações sugeridas: $adaptations';
    }

    return 'Exercício pode precisar de substituição.';
  }
}
