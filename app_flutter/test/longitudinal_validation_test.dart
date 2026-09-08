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
    print('║ LONGITUDINAL: Perfil 1 — Iniciante + Geral + 3x/semana    ║');
    print('╚══════════════════════════════════════════════════════════════╝');

    final allWeeks = <GeneratedWorkout>[];
    for (var week = 1; week <= 4; week++) {
      allWeeks.add(intelligence.generateWorkout(profile1, weekNumber: week));
    }

    _analyzeLongitudinal(allWeeks, 'Perfil 1');

    // ── Continuidade ──
    // Padrões devem ser cobertos em todas as semanas
    final week1Patterns = allWeeks[0].sessions.expand((s) => s.exercises).map((e) => e.exercise.movementPattern).toSet();
    final week4Patterns = allWeeks[3].sessions.expand((s) => s.exercises).map((e) => e.exercise.movementPattern).toSet();
    expect(week1Patterns, isNotEmpty);
    expect(week4Patterns, isNotEmpty);

    // ── Progressão ──
    final week1Sets = allWeeks[0].sessions.expand((s) => s.exercises).map((e) => e.sets).reduce((a, b) => a + b);
    final week4Sets = allWeeks[3].sessions.expand((s) => s.exercises).map((e) => e.sets).reduce((a, b) => a + b);

    print('Volume Semana 1: $week1Sets séries');
    print('Volume Semana 4: $week4Sets séries');

    // Volume deve aumentar ou permanecer
    expect(week4Sets, greaterThanOrEqualTo(week1Sets),
        reason: 'Volume deve aumentar ou permanecer ao longo das semanas');

    print('✓ Perfil 1: 4 semanas geradas com progressão');
  });

  // ── TESTE 2: Perfil 2 — 4 semanas ──
  test('Longitudinal: Perfil 2 — 4 semanas', () {
    print('\n╔══════════════════════════════════════════════════════════════╗');
    print('║ LONGITUDINAL: Perfil 2 — Iniciante + Condicionamento       ║');
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

    // ── Volume deve aumentar ou permanecer ──
    final week1Sets = allWeeks[0].sessions.expand((s) => s.exercises).map((e) => e.sets).reduce((a, b) => a + b);
    final week4Sets = allWeeks[3].sessions.expand((s) => s.exercises).map((e) => e.sets).reduce((a, b) => a + b);

    print('Volume Semana 1: $week1Sets séries');
    print('Volume Semana 4: $week4Sets séries');

    expect(week4Sets, greaterThanOrEqualTo(week1Sets),
        reason: 'Volume deve aumentar ou permanecer ao longo das semanas');

    print('✓ Perfil 2: 4 semanas geradas com progressão');
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

    // ── Avançado deve ter mais volume ──
    final week1Sets = allWeeks[0].sessions.expand((s) => s.exercises).map((e) => e.sets).reduce((a, b) => a + b);
    final week4Sets = allWeeks[3].sessions.expand((s) => s.exercises).map((e) => e.sets).reduce((a, b) => a + b);

    print('Volume Semana 1: $week1Sets séries');
    print('Volume Semana 4: $week4Sets séries');

    // Avançado deve ter volume adequado
    expect(week1Sets, greaterThanOrEqualTo(20),
        reason: 'Avançado deve ter ≥20 séries semanais');

    // Volume deve aumentar
    expect(week4Sets, greaterThanOrEqualTo(week1Sets),
        reason: 'Volume deve aumentar ao longo das semanas');

    // ── RIR deve diminuir ao longo das semanas ──
    final week1Rir = allWeeks[0].sessions.expand((s) => s.exercises).map((e) => e.rir).reduce((a, b) => a + b) /
        allWeeks[0].sessions.expand((s) => s.exercises).length;
    final week4Rir = allWeeks[3].sessions.expand((s) => s.exercises).map((e) => e.rir).reduce((a, b) => a + b) /
        allWeeks[3].sessions.expand((s) => s.exercises).length;

    print('RIR médio: Sem1=${week1Rir.toStringAsFixed(1)}, Sem4=${week4Rir.toStringAsFixed(1)}');

    // RIR deve diminuir ou permanecer (não aumentar)
    expect(week4Rir, lessThanOrEqualTo(week1Rir + 0.5),
        reason: 'RIR não deve aumentar significativamente');

    print('✓ Perfil 3: 4 semanas geradas com progressão');
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
    for (var week = 0; week < 4; week++) {
      for (final s in allWeeks[week].sessions) {
        for (final ex in s.exercises) {
          // Não deve ter exercícios de salto
          expect(ex.exercise.name.contains('Salto'), isFalse,
              reason: 'Semana ${week + 1}: ${ex.exercise.name} não deve estar presente com limitação no joelho');
        }
      }
    }

    // ── Volume deve aumentar ou permanecer ──
    final week1Sets = allWeeks[0].sessions.expand((s) => s.exercises).map((e) => e.sets).reduce((a, b) => a + b);
    final week4Sets = allWeeks[3].sessions.expand((s) => s.exercises).map((e) => e.sets).reduce((a, b) => a + b);

    print('Volume Semana 1: $week1Sets séries');
    print('Volume Semana 4: $week4Sets séries');

    expect(week4Sets, greaterThanOrEqualTo(week1Sets),
        reason: 'Volume deve aumentar ou permanecer ao longo das semanas');

    print('✓ Perfil 4: 4 semanas geradas com progressão e limitação respeitada');
  });

  // ── TESTE 5: Comparação Semana 1 vs Semana 4 ──
  test('Longitudinal: prescrição Semana 1 vs Semana 4', () {
    print('\n=== COMPARAÇÃO: PRESCRIÇÃO SEMANA 1 vs SEMANA 4 ===');

    final week1 = intelligence.generateWorkout(profile1, weekNumber: 1);
    final week4 = intelligence.generateWorkout(profile1, weekNumber: 4);

    // Séries
    final week1Sets = week1.sessions.expand((s) => s.exercises).map((e) => e.sets).toList();
    final week4Sets = week4.sessions.expand((s) => s.exercises).map((e) => e.sets).toList();
    final avgSets1 = week1Sets.reduce((a, b) => a + b) / week1Sets.length;
    final avgSets4 = week4Sets.reduce((a, b) => a + b) / week4Sets.length;
    print('Séries médias: Sem1=${avgSets1.toStringAsFixed(1)}, Sem4=${avgSets4.toStringAsFixed(1)}');

    // Reps
    final week1Reps = week1.sessions.expand((s) => s.exercises).map((e) => e.repsMax).toList();
    final week4Reps = week4.sessions.expand((s) => s.exercises).map((e) => e.repsMax).toList();
    final avgReps1 = week1Reps.reduce((a, b) => a + b) / week1Reps.length;
    final avgReps4 = week4Reps.reduce((a, b) => a + b) / week4Reps.length;
    print('Reps máx médios: Sem1=${avgReps1.toStringAsFixed(1)}, Sem4=${avgReps4.toStringAsFixed(1)}');

    // RIR
    final week1Rir = week1.sessions.expand((s) => s.exercises).map((e) => e.rir).toList();
    final week4Rir = week4.sessions.expand((s) => s.exercises).map((e) => e.rir).toList();
    final avgRir1 = week1Rir.reduce((a, b) => a + b) / week1Rir.length;
    final avgRir4 = week4Rir.reduce((a, b) => a + b) / week4Rir.length;
    print('RIR médio: Sem1=${avgRir1.toStringAsFixed(1)}, Sem4=${avgRir4.toStringAsFixed(1)}');

    // Descanso
    final week1Rest = week1.sessions.expand((s) => s.exercises).map((e) => e.restSeconds).toList();
    final week4Rest = week4.sessions.expand((s) => s.exercises).map((e) => e.restSeconds).toList();
    final avgRest1 = week1Rest.reduce((a, b) => a + b) / week1Rest.length;
    final avgRest4 = week4Rest.reduce((a, b) => a + b) / week4Rest.length;
    print('Descanso médio: Sem1=${avgRest1.toStringAsFixed(0)}s, Sem4=${avgRest4.toStringAsFixed(0)}s');

    // Volume total
    final week1Total = week1Sets.reduce((a, b) => a + b);
    final week4Total = week4Sets.reduce((a, b) => a + b);
    print('Volume total: Sem1=$week1Total, Sem4=$week4Total séries');

    // ── Verificar coerência ──
    // Séries não devem diminuir
    expect(avgSets4, greaterThanOrEqualTo(avgSets1 - 0.5),
        reason: 'Séries não devem diminuir entre semanas');

    // RIR não deve aumentar (ficar mais fácil)
    expect(avgRir4, lessThanOrEqualTo(avgRir1 + 0.5),
        reason: 'RIR não deve aumentar significativamente');

    // Volume total não deve diminuir
    expect(week4Total, greaterThanOrEqualTo(week1Total - 4),
        reason: 'Volume total não deve diminuir significativamente');

    print('✓ Prescrição coerente entre Semana 1 e Semana 4');
  });
}

void _analyzeLongitudinal(List<GeneratedWorkout> weeks, String label) {
  print('\n--- $label: ANÁLISE LONGITUDINAL ---');

  for (var w = 0; w < weeks.length; w++) {
    final week = weeks[w];
    final totalExercises = week.sessions.expand((s) => s.exercises).length;
    final totalSets = week.sessions.expand((s) => s.exercises).map((e) => e.sets).reduce((a, b) => a + b);
    final avgRir = week.sessions.expand((s) => s.exercises).map((e) => e.rir).reduce((a, b) => a + b) / totalExercises;
    final patterns = week.sessions.expand((s) => s.exercises).map((e) => e.exercise.movementPattern).toSet();

    print('  Semana ${w + 1}: ${week.sessions.length} sessões, $totalExercises exercises, $totalSets séries, RIR ${avgRir.toStringAsFixed(1)}, ${patterns.length} padrões');
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
}
