import '../exercises/exercise_model.dart';
import 'prescribed_workout_model.dart';

// ═══════════════════════════════════════════════════════════════
// SESSION FATIGUE ACCUMULATOR
//
// Rastreia acumulação de fadiga multiarticular durante a
// montagem de uma sessão. Impede que o motor prescreva
// exercícios que sobrecarreguem articulações além do seguro.
// ═══════════════════════════════════════════════════════════════

class SessionFatigueAccumulator {
  double spinalLoadAccumulated = 0;
  double shoulderStressAccumulated = 0;
  double kneeStressAccumulated = 0;
  double cnsLoadAccumulated = 0;
  
  // Rastrear exercícios por músculo para cálculo de posição
  final Map<String, int> _exerciseCountByMuscle = {};
  
  // Fadiga residual de sessões anteriores (com decaimento temporal)
  double _residualSpinalLoad = 0;
  double _residualShoulderStress = 0;
  double _residualKneeStress = 0;
  double _residualCnsLoad = 0;

  // Limites por sessão (considerando séries como multiplicador)
  static const maxSpinalLoad = 3.0;      // Terra pesado (1.0 x 3) = 3.0, limite
  static const maxShoulderStress = 3.5;  // shoulder press (0.7 x 5) = 3.5
  static const maxKneeStress = 4.0;      // squat pesado (0.8 x 5) = 4.0
  static const maxCnsLoad = 3.0;         // soma de CNS por exercício (direto, não por série)
  
  // Fator de decaimento da fadiga (50% após 48h)
  static const _fatigueDecayFactor = 0.5;

  /// Carrega fadiga residual das últimas sessões.
  /// A fadiga decai exponencialmente com o tempo.
  void loadResidualFatigue(List<PrescribedSession> recentSessions) {
    if (recentSessions.isEmpty) return;
    
    for (int i = 0; i < recentSessions.length && i < 3; i++) {
      final session = recentSessions[i];
      final decay = _fatigueDecayFactor * (i + 1); // Mais recente = mais fadiga
      
      _residualSpinalLoad += session.fatigue.spinalLoad * decay;
      _residualShoulderStress += session.fatigue.shoulderStress * decay;
      _residualKneeStress += session.fatigue.kneeStress * decay;
      _residualCnsLoad += session.fatigue.cnsLoad * decay;
    }
  }

  bool canAdd(ExerciseModel ex, int sets) {
    final totalSpinal = spinalLoadAccumulated + _residualSpinalLoad + ex.spinalLoad * sets;
    final totalShoulder = shoulderStressAccumulated + _residualShoulderStress + ex.shoulderStress * sets;
    final totalKnee = kneeStressAccumulated + _residualKneeStress + ex.kneeStress * sets;
    final totalCns = cnsLoadAccumulated + _residualCnsLoad + ex.cnsLoad * sets;
    
    return totalSpinal <= maxSpinalLoad &&
        totalShoulder <= maxShoulderStress &&
        totalKnee <= maxKneeStress &&
        totalCns <= maxCnsLoad;
  }

  void add(ExerciseModel ex, int sets) {
    spinalLoadAccumulated += ex.spinalLoad * sets;
    shoulderStressAccumulated += ex.shoulderStress * sets;
    kneeStressAccumulated += ex.kneeStress * sets;
    cnsLoadAccumulated += ex.cnsLoad * sets;
    
    // Rastrear contagem por músculo
    for (final muscle in ex.primaryMuscles) {
      _exerciseCountByMuscle[muscle] = (_exerciseCountByMuscle[muscle] ?? 0) + 1;
    }
  }

  /// Retorna quantos exercícios já foram adicionados para um músculo.
  int getExerciseCountForMuscle(String muscle) {
    return _exerciseCountByMuscle[muscle] ?? 0;
  }

  double get fatigueRatio => (spinalLoadAccumulated + _residualSpinalLoad) / maxSpinalLoad;
  bool get isSpinalLoadCritical => (spinalLoadAccumulated + _residualSpinalLoad) > maxSpinalLoad * 0.8;
  bool get isShoulderStressCritical => (shoulderStressAccumulated + _residualShoulderStress) > maxShoulderStress * 0.8;
  bool get isKneeStressCritical => (kneeStressAccumulated + _residualKneeStress) > maxKneeStress * 0.8;
}

// ═══════════════════════════════════════════════════════════════
// PATTERN HISTORY TRACKER
//
// Rastreia quais padrões de movimento foram executados nos
// últimos dias para evitar sobreposição entre sessões consecutivas.
// ═══════════════════════════════════════════════════════════════

class PatternHistoryTracker {
  final Map<String, List<String>> _recentPatterns;

  PatternHistoryTracker({Map<String, List<String>>? recentPatterns})
      : _recentPatterns = recentPatterns ?? {};

  Map<String, List<String>> toMap() => Map.fromEntries(
        _recentPatterns.entries.map((e) => MapEntry(e.key, List.from(e.value))),
      );

  factory PatternHistoryTracker.fromMap(Map<String, dynamic> map) {
    return PatternHistoryTracker(
      recentPatterns: map.map(
        (k, v) => MapEntry(k, List<String>.from(v as List)),
      ),
    );
  }

  void recordDay(String dayKey, List<String> movementPatterns) {
    _recentPatterns[dayKey] = List.from(movementPatterns);
  }

  /// Retorna 1.0 se o padrão não foi usado recentemente, 0.5 se foi
  /// usado há 2 dias, 0.0 se foi usado ontem (bloqueia).
  double patternAvailability(String pattern) {
    final yesterday = _recentPatterns['day_minus_1'] ?? [];
    final twoDaysAgo = _recentPatterns['day_minus_2'] ?? [];

    if (yesterday.any((p) => _relatedPatterns(p, pattern))) return 0.0;
    if (twoDaysAgo.any((p) => _relatedPatterns(p, pattern))) return 0.5;
    return 1.0;
  }

  /// Verifica se dois padrões são relacionados (compartilham carga articular)
  bool _relatedPatterns(String a, String b) {
    if (a == b) return true;
    // hinge + squat compartilham carga lombar
    if (_isSpinalPattern(a) && _isSpinalPattern(b)) return true;
    // push_vertical + push_horizontal compartilham ombro
    if (a.startsWith('push_') && b.startsWith('push_')) return true;
    return false;
  }

  bool _isSpinalPattern(String pattern) {
    return pattern.contains('hinge') || pattern.contains('squat');
  }

  String get spinalLoadWarning {
    final yesterday = _recentPatterns['day_minus_1'] ?? [];
    if (yesterday.any(_isSpinalPattern)) {
      return 'Sessão com alta carga lombar no dia anterior. Priorize alternativas de baixa sobrecarga.';
    }
    return '';
  }
}
