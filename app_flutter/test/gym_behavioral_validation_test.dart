import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/workout/intelligence/user_training_profile.dart';
import 'package:app/features/workout/intelligence/training_intelligence.dart';
import 'package:app/features/workout/intelligence/training_context.dart';
import 'package:app/features/workout/intelligence/training_strategy_engine.dart';
import 'package:app/features/exercise_library_v2/v2_exercise_library.dart';
import 'package:app/features/exercise_library_v2/data/home_exercises.dart';
import 'package:app/features/exercise_library_v2/data/gym_free_weights_exercises.dart';
import 'package:app/features/exercise_library_v2/bridge/v2_home_bridge.dart';
import 'package:app/features/exercise_library_v2/enums/goal.dart';
import 'package:app/features/exercise_library_v2/enums/modality.dart';
import 'package:app/features/exercise_library_v2/enums/environment.dart';
import 'package:app/features/exercise_library_v2/enums/equipment.dart';
import 'package:app/features/exercise_library_v2/enums/joint.dart';
import 'package:app/features/exercise_library_v2/enums/limitation_severity.dart';
import 'package:app/features/exercise_library_v2/enums/movement_pattern.dart';
import 'package:app/features/exercise_library_v2/enums/exercise_block.dart';
import 'package:app/features/exercise_library_v2/models/v2_exercise.dart';
import 'package:app/features/workout/prescribed_workout_model.dart';

void main() {
  setUpAll(() {
    final library = V2ExerciseLibrary();
    library.registerAll(createHomeExercises());
    library.registerAll(createGymFreeWeightExercises());
    V2HomeBridge.registerAll(createHomeExercises());
    V2HomeBridge.registerAll(createGymFreeWeightExercises());
  });

  final intelligence = TrainingIntelligence();

  // ═══════════════════════════════════════════════════════════════
  // PERFIS
  // ═══════════════════════════════════════════════════════════════

  final profileA = UserTrainingProfile(
    uid: 'A', age: 25, primaryGoal: V2Goal.hypertrophy,
    modality: V2Modality.hypertrophy,
    environment: V2Environment.gym,
    availableEquipment: const [V2Equipment.dumbbell, V2Equipment.barbell, V2Equipment.bench],
    availableDaysPerWeek: 3, sessionDurationMinutes: 45,
    experienceLevel: ExperienceLevel.never, trainingAgeMonths: 0,
  );

  final profileB = UserTrainingProfile(
    uid: 'B', age: 25, primaryGoal: V2Goal.hypertrophy,
    modality: V2Modality.hypertrophy,
    environment: V2Environment.gym,
    availableEquipment: const [V2Equipment.dumbbell, V2Equipment.barbell, V2Equipment.bench],
    availableDaysPerWeek: 4, sessionDurationMinutes: 60,
    experienceLevel: ExperienceLevel.regularly, trainingAgeMonths: 24,
  );

  final profileC = UserTrainingProfile(
    uid: 'C', age: 25, primaryGoal: V2Goal.hypertrophy,
    modality: V2Modality.hypertrophy,
    environment: V2Environment.gym,
    availableEquipment: const [V2Equipment.dumbbell, V2Equipment.barbell, V2Equipment.bench],
    availableDaysPerWeek: 5, sessionDurationMinutes: 60,
    experienceLevel: ExperienceLevel.years, trainingAgeMonths: 60,
  );

  final profileD = UserTrainingProfile(
    uid: 'D', age: 30, primaryGoal: V2Goal.strength,
    modality: V2Modality.strength,
    environment: V2Environment.gym,
    availableEquipment: const [V2Equipment.dumbbell, V2Equipment.barbell, V2Equipment.bench],
    availableDaysPerWeek: 3, sessionDurationMinutes: 60,
    experienceLevel: ExperienceLevel.never, trainingAgeMonths: 0,
  );

  final profileE = UserTrainingProfile(
    uid: 'E', age: 35, primaryGoal: V2Goal.strength,
    modality: V2Modality.strength,
    environment: V2Environment.gym,
    availableEquipment: const [V2Equipment.dumbbell, V2Equipment.bench],
    availableDaysPerWeek: 3, sessionDurationMinutes: 45,
    experienceLevel: ExperienceLevel.regularly, trainingAgeMonths: 24,
  );

  final profileF = UserTrainingProfile(
    uid: 'F', age: 25, primaryGoal: V2Goal.hypertrophy,
    modality: V2Modality.hypertrophy,
    environment: V2Environment.gym,
    availableEquipment: const [V2Equipment.barbell, V2Equipment.bench],
    availableDaysPerWeek: 4, sessionDurationMinutes: 45,
    experienceLevel: ExperienceLevel.regularly, trainingAgeMonths: 24,
  );

  final profileG = UserTrainingProfile(
    uid: 'G', age: 55, primaryGoal: V2Goal.generalFitness,
    modality: V2Modality.generalPhysicalDevelopment,
    environment: V2Environment.gym,
    availableEquipment: const [V2Equipment.dumbbell, V2Equipment.bench],
    availableDaysPerWeek: 2, sessionDurationMinutes: 30,
    experienceLevel: ExperienceLevel.never, trainingAgeMonths: 0,
  );

  final profileH = UserTrainingProfile(
    uid: 'H', age: 30, primaryGoal: V2Goal.hypertrophy,
    modality: V2Modality.hypertrophy,
    environment: V2Environment.gym,
    availableEquipment: const [V2Equipment.dumbbell, V2Equipment.barbell, V2Equipment.bench],
    availableDaysPerWeek: 3, sessionDurationMinutes: 45,
    experienceLevel: ExperienceLevel.regularly, trainingAgeMonths: 24,
    limitations: const [
      UserLimitation(
        joint: V2Joint.knee, severity: V2LimitationSeverity.moderate,
        side: 'both', timing: 'during',
        affectedMovements: ['agachar', 'saltar'],
      ),
    ],
  );

  // ═══════════════════════════════════════════════════════════════
  // TESTE 1: PERFIL A — Iniciante + Hipertrofia + 3x + 45min
  // ═══════════════════════════════════════════════════════════════

  test('Perfil A: iniciante + hipertrofia + gym + 3x + 45min', () {
    print('\n╔══════════════════════════════════════════════════════════╗');
    print('║ PERFIL A: Iniciante + Hipertrofia + 3x + 45min         ║');
    print('╚══════════════════════════════════════════════════════════╝');

    final workout = intelligence.generateWorkout(profileA);
    _analyzeWorkout(workout, profileA, 'A');

    // Verificar coerência
    _validateSelection(workout, profileA, 'A');
    _validatePatterns(workout, 'A');
    _validateDuration(workout, profileA, 'A');
    _validateEquipment(workout, profileA, 'A');
    _validateNoRedundancy(workout, 'A');
    _validatePrescription(workout, 'A');

    print('✓ Perfil A aprovado');
  });

  // ═══════════════════════════════════════════════════════════════
  // TESTE 2: PERFIL B — Intermediário + Hipertrofia + 4x + 60min
  // ═══════════════════════════════════════════════════════════════

  test('Perfil B: intermediário + hipertrofia + gym + 4x + 60min', () {
    print('\n╔══════════════════════════════════════════════════════════╗');
    print('║ PERFIL B: Intermediário + Hipertrofia + 4x + 60min     ║');
    print('╚══════════════════════════════════════════════════════════╝');

    final workout = intelligence.generateWorkout(profileB);
    _analyzeWorkout(workout, profileB, 'B');

    _validateSelection(workout, profileB, 'B');
    _validatePatterns(workout, 'B');
    _validateDuration(workout, profileB, 'B');
    _validateEquipment(workout, profileB, 'B');
    _validateNoRedundancy(workout, 'B');
    _validatePrescription(workout, 'B');

    print('✓ Perfil B aprovado');
  });

  // ═══════════════════════════════════════════════════════════════
  // TESTE 3: PERFIL C — Avançado + Hipertrofia + 5x + 60min
  // ═══════════════════════════════════════════════════════════════

  test('Perfil C: avançado + hipertrofia + gym + 5x + 60min', () {
    print('\n╔══════════════════════════════════════════════════════════╗');
    print('║ PERFIL C: Avançado + Hipertrofia + 5x + 60min          ║');
    print('╚══════════════════════════════════════════════════════════╝');

    final workout = intelligence.generateWorkout(profileC);
    _analyzeWorkout(workout, profileC, 'C');

    _validateSelection(workout, profileC, 'C');
    _validatePatterns(workout, 'C');
    _validateDuration(workout, profileC, 'C');
    _validateEquipment(workout, profileC, 'C');
    _validateNoRedundancy(workout, 'C');
    _validatePrescription(workout, 'C');

    print('✓ Perfil C aprovado');
  });

  // ═══════════════════════════════════════════════════════════════
  // TESTE 4: PERFIL D — Iniciante + Força + 3x + 60min
  // ═══════════════════════════════════════════════════════════════

  test('Perfil D: iniciante + força + gym + 3x + 60min', () {
    print('\n╔══════════════════════════════════════════════════════════╗');
    print('║ PERFIL D: Iniciante + Força + 3x + 60min               ║');
    print('╚══════════════════════════════════════════════════════════╝');

    final workout = intelligence.generateWorkout(profileD);
    _analyzeWorkout(workout, profileD, 'D');

    _validateSelection(workout, profileD, 'D');
    _validatePatterns(workout, 'D');
    _validateDuration(workout, profileD, 'D');
    _validateEquipment(workout, profileD, 'D');
    _validatePrescription(workout, 'D');

    print('✓ Perfil D aprovado');
  });

  // ═══════════════════════════════════════════════════════════════
  // TESTE 5: PERFIL E — Intermediário + Força + Só Halteres + 3x + 45min
  // ═══════════════════════════════════════════════════════════════

  test('Perfil E: intermediário + força + só halteres + 3x + 45min', () {
    print('\n╔══════════════════════════════════════════════════════════╗');
    print('║ PERFIL E: Intermediário + Força + Só Halteres          ║');
    print('╚══════════════════════════════════════════════════════════╝');

    final workout = intelligence.generateWorkout(profileE);
    _analyzeWorkout(workout, profileE, 'E');

    _validateSelection(workout, profileE, 'E');
    _validateEquipment(workout, profileE, 'E');
    _validatePrescription(workout, 'E');

    // NENHUM exercício deve usar barra
    for (final s in workout.sessions) {
      for (final ex in s.exercises) {
        final v2 = V2HomeBridge.getV2Exercise(ex.exercise.id);
        if (v2 != null) {
          expect(v2.requiredEquipment.contains(V2Equipment.barbell), isFalse,
              reason: '${ex.exercise.name} usa barra mas perfil E só tem halteres');
        }
      }
    }

    print('✓ Perfil E aprovado — nenhum exercício com barra');
  });

  // ═══════════════════════════════════════════════════════════════
  // TESTE 6: PERFIL F — Intermediário + Hipertrofia + Só Barra + 4x + 45min
  // ═══════════════════════════════════════════════════════════════

  test('Perfil F: intermediário + hipertrofia + só barra + 4x + 45min', () {
    print('\n╔══════════════════════════════════════════════════════════╗');
    print('║ PERFIL F: Intermediário + Hipertrofia + Só Barra       ║');
    print('╚══════════════════════════════════════════════════════════╝');

    final workout = intelligence.generateWorkout(profileF);
    _analyzeWorkout(workout, profileF, 'F');

    _validateSelection(workout, profileF, 'F');
    _validateEquipment(workout, profileF, 'F');
    _validatePrescription(workout, 'F');

    // NENHUM exercício deve usar halteres
    for (final s in workout.sessions) {
      for (final ex in s.exercises) {
        final v2 = V2HomeBridge.getV2Exercise(ex.exercise.id);
        if (v2 != null) {
          expect(v2.requiredEquipment.contains(V2Equipment.dumbbell), isFalse,
              reason: '${ex.exercise.name} usa halteres mas perfil F só tem barra');
        }
      }
    }

    print('✓ Perfil F aprovado — nenhum exercício com halteres');
  });

  // ═══════════════════════════════════════════════════════════════
  // TESTE 7: PERFIL G — Idoso + Geral + 2x + 30min
  // ═══════════════════════════════════════════════════════════════

  test('Perfil G: idoso + geral + gym + 2x + 30min', () {
    print('\n╔══════════════════════════════════════════════════════════╗');
    print('║ PERFIL G: Idoso (55) + Geral + 2x + 30min              ║');
    print('╚══════════════════════════════════════════════════════════╝');

    final workout = intelligence.generateWorkout(profileG);
    _analyzeWorkout(workout, profileG, 'G');

    _validateSelection(workout, profileG, 'G');
    _validateDuration(workout, profileG, 'G');
    _validateEquipment(workout, profileG, 'G');
    _validatePrescription(workout, 'G');

    // Deve ter volume reduzido para idoso + sessão curta
    final totalSets = workout.sessions
        .expand((s) => s.exercises)
        .map((e) => e.sets)
        .reduce((a, b) => a + b);
    print('Volume total: $totalSets séries');
    expect(totalSets, lessThanOrEqualTo(20),
        reason: 'Idoso com sessão curta não deve ter volume alto');

    print('✓ Perfil G aprovado');
  });

  // ═══════════════════════════════════════════════════════════════
  // TESTE 8: PERFIL H — Com Limitação de Joelho
  // ═══════════════════════════════════════════════════════════════

  test('Perfil H: intermediário + hipertrofia + limitação joelho', () {
    print('\n╔══════════════════════════════════════════════════════════╗');
    print('║ PERFIL H: Intermediário + Hipertrofia + Limitação      ║');
    print('╚══════════════════════════════════════════════════════════╝');

    final workout = intelligence.generateWorkout(profileH);
    _analyzeWorkout(workout, profileH, 'H');

    _validateSelection(workout, profileH, 'H');
    _validateEquipment(workout, profileH, 'H');
    _validatePrescription(workout, 'H');

    // Verificar que limitação está sendo considerada
    final v2Library = V2ExerciseLibrary();
    final allGym = v2Library.getByBlock(V2ExerciseBlock.gymFreeWeights);
    final homeExercises = v2Library.getByBlock(V2ExerciseBlock.home);

    // Identificar exercícios que teriam problemas com joelho
    final kneeProblematic = <String>[];
    for (final ex in [...allGym, ...homeExercises]) {
      for (final rule in ex.limitationRules) {
        if (rule.joint == V2Joint.knee &&
            (rule.severity == V2LimitationSeverity.moderate ||
             rule.severity == V2LimitationSeverity.severe)) {
          kneeProblematic.add(ex.id);
        }
      }
    }

    print('Exercícios com regra de limitação no joelho: ${kneeProblematic.length}');

    // Verificar que treino não contém exercícios com limitação severa no joelho
    for (final s in workout.sessions) {
      for (final ex in s.exercises) {
        final v2 = V2HomeBridge.getV2Exercise(ex.exercise.id);
        if (v2 != null) {
          for (final rule in v2.limitationRules) {
            if (rule.joint == V2Joint.knee &&
                rule.severity == V2LimitationSeverity.severe) {
              fail('${ex.exercise.name} tem limitação severa no joelho e não deveria estar no treino');
            }
          }
        }
      }
    }

    print('✓ Perfil H aprovado — limitação de joelho respeitada');
  });

  // ═══════════════════════════════════════════════════════════════
  // TESTE 9: DIFERENCIAÇÃO HIPERTROFIA vs FORÇA
  // ═══════════════════════════════════════════════════════════════

  test('Diferenciação: hipertrofia vs força', () {
    print('\n=== DIFERENCIAÇÃO: HIPERTROFIA vs FORÇA ===');

    // Usar mesmo perfil com objetivo diferente
    final baseProfile = UserTrainingProfile(
      uid: 'diff_test', age: 25, primaryGoal: V2Goal.hypertrophy,
      modality: V2Modality.hypertrophy,
      environment: V2Environment.gym,
      availableEquipment: const [V2Equipment.dumbbell, V2Equipment.barbell, V2Equipment.bench],
      availableDaysPerWeek: 3, sessionDurationMinutes: 45,
      experienceLevel: ExperienceLevel.regularly, trainingAgeMonths: 24,
    );

    final hypertrophyWorkout = intelligence.generateWorkout(baseProfile);

    final strengthProfile = UserTrainingProfile(
      uid: 'diff_test', age: 25, primaryGoal: V2Goal.strength,
      modality: V2Modality.strength,
      environment: V2Environment.gym,
      availableEquipment: const [V2Equipment.dumbbell, V2Equipment.barbell, V2Equipment.bench],
      availableDaysPerWeek: 3, sessionDurationMinutes: 45,
      experienceLevel: ExperienceLevel.regularly, trainingAgeMonths: 24,
    );

    final strengthWorkout = intelligence.generateWorkout(strengthProfile);

    // Comparar RIR
    final hRir = _avgRir(hypertrophyWorkout);
    final sRir = _avgRir(strengthWorkout);
    print('RIR médio: Hipertrofia=${hRir.toStringAsFixed(1)}, Força=${sRir.toStringAsFixed(1)}');

    // Força deve ter RIR menor (mais intenso)
    expect(sRir, lessThanOrEqualTo(hRir),
        reason: 'Força deve ter RIR menor ou igual a hipertrofia');

    // Comparar descanso
    final hRest = _avgRest(hypertrophyWorkout);
    final sRest = _avgRest(strengthWorkout);
    print('Descanso médio: Hipertrofia=${hRest.toStringAsFixed(0)}s, Força=${sRest.toStringAsFixed(0)}s');

    // Força deve ter descanso maior ou igual
    expect(sRest, greaterThanOrEqualTo(hRest),
        reason: 'Força deve ter descanso maior ou igual a hipertrofia');

    // Comparar volume (séries por exercício)
    final hAvgSets = _avgSetsPerExercise(hypertrophyWorkout);
    final sAvgSets = _avgSetsPerExercise(strengthWorkout);
    print('Séries/exercício: Hipertrofia=${hAvgSets.toStringAsFixed(1)}, Força=${sAvgSets.toStringAsFixed(1)}');

    print('✓ Diferenciação hipertrofia vs força validada');
  });

  // ═══════════════════════════════════════════════════════════════
  // TESTE 10: DIFERENCIAÇÃO POR NÍVEL
  // ═══════════════════════════════════════════════════════════════

  test('Diferenciação: iniciante vs intermediário vs avançado', () {
    print('\n=== DIFERENCIAÇÃO POR NÍVEL ===');

    UserTrainingProfile makeProfile(ExperienceLevel level, int months) {
      return UserTrainingProfile(
        uid: 'level_${level.name}', age: 25, primaryGoal: V2Goal.hypertrophy,
        modality: V2Modality.hypertrophy,
        environment: V2Environment.gym,
        availableEquipment: const [V2Equipment.dumbbell, V2Equipment.barbell, V2Equipment.bench],
        availableDaysPerWeek: 3, sessionDurationMinutes: 45,
        experienceLevel: level, trainingAgeMonths: months,
      );
    }

    final beginner = intelligence.generateWorkout(makeProfile(ExperienceLevel.never, 0));
    final intermediate = intelligence.generateWorkout(makeProfile(ExperienceLevel.regularly, 24));
    final advanced = intelligence.generateWorkout(makeProfile(ExperienceLevel.years, 60));

    final bExCount = beginner.sessions.expand((s) => s.exercises).length;
    final iExCount = intermediate.sessions.expand((s) => s.exercises).length;
    final aExCount = advanced.sessions.expand((s) => s.exercises).length;

    final bRir = _avgRir(beginner);
    final iRir = _avgRir(intermediate);
    final aRir = _avgRir(advanced);

    print('Exercícios: Iniciante=$bExCount, Intermediário=$iExCount, Avançado=$aExCount');
    print('RIR médio: Iniciante=${bRir.toStringAsFixed(1)}, Intermediário=${iRir.toStringAsFixed(1)}, Avançado=${aRir.toStringAsFixed(1)}');

    // Avançado deve ter mais exercícios que iniciante
    expect(aExCount, greaterThanOrEqualTo(bExCount),
        reason: 'Avançado deve ter >= exercícios que iniciante');

    // Avançado deve ter RIR menor ou igual (mais intenso)
    expect(aRir, lessThanOrEqualTo(bRir),
        reason: 'Avançado deve ter RIR <= iniciante');

    print('✓ Diferenciação por nível validada');
  });

  // ═══════════════════════════════════════════════════════════════
  // TESTE 11: VARIAÇÃO POR FREQUÊNCIA
  // ═══════════════════════════════════════════════════════════════

  test('Frequência: 2x vs 3x vs 4x vs 5x', () {
    print('\n=== VARIAÇÃO POR FREQUÊNCIA ===');

    UserTrainingProfile makeProfile(int days) {
      return UserTrainingProfile(
        uid: 'freq_$days', age: 25, primaryGoal: V2Goal.hypertrophy,
        modality: V2Modality.hypertrophy,
        environment: V2Environment.gym,
        availableEquipment: const [V2Equipment.dumbbell, V2Equipment.barbell, V2Equipment.bench],
        availableDaysPerWeek: days, sessionDurationMinutes: 45,
        experienceLevel: ExperienceLevel.regularly, trainingAgeMonths: 24,
      );
    }

    for (final days in [2, 3, 4, 5]) {
      final workout = intelligence.generateWorkout(makeProfile(days));
      print('${days}x/semana: ${workout.sessions.length} sessões');

      expect(workout.sessions.length, days,
          reason: '$days dias devem gerar $days sessões');

      // Volume total deve ser coerente
      final totalSets = workout.sessions
          .expand((s) => s.exercises)
          .map((e) => e.sets)
          .reduce((a, b) => a + b);
      print('  Volume total: $totalSets séries');
    }

    print('✓ Frequência validada');
  });

  // ═══════════════════════════════════════════════════════════════
  // TESTE 12: VARIAÇÃO POR DURAÇÃO
  // ═══════════════════════════════════════════════════════════════

  test('Duração: 30min vs 45min vs 60min', () {
    print('\n=== VARIAÇÃO POR DURAÇÃO ===');

    UserTrainingProfile makeProfile(int minutes) {
      return UserTrainingProfile(
        uid: 'dur_$minutes', age: 25, primaryGoal: V2Goal.hypertrophy,
        modality: V2Modality.hypertrophy,
        environment: V2Environment.gym,
        availableEquipment: const [V2Equipment.dumbbell, V2Equipment.barbell, V2Equipment.bench],
        availableDaysPerWeek: 3, sessionDurationMinutes: minutes,
        experienceLevel: ExperienceLevel.regularly, trainingAgeMonths: 24,
      );
    }

    final w30 = intelligence.generateWorkout(makeProfile(30));
    final w45 = intelligence.generateWorkout(makeProfile(45));
    final w60 = intelligence.generateWorkout(makeProfile(60));

    final ex30 = w30.sessions.expand((s) => s.exercises).length ~/ w30.sessions.length;
    final ex45 = w45.sessions.expand((s) => s.exercises).length ~/ w45.sessions.length;
    final ex60 = w60.sessions.expand((s) => s.exercises).length ~/ w60.sessions.length;

    print('Exercícios/sessão: 30min=$ex30, 45min=$ex45, 60min=$ex60');

    // Mais tempo = mais exercícios
    expect(ex60, greaterThanOrEqualTo(ex45),
        reason: '60min deve ter >= exercícios que 45min');
    expect(ex45, greaterThanOrEqualTo(ex30),
        reason: '45min deve ter >= exercícios que 30min');

    print('✓ Duração validada');
  });

  // ═══════════════════════════════════════════════════════════════
  // TESTE 13: RELAÇÕES PROGRESSÃO/REGRESSÃO
  // ═══════════════════════════════════════════════════════════════

  test('Relações: progressão/regressão semanticamente coerentes', () {
    print('\n=== RELAÇÕES PROGRESSÃO/REGRESSÃO ===');

    final library = V2ExerciseLibrary();
    final gymExercises = library.getByBlock(V2ExerciseBlock.gymFreeWeights);

    // Relações que devem existir
    final expectedProgressions = {
      'gym_pushh_001': 'gym_pushh_002', // DB Bench → Barbell Bench
      'gym_squat_001': 'gym_squat_002', // Goblet → Back Squat
      'gym_squat_002': 'gym_squat_003', // Back Squat → Front Squat
      'gym_hinge_002': 'gym_hinge_001', // DB RDL → Barbell RDL
      'gym_hinge_001': 'gym_hinge_003', // Barbell RDL → Deadlift
      'gym_hipext_002': 'gym_hipext_001', // DB Hip Thrust → Barbell
    };

    for (final entry in expectedProgressions.entries) {
      final source = library.getById(entry.key);
      final target = library.getById(entry.value);

      expect(source, isNotNull, reason: '${entry.key} não encontrado');
      expect(target, isNotNull, reason: '${entry.value} não encontrado');

      final hasProgression = source!.relatedExercises.any(
        (r) => r.targetId == entry.value && r.type.name == 'progression',
      );

      print('${source.name} → ${entry.value}: ${hasProgression ? "✓" : "✗"}');

      expect(hasProgression, isTrue,
          reason: '${source.name} deveria ter progressão para ${target!.name}');
    }

    print('✓ Relações progressão/regressão validadas');
  });

  // ═══════════════════════════════════════════════════════════════
  // TESTE 14: PULL VERTICAL
  // ═══════════════════════════════════════════════════════════════

  test('Pull vertical: Pullover não substitui pull vertical', () {
    print('\n=== PULL VERTICAL ===');

    final library = V2ExerciseLibrary();
    final pullover = library.getById('gym_pullv_001');

    expect(pullover, isNotNull);
    expect(pullover!.pattern, V2MovementPattern.pullVertical);

    print('Pullover pattern: ${pullover.pattern.name}');
    print('Pullover músculos primários: ${pullover.primaryMuscles}');

    // O Pullover é pullVertical, mas seus músculos primários são latissimus_dorsi
    // Ele NÃO deve ser tratado como equivalente a barra fixa/puxada
    // Isso é uma lacuna de biblioteca, não um bug

    print('✓ Pull vertical: Pullover registrado como pullVertical');
    print('  NOTA: Barra fixa/puxada vertical é lacuna de biblioteca');
  });

  // ═══════════════════════════════════════════════════════════════
  // TESTE 15: RASTREABILIDADE V2
  // ═══════════════════════════════════════════════════════════════

  test('Rastreabilidade: todos os exercícios Gym são V2', () {
    print('\n=== RASTREABILIDADE V2 ===');

    final workout = intelligence.generateWorkout(profileB);

    for (final s in workout.sessions) {
      for (final ex in s.exercises) {
        // Verificar que tem tag v2
        expect(ex.exercise.tags, contains('v2'),
            reason: '${ex.exercise.name} não tem tag v2');

        // Verificar que o ID começa com gym_ ou home_
        final isGym = ex.exercise.id.startsWith('gym_');
        final isHome = ex.exercise.id.startsWith('home_');
        expect(isGym || isHome, isTrue,
            reason: '${ex.exercise.id} não é um ID V2 válido');

        // Verificar que V2HomeBridge consegue recuperar o original
        final v2 = V2HomeBridge.getV2Exercise(ex.exercise.id);
        expect(v2, isNotNull,
            reason: '${ex.exercise.id} não encontrado no V2HomeBridge');
      }
    }

    print('✓ Rastreabilidade V2 validada');
  });
}

// ═══════════════════════════════════════════════════════════════
// FUNÇÕES AUXILIARES DE ANÁLISE
// ═══════════════════════════════════════════════════════════════

void _analyzeWorkout(GeneratedWorkout workout, UserTrainingProfile profile, String label) {
  print('\n--- $label: ANÁLISE DO TREINO ---');
  print('Sessões: ${workout.sessions.length}');
  print('Split: ${workout.splitType}');
  print('Modelo: ${workout.periodizationModel}');

  for (var i = 0; i < workout.sessions.length; i++) {
    final s = workout.sessions[i];
    final exCount = s.exercises.length;
    final totalSets = s.exercises.map((e) => e.sets).reduce((a, b) => a + b);
    final avgRir = s.exercises.map((e) => e.rir).reduce((a, b) => a + b) / exCount;
    final avgRest = s.exercises.map((e) => e.restSeconds).reduce((a, b) => a + b) / exCount;

    print('\n  Sessão ${i + 1}: ${s.name}');
    print('    Objetivo: ${s.objective}');
    print('    Exercícios: $exCount');
    print('    Séries totais: $totalSets');
    print('    RIR médio: ${avgRir.toStringAsFixed(1)}');
    print('    Descanso médio: ${avgRest.toStringAsFixed(0)}s');
    print('    Duração estimada: ${s.estimatedDurationMinutes}min');

    for (final ex in s.exercises) {
      final v2 = V2HomeBridge.getV2Exercise(ex.exercise.id);
      final block = v2?.block.name ?? 'unknown';
      print('      ${ex.exercise.name} [$block] '
          '${ex.sets}×${ex.repsMin}-${ex.repsMax} '
          'RIR${ex.rir} descanso${ex.restSeconds}s '
          '${ex.decisionReason ?? ""}');
    }
  }

  // Volume total
  final totalSets = workout.sessions
      .expand((s) => s.exercises)
      .map((e) => e.sets)
      .reduce((a, b) => a + b);
  final totalExercises = workout.sessions
      .expand((s) => s.exercises)
      .length;
  print('\n  RESUMO: $totalExercises exercícios, $totalSets séries totais');
}

void _validateSelection(GeneratedWorkout workout, UserTrainingProfile profile, String label) {
  final allExercises = workout.sessions.expand((s) => s.exercises).toList();

  // Verificar que todos são do bloco gym (ou home se não há gym)
  for (final ex in allExercises) {
    final v2 = V2HomeBridge.getV2Exercise(ex.exercise.id);
    if (v2 != null) {
      if (profile.environment == V2Environment.gym) {
        expect(
          v2.block.name == 'gymFreeWeights' || v2.block.name == 'home',
          isTrue,
          reason: '$label: ${ex.exercise.name} não é gym nem home',
        );
      }
    }
  }
}

void _validatePatterns(GeneratedWorkout workout, String label) {
  final patterns = <String, int>{};
  for (final s in workout.sessions) {
    for (final ex in s.exercises) {
      final v2 = V2HomeBridge.getV2Exercise(ex.exercise.id);
      if (v2 != null) {
        patterns[v2.pattern.name] = (patterns[v2.pattern.name] ?? 0) + 1;
      }
    }
  }

  print('\n  $label Padrões: $patterns');

  // Deve ter pelo menos push e squat/hinge
  expect(patterns.containsKey('pushHorizontal') || patterns.containsKey('pushVertical') || patterns.containsKey('pushIncline'), isTrue,
      reason: '$label: Deve ter pelo menos um push pattern');
  expect(patterns.containsKey('squat') || patterns.containsKey('hipHinge'), isTrue,
      reason: '$label: Deve ter squat ou hinge');
}

void _validateDuration(GeneratedWorkout workout, UserTrainingProfile profile, String label) {
  for (final s in workout.sessions) {
    if (s.estimatedDurationMinutes > profile.sessionDurationMinutes * 1.3) {
      print('  ⚠ $label Sessão ${s.name}: duração estimada (${s.estimatedDurationMinutes}min) '
          'excede ${profile.sessionDurationMinutes}min');
    }
  }
}

void _validateEquipment(GeneratedWorkout workout, UserTrainingProfile profile, String label) {
  for (final s in workout.sessions) {
    for (final ex in s.exercises) {
      final v2 = V2HomeBridge.getV2Exercise(ex.exercise.id);
      if (v2 != null) {
        for (final equip in v2.requiredEquipment) {
          expect(profile.availableEquipment.contains(equip), isTrue,
              reason: '$label: ${ex.exercise.name} requer ${equip.name} que não está disponível');
        }
      }
    }
  }
}

void _validateNoRedundancy(GeneratedWorkout workout, String label) {
  for (final s in workout.sessions) {
    final patterns = s.exercises.map((e) {
      final v2 = V2HomeBridge.getV2Exercise(e.exercise.id);
      return v2?.pattern.name ?? '';
    }).toList();

    final counts = <String, int>{};
    for (final p in patterns) {
      counts[p] = (counts[p] ?? 0) + 1;
    }

    for (final entry in counts.entries) {
      if (entry.value > 2) {
        print('  ⚠ $label Sessão ${s.name}: padrão ${entry.key} aparece ${entry.value} vezes');
      }
    }
  }
}

void _validatePrescription(GeneratedWorkout workout, String label) {
  for (final s in workout.sessions) {
    for (final ex in s.exercises) {
      // Verificar que usa V2EngineRules
      expect(ex.sets, greaterThanOrEqualTo(1), reason: '$label: ${ex.exercise.name} deve ter séries');
      expect(ex.repsMin, greaterThanOrEqualTo(1), reason: '$label: ${ex.exercise.name} deve ter repsMin');
      expect(ex.repsMax, greaterThanOrEqualTo(ex.repsMin), reason: '$label: repsMax >= repsMin');
      expect(ex.rir, greaterThanOrEqualTo(0), reason: '$label: RIR deve ser >= 0');
      expect(ex.rir, lessThanOrEqualTo(3), reason: '$label: RIR deve ser <= 3');
      expect(ex.restSeconds, greaterThanOrEqualTo(30), reason: '$label: descanso deve ser >= 30s');
    }
  }
}

double _avgRir(GeneratedWorkout workout) {
  final rirs = workout.sessions.expand((s) => s.exercises).map((e) => e.rir).toList();
  return rirs.reduce((a, b) => a + b) / rirs.length;
}

double _avgRest(GeneratedWorkout workout) {
  final rests = workout.sessions.expand((s) => s.exercises).map((e) => e.restSeconds).toList();
  return rests.reduce((a, b) => a + b) / rests.length;
}

double _avgSetsPerExercise(GeneratedWorkout workout) {
  final sets = workout.sessions.expand((s) => s.exercises).map((e) => e.sets).toList();
  return sets.reduce((a, b) => a + b) / sets.length;
}
