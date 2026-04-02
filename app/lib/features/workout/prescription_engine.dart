import 'dart:math';
import '../exercises/exercise_model.dart';
import 'workout_profile_model.dart';
import 'prescribed_workout_model.dart';
import '../../core/data/exercise_library.dart';

// ═══════════════════════════════════════════════════════════════
// MOTOR DE PRESCRIÇÃO v3.0
//
// Melhorias baseadas em Schoenfeld (2021) + Murer et al. (2019):
// 1. DUP real: rep range varia ENTRE sessões (força/hipertrofia/resistência)
// 2. Cadência prescrita por exercício
// 3. RIR real por objetivo (não só por nível)
// 4. Equilíbrio push:pull garantido (ratio >= 1:1 na semana)
// 5. ROM completa nos cues de todos os exercícios
// 6. Volume indireto contabilizado (bíceps/tríceps)
// 7. Descanso correto por padrão motor e objetivo
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

  WorkoutPrescriptionEngine(WorkoutProfile profile)
      : _library = exerciseLibrary,
        _seed = profile.uid.codeUnits.fold(0, (a, b) => a + b);

  // ── API Pública ───────────────────────────────────────────────

  GeneratedWorkout generate(WorkoutProfile profile) {
    final splitType = _selectSplit(profile);
    final periodization = _selectPeriodization(profile);
    final sessions = _buildSessions(profile, splitType, periodization);

    // Etapa 4: Ajustes Clínicos e Proporções de Volume (Murer 2019 / Doral 2012)
    final adjustedSessions = _applyClinicalAdjustments(profile, sessions);

    return GeneratedWorkout(
      id: 'gen_${DateTime.now().millisecondsSinceEpoch}',
      userId: profile.uid,
      splitType: splitType,
      periodizationModel: periodization,
      sessions: adjustedSessions,
      mesocycleDurationWeeks: _mesocycleDuration(profile),
      generatedAt: DateTime.now(),
    );
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
      if (days <= 3) return 'ppl_3days';
      if (days == 4) return 'upper_lower';
      if (days == 5) return 'ppl_5days';
      return 'ppl_6days';
    }

    // Advanced
    if (goal == 'strength') {
      if (days <= 4) return 'upper_lower_strength';
      return 'ppl_strength';
    }
    if (days <= 3) return 'ppl_3days';
    if (days == 4) return 'upper_lower';
    if (days == 5) return 'ppl_5days';
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
    // Para iniciantes: 0-12 meses
    // Para inter/avançados: 12-60 meses (5 anos)
    double factor;
    if (isBeginner) {
      factor = (months / 12.0).clamp(0.0, 1.0);
    } else {
      factor = ((months - 12) / 48.0).clamp(0.0, 1.0);
      if (isAdvanced) factor = factor.clamp(0.5, 1.0); // Avançados começam no meio da faixa INT
    }

    // Helper para extrair volume das faixas da imagem técnica
    int getVol(List<int> rangeINI, List<int> rangeINT) {
      final range = isBeginner ? rangeINI : rangeINT;
      return (range[0] + (range[1] - range[0]) * factor).round();
    }

    // 1. Cálculos de volumes ALVO (Brutos por grupo muscular)
    final vChest = getVol([8, 10], [12, 16]);
    final vBack = getVol([10, 12], [14, 20]);
    final vShoulders = getVol([8, 10], [12, 16]);
    final vQuads = getVol([8, 10], [12, 18]);
    final vPostGlute = getVol([6, 8], [10, 16]);
    final vCalves = getVol([8, 10], [12, 16]);
    final vAbs = getVol([4, 6], [6, 12]);

    // Alvos para braços (antes de descontar o volume indireto)
    final vBicepsTarget = getVol([6, 8], [10, 14]);
    final vTricepsTarget = getVol([6, 8], [10, 14]);

    // 2. Aplicação da REGRA: Volume Indireto (Israelte 2019 / Schoenfeld 2021)
    // Biceps recebem ~50% de remadas/puxadas (Back)
    // Triceps recebem ~50% de supinos/desenvolvimentos (Chest/Shoulders parcial)
    // Clamp mínimo de 2-4 séries para garantir estimulo direto mínimo
    
    final vBicepsFinal = (vBicepsTarget - (vBack * 0.5)).round().clamp(3, 14);
    final vTricepsFinal = (vTricepsTarget - (vChest * 0.5)).round().clamp(3, 14);

    return {
      'chest': vChest,
      'back': vBack,
      'shoulders': vShoulders,
      'side_delt': (vShoulders * 0.6).round().clamp(4, 12),
      'rear_delt': (vShoulders * 0.5).round().clamp(3, 10),
      'biceps': vBicepsFinal,
      'triceps': vTricepsFinal,
      'quads': vQuads,
      'hamstrings': vPostGlute,
      'glutes': (vPostGlute * 0.6).round().clamp(4, 12),
      'calves': vCalves,
      'abs': vAbs,
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
      case 'fat_loss':
        return (
          sets: 3,
          repsMin: 12, repsMax: 20,
          rir: 2,
          restSeconds: 45,
          tempo: '2-0-2',
        );
      case 'endurance':
        return (
          sets: 3,
          repsMin: 15, repsMax: 25,
          rir: 1,
          restSeconds: 45,
          tempo: '2-0-1',
        );
      case 'general_health':
        return (
          sets: 2,
          repsMin: 12, repsMax: 15,
          rir: 3,
          restSeconds: 75,
          tempo: '2-0-2',
        );
      case 'athletic_performance':
        return (
          sets: isCompound ? 5 : 3,
          repsMin: 4, repsMax: 8,
          rir: 1,
          restSeconds: isCompound ? 180 : 120,
          tempo: '1-0-2',
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
      case 'ppl_6days':
      case 'ppl_strength':
        return _buildPPLSplit(profile, periodization, splitType);
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

      final exercises = <PrescribedExercise?>[];

      // Compostos: push horizontal + pull vertical (equilíbrio 1:1)
      exercises.add(_pick('chest', isA ? 'push_horizontal' : 'push_incline',
          profile, vols, days, slot: i, phase: phase));
      exercises.add(_pick('back', isA ? 'pull_vertical' : 'pull_horizontal',
          profile, vols, days, slot: i, phase: phase));
      exercises.add(_pick('quads', 'squat', profile, vols, days, slot: i, phase: phase));
      exercises.add(_pick('hamstrings', 'hinge', profile, vols, days, slot: i, phase: phase));
      exercises.add(_pick('shoulders', 'push_vertical', profile, vols, days,
          slot: i, phase: phase, setsModifier: 1));
      // Isoladores (Murer 2019: opcional para iniciantes, importante para intermediários+)
      if (profile.experienceLevel != 'beginner') {
        exercises.add(_pick('biceps', 'isolation', profile, vols, days,
            slot: i, phase: phase, forceIsolation: true));
        exercises.add(_pick('triceps', 'isolation', profile, vols, days,
            slot: i, phase: phase, forceIsolation: true));
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
    final dupLabel = _dupLabel(phase, periodization);

    // Push composto
    exercises.add(_pick('chest', isA ? 'push_horizontal' : 'push_incline',
        profile, vols, 2, slot: slot, phase: phase, setsModifier: 2));
    // Pull vertical (garante equilíbrio push:pull)
    exercises.add(_pick('back', isA ? 'pull_vertical' : 'pull_horizontal',
        profile, vols, 2, slot: slot, phase: phase, setsModifier: 2));
    // Pull horizontal (2º puxada para ratio >=1:1)
    exercises.add(_pick('back', isA ? 'pull_horizontal' : 'pull_vertical',
        profile, vols, 2, slot: slot + 5, phase: phase, setsModifier: 1));
    // Ombros
    exercises.add(_pick('shoulders', 'push_vertical', profile, vols, 2,
        slot: slot, phase: phase, setsModifier: 1));
    // Isoladores (intermediários+)
    if (profile.experienceLevel != 'beginner') {
      exercises.add(_pick('triceps', 'isolation', profile, vols, 2,
          slot: slot, phase: phase, forceIsolation: true));
      exercises.add(_pick('biceps', 'isolation', profile, vols, 2,
          slot: slot, phase: phase, forceIsolation: true));
    }
    if (profile.sessionDurationMinutes >= 60 && profile.experienceLevel != 'beginner') {
      exercises.add(_pick('side_delt', 'isolation', profile, vols, 2,
          slot: slot, phase: phase, forceIsolation: true));
    }

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
    final isA = slot.isEven;
    final exercises = <PrescribedExercise?>[];
    final dupLabel = _dupLabel(phase, periodization);

    exercises.add(_pick('quads', 'squat', profile, vols, 2,
        slot: slot, phase: phase, setsModifier: 2));
    exercises.add(_pick('hamstrings', 'hinge', profile, vols, 2,
        slot: slot, phase: phase, setsModifier: 2));
    exercises.add(_pick('glutes', 'hinge', profile, vols, 2,
        slot: slot, phase: phase, setsModifier: 1));
    if (!profile.healthRestrictions.contains('knee')) {
      exercises.add(_pick('quads', 'isolation', profile, vols, 2,
          slot: slot + 5, phase: phase, forceIsolation: true));
    }
    exercises.add(_pick('hamstrings', 'isolation', profile, vols, 2,
        slot: slot + 5, phase: phase, forceIsolation: true));
    exercises.add(_pick('calves', 'isolation', profile, vols, 2,
        slot: slot, phase: phase, setsModifier: 2, forceIsolation: true));
    if (profile.sessionDurationMinutes >= 60) {
      exercises.add(_pick('abs', 'isolation', profile, vols, 2,
          slot: slot, phase: phase, forceIsolation: true));
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
    } else if (splitType == 'ppl_5days') {
      sessions.add(_buildPushSession('B', profile, vols, slot: 1, periodization: periodization, phase: _dupPhase(periodization, 3, 3)));
      sessions.add(_buildPullSession('B', profile, vols, slot: 1, periodization: periodization, phase: _dupPhase(periodization, 4, 3)));
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
    final dupLabel = _dupLabel(phase, periodization);

    exercises.add(_pick('chest', isA ? 'push_horizontal' : 'push_incline',
        profile, vols, 3, slot: slot, phase: phase, setsModifier: 2));
    exercises.add(_pick('shoulders', 'push_vertical', profile, vols, 3,
        slot: slot, phase: phase, setsModifier: 2));
    exercises.add(_pick('chest', 'isolation', profile, vols, 3,
        slot: slot, phase: phase, forceIsolation: true));
    exercises.add(_pick('side_delt', 'isolation', profile, vols, 3,
        slot: slot, phase: phase, forceIsolation: true));
    exercises.add(_pick('triceps', 'isolation', profile, vols, 3,
        slot: slot, phase: phase));
    if (profile.sessionDurationMinutes >= 60) {
      exercises.add(_pick('triceps', 'isolation', profile, vols, 3,
          slot: slot + 10, phase: phase));
    }

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
    final dupLabel = _dupLabel(phase, periodization);

    exercises.add(_pick('back', isA ? 'pull_vertical' : 'pull_vertical',
        profile, vols, 3, slot: slot, phase: phase, setsModifier: 2));
    exercises.add(_pick('back', 'pull_horizontal', profile, vols, 3,
        slot: slot, phase: phase, setsModifier: 2));
    exercises.add(_pick('back', 'pull_horizontal', profile, vols, 3,
        slot: slot + 5, phase: phase, setsModifier: 1));
    exercises.add(_pick('rear_delt', 'pull_horizontal', profile, vols, 3,
        slot: slot, phase: phase, forceIsolation: true));
    exercises.add(_pick('biceps', 'isolation', profile, vols, 3,
        slot: slot, phase: phase));
    if (profile.sessionDurationMinutes >= 60) {
      exercises.add(_pick('biceps', 'isolation', profile, vols, 3,
          slot: slot + 10, phase: phase));
    }

    return PrescribedSession(
      id: 'session_pull_$tag',
      name: 'Pull (Puxar) $tag$dupLabel',
      objective: 'Costas, bíceps e deltóide posterior — ${_phaseLabel(phase)}',
      estimatedDurationMinutes: profile.sessionDurationMinutes,
      warmupInstructions: _warmup('pull', profile),
      exercises: exercises.where((e) => e != null).cast<PrescribedExercise>().toList(),
      progressionNote: _progressionNote(profile, periodization, phase),
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
    final dupLabel = _dupLabel(phase, periodization);
    final hasKneeInjury = profile.healthRestrictions.contains('knee');

    exercises.add(_pick('quads', 'squat', profile, vols, 3,
        slot: slot, phase: phase, setsModifier: 2));
    exercises.add(_pick('hamstrings', 'hinge', profile, vols, 3,
        slot: slot, phase: phase, setsModifier: 2));
    exercises.add(_pick('glutes', 'hinge', profile, vols, 3,
        slot: slot, phase: phase, setsModifier: 1));
    if (!hasKneeInjury) {
      exercises.add(_pick('quads', 'isolation', profile, vols, 3,
          slot: slot, phase: phase, forceIsolation: true));
    }
    exercises.add(_pick('hamstrings', 'isolation', profile, vols, 3,
        slot: slot, phase: phase, forceIsolation: true));
    exercises.add(_pick('calves', 'isolation', profile, vols, 3,
        slot: slot, phase: phase, setsModifier: 2, forceIsolation: true));
    if (profile.sessionDurationMinutes >= 60) {
      exercises.add(_pick('abs', 'isolation', profile, vols, 3,
          slot: slot, phase: phase, forceIsolation: true));
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
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // SELEÇÃO INTELIGENTE DE EXERCÍCIO
  // ═══════════════════════════════════════════════════════════════

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
  }) {
    final candidates = _filterCandidates(
      muscle: muscle,
      pattern: pattern,
      profile: profile,
      forceIsolation: forceIsolation,
    );

    if (candidates.isEmpty) return null;

    final pickIndex = (_seed + slot + muscle.hashCode).abs() % candidates.length;
    final ex = candidates[pickIndex];

    // Volume baseado em MEV/MRV
    final weeklyVol = vols[muscle] ?? 10;
    final freqPerWeek = max(1, sessionsPerWeek ~/ 2 + 1);
    final rawSets = (weeklyVol / freqPerWeek).ceil();
    final baseSets = (rawSets * setsModifier).clamp(2, 5);

    // Prescrição com DUP
    final rx = _prescription(profile, ex, phase);

    // Cues com ROM completa obrigatório (Schoenfeld 2021)
    final sessionCues = [
      ...ex.cues.take(2),
      'ROM completa — amplitude máxima segura em cada repetição.',
    ];

    return PrescribedExercise(
      exercise: ex,
      sets: phase == _DupPhase.strength ? min(baseSets + 1, 5) : baseSets,
      repsMin: rx.repsMin,
      repsMax: rx.repsMax,
      rir: rx.rir,
      restSeconds: rx.restSeconds,
      sessionCues: sessionCues,
      progressionNote: _exerciseProgressionNote(ex, profile, phase),
      tempo: rx.tempo,
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

      // Filtro ambiente
      if (!ex.environment.contains(profile.environment)) {
        if (profile.environment != 'full_gym' && !ex.environment.contains('home')) return false;
      }

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
}
