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
    uid: 'p3', age: 25, primaryGoal: V2Goal.hypertrophy,
    modality: V2Modality.hypertrophy,
    environment: V2Environment.home, availableEquipment: const [],
    availableDaysPerWeek: 3, sessionDurationMinutes: 60,
    experienceLevel: ExperienceLevel.years, trainingAgeMonths: 60,
  );

  final profile4 = UserTrainingProfile(
    uid: 'p4', age: 25, primaryGoal: V2Goal.generalFitness,
    modality: V2Modality.generalPhysicalDevelopment,
    environment: V2Environment.home, availableEquipment: const [],
    availableDaysPerWeek: 3, sessionDurationMinutes: 30,
    experienceLevel: ExperienceLevel.regularly, trainingAgeMonths: 24,
  );

  final profile5 = UserTrainingProfile(
    uid: 'p5', age: 25, primaryGoal: V2Goal.generalFitness,
    modality: V2Modality.generalPhysicalDevelopment,
    environment: V2Environment.home, availableEquipment: const [],
    availableDaysPerWeek: 5, sessionDurationMinutes: 30,
    experienceLevel: ExperienceLevel.regularly, trainingAgeMonths: 24,
  );

  final profile6 = UserTrainingProfile(
    uid: 'p6', age: 25, primaryGoal: V2Goal.generalFitness,
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

  // ── ANÁLISE 1: PERFIL 1 — Geral ──
  test('Composição: Perfil 1 (geral) — sessão coerente', () {
    final workout = intelligence.generateWorkout(profile1);
    final session = workout.sessions.first;

    print('=== ANÁLISE DE COMPOSIÇÃO: PERFIL 1 (GERAL) ===');
    _analyzeSession(session, 'Perfil 1');

    // ── Distribuição de padrões ──
    final patterns = session.exercises.map((e) => e.exercise.movementPattern).toList();
    final patternCounts = <String, int>{};
    for (final p in patterns) {
      patternCounts[p] = (patternCounts[p] ?? 0) + 1;
    }

    // Não deve ter mais de 1 exercício do mesmo padrão
    for (final count in patternCounts.values) {
      expect(count, lessThanOrEqualTo(1),
          reason: 'Nenhum padrão deve repetir na sessão');
    }

    // ── Distribuição de regiões corporais ──
    final muscles = session.exercises
        .expand((e) => e.exercise.primaryMuscles)
        .toList();
    final muscleSet = muscles.toSet();

    // Deve ter músculos de pelo menos 2 regiões diferentes
    expect(muscleSet.length, greaterThanOrEqualTo(2),
        reason: 'Deve trabalhar múltiplas regiões');

    // ── Papéis ──
    // Sessão de 30min com 3 exercises: todos principais
    expect(session.exercises.length, equals(3));

    // ── Sequência ──
    // Deve começar com exercício mais complexo e terminar com menos
    final firstExercise = session.exercises.first;
    final lastExercise = session.exercises.last;

    // Primeiro exercício deve ser compound
    expect(firstExercise.exercise.category, equals('compound'),
        reason: 'Primeiro exercício deve ser compound');

    // ── Volume total ──
    final totalSets = session.exercises.map((e) => e.sets).reduce((a, b) => a + b);
    expect(totalSets, greaterThanOrEqualTo(6),
        reason: 'Volume total deve ser ≥6 séries');
    expect(totalSets, lessThanOrEqualTo(12),
        reason: 'Volume total deve ser ≤12 séries para 30min');

    // ── Estímulos ──
    final hasStrength = session.exercises.any((e) =>
        e.exercise.tags.contains('v2_pattern_squat') ||
        e.exercise.tags.contains('v2_pattern_push_horizontal'));
    expect(hasStrength, isTrue, reason: 'Deve ter estímulo de força');

    print('✓ Composição do Perfil 1 é coerente');
  });

  // ── ANÁLISE 2: PERFIL 2 — Condicionamento ──
  test('Composição: Perfil 2 (condicionamento) — sessão coerente', () {
    final workout = intelligence.generateWorkout(profile2);
    final session = workout.sessions.first;

    print('=== ANÁLISE DE COMPOSIÇÃO: PERFIL 2 (CONDICIONAMENTO) ===');
    _analyzeSession(session, 'Perfil 2');

    // ── Deve ter exercício de condicionamento ──
    final hasConditioning = session.exercises.any((e) =>
        e.exercise.tags.contains('v2_pattern_conditioning'));
    expect(hasConditioning, isTrue,
        reason: 'Sessão de condicionamento deve ter exercício de condicionamento');

    // ── Descanso deve ser mais curto ──
    final avgRest = session.exercises
        .map((e) => e.restSeconds)
        .reduce((a, b) => a + b) / session.exercises.length;
    expect(avgRest, lessThanOrEqualTo(90),
        reason: 'Descanso médio deve ser ≤90s para condicionamento');

    // ── Volume deve ser adequado ──
    final totalSets = session.exercises.map((e) => e.sets).reduce((a, b) => a + b);
    expect(totalSets, greaterThanOrEqualTo(8),
        reason: 'Volume deve ser ≥8 séries para condicionamento');
    expect(totalSets, lessThanOrEqualTo(12),
        reason: 'Volume deve ser ≤12 séries para 30min');

    print('✓ Composição do Perfil 2 é coerente');
  });

  // ── ANÁLISE 3: PERFIL 3 — Hipertrofia ──
  test('Composição: Perfil 3 (hipertrofia) — sessão coerente', () {
    final workout = intelligence.generateWorkout(profile3);
    final session = workout.sessions.first;

    print('=== ANÁLISE DE COMPOSIÇÃO: PERFIL 3 (HIPERTROFIA) ===');
    _analyzeSession(session, 'Perfil 3');

    // ── Deve ter mais exercises e séries ──
    expect(session.exercises.length, greaterThanOrEqualTo(5),
        reason: 'Hipertrofia deve ter ≥5 exercises');

    final totalSets = session.exercises.map((e) => e.sets).reduce((a, b) => a + b);
    expect(totalSets, greaterThanOrEqualTo(15),
        reason: 'Hipertrofia deve ter ≥15 séries totais');

    // ── RIR deve ser adequado ──
    final avgRir = session.exercises
        .map((e) => e.rir)
        .reduce((a, b) => a + b) / session.exercises.length;
    expect(avgRir, lessThanOrEqualTo(2),
        reason: 'RIR médio deve ser ≤2 para hipertrofia');

    // ── Deve ter padrões variados ──
    final patterns = session.exercises.map((e) => e.exercise.movementPattern).toSet();
    expect(patterns.length, greaterThanOrEqualTo(3),
        reason: 'Deve ter ≥3 padrões diferentes');

    // ── Distribuição de regiões ──
    final muscles = session.exercises
        .expand((e) => e.exercise.primaryMuscles)
        .toSet();
    expect(muscles.length, greaterThanOrEqualTo(4),
        reason: 'Deve trabalhar ≥4 músculos diferentes');

    print('✓ Composição do Perfil 3 é coerente');
  });

  // ── ANÁLISE 4: PERFIL 4 — Baixa frequência ──
  test('Composição: Perfil 4 (baixa frequência) — dias diferentes', () {
    final workout = intelligence.generateWorkout(profile4);

    print('=== ANÁLISE DE COMPOSIÇÃO: PERFIL 4 (BAIXA FREQUÊNCIA) ===');

    // ── Dias devem ser diferentes ──
    final patterns1 = workout.sessions[0].exercises
        .map((e) => e.exercise.movementPattern).toSet();
    final patterns2 = workout.sessions[1].exercises
        .map((e) => e.exercise.movementPattern).toSet();

    print('Dia 1 padrões: $patterns1');
    print('Dia 2 padrões: $patterns2');

    // Padrões não devem ser idênticos
    expect(patterns1, isNot(equals(patterns2)),
        reason: 'Dias devem ter padrões diferentes');

    // ── Cada dia deve ser coerente ──
    for (var i = 0; i < workout.sessions.length; i++) {
      final session = workout.sessions[i];
      _analyzeSession(session, 'Perfil 4 Dia ${i + 1}');

      // Cada dia deve ter ≥2 padrões
      final patterns = session.exercises
          .map((e) => e.exercise.movementPattern).toSet();
      expect(patterns.length, greaterThanOrEqualTo(2),
          reason: 'Dia ${i + 1} deve ter ≥2 padrões');
    }

    print('✓ Composição do Perfil 4 é coerente');
  });

  // ── ANÁLISE 5: PERFIL 5 — Alta frequência ──
  test('Composição: Perfil 5 (alta frequência) — distribuição semanal', () {
    final workout = intelligence.generateWorkout(profile5);

    print('=== ANÁLISE DE COMPOSIÇÃO: PERFIL 5 (ALTA FREQUÊNCIA) ===');

    // ── Todos os dias devem ser diferentes ──
    final allPatterns = <String>[];
    for (var i = 0; i < workout.sessions.length; i++) {
      final patterns = workout.sessions[i].exercises
          .map((e) => e.exercise.movementPattern).toList();
      allPatterns.addAll(patterns);
      print('Dia ${i + 1}: $patterns');
    }

    // ── Distribuição semanal de padrões ──
    final patternCounts = <String, int>{};
    for (final p in allPatterns) {
      patternCounts[p] = (patternCounts[p] ?? 0) + 1;
    }

    print('Distribuição semanal: $patternCounts');

    // Nenhum padrão deve dominar (>50% dos exercícios)
    final totalExercises = allPatterns.length;
    for (final entry in patternCounts.entries) {
      expect(entry.value / totalExercises, lessThanOrEqualTo(0.5),
          reason: 'Padrão ${entry.key} não deve dominar a semana');
    }

    // ── Cada dia deve ter exercícios diferentes ──
    for (var i = 0; i < workout.sessions.length; i++) {
      final ids = workout.sessions[i].exercises
          .map((e) => e.exercise.id).toSet();
      for (var j = i + 1; j < workout.sessions.length; j++) {
        final ids2 = workout.sessions[j].exercises
            .map((e) => e.exercise.id).toSet();
        expect(ids, isNot(equals(ids2)),
            reason: 'Dias ${i + 1} e ${j + 1} devem ter exercícios diferentes');
      }
    }

    print('✓ Composição do Perfil 5 é coerente');
  });

  // ── ANÁLISE 6: PERFIL 6 — Com limitação ──
  test('Composição: Perfil 6 (limitação) — sessão válida', () {
    final workout = intelligence.generateWorkout(profile6);
    final session = workout.sessions.first;

    print('=== ANÁLISE DE COMPOSIÇÃO: PERFIL 6 (LIMITAÇÃO) ===');
    _analyzeSession(session, 'Perfil 6');

    // ── Não deve ter exercícios que sobrecarreguem o joelho ──
    final hasHighImpact = session.exercises.any((e) =>
        e.exercise.tags.contains('v2_pattern_conditioning') &&
        e.exercise.name.contains('Salto'));
    expect(hasHighImpact, isFalse,
        reason: 'Não deve ter exercícios de salto com limitação no joelho');

    // ── Deve ter exercícios compatíveis ──
    for (final ex in session.exercises) {
      expect(ex.exercise.equipment, isEmpty,
          reason: '${ex.exercise.name} deve ser bodyweight');
    }

    // ── Sessão deve ser coerente ──
    _analyzeSession(session, 'Perfil 6');

    print('✓ Composição do Perfil 6 é coerente');
  });

  // ── ANÁLISE 7: NÃO REDUNDÂNCIA ──
  test('Composição: nenhum exercício redundante', () {
    final workout = intelligence.generateWorkout(profile1);
    final session = workout.sessions.first;

    print('=== ANÁLISE: REDUNDÂNCIA ===');

    // ── Verificar redundância de padrão ──
    final patterns = session.exercises
        .map((e) => e.exercise.movementPattern).toList();
    final patternCounts = <String, int>{};
    for (final p in patterns) {
      patternCounts[p] = (patternCounts[p] ?? 0) + 1;
    }

    for (final entry in patternCounts.entries) {
      expect(entry.value, equals(1),
          reason: 'Padrão ${entry.key} não deve repetir');
    }

    // ── Verificar redundância muscular ──
    final primaryMuscles = session.exercises
        .expand((e) => e.exercise.primaryMuscles)
        .toList();
    final muscleCounts = <String, int>{};
    for (final m in primaryMuscles) {
      muscleCounts[m] = (muscleCounts[m] ?? 0) + 1;
    }

    // Músculo principal não deve trabalhar em mais de 2 exercises
    for (final entry in muscleCounts.entries) {
      expect(entry.value, lessThanOrEqualTo(2),
          reason: 'Músculo ${entry.key} não deve trabalhar em >2 exercises');
    }

    print('✓ Nenhuma redundância detectada');
  });

  // ── ANÁLISE 8: SEQUÊNCIA ──
  test('Composição: sequência lógica', () {
    final workout = intelligence.generateWorkout(profile3);
    final session = workout.sessions.first;

    print('=== ANÁLISE: SEQUÊNCIA ===');

    // ── Primeiro exercício deve ser compound ──
    expect(session.exercises.first.exercise.category, equals('compound'),
        reason: 'Primeiro exercício deve ser compound');

    // ── Último exercício pode ser isolation ou core ──
    final lastCategory = session.exercises.last.exercise.category;
    final lastTags = session.exercises.last.exercise.tags;
    final isCoreOrIsolation = lastCategory == 'isolation' ||
        lastTags.any((t) => t.contains('core'));
    expect(isCoreOrIsolation, isTrue,
        reason: 'Último exercício deve ser isolation ou core');

    print('✓ Sequência lógica confirmada');
  });
}

void _analyzeSession(PrescribedSession session, String label) {
  print('\n--- $label ---');
  print('Exercícios: ${session.exercises.length}');
  print('Duração estimada: ${session.estimatedDurationMinutes}min');

  // Padrões
  final patterns = session.exercises
      .map((e) => e.exercise.movementPattern).toList();
  print('Padrões: $patterns');

  // Músculos principais
  final muscles = session.exercises
      .expand((e) => e.exercise.primaryMuscles).toSet().toList();
  print('Músculos: $muscles');

  // Volume
  final totalSets = session.exercises.map((e) => e.sets).reduce((a, b) => a + b);
  print('Total séries: $totalSets');

  // RIR
  final avgRir = session.exercises
      .map((e) => e.rir).reduce((a, b) => a + b) / session.exercises.length;
  print('RIR médio: ${avgRir.toStringAsFixed(1)}');

  // Descanso
  final avgRest = session.exercises
      .map((e) => e.restSeconds).reduce((a, b) => a + b) / session.exercises.length;
  print('Descanso médio: ${avgRest.toStringAsFixed(0)}s');

  // Categorias
  final categories = session.exercises
      .map((e) => e.exercise.category).toList();
  print('Categorias: $categories');
}
