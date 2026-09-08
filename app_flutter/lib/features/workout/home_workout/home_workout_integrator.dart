// ─────────────────────────────────────────────
// Integrador do Motor de Casa com o Sistema Principal
// ─────────────────────────────────────────────

import 'package:flutter/foundation.dart';

import '../workout_profile_model.dart';
import '../prescribed_workout_model.dart';
import '../../exercises/exercise_model.dart';
import '../../exercise_library_v2/queries/relationship_resolver.dart';
import '../../exercise_library_v2/models/v2_exercise.dart';
import 'home_workout_engine.dart';
import 'home_exercise_model.dart';
import 'limitation_analyzer.dart';
import '../exercise_compatibility.dart';
import 'v2_home_source.dart';

class HomeWorkoutIntegrator {
  final HomeWorkoutEngine _engine;

  HomeWorkoutIntegrator({String? userId})
    : _engine = HomeWorkoutEngine(userId: userId);

  /// Gera um treino para casa sem equipamento.
  ///
  /// Prioriza V2 Home quando disponível. Fallback para V1.
  GeneratedWorkout generateHomeWorkout(WorkoutProfile profile) {
    if (V2HomeSource.isAvailable) {
      debugPrint('V2_HOME: tentando gerar treino a partir da biblioteca V2...');
      try {
        final workout = _generateFromV2(profile);
        debugPrint('V2_HOME: treino gerado com sucesso via V2.');
        return workout;
      } catch (e) {
        debugPrint('V2_HOME: falha na geração V2 ($e) — usando fallback V1.');
      }
    } else {
      debugPrint('V2_HOME: indisponível — usando motor V1.');
    }

    debugPrint('V1_HOME: gerando treino via motor V1 legado.');
    return _generateFromV1(profile);
  }

  /// Gera treino a partir da V2ExerciseLibrary.
  /// Usa V2EngineRules para prescrição, RelationshipResolver para diversidade.
  GeneratedWorkout _generateFromV2(WorkoutProfile profile) {
    final v2Exercises = V2HomeSource.queryHomeExercises(profile: profile);

    if (v2Exercises.isEmpty) {
      throw StateError(
        'V2_HOME_EMPTY: V2ExerciseLibrary retornou 0 exercícios Home '
        'compatíveis com o perfil.',
      );
    }

    final v2Map = <String, ExerciseModel>{};
    for (final ex in v2Exercises) {
      v2Map[ex.id] = ex;
    }

    final resolver = RelationshipResolver(
      v2Map.keys
          .map((id) => V2HomeSource.getV2ById(id))
          .whereType<V2Exercise>()
          .toList(),
    );

    final selectedExercises = _selectExercisesForSession(
      v2Exercises,
      profile,
      resolver,
    );

    if (selectedExercises.isEmpty) {
      throw StateError(
        'V2_HOME_NO_SELECTION: nenhum exercício V2 selecionado '
        'para a sessão.',
      );
    }

    final prescribed = selectedExercises.map((exercise) {
      final v2 = V2HomeSource.getV2ById(exercise.id);
      final engineRules = v2?.engineRules;

      return PrescribedExercise(
        exercise: exercise,
        sets: _calculateSets(profile),
        repsMin: engineRules?.repRangeMin ?? exercise.repRangeMin,
        repsMax: engineRules?.repRangeMax ?? exercise.repRangeMax,
        rir: _calculateV2Rir(profile),
        restSeconds: engineRules?.defaultRestSeconds ?? _calculateRest(exercise, profile),
        sessionCues: exercise.cues,
        progressionNote: _generateV2ProgressionNote(exercise, profile, resolver),
        tempo: _tempo(profile),
        decisionReason: 'V2_HOME: selecionado via V2ExerciseLibrary.',
      );
    }).toList();

    final sessionCount = profile.availableDaysPerWeek.clamp(2, 7);
    final sessions = _generateVariedSessions(
      prescribed,
      sessionCount,
      profile,
    );

    return GeneratedWorkout(
      id: 'home_v2_workout_${DateTime.now().millisecondsSinceEpoch}',
      userId: profile.uid,
      splitType: 'home_bodyweight',
      periodizationModel: 'functional_patterns',
      sessions: sessions,
      mesocycleDurationWeeks: 4,
      generatedAt: DateTime.now(),
      planExplanation:
          'Plano de treino em casa (V2) sem equipamento, '
          'baseado em ${v2Exercises.length} exercícios da biblioteca V2. '
          'Duração estimada: ${profile.sessionDurationMinutes} minutos.',
    );
  }

  /// Gera treino a partir do motor V1 legado.
  GeneratedWorkout _generateFromV1(WorkoutProfile profile) {
    final limitations = _convertLimitations(profile);
    final capabilities = _calculateCapabilities(profile);

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

  /// Seleciona exercícios para a sessão, evitando redundância via RelationshipResolver.
  List<ExerciseModel> _selectExercisesForSession(
    List<ExerciseModel> allExercises,
    WorkoutProfile profile,
    RelationshipResolver resolver,
  ) {
    final byPattern = <String, List<ExerciseModel>>{};
    for (final ex in allExercises) {
      byPattern.putIfAbsent(ex.movementPattern, () => []).add(ex);
    }

    final maxExercises = _maxExercisesForDuration(profile.sessionDurationMinutes);
    final selected = <ExerciseModel>[];
    final selectedIds = <String>{};
    final patterns = byPattern.keys.toList()..shuffle();

    for (final pattern in patterns) {
      if (selected.length >= maxExercises) break;
      final candidates = byPattern[pattern]!;
      final best = _selectBestForLevel(candidates, profile);
      if (best == null) continue;

      bool conflicts = false;
      for (final existing in selected) {
        if (resolver.wouldConflict(existing.id, best.id)) {
          conflicts = true;
          break;
        }
      }
      if (conflicts) continue;

      selected.add(best);
      selectedIds.add(best.id);
    }

    return selected;
  }

  /// Seleciona o melhor exercício para o nível do usuário.
  ExerciseModel? _selectBestForLevel(
    List<ExerciseModel> candidates,
    WorkoutProfile profile,
  ) {
    if (candidates.isEmpty) return null;

    int difficultyScore(String d) {
      switch (d) {
        case 'beginner':
          return 1;
        case 'intermediate':
          return 2;
        case 'advanced':
          return 3;
        default:
          return 1;
      }
    }

    int targetDifficulty(String level) {
      switch (level) {
        case 'beginner':
          return 1;
        case 'intermediate':
          return 2;
        case 'advanced':
          return 3;
        default:
          return 1;
      }
    }

    final target = targetDifficulty(profile.experienceLevel);

    final sorted = List<ExerciseModel>.from(candidates)
      ..sort((a, b) {
        final diffA = (difficultyScore(a.difficulty) - target).abs();
        final diffB = (difficultyScore(b.difficulty) - target).abs();
        return diffA.compareTo(diffB);
      });

    return sorted.first;
  }

  /// Gera sessões com variação entre dias.
  ///
  /// Em vez de clonar a mesma sessão N vezes, rotaciona a ênfase
  /// de padrões de movimento e reordena os exercícios.
  List<PrescribedSession> _generateVariedSessions(
    List<PrescribedExercise> basePrescribed,
    int sessionCount,
    WorkoutProfile profile,
  ) {
    final sessions = <PrescribedSession>[];

    for (var i = 0; i < sessionCount; i++) {
      final varied = _varySession(basePrescribed, i, sessionCount);
      sessions.add(PrescribedSession(
        id: 'home_v2_session_${i + 1}',
        name: i == 0
            ? 'Treino em Casa — V2'
            : 'Treino em Casa — V2 — Sessão ${i + 1}',
        objective: 'Treino funcional baseado em padrões de movimento (V2)',
        estimatedDurationMinutes: profile.sessionDurationMinutes,
        warmupInstructions: [
          '5 minutos de mobilidade articular',
          'Marcha no lugar por 2 minutos',
          'Ativação de core: prancha leve por 30 segundos',
        ],
        exercises: varied,
        progressionNote:
            'Treino baseado em padrões de movimento (V2). '
            'Progrida conforme dominar cada exercício.',
      ));
    }

    return sessions;
  }

  /// Varia uma sessão base: rotaciona ordem e alterna repetições.
  List<PrescribedExercise> _varySession(
    List<PrescribedExercise> base,
    int dayIndex,
    int totalDays,
  ) {
    if (dayIndex == 0) return List.from(base);

    final shifted = <PrescribedExercise>[];
    final rotation = dayIndex % base.length;

    for (var i = 0; i < base.length; i++) {
      final srcIdx = (i + rotation) % base.length;
      final src = base[srcIdx];

      final repsAdjust = (dayIndex % 2 == 0) ? 1 : -1;
      final newMin = (src.repsMin + repsAdjust).clamp(5, 20);
      final newMax = (src.repsMax + repsAdjust).clamp(6, 25);
      final adjustedMax = newMax < newMin ? newMin + 2 : newMax;

      shifted.add(PrescribedExercise(
        exercise: src.exercise,
        sets: src.sets,
        repsMin: newMin,
        repsMax: adjustedMax,
        rir: src.rir,
        restSeconds: src.restSeconds,
        tempo: src.tempo,
        sessionCues: src.sessionCues,
        progressionNote: src.progressionNote,
        injuryNote: src.injuryNote,
        defaultWeightKg: src.defaultWeightKg,
        decisionReason: src.decisionReason,
        selectionScore: src.selectionScore,
      ));
    }

    return shifted;
  }

  int _maxExercisesForDuration(int minutes) {
    if (minutes <= 20) return 4;
    if (minutes <= 30) return 5;
    if (minutes <= 45) return 6;
    if (minutes <= 60) return 7;
    return 8;
  }

  int _calculateSets(WorkoutProfile profile) {
    switch (profile.experienceLevel) {
      case 'beginner':
        return 2;
      case 'intermediate':
        return 3;
      case 'advanced':
        return 4;
      default:
        return 3;
    }
  }

  int _calculateV2Rir(WorkoutProfile profile) {
    switch (profile.experienceLevel) {
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

  int _calculateRest(ExerciseModel exercise, WorkoutProfile profile) {
    if (exercise.category == 'compound') return 90;
    return 60;
  }

  String _tempo(WorkoutProfile profile) {
    switch (profile.experienceLevel) {
      case 'beginner':
        return '3-1-3';
      case 'intermediate':
        return '2-0-2';
      case 'advanced':
        return '2-1-2';
      default:
        return '2-0-2';
    }
  }

  /// Gera nota de progressão usando RelationshipResolver.
  String _generateV2ProgressionNote(
    ExerciseModel exercise,
    WorkoutProfile profile,
    RelationshipResolver resolver,
  ) {
    final progressionChain = resolver.getProgressionChain(exercise.id);
    if (progressionChain.length > 1) {
      final next = progressionChain[1];
      return 'Para progressão: ${next.name} (${next.id}).';
    }

    final regressionChain = resolver.getRegressionChain(exercise.id);
    if (regressionChain.length > 1) {
      final prev = regressionChain[1];
      return 'Para regressão: ${prev.name} (${prev.id}).';
    }

    final substitutes = resolver.getRelated(
      exercise.id,
    );
    if (substitutes.isNotEmpty) {
      final names = substitutes.take(2).map((s) => s.name).join(', ');
      return 'Alternativas: $names.';
    }

    return 'Exercício V2. Progrida conforme dominar.';
  }

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

  List<HomeExercise> getExercisesByPattern(
    HomeMovementPattern pattern, {
    List<String> availableEquipment = const [],
  }) {
    return _engine.getExercisesByPattern(
      pattern,
      availableEquipment: availableEquipment,
    );
  }

  HomeExercise? getExerciseById(String id) {
    return _engine.getExerciseById(id);
  }

  ExerciseModel? getExerciseModelById(String id) {
    final v2Result = V2HomeSource.getById(id);
    if (v2Result != null) return v2Result;

    final exercise = _engine.getExerciseById(id);
    return exercise == null ? null : _convertToExerciseModel(exercise);
  }

  HomeExercise? getRegression(String exerciseId) {
    final exercise = _engine.getExerciseById(exerciseId);
    if (exercise == null) return null;
    return _engine.getRegression(exercise);
  }

  HomeExercise? getProgression(String exerciseId) {
    final exercise = _engine.getExerciseById(exerciseId);
    if (exercise == null) return null;
    return _engine.getProgression(exercise);
  }

  List<HomeExercise> getAlternatives(String exerciseId) {
    final exercise = _engine.getExerciseById(exerciseId);
    if (exercise == null) return [];
    return _engine.getAlternatives(exercise);
  }

  // ── Métodos Privados V1 ──────────────────────────────────────────

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

  Map<String, double> _calculateCapabilities(WorkoutProfile profile) {
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

    final ageFactor = _ageFactor(profile.age);
    baseStrength *= ageFactor;
    baseBalance *= ageFactor;
    baseMobility *= ageFactor;

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

  double _ageFactor(int age) {
    if (age < 30) return 1.0;
    if (age < 40) return 0.9;
    if (age < 50) return 0.8;
    if (age < 60) return 0.7;
    if (age < 70) return 0.6;
    return 0.5;
  }

  double _restrictionFactor(List<String> restrictions) {
    if (restrictions.isEmpty) return 1.0;
    if (restrictions.length == 1) return 0.8;
    if (restrictions.length == 2) return 0.6;
    return 0.5;
  }

  GeneratedWorkout _convertToGeneratedWorkout(
    HomeWorkout homeWorkout,
    WorkoutProfile profile,
  ) {
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

  ExerciseModel _convertToExerciseModel(HomeExercise homeExercise) {
    return ExerciseModel(
      id: homeExercise.id,
      name: homeExercise.name,
      nameEn: homeExercise.nameEn,
      primaryMuscles: homeExercise.primaryMuscles,
      secondaryMuscles: homeExercise.secondaryMuscles,
      movementPattern: homeExercise.pattern.name,
      equipment: const [],
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
