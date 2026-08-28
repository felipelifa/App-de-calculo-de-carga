import 'prescribed_workout_model.dart';

/// 🧬 BIO-ADAPTIVE ENGINE v6.0
/// O "Organismo Digital" que simula fadiga e adaptação.
class BioAdaptiveEngine {
  
  // Limites de fadiga para intervenção (0.0 a 1.0)
  static const double maxCnsLoadThreshold = 0.8;
  static const double maxJointStressThreshold = 0.75;

  /// Calcula o "Índice de Prontidão" (Readiness Score) do usuário.
  /// Baseado no acúmulo de fadiga das últimas sessões e aderência.
  static BioReadiness calculateReadiness({
    required List<PrescribedSession> recentHistory,
    required double sleepQualityScore, // 1.0 (Ótimo) a 0.0 (Péssimo)
    required double stressLevelScore,  // 1.0 (Baixo) a 0.0 (Alto)
  }) {
    double accumulatedCns = 0;
    double accumulatedSpinal = 0;
    double accumulatedShoulder = 0;
    double accumulatedKnee = 0;

    // Analisa as últimas 3 sessões (janela de fadiga aguda)
    final sessionsToAnalyze = recentHistory.take(3).toList();
    if (sessionsToAnalyze.isEmpty) return const BioReadiness();

    for (var session in sessionsToAnalyze) {
      accumulatedCns += session.fatigue.cnsLoad;
      accumulatedSpinal += session.fatigue.spinalLoad;
      accumulatedShoulder += session.fatigue.shoulderStress;
      accumulatedKnee += session.fatigue.kneeStress;
    }

    // Médias normalizadas (dividir pelo número real de sessões analisadas)
    final count = sessionsToAnalyze.length;
    final avgCns = (accumulatedCns / count) * (1.2 - sleepQualityScore);
    final avgJoint = (accumulatedSpinal + accumulatedShoulder + accumulatedKnee) / (count * 3);

    // Determina o estado
    BioStatus status = BioStatus.optimal;
    String recommendation = "Plano ideal mantido.";

    if (avgCns > maxCnsLoadThreshold || avgJoint > maxJointStressThreshold) {
      status = BioStatus.recovering;
      recommendation = "Sistema detectou fadiga acumulada. Reduzindo volume acessório.";
    } else if (sleepQualityScore < 0.4 || stressLevelScore < 0.4) {
      status = BioStatus.fragile;
      recommendation = "Fatores externos de stress detectados. Priorizando intensidade controlada.";
    }

    return BioReadiness(
      score: (1.0 - ((avgCns + avgJoint) / 2)).clamp(0.0, 1.0),
      status: status,
      recommendation: recommendation,
      cnsFatigue: avgCns.clamp(0.0, 1.0),
      jointStress: avgJoint.clamp(0.0, 1.0),
    );
  }

  /// Intervém na prescrição de forma "silenciosa" se as tendências indicarem risco.
  static PrescribedExercise applyBioAdaptation(PrescribedExercise ex, BioReadiness readiness) {
    if (readiness.status == BioStatus.optimal) return ex;

    // Se a fadiga do CNS está alta, reduz o número de séries (Volume)
    int finalSets = ex.sets;
    if (readiness.cnsFatigue > 0.7 && ex.sets > 2) {
      finalSets = ex.sets - 1;
    }

    // Se o stress articular está alto e o exercício carrega muito a coluna, aumenta o RIR (Intensidade menor)
    int finalRir = ex.rir;
    if (readiness.jointStress > 0.6 && ex.exercise.spinalLoad > 0.6) {
      finalRir = ex.rir + 1;
    }

    return PrescribedExercise(
      exercise: ex.exercise,
      sets: finalSets,
      repsMin: ex.repsMin,
      repsMax: ex.repsMax,
      rir: finalRir,
      restSeconds: ex.restSeconds + (readiness.status == BioStatus.recovering ? 30 : 0),
      sessionCues: [
        ...ex.sessionCues,
        if (readiness.status != BioStatus.optimal) "Bio-Adaptation: Foco em controle e técnica hoje."
      ],
      progressionNote: ex.progressionNote,
      injuryNote: readiness.status == BioStatus.fragile ? "Risco de lesão moderadamente elevado por fadiga." : ex.injuryNote,
      tempo: ex.tempo,
    );
  }
}

enum BioStatus { optimal, recovering, fragile }

class BioReadiness {
  final double score;
  final BioStatus status;
  final String recommendation;
  final double cnsFatigue;
  final double jointStress;

  const BioReadiness({
    this.score = 1.0,
    this.status = BioStatus.optimal,
    this.recommendation = "Pronto para o estímulo ideal.",
    this.cnsFatigue = 0.0,
    this.jointStress = 0.0,
  });
}
