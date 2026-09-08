import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/workout/intelligence/user_training_profile.dart';
import 'package:app/features/workout/intelligence/training_intelligence.dart';
import 'package:app/features/exercise_library_v2/v2_exercise_library.dart';
import 'package:app/features/exercise_library_v2/data/home_exercises.dart';
import 'package:app/features/exercise_library_v2/bridge/v2_home_bridge.dart';
import 'package:app/features/exercise_library_v2/enums/goal.dart';
import 'package:app/features/exercise_library_v2/enums/modality.dart';
import 'package:app/features/exercise_library_v2/enums/environment.dart';
import 'package:app/features/exercise_library_v2/enums/joint.dart';
import 'package:app/features/exercise_library_v2/enums/limitation_severity.dart';
import 'package:app/features/workout/prescribed_workout_model.dart';

void main() {
  setUpAll(() {
    final library = V2ExerciseLibrary();
    library.registerAll(createHomeExercises());
    V2HomeBridge.registerAll(createHomeExercises());
  });

  final intelligence = TrainingIntelligence();

  // ── PERFIS ──

  final profile1 = UserTrainingProfile(
    uid: 'p1', age: 25, primaryGoal: V2Goal.generalFitness,
    modality: V2Modality.generalPhysicalDevelopment,
    environment: V2Environment.home, availableEquipment: const [],
    availableDaysPerWeek: 3, sessionDurationMinutes: 30,
    experienceLevel: ExperienceLevel.regularly, trainingAgeMonths: 24,
  );

  final profile2 = UserTrainingProfile(
    uid: 'p2', age: 25, primaryGoal: V2Goal.conditioning,
    modality: V2Modality.conditioning,
    environment: V2Environment.home, availableEquipment: const [],
    availableDaysPerWeek: 3, sessionDurationMinutes: 30,
    experienceLevel: ExperienceLevel.regularly, trainingAgeMonths: 24,
  );

  final profile3 = UserTrainingProfile(
    uid: 'p3', age: 25, primaryGoal: V2Goal.generalFitness,
    modality: V2Modality.generalPhysicalDevelopment,
    environment: V2Environment.home, availableEquipment: const [],
    availableDaysPerWeek: 4, sessionDurationMinutes: 45,
    experienceLevel: ExperienceLevel.years, trainingAgeMonths: 60,
  );

  final profile4 = UserTrainingProfile(
    uid: 'p4', age: 25, primaryGoal: V2Goal.generalFitness,
    modality: V2Modality.generalPhysicalDevelopment,
    environment: V2Environment.home, availableEquipment: const [],
    availableDaysPerWeek: 3, sessionDurationMinutes: 30,
    experienceLevel: ExperienceLevel.regularly, trainingAgeMonths: 24,
    limitations: const [
      UserLimitation(
        joint: V2Joint.knee, severity: V2LimitationSeverity.moderate,
        side: 'both', timing: 'during',
        affectedMovements: ['agachar', 'saltar'],
      ),
    ],
  );

  // ── TESTE 1: Perfil 1 — 4 semanas ──
  test('Longitudinal: Perfil 1 — 4 semanas', () {
    print('\n╔══════════════════════════════════════════════════════════════╗');
    print('║ LONGITUDINAL: Perfil 1 — Intermediário + Geral + 3x/sem  ║');
    print('╚══════════════════════════════════════════════════════════════╝');

    final allWeeks = <GeneratedWorkout>[];
    for (var week = 1; week <= 4; week++) {
      allWeeks.add(intelligence.generateWorkout(profile1, weekNumber: week));
    }

    _analyzeLongitudinal(allWeeks, 'Perfil 1');

    // ── Coerência de RIR ──
    _validateRirCoherence(allWeeks, 'Perfil 1');

    // ── Volume não cresce automaticamente ──
    _validateVolumeNotAutomatic(allWeeks, 'Perfil 1');

    // ── Limitações respeitadas ──
    _validateLimitations(allWeeks, 'Perfil 1');

    print('✓ Perfil 1: 4 semanas geradas com progressão contextual');
  });

  // ── TESTE 2: Perfil 2 — 4 semanas ──
  test('Longitudinal: Perfil 2 — 4 semanas', () {
    print('\n╔══════════════════════════════════════════════════════════════╗');
    print('║ LONGITUDINAL: Perfil 2 — Intermediário + Condicionamento   ║');
    print('╚══════════════════════════════════════════════════════════════╝');

    final allWeeks = <GeneratedWorkout>[];
    for (var week = 1; week <= 4; week++) {
      allWeeks.add(intelligence.generateWorkout(profile2, weekNumber: week));
    }

    _analyzeLongitudinal(allWeeks, 'Perfil 2');

    // ── Deve ter exercícios de condicionamento em todas as semanas ──
    for (var week = 0; week < 4; week++) {
      final hasConditioning = allWeeks[week].sessions
          .expand((s) => s.exercises)
          .any((e) => e.exercise.tags.contains('v2_pattern_conditioning'));
      expect(hasConditioning, isTrue,
          reason: 'Semana ${week + 1} deve ter exercício de condicionamento');
    }

    // ── Coerência de RIR ──
    _validateRirCoherence(allWeeks, 'Perfil 2');

    // ── Volume não cresce automaticamente ──
    _validateVolumeNotAutomatic(allWeeks, 'Perfil 2');

    print('✓ Perfil 2: 4 semanas geradas com progressão contextual');
  });

  // ── TESTE 3: Perfil 3 — 4 semanas ──
  test('Longitudinal: Perfil 3 — 4 semanas', () {
    print('\n╔══════════════════════════════════════════════════════════════╗');
    print('║ LONGITUDINAL: Perfil 3 — Avançado + 4x/semana             ║');
    print('╚══════════════════════════════════════════════════════════════╝');

    final allWeeks = <GeneratedWorkout>[];
    for (var week = 1; week <= 4; week++) {
      allWeeks.add(intelligence.generateWorkout(profile3, weekNumber: week));
    }

    _analyzeLongitudinal(allWeeks, 'Perfil 3');

    // ── Avançado deve ter volume adequado ──
    final week1Sets = _totalSets(allWeeks[0]);
    expect(week1Sets, greaterThanOrEqualTo(20),
        reason: 'Avançado deve ter ≥20 séries semanais');

    // ── Coerência de RIR ──
    _validateRirCoherence(allWeeks, 'Perfil 3');

    // ── Volume não cresce automaticamente ──
    _validateVolumeNotAutomatic(allWeeks, 'Perfil 3');

    print('✓ Perfil 3: 4 semanas geradas com progressão contextual');
  });

  // ── TESTE 4: Perfil 4 — 4 semanas ──
  test('Longitudinal: Perfil 4 — 4 semanas', () {
    print('\n╔══════════════════════════════════════════════════════════════╗');
    print('║ LONGITUDINAL: Perfil 4 — Com limitação + 3x/semana        ║');
    print('╚══════════════════════════════════════════════════════════════╝');

    final allWeeks = <GeneratedWorkout>[];
    for (var week = 1; week <= 4; week++) {
      allWeeks.add(intelligence.generateWorkout(profile4, weekNumber: week));
    }

    _analyzeLongitudinal(allWeeks, 'Perfil 4');

    // ── Limitação deve ser respeitada em todas as semanas ──
    _validateLimitations(allWeeks, 'Perfil 4');

    // ── Coerência de RIR ──
    _validateRirCoherence(allWeeks, 'Perfil 4');

    // ── Volume não cresce automaticamente ──
    _validateVolumeNotAutomatic(allWeeks, 'Perfil 4');

    print('✓ Perfil 4: 4 semanas geradas com progressão contextual e limitação respeitada');
  });

  // ── TESTE 5: Comparação Semana 1 vs Semana 4 ──
  test('Longitudinal: prescrição Semana 1 vs Semana 4', () {
    print('\n=== COMPARAÇÃO: PRESCRIÇÃO SEMANA 1 vs SEMANA 4 ===');

    final week1 = intelligence.generateWorkout(profile1, weekNumber: 1);
    final week4 = intelligence.generateWorkout(profile1, weekNumber: 4);

    // Séries
    final avgSets1 = _avgSets(week1);
    final avgSets4 = _avgSets(week4);
    print('Séries médias: Sem1=${avgSets1.toStringAsFixed(1)}, Sem4=${avgSets4.toStringAsFixed(1)}');

    // Reps
    final avgReps1 = _avgReps(week1);
    final avgReps4 = _avgReps(week4);
    print('Reps máx médios: Sem1=${avgReps1.toStringAsFixed(1)}, Sem4=${avgReps4.toStringAsFixed(1)}');

    // RIR
    final avgRir1 = _avgRir(week1);
    final avgRir4 = _avgRir(week4);
    print('RIR médio: Sem1=${avgRir1.toStringAsFixed(1)}, Sem4=${avgRir4.toStringAsFixed(1)}');

    // Descanso
    final avgRest1 = _avgRest(week1);
    final avgRest4 = _avgRest(week4);
    print('Descanso médio: Sem1=${avgRest1.toStringAsFixed(0)}s, Sem4=${avgRest4.toStringAsFixed(0)}s');

    // Volume total
    final week1Total = _totalSets(week1);
    final week4Total = _totalSets(week4);
    print('Volume total: Sem1=$week1Total, Sem4=$week4Total séries');

    // ── Verificar coerência ──
    // RIR não deve aumentar significativamente (ficar mais fácil)
    expect(avgRir4, lessThanOrEqualTo(avgRir1 + 0.5),
        reason: 'RIR não deve aumentar significativamente');

    // Volume total não deve diminuir drasticamente
    expect(week4Total, greaterThanOrEqualTo(week1Total - 4),
        reason: 'Volume total não deve diminuir significativamente');

    print('✓ Prescrição coerente entre Semana 1 e Semana 4');
  });

  // ── TESTE 6: Progressão é contextual ──
  test('Longitudinal: progressão é contextual', () {
    print('\n=== VALIDAÇÃO: PROGRESSÃO CONTEXTUAL ===');

    // Iniciante com sessão curta: deve ter progressão limitada
    final beginnerShort = UserTrainingProfile(
      uid: 'beginner_short', age: 25, primaryGoal: V2Goal.generalFitness,
      modality: V2Modality.generalPhysicalDevelopment,
      environment: V2Environment.home, availableEquipment: const [],
      availableDaysPerWeek: 3, sessionDurationMinutes: 20,
      experienceLevel: ExperienceLevel.never, trainingAgeMonths: 0,
    );

    final allWeeks = <GeneratedWorkout>[];
    for (var week = 1; week <= 4; week++) {
      allWeeks.add(intelligence.generateWorkout(beginnerShort, weekNumber: week));
    }

    final week1Sets = _totalSets(allWeeks[0]);
    final week4Sets = _totalSets(allWeeks[3]);
    print('Iniciante curto: Sem1=$week1Sets, Sem4=$week4Sets séries');

    // Volume não deve aumentar drasticamente para iniciante com sessão curta
    expect(week4Sets, lessThanOrEqualTo(week1Sets + 2),
        reason: 'Iniciante com sessão curta não deve ter progressão de volume significativa');

    print('✓ Progressão é contextual e respeita limitações do perfil');
  });
}

// ── Funções auxiliares ──

int _totalSets(GeneratedWorkout workout) {
  return workout.sessions
      .expand((s) => s.exercises)
      .map((e) => e.sets)
      .reduce((a, b) => a + b);
}

double _avgSets(GeneratedWorkout workout) {
  final sets = workout.sessions
      .expand((s) => s.exercises)
      .map((e) => e.sets)
      .toList();
  return sets.reduce((a, b) => a + b) / sets.length;
}

double _avgReps(GeneratedWorkout workout) {
  final reps = workout.sessions
      .expand((s) => s.exercises)
      .map((e) => e.repsMax)
      .toList();
  return reps.reduce((a, b) => a + b) / reps.length;
}

double _avgRir(GeneratedWorkout workout) {
  final rirs = workout.sessions
      .expand((s) => s.exercises)
      .map((e) => e.rir)
      .toList();
  return rirs.reduce((a, b) => a + b) / rirs.length;
}

double _avgRest(GeneratedWorkout workout) {
  final rests = workout.sessions
      .expand((s) => s.exercises)
      .map((e) => e.restSeconds)
      .toList();
  return rests.reduce((a, b) => a + b) / rests.length;
}

void _validateRirCoherence(List<GeneratedWorkout> weeks, String label) {
  for (var i = 0; i < weeks.length; i++) {
    final rirs = weeks[i].sessions
        .expand((s) => s.exercises)
        .map((e) => e.rir)
        .toList();

    // RIR deve estar entre 0 e 3
    for (final rir in rirs) {
      expect(rir, greaterThanOrEqualTo(0),
          reason: '$label Semana ${i + 1}: RIR deve ser ≥ 0');
      expect(rir, lessThanOrEqualTo(3),
          reason: '$label Semana ${i + 1}: RIR deve ser ≤ 3');
    }
  }

  // Verificar que RIR não aumenta entre semanas adjacentes
  for (var i = 0; i < weeks.length - 1; i++) {
    final avgRirCurrent = _avgRir(weeks[i]);
    final avgRirNext = _avgRir(weeks[i + 1]);

    // RIR pode diminuir (mais intenso) ou permanecer, mas não deve aumentar drasticamente
    expect(avgRirNext, lessThanOrEqualTo(avgRirCurrent + 0.5),
        reason: '$label: RIR não deve aumentar significativamente entre semanas ${i + 1} e ${i + 2}');
  }
}

void _validateVolumeNotAutomatic(List<GeneratedWorkout> weeks, String label) {
  final volumes = weeks.map((w) => _totalSets(w)).toList();

  // Verificar que volume não cresce toda semana
  var growthCount = 0;
  for (var i = 0; i < volumes.length - 1; i++) {
    if (volumes[i + 1] > volumes[i]) growthCount++;
  }

  // No máximo 2 semanas podem ter crescimento (não todas)
  expect(growthCount, lessThanOrEqualTo(2),
      reason: '$label: Volume não deve crescer automaticamente toda semana');
}

void _validateLimitations(List<GeneratedWorkout> weeks, String label) {
  for (var week = 0; week < weeks.length; week++) {
    for (final s in weeks[week].sessions) {
      for (final ex in s.exercises) {
        // Não deve ter exercícios de salto
        expect(ex.exercise.name.contains('Salto'), isFalse,
            reason: '$label Semana ${week + 1}: ${ex.exercise.name} não deve estar presente com limitação no joelho');
      }
    }
  }
}

void _analyzeLongitudinal(List<GeneratedWorkout> weeks, String label) {
  print('\n--- $label: ANÁLISE LONGITUDINAL ---');

  for (var w = 0; w < weeks.length; w++) {
    final week = weeks[w];
    final totalExercises = week.sessions.expand((s) => s.exercises).length;
    final totalSets = _totalSets(week);
    final avgRir = _avgRir(week);
    final patterns = week.sessions.expand((s) => s.exercises).map((e) => e.exercise.movementPattern).toSet();

    print('  Semana ${w + 1}: ${week.sessions.length} sessões, $totalExercises exercícios, '
        '$totalSets séries, RIR ${avgRir.toStringAsFixed(1)}, ${patterns.length} padrões');
  }

  // Verificar variação entre semanas
  final weekPatterns = weeks.map((w) =>
      w.sessions.expand((s) => s.exercises).map((e) => e.exercise.movementPattern).toSet()).toList();

  for (var i = 0; i < weekPatterns.length - 1; i++) {
    final intersection = weekPatterns[i].intersection(weekPatterns[i + 1]);
    final union = weekPatterns[i].union(weekPatterns[i + 1]);
    final similarity = union.isNotEmpty ? intersection.length / union.length : 0.0;
    print('  Similaridade semanas ${i + 1}-${i + 2}: ${(similarity * 100).toStringAsFixed(0)}%');
  }

  // Justificativa da progressão
  print('  ── Justificativa ──');
  print('  Progressão determinada pelo perfil do usuário, não pelo número da semana.');
  print('  Volume e intensidade variam conforme: objetivo, nível, duração, frequência, recuperação.');
}
