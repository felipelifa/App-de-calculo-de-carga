import 'dart:math';
import '../exercises/exercise_model.dart';
import 'workout_profile_model.dart';
import 'prescribed_workout_model.dart';
import 'session_fatigue_accumulator.dart';
import 'exercise_compatibility.dart';
import '../../core/data/exercise_library.dart';

// ═══════════════════════════════════════════════════════════════
// SPORT & MODALITY PLAN BUILDERS
//
// Dimensão 1 (Modalidades) + Dimensão 2 (Objetivos Esportivos)
// + Dimensão 7 (Planos Temáticos)
//
// Cada builder retorna List<PrescribedSession> pronto para o
// GeneratedWorkout do motor principal.
// ═══════════════════════════════════════════════════════════════

class SportPlanBuilders {
  final List<ExerciseModel> _library;
  final int _seed;

  SportPlanBuilders(this._library, this._seed);

  // ── CORRIDA ──────────────────────────────────────────────────

  List<PrescribedSession> buildRunningPlan(WorkoutProfile profile) {
    final sub = profile.sportSubType;
    final days = profile.availableDaysPerWeek.clamp(2, 4);

    // Configurações por distância
    final config = _runningConfig(sub);

    final sessions = <PrescribedSession>[];
    final tags = ['A', 'B', 'C', 'D'];

    for (int i = 0; i < days; i++) {
      final isA = i.isEven;
      final fatigue = SessionFatigueAccumulator();
      final exercises = <PrescribedExercise>[];

      // Exercícios obrigatórios para corredor
      // 1. Glúteo unilateral (estabilidade pélvica)
      _addIfFound(
        exercises,
        profile,
        fatigue,
        muscle: 'glutes',
        pattern: 'hinge',
        isUnilateral: true,
        sets: config.sets,
        repsMin: config.repsMin,
        repsMax: config.repsMax,
        slot: i,
        rir: config.rir,
        rest: config.rest,
      );

      // 2. Quads unilateral (propulsão)
      _addIfFound(
        exercises,
        profile,
        fatigue,
        muscle: 'quads',
        pattern: 'squat',
        isUnilateral: true,
        sets: config.sets,
        repsMin: config.repsMin,
        repsMax: config.repsMax,
        slot: i + 10,
        rir: config.rir,
        rest: config.rest,
      );

      // 3. Panturrilha (prevenção canelite + propulsão)
      _addIfFound(
        exercises,
        profile,
        fatigue,
        muscle: 'calves',
        pattern: 'isolation',
        sets: config.sets + 1,
        repsMin: 15,
        repsMax: 25,
        slot: i,
        rir: 1,
        rest: 45,
      );

      // 4. Core anti-rotação (postura na corrida)
      _addIfFound(
        exercises,
        profile,
        fatigue,
        muscle: 'abs',
        pattern: 'isolation',
        sets: 3,
        repsMin: 12,
        repsMax: 15,
        slot: i,
        rir: 2,
        rest: 45,
      );

      // 5. Posterior de coxa (prevenção lesão hamstring)
      _addIfFound(
        exercises,
        profile,
        fatigue,
        muscle: 'hamstrings',
        pattern: 'hinge',
        sets: config.sets,
        repsMin: config.repsMin,
        repsMax: config.repsMax,
        slot: i + 5,
        rir: config.rir,
        rest: config.rest,
      );

      // 6. Para sessões B: upper body de manutenção
      if (!isA && profile.sessionDurationMinutes >= 45) {
        _addIfFound(
          exercises,
          profile,
          fatigue,
          muscle: 'back',
          pattern: 'pull_horizontal',
          sets: 2,
          repsMin: 10,
          repsMax: 15,
          slot: i,
          rir: 3,
          rest: 60,
        );
        _addIfFound(
          exercises,
          profile,
          fatigue,
          muscle: 'chest',
          pattern: 'push_horizontal',
          sets: 2,
          repsMin: 10,
          repsMax: 15,
          slot: i,
          rir: 3,
          rest: 60,
        );
      }

      // 7. Mobilidade de quadril e tornozelo
      _addMobilityBlock(exercises, profile, ['hip', 'ankle'], slot: i);

      sessions.add(
        PrescribedSession(
          id: 'session_run_${tags[i]}',
          name: 'Corrida — Força ${tags[i]} (${config.label})',
          objective: config.objective,
          estimatedDurationMinutes: profile.sessionDurationMinutes,
          warmupInstructions: [
            '5 min trote leve ou bike',
            'Mobilidade de quadril: círculos 2x10/lado',
            'Ativação glútea: ponte 2x15',
            'Skipping A e B: 2x20m',
          ],
          exercises: exercises,
          progressionNote: config.progressionNote,
        ),
      );
    }
    return sessions;
  }

  // ── FUTEBOL / BASQUETE / AGILIDADE ──────────────────────────

  List<PrescribedSession> buildFieldSportPlan(WorkoutProfile profile) {
    final sub = profile.sportSubType;
    final days = profile.availableDaysPerWeek.clamp(2, 4);
    final sessions = <PrescribedSession>[];

    // Sessão A: Força + Potência
    final fatigueA = SessionFatigueAccumulator();
    final exA = <PrescribedExercise>[];

    // Agachamento composto (base de força)
    _addIfFound(
      exA,
      profile,
      fatigueA,
      muscle: 'quads',
      pattern: 'squat',
      sets: 4,
      repsMin: 4,
      repsMax: 6,
      slot: 0,
      rir: 1,
      rest: 180,
    );
    // Levantamento terra (cadeia posterior)
    _addIfFound(
      exA,
      profile,
      fatigueA,
      muscle: 'hamstrings',
      pattern: 'hinge',
      sets: 4,
      repsMin: 4,
      repsMax: 6,
      slot: 0,
      rir: 1,
      rest: 180,
    );
    // Salto/explosão (pliometria)
    _addIfFound(
      exA,
      profile,
      fatigueA,
      muscle: 'quads',
      pattern: 'squat',
      preferTags: ['explosive'],
      sets: 4,
      repsMin: 5,
      repsMax: 8,
      slot: 1,
      rir: 3,
      rest: 120,
      tempo: 'explosive',
    );
    // Core anti-rotação
    _addIfFound(
      exA,
      profile,
      fatigueA,
      muscle: 'abs',
      pattern: 'isolation',
      sets: 3,
      repsMin: 10,
      repsMax: 15,
      slot: 0,
      rir: 2,
      rest: 60,
    );
    // Panturrilha
    _addIfFound(
      exA,
      profile,
      fatigueA,
      muscle: 'calves',
      pattern: 'isolation',
      sets: 3,
      repsMin: 12,
      repsMax: 20,
      slot: 0,
      rir: 1,
      rest: 45,
    );

    sessions.add(
      PrescribedSession(
        id: 'session_sport_a',
        name: '${_sportLabel(sub)} — NSCA Dia Explosivo/Força',
        objective:
            'Bompa Fase de Conversão: Força explosiva e potência para ${_sportLabel(sub)}',
        estimatedDurationMinutes: profile.sessionDurationMinutes,
        warmupInstructions: _sportWarmup(sub),
        exercises: exA,
        progressionNote:
            'NSCA Guidelines: Execute os saltos/Cleans com explosão máxima. Adicione carga apenas quando a velocidade do movimento for dominada (RIR >= 2).',
      ),
    );

    // Sessão B: Agilidade + Prevenção
    final fatigueB = SessionFatigueAccumulator();
    final exB = <PrescribedExercise>[];

    // Glúteo unilateral (estabilidade lateral)
    _addIfFound(
      exB,
      profile,
      fatigueB,
      muscle: 'glutes',
      pattern: 'hinge',
      isUnilateral: true,
      sets: 3,
      repsMin: 8,
      repsMax: 12,
      slot: 1,
      rir: 2,
      rest: 90,
    );
    // Quads unilateral (agilidade/mudança de direção)
    _addIfFound(
      exB,
      profile,
      fatigueB,
      muscle: 'quads',
      pattern: 'squat',
      isUnilateral: true,
      sets: 3,
      repsMin: 8,
      repsMax: 12,
      slot: 1,
      rir: 2,
      rest: 90,
    );
    // Upper push (equilíbrio)
    _addIfFound(
      exB,
      profile,
      fatigueB,
      muscle: 'chest',
      pattern: 'push_horizontal',
      sets: 3,
      repsMin: 8,
      repsMax: 12,
      slot: 1,
      rir: 2,
      rest: 90,
    );
    // Upper pull
    _addIfFound(
      exB,
      profile,
      fatigueB,
      muscle: 'back',
      pattern: 'pull_vertical',
      sets: 3,
      repsMin: 8,
      repsMax: 12,
      slot: 1,
      rir: 2,
      rest: 90,
    );
    // Core rotacional
    _addIfFound(
      exB,
      profile,
      fatigueB,
      muscle: 'abs',
      pattern: 'isolation',
      preferTags: ['rotation'],
      sets: 3,
      repsMin: 10,
      repsMax: 15,
      slot: 1,
      rir: 2,
      rest: 60,
    );
    // Prevenção: posterior
    _addIfFound(
      exB,
      profile,
      fatigueB,
      muscle: 'hamstrings',
      pattern: 'isolation',
      sets: 3,
      repsMin: 12,
      repsMax: 15,
      slot: 1,
      rir: 2,
      rest: 60,
    );

    sessions.add(
      PrescribedSession(
        id: 'session_sport_b',
        name: '${_sportLabel(sub)} — Agilidade & Prevenção',
        objective:
            'Estabilidade unilateral e prevenção de lesões para ${_sportLabel(sub)}',
        estimatedDurationMinutes: profile.sessionDurationMinutes,
        warmupInstructions: _sportWarmup(sub),
        exercises: exB,
        progressionNote:
            'Exercícios unilaterais: corrija desequilíbrios. Use o lado fraco como referência de carga.',
      ),
    );

    // Sessão C: Upper (se 3+ dias)
    if (days >= 3) {
      final fatigueC = SessionFatigueAccumulator();
      final exC = <PrescribedExercise>[];

      _addIfFound(
        exC,
        profile,
        fatigueC,
        muscle: 'shoulders',
        pattern: 'push_vertical',
        sets: 3,
        repsMin: 8,
        repsMax: 12,
        slot: 2,
        rir: 2,
        rest: 90,
      );
      _addIfFound(
        exC,
        profile,
        fatigueC,
        muscle: 'back',
        pattern: 'pull_horizontal',
        sets: 3,
        repsMin: 8,
        repsMax: 12,
        slot: 2,
        rir: 2,
        rest: 90,
      );
      _addIfFound(
        exC,
        profile,
        fatigueC,
        muscle: 'biceps',
        pattern: 'isolation',
        sets: 2,
        repsMin: 10,
        repsMax: 15,
        slot: 2,
        rir: 2,
        rest: 60,
      );
      _addIfFound(
        exC,
        profile,
        fatigueC,
        muscle: 'triceps',
        pattern: 'isolation',
        sets: 2,
        repsMin: 10,
        repsMax: 15,
        slot: 2,
        rir: 2,
        rest: 60,
      );

      sessions.add(
        PrescribedSession(
          id: 'session_sport_c',
          name: '${_sportLabel(sub)} — Superior Complementar',
          objective: 'Manutenção de upper body e equilíbrio muscular',
          estimatedDurationMinutes: profile.sessionDurationMinutes,
          warmupInstructions: _sportWarmup(sub),
          exercises: exC,
          progressionNote:
              'Volume moderado para manutenção. Não deve competir com recuperação das sessões de campo.',
        ),
      );
    }

    return sessions;
  }

  // ── NATAÇÃO ───────────────────────────────────────────────────

  List<PrescribedSession> buildSwimmingPlan(WorkoutProfile profile) {
    final sessions = <PrescribedSession>[];

    // Sessão A: Pull dominante (costas, dorsais, rotadores)
    final fatigueA = SessionFatigueAccumulator();
    final exA = <PrescribedExercise>[];

    _addIfFound(
      exA,
      profile,
      fatigueA,
      muscle: 'back',
      pattern: 'pull_vertical',
      sets: 4,
      repsMin: 8,
      repsMax: 12,
      slot: 0,
      rir: 2,
      rest: 90,
    );
    _addIfFound(
      exA,
      profile,
      fatigueA,
      muscle: 'back',
      pattern: 'pull_horizontal',
      sets: 3,
      repsMin: 10,
      repsMax: 12,
      slot: 0,
      rir: 2,
      rest: 90,
    );
    _addIfFound(
      exA,
      profile,
      fatigueA,
      muscle: 'shoulders',
      pattern: 'isolation',
      preferTags: ['rotation'],
      sets: 3,
      repsMin: 15,
      repsMax: 20,
      slot: 0,
      rir: 3,
      rest: 45,
    );
    _addIfFound(
      exA,
      profile,
      fatigueA,
      muscle: 'abs',
      pattern: 'isolation',
      sets: 3,
      repsMin: 12,
      repsMax: 20,
      slot: 0,
      rir: 2,
      rest: 45,
    );

    sessions.add(
      PrescribedSession(
        id: 'session_swim_a',
        name: 'Natação — Pull & Rotadores',
        objective: 'Força de tração e saúde do manguito rotador para natação',
        estimatedDurationMinutes: profile.sessionDurationMinutes,
        warmupInstructions: [
          '5 min cardio leve',
          'Rotação de ombro com elástico: 2x15',
          'Face pull leve: 2x12',
          'Mobilidade torácica: 2x10',
        ],
        exercises: exA,
        progressionNote:
            'Priorize ROM completa. Rotadores: nunca aumente carga se sentir desconforto no ombro.',
      ),
    );

    // Sessão B: Push + Lower
    final fatigueB = SessionFatigueAccumulator();
    final exB = <PrescribedExercise>[];

    _addIfFound(
      exB,
      profile,
      fatigueB,
      muscle: 'chest',
      pattern: 'push_horizontal',
      sets: 3,
      repsMin: 8,
      repsMax: 12,
      slot: 1,
      rir: 2,
      rest: 90,
    );
    _addIfFound(
      exB,
      profile,
      fatigueB,
      muscle: 'shoulders',
      pattern: 'push_vertical',
      sets: 3,
      repsMin: 8,
      repsMax: 12,
      slot: 1,
      rir: 2,
      rest: 90,
    );
    _addIfFound(
      exB,
      profile,
      fatigueB,
      muscle: 'quads',
      pattern: 'squat',
      sets: 3,
      repsMin: 10,
      repsMax: 15,
      slot: 1,
      rir: 2,
      rest: 90,
    );
    _addIfFound(
      exB,
      profile,
      fatigueB,
      muscle: 'glutes',
      pattern: 'hinge',
      sets: 3,
      repsMin: 10,
      repsMax: 15,
      slot: 1,
      rir: 2,
      rest: 90,
    );
    _addIfFound(
      exB,
      profile,
      fatigueB,
      muscle: 'calves',
      pattern: 'isolation',
      sets: 3,
      repsMin: 15,
      repsMax: 20,
      slot: 1,
      rir: 1,
      rest: 45,
    );

    sessions.add(
      PrescribedSession(
        id: 'session_swim_b',
        name: 'Natação — Push & Pernas',
        objective: 'Força de propulsão e pernada para natação',
        estimatedDurationMinutes: profile.sessionDurationMinutes,
        warmupInstructions: [
          '5 min cardio leve',
          'Mobilidade de ombro: 2x15',
          '1 série leve do primeiro exercício',
        ],
        exercises: exB,
        progressionNote:
            'Panturrilha e glúteos são fundamentais para a pernada. Priorize contração completa.',
      ),
    );

    return sessions;
  }

  // ── CICLISMO ──────────────────────────────────────────────────

  List<PrescribedSession> buildCyclingPlan(WorkoutProfile profile) {
    final sessions = <PrescribedSession>[];

    final fatigueA = SessionFatigueAccumulator();
    final exA = <PrescribedExercise>[];

    // Quads pesado
    _addIfFound(
      exA,
      profile,
      fatigueA,
      muscle: 'quads',
      pattern: 'squat',
      sets: 4,
      repsMin: 6,
      repsMax: 10,
      slot: 0,
      rir: 2,
      rest: 120,
    );
    // Glúteo unilateral
    _addIfFound(
      exA,
      profile,
      fatigueA,
      muscle: 'glutes',
      pattern: 'hinge',
      isUnilateral: true,
      sets: 3,
      repsMin: 8,
      repsMax: 12,
      slot: 0,
      rir: 2,
      rest: 90,
    );
    // Posterior (equilíbrio quad/ham)
    _addIfFound(
      exA,
      profile,
      fatigueA,
      muscle: 'hamstrings',
      pattern: 'hinge',
      sets: 3,
      repsMin: 8,
      repsMax: 12,
      slot: 0,
      rir: 2,
      rest: 90,
    );
    // Core (postura na bike)
    _addIfFound(
      exA,
      profile,
      fatigueA,
      muscle: 'abs',
      pattern: 'isolation',
      sets: 3,
      repsMin: 15,
      repsMax: 20,
      slot: 0,
      rir: 2,
      rest: 45,
    );
    // Panturrilha
    _addIfFound(
      exA,
      profile,
      fatigueA,
      muscle: 'calves',
      pattern: 'isolation',
      sets: 3,
      repsMin: 15,
      repsMax: 25,
      slot: 0,
      rir: 1,
      rest: 45,
    );

    sessions.add(
      PrescribedSession(
        id: 'session_cycling_a',
        name: 'Ciclismo — Força de Pedal',
        objective: 'Força de propulsão e resistência para ciclismo',
        estimatedDurationMinutes: profile.sessionDurationMinutes,
        warmupInstructions: [
          '5 min bike leve',
          'Mobilidade de quadril: 2x10/lado',
          'Ativação glútea: ponte 2x15',
        ],
        exercises: exA,
        progressionNote:
            'Foco em fase excêntrica controlada. Quads e glúteos são os motores primários da pedalada.',
      ),
    );

    // Upper de manutenção
    if (profile.availableDaysPerWeek >= 2) {
      final fatigueB = SessionFatigueAccumulator();
      final exB = <PrescribedExercise>[];

      _addIfFound(
        exB,
        profile,
        fatigueB,
        muscle: 'back',
        pattern: 'pull_horizontal',
        sets: 3,
        repsMin: 10,
        repsMax: 15,
        slot: 1,
        rir: 2,
        rest: 90,
      );
      _addIfFound(
        exB,
        profile,
        fatigueB,
        muscle: 'chest',
        pattern: 'push_horizontal',
        sets: 3,
        repsMin: 10,
        repsMax: 15,
        slot: 1,
        rir: 2,
        rest: 90,
      );
      _addIfFound(
        exB,
        profile,
        fatigueB,
        muscle: 'shoulders',
        pattern: 'push_vertical',
        sets: 2,
        repsMin: 10,
        repsMax: 15,
        slot: 1,
        rir: 3,
        rest: 60,
      );
      _addIfFound(
        exB,
        profile,
        fatigueB,
        muscle: 'abs',
        pattern: 'isolation',
        sets: 3,
        repsMin: 15,
        repsMax: 20,
        slot: 1,
        rir: 2,
        rest: 45,
      );

      sessions.add(
        PrescribedSession(
          id: 'session_cycling_b',
          name: 'Ciclismo — Superior & Core',
          objective: 'Manutenção upper body e core para postura na bike',
          estimatedDurationMinutes: profile.sessionDurationMinutes,
          warmupInstructions: [
            '5 min cardio leve',
            'Mobilidade torácica: 2x10',
            'Rotação de ombros: 2x15',
          ],
          exercises: exB,
          progressionNote:
              'Volume moderado para não prejudicar recuperação das pedaladas.',
        ),
      );
    }

    return sessions;
  }

  // ── LUTAS (MMA/BJJ/Boxe) ──────────────────────────────────────

  List<PrescribedSession> buildCombatPlan(WorkoutProfile profile) {
    final sub = profile.sportSubType;
    final days = profile.availableDaysPerWeek.clamp(2, 4);
    final sessions = <PrescribedSession>[];
    final label = sub == 'bjj'
        ? 'Jiu-Jitsu'
        : sub == 'boxing'
        ? 'Boxe/Muay Thai'
        : 'MMA';

    // A: Força funcional
    final fatigueA = SessionFatigueAccumulator();
    final exA = <PrescribedExercise>[];

    _addIfFound(
      exA,
      profile,
      fatigueA,
      muscle: 'back',
      pattern: 'pull_vertical',
      sets: 4,
      repsMin: 5,
      repsMax: 8,
      slot: 0,
      rir: 1,
      rest: 150,
      tempo: 'explosive',
    );
    _addIfFound(
      exA,
      profile,
      fatigueA,
      muscle: 'chest',
      pattern: 'push_horizontal',
      sets: 4,
      repsMin: 5,
      repsMax: 8,
      slot: 0,
      rir: 1,
      rest: 150,
      tempo: 'explosive',
    );
    _addIfFound(
      exA,
      profile,
      fatigueA,
      muscle: 'quads',
      pattern: 'squat',
      sets: 4,
      repsMin: 5,
      repsMax: 8,
      slot: 0,
      rir: 1,
      rest: 150,
    );
    _addIfFound(
      exA,
      profile,
      fatigueA,
      muscle: 'abs',
      pattern: 'isolation',
      preferTags: ['rotation'],
      sets: 3,
      repsMin: 10,
      repsMax: 15,
      slot: 0,
      rir: 2,
      rest: 60,
    );

    sessions.add(
      PrescribedSession(
        id: 'session_combat_a',
        name: '$label — Força Funcional',
        objective: 'Força máxima aplicável ao combate',
        estimatedDurationMinutes: profile.sessionDurationMinutes,
        warmupInstructions: [
          '5 min shadow boxing ou pular corda',
          'Mobilidade de ombro e quadril: 2x10',
          'Ativação core: prancha 2x30s',
          '1 série leve do 1º exercício',
        ],
        exercises: exA,
        progressionNote:
            'Fase concêntrica explosiva. Lutadores precisam de força relativa, não volume muscular excessivo.',
      ),
    );

    // B: Resistência de grip + Core + Posterior
    final fatigueB = SessionFatigueAccumulator();
    final exB = <PrescribedExercise>[];

    _addIfFound(
      exB,
      profile,
      fatigueB,
      muscle: 'back',
      pattern: 'pull_horizontal',
      sets: 3,
      repsMin: 10,
      repsMax: 15,
      slot: 1,
      rir: 2,
      rest: 90,
    );
    _addIfFound(
      exB,
      profile,
      fatigueB,
      muscle: 'hamstrings',
      pattern: 'hinge',
      sets: 3,
      repsMin: 8,
      repsMax: 12,
      slot: 1,
      rir: 2,
      rest: 90,
    );
    _addIfFound(
      exB,
      profile,
      fatigueB,
      muscle: 'glutes',
      pattern: 'hinge',
      sets: 3,
      repsMin: 10,
      repsMax: 15,
      slot: 1,
      rir: 2,
      rest: 90,
    );
    _addIfFound(
      exB,
      profile,
      fatigueB,
      muscle: 'shoulders',
      pattern: 'push_vertical',
      sets: 3,
      repsMin: 8,
      repsMax: 12,
      slot: 1,
      rir: 2,
      rest: 90,
    );
    _addIfFound(
      exB,
      profile,
      fatigueB,
      muscle: 'abs',
      pattern: 'isolation',
      sets: 3,
      repsMin: 12,
      repsMax: 20,
      slot: 1,
      rir: 1,
      rest: 45,
    );

    sessions.add(
      PrescribedSession(
        id: 'session_combat_b',
        name: '$label — Grip & Posterior',
        objective: 'Resistência muscular, grip e cadeia posterior para $label',
        estimatedDurationMinutes: profile.sessionDurationMinutes,
        warmupInstructions: [
          '5 min pular corda',
          'Mobilidade torácica e quadril: 2x10',
          'Ativação escapular: 2x15',
        ],
        exercises: exB,
        progressionNote:
            'Grip: troque para pegada grossa quando possível. Core rotacional é essencial para golpes e quedas.',
      ),
    );

    return sessions;
  }

  // ── CALISTENIA ────────────────────────────────────────────────

  List<PrescribedSession> buildCalisthenicsPlan(WorkoutProfile profile) {
    final modality = profile.trainingModality;
    final sessions = <PrescribedSession>[];

    final isAdvanced =
        modality == 'calisthenics_advanced' || modality == 'street_workout';

    // A: Push + Core
    final fatigueA = SessionFatigueAccumulator();
    final exA = <PrescribedExercise>[];

    _addIfFound(
      exA,
      profile,
      fatigueA,
      muscle: 'chest',
      pattern: 'push_horizontal',
      preferEquip: ['bodyweight'],
      sets: isAdvanced ? 5 : 3,
      repsMin: 5,
      repsMax: isAdvanced ? 8 : 15,
      slot: 0,
      rir: isAdvanced ? 1 : 3,
      rest: isAdvanced ? 180 : 90,
    );
    _addIfFound(
      exA,
      profile,
      fatigueA,
      muscle: 'shoulders',
      pattern: 'push_vertical',
      preferEquip: ['bodyweight'],
      sets: isAdvanced ? 5 : 3,
      repsMin: 5,
      repsMax: isAdvanced ? 8 : 12,
      slot: 0,
      rir: isAdvanced ? 1 : 3,
      rest: isAdvanced ? 180 : 90,
    );
    _addIfFound(
      exA,
      profile,
      fatigueA,
      muscle: 'triceps',
      pattern: 'isolation',
      preferEquip: ['bodyweight'],
      sets: 3,
      repsMin: 8,
      repsMax: 15,
      slot: 0,
      rir: 2,
      rest: 60,
    );
    _addIfFound(
      exA,
      profile,
      fatigueA,
      muscle: 'abs',
      pattern: 'isolation',
      preferEquip: ['bodyweight'],
      sets: 3,
      repsMin: 10,
      repsMax: 20,
      slot: 0,
      rir: 2,
      rest: 45,
    );

    sessions.add(
      PrescribedSession(
        id: 'session_cali_a',
        name: 'Calistenia — Push & Core',
        objective: isAdvanced
            ? 'Força de empurrar para skills (planche, HSPU)'
            : 'Base de empurrar com peso corporal',
        estimatedDurationMinutes: profile.sessionDurationMinutes,
        warmupInstructions: [
          'Rotação articular: ombros, cotovelos, punhos',
          'Flexão de parede: 2x15',
          'Prancha: 2x30s',
          isAdvanced
              ? 'Skill work: 5 min (handstand, L-sit holds)'
              : 'Aquecimento: flexão facilitada 2x10',
        ],
        exercises: exA,
        progressionNote: isAdvanced
            ? 'Calistenia avançada: progrida para variações mais difíceis quando conseguir 3x8 com boa forma.'
            : 'Progressão bodyweight: aumente reps até 3x15, depois avance para variação mais difícil.',
      ),
    );

    // B: Pull + Legs
    final fatigueB = SessionFatigueAccumulator();
    final exB = <PrescribedExercise>[];

    _addIfFound(
      exB,
      profile,
      fatigueB,
      muscle: 'back',
      pattern: 'pull_vertical',
      preferEquip: ['bodyweight'],
      sets: isAdvanced ? 5 : 3,
      repsMin: 3,
      repsMax: isAdvanced ? 8 : 12,
      slot: 1,
      rir: isAdvanced ? 1 : 3,
      rest: isAdvanced ? 180 : 90,
    );
    _addIfFound(
      exB,
      profile,
      fatigueB,
      muscle: 'back',
      pattern: 'pull_horizontal',
      preferEquip: ['bodyweight'],
      sets: 3,
      repsMin: 6,
      repsMax: 12,
      slot: 1,
      rir: 2,
      rest: 90,
    );
    _addIfFound(
      exB,
      profile,
      fatigueB,
      muscle: 'biceps',
      pattern: 'isolation',
      preferEquip: ['bodyweight'],
      sets: 3,
      repsMin: 8,
      repsMax: 15,
      slot: 1,
      rir: 2,
      rest: 60,
    );
    _addIfFound(
      exB,
      profile,
      fatigueB,
      muscle: 'quads',
      pattern: 'squat',
      preferEquip: ['bodyweight'],
      sets: 3,
      repsMin: 8,
      repsMax: 20,
      slot: 1,
      rir: 2,
      rest: 90,
    );
    _addIfFound(
      exB,
      profile,
      fatigueB,
      muscle: 'glutes',
      pattern: 'hinge',
      preferEquip: ['bodyweight'],
      sets: 3,
      repsMin: 10,
      repsMax: 15,
      slot: 1,
      rir: 2,
      rest: 60,
    );

    sessions.add(
      PrescribedSession(
        id: 'session_cali_b',
        name: 'Calistenia — Pull & Pernas',
        objective: isAdvanced
            ? 'Força de tração para skills (lever, muscle up)'
            : 'Base de puxar e membros inferiores',
        estimatedDurationMinutes: profile.sessionDurationMinutes,
        warmupInstructions: [
          'Mobilidade escapular: 2x15',
          'Barra fixa facilitada ou australian pull up: 2x6',
          'Agachamento livre: 2x15',
        ],
        exercises: exB,
        progressionNote: isAdvanced
            ? 'Front lever: progrida tuck → advanced tuck → straddle → full. Nunca pule etapas.'
            : 'Complete 3x12 na barra fixa antes de tentar variações avançadas.',
      ),
    );

    return sessions;
  }

  // ── HIIT / FUNCIONAL ─────────────────────────────────────────

  List<PrescribedSession> buildHIITPlan(WorkoutProfile profile) {
    final modality = profile.trainingModality;
    final days = profile.availableDaysPerWeek.clamp(2, 5);
    final sessions = <PrescribedSession>[];
    final tags = ['A', 'B', 'C', 'D', 'E'];

    for (int i = 0; i < days.clamp(2, 4); i++) {
      final fatigue = SessionFatigueAccumulator();
      final exercises = <PrescribedExercise>[];
      final isUpper = i.isEven;
      String name;
      String objective;

      // Cada sessão: 5-8 exercícios em circuito
      if (isUpper) {
        _addIfFound(
          exercises,
          profile,
          fatigue,
          muscle: 'chest',
          pattern: 'push_horizontal',
          sets: 3,
          repsMin: 12,
          repsMax: 20,
          slot: i,
          rir: 0,
          rest: 30,
        );
        _addIfFound(
          exercises,
          profile,
          fatigue,
          muscle: 'back',
          pattern: 'pull_horizontal',
          sets: 3,
          repsMin: 12,
          repsMax: 20,
          slot: i,
          rir: 0,
          rest: 30,
        );
        _addIfFound(
          exercises,
          profile,
          fatigue,
          muscle: 'shoulders',
          pattern: 'push_vertical',
          sets: 3,
          repsMin: 12,
          repsMax: 15,
          slot: i,
          rir: 1,
          rest: 30,
        );
        _addIfFound(
          exercises,
          profile,
          fatigue,
          muscle: 'abs',
          pattern: 'isolation',
          sets: 3,
          repsMin: 15,
          repsMax: 20,
          slot: i,
          rir: 0,
          rest: 30,
        );
        name = 'HIIT Upper ${tags[i]}';
        objective = 'Circuito metabólico upper body — descanso mínimo';
      } else {
        _addIfFound(
          exercises,
          profile,
          fatigue,
          muscle: 'quads',
          pattern: 'squat',
          sets: 3,
          repsMin: 15,
          repsMax: 20,
          slot: i,
          rir: 0,
          rest: 30,
        );
        _addIfFound(
          exercises,
          profile,
          fatigue,
          muscle: 'glutes',
          pattern: 'hinge',
          sets: 3,
          repsMin: 12,
          repsMax: 20,
          slot: i,
          rir: 0,
          rest: 30,
        );
        _addIfFound(
          exercises,
          profile,
          fatigue,
          muscle: 'hamstrings',
          pattern: 'hinge',
          sets: 3,
          repsMin: 12,
          repsMax: 15,
          slot: i,
          rir: 1,
          rest: 30,
        );
        _addIfFound(
          exercises,
          profile,
          fatigue,
          muscle: 'calves',
          pattern: 'isolation',
          sets: 3,
          repsMin: 15,
          repsMax: 25,
          slot: i,
          rir: 0,
          rest: 30,
        );
        _addIfFound(
          exercises,
          profile,
          fatigue,
          muscle: 'abs',
          pattern: 'isolation',
          sets: 3,
          repsMin: 15,
          repsMax: 20,
          slot: i,
          rir: 0,
          rest: 30,
        );
        name = 'HIIT Lower ${tags[i]}';
        objective = 'Circuito metabólico lower body — descanso mínimo';
      }

      String protocolNote;
      switch (modality) {
        case 'hiit_tabata':
          protocolNote =
              'TABATA: 20s trabalho máximo + 10s descanso x 8 rounds por exercício. Total: ~4 min/exercício.';
          break;
        case 'hiit_emom':
          protocolNote =
              'EMOM: Complete as reps no início de cada minuto. O descanso é o tempo restante.';
          break;
        case 'hiit_amrap':
          protocolNote =
              'AMRAP: Faça o máximo de rounds possível em 20 minutos. Registre o total.';
          break;
        default:
          protocolNote =
              'CIRCUITO: Execute todos os exercícios em sequência com 30s de descanso. Repita 3-4 rounds.';
      }

      sessions.add(
        PrescribedSession(
          id: 'session_hiit_${tags[i]}',
          name: name,
          objective: objective,
          estimatedDurationMinutes: profile.sessionDurationMinutes,
          warmupInstructions: [
            '3 min de mobilidade articular',
            '2 min de cardio progressivo (andar → trotar → correr)',
            '1 round do circuito com 50% da intensidade',
          ],
          exercises: exercises,
          progressionNote: protocolNote,
        ),
      );
    }

    return sessions;
  }

  // ── MOBILIDADE / REABILITAÇÃO ────────────────────────────────

  List<PrescribedSession> buildMobilityRehabPlan(WorkoutProfile profile) {
    final modality = profile.trainingModality;
    final days = profile.availableDaysPerWeek.clamp(2, 5);
    final sessions = <PrescribedSession>[];

    // Sessão A: Upper Mobility
    final fatigueA = SessionFatigueAccumulator();
    final exA = <PrescribedExercise>[];

    // Exercícios de mobilidade/alongamento
    _addMobilityBlock(exA, profile, ['shoulder', 'thoracic', 'wrist'], slot: 0);

    // Se reabilitação específica, adicionar exercícios de rehab
    if (modality.startsWith('rehab_')) {
      _addRehabBlock(exA, profile, modality);
    }

    // Fortalecimento leve preventivo
    _addIfFound(
      exA,
      profile,
      fatigueA,
      muscle: 'shoulders',
      pattern: 'isolation',
      preferTags: ['prevention', 'rehab'],
      sets: 2,
      repsMin: 15,
      repsMax: 20,
      slot: 0,
      rir: 4,
      rest: 45,
      tempo: '3-1-3',
    );
    _addIfFound(
      exA,
      profile,
      fatigueA,
      muscle: 'back',
      pattern: 'pull_horizontal',
      sets: 2,
      repsMin: 12,
      repsMax: 15,
      slot: 0,
      rir: 3,
      rest: 60,
      tempo: '2-1-2',
    );

    sessions.add(
      PrescribedSession(
        id: 'session_mobility_a',
        name: 'Mobilidade & Prevenção — Superior',
        objective: _mobilityObjective(modality, 'upper'),
        estimatedDurationMinutes: profile.sessionDurationMinutes,
        warmupInstructions: [
          '3 min de caminhada leve',
          'Rotação articular geral: 2 min (pescoço → ombros → cotovelos → punhos)',
          'Respiração diafragmática: 10 inspirações profundas',
        ],
        exercises: exA,
        progressionNote:
            'Mobilidade: mantenha cada posição 30-60s. Sem dor. Aumente ROM gradualmente a cada semana.',
      ),
    );

    // Sessão B: Lower Mobility
    if (days >= 2) {
      final fatigueB = SessionFatigueAccumulator();
      final exB = <PrescribedExercise>[];

      _addMobilityBlock(exB, profile, ['hip', 'knee', 'ankle'], slot: 1);

      if (modality.startsWith('rehab_')) {
        _addRehabBlock(exB, profile, modality);
      }

      _addIfFound(
        exB,
        profile,
        fatigueB,
        muscle: 'glutes',
        pattern: 'hinge',
        sets: 2,
        repsMin: 12,
        repsMax: 15,
        slot: 1,
        rir: 3,
        rest: 60,
        tempo: '3-1-3',
      );
      _addIfFound(
        exB,
        profile,
        fatigueB,
        muscle: 'abs',
        pattern: 'isolation',
        sets: 2,
        repsMin: 12,
        repsMax: 15,
        slot: 1,
        rir: 3,
        rest: 45,
        tempo: '2-1-2',
      );

      sessions.add(
        PrescribedSession(
          id: 'session_mobility_b',
          name: 'Mobilidade & Prevenção — Inferior',
          objective: _mobilityObjective(modality, 'lower'),
          estimatedDurationMinutes: profile.sessionDurationMinutes,
          warmupInstructions: [
            '3 min de caminhada leve',
            'Rotação articular: quadril, joelhos, tornozelos',
            'Respiração diafragmática: 10 inspirações profundas',
          ],
          exercises: exB,
          progressionNote:
              'Foco em qualidade, não quantidade. Pare se sentir dor aguda. Desconforto leve é aceitável.',
        ),
      );
    }

    return sessions;
  }

  // ── PLANOS TEMÁTICOS (D7) ────────────────────────────────────

  List<PrescribedSession> buildTemplatePlan(WorkoutProfile profile) {
    final modality = profile.trainingModality;
    switch (modality) {
      case 'template_5x5':
        return _build5x5(profile);
      case 'template_gvt':
        return _buildGVT(profile);
      case 'template_531':
        return _build531(profile);
      case 'template_phul':
        return _buildPHUL(profile);
      case 'template_phat':
        return _buildPHAT(profile);
      default:
        return _build5x5(profile);
    }
  }

  List<PrescribedSession> _build5x5(WorkoutProfile profile) {
    final sessions = <PrescribedSession>[];

    // StrongLifts 5x5: A/B alternando, 3x/semana
    final fatigueA = SessionFatigueAccumulator();
    final exA = <PrescribedExercise>[];

    _addIfFound(
      exA,
      profile,
      fatigueA,
      muscle: 'quads',
      pattern: 'squat',
      sets: 5,
      repsMin: 5,
      repsMax: 5,
      slot: 0,
      rir: 1,
      rest: 180,
    );
    _addIfFound(
      exA,
      profile,
      fatigueA,
      muscle: 'chest',
      pattern: 'push_horizontal',
      sets: 5,
      repsMin: 5,
      repsMax: 5,
      slot: 0,
      rir: 1,
      rest: 180,
    );
    _addIfFound(
      exA,
      profile,
      fatigueA,
      muscle: 'back',
      pattern: 'pull_horizontal',
      sets: 5,
      repsMin: 5,
      repsMax: 5,
      slot: 0,
      rir: 1,
      rest: 180,
    );

    sessions.add(
      PrescribedSession(
        id: 'session_5x5_a',
        name: 'StrongLifts 5×5 — Dia A',
        objective: 'Força básica: Agachamento, Supino, Remada',
        estimatedDurationMinutes: profile.sessionDurationMinutes,
        warmupInstructions: [
          '5 min cardio leve',
          '2 séries de aquecimento progressivo: barra vazia → 50% → 70% da carga de trabalho',
        ],
        exercises: exA,
        progressionNote:
            '5×5: Adicione 2,5 kg por sessão em upper e 5 kg em lower. Se falhar 3x seguidas, reduza 10%.',
      ),
    );

    final fatigueB = SessionFatigueAccumulator();
    final exB = <PrescribedExercise>[];

    _addIfFound(
      exB,
      profile,
      fatigueB,
      muscle: 'quads',
      pattern: 'squat',
      sets: 5,
      repsMin: 5,
      repsMax: 5,
      slot: 1,
      rir: 1,
      rest: 180,
    );
    _addIfFound(
      exB,
      profile,
      fatigueB,
      muscle: 'shoulders',
      pattern: 'push_vertical',
      sets: 5,
      repsMin: 5,
      repsMax: 5,
      slot: 1,
      rir: 1,
      rest: 180,
    );
    _addIfFound(
      exB,
      profile,
      fatigueB,
      muscle: 'hamstrings',
      pattern: 'hinge',
      sets: 5,
      repsMin: 5,
      repsMax: 5,
      slot: 1,
      rir: 1,
      rest: 180,
    );

    sessions.add(
      PrescribedSession(
        id: 'session_5x5_b',
        name: 'StrongLifts 5×5 — Dia B',
        objective: 'Força básica: Agachamento, Desenvolvimento, Terra',
        estimatedDurationMinutes: profile.sessionDurationMinutes,
        warmupInstructions: [
          '5 min cardio leve',
          '2 séries de aquecimento progressivo: barra vazia → 50% → 70% da carga de trabalho',
        ],
        exercises: exB,
        progressionNote:
            '5×5: Agachamento é feito TODOS os dias. É o centro do programa.',
      ),
    );

    return sessions;
  }

  List<PrescribedSession> _buildGVT(WorkoutProfile profile) {
    final sessions = <PrescribedSession>[];

    // GVT: 10x10 com 60% do 1RM, descanso 60-90s
    final fatigueA = SessionFatigueAccumulator();
    final exA = <PrescribedExercise>[];

    _addIfFound(
      exA,
      profile,
      fatigueA,
      muscle: 'chest',
      pattern: 'push_horizontal',
      sets: 10,
      repsMin: 10,
      repsMax: 10,
      slot: 0,
      rir: 2,
      rest: 90,
      tempo: '4-0-2',
    );
    _addIfFound(
      exA,
      profile,
      fatigueA,
      muscle: 'back',
      pattern: 'pull_vertical',
      sets: 10,
      repsMin: 10,
      repsMax: 10,
      slot: 0,
      rir: 2,
      rest: 90,
      tempo: '4-0-2',
    );
    _addIfFound(
      exA,
      profile,
      fatigueA,
      muscle: 'biceps',
      pattern: 'isolation',
      sets: 3,
      repsMin: 10,
      repsMax: 12,
      slot: 0,
      rir: 2,
      rest: 60,
    );
    _addIfFound(
      exA,
      profile,
      fatigueA,
      muscle: 'triceps',
      pattern: 'isolation',
      sets: 3,
      repsMin: 10,
      repsMax: 12,
      slot: 0,
      rir: 2,
      rest: 60,
    );

    sessions.add(
      PrescribedSession(
        id: 'session_gvt_a',
        name: 'GVT 10×10 — Peito & Costas',
        objective:
            'German Volume Training: 100 reps por exercício para hipertrofia extrema',
        estimatedDurationMinutes: profile.sessionDurationMinutes,
        warmupInstructions: [
          '5 min cardio',
          '2 séries progressivas de aquecimento',
          'Use 60% do seu 1RM ou 20RM como carga de trabalho',
        ],
        exercises: exA,
        progressionNote:
            'GVT: Use cadência 4-0-2 (4s excêntrico). Quando completar 10×10 sem falha, adicione 2,5 kg.',
      ),
    );

    final fatigueB = SessionFatigueAccumulator();
    final exB = <PrescribedExercise>[];

    _addIfFound(
      exB,
      profile,
      fatigueB,
      muscle: 'quads',
      pattern: 'squat',
      sets: 10,
      repsMin: 10,
      repsMax: 10,
      slot: 1,
      rir: 2,
      rest: 90,
      tempo: '4-0-2',
    );
    _addIfFound(
      exB,
      profile,
      fatigueB,
      muscle: 'hamstrings',
      pattern: 'hinge',
      sets: 10,
      repsMin: 10,
      repsMax: 10,
      slot: 1,
      rir: 2,
      rest: 90,
      tempo: '4-0-2',
    );
    _addIfFound(
      exB,
      profile,
      fatigueB,
      muscle: 'calves',
      pattern: 'isolation',
      sets: 3,
      repsMin: 15,
      repsMax: 20,
      slot: 1,
      rir: 1,
      rest: 60,
    );
    _addIfFound(
      exB,
      profile,
      fatigueB,
      muscle: 'abs',
      pattern: 'isolation',
      sets: 3,
      repsMin: 15,
      repsMax: 20,
      slot: 1,
      rir: 1,
      rest: 60,
    );

    sessions.add(
      PrescribedSession(
        id: 'session_gvt_b',
        name: 'GVT 10×10 — Pernas',
        objective: 'German Volume Training: volume extremo para pernas',
        estimatedDurationMinutes: profile.sessionDurationMinutes,
        warmupInstructions: [
          '5 min bike',
          '2 séries progressivas do primeiro exercício',
          'Mobilidade de quadril: 2x10',
        ],
        exercises: exB,
        progressionNote:
            'GVT Pernas: pode ser dividido em leg press 10×10 + leg curl 10×10 se agachamento for desconfortável.',
      ),
    );

    return sessions;
  }

  List<PrescribedSession> _build531(WorkoutProfile profile) {
    // Wendler 5/3/1: 4 dias por semana, cada dia um lift principal
    final sessions = <PrescribedSession>[];
    final lifts = [
      {
        'id': 'session_531_squat',
        'name': '5/3/1 — Agachamento',
        'muscle': 'quads',
        'pattern': 'squat',
      },
      {
        'id': 'session_531_bench',
        'name': '5/3/1 — Supino',
        'muscle': 'chest',
        'pattern': 'push_horizontal',
      },
      {
        'id': 'session_531_dead',
        'name': '5/3/1 — Levantamento Terra',
        'muscle': 'hamstrings',
        'pattern': 'hinge',
      },
      {
        'id': 'session_531_press',
        'name': '5/3/1 — Desenvolvimento',
        'muscle': 'shoulders',
        'pattern': 'push_vertical',
      },
    ];

    final week = profile.currentWeek;
    final weekInCycle = ((week - 1) % 4) + 1;
    String scheme;
    int mainSets;
    int mainRepsMin;
    int mainRepsMax;
    int mainRir;

    switch (weekInCycle) {
      case 1:
        scheme = 'Semana 5s';
        mainSets = 3;
        mainRepsMin = 5;
        mainRepsMax = 5;
        mainRir = 2;
        break;
      case 2:
        scheme = 'Semana 3s';
        mainSets = 3;
        mainRepsMin = 3;
        mainRepsMax = 3;
        mainRir = 1;
        break;
      case 3:
        scheme = 'Semana 5/3/1';
        mainSets = 3;
        mainRepsMin = 1;
        mainRepsMax = 5;
        mainRir = 0;
        break;
      default:
        scheme = 'Deload';
        mainSets = 3;
        mainRepsMin = 5;
        mainRepsMax = 5;
        mainRir = 4;
        break;
    }

    for (int i = 0; i < min(lifts.length, profile.availableDaysPerWeek); i++) {
      final lift = lifts[i];
      final fatigue = SessionFatigueAccumulator();
      final exercises = <PrescribedExercise>[];

      // Lift principal
      _addIfFound(
        exercises,
        profile,
        fatigue,
        muscle: lift['muscle']!,
        pattern: lift['pattern']!,
        sets: mainSets,
        repsMin: mainRepsMin,
        repsMax: mainRepsMax,
        slot: i,
        rir: mainRir,
        rest: 240,
      );

      // Boring But Big (BBB): 5x10 do mesmo padrão com 50-60%
      _addIfFound(
        exercises,
        profile,
        fatigue,
        muscle: lift['muscle']!,
        pattern: lift['pattern']!,
        sets: 5,
        repsMin: 10,
        repsMax: 10,
        slot: i + 10,
        rir: 2,
        rest: 90,
        tempo: '2-0-2',
      );

      // Assistência
      final isUpper =
          lift['muscle'] == 'chest' || lift['muscle'] == 'shoulders';
      if (isUpper) {
        _addIfFound(
          exercises,
          profile,
          fatigue,
          muscle: 'back',
          pattern: 'pull_vertical',
          sets: 3,
          repsMin: 8,
          repsMax: 15,
          slot: i,
          rir: 2,
          rest: 90,
        );
      } else {
        _addIfFound(
          exercises,
          profile,
          fatigue,
          muscle: 'abs',
          pattern: 'isolation',
          sets: 3,
          repsMin: 10,
          repsMax: 20,
          slot: i,
          rir: 2,
          rest: 60,
        );
      }

      sessions.add(
        PrescribedSession(
          id: lift['id']!,
          name: '${lift['name']!} [$scheme]',
          objective: 'Wendler 5/3/1 — $scheme + Boring But Big',
          estimatedDurationMinutes: profile.sessionDurationMinutes,
          warmupInstructions: [
            '5 min cardio',
            'Séries de aquecimento: 40% x 5, 50% x 5, 60% x 3',
          ],
          exercises: exercises,
          progressionNote:
              '5/3/1: Após cada ciclo de 4 semanas, adicione 2,5 kg aos upper lifts e 5 kg aos lower lifts.',
        ),
      );
    }

    return sessions;
  }

  List<PrescribedSession> _buildPHUL(WorkoutProfile profile) {
    final sessions = <PrescribedSession>[];

    // Power Upper
    final fPU = SessionFatigueAccumulator();
    final exPU = <PrescribedExercise>[];
    _addIfFound(
      exPU,
      profile,
      fPU,
      muscle: 'chest',
      pattern: 'push_horizontal',
      sets: 4,
      repsMin: 3,
      repsMax: 5,
      slot: 0,
      rir: 1,
      rest: 180,
    );
    _addIfFound(
      exPU,
      profile,
      fPU,
      muscle: 'back',
      pattern: 'pull_vertical',
      sets: 4,
      repsMin: 3,
      repsMax: 5,
      slot: 0,
      rir: 1,
      rest: 180,
    );
    _addIfFound(
      exPU,
      profile,
      fPU,
      muscle: 'shoulders',
      pattern: 'push_vertical',
      sets: 3,
      repsMin: 5,
      repsMax: 8,
      slot: 0,
      rir: 2,
      rest: 120,
    );
    _addIfFound(
      exPU,
      profile,
      fPU,
      muscle: 'back',
      pattern: 'pull_horizontal',
      sets: 3,
      repsMin: 5,
      repsMax: 8,
      slot: 1,
      rir: 2,
      rest: 120,
    );
    _addIfFound(
      exPU,
      profile,
      fPU,
      muscle: 'biceps',
      pattern: 'isolation',
      sets: 3,
      repsMin: 6,
      repsMax: 10,
      slot: 0,
      rir: 2,
      rest: 90,
    );
    _addIfFound(
      exPU,
      profile,
      fPU,
      muscle: 'triceps',
      pattern: 'isolation',
      sets: 3,
      repsMin: 6,
      repsMax: 10,
      slot: 0,
      rir: 2,
      rest: 90,
    );

    sessions.add(
      PrescribedSession(
        id: 'session_phul_pu',
        name: 'PHUL — Power Upper',
        objective: 'Força máxima upper body — cargas pesadas, reps baixas',
        estimatedDurationMinutes: profile.sessionDurationMinutes,
        warmupInstructions: [
          '5 min cardio',
          '3 séries progressivas de aquecimento',
        ],
        exercises: exPU,
        progressionNote:
            'PHUL Power: Aumente 2,5 kg quando completar todas as reps com RIR >= 2.',
      ),
    );

    // Power Lower
    final fPL = SessionFatigueAccumulator();
    final exPL = <PrescribedExercise>[];
    _addIfFound(
      exPL,
      profile,
      fPL,
      muscle: 'quads',
      pattern: 'squat',
      sets: 4,
      repsMin: 3,
      repsMax: 5,
      slot: 0,
      rir: 1,
      rest: 180,
    );
    _addIfFound(
      exPL,
      profile,
      fPL,
      muscle: 'hamstrings',
      pattern: 'hinge',
      sets: 4,
      repsMin: 3,
      repsMax: 5,
      slot: 0,
      rir: 1,
      rest: 180,
    );
    _addIfFound(
      exPL,
      profile,
      fPL,
      muscle: 'quads',
      pattern: 'squat',
      sets: 3,
      repsMin: 5,
      repsMax: 8,
      slot: 1,
      rir: 2,
      rest: 120,
    );
    _addIfFound(
      exPL,
      profile,
      fPL,
      muscle: 'calves',
      pattern: 'isolation',
      sets: 4,
      repsMin: 6,
      repsMax: 10,
      slot: 0,
      rir: 2,
      rest: 90,
    );
    _addIfFound(
      exPL,
      profile,
      fPL,
      muscle: 'abs',
      pattern: 'isolation',
      sets: 3,
      repsMin: 8,
      repsMax: 15,
      slot: 0,
      rir: 2,
      rest: 60,
    );

    sessions.add(
      PrescribedSession(
        id: 'session_phul_pl',
        name: 'PHUL — Power Lower',
        objective: 'Força máxima lower body',
        estimatedDurationMinutes: profile.sessionDurationMinutes,
        warmupInstructions: [
          '5 min bike',
          'Mobilidade de quadril: 2x10/lado',
          'Aquecimento progressivo',
        ],
        exercises: exPL,
        progressionNote:
            'PHUL Power Lower: Agachamento e terra são os pilares.',
      ),
    );

    // Hypertrophy Upper
    final fHU = SessionFatigueAccumulator();
    final exHU = <PrescribedExercise>[];
    _addIfFound(
      exHU,
      profile,
      fHU,
      muscle: 'chest',
      pattern: 'push_incline',
      sets: 4,
      repsMin: 8,
      repsMax: 12,
      slot: 2,
      rir: 2,
      rest: 90,
    );
    _addIfFound(
      exHU,
      profile,
      fHU,
      muscle: 'back',
      pattern: 'pull_horizontal',
      sets: 4,
      repsMin: 8,
      repsMax: 12,
      slot: 2,
      rir: 2,
      rest: 90,
    );
    _addIfFound(
      exHU,
      profile,
      fHU,
      muscle: 'chest',
      pattern: 'isolation',
      sets: 3,
      repsMin: 10,
      repsMax: 15,
      slot: 2,
      rir: 2,
      rest: 60,
    );
    _addIfFound(
      exHU,
      profile,
      fHU,
      muscle: 'shoulders',
      pattern: 'isolation',
      sets: 3,
      repsMin: 10,
      repsMax: 15,
      slot: 2,
      rir: 2,
      rest: 60,
    );
    _addIfFound(
      exHU,
      profile,
      fHU,
      muscle: 'biceps',
      pattern: 'isolation',
      sets: 3,
      repsMin: 10,
      repsMax: 15,
      slot: 2,
      rir: 2,
      rest: 60,
    );
    _addIfFound(
      exHU,
      profile,
      fHU,
      muscle: 'triceps',
      pattern: 'isolation',
      sets: 3,
      repsMin: 10,
      repsMax: 15,
      slot: 2,
      rir: 2,
      rest: 60,
    );

    sessions.add(
      PrescribedSession(
        id: 'session_phul_hu',
        name: 'PHUL — Hypertrophy Upper',
        objective: 'Hipertrofia upper body — volume e conexão mente-músculo',
        estimatedDurationMinutes: profile.sessionDurationMinutes,
        warmupInstructions: ['5 min cardio', 'Rotação de ombros: 2x15'],
        exercises: exHU,
        progressionNote:
            'PHUL Hypertrophy: Foco em squeeze e ROM completa. Progressão dupla (reps → carga).',
      ),
    );

    // Hypertrophy Lower
    final fHL = SessionFatigueAccumulator();
    final exHL = <PrescribedExercise>[];
    _addIfFound(
      exHL,
      profile,
      fHL,
      muscle: 'quads',
      pattern: 'squat',
      sets: 4,
      repsMin: 8,
      repsMax: 12,
      slot: 3,
      rir: 2,
      rest: 90,
    );
    _addIfFound(
      exHL,
      profile,
      fHL,
      muscle: 'hamstrings',
      pattern: 'hinge',
      sets: 4,
      repsMin: 8,
      repsMax: 12,
      slot: 3,
      rir: 2,
      rest: 90,
    );
    _addIfFound(
      exHL,
      profile,
      fHL,
      muscle: 'glutes',
      pattern: 'hinge',
      sets: 3,
      repsMin: 10,
      repsMax: 15,
      slot: 3,
      rir: 2,
      rest: 60,
    );
    _addIfFound(
      exHL,
      profile,
      fHL,
      muscle: 'quads',
      pattern: 'isolation',
      sets: 3,
      repsMin: 10,
      repsMax: 15,
      slot: 3,
      rir: 2,
      rest: 60,
    );
    _addIfFound(
      exHL,
      profile,
      fHL,
      muscle: 'hamstrings',
      pattern: 'isolation',
      sets: 3,
      repsMin: 10,
      repsMax: 15,
      slot: 3,
      rir: 2,
      rest: 60,
    );
    _addIfFound(
      exHL,
      profile,
      fHL,
      muscle: 'calves',
      pattern: 'isolation',
      sets: 4,
      repsMin: 12,
      repsMax: 20,
      slot: 3,
      rir: 1,
      rest: 60,
    );

    sessions.add(
      PrescribedSession(
        id: 'session_phul_hl',
        name: 'PHUL — Hypertrophy Lower',
        objective: 'Hipertrofia lower body — volume e bomba muscular',
        estimatedDurationMinutes: profile.sessionDurationMinutes,
        warmupInstructions: ['5 min bike', 'Mobilidade de quadril: 2x10'],
        exercises: exHL,
        progressionNote:
            'PHUL Hypertrophy Lower: Use drop sets na última série de isoladores.',
      ),
    );

    return sessions;
  }

  List<PrescribedSession> _buildPHAT(WorkoutProfile profile) {
    // PHAT: 5 dias — similar ao PHUL mas com dia de ombros/braços separado
    final sessions = _buildPHUL(profile);

    // Adicionar sessão de ombros se dias >= 5
    if (profile.availableDaysPerWeek >= 5) {
      final fatigue = SessionFatigueAccumulator();
      final exercises = <PrescribedExercise>[];

      _addIfFound(
        exercises,
        profile,
        fatigue,
        muscle: 'shoulders',
        pattern: 'push_vertical',
        sets: 4,
        repsMin: 6,
        repsMax: 10,
        slot: 4,
        rir: 2,
        rest: 120,
      );
      _addIfFound(
        exercises,
        profile,
        fatigue,
        muscle: 'side_delt',
        pattern: 'isolation',
        sets: 4,
        repsMin: 10,
        repsMax: 15,
        slot: 4,
        rir: 2,
        rest: 60,
      );
      _addIfFound(
        exercises,
        profile,
        fatigue,
        muscle: 'rear_delt',
        pattern: 'isolation',
        sets: 3,
        repsMin: 12,
        repsMax: 15,
        slot: 4,
        rir: 2,
        rest: 60,
      );
      _addIfFound(
        exercises,
        profile,
        fatigue,
        muscle: 'biceps',
        pattern: 'isolation',
        sets: 3,
        repsMin: 8,
        repsMax: 12,
        slot: 4,
        rir: 2,
        rest: 60,
      );
      _addIfFound(
        exercises,
        profile,
        fatigue,
        muscle: 'triceps',
        pattern: 'isolation',
        sets: 3,
        repsMin: 8,
        repsMax: 12,
        slot: 4,
        rir: 2,
        rest: 60,
      );

      sessions.add(
        PrescribedSession(
          id: 'session_phat_arms',
          name: 'PHAT — Ombros & Braços Speed',
          objective: 'Ombros e braços com foco em velocidade concêntrica',
          estimatedDurationMinutes: profile.sessionDurationMinutes,
          warmupInstructions: [
            '5 min cardio',
            'Rotação de ombros: 2x15',
            'Face pull: 2x12',
          ],
          exercises: exercises,
          progressionNote:
              'PHAT Speed Day: Use 65-70% do 1RM. Fase concêntrica explosiva, excêntrica controlada.',
        ),
      );
    }

    return sessions;
  }

  // ═══════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════

  void _addIfFound(
    List<PrescribedExercise> exercises,
    WorkoutProfile profile,
    SessionFatigueAccumulator fatigue, {
    required String muscle,
    required String pattern,
    required int sets,
    required int repsMin,
    required int repsMax,
    required int slot,
    required int rir,
    required int rest,
    bool isUnilateral = false,
    String tempo = '2-0-2',
    List<String>? preferTags,
    List<String>? preferEquip,
  }) {
    // ── BOMPA: LEVEL 1 ANATOMICAL ADAPTATION (AA) PHASE ──
    if (profile.experienceLevel == 'beginner') {
      repsMin = max(12, repsMin);
      repsMax = max(15, repsMax);
      sets = min(2, sets);
      rir = max(3, rir);
      // Forçamos um RIR mais alto e repetições mais altas para
      // focar em adaptação de tendões/ligamentos antes de carga pesada.
    }

    if (profile.priorityMuscles.contains(muscle)) {
      sets = (sets * 1.3).ceil().clamp(2, 6).toInt();
    }

    final candidates = _library.where((ex) {
      if (!ex.primaryMuscles.contains(muscle)) return false;

      // Pattern match (isolation exclui compound)
      if (pattern == 'isolation') {
        if (ex.category != 'isolation') return false;
      } else if (ex.movementPattern != pattern)
        return false;

      // Unilateral preference
      if (isUnilateral && !ex.isUnilateral) return false;

      // Equipment preference pass from Builder config explicitly
      if (preferEquip != null && preferEquip.isNotEmpty) {
        if (!ex.equipment.any((eq) => preferEquip.contains(eq))) return false;
      }

      // ── MODO 'EM CASA' / RESTRIÇÃO DE EQUIPAMENTO ──
      // Usar ExerciseCompatibility como fonte única de verdade
      if (!ExerciseCompatibility.isCompatible(profile, ex)) return false;

      return true;
    }).toList();

    if (candidates.isEmpty) return;

    // Score and pick best
    ExerciseModel best = candidates.first;
    double bestScore = -double.infinity;

    for (final c in candidates) {
      double score = 1.0;
      if (preferTags != null) {
        for (final tag in preferTags) {
          if (c.tags.contains(tag)) score += 3.0;
        }
      }
      if (profile.favoriteExercises.contains(c.id)) score += 2.0;
      // Deterministic tiebreaker
      score += ((_seed + slot + c.id.hashCode).abs() % 100) * 0.01;

      if (score > bestScore) {
        bestScore = score;
        best = c;
      }
    }

    if (!fatigue.canAdd(best, sets)) return;
    fatigue.add(best, sets);

    exercises.add(
      PrescribedExercise(
        exercise: best,
        sets: sets,
        repsMin: repsMin,
        repsMax: repsMax,
        rir: rir,
        restSeconds: rest,
        tempo: tempo,
        sessionCues: [
          ...best.cues.take(2),
          'ROM completa — amplitude máxima segura.',
        ],
        progressionNote:
            'Complete ${best.repRangeMax} reps com boa técnica antes de aumentar carga.',
      ),
    );
  }

  void _addMobilityBlock(
    List<PrescribedExercise> exercises,
    WorkoutProfile profile,
    List<String> areas, {
    required int slot,
  }) {
    final mobilityExs = _library
        .where(
          (ex) => ex.tags.contains('mobility') || ex.category == 'mobility',
        )
        .toList();

    int added = 0;
    for (final ex in mobilityExs) {
      if (added >= 3) break;
      if (profile.dislikedExercises.contains(ex.id)) continue;
      if (!ExerciseCompatibility.isCompatible(profile, ex)) continue;

      exercises.add(
        PrescribedExercise(
          exercise: ex,
          sets: 2,
          repsMin: 10,
          repsMax: 15,
          rir: 4,
          restSeconds: 30,
          tempo: '3-2-3',
          sessionCues: [
            ...ex.cues.take(2),
            'Posição sustentada por 30-60s. Sem dor.',
          ],
          progressionNote: 'Mobilidade: aumente ROM gradualmente. Sem forçar.',
        ),
      );
      added++;
    }
  }

  void _addRehabBlock(
    List<PrescribedExercise> exercises,
    WorkoutProfile profile,
    String modality,
  ) {
    String targetInjury;
    switch (modality) {
      case 'rehab_shoulder':
        targetInjury = 'shoulder';
        break;
      case 'rehab_knee':
        targetInjury = 'knee';
        break;
      case 'rehab_lower_back':
        targetInjury = 'lower_back';
        break;
      default:
        targetInjury = 'general';
        break;
    }

    final rehabIds = injuryRehabExercises[targetInjury] ?? [];
    for (final id in rehabIds.take(3)) {
      final ex = _library.firstWhere(
        (e) => e.id == id,
        orElse: () => _library.first,
      );
      if (ex.id == id) {
        if (!ExerciseCompatibility.isCompatible(profile, ex)) continue;
        exercises.add(
          PrescribedExercise(
            exercise: ex,
            sets: 3,
            repsMin: 15,
            repsMax: 20,
            rir: 3,
            restSeconds: 60,
            sessionCues: [...ex.cues.take(2), 'Sem dor em nenhuma amplitude.'],
            progressionNote: 'Reabilitação: carga leve, controle total.',
            tempo: '3-1-3',
          ),
        );
      }
    }
  }

  _RunningConfig _runningConfig(String subType) {
    switch (subType) {
      case 'run_5k':
        return _RunningConfig(
          label: '5K',
          sets: 3,
          repsMin: 8,
          repsMax: 15,
          rir: 2,
          rest: 60,
          objective:
              'Força de propulsão e Lactic/Power Endurance para corrida de 5K (Bompa)',
          progressionNote:
              'Corrida 5K: priorize resistência muscular de média duração (12-15 reps). Sessão em dia livre de corrida.',
        );
      case 'run_10k':
        return _RunningConfig(
          label: '10K',
          sets: 3,
          repsMin: 10,
          repsMax: 15,
          rir: 2,
          rest: 60,
          objective: 'Resistência Muscular e tolerância ao lactato para 10K',
          progressionNote:
              'Corrida 10K: foco em resistência do sistema aeróbio-glicolítico. Não aumente carga até completar 3x15.',
        );
      case 'run_half':
        return _RunningConfig(
          label: 'Meia Maratona',
          sets: 2,
          repsMin: 12,
          repsMax: 20,
          rir: 3,
          rest: 45,
          objective:
              'Capacidade Aeróbia (ME Long) e economia de corrida para meia maratona (Bompa/NSCA)',
          progressionNote:
              'Meia maratona: volume baixo na musculação. O foco é suporte à corrida, não hipertrofia.',
        );
      case 'run_marathon':
        return _RunningConfig(
          label: 'Maratona',
          sets: 2,
          repsMin: 15,
          repsMax: 20,
          rir: 3,
          rest: 45,
          objective:
              'Capacidade Aeróbia máxima e prevenção para maratona (ME Long)',
          progressionNote:
              'Maratona: musculação 1-2x/semana com volume mínimo. Prioridade total é a corrida.',
        );
      default:
        return _RunningConfig(
          label: 'Corrida',
          sets: 3,
          repsMin: 10,
          repsMax: 15,
          rir: 2,
          rest: 60,
          objective: 'Força complementar para corredores',
          progressionNote:
              'Priorize exercícios unilaterais e core anti-rotação.',
        );
    }
  }

  String _sportLabel(String subType) {
    switch (subType) {
      case 'soccer':
        return 'Futebol';
      case 'basketball':
        return 'Basquete';
      case 'swimming':
        return 'Natação';
      case 'cycling':
        return 'Ciclismo';
      case 'mma':
        return 'MMA';
      case 'bjj':
        return 'Jiu-Jitsu';
      case 'boxing':
        return 'Boxe';
      case 'agility':
        return 'Agilidade';
      default:
        return 'Esporte';
    }
  }

  List<String> _sportWarmup(String subType) {
    switch (subType) {
      case 'soccer':
      case 'basketball':
      case 'agility':
        return [
          'NSCA RAMP — Raise: 5 min corrida leve multifásica',
          'Activate/Mobilize: Forward Lunge com Rotação T-Spine (2x10)',
          'Potentiate: High-Knees (2x20m), Power Skips (2x20m)',
          'Potentiate: Ali Shuffle e Mudança de Direção (2x15m)',
        ];
      case 'swimming':
        return [
          'NSCA RAMP — Raise: 5 min ergométrico superior',
          'Activate/Mobilize: Rotação de ombros com elástico (2x15)',
          'Potentiate: Ativação escapular e Face Pull leve (2x12)',
        ];
      case 'mma':
      case 'bjj':
      case 'boxing':
        return [
          'NSCA RAMP — Raise: 5 min pular corda (ritmo variado)',
          'Activate/Mobilize: Prancha frontal (60s) e Sprawls lentos (2x10)',
          'Potentiate: Saltos explosivos verticais e Shadow Boxing (2 min)',
        ];
      default:
        return [
          'NSCA RAMP — Raise: 5 min cardio geral contínuo',
          'Activate/Mobilize: Mobilidade articular e dinâmica (2 min)',
          'Potentiate: Movimentos primários sem carga (2x10)',
        ];
    }
  }

  String _mobilityObjective(String modality, String focus) {
    switch (modality) {
      case 'rehab_shoulder':
        return 'Reabilitação de ombro — fortalecimento progressivo do manguito rotador';
      case 'rehab_knee':
        return 'Reabilitação de joelho — fortalecimento do vasto medial e estabilizadores';
      case 'rehab_lower_back':
        return 'Reabilitação lombar — core profundo e extensores sem carga';
      case 'rehab_return':
        return 'Retorno pós-lesão — readaptação gradual com volume mínimo';
      case 'yoga_fitness':
        return 'Yoga Fitness — flexibilidade, equilíbrio e controle respiratório';
      case 'myofascial':
        return 'Liberação miofascial — rolo de espuma e alongamento ativo';
      default:
        return 'Mobilidade articular e prevenção — $focus';
    }
  }
}

class _RunningConfig {
  final String label;
  final int sets;
  final int repsMin;
  final int repsMax;
  final int rir;
  final int rest;
  final String objective;
  final String progressionNote;

  const _RunningConfig({
    required this.label,
    required this.sets,
    required this.repsMin,
    required this.repsMax,
    required this.rir,
    required this.rest,
    required this.objective,
    required this.progressionNote,
  });
}
