import 'dart:math';
import 'package:flutter/foundation.dart';
import '../exercises/exercise_model.dart';
import 'workout_profile_model.dart';
import 'prescribed_workout_model.dart';
import 'session_fatigue_accumulator.dart';
import 'exercise_rotation_manager.dart';
import 'sport_plan_builders.dart';
import '../../core/data/exercise_library.dart' show exerciseLibrary, injuryRehabExercises;
import 'exercise_compatibility.dart';
import 'exercise_dna.dart';
import 'training_readiness.dart';
import 'age_modifier.dart';
import 'bio_adaptive_engine.dart';
import 'decision_memory.dart';
import 'progression_engine.dart';
import 'home_workout/home_workout_integrator.dart';

// ═══════════════════════════════════════════════════════════════
// MOTOR DE PRESCRIÇÃO v4.0
//
// Baseado em Schoenfeld (2021) + Murer et al. (2019):
// 1. DUP real: rep range varia ENTRE sessões
// 2. Cadência prescrita por exercício
// 3. RIR real por objetivo
// 4. Equilíbrio push:pull garantido
// 5. ROM completa nos cues
// 6. Volume indireto contabilizado
// 7. FatigueAccumulator: previne sobrecarga articular
// 8. PatternHistory: evita padrão repetido entre dias
// 9. Algoritmo de score > seleção por seed
// 10. Exercise Rotation: variação semanal de exercícios (Schoenfeld + Bompa)
// ═══════════════════════════════════════════════════════════════

// Intensidade da sessão DUP
enum _DupPhase {
  strength,     // 4x6, RIR 1, Descanso 3min, Cadência 1-0-1
  hypertrophy,  // 3x10, RIR 2, Descanso 90s, Cadência 2-0-2
  endurance,    // 2x15, RIR 0-1, Descanso 60s, Cadência 3-1-3
}

class WorkoutPrescriptionEngine {
  final List<ExerciseModel> _library;
  late final int _seed;
  final PatternHistoryTracker _patternHistory;
  final ExerciseRotationManager _rotation;
  final SportPlanBuilders _sportBuilders;
  final int _weekNumber;
  final ProgressionState? _progressionState;
  final DecisionMemory? _decisionMemory;
  final List<PrescribedSession> _recentSessions;

  WorkoutPrescriptionEngine(WorkoutProfile profile,
      {List<ExerciseModel>? library, PatternHistoryTracker? patternHistory, int? weekNumber, ProgressionState? progressionState, DecisionMemory? decisionMemory, List<PrescribedSession>? recentSessions})
      : _library = library ?? exerciseLibrary,
        _seed = _computeSeed(profile),
        _patternHistory = patternHistory ?? PatternHistoryTracker(),
        _rotation = ExerciseRotationManager(library ?? exerciseLibrary),
        _sportBuilders = SportPlanBuilders(library ?? exerciseLibrary, _computeSeed(profile)),
        _weekNumber = weekNumber ?? profile.currentWeek,
        _progressionState = progressionState,
        _decisionMemory = decisionMemory,
        _recentSessions = recentSessions ?? [];

  static int _computeSeed(WorkoutProfile profile) {
    // Usar hashCode em vez de soma de codeUnits para melhor distribuição
    return profile.uid.hashCode;
  }

  /// Cria um SessionFatigueAccumulator com fadiga residual das sessões recentes
  SessionFatigueAccumulator _createFatigueAccumulator() {
    final fatigue = _createFatigueAccumulator();
    if (_recentSessions.isNotEmpty) {
      fatigue.loadResidualFatigue(_recentSessions);
    }
    return fatigue;
  }

  // ── API Pública ───────────────────────────────────────────────

  GeneratedWorkout generate(WorkoutProfile profile) {
    // ── Carregar fadiga residual das sessões recentes ──
    if (_recentSessions.isNotEmpty) {
      // A fadiga residual é considerada pelo SessionFatigueAccumulator
      // quando loadResidualFatigue é chamado antes de montar cada sessão
    }

    // ── Dimensão 0: Verificar se é treino em casa sem equipamento ──
    if (_isHomeBodyweight(profile)) {
      return _generateHomeBodyweightWorkout(profile);
    }

    // ── Dimensão 1+2: Roteamento por modalidade/esporte ──
    final goal = profile.primaryGoal;
    List<PrescribedSession> sessions;
    String splitType;
    String periodization;

    if (_isSportGoal(goal) || _isModalityGoal(goal)) {
      sessions = _buildSportOrModalitySessions(profile);
      splitType = _sportSplitLabel(profile);
      periodization = 'sport_specific';
    } else if (profile.trainingModality.startsWith('template_')) {
      sessions = _sportBuilders.buildTemplatePlan(profile);
      splitType = profile.trainingModality;
      periodization = 'template';
    } else {
      splitType = _selectSplit(profile);
      periodization = _selectPeriodization(profile);
      sessions = _buildSessions(profile, splitType, periodization);
    }

    // Builders diferentes devem obedecer às mesmas hard constraints.
    sessions = _applyClinicalAdjustments(profile, sessions);
    sessions = _auditAndSanitizeSessions(profile, sessions);
    sessions = _fitRequestedSessionCount(profile, sessions);

    // Aplicar Bio-Adaptação: ajustar sets/RIR com base em fadiga e readiness
    sessions = _applyBioAdaptation(profile, sessions);

    // Registrar decisões no DecisionMemory para auditoria
    _recordDecisions(profile, sessions, splitType, periodization);

    // Registra padrões usados
    for (int i = 0; i < sessions.length; i++) {
      final patterns = sessions[i].exercises
          .map((e) => e.exercise.movementPattern)
          .toList();
      final dayKey = i % 2 == 0 ? 'day_minus_1' : 'day_minus_2';
      _patternHistory.recordDay(dayKey, patterns);
    }

    final envLabel = ExerciseCompatibility.isHome(profile.environment)
        ? 'casa' : 'academia';
    final totalExercises = sessions.fold(0, (sum, s) => sum + s.exercises.length);
    final planExplanation = 'Plano de ${sessions.length} sessões com '
        '$totalExercises exercícios, '
        'divisão ${splitType.replaceAll('_', ' ')} '
        '(${periodization.replaceAll('_', ' ')}) '
        'compatível com $envLabel. '
        '${profile.calibrationActive ? "Em fase de calibração — priorizando exercícios simples e seguros." : ""}';

    return GeneratedWorkout(
      id: 'gen_${DateTime.now().millisecondsSinceEpoch}',
      userId: profile.uid,
      splitType: splitType,
      periodizationModel: periodization,
      sessions: sessions,
      mesocycleDurationWeeks: _mesocycleDuration(profile),
      generatedAt: DateTime.now(),
      planExplanation: planExplanation,
    );
  }

  bool _isSportGoal(String goal) =>
      ['sport_specific', 'combat_sports', 'running_hybrid'].contains(goal);

  bool _isModalityGoal(String goal) =>
      ['calisthenics', 'functional_hiit', 'mobility_rehab'].contains(goal);

  // Verifica se o perfil é para treino em casa sem equipamento
  bool _isHomeBodyweight(WorkoutProfile profile) {
    final env = profile.environment.toLowerCase();
    final modality = profile.trainingModality.toLowerCase();
    
    return env == 'home_bodyweight' || 
           env == 'outdoor' ||
           modality == 'home_no_equip' ||
           (ExerciseCompatibility.isHome(env) && 
            profile.availableEquipment.isEmpty);
  }

  // Gera treino usando o novo motor de casa sem equipamento
  GeneratedWorkout _generateHomeBodyweightWorkout(WorkoutProfile profile) {
    final integrator = HomeWorkoutIntegrator(userId: profile.uid);
    return integrator.generateHomeWorkout(profile);
  }

  List<PrescribedSession> _buildSportOrModalitySessions(WorkoutProfile profile) {
    final goal = profile.primaryGoal;
    final sub = profile.sportSubType;

    if (goal == 'running_hybrid' || (goal == 'sport_specific' && sub.startsWith('run_'))) {
      return _sportBuilders.buildRunningPlan(profile);
    }
    if (goal == 'combat_sports' || sub == 'mma' || sub == 'bjj' || sub == 'boxing') {
      return _sportBuilders.buildCombatPlan(profile);
    }
    if (sub == 'swimming') return _sportBuilders.buildSwimmingPlan(profile);
    if (sub == 'cycling') return _sportBuilders.buildCyclingPlan(profile);
    if (sub == 'soccer' || sub == 'basketball' || sub == 'agility') {
      return _sportBuilders.buildFieldSportPlan(profile);
    }
    if (goal == 'calisthenics') return _sportBuilders.buildCalisthenicsPlan(profile);
    if (goal == 'functional_hiit') return _sportBuilders.buildHIITPlan(profile);
    if (goal == 'mobility_rehab') return _sportBuilders.buildMobilityRehabPlan(profile);

    // Fallback para sport_specific genérico
    return _sportBuilders.buildFieldSportPlan(profile);
  }

  String _sportSplitLabel(WorkoutProfile profile) {
    final goal = profile.primaryGoal;
    final sub = profile.sportSubType;
    if (goal == 'running_hybrid' || sub.startsWith('run_')) return 'running_$sub';
    if (goal == 'combat_sports' || sub == 'mma' || sub == 'bjj' || sub == 'boxing') return 'combat_$sub';
    if (sub == 'swimming') return 'swimming';
    if (sub == 'cycling') return 'cycling';
    if (goal == 'calisthenics') return 'calisthenics';
    if (goal == 'functional_hiit') return 'hiit_${profile.trainingModality}';
    if (goal == 'mobility_rehab') return 'mobility_${profile.trainingModality}';
    return 'sport_$sub';
  }

  // ── Ajustes Clínicos e de Nível ──────────────────────────────

  List<PrescribedSession> _applyClinicalAdjustments(
      WorkoutProfile profile, List<PrescribedSession> sessions) {
    final List<PrescribedSession> adjusted = [];
    final hasRestrictions = profile.healthRestrictions.isNotEmpty;
    final isBeginner = profile.experienceLevel == 'beginner';

    for (final session in sessions) {
      final List<PrescribedExercise> sessionExercises = [];
      int currentIsolators = 0;

      for (final pe in session.exercises) {
        // Regra de Proporção (Murer 2019)
        // Iniciantes: Máximo 2 isoladores por treino para reduzir fadiga/DOMS
        if (isBeginner && pe.exercise.category == 'isolation') {
          if (currentIsolators >= 2) continue;
          currentIsolators++;
        }

        PrescribedExercise adjustedEx = pe;

        // Regra de Lesões (Doral 2012)
        if (hasRestrictions) {
          adjustedEx = _handleInjuryRules(profile, pe);
        }

        sessionExercises.add(adjustedEx);
      }

      adjusted.add(PrescribedSession(
        id: session.id,
        name: session.name,
        objective: session.objective,
        estimatedDurationMinutes: session.estimatedDurationMinutes,
        warmupInstructions: session.warmupInstructions,
        exercises: sessionExercises,
        progressionNote: session.progressionNote,
      ));
    }
    return adjusted;
  }

  List<PrescribedSession> _auditAndSanitizeSessions(
      WorkoutProfile profile, List<PrescribedSession> sessions) {
    final originalCount = sessions.fold(0, (sum, s) => sum + s.exercises.length);

    final result = sessions.map((session) {
      final sessionFatigue = _createFatigueAccumulator();
      final safeExercises = <PrescribedExercise>[];
      for (final prescribed in session.exercises) {
        if (!ExerciseCompatibility.isCompatible(profile, prescribed.exercise)) {
          continue;
        }
        if (!sessionFatigue.canAdd(prescribed.exercise, prescribed.sets)) {
          continue;
        }
        sessionFatigue.add(prescribed.exercise, prescribed.sets);
        safeExercises.add(prescribed);
      }

      final envLabel = ExerciseCompatibility.isHome(profile.environment)
          ? 'casa' : 'academia';
      final userExplanation = 'Treino de ${session.name.toLowerCase()} '
          'com ${safeExercises.length} exercícios compatíveis com seu ambiente ($envLabel). '
          'Objetivo: ${session.objective}';

      // Sensibilidade: se muitos exercícios foram removidos, marcar decisão frágil
      if (safeExercises.length < 2 && session.exercises.isNotEmpty) {
        debugPrint('AVISO MOTOR: sessão ${session.name} ficou com apenas '
            '${safeExercises.length} exercício(s) após auditoria.');
      }

      return PrescribedSession(
        id: session.id,
        name: session.name,
        objective: session.objective,
        estimatedDurationMinutes: session.estimatedDurationMinutes,
        warmupInstructions: session.warmupInstructions,
        exercises: safeExercises,
        progressionNote: session.progressionNote,
        fatigue: _fatigueMetrics(sessionFatigue),
        userExplanation: userExplanation,
      );
    }).where((session) => session.exercises.isNotEmpty).toList();

    // Sensibilidade global
    final sanitizedCount = result.fold(0, (sum, s) => sum + s.exercises.length);
    if (originalCount > 0 && sanitizedCount / originalCount < 0.6) {
      debugPrint('AVISO MOTOR: ${(sanitizedCount / originalCount * 100).round()}% '
          'dos exercícios restaram após auditoria. Decisão pode ser frágil.');
    }

    return result;
  }

  List<PrescribedSession> _fitRequestedSessionCount(
      WorkoutProfile profile, List<PrescribedSession> sessions) {
    if (sessions.isEmpty) return sessions;
    final requested = profile.availableDaysPerWeek.clamp(2, 6);
    if (sessions.length >= requested) return sessions.take(requested).toList();

    final result = List<PrescribedSession>.from(sessions);
    var variant = 1;
    while (result.length < requested) {
      final source = sessions[(result.length - sessions.length) % sessions.length];
      result.add(PrescribedSession(
        id: '${source.id}_variant_$variant',
        name: '${source.name} — Variação $variant',
        objective: source.objective,
        estimatedDurationMinutes: source.estimatedDurationMinutes,
        warmupInstructions: source.warmupInstructions,
        exercises: List<PrescribedExercise>.from(source.exercises),
        progressionNote: source.progressionNote,
        fatigue: source.fatigue,
        userExplanation: source.userExplanation,
      ));
      variant++;
    }
    return result;
  }

  PrescribedExercise _handleInjuryRules(WorkoutProfile profile, PrescribedExercise pe) {
    String? injuryNote;
    String tempo = pe.tempo;
    int rir = pe.rir;
    final exId = pe.exercise.id;
    final rest = profile.healthRestrictions;

    // Hipertensão (ACSM 2021)
    if (rest.contains('hypertension')) {
      rir = (rir >= 3) ? rir : 3;
      injuryNote = 'SEGURANÇA: Evite manobra de Valsalva (bloqueio da respiração). RIR mínimo de 3 sempre garantido.';
    }

    // Joelho (LCA / Menisco / Condromalácia)
    if (rest.contains('knee')) {
      if (exId.contains('leg_press')) {
         injuryNote = 'REABILITAÇÃO: Utilize amplitude parcial (0-60 graus). Evite extensão total explosiva.';
      }
      if (exId.contains('agachamento') || exId.contains('flexora')) {
         injuryNote = 'ATENÇÃO: Mantenha joelhos alinhados com o segundo dedo do pé. Evite dor > 3/10.';
      }
    }

    // Lombar (Hérnia / Dor Axial)
    if (rest.contains('lower_back')) {
      if (pe.exercise.category == 'compound' && (exId.contains('barra') || exId.contains('terra'))) {
        injuryNote = 'PROTEÇÃO LOMBAR: Ative o cinturão abdominal (Bracing). Reduza carga se sentir desconforto axial.';
      }
    }

    // Cotovelo / Tendinopatias (Alfredson Protocol)
    if (rest.contains('elbow')) {
      tempo = '3-0-3'; // Cadência exêntrica lenta
      injuryNote = 'PROTOCOLO TENDINOSO: Foco na fase exêntrica lenta (3 seg) para estímulo de colágeno.';
    }

    // Punho (Instabilidade)
    if (rest.contains('wrist')) {
      if (exId.contains('rosca_barra_reta') || exId.contains('supino_barra')) {
        injuryNote = 'PUNHO NEUTRO: Recomendado usar Barra W ou halteres para reduzir cisalhamento no túnel do carpo.';
      }
    }

    // Ombro / Manguito (Impingement)
    if (rest.contains('shoulder')) {
      if (exId.contains('arnold') || (pe.exercise.movementPattern == 'push_vertical')) {
        injuryNote = 'SAÚDE DO OMBRO: Evite abdução > 90°. Foco em manter as escápulas "no bolso traseiro" durante todo o movimento.';
      }
    }

    // Pós-cirurgia (Recuperação)
    if (rest.contains('post_surgery')) {
      rir = (rir >= 4) ? rir : 4;
      injuryNote = 'PÓS-CIRÚRGICO: Treino de intensidade reduzida. Continue apenas com liberação médica explícita para esta região.';
    }

    return PrescribedExercise(
      exercise: pe.exercise,
      sets: pe.sets,
      repsMin: pe.repsMin,
      repsMax: pe.repsMax,
      rir: rir,
      restSeconds: pe.restSeconds,
      tempo: tempo,
      sessionCues: pe.sessionCues,
      progressionNote: pe.progressionNote,
      injuryNote: injuryNote,
    );
  }

  // ── Step 1: Selecionar Divisão ────────────────────────────────

  String _selectSplit(WorkoutProfile profile) {
    final days = profile.availableDaysPerWeek;
    final level = profile.experienceLevel;
    final goal = profile.primaryGoal;

    if (level == 'beginner') {
      if (days <= 3) return 'full_body';
      return 'upper_lower';
    }

    if (level == 'intermediate') {
      if (days <= 2) return 'full_body';
      if (days == 3) return 'ppl_3days';
      if (days == 4) return 'upper_lower';
      if (days == 5) return 'ppl_ul_hybrid'; // híbrido: Push/Pull/Legs/Upper/Lower
      return 'ppl_6days';
    }

    // Advanced
    if (goal == 'strength') {
      if (days <= 2) return 'full_body';
      if (days == 3) return 'ppl_3days';
      if (days == 4) return 'upper_lower_strength';
      if (days == 5) return 'ppl_ul_hybrid';
      return 'ppl_6days';
    }
    if (days <= 2) return 'full_body';
    if (days <= 3) return 'ppl_3days';
    if (days == 4) return 'upper_lower';
    if (days == 5) return 'arnold'; // Arnold split para avançados com 5-6 dias
    if (days == 6) return 'arnold';
    return 'ppl_6days';
  }

  // ── Step 2: Periodização ──────────────────────────────────────

  String _selectPeriodization(WorkoutProfile profile) {
    if (profile.experienceLevel == 'beginner') return 'linear';
    if (profile.primaryGoal == 'strength') return 'dup';
    if (profile.experienceLevel == 'advanced') return 'block';
    return 'dup'; // intermediários sempre DUP
  }

  int _mesocycleDuration(WorkoutProfile profile) {
    if (profile.experienceLevel == 'beginner') return 8;
    if (profile.experienceLevel == 'intermediate') return 10;
    return 12;
  }

  // ── Step 3: Volumes Semanais (MEV/MRV) ───────────────────────

  Map<String, int> _weeklyVolumes(WorkoutProfile profile) {
    final months = profile.trainingAge;
    final isBeginner = profile.experienceLevel == 'beginner';
    final isAdvanced = profile.experienceLevel == 'advanced';

    // Fator de escala dentro da faixa (0.0 a 1.0) baseado no tempo de treino
    double factor;
    if (isBeginner) {
      factor = (months / 12.0).clamp(0.0, 1.0);
    } else {
      factor = ((months - 12) / 48.0).clamp(0.0, 1.0);
      if (isAdvanced) factor = factor.clamp(0.5, 1.0);
    }

    // Ajuste de recuperação (sono + estresse + BF)
    // Sono ruim + estresse alto => reduzir volume global ~25%
    // BF alto => menor capacidade de ganho, reduzir ~10%
    double recoveryMod = 1.0;
    if (profile.sleepQuality == 'poor') recoveryMod -= 0.15;
    if (profile.stressLevel == 'high') recoveryMod -= 0.10;
    if (profile.bodyFatCategory == 'high') recoveryMod -= 0.10;
    // BF baixo em iniciantes = potencial maior, +5%
    if (profile.bodyFatCategory == 'low' && isBeginner) recoveryMod += 0.05;
    recoveryMod = recoveryMod.clamp(0.65, 1.1);
    final readiness = DailyReadiness.fromProfile(
      sleepQuality: profile.sleepQuality,
      stressLevel: profile.stressLevel,
      lifeLoad: profile.lifeLoad,
    );
    recoveryMod *= readiness.volumeMultiplier;
    if (profile.calibrationActive) recoveryMod *= 0.85;

    // Modificador de idade: não regra rígida, apenas modificador contextual
    final ageVolMod = AgeModifier.volumeModifier(
      age: profile.age,
      experienceLevel: profile.experienceLevel,
      fitnessCapacity: profile.adaptive.volumeTolerance,
      recoveryCapacity: profile.adaptive.recoveryCapacity,
    );
    recoveryMod *= ageVolMod;

    // Helper para extrair volume das faixas
    int getVol(List<int> rangeINI, List<int> rangeINT) {
      final range = isBeginner ? rangeINI : rangeINT;
      return ((range[0] + (range[1] - range[0]) * factor) * recoveryMod).round();
    }

    // Volumes ALVO
    final vChest = getVol([8, 10], [12, 16]);
    final vBack = getVol([10, 12], [14, 20]);
    final vShoulders = getVol([8, 10], [12, 16]);
    final vQuads = getVol([8, 10], [12, 18]);
    final vPostGlute = getVol([6, 8], [10, 16]);
    final vCalves = getVol([8, 10], [12, 16]);
    final vAbs = getVol([4, 6], [6, 12]);

    final vBicepsTarget = getVol([6, 8], [10, 14]);
    final vTricepsTarget = getVol([6, 8], [10, 14]);

    final vBicepsFinal = (vBicepsTarget - (vBack * 0.5)).round().clamp(3, 14);
    final vTricepsFinal = (vTricepsTarget - (vChest * 0.5)).round().clamp(3, 14);

    // Boost para músculos prioritários (+30% volume)
    final priorities = profile.priorityMuscles.toSet();
    int finalVol(int vol, String muscle) {
      double v = vol.toDouble();
      if (priorities.contains(muscle)) v *= 1.3;

      // Dimensão 8 — ADAPTAÇÃO POR TOLERÂNCIA (Adaptive Profile)
      if (profile.adaptive.volumeTolerance == 'high') v *= 1.15;
      if (profile.adaptive.volumeTolerance == 'low') v *= 0.85;
      
      if (profile.adaptive.recoveryCapacity == 'low') v *= 0.9;

      // Adaptação para Corredores (Não sobrecarregar pernas, mas focar em estabilizadores)
      if (profile.primaryGoal == 'running_hybrid') {
        if (muscle == 'quads') v *= 0.6; // Redução maior em quads (fadiga de impacto)
        if (muscle == 'calves') v *= 1.4; // BOOST em panturrilhas (propulsão e prevenção de canelite)
        if (muscle == 'glutes') v *= 1.2; // BOOST em glúteos (estabilidade pélvica)
        if (muscle == 'abs') v *= 1.2; // BOOST em core (postura na corrida)
      }
      
      return v.round().clamp(3, 22);
    }

    return {
      'chest': finalVol(vChest, 'chest'),
      'back': finalVol(vBack, 'back'),
      'shoulders': finalVol(vShoulders, 'shoulders'),
      'side_delt': finalVol((vShoulders * 0.6).round().clamp(4, 12), 'side_delt'),
      'rear_delt': finalVol((vShoulders * 0.5).round().clamp(3, 10), 'rear_delt'),
      'biceps': finalVol(vBicepsFinal, 'biceps'),
      'triceps': finalVol(vTricepsFinal, 'triceps'),
      'quads': finalVol(vQuads, 'quads'),
      'hamstrings': finalVol(vPostGlute, 'hamstrings'),
      'glutes': finalVol((vPostGlute * 0.6).round().clamp(4, 12), 'glutes'),
      'calves': finalVol(vCalves, 'calves'),
      'abs': finalVol(vAbs, 'abs'),
    };
  }

  // ── DUP: fase da sessão ───────────────────────────────────────

  _DupPhase _dupPhase(String periodization, int sessionIndex, int totalSessions) {
    if (periodization == 'linear') return _DupPhase.hypertrophy;
    // Para DUP: alterna Força → Hipertrofia → Resistência
    final phases = [
      _DupPhase.hypertrophy,
      _DupPhase.strength,
      _DupPhase.endurance,
    ];
    return phases[sessionIndex % phases.length];
  }

  // ── Prescrição de sets/reps/descanso por objetivo e DUP ───────

  ({int sets, int repsMin, int repsMax, int rir, int restSeconds, String tempo})
      _prescription(WorkoutProfile profile, ExerciseModel ex, _DupPhase phase) {
    final goal = profile.primaryGoal;
    final isCompound = ex.category == 'compound';

    // Fase DUP sobrescreve o objetivo
    if (phase == _DupPhase.strength) {
      return (
        sets: isCompound ? 4 : 3,
        repsMin: 4, repsMax: 6,
        rir: 1,
        restSeconds: isCompound ? 180 : 120,
        tempo: '1-0-1',
      );
    }

    if (phase == _DupPhase.endurance) {
      return (
        sets: isCompound ? 3 : 2,
        repsMin: 15, repsMax: 20,
        rir: 0,
        restSeconds: 60,
        tempo: '3-1-3',
      );
    }

    // DUP hipertrofia ou periodização linear — baseado no objetivo
    switch (goal) {
      case 'hypertrophy':
        return (
          sets: isCompound ? (profile.experienceLevel == 'beginner' ? 3 : 4) : 3,
          repsMin: 8, repsMax: 12,
          rir: profile.experienceLevel == 'beginner' ? 3 : 2,
          restSeconds: isCompound ? 90 : 60,
          tempo: '2-0-2',
        );
      case 'strength':
        return (
          sets: isCompound ? 5 : 3,
          repsMin: 3, repsMax: 6,
          rir: 1,
          restSeconds: isCompound ? 180 : 120,
          tempo: '1-0-1',
        );
      case 'combat_sports':
        return (
          sets: 4,
          repsMin: 6, repsMax: 10,
          rir: 2,
          restSeconds: 120,
          tempo: 'explosive',
        );
      case 'power_explosive':
        return (
          sets: 5,
          repsMin: 3, repsMax: 5,
          rir: 4,
          restSeconds: 240,
          tempo: 'explosive',
        );
      case 'running_hybrid':
        return (
          sets: 3,
          repsMin: 12, repsMax: 15,
          rir: 2,
          restSeconds: 60,
          tempo: 'controlled',
        );
      case 'athletic_agility':
        return (
          sets: 4,
          repsMin: 8, repsMax: 12,
          rir: 3,
          restSeconds: 90,
          tempo: 'dynamic',
        );
      case 'fat_loss':
        return (
          sets: 3,
          repsMin: 12, repsMax: 20,
          rir: 2,
          restSeconds: 45,
          tempo: '2-0-2',
        );
      case 'general_health':
        return (
          sets: 2,
          repsMin: 12, repsMax: 15,
          rir: 3,
          restSeconds: 75,
          tempo: '2-0-2',
        );
      default:
        return (
          sets: 3,
          repsMin: 8, repsMax: 12,
          rir: 2,
          restSeconds: 90,
          tempo: '2-0-2',
        );
    }
  }

  // ── Prescrição com modificadores de idade ──

  ({int sets, int repsMin, int repsMax, int rir, int restSeconds, String tempo})
      _prescriptionWithAgeModifiers(WorkoutProfile profile, ExerciseModel ex, _DupPhase phase) {
    final base = _prescription(profile, ex, phase);

    // Aplicar modificador de descanso para idade >= 55
    final adjustedRest = AgeModifier.restSecondsModifier(
      age: profile.age,
      experienceLevel: profile.experienceLevel,
      baseRestSeconds: base.restSeconds,
    );

    return (
      sets: base.sets,
      repsMin: base.repsMin,
      repsMax: base.repsMax,
      rir: base.rir,
      restSeconds: adjustedRest,
      tempo: base.tempo,
    );
  }

  // ── Step 4: Construção de Sessões ─────────────────────────────

  List<PrescribedSession> _buildSessions(
    WorkoutProfile profile,
    String splitType,
    String periodization,
  ) {
    switch (splitType) {
      case 'full_body':
        return _buildFullBodySplit(profile, periodization);
      case 'upper_lower':
      case 'upper_lower_strength':
        return _buildUpperLowerSplit(profile, periodization, splitType);
      case 'ppl_3days':
      case 'ppl_5days':
      case 'ppl_ul_hybrid':
      case 'ppl_6days':
      case 'ppl_strength':
        return _buildPPLSplit(profile, periodization, splitType);
      case 'arnold':
        return _buildArnoldSplit(profile, periodization);
      default:
        return _buildFullBodySplit(profile, periodization);
    }
  }


  // ── Full Body ──────────────────────────────────────────────────

  List<PrescribedSession> _buildFullBodySplit(
    WorkoutProfile profile,
    String periodization,
  ) {
    final days = profile.availableDaysPerWeek.clamp(1, 4);
    final vols = _weeklyVolumes(profile);
    final sessions = <PrescribedSession>[];
    final tags = ['A', 'B', 'C', 'D'];

    for (int i = 0; i < days; i++) {
      final tag = tags[i];
      final isA = i.isEven;
      final phase = _dupPhase(periodization, i, days);

      final fatigue = _createFatigueAccumulator();
      final exercises = <PrescribedExercise?>[];

      // Compostos: push horizontal + pull vertical (equilíbrio 1:1)
      exercises.add(_pick('chest', isA ? 'push_horizontal' : 'push_incline',
          profile, vols, days, slot: i, phase: phase, fatigue: fatigue));
      exercises.add(_pick('back', isA ? 'pull_vertical' : 'pull_horizontal',
          profile, vols, days, slot: i, phase: phase, fatigue: fatigue));
      exercises.add(_pick('quads', 'squat', profile, vols, days, slot: i, phase: phase, fatigue: fatigue));
      exercises.add(_pick('hamstrings', 'hinge', profile, vols, days, slot: i, phase: phase, fatigue: fatigue));
      exercises.add(_pick('shoulders', 'push_vertical', profile, vols, days,
          slot: i, phase: phase, setsModifier: 1, fatigue: fatigue));
      // Isoladores (Murer 2019: opcional para iniciantes, importante para intermediários+)
      if (profile.experienceLevel != 'beginner') {
        exercises.add(_pick('biceps', 'isolation', profile, vols, days,
            slot: i, phase: phase, forceIsolation: true, fatigue: fatigue));
        exercises.add(_pick('triceps', 'isolation', profile, vols, days,
            slot: i, phase: phase, forceIsolation: true, fatigue: fatigue));
      }

      final rehabExs = _buildRehabBlock(profile, days);
      final dupLabel = _dupLabel(phase, periodization);

      sessions.add(PrescribedSession(
        id: 'session_fb_$tag',
        name: 'Full Body $tag$dupLabel',
        objective: _sessionObjective(profile.primaryGoal, 'full_body', phase),
        estimatedDurationMinutes: profile.sessionDurationMinutes,
        warmupInstructions: _warmup('full_body', profile),
        exercises: [
          ...exercises.where((e) => e != null).cast<PrescribedExercise>(),
          ...rehabExs,
        ],
        progressionNote: _progressionNote(profile, periodization, phase),
        fatigue: _fatigueMetrics(fatigue),
      ));
    }

    return sessions;
  }

  // ── Upper / Lower ──────────────────────────────────────────────

  List<PrescribedSession> _buildUpperLowerSplit(
    WorkoutProfile profile,
    String periodization,
    String splitType,
  ) {
    final vols = _weeklyVolumes(profile);
    final isStrength = splitType.contains('strength');
    final sessions = <PrescribedSession>[];

    // DUP: sessões A e B têm fases diferentes
    final phaseUpperA = _dupPhase(periodization, 0, 4);
    final phaseLowerA = _dupPhase(periodization, 1, 4);
    final phaseUpperB = _dupPhase(periodization, 2, 4);
    final phaseLowerB = _dupPhase(periodization, 3, 4);

    sessions.add(_buildUpperSession('A', profile, vols, isStrength, slot: 0, phase: phaseUpperA, periodization: periodization));
    sessions.add(_buildLowerSession('A', profile, vols, isStrength, slot: 0, phase: phaseLowerA, periodization: periodization));

    if (profile.availableDaysPerWeek >= 4) {
      sessions.add(_buildUpperSession('B', profile, vols, isStrength, slot: 1, phase: phaseUpperB, periodization: periodization));
      sessions.add(_buildLowerSession('B', profile, vols, isStrength, slot: 1, phase: phaseLowerB, periodization: periodization));
    }

    return sessions;
  }

  PrescribedSession _buildUpperSession(
    String tag,
    WorkoutProfile profile,
    Map<String, int> vols,
    bool isStrength, {
    required int slot,
    required _DupPhase phase,
    required String periodization,
  }) {
    final isA = slot.isEven;
    final exercises = <PrescribedExercise?>[];
    final fatigue = _createFatigueAccumulator();
    final dupLabel = _dupLabel(phase, periodization);

    // Push composto
    exercises.add(_pick('chest', isA ? 'push_horizontal' : 'push_incline',
        profile, vols, 2, slot: slot, phase: phase, setsModifier: 2, fatigue: fatigue));
    // Pull vertical (garante equilíbrio push:pull)
    exercises.add(_pick('back', isA ? 'pull_vertical' : 'pull_horizontal',
        profile, vols, 2, slot: slot, phase: phase, setsModifier: 2, fatigue: fatigue));
    // Pull horizontal (2º puxada para ratio >=1:1)
    exercises.add(_pick('back', isA ? 'pull_horizontal' : 'pull_vertical',
        profile, vols, 2, slot: slot + 5, phase: phase, setsModifier: 1, fatigue: fatigue));
    // Ombros
    exercises.add(_pick('shoulders', 'push_vertical', profile, vols, 2,
        slot: slot, phase: phase, setsModifier: 1, fatigue: fatigue));
    // Isoladores (intermediários+)
    if (profile.experienceLevel != 'beginner') {
      exercises.add(_pick('triceps', 'isolation', profile, vols, 2,
          slot: slot, phase: phase, forceIsolation: true, fatigue: fatigue));
      exercises.add(_pick('biceps', 'isolation', profile, vols, 2,
          slot: slot, phase: phase, forceIsolation: true, fatigue: fatigue));
    }
    if (profile.sessionDurationMinutes >= 60 && profile.experienceLevel != 'beginner') {
      exercises.add(_pick('side_delt', 'isolation', profile, vols, 2,
          slot: slot, phase: phase, forceIsolation: true, fatigue: fatigue));
    }

    // Obrigatório: exercício escapular por sessão Upper (previne impingement)
    exercises.add(_pickScapularExercise(profile, vols, fatigue));

    final rehabExs = _buildRehabBlockUpper(profile, 2);

    return PrescribedSession(
      id: 'session_upper_$tag',
      name: 'Superior $tag$dupLabel',
      objective: _sessionObjective(profile.primaryGoal, 'upper', phase),
      estimatedDurationMinutes: profile.sessionDurationMinutes,
      warmupInstructions: _warmup('upper', profile),
      exercises: [
        ...exercises.where((e) => e != null).cast<PrescribedExercise>(),
        ...rehabExs,
      ],
      progressionNote: _progressionNote(profile, periodization, phase),
      fatigue: _fatigueMetrics(fatigue),
    );
  }

  PrescribedSession _buildLowerSession(
    String tag,
    WorkoutProfile profile,
    Map<String, int> vols,
    bool isStrength, {
    required int slot,
    required _DupPhase phase,
    required String periodization,
  }) {
    final exercises = <PrescribedExercise?>[];
    final fatigue = _createFatigueAccumulator();
    final dupLabel = _dupLabel(phase, periodization);

    exercises.add(_pick('quads', 'squat', profile, vols, 2,
        slot: slot, phase: phase, setsModifier: 2, fatigue: fatigue));
    exercises.add(_pick('hamstrings', 'hinge', profile, vols, 2,
        slot: slot, phase: phase, setsModifier: 2, fatigue: fatigue));
    exercises.add(_pick('glutes', 'hinge', profile, vols, 2,
        slot: slot, phase: phase, setsModifier: 1, fatigue: fatigue));
    if (!profile.healthRestrictions.contains('knee')) {
      exercises.add(_pick('quads', 'isolation', profile, vols, 2,
          slot: slot + 5, phase: phase, forceIsolation: true, fatigue: fatigue));
    }
    exercises.add(_pick('hamstrings', 'isolation', profile, vols, 2,
        slot: slot + 5, phase: phase, forceIsolation: true, fatigue: fatigue));
    exercises.add(_pick('calves', 'isolation', profile, vols, 2,
        slot: slot, phase: phase, setsModifier: 2, forceIsolation: true, fatigue: fatigue));
    if (profile.sessionDurationMinutes >= 60) {
      exercises.add(_pick('abs', 'isolation', profile, vols, 2,
          slot: slot, phase: phase, forceIsolation: true, fatigue: fatigue));
    }

    final rehabExs = _buildRehabBlockLower(profile, 2);

    return PrescribedSession(
      id: 'session_lower_$tag',
      name: 'Inferior $tag$dupLabel',
      objective: _sessionObjective(profile.primaryGoal, 'lower', phase),
      estimatedDurationMinutes: profile.sessionDurationMinutes,
      warmupInstructions: _warmup('lower', profile),
      exercises: [
        ...exercises.where((e) => e != null).cast<PrescribedExercise>(),
        ...rehabExs,
      ],
      progressionNote: _progressionNote(profile, periodization, phase),
      fatigue: _fatigueMetrics(fatigue),
    );
  }

  // ── PPL (Push / Pull / Legs) ───────────────────────────────────

  List<PrescribedSession> _buildPPLSplit(
    WorkoutProfile profile,
    String periodization,
    String splitType,
  ) {
    final vols = _weeklyVolumes(profile);
    final sessions = <PrescribedSession>[];
    final double6 = splitType == 'ppl_6days';

    sessions.add(_buildPushSession('A', profile, vols, slot: 0, periodization: periodization, phase: _dupPhase(periodization, 0, 3)));
    sessions.add(_buildPullSession('A', profile, vols, slot: 0, periodization: periodization, phase: _dupPhase(periodization, 1, 3)));
    sessions.add(_buildLegsSession('A', profile, vols, slot: 0, periodization: periodization, phase: _dupPhase(periodization, 2, 3)));

    if (double6) {
      sessions.add(_buildPushSession('B', profile, vols, slot: 1, periodization: periodization, phase: _dupPhase(periodization, 3, 3)));
      sessions.add(_buildPullSession('B', profile, vols, slot: 1, periodization: periodization, phase: _dupPhase(periodization, 4, 3)));
      sessions.add(_buildLegsSession('B', profile, vols, slot: 1, periodization: periodization, phase: _dupPhase(periodization, 5, 3)));
    } else if (splitType == 'ppl_5days' || splitType == 'ppl_ul_hybrid') {
      // Híbrido real: Push / Pull / Legs / Upper / Lower.
      sessions.add(_buildUpperSession('B', profile, vols, false,
          slot: 1,
          phase: _dupPhase(periodization, 3, 5),
          periodization: periodization));
      sessions.add(_buildLowerSession('B', profile, vols, false,
          slot: 1,
          phase: _dupPhase(periodization, 4, 5),
          periodization: periodization));
    }

    return sessions;
  }

  PrescribedSession _buildPushSession(
    String tag,
    WorkoutProfile profile,
    Map<String, int> vols, {
    required int slot,
    required String periodization,
    required _DupPhase phase,
  }) {
    final isA = slot.isEven;
    final exercises = <PrescribedExercise?>[];
    final fatigue = _createFatigueAccumulator();
    final dupLabel = _dupLabel(phase, periodization);

    exercises.add(_pick('chest', isA ? 'push_horizontal' : 'push_incline',
        profile, vols, 3, slot: slot, phase: phase, setsModifier: 2, fatigue: fatigue));
    exercises.add(_pick('shoulders', 'push_vertical', profile, vols, 3,
        slot: slot, phase: phase, setsModifier: 2, fatigue: fatigue));
    exercises.add(_pick('chest', 'isolation', profile, vols, 3,
        slot: slot, phase: phase, forceIsolation: true, fatigue: fatigue));
    exercises.add(_pick('side_delt', 'isolation', profile, vols, 3,
        slot: slot, phase: phase, forceIsolation: true, fatigue: fatigue));
    exercises.add(_pick('triceps', 'isolation', profile, vols, 3,
        slot: slot, phase: phase, fatigue: fatigue));
    if (profile.sessionDurationMinutes >= 60) {
      exercises.add(_pick('triceps', 'isolation', profile, vols, 3,
          slot: slot + 10, phase: phase, fatigue: fatigue));
    }
    exercises.add(_pickScapularExercise(profile, vols, fatigue));

    final rehabExs = _buildRehabBlockUpper(profile, 3);

    return PrescribedSession(
      id: 'session_push_$tag',
      name: 'Push (Empurrar) $tag$dupLabel',
      objective: 'Peito, ombros e tríceps — ${_phaseLabel(phase)}',
      estimatedDurationMinutes: profile.sessionDurationMinutes,
      warmupInstructions: _warmup('push', profile),
      exercises: [
        ...exercises.where((e) => e != null).cast<PrescribedExercise>(),
        ...rehabExs,
      ],
      progressionNote: _progressionNote(profile, periodization, phase),
      fatigue: _fatigueMetrics(fatigue),
    );
  }

  PrescribedSession _buildPullSession(
    String tag,
    WorkoutProfile profile,
    Map<String, int> vols, {
    required int slot,
    required String periodization,
    required _DupPhase phase,
  }) {
    final isA = slot.isEven;
    final exercises = <PrescribedExercise?>[];
    final fatigue = _createFatigueAccumulator();
    final dupLabel = _dupLabel(phase, periodization);

    exercises.add(_pick('back', isA ? 'pull_vertical' : 'pull_horizontal',
        profile, vols, 3, slot: slot, phase: phase, setsModifier: 2, fatigue: fatigue));
    exercises.add(_pick('back', isA ? 'pull_horizontal' : 'pull_vertical', profile, vols, 3,
        slot: slot, phase: phase, setsModifier: 2, fatigue: fatigue));
    exercises.add(_pick('back', 'pull_horizontal', profile, vols, 3,
        slot: slot + 5, phase: phase, setsModifier: 1, fatigue: fatigue));
    exercises.add(_pick('rear_delt', 'pull_horizontal', profile, vols, 3,
        slot: slot, phase: phase, forceIsolation: true, fatigue: fatigue));
    exercises.add(_pick('biceps', 'isolation', profile, vols, 3,
        slot: slot, phase: phase, fatigue: fatigue));
    if (profile.sessionDurationMinutes >= 60) {
      exercises.add(_pick('biceps', 'isolation', profile, vols, 3,
          slot: slot + 10, phase: phase, fatigue: fatigue));
    }

    return PrescribedSession(
      id: 'session_pull_$tag',
      name: 'Pull (Puxar) $tag$dupLabel',
      objective: 'Costas, bíceps e deltóide posterior — ${_phaseLabel(phase)}',
      estimatedDurationMinutes: profile.sessionDurationMinutes,
      warmupInstructions: _warmup('pull', profile),
      exercises: exercises.where((e) => e != null).cast<PrescribedExercise>().toList(),
      progressionNote: _progressionNote(profile, periodization, phase),
      fatigue: _fatigueMetrics(fatigue),
    );
  }

  PrescribedSession _buildLegsSession(
    String tag,
    WorkoutProfile profile,
    Map<String, int> vols, {
    required int slot,
    required String periodization,
    required _DupPhase phase,
  }) {
    final exercises = <PrescribedExercise?>[];
    final fatigue = _createFatigueAccumulator();
    final dupLabel = _dupLabel(phase, periodization);
    final hasKneeInjury = profile.healthRestrictions.contains('knee');

    exercises.add(_pick('quads', 'squat', profile, vols, 3,
        slot: slot, phase: phase, setsModifier: 2, fatigue: fatigue));
    exercises.add(_pick('hamstrings', 'hinge', profile, vols, 3,
        slot: slot, phase: phase, setsModifier: 2, fatigue: fatigue));
    exercises.add(_pick('glutes', 'hinge', profile, vols, 3,
        slot: slot, phase: phase, setsModifier: 1, fatigue: fatigue));
    if (!hasKneeInjury) {
      exercises.add(_pick('quads', 'isolation', profile, vols, 3,
          slot: slot, phase: phase, forceIsolation: true, fatigue: fatigue));
    }
    exercises.add(_pick('hamstrings', 'isolation', profile, vols, 3,
        slot: slot, phase: phase, forceIsolation: true, fatigue: fatigue));
    exercises.add(_pick('calves', 'isolation', profile, vols, 3,
        slot: slot, phase: phase, setsModifier: 2, forceIsolation: true, fatigue: fatigue));
    if (profile.sessionDurationMinutes >= 60) {
      exercises.add(_pick('abs', 'isolation', profile, vols, 3,
          slot: slot, phase: phase, forceIsolation: true, fatigue: fatigue));
    }

    final rehabExs = _buildRehabBlockLower(profile, 3);

    return PrescribedSession(
      id: 'session_legs_$tag',
      name: 'Pernas $tag$dupLabel',
      objective: 'Quadríceps, posteriores, glúteos e panturrilhas — ${_phaseLabel(phase)}',
      estimatedDurationMinutes: profile.sessionDurationMinutes,
      warmupInstructions: _warmup('lower', profile),
      exercises: [
        ...exercises.where((e) => e != null).cast<PrescribedExercise>(),
        ...rehabExs,
      ],
      progressionNote: _progressionNote(profile, periodization, phase),
      fatigue: _fatigueMetrics(fatigue),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // ARNOLD SPLIT
  //
  // Arnold Schwarzenegger: Chest/Back, Shoulders/Arms, Legs
  // Alta frequência para upper, bom para avançados + hipertrofia
  // Referência: Encyclopedia of Modern Bodybuilding
  // ═══════════════════════════════════════════════════════════════

  List<PrescribedSession> _buildArnoldSplit(
    WorkoutProfile profile,
    String periodization,
  ) {
    final vols = _weeklyVolumes(profile);
    final sessions = <PrescribedSession>[];

    // A: Chest + Back (agonista-antagonista, Arnold 1980)
    final fatigueA = _createFatigueAccumulator();
    final phaseA = _dupPhase(periodization, 0, 6);
    final exercisesA = <PrescribedExercise?>[];

    // Push horizontal + Pull vertical (par agonista-antagonista)
    exercisesA.add(_pick('chest', 'push_horizontal', profile, vols, 3,
        slot: 0, phase: phaseA, setsModifier: 2, fatigue: fatigueA));
    exercisesA.add(_pick('back', 'pull_vertical', profile, vols, 3,
        slot: 0, phase: phaseA, setsModifier: 2, fatigue: fatigueA));
    // Push inclinado + Pull horizontal
    exercisesA.add(_pick('chest', 'push_incline', profile, vols, 3,
        slot: 1, phase: phaseA, setsModifier: 2, fatigue: fatigueA));
    exercisesA.add(_pick('back', 'pull_horizontal', profile, vols, 3,
        slot: 1, phase: phaseA, setsModifier: 2, fatigue: fatigueA));
    // Isolador peito + Isolador costas
    exercisesA.add(_pick('chest', 'isolation', profile, vols, 3,
        slot: 2, phase: phaseA, forceIsolation: true, fatigue: fatigueA));
    // Scapular obrigatório
    exercisesA.add(_pickScapularExercise(profile, vols, fatigueA));

    sessions.add(PrescribedSession(
      id: 'session_arnold_chestback',
      name: 'Peito & Costas${_dupLabel(phaseA, periodization)}',
      objective: 'Peito e costas — antagonista (${_phaseLabel(phaseA)})',
      estimatedDurationMinutes: profile.sessionDurationMinutes,
      warmupInstructions: _warmup('push', profile),
      exercises: [...exercisesA.where((e) => e != null).cast<PrescribedExercise>(),
        ..._buildRehabBlockUpper(profile, 3)],
      progressionNote: _progressionNote(profile, periodization, phaseA),
      fatigue: _fatigueMetrics(fatigueA),
    ));

    // B: Shoulders + Arms
    final fatigueB = _createFatigueAccumulator();
    final phaseB = _dupPhase(periodization, 1, 6);
    final exercisesB = <PrescribedExercise?>[];

    exercisesB.add(_pick('shoulders', 'push_vertical', profile, vols, 3,
        slot: 0, phase: phaseB, setsModifier: 2, fatigue: fatigueB));
    exercisesB.add(_pick('shoulders', 'isolation', profile, vols, 3,
        slot: 0, phase: phaseB, forceIsolation: true, fatigue: fatigueB));
    exercisesB.add(_pick('side_delt', 'isolation', profile, vols, 3,
        slot: 0, phase: phaseB, forceIsolation: true, fatigue: fatigueB));
    exercisesB.add(_pick('rear_delt', 'isolation', profile, vols, 3,
        slot: 0, phase: phaseB, forceIsolation: true, fatigue: fatigueB));
    exercisesB.add(_pick('biceps', 'isolation', profile, vols, 3,
        slot: 0, phase: phaseB, forceIsolation: true, fatigue: fatigueB));
    exercisesB.add(_pick('triceps', 'isolation', profile, vols, 3,
        slot: 0, phase: phaseB, forceIsolation: true, fatigue: fatigueB));
    exercisesB.add(_pickScapularExercise(profile, vols, fatigueB));

    sessions.add(PrescribedSession(
      id: 'session_arnold_shoulders_arms',
      name: 'Ombros & Braços${_dupLabel(phaseB, periodization)}',
      objective: 'Ombros, bíceps e tríceps — ${_phaseLabel(phaseB)}',
      estimatedDurationMinutes: profile.sessionDurationMinutes,
      warmupInstructions: _warmup('push', profile),
      exercises: [...exercisesB.where((e) => e != null).cast<PrescribedExercise>(),
        ..._buildRehabBlockUpper(profile, 3)],
      progressionNote: _progressionNote(profile, periodization, phaseB),
      fatigue: _fatigueMetrics(fatigueB),
    ));

    // C: Legs
    sessions.add(_buildLegsSession('A', profile, vols,
        slot: 0, periodization: periodization, phase: _dupPhase(periodization, 2, 3)));

    // Para 5 dias: só A, B, C + variações de A e B
    if (profile.availableDaysPerWeek >= 5) {
      // D: Chest + Back variante B
      final fatigueD = _createFatigueAccumulator();
      final phaseD = _dupPhase(periodization, 3, 6);
      final exercisesD = <PrescribedExercise?>[];
      exercisesD.add(_pick('chest', 'push_incline', profile, vols, 3,
          slot: 5, phase: phaseD, setsModifier: 2, fatigue: fatigueD));
      exercisesD.add(_pick('back', 'pull_horizontal', profile, vols, 3,
          slot: 5, phase: phaseD, setsModifier: 2, fatigue: fatigueD));
      exercisesD.add(_pick('chest', 'isolation', profile, vols, 3,
          slot: 6, phase: phaseD, forceIsolation: true, fatigue: fatigueD));
      exercisesD.add(_pick('back', 'pull_vertical', profile, vols, 3,
          slot: 6, phase: phaseD, setsModifier: 1, fatigue: fatigueD));
      exercisesD.add(_pickScapularExercise(profile, vols, fatigueD));

      sessions.add(PrescribedSession(
        id: 'session_arnold_chestback_b',
        name: 'Peito & Costas B${_dupLabel(phaseD, periodization)}',
        objective: 'Peito e costas (variante) — ${_phaseLabel(phaseD)}',
        estimatedDurationMinutes: profile.sessionDurationMinutes,
        warmupInstructions: _warmup('push', profile),
        exercises: [...exercisesD.where((e) => e != null).cast<PrescribedExercise>(),
          ..._buildRehabBlockUpper(profile, 3)],
        progressionNote: _progressionNote(profile, periodization, phaseD),
        fatigue: _fatigueMetrics(fatigueD),
      ));

      // E: Shoulders + Arms variante B
      final fatigueE = _createFatigueAccumulator();
      final phaseE = _dupPhase(periodization, 4, 6);
      final exercisesE = <PrescribedExercise?>[];
      exercisesE.add(_pick('shoulders', 'push_vertical', profile, vols, 3,
          slot: 7, phase: phaseE, setsModifier: 2, fatigue: fatigueE));
      exercisesE.add(_pick('side_delt', 'isolation', profile, vols, 3,
          slot: 7, phase: phaseE, forceIsolation: true, fatigue: fatigueE));
      exercisesE.add(_pick('biceps', 'isolation', profile, vols, 3,
          slot: 7, phase: phaseE, forceIsolation: true, fatigue: fatigueE));
      exercisesE.add(_pick('triceps', 'isolation', profile, vols, 3,
          slot: 7, phase: phaseE, forceIsolation: true, fatigue: fatigueE));
      exercisesE.add(_pickScapularExercise(profile, vols, fatigueE));

      sessions.add(PrescribedSession(
        id: 'session_arnold_shoulders_arms_b',
        name: 'Ombros & Braços B${_dupLabel(phaseE, periodization)}',
        objective: 'Ombros e braços (variante) — ${_phaseLabel(phaseE)}',
        estimatedDurationMinutes: profile.sessionDurationMinutes,
        warmupInstructions: _warmup('push', profile),
        exercises: [...exercisesE.where((e) => e != null).cast<PrescribedExercise>(),
          ..._buildRehabBlockUpper(profile, 3)],
        progressionNote: _progressionNote(profile, periodization, phaseE),
        fatigue: _fatigueMetrics(fatigueE),
      ));
    }

    // Para 6 dias: add Legs B
    if (profile.availableDaysPerWeek >= 6) {
      sessions.add(_buildLegsSession('B', profile, vols,
          slot: 1, periodization: periodization, phase: _dupPhase(periodization, 5, 3)));
    }

    return sessions;
  }

  // ═══════════════════════════════════════════════════════════════
  // SELEÇÃO INTELIGENTE DE EXERCÍCIO
  // ═══════════════════════════════════════════════════════════════

  /// Calcula a posição do exercício para um músculo baseado no acumulador de fadiga.
  int _getExercisePositionForMuscle(String muscle, SessionFatigueAccumulator? fatigue) {
    if (fatigue == null) return 0;
    // Contar quantos exercícios já foram adicionados para este músculo
    return fatigue.getExerciseCountForMuscle(muscle);
  }

  PrescribedExercise? _pick(
    String muscle,
    String pattern,
    WorkoutProfile profile,
    Map<String, int> vols,
    int sessionsPerWeek, {
    int slot = 0,
    bool forceIsolation = false,
    int setsModifier = 1,
    required _DupPhase phase,
    SessionFatigueAccumulator? fatigue,
    int exercisePosition = 0, // posição do músculo na sessão (0 = primeiro)
  }) {
    final candidates = _filterCandidates(
      muscle: muscle,
      pattern: pattern,
      profile: profile,
      forceIsolation: forceIsolation,
    );

    if (candidates.isEmpty) return null;

    // Calcular exercisePosition automaticamente baseado no volume do músculo
    // Se já há exercícios para este músculo na sessão, incrementar posição
    final effectivePosition = exercisePosition == 0 
        ? _getExercisePositionForMuscle(muscle, fatigue)
        : exercisePosition;

    // Algoritmo de score: seleciona o melhor exercício por contexto
    // Em vez de seed aleatório, calcula pontuação baseada em:
    // - Necessidade de músculo / pattern faltando (positivo)
    // - Fadiga acumulada (penalidade)
    // - Pattern usado ontem (penalidade)
    // - Skill > nível do usuário (penalidade)
    // - Bonus lengthened (Schoenfeld 2021)

    ExerciseModel? bestEx;
    double bestScore = -double.infinity;

    for (final candidate in candidates) {
      double score = 0;
      final dna = ExerciseDna.fromExercise(candidate);
      final desiredCapabilities = _desiredCapabilities(profile);

      // Positivos
      score += 2.0; // baseline
      if (profile.preferredStyle == 'compound_focus' &&
          candidate.category == 'compound') {
        score += 1.0;
      }
      if (profile.preferredStyle == 'isolation_focus' &&
          candidate.category == 'isolation') {
        score += 1.0;
      }
      score += desiredCapabilities
              .where(dna.capabilities.contains)
              .length *
          0.8;
      // Em sessões curtas, densidade de função e baixo custo têm prioridade.
      score -= dna.recoveryCost * 0.75;
      if (profile.sessionDurationMinutes <= 45) {
        score -= dna.technicalDemand * 0.5;
      }
      if (profile.calibrationActive) {
        score -= dna.technicalDemand * 1.0;
      }

      // Modificador de complexidade por idade (AgeModifier)
      final complexityMod = AgeModifier.complexityModifier(
        age: profile.age,
        experienceLevel: profile.experienceLevel,
        fitnessCapacity: profile.adaptive.volumeTolerance,
      );
      // Penalizar exercícios complexos para usuários com menor capacidade
      if (complexityMod < 1.0) {
        score -= dna.technicalDemand * (1.0 - complexityMod) * 2.0;
      }

      // Penalidade de fadiga
      if (fatigue != null) {
        score -= fatigue.spinalLoadAccumulated * candidate.spinalLoad * 1.5;
        score -= fatigue.shoulderStressAccumulated * candidate.shoulderStress * 1.5;
        score -= fatigue.kneeStressAccumulated * candidate.kneeStress * 1.5;
      }

      // Penalidade de pattern entre dias
      final patternAvailability = _patternHistory.patternAvailability(candidate.movementPattern);
      score -= (1.0 - patternAvailability) * 2.0;

      // Penalidade de skill > nível
      final levelMax = profile.experienceLevel == 'beginner' ? 2 : profile.experienceLevel == 'intermediate' ? 4 : 5;
      if (candidate.skillLevel > levelMax) {
        score -= 3.0;
      }

      // Length bias balancing (Schoenfeld 2021)
      // Primeiro exercício do músculo: favorece posição alongada
      // Exercícios seguintes: favorece mid_range ou posição encurtada
      if (effectivePosition == 0) {
        if (candidate.lengthBias == 'lengthened') score += 1.0;
        if (candidate.lengthBias == 'shortened') score -= 0.5;
      } else if (effectivePosition == 1) {
        if (candidate.lengthBias == 'mid_range' || candidate.lengthBias == 'shortened') {
          score += 0.8;
        }
      } else {
        if (candidate.lengthBias == 'shortened') score += 0.6;
      }

      // Bonus exercício favorito (aderência)
      if (profile.favoriteExercises.contains(candidate.id)) {
        score += 2.0;
      }

      // Bonus de idade: exercícios funcionais/unilaterais para 50+
      if (profile.age >= 50) {
        if (candidate.isUnilateral) score += 1.5;
        if (candidate.movementPattern == 'squat' || candidate.movementPattern == 'hinge') {
          score += 0.8; // Exercícios fundamentais
        }
      }
      if (AgeModifier.shouldPrioritizeFunctional(
        age: profile.age,
        experienceLevel: profile.experienceLevel,
        fitnessCapacity: profile.adaptive.volumeTolerance,
      )) {
        score += AgeModifier.functionalBonus(
          age: profile.age,
          experienceLevel: profile.experienceLevel,
          primaryGoal: profile.primaryGoal,
        );
      }

      // Seed como tiebreaker determinístico
      score += ((_seed + slot + candidate.id.hashCode).abs() % 100) * 0.01;

      // Bonus de Especificidade por Objetivo (Dimenso 8)
      if (profile.primaryGoal == 'combat_sports') {
        if (candidate.movementPattern == 'rotation') score += 5.0; // PRIORIDADE MÁXIMA
        if (candidate.movementPattern == 'carry') score += 3.0;
        if (candidate.movementPattern == 'isometric') score += 2.0;
        if (candidate.equipment.contains('cable') || candidate.equipment.contains('kettlebell')) score += 1.5;
        if (candidate.tags.contains('explosive') || candidate.tags.contains('combat')) score += 4.0;
      } else if (profile.primaryGoal == 'running_hybrid') {
         if (candidate.isUnilateral) score += 5.0; // PRIORIDADE MÁXIMA PARA CORRIDA
         if (candidate.primaryMuscles.contains('calves') || candidate.primaryMuscles.contains('glutes')) score += 2.0;
         if (candidate.movementPattern == 'carry') score += 1.5;
      } else if (profile.primaryGoal == 'athletic_agility') {
         if (candidate.movementPattern == 'rotation' || candidate.movementPattern == 'carry') score += 2.5;
         if (candidate.equipment.contains('medicine_ball') || candidate.equipment.contains('band')) score += 1.5;
      }

      if (score > bestScore) {
        bestScore = score;
        bestEx = candidate;
      }
    }

    if (bestEx == null) return null;

    final weeklyVol = vols[muscle] ?? 10;
    final freqPerWeek = max(1, sessionsPerWeek ~/ 2 + 1);
    final rawSets = (weeklyVol / freqPerWeek).ceil();
    final baseSets = (rawSets * setsModifier).clamp(2, 5);
    final sets = phase == _DupPhase.strength ? min(baseSets + 1, 5) : baseSets;

    // Verifica se pode adicionar sem estourar fatigue.
    if (fatigue != null) {
      if (!fatigue.canAdd(bestEx, sets)) {
        // Candidata alternativa com menos fadiga
        final safeCands = candidates.where((c) {
          return fatigue.canAdd(c, sets) && c.id != bestEx!.id;
        }).toList()
          ..sort((a, b) => _scoreExercise(b, profile, fatigue, slot)
              .compareTo(_scoreExercise(a, profile, fatigue, slot)));
        if (safeCands.isNotEmpty) bestEx = safeCands.first;
        // Sem alternativa segura, não prescreve este slot.
        if (!fatigue.canAdd(bestEx, sets)) return null;
      }
    }

    final ex = bestEx;

    // Rotação semanal: troca exercício similar se semana > 1
    final rotatedId = _rotation.resolveExercise(
      ex.id,
      weekNumber: _weekNumber,
      favorites: profile.favoriteExercises,
      disliked: profile.dislikedExercises,
      rotationSeed: _seed,
      filter: (candidate) {
        return ExerciseCompatibility.isCompatible(profile, candidate);
      },
    );
    final rotatedEx = rotatedId != ex.id
        ? _library.firstWhere((e) => e.id == rotatedId, orElse: () => ex)
        : ex;
    var finalEx = ExerciseCompatibility.isCompatible(profile, rotatedEx)
        ? rotatedEx
        : ex;
    if (fatigue != null && !fatigue.canAdd(finalEx, sets)) {
      if (!fatigue.canAdd(ex, sets)) return null;
      finalEx = ex;
    }
    if (fatigue != null) fatigue.add(finalEx, sets);
    final rx = _prescriptionWithAgeModifiers(profile, finalEx, phase);
    final sessionCues = [
      ...finalEx.cues.take(2),
      'ROM completa — amplitude máxima segura em cada repetição.',
    ];

    final wasRotated = rotatedId != ex.id;
    final decisionReason = wasRotated
        ? 'Exercício rotacionado de ${ex.name} para ${finalEx.name} (variação semanal) [score: ${bestScore.toStringAsFixed(1)}]'
        : 'Selecionado para $muscle com padrão $pattern (compatível com seu ambiente) [score: ${bestScore.toStringAsFixed(1)}]';

    return PrescribedExercise(
      exercise: finalEx,
      sets: phase == _DupPhase.strength ? min(baseSets + 1, 5) : baseSets,
      repsMin: rx.repsMin,
      repsMax: rx.repsMax,
      rir: rx.rir,
      restSeconds: rx.restSeconds,
      sessionCues: sessionCues,
      progressionNote: _exerciseProgressionNote(finalEx, profile, phase),
      tempo: rx.tempo,
      decisionReason: decisionReason,
    );
  }

  double _scoreExercise(
    ExerciseModel ex,
    WorkoutProfile profile,
    SessionFatigueAccumulator fatigue,
    int slot, {
    int exercisePosition = 1,
  }) {
    double score = 0;
    score += 2.0;
    score -= fatigue.spinalLoadAccumulated * ex.spinalLoad * 1.5;
    score -= fatigue.shoulderStressAccumulated * ex.shoulderStress * 1.5;
    score -= fatigue.kneeStressAccumulated * ex.kneeStress * 1.5;
    score -= (1.0 - _patternHistory.patternAvailability(ex.movementPattern)) * 2.0;
    final levelMax = profile.experienceLevel == 'beginner'
        ? 2
        : profile.experienceLevel == 'intermediate'
            ? 4
            : 5;
    if (ex.skillLevel > levelMax) score -= 3.0;
    // Length bias (position-aware)
    if (exercisePosition == 0) {
      if (ex.lengthBias == 'lengthened') score += 1.0;
      if (ex.lengthBias == 'shortened') score -= 0.5;
    } else {
      if (ex.lengthBias == 'shortened') score += 0.6;
    }
    if (profile.favoriteExercises.contains(ex.id)) score += 2.0;

    // Bonus de Especificidade por Objetivo (Dimenso 8)
    if (profile.primaryGoal == 'combat_sports') {
      if (ex.movementPattern == 'rotation') score += 5.0;
      if (ex.movementPattern == 'carry') score += 3.0;
      if (ex.tags.contains('explosive') || ex.tags.contains('combat')) score += 4.0;
    } else if (profile.primaryGoal == 'power_explosive') {
      if (ex.tags.contains('explosive')) score += 5.0;
    }

    score += ((_seed + slot + ex.id.hashCode).abs() % 100) * 0.01;
    return score;
  }

  // ═══════════════════════════════════════════════════════════════
  // EXERCÍCIO ESCAPULAR OBRIGATÓRIO (Upper sessions)
  //
  // Previne impingement selecionando exercícios de estabilidade
  // escapular com prioridade: face pull, Y-raise, external rotation.
  // NUNCA é pulado — é o seguro do treino upper.
  // ═══════════════════════════════════════════════════════════════

  PrescribedExercise? _pickScapularExercise(
    WorkoutProfile profile,
    Map<String, int> vols,
    SessionFatigueAccumulator fatigue,
  ) {
    // Exercícios scapulares por ambiente
    final isHome = ExerciseCompatibility.isHome(profile.environment);
    
    List<String> scapularIds;
    if (isHome) {
      // Para casa: apenas exercícios bodyweight
      scapularIds = [
        'scapular_push_up',
        'prone_scapular_retraction',
        'wall_scapular_slide',
      ];
    } else {
      // Para academia: todos os exercícios scapulares
      scapularIds = [
        'face_pull',
        'scapular_push_up',
        'prone_scapular_retraction',
        'wall_scapular_slide',
        'scapular_pull_up',
      ];
    }

    // Filtrar exercícios que existem na biblioteca e são compatíveis
    final availableExercises = <ExerciseModel>[];
    for (final id in scapularIds) {
      final ex = _library.firstWhere(
        (e) => e.id == id,
        orElse: () => ExerciseModel(
          id: '', name: '', primaryMuscles: [],
        ),
      );
      if (ex.id.isEmpty) continue;
      if (!ExerciseCompatibility.isCompatible(profile, ex)) continue;
      availableExercises.add(ex);
    }

    if (availableExercises.isEmpty) return null;

    // Preferência: maior score, mas respeitando fadiga
    ExerciseModel? best;
    double bestScore = -double.infinity;

    for (final ex in availableExercises) {
      double score = _scoreExercise(ex, profile, fatigue, _seed);
      // Bonus extra para exercícios mais evidenciados
      if (ex.id == 'face_pull') score += 1.5;
      if (ex.id == 'scapular_push_up') score += 1.0;
      if (ex.id == 'prone_scapular_retraction') score += 0.8;

      if (score > bestScore) {
        bestScore = score;
        best = ex;
      }
    }

    if (best == null) return null;

    if (!fatigue.canAdd(best, 2)) return null;
    fatigue.add(best, 2);

    // 2 séries leves, RIR 3, foco em ativação
    return PrescribedExercise(
      exercise: best,
      sets: 2,
      repsMin: 15,
      repsMax: 20,
      rir: 3,
      restSeconds: 45,
      sessionCues: [
        ...best.cues.take(2),
        'ESCOPO ESCAPULAR: Foque em retração/depressão escapular. Carga leve, ativação máxima.',
      ],
      progressionNote: 'Estabilidade escapular: previne impingement. Não aumente carga a ponto de compensar trapézio superior.',
      tempo: '2-1-2',
    );
  }

  List<ExerciseModel> _filterCandidates({
    required String muscle,
    required String pattern,
    required WorkoutProfile profile,
    bool forceIsolation = false,
  }) {
    return _library.where((ex) {
      if (!ex.primaryMuscles.contains(muscle)) return false;
      if (!forceIsolation && ex.movementPattern != pattern) return false;
      if (forceIsolation && ex.category != 'isolation') return false;

      if (!ExerciseCompatibility.isCompatible(profile, ex)) return false;

      // Filtro restrições (NUNCA incluir exercícios contraindicados — Doral 2012)
      if (ex.restrictions.any((r) => profile.healthRestrictions.contains(r))) return false;

      // Filtro nível
      if (profile.experienceLevel == 'beginner' && ex.difficulty == 'advanced') return false;

      // Filtro preferências
      if (profile.dislikedExercises.contains(ex.id)) return false;

      // Não incluir exercícios de reabilitação no treino principal
      if (ex.tags.contains('rehab') || ex.tags.contains('prevention')) return false;

      return true;
    }).toList();
  }

  List<String> _desiredCapabilities(WorkoutProfile profile) {
    switch (profile.primaryGoal) {
      case 'strength':
        return const ['strength', 'isometric_strength'];
      case 'running_hybrid':
        return const ['lower_limb_control', 'posterior_chain_control', 'coordination'];
      case 'athletic_agility':
        return const ['coordination', 'stability', 'rotation_control'];
      case 'endurance':
      case 'fat_loss':
        return const ['local_strength', 'coordination'];
      case 'mobility_rehab':
        return const ['motor_control', 'stability'];
      default:
        return const ['strength', 'local_strength', 'motor_control'];
    }
  }

  // ── Bloco de reabilitação ─────────────────────────────────────

  List<PrescribedExercise> _buildRehabBlock(WorkoutProfile profile, int daysPerWeek) {
    return [
      ..._buildRehabBlockUpper(profile, daysPerWeek),
      ..._buildRehabBlockLower(profile, daysPerWeek),
    ];
  }

  List<PrescribedExercise> _buildRehabBlockUpper(
      WorkoutProfile profile, int daysPerWeek) {
    final result = <PrescribedExercise>[];

    for (final injury in profile.healthRestrictions
        .where((r) => ['shoulder', 'wrist', 'elbow'].contains(r))) {
      for (final id in (injuryRehabExercises[injury] ?? []).take(2)) {
        final ex = _library.firstWhere((e) => e.id == id, orElse: () => _library.first);
        if (ex.id == id) {
          if (!ExerciseCompatibility.isCompatible(profile, ex)) continue;
          result.add(PrescribedExercise(
            exercise: ex,
            sets: 3,
            repsMin: 15,
            repsMax: 20,
            rir: 3,
            restSeconds: 60,
            sessionCues: [...ex.cues.take(2), 'Sem dor em nenhuma amplitude.'],
            progressionNote: 'Reabilitação: carga leve, controle total. Sem dor.',
            tempo: '3-1-3',
          ));
        }
      }
    }
    return result;
  }

  List<PrescribedExercise> _buildRehabBlockLower(
      WorkoutProfile profile, int daysPerWeek) {
    final result = <PrescribedExercise>[];

    for (final injury in profile.healthRestrictions
        .where((r) => ['knee', 'lower_back', 'hip'].contains(r))) {
      for (final id in (injuryRehabExercises[injury] ?? []).take(2)) {
        final ex = _library.firstWhere((e) => e.id == id, orElse: () => _library.first);
        if (ex.id == id) {
          if (!ExerciseCompatibility.isCompatible(profile, ex)) continue;
          result.add(PrescribedExercise(
            exercise: ex,
            sets: 3,
            repsMin: 15,
            repsMax: 20,
            rir: 3,
            restSeconds: 60,
            sessionCues: [...ex.cues.take(2), 'Pare imediatamente se sentir dor.'],
            progressionNote: 'Reabilitação: sem dor. Consulte fisioterapeuta.',
            tempo: '3-1-3',
          ));
        }
      }
    }
    return result;
  }

  // ── Auxiliares ────────────────────────────────────────────────

  FatigueMetrics _fatigueMetrics(SessionFatigueAccumulator ft) =>
      FatigueMetrics(
        spinalLoad: ft.spinalLoadAccumulated / SessionFatigueAccumulator.maxSpinalLoad,
        shoulderStress: ft.shoulderStressAccumulated / SessionFatigueAccumulator.maxShoulderStress,
        kneeStress: ft.kneeStressAccumulated / SessionFatigueAccumulator.maxKneeStress,
        cnsLoad: ft.cnsLoadAccumulated / SessionFatigueAccumulator.maxCnsLoad,
      );

  String _dupLabel(_DupPhase phase, String periodization) {
    if (periodization == 'linear') return '';
    switch (phase) {
      case _DupPhase.strength: return ' [Força]';
      case _DupPhase.hypertrophy: return ' [Hipertrofia]';
      case _DupPhase.endurance: return ' [Resistência]';
    }
  }

  String _phaseLabel(_DupPhase phase) {
    switch (phase) {
      case _DupPhase.strength: return 'foco em força';
      case _DupPhase.hypertrophy: return 'foco em hipertrofia';
      case _DupPhase.endurance: return 'foco em resistência muscular';
    }
  }

  String _sessionObjective(String goal, String type, _DupPhase phase) {
    final goalMap = {
      'hypertrophy': 'Máxima hipertrofia',
      'fat_loss': 'Queima calórica com volume',
      'strength': 'Ganho de força',
      'general_health': 'Saúde e condicionamento',
      'endurance': 'Resistência muscular',
      'athletic_performance': 'Performance atlética',
    };
    final phaseStr = _phaseLabel(phase);
    return '${goalMap[goal] ?? 'Evolução'} — $type ($phaseStr)';
  }

  List<String> _warmup(String type, WorkoutProfile profile) {
    const base = ['5 min de cardio leve (esteira, bike ou pular corda)'];
    if (type == 'full_body' || type == 'push') {
      return [...base, 'Rotação de ombros: 2x15 (mobilidade escapular)', 'Flexão de braços leve: 2x10 (aquecimento específico)', '1 série de aquecimento no 1º exercício com 40% da carga de trabalho'];
    }
    if (type == 'pull') {
      return [...base, 'Rotação escapular: 2x15', 'Puxada leve ou elástico: 2x10', '1 série de aquecimento a 40% da carga'];
    }
    if (type == 'lower' || type == 'legs') {
      return [...base, 'Mobilidade de quadril: 2x10 por lado (círculos e abdução)', 'Agachamento corporal: 2x15 (amplitude total)', '1 série de aquecimento no 1º composto a 40% da carga'];
    }
    if (type == 'upper') {
      return [...base, 'Rotação de ombros: 2x15', 'Remada leve: 1x15', '1 série de aquecimento a 40% da carga no 1º exercício'];
    }
    return base;
  }

  String _progressionNote(
      WorkoutProfile profile, String periodization, _DupPhase phase) {
    if (periodization == 'linear' || profile.experienceLevel == 'beginner') {
      return 'Progressão Linear: complete todas as reps com boa técnica. Quando conseguir, adicione 2,5 kg (superiores) ou 5 kg (inferiores) na próxima sessão.';
    }
    switch (phase) {
      case _DupPhase.strength:
        return 'DUP — Sessão de Força: execute com carga máxima sustentável. RIR alvo 1. Se completar todas as reps com RIR >= 2, adicione 2,5-5 kg.';
      case _DupPhase.hypertrophy:
        return 'DUP — Sessão de Hipertrofia: foco em conexão mente-músculo e ROM completa. RIR alvo 2. Progressão dupla: aumente reps até o máximo, depois adicione carga.';
      case _DupPhase.endurance:
        return 'DUP — Sessão de Resistência: alta repetição, descanso curto. RIR alvo 0-1. Use carga moderada (~60% da sua carga normal). Objetivo: estresse metabólico máximo.';
    }
  }

  String _exerciseProgressionNote(
      ExerciseModel ex, WorkoutProfile profile, _DupPhase phase) {
    if (ex.progressionIds.isNotEmpty &&
        (ex.equipment.contains('bodyweight') && ex.equipment.length == 1)) {
      return 'Bodyweight: complete com RIR >= 3 por 2 sessões para avançar para o próximo nível da cadeia.';
    }
    return 'Complete ${ex.repRangeMax} reps em todas as séries com boa técnica antes de aumentar a carga em 2,5 kg.';
  }

  // ── Bio-Adaptação: ajustar prescrição com base em readiness ──

  List<PrescribedSession> _applyBioAdaptation(
      WorkoutProfile profile, List<PrescribedSession> sessions) {
    // Calcular readiness baseado em sono, estresse e lifeLoad
    final readiness = DailyReadiness.fromProfile(
      sleepQuality: profile.sleepQuality,
      stressLevel: profile.stressLevel,
      lifeLoad: profile.lifeLoad,
    );

    // Se readiness está ótimo, não adaptar
    if (readiness.status == 'ready') return sessions;

    // Converter readiness para BioReadiness
    final bioReadiness = BioReadiness(
      score: readiness.volumeMultiplier,
      status: readiness.status == 'recover'
          ? BioStatus.fragile
          : readiness.status == 'adapt'
              ? BioStatus.recovering
              : BioStatus.optimal,
      recommendation: readiness.status == 'recover'
          ? 'Fadiga acumulada detectada. Reduzindo volume e aumentando RIR.'
          : readiness.status == 'adapt'
              ? 'Adaptação em andamento. Mantendo volume moderado.'
              : 'Plano ideal mantido.',
      cnsFatigue: (1.0 - readiness.volumeMultiplier).clamp(0.0, 1.0),
      jointStress: (1.0 - readiness.volumeMultiplier).clamp(0.0, 1.0),
    );

    // Aplicar adaptação em cada exercício de cada sessão
    return sessions.map((session) {
      final adaptedExercises = session.exercises.map((ex) {
        return BioAdaptiveEngine.applyBioAdaptation(ex, bioReadiness);
      }).toList();

      return PrescribedSession(
        id: session.id,
        name: session.name,
        objective: session.objective,
        estimatedDurationMinutes: session.estimatedDurationMinutes,
        warmupInstructions: session.warmupInstructions,
        exercises: adaptedExercises,
        progressionNote: session.progressionNote,
        fatigue: session.fatigue,
        userExplanation: session.userExplanation,
      );
    }).toList();
  }

  // ── Decision Memory: registrar decisões para auditoria ──

  void _recordDecisions(WorkoutProfile profile, List<PrescribedSession> sessions,
      String splitType, String periodization) {
    if (_decisionMemory == null) return;

    final decisions = <PrescriptionDecision>[];

    for (final session in sessions) {
      for (final ex in session.exercises) {
        decisions.add(PrescriptionDecision(
          exerciseId: ex.exercise.id,
          exerciseName: ex.exercise.name,
          muscle: ex.exercise.primaryMuscles.isNotEmpty
              ? ex.exercise.primaryMuscles.first
              : 'unknown',
          pattern: ex.exercise.movementPattern,
          reason: ex.decisionReason ?? 'Selecionado pelo motor de prescrição',
          score: 0,
          timestamp: DateTime.now(),
        ));
      }
    }

    if (decisions.isNotEmpty) {
      final record = PrescriptionRecord(
        workoutId: 'gen_${DateTime.now().millisecondsSinceEpoch}',
        splitType: splitType,
        periodization: periodization,
        decisions: decisions,
        inputSnapshot: {
          'goal': profile.primaryGoal,
          'experience': profile.experienceLevel,
          'days': profile.availableDaysPerWeek,
        },
        timestamp: DateTime.now(),
      );
      _decisionMemory!.addRecord(record);
    }
  }
}
