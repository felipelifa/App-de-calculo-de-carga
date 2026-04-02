import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'workout_models.dart';

// ═══════════════════════════════════════════════════════════════
// MOTOR DE PROGRESSÃO v2.0
//
// Base científica:
// - Schoenfeld (2021): RIR como métrica de intensidade superior ao %1RM
// - GAS de Selye: deload = fase de supercompensação
// - Princípio de sobrecarga progressiva (ACSM 2021)
// - Progressão dupla: reps antes de carga
//
// Tabela de decisão:
// RIR >= 3 → aumentar carga (+2,5kg sup / +5kg inf)
// RIR 1-2  → consolidar (manter carga, repetir sessão)
// Não completou reps → manter; 2x seguidas → reduzir 10%
// 3 sessões sem progressão → substituir exercício
// Semana 4/6/8 → deload automático
// ═══════════════════════════════════════════════════════════════

// ─────────────────────────────────────────────
// Modelos
// ─────────────────────────────────────────────

enum ProgressionDecisionType {
  increaseLoad,       // RIR >= 3: adicionar carga
  consolidate,        // RIR 1-2: manter, consolidar
  decreaseLoad,       // Falhou 2x: reduzir 10%
  substituteExercise, // 3 sessões sem progressão
  deload,             // Temporal ou por fadiga
  continueBodyweight, // Bodyweight: RIR ok, manter progressão
  advanceBodyweight,  // Bodyweight: RIR >= 3 por 2 sessões → próximo na cadeia
}

class ProgressionDecision {
  final String exerciseId;
  final ProgressionDecisionType type;
  final String title;
  final String reason;
  final double? suggestedWeightKg;
  final String? suggestedSubstituteId; // para substituteExercise
  final String? suggestedProgressionId; // para advanceBodyweight
  final int sessionsAnalyzed;

  const ProgressionDecision({
    required this.exerciseId,
    required this.type,
    required this.title,
    required this.reason,
    this.suggestedWeightKg,
    this.suggestedSubstituteId,
    this.suggestedProgressionId,
    required this.sessionsAnalyzed,
  });
}

class ExerciseProgressState {
  final String exerciseId;
  final double lastWeightKg;
  final int lastRepsCompleted;
  final int lastRirReported; // RIR reportado pelo usuário (0-5+)
  final int sessionsWithoutProgress;
  final int consecutiveFailures; // séries não completadas
  final DateTime? lastPR;
  final bool isBodyweight;
  final List<String> progressionIds; // próximos exercícios na cadeia
  final List<String> substituteIds;
  final bool sessionCompletedAllReps; // completou todas as reps da última sessão

  const ExerciseProgressState({
    required this.exerciseId,
    required this.lastWeightKg,
    required this.lastRepsCompleted,
    required this.lastRirReported,
    required this.sessionsWithoutProgress,
    required this.consecutiveFailures,
    this.lastPR,
    this.isBodyweight = false,
    this.progressionIds = const [],
    this.substituteIds = const [],
    this.sessionCompletedAllReps = true,
  });

  Map<String, dynamic> toMap() => {
        'exerciseId': exerciseId,
        'lastWeightKg': lastWeightKg,
        'lastRepsCompleted': lastRepsCompleted,
        'lastRirReported': lastRirReported,
        'sessionsWithoutProgress': sessionsWithoutProgress,
        'consecutiveFailures': consecutiveFailures,
        'lastPR': lastPR?.toIso8601String(),
        'isBodyweight': isBodyweight,
        'progressionIds': progressionIds,
        'substituteIds': substituteIds,
        'sessionCompletedAllReps': sessionCompletedAllReps,
      };

  factory ExerciseProgressState.fromMap(Map<String, dynamic> map) {
    return ExerciseProgressState(
      exerciseId: map['exerciseId'] as String? ?? '',
      lastWeightKg: (map['lastWeightKg'] as num?)?.toDouble() ?? 0,
      lastRepsCompleted: (map['lastRepsCompleted'] as num?)?.toInt() ?? 0,
      lastRirReported: (map['lastRirReported'] as num?)?.toInt() ?? 3,
      sessionsWithoutProgress: (map['sessionsWithoutProgress'] as num?)?.toInt() ?? 0,
      consecutiveFailures: (map['consecutiveFailures'] as num?)?.toInt() ?? 0,
      lastPR: map['lastPR'] != null ? DateTime.tryParse(map['lastPR'] as String) : null,
      isBodyweight: map['isBodyweight'] as bool? ?? false,
      progressionIds: List<String>.from(map['progressionIds'] ?? []),
      substituteIds: List<String>.from(map['substituteIds'] ?? []),
      sessionCompletedAllReps: map['sessionCompletedAllReps'] as bool? ?? true,
    );
  }
}

// ─────────────────────────────────────────────
// Estado global de progressão
// ─────────────────────────────────────────────

class ProgressionState {
  final int currentWeek;
  final String currentPhase; // accumulation | intensification | peak | deload
  final String periodizationModel; // linear | dup | block
  final bool isDeloadWeek;
  final int weeksUntilDeload;
  final Map<String, ExerciseProgressState> exerciseProgress;
  final Map<String, int> weeklyVolumeActual; // séries realizadas por grupo
  final DateTime lastUpdated;

  const ProgressionState({
    required this.currentWeek,
    required this.currentPhase,
    required this.periodizationModel,
    required this.isDeloadWeek,
    required this.weeksUntilDeload,
    required this.exerciseProgress,
    required this.weeklyVolumeActual,
    required this.lastUpdated,
  });

  Map<String, dynamic> toMap() => {
        'currentWeek': currentWeek,
        'currentPhase': currentPhase,
        'periodizationModel': periodizationModel,
        'isDeloadWeek': isDeloadWeek,
        'weeksUntilDeload': weeksUntilDeload,
        'exerciseProgress': exerciseProgress
            .map((k, v) => MapEntry(k, v.toMap())),
        'weeklyVolumeActual': weeklyVolumeActual,
        'lastUpdated': lastUpdated.toIso8601String(),
      };

  factory ProgressionState.fromMap(Map<String, dynamic> map) {
    final epRaw = map['exerciseProgress'] as Map<String, dynamic>? ?? {};
    return ProgressionState(
      currentWeek: (map['currentWeek'] as num?)?.toInt() ?? 1,
      currentPhase: map['currentPhase'] as String? ?? 'accumulation',
      periodizationModel: map['periodizationModel'] as String? ?? 'linear',
      isDeloadWeek: map['isDeloadWeek'] as bool? ?? false,
      weeksUntilDeload: (map['weeksUntilDeload'] as num?)?.toInt() ?? 4,
      exerciseProgress: epRaw.map(
        (k, v) => MapEntry(k, ExerciseProgressState.fromMap(v as Map<String, dynamic>)),
      ),
      weeklyVolumeActual: (map['weeklyVolumeActual'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(k, (v as num).toInt())),
      lastUpdated: map['lastUpdated'] != null
          ? DateTime.tryParse(map['lastUpdated'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  ProgressionState copyWith({
    int? currentWeek,
    String? currentPhase,
    bool? isDeloadWeek,
    int? weeksUntilDeload,
    Map<String, ExerciseProgressState>? exerciseProgress,
    Map<String, int>? weeklyVolumeActual,
  }) {
    return ProgressionState(
      currentWeek: currentWeek ?? this.currentWeek,
      currentPhase: currentPhase ?? this.currentPhase,
      periodizationModel: periodizationModel,
      isDeloadWeek: isDeloadWeek ?? this.isDeloadWeek,
      weeksUntilDeload: weeksUntilDeload ?? this.weeksUntilDeload,
      exerciseProgress: exerciseProgress ?? this.exerciseProgress,
      weeklyVolumeActual: weeklyVolumeActual ?? this.weeklyVolumeActual,
      lastUpdated: DateTime.now(),
    );
  }
}

// ─────────────────────────────────────────────
// Motor de Progressão principal
// ─────────────────────────────────────────────

class ProgressionEngine {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  ProgressionEngine({FirebaseFirestore? db, FirebaseAuth? auth})
      : _db = db ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String get _uid => _auth.currentUser?.uid ?? '';
  String get _stateDoc => 'users/$_uid/progression_state/current';

  // ── Carregar estado ───────────────────────────────────────────

  Future<ProgressionState?> loadState() async {
    try {
      final doc = await _db.doc(_stateDoc).get();
      if (!doc.exists || doc.data() == null) return null;
      return ProgressionState.fromMap(doc.data()!);
    } catch (e) {
      debugPrint('ProgressionEngine.loadState error: $e');
      return null;
    }
  }

  // ── Salvar estado ─────────────────────────────────────────────

  Future<void> saveState(ProgressionState state) async {
    try {
      await _db.doc(_stateDoc).set(state.toMap());
    } catch (e) {
      debugPrint('ProgressionEngine.saveState error: $e');
    }
  }

  // ── Inicializar estado para novo treino gerado ────────────────

  Future<ProgressionState> initializeForNewWorkout({
    required String periodizationModel,
    required String experienceLevel,
  }) async {
    final weeksUntilDeload = _deloadInterval(experienceLevel);
    final state = ProgressionState(
      currentWeek: 1,
      currentPhase: 'accumulation',
      periodizationModel: periodizationModel,
      isDeloadWeek: false,
      weeksUntilDeload: weeksUntilDeload,
      exerciseProgress: {},
      weeklyVolumeActual: {},
      lastUpdated: DateTime.now(),
    );
    await saveState(state);
    return state;
  }

  // ── Processar sessão concluída ────────────────────────────────
  //
  // Chamado pelo WorkoutProvider após finishSession()
  // Recebe os exercícios executados + RIR reportado pelo usuário
  //
  // workoutEntries: exercícios com séries/reps/cargas
  // rirByExercise: mapa exerciseId → RIR médio reportado
  // exerciseMetadata: mapa exerciseId → {isBodyweight, progressionIds, substituteIds}

  Future<List<ProgressionDecision>> processSession({
    required List<WorkoutExerciseEntry> workoutEntries,
    required Map<String, int> rirByExercise,
    required Map<String, Map<String, dynamic>> exerciseMetadata,
    required String experienceLevel,
  }) async {
    ProgressionState state = await loadState() ??
        await initializeForNewWorkout(
          periodizationModel: 'linear',
          experienceLevel: experienceLevel,
        );

    // Verifica deload automático temporal
    if (_shouldDeload(state, experienceLevel)) {
      final newState = state.copyWith(
        isDeloadWeek: true,
        currentPhase: 'deload',
        weeksUntilDeload: _deloadInterval(experienceLevel),
      );
      await saveState(newState);
      return [
        ProgressionDecision(
          exerciseId: 'ALL',
          type: ProgressionDecisionType.deload,
          title: 'Semana de Deload',
          reason:
              'Você chegou na semana ${state.currentWeek}. O seu corpo precisa de supercompensação. '
              'Reduza o volume em 45% esta semana — a carga permanece a mesma.',
          sessionsAnalyzed: state.currentWeek,
        )
      ];
    }

    final decisions = <ProgressionDecision>[];
    final updatedProgress = Map<String, ExerciseProgressState>.from(
      state.exerciseProgress,
    );

    for (final entry in workoutEntries) {
      final exId = entry.exerciseId;
      if (exId.isEmpty || entry.sets.isEmpty) continue;

      final rir = rirByExercise[exId] ?? 3;
      final meta = exerciseMetadata[exId] ?? {};
      final isBodyweight = meta['isBodyweight'] as bool? ?? false;
      final progressionIds = List<String>.from(meta['progressionIds'] ?? []);
      final substituteIds = List<String>.from(meta['substituteIds'] ?? []);

      // Calcula métricas da sessão
      double maxWeight = 0;
      int totalReps = 0;
      bool completedAllSets = true;

      for (final set in entry.sets) {
        if (set.weight > maxWeight) maxWeight = set.weight;
        totalReps += set.reps;
        if (set.reps == 0) completedAllSets = false;
      }
      final avgReps = (totalReps / entry.sets.length).round();

      // Estado anterior deste exercício
      final prev = state.exerciseProgress[exId];

      // Verifica progressão
      final hasMadeProgress = prev == null ||
          maxWeight > prev.lastWeightKg ||
          avgReps > prev.lastRepsCompleted;

      final newSessionsWithoutProgress = hasMadeProgress
          ? 0
          : (prev?.sessionsWithoutProgress ?? 0) + 1;

      final newConsecutiveFailures = completedAllSets
          ? 0
          : (prev?.consecutiveFailures ?? 0) + 1;

      // Aplica tabela de decisão
      final decision = _decide(
        exerciseId: exId,
        rir: rir,
        currentWeight: maxWeight,
        completedAllSets: completedAllSets,
        sessionsWithoutProgress: newSessionsWithoutProgress,
        consecutiveFailures: newConsecutiveFailures,
        isBodyweight: isBodyweight,
        progressionIds: progressionIds,
        substituteIds: substituteIds,
        prevSessionsWithProgress: !hasMadeProgress ? (prev?.sessionsWithoutProgress ?? 0) : 0,
      );

      decisions.add(decision);

      // Atualiza estado deste exercício
      updatedProgress[exId] = ExerciseProgressState(
        exerciseId: exId,
        lastWeightKg: decision.suggestedWeightKg ?? maxWeight,
        lastRepsCompleted: avgReps,
        lastRirReported: rir,
        sessionsWithoutProgress: newSessionsWithoutProgress,
        consecutiveFailures: newConsecutiveFailures,
        lastPR: hasMadeProgress ? DateTime.now() : prev?.lastPR,
        isBodyweight: isBodyweight,
        progressionIds: progressionIds,
        substituteIds: substituteIds,
        sessionCompletedAllReps: completedAllSets,
      );
    }

    // Avança semana e salva
    final nextWeek = state.currentWeek + 1;
    final newState = state.copyWith(
      currentWeek: nextWeek,
      weeksUntilDeload: state.weeksUntilDeload - 1,
      isDeloadWeek: false,
      exerciseProgress: updatedProgress,
      currentPhase: _currentPhase(
        state.periodizationModel,
        nextWeek,
        experienceLevel,
      ),
    );
    await saveState(newState);

    return decisions;
  }

  // ── Tabela de Decisão ─────────────────────────────────────────

  ProgressionDecision _decide({
    required String exerciseId,
    required int rir,
    required double currentWeight,
    required bool completedAllSets,
    required int sessionsWithoutProgress,
    required int consecutiveFailures,
    required bool isBodyweight,
    required List<String> progressionIds,
    required List<String> substituteIds,
    required int prevSessionsWithProgress,
  }) {
    // ── Regra 1: Substituição por plateau (3 sessões sem progressão)
    if (sessionsWithoutProgress >= 3 && substituteIds.isNotEmpty) {
      return ProgressionDecision(
        exerciseId: exerciseId,
        type: ProgressionDecisionType.substituteExercise,
        title: 'Troque o exercício',
        reason:
            '$sessionsWithoutProgress sessões sem progressão. Um novo estímulo vai quebrar o plateau.',
        suggestedSubstituteId: substituteIds.first,
        sessionsAnalyzed: sessionsWithoutProgress,
      );
    }

    // ── Regra 2: Falha consecutiva (2x não completou reps)
    if (consecutiveFailures >= 2 && !isBodyweight) {
      final reducedWeight = (currentWeight * 0.9 / 2.5).round() * 2.5;
      return ProgressionDecision(
        exerciseId: exerciseId,
        type: ProgressionDecisionType.decreaseLoad,
        title: 'Reduza a carga',
        reason:
            'Você não completou as reps em 2 sessões seguidas. Reduza 10% e reconstrua.',
        suggestedWeightKg: reducedWeight.toDouble(),
        sessionsAnalyzed: consecutiveFailures,
      );
    }

    // ── Regra 3: Bodyweight — avançar na cadeia
    if (isBodyweight && rir >= 3 && progressionIds.isNotEmpty) {
      // Avança 2 sessões consecutivas com RIR >= 3
      if (prevSessionsWithProgress == 0) {
        // Esta é a primeira sessão com RIR >= 3 — consolidar por 1 mais
        return ProgressionDecision(
          exerciseId: exerciseId,
          type: ProgressionDecisionType.continueBodyweight,
          title: 'Quase pronto para avançar',
          reason:
              'RIR $rir. Mais uma sessão assim e você estará pronto para o próximo nível na cadeia de progressão.',
          sessionsAnalyzed: 1,
        );
      }
      return ProgressionDecision(
        exerciseId: exerciseId,
        type: ProgressionDecisionType.advanceBodyweight,
        title: 'Avance na progressão',
        reason:
            'Você completou este exercício com RIR >= 3 por 2 sessões. Hora de avançar para o próximo nível.',
        suggestedProgressionId: progressionIds.first,
        sessionsAnalyzed: 2,
      );
    }

    // ── Regra 4: RIR >= 3 → aumentar carga (progressão linear)
    if (rir >= 3 && completedAllSets && !isBodyweight) {
      final isLower = exerciseId.contains('quad') ||
          exerciseId.contains('ham') ||
          exerciseId.contains('glute') ||
          exerciseId.contains('leg') ||
          exerciseId.contains('calf');
      final increment = isLower ? 5.0 : 2.5;
      final newWeight = ((currentWeight + increment) / 2.5).ceil() * 2.5;
      return ProgressionDecision(
        exerciseId: exerciseId,
        type: ProgressionDecisionType.increaseLoad,
        title: 'Aumente a carga',
        reason:
            'RIR $rir — você tem margem. Adicione ${increment.toStringAsFixed(1)} kg na próxima sessão.',
        suggestedWeightKg: newWeight.toDouble(),
        sessionsAnalyzed: 1,
      );
    }

    // ── Regra 5: RIR 1-2 → consolidar (zona ideal)
    if (rir <= 2 && rir >= 1 && completedAllSets) {
      return ProgressionDecision(
        exerciseId: exerciseId,
        type: ProgressionDecisionType.consolidate,
        title: 'Zona ideal — consolide',
        reason:
            'RIR $rir — zona perfeita de hipertrofia. Mantenha a carga e repita na próxima sessão.',
        suggestedWeightKg: currentWeight,
        sessionsAnalyzed: 1,
      );
    }

    // ── Padrão: manter
    return ProgressionDecision(
      exerciseId: exerciseId,
      type: ProgressionDecisionType.consolidate,
      title: 'Mantenha o ritmo',
      reason: 'Progresso estável. Continue registrando para sugestões mais precisas.',
      suggestedWeightKg: currentWeight,
      sessionsAnalyzed: 1,
    );
  }

  // ── Auxiliares ────────────────────────────────────────────────

  bool _shouldDeload(ProgressionState state, String experienceLevel) {
    return state.weeksUntilDeload <= 0 && !state.isDeloadWeek;
  }

  int _deloadInterval(String experienceLevel) {
    switch (experienceLevel) {
      case 'beginner':
        return 4;
      case 'intermediate':
        return 6;
      case 'advanced':
        return 8;
      default:
        return 4;
    }
  }

  String _currentPhase(
    String model,
    int week,
    String experienceLevel,
  ) {
    if (model == 'linear') return 'accumulation';
    if (model == 'dup') {
      // DUP: alterna entre fases mais rápido
      final cycle = week % 3;
      if (cycle == 0) return 'intensification';
      if (cycle == 1) return 'accumulation';
      return 'peak';
    }
    // Bloco: acumulação 4-6 sem → intensificação 3-4 sem → pico 2-3 sem
    final blockLength = experienceLevel == 'beginner' ? 4 : 6;
    final totalCycle = blockLength * 3;
    final posInCycle = week % totalCycle;
    if (posInCycle < blockLength) return 'accumulation';
    if (posInCycle < blockLength * 2) return 'intensification';
    return 'peak';
  }
}
