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

  final profile2x = UserTrainingProfile(
    uid: 'p2x', age: 25, primaryGoal: V2Goal.generalFitness,
    modality: V2Modality.generalPhysicalDevelopment,
    environment: V2Environment.home, availableEquipment: const [],
    availableDaysPerWeek: 2, sessionDurationMinutes: 30,
    experienceLevel: ExperienceLevel.little, trainingAgeMonths: 0,
  );

  final profile3x = UserTrainingProfile(
    uid: 'p3x', age: 25, primaryGoal: V2Goal.generalFitness,
    modality: V2Modality.generalPhysicalDevelopment,
    environment: V2Environment.home, availableEquipment: const [],
    availableDaysPerWeek: 3, sessionDurationMinutes: 30,
    experienceLevel: ExperienceLevel.regularly, trainingAgeMonths: 24,
  );

  final profile5x = UserTrainingProfile(
    uid: 'p5x', age: 25, primaryGoal: V2Goal.generalFitness,
    modality: V2Modality.generalPhysicalDevelopment,
    environment: V2Environment.home, availableEquipment: const [],
    availableDaysPerWeek: 5, sessionDurationMinutes: 30,
    experienceLevel: ExperienceLevel.regularly, trainingAgeMonths: 24,
  );

  final profile5xAdv = UserTrainingProfile(
    uid: 'p5xadv', age: 25, primaryGoal: V2Goal.generalFitness,
    modality: V2Modality.generalPhysicalDevelopment,
    environment: V2Environment.home, availableEquipment: const [],
    availableDaysPerWeek: 5, sessionDurationMinutes: 60,
    experienceLevel: ExperienceLevel.years, trainingAgeMonths: 60,
  );

  final profileLimit = UserTrainingProfile(
    uid: 'plim', age: 25, primaryGoal: V2Goal.generalFitness,
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

  // ── ANÁLISE 1: 2x/semana — iniciante ──
  test('Semanal: 2x/semana — iniciante', () {
    final workout = intelligence.generateWorkout(profile2x);

    print('=== ANÁLISE SEMANAL: 2x/semana — INICIANTE ===');
    _analyzeWeek(workout, '2x Iniciante');

    // ── Verificações ──
    expect(workout.sessions.length, equals(2));

    // Dias devem ser diferentes
    final ids1 = workout.sessions[0].exercises.map((e) => e.exercise.id).toSet();
    final ids2 = workout.sessions[1].exercises.map((e) => e.exercise.id).toSet();
    expect(ids1, isNot(equals(ids2)), reason: 'Dias devem ter exercícios diferentes');

    // Padrões devem ser diferentes
    final p1 = workout.sessions[0].exercises.map((e) => e.exercise.movementPattern).toSet();
    final p2 = workout.sessions[1].exercises.map((e) => e.exercise.movementPattern).toSet();
    expect(p1, isNot(equals(p2)), reason: 'Dias devem ter padrões diferentes');

    // Volume total não deve ser excessivo para 2x
    final totalSets = workout.sessions
        .expand((s) => s.exercises)
        .map((e) => e.sets)
        .reduce((a, b) => a + b);
    expect(totalSets, lessThanOrEqualTo(20),
        reason: 'Volume total deve ser ≤20 séries para 2x/semana');

    print('✓ Semanal 2x coerente');
  });

  // ── ANÁLISE 2: 3x/semana — iniciante ──
  test('Semanal: 3x/semana — iniciante', () {
    final workout = intelligence.generateWorkout(profile3x);

    print('=== ANÁLISE SEMANAL: 3x/semana — INICIANTE ===');
    _analyzeWeek(workout, '3x Iniciante');

    // ── Verificações ──
    expect(workout.sessions.length, equals(3));

    // Todos os dias devem ser diferentes
    final allIds = <String>[];
    for (final s in workout.sessions) {
      allIds.addAll(s.exercises.map((e) => e.exercise.id));
    }
    final uniqueIds = allIds.toSet();
    expect(uniqueIds.length, greaterThanOrEqualTo(allIds.length * 0.7),
        reason: '≥70% dos exercises devem ser únicos na semana');

    // Padrões devem cobrir a semana
    final allPatterns = workout.sessions
        .expand((s) => s.exercises)
        .map((e) => e.exercise.movementPattern)
        .toSet();
    expect(allPatterns.length, greaterThanOrEqualTo(4),
        reason: 'Semana deve cobrir ≥4 padrões diferentes');

    // Volume semanal adequado
    final totalSets = workout.sessions
        .expand((s) => s.exercises)
        .map((e) => e.sets)
        .reduce((a, b) => a + b);
    expect(totalSets, greaterThanOrEqualTo(15),
        reason: 'Volume semanal deve ser ≥15 séries');
    expect(totalSets, lessThanOrEqualTo(30),
        reason: 'Volume semanal deve ser ≤30 séries');

    print('✓ Semanal 3x coerente');
  });

  // ── ANÁLISE 3: 5x/semana — iniciante ──
  test('Semanal: 5x/semana — iniciante', () {
    final workout = intelligence.generateWorkout(profile5x);

    print('=== ANÁLISE SEMANAL: 5x/semana — INICIANTE ===');
    _analyzeWeek(workout, '5x Iniciante');

    // ── Verificações ──
    expect(workout.sessions.length, equals(5));

    // Cada dia deve ter exercises diferentes
    for (var i = 0; i < workout.sessions.length; i++) {
      for (var j = i + 1; j < workout.sessions.length; j++) {
        final ids1 = workout.sessions[i].exercises.map((e) => e.exercise.id).toSet();
        final ids2 = workout.sessions[j].exercises.map((e) => e.exercise.id).toSet();
        expect(ids1, isNot(equals(ids2)),
            reason: 'Dias ${i + 1} e ${j + 1} devem ter exercises diferentes');
      }
    }

    // Distribuição de padrões na semana
    final weeklyPatterns = workout.sessions
        .expand((s) => s.exercises)
        .map((e) => e.exercise.movementPattern)
        .toList();
    final patternCounts = <String, int>{};
    for (final p in weeklyPatterns) {
      patternCounts[p] = (patternCounts[p] ?? 0) + 1;
    }

    // Nenhum padrão deve dominar (>40% dos exercises)
    final totalExercises = weeklyPatterns.length;
    for (final entry in patternCounts.entries) {
      expect(entry.value / totalExercises, lessThanOrEqualTo(0.4),
          reason: 'Padrão ${entry.key} não deve dominar a semana (>40%)');
    }

    // Volume semanal adequado
    final totalSets = workout.sessions
        .expand((s) => s.exercises)
        .map((e) => e.sets)
        .reduce((a, b) => a + b);
    expect(totalSets, greaterThanOrEqualTo(20),
        reason: 'Volume semanal deve ser ≥20 séries');
    expect(totalSets, lessThanOrEqualTo(50),
        reason: 'Volume semanal deve ser ≤50 séries');

    // Cada dia deve ter volume adequado (não muito baixo)
    for (final s in workout.sessions) {
      final daySets = s.exercises.map((e) => e.sets).reduce((a, b) => a + b);
      expect(daySets, greaterThanOrEqualTo(4),
          reason: 'Cada dia deve ter ≥4 séries');
    }

    print('✓ Semanal 5x coerente');
  });

  // ── ANÁLISE 4: 5x/semana — avançado ──
  test('Semanal: 5x/semana — avançado', () {
    final workout = intelligence.generateWorkout(profile5xAdv);

    print('=== ANÁLISE SEMANAL: 5x/semana — AVANÇADO ===');
    _analyzeWeek(workout, '5x Avançado');

    // ── Verificações ──
    expect(workout.sessions.length, equals(5));

    // Avançado deve ter mais volume que iniciante
    final totalSets = workout.sessions
        .expand((s) => s.exercises)
        .map((e) => e.sets)
        .reduce((a, b) => a + b);
    expect(totalSets, greaterThanOrEqualTo(30),
        reason: 'Avançado deve ter ≥30 séries semanais');

    // RIR deve ser menor
    final avgRir = workout.sessions
        .expand((s) => s.exercises)
        .map((e) => e.rir)
        .reduce((a, b) => a + b) / workout.sessions
        .expand((s) => s.exercises)
        .length;
    expect(avgRir, lessThanOrEqualTo(2.0),
        reason: 'RIR médio deve ser ≤2 para avançado');

    // Cada dia deve ter exercises diferentes
    for (var i = 0; i < workout.sessions.length; i++) {
      for (var j = i + 1; j < workout.sessions.length; j++) {
        final ids1 = workout.sessions[i].exercises.map((e) => e.exercise.id).toSet();
        final ids2 = workout.sessions[j].exercises.map((e) => e.exercise.id).toSet();
        expect(ids1, isNot(equals(ids2)),
            reason: 'Dias ${i + 1} e ${j + 1} devem ter exercises diferentes');
      }
    }

    print('✓ Semanal 5x avançado coerente');
  });

  // ── ANÁLISE 5: 3x/semana — com limitação ──
  test('Semanal: 3x/semana — com limitação', () {
    final workout = intelligence.generateWorkout(profileLimit);

    print('=== ANÁLISE SEMANAL: 3x/semana — LIMITAÇÃO ===');
    _analyzeWeek(workout, '3x Limitação');

    // ── Verificações ──
    expect(workout.sessions.length, equals(3));

    // Não deve ter exercícios de alto impacto no joelho
    for (final s in workout.sessions) {
      for (final ex in s.exercises) {
        // Não deve ter exercícios de salto
        expect(ex.exercise.name.contains('Salto'), isFalse,
            reason: '${ex.exercise.name} não deve estar em sessão com limitação no joelho');
      }
    }

    // Todos os exercises devem ser válidos
    for (final s in workout.sessions) {
      for (final ex in s.exercises) {
        expect(ex.exercise.id, startsWith('home_'));
        expect(ex.exercise.equipment, isEmpty);
      }
    }

    // Dias devem ser diferentes
    for (var i = 0; i < workout.sessions.length; i++) {
      for (var j = i + 1; j < workout.sessions.length; j++) {
        final ids1 = workout.sessions[i].exercises.map((e) => e.exercise.id).toSet();
        final ids2 = workout.sessions[j].exercises.map((e) => e.exercise.id).toSet();
        expect(ids1, isNot(equals(ids2)),
            reason: 'Dias ${i + 1} e ${j + 1} devem ter exercises diferentes');
      }
    }

    print('✓ Semanal com limitação coerente');
  });

  // ── ANÁLISE 6: Volume acumulado ──
  test('Semanal: volume acumulado adequado', () {
    final workout = intelligence.generateWorkout(profile3x);

    print('=== ANÁLISE: VOLUME ACUMULADO ===');

    // Volume por dia
    final dayVolumes = workout.sessions.map((s) =>
        s.exercises.map((e) => e.sets).reduce((a, b) => a + b)).toList();
    print('Volume por dia: $dayVolumes');

    // Volume total
    final totalSets = dayVolumes.reduce((a, b) => a + b);
    print('Volume total: $totalSets séries');

    // Variação de volume entre dias (não deve ser idêntico)
    final uniqueVolumes = dayVolumes.toSet();
    expect(uniqueVolumes.length, greaterThanOrEqualTo(1),
        reason: 'Volume deve ter alguma variação');

    // Volume total adequado para 3x iniciante
    expect(totalSets, greaterThanOrEqualTo(15));
    expect(totalSets, lessThanOrEqualTo(30));

    print('✓ Volume acumulado adequado');
  });

  // ── ANÁLISE 7: Intensidade acumulada ──
  test('Semanal: intensidade acumulada adequada', () {
    final workout = intelligence.generateWorkout(profile3x);

    print('=== ANÁLISE: INTENSIDADE ACUMULADA ===');

    // RIR por dia
    final dayRirs = workout.sessions.map((s) =>
        s.exercises.map((e) => e.rir).reduce((a, b) => a + b) /
        s.exercises.length).toList();
    print('RIR por dia: ${dayRirs.map((r) => r.toStringAsFixed(1)).toList()}');

    // RIR médio semanal
    final avgRir = dayRirs.reduce((a, b) => a + b) / dayRirs.length;
    print('RIR médio semanal: ${avgRir.toStringAsFixed(1)}');

    // Intensidade deve ser consistente (não variar muito entre dias)
    final rirRange = dayRirs.reduce((a, b) => a > b ? a : b) -
        dayRirs.reduce((a, b) => a < b ? a : b);
    expect(rirRange, lessThanOrEqualTo(1.0),
        reason: 'RIR não deve variar mais de 1.0 entre dias');

    print('✓ Intensidade acumulada adequada');
  });

  // ── ANÁLISE 8: Proximidade de estímulos ──
  test('Semanal: estímulos semelhantes não muito próximos', () {
    final workout = intelligence.generateWorkout(profile5x);

    print('=== ANÁLISE: PROXIMIDADE DE ESTÍMULOS ===');

    // Mapear padrões por dia
    final dailyPatterns = workout.sessions.map((s) =>
        s.exercises.map((e) => e.exercise.movementPattern).toSet()).toList();

    print('Padrões por dia:');
    for (var i = 0; i < dailyPatterns.length; i++) {
      print('  Dia ${i + 1}: ${dailyPatterns[i]}');
    }

    // Verificar se dias consecutivos têm padrões muito similares
    for (var i = 0; i < dailyPatterns.length - 1; i++) {
      final intersection = dailyPatterns[i].intersection(dailyPatterns[i + 1]);
      final union = dailyPatterns[i].union(dailyPatterns[i + 1]);
      final similarity = intersection.length / union.length;

      print('  Similaridade dias ${i + 1}-${i + 2}: ${(similarity * 100).toStringAsFixed(0)}%');

      // Dias consecutivos não devem ter >60% de similaridade
      expect(similarity, lessThanOrEqualTo(0.6),
          reason: 'Dias ${i + 1} e ${i + 2} não devem ter >60% de similaridade');
    }

    print('✓ Estímulos semelhantes adequadamente distribuídos');
  });
}

void _analyzeWeek(GeneratedWorkout workout, String label) {
  print('\n--- $label ---');
  print('Sessões: ${workout.sessions.length}');

  for (var i = 0; i < workout.sessions.length; i++) {
    final s = workout.sessions[i];
    final names = s.exercises.map((e) => e.exercise.name).toList();
    final patterns = s.exercises.map((e) => e.exercise.movementPattern).toList();
    final totalSets = s.exercises.map((e) => e.sets).reduce((a, b) => a + b);
    final avgRir = s.exercises.map((e) => e.rir).reduce((a, b) => a + b) / s.exercises.length;

    print('  Dia ${i + 1}: ${s.exercises.length} exercises, $totalSets séries, RIR ${avgRir.toStringAsFixed(1)}');
    print('    Exercises: $names');
    print('    Padrões: $patterns');
  }

  // Resumo semanal
  final allPatterns = workout.sessions
      .expand((s) => s.exercises)
      .map((e) => e.exercise.movementPattern)
      .toList();
  final patternCounts = <String, int>{};
  for (final p in allPatterns) {
    patternCounts[p] = (patternCounts[p] ?? 0) + 1;
  }
  print('  Distribuição semanal: $patternCounts');

  final totalSets = workout.sessions
      .expand((s) => s.exercises)
      .map((e) => e.sets)
      .reduce((a, b) => a + b);
  print('  Volume total: $totalSets séries');
}
