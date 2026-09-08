import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/workout/intelligence/user_training_profile.dart';
import 'package:app/features/workout/intelligence/training_context.dart';
import 'package:app/features/workout/intelligence/training_strategy_engine.dart';
import 'package:app/features/workout/intelligence/training_intelligence.dart';
import 'package:app/features/exercise_library_v2/v2_exercise_library.dart';
import 'package:app/features/exercise_library_v2/data/home_exercises.dart';
import 'package:app/features/exercise_library_v2/bridge/v2_home_bridge.dart';
import 'package:app/features/exercise_library_v2/enums/goal.dart';
import 'package:app/features/exercise_library_v2/enums/modality.dart';
import 'package:app/features/exercise_library_v2/enums/environment.dart';
import 'package:app/features/exercise_library_v2/enums/equipment.dart';
import 'package:app/features/exercise_library_v2/enums/joint.dart';
import 'package:app/features/exercise_library_v2/enums/limitation_severity.dart';
import 'package:app/features/exercise_library_v2/enums/difficulty.dart';
import 'package:app/features/workout/prescribed_workout_model.dart';

void main() {
  setUpAll(() {
    final library = V2ExerciseLibrary();
    library.registerAll(createHomeExercises());
    V2HomeBridge.registerAll(createHomeExercises());
  });

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
    environment: V2Environment.gym, availableEquipment: const [],
    availableDaysPerWeek: 3, sessionDurationMinutes: 60,
    experienceLevel: ExperienceLevel.years, trainingAgeMonths: 60,
  );

  final profile4 = UserTrainingProfile(
    uid: 'p4', age: 25, primaryGoal: V2Goal.generalFitness,
    modality: V2Modality.generalPhysicalDevelopment,
    environment: V2Environment.home, availableEquipment: const [],
    availableDaysPerWeek: 2, sessionDurationMinutes: 30,
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

  final intelligence = TrainingIntelligence();

  // ── TESTE 1: PERFIL 1 — Iniciante + geral + casa + 30min ──
  test('Perfil 1: iniciante + geral + casa + 30min', () {
    final workout = intelligence.generateWorkout(profile1);
    final session = workout.sessions.first;
    final exerciseNames = session.exercises.map((e) => e.exercise.name).toList();

    print('=== PERFIL 1: Iniciante + Geral + Casa + 30min ===');
    print('Sessões: ${workout.sessions.length}');
    print('Exercícios/sessão: ${session.exercises.length}');
    print('Duração estimada: ${session.estimatedDurationMinutes}min');
    print('Exercícios: $exerciseNames');
    print('Prescrição:');
    for (final ex in session.exercises) {
      print('  ${ex.exercise.name}: ${ex.sets}×${ex.repsMin}-${ex.repsMax} RIR${ex.rir} descanso${ex.restSeconds}s');
    }
    print('');

    // Verificações
    expect(workout.sessions.length, equals(3));
    expect(session.exercises.length, greaterThanOrEqualTo(3));
    expect(session.exercises.length, lessThanOrEqualTo(6));
    expect(session.estimatedDurationMinutes, lessThanOrEqualTo(40));

    // Deve ter padrões variados
    final patterns = session.exercises.map((e) => e.exercise.movementPattern).toSet();
    expect(patterns.length, greaterThanOrEqualTo(3));

    // Deve ter exercícios de casa (sem equipamento)
    for (final ex in session.exercises) {
      expect(ex.exercise.equipment, isEmpty);
    }
  });

  // ── TESTE 2: PERFIL 2 — Iniciante + condicionamento + casa + 30min ──
  test('Perfil 2: iniciante + condicionamento + casa + 30min', () {
    final workout = intelligence.generateWorkout(profile2);
    final session = workout.sessions.first;
    final exerciseNames = session.exercises.map((e) => e.exercise.name).toList();

    print('=== PERFIL 2: Iniciante + Condicionamento + Casa + 30min ===');
    print('Sessões: ${workout.sessions.length}');
    print('Exercícios/sessão: ${session.exercises.length}');
    print('Duração estimada: ${session.estimatedDurationMinutes}min');
    print('Exercícios: $exerciseNames');
    print('Prescrição:');
    for (final ex in session.exercises) {
      print('  ${ex.exercise.name}: ${ex.sets}×${ex.repsMin}-${ex.repsMax} RIR${ex.rir} descanso${ex.restSeconds}s');
    }
    print('');

    // Verificações
    expect(workout.sessions.length, equals(3));
    expect(session.exercises.length, greaterThanOrEqualTo(3));

    // Deve ter exercícios de condicionamento
    final hasConditioning = session.exercises.any((e) =>
        e.exercise.tags.contains('v2_pattern_conditioning'));
    expect(hasConditioning, isTrue, reason: 'Deve ter exercício de condicionamento');

    // Descanso deve ser mais curto que geral (condicionamento = mais denso)
    final avgRest = session.exercises.map((e) => e.restSeconds).reduce((a, b) => a + b) / session.exercises.length;
    expect(avgRest, lessThanOrEqualTo(90), reason: 'Descanso médio deve ser ≤90s para condicionamento');
  });

  // ── TESTE 3: PERFIL 3 — Avançado + hipertrofia + academia + 60min ──
  test('Perfil 3: avançado + hipertrofia + academia + 60min', () {
    final workout = intelligence.generateWorkout(profile3);
    final session = workout.sessions.first;
    final exerciseNames = session.exercises.map((e) => e.exercise.name).toList();

    print('=== PERFIL 3: Avançado + Hipertrofia + Academia + 60min ===');
    print('Sessões: ${workout.sessions.length}');
    print('Exercícios/sessão: ${session.exercises.length}');
    print('Duração estimada: ${session.estimatedDurationMinutes}min');
    print('Exercícios: $exerciseNames');
    print('Prescrição:');
    for (final ex in session.exercises) {
      print('  ${ex.exercise.name}: ${ex.sets}×${ex.repsMin}-${ex.repsMax} RIR${ex.rir} descanso${ex.restSeconds}s');
    }
    print('');

    // Verificações
    expect(workout.sessions.length, equals(3));
    expect(session.exercises.length, greaterThanOrEqualTo(5));

    // Deve ter mais exercises que iniciante (60min vs 30min)
    expect(session.exercises.length, greaterThanOrEqualTo(5));

    // Séries devem ser mais altas para hipertrofia
    final avgSets = session.exercises.map((e) => e.sets).reduce((a, b) => a + b) / session.exercises.length;
    expect(avgSets, greaterThanOrEqualTo(3), reason: 'Séries médias devem ser ≥3 para hipertrofia');
  });

  // ── TESTE 4: PERFIL 4 — Baixa frequência (2x/semana) ──
  test('Perfil 4: baixa frequência (2x/semana)', () {
    final workout = intelligence.generateWorkout(profile4);

    print('=== PERFIL 4: Baixa Frequência (2x/semana) ===');
    print('Sessões: ${workout.sessions.length}');
    for (var i = 0; i < workout.sessions.length; i++) {
      final s = workout.sessions[i];
      final names = s.exercises.map((e) => e.exercise.name).toList();
      print('  Dia ${i + 1}: ${names.length} exercícios — $names');
    }
    print('');

    // Verificações
    expect(workout.sessions.length, equals(2));

    // Dias devem ter exercícios diferentes
    final ids1 = workout.sessions[0].exercises.map((e) => e.exercise.id).toSet();
    final ids2 = workout.sessions[1].exercises.map((e) => e.exercise.id).toSet();
    expect(ids1, isNot(equals(ids2)), reason: 'Dias devem ter exercícios diferentes');
  });

  // ── TESTE 5: PERFIL 5 — Alta frequência (5x/semana) ──
  test('Perfil 5: alta frequência (5x/semana)', () {
    final workout = intelligence.generateWorkout(profile5);

    print('=== PERFIL 5: Alta Frequência (5x/semana) ===');
    print('Sessões: ${workout.sessions.length}');
    for (var i = 0; i < workout.sessions.length; i++) {
      final s = workout.sessions[i];
      final names = s.exercises.map((e) => e.exercise.name).toList();
      print('  Dia ${i + 1}: ${names.length} exercícios — $names');
    }
    print('');

    // Verificações
    expect(workout.sessions.length, equals(5));

    // Cada sessão deve ter menos exercises (diluir volume)
    final avgExercises = workout.sessions
        .map((s) => s.exercises.length)
        .reduce((a, b) => a + b) / workout.sessions.length;
    expect(avgExercises, lessThanOrEqualTo(5), reason: 'Sessões de alta frequência devem ter menos exercises');
  });

  // ── TESTE 6: PERFIL 6 — Com limitação ──
  test('Perfil 6: com limitação de joelho', () {
    final workout = intelligence.generateWorkout(profile6);
    final session = workout.sessions.first;
    final exerciseNames = session.exercises.map((e) => e.exercise.name).toList();

    print('=== PERFIL 6: Com Limitação de Joelho ===');
    print('Sessões: ${workout.sessions.length}');
    print('Exercícios/sessão: ${session.exercises.length}');
    print('Exercícios: $exerciseNames');
    print('Prescrição:');
    for (final ex in session.exercises) {
      print('  ${ex.exercise.name}: ${ex.sets}×${ex.repsMin}-${ex.repsMax} RIR${ex.rir} descanso${ex.restSeconds}s');
    }
    print('');

    // Verificações
    expect(workout.sessions.length, equals(3));
    expect(session.exercises, isNotEmpty);

    // Todos os exercícios devem ser válidos
    for (final ex in session.exercises) {
      expect(ex.exercise.id, startsWith('home_'));
      expect(ex.exercise.equipment, isEmpty);
    }
  });

  // ── TESTE DE COERÊNCIA: Iniciante vs Avançado ──
  test('Coerência: iniciante vs avançado', () {
    final beginner = UserTrainingProfile(
      uid: 'beg', age: 25, primaryGoal: V2Goal.generalFitness,
      modality: V2Modality.generalPhysicalDevelopment,
      environment: V2Environment.home, availableEquipment: const [],
      availableDaysPerWeek: 3, sessionDurationMinutes: 30,
      experienceLevel: ExperienceLevel.little, trainingAgeMonths: 0,
    );
    final advanced = UserTrainingProfile(
      uid: 'adv', age: 25, primaryGoal: V2Goal.generalFitness,
      modality: V2Modality.generalPhysicalDevelopment,
      environment: V2Environment.home, availableEquipment: const [],
      availableDaysPerWeek: 3, sessionDurationMinutes: 30,
      experienceLevel: ExperienceLevel.years, trainingAgeMonths: 60,
    );

    final w1 = intelligence.generateWorkout(beginner);
    final w2 = intelligence.generateWorkout(advanced);

    final s1 = w1.sessions.first;
    final s2 = w2.sessions.first;

    print('=== COERÊNCIA: Iniciante vs Avançado ===');
    print('Iniciante: ${s1.exercises.length} exercises, RIR médio: ${_avgRir(s1)}');
    print('Avançado: ${s2.exercises.length} exercises, RIR médio: ${_avgRir(s2)}');
    print('');

    // Avançado deve ter RIR menor (mais intenso)
    expect(_avgRir(s2), lessThanOrEqualTo(_avgRir(s1)),
        reason: 'Avançado deve ter RIR menor que iniciante');
  });

  // ── TESTE DE COERÊNCIA: 30min vs 60min ──
  test('Coerência: 30min vs 60min', () {
    final short = UserTrainingProfile(
      uid: 'short', age: 25, primaryGoal: V2Goal.generalFitness,
      modality: V2Modality.generalPhysicalDevelopment,
      environment: V2Environment.home, availableEquipment: const [],
      availableDaysPerWeek: 3, sessionDurationMinutes: 20,
      experienceLevel: ExperienceLevel.regularly, trainingAgeMonths: 24,
    );
    final long = UserTrainingProfile(
      uid: 'long', age: 25, primaryGoal: V2Goal.generalFitness,
      modality: V2Modality.generalPhysicalDevelopment,
      environment: V2Environment.home, availableEquipment: const [],
      availableDaysPerWeek: 3, sessionDurationMinutes: 60,
      experienceLevel: ExperienceLevel.regularly, trainingAgeMonths: 24,
    );

    final w1 = intelligence.generateWorkout(short);
    final w2 = intelligence.generateWorkout(long);

    final s1 = w1.sessions.first;
    final s2 = w2.sessions.first;

    print('=== COERÊNCIA: 30min vs 60min ===');
    print('20min: ${s1.exercises.length} exercises');
    print('60min: ${s2.exercises.length} exercises');
    print('');

    // 60min deve ter mais exercises
    expect(s2.exercises.length, greaterThanOrEqualTo(s1.exercises.length),
        reason: '60min deve ter ≥ exercises que 20min');
  });

  // ── TESTE DE COERÊNCIA: Geral vs Condicionamento ──
  test('Coerência: geral vs condicionamento', () {
    final general = UserTrainingProfile(
      uid: 'gen', age: 25, primaryGoal: V2Goal.generalFitness,
      modality: V2Modality.generalPhysicalDevelopment,
      environment: V2Environment.home, availableEquipment: const [],
      availableDaysPerWeek: 3, sessionDurationMinutes: 30,
      experienceLevel: ExperienceLevel.regularly, trainingAgeMonths: 24,
    );
    final conditioning = UserTrainingProfile(
      uid: 'cond', age: 25, primaryGoal: V2Goal.conditioning,
      modality: V2Modality.conditioning,
      environment: V2Environment.home, availableEquipment: const [],
      availableDaysPerWeek: 3, sessionDurationMinutes: 30,
      experienceLevel: ExperienceLevel.regularly, trainingAgeMonths: 24,
    );

    final w1 = intelligence.generateWorkout(general);
    final w2 = intelligence.generateWorkout(conditioning);

    final s1 = w1.sessions.first;
    final s2 = w2.sessions.first;

    print('=== COERÊNCIA: Geral vs Condicionamento ===');
    print('Geral: ${s1.exercises.map((e) => e.exercise.movementPattern).toSet()}');
    print('Condicionamento: ${s2.exercises.map((e) => e.exercise.movementPattern).toSet()}');
    print('Geral RIR: ${_avgRir(s1)}, Condicionamento RIR: ${_avgRir(s2)}');
    print('');

    // Devem ter padrões diferentes
    final patterns1 = s1.exercises.map((e) => e.exercise.movementPattern).toSet();
    final patterns2 = s2.exercises.map((e) => e.exercise.movementPattern).toSet();
    expect(patterns1, isNot(equals(patterns2)),
        reason: 'Geral e condicionamento devem ter padrões diferentes');
  });

  // ── TESTE DE COERÊNCIA: Sem limitação vs Com limitação ──
  test('Coerência: sem limitação vs com limitação', () {
    final noLimit = UserTrainingProfile(
      uid: 'nolim', age: 25, primaryGoal: V2Goal.generalFitness,
      modality: V2Modality.generalPhysicalDevelopment,
      environment: V2Environment.home, availableEquipment: const [],
      availableDaysPerWeek: 3, sessionDurationMinutes: 30,
      experienceLevel: ExperienceLevel.regularly, trainingAgeMonths: 24,
    );
    final withLimit = UserTrainingProfile(
      uid: 'withlim', age: 25, primaryGoal: V2Goal.generalFitness,
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

    final w1 = intelligence.generateWorkout(noLimit);
    final w2 = intelligence.generateWorkout(withLimit);

    final s1 = w1.sessions.first;
    final s2 = w2.sessions.first;

    print('=== COERÊNCIA: Sem vs Com Limitação ===');
    print('Sem: ${s1.exercises.map((e) => e.exercise.name).toList()}');
    print('Com: ${s2.exercises.map((e) => e.exercise.name).toList()}');
    print('');

    // Ambos devem gerar treinos válidos
    expect(s1.exercises, isNotEmpty);
    expect(s2.exercises, isNotEmpty);
  });
}

double _avgRir(PrescribedSession session) {
  if (session.exercises.isEmpty) return 0;
  return session.exercises.map((e) => e.rir).reduce((a, b) => a + b) / session.exercises.length;
}
