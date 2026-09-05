import 'prescribed_workout_model.dart';
import 'training_readiness.dart';

/// 🧬 BIO-ADAPTIVE ENGINE v7.0
/// O "Organismo Digital" que simula fadiga e adaptação.
/// Integrado com DailyReadiness para unificar fonte de verdade.
class BioAdaptiveEngine {
  
  // Limites de fadiga para intervenção (0.0 a 1.0)
  static const double maxCnsLoadThreshold = 0.8;
  static const double maxJointStressThreshold = 0.75;

  /// Calcula o "Índice de Prontidão" (Readiness Score) do usuário.
  /// Combina fadiga acumulada das sessões com DailyReadiness.
  static BioReadiness calculateReadiness({
    required List<PrescribedSession> recentHistory,
    required DailyReadiness dailyReadiness,
  }) {
    double accumulatedCns = 0;
    double accumulatedSpinal = 0;
    double accumulatedShoulder = 0;
    double accumulatedKnee = 0;

    // Analisa as últimas 3 sessões (janela de fadiga aguda)
    final sessionsToAnalyze = recentHistory.take(3).toList();
    
    // Se não há histórico, usar apenas DailyReadiness
    if (sessionsToAnalyze.isEmpty) {
      return BioReadiness(
        score: dailyReadiness.volumeMultiplier,
        status: _statusFromReadiness(dailyReadiness),
        recommendation: _recommendationFromReadiness(dailyReadiness),
        cnsFatigue: 0.0,
        jointStress: 0.0,
      );
    }

    for (var session in sessionsToAnalyze) {
      accumulatedCns += session.fatigue.cnsLoad;
      accumulatedSpinal += session.fatigue.spinalLoad;
      accumulatedShoulder += session.fatigue.shoulderStress;
      accumulatedKnee += session.fatigue.kneeStress;
    }

    // Médias normalizadas (dividir pelo número real de sessões analisadas)
    final count = sessionsToAnalyze.length;
    // Multiplicador de fadiga baseado no sono e estresse (DailyReadiness)
    final sleepMultiplier = 1.0 + (1.0 - dailyReadiness.sleepScore) * 0.4;
    final stressMultiplier = 1.0 + (1.0 - dailyReadiness.stressScore) * 0.3;
    final avgCns = (accumulatedCns / count) * sleepMultiplier * stressMultiplier;
    final avgJoint = (accumulatedSpinal + accumulatedShoulder + accumulatedKnee) / (count * 3);

    // Determina o estado combinando fadiga acumulada e DailyReadiness
    BioStatus status = BioStatus.optimal;
    String recommendation = "Plano ideal mantido.";

    if (avgCns > maxCnsLoadThreshold || avgJoint > maxJointStressThreshold) {
      status = BioStatus.recovering;
      recommendation = "Sistema detectou fadiga acumulada. Reduzindo volume acessório.";
    } else if (dailyReadiness.status == 'recover') {
      status = BioStatus.fragile;
      recommendation = "Fatores externos de stress detectados. Priorizando intensidade controlada.";
    } else if (dailyReadiness.status == 'adapt') {
      status = BioStatus.recovering;
      recommendation = "Readiness moderada. Ajustando volume conforme necessário.";
    }

    // Score combinado: 60% DailyReadiness + 40% fadiga acumulada
    final fatigueScore = (1.0 - ((avgCns + avgJoint) / 2)).clamp(0.0, 1.0);
    final combinedScore = (dailyReadiness.volumeMultiplier * 0.6 + fatigueScore * 0.4).clamp(0.0, 1.0);

    return BioReadiness(
      score: combinedScore,
      status: status,
      recommendation: recommendation,
      cnsFatigue: avgCns.clamp(0.0, 1.0),
      jointStress: avgJoint.clamp(0.0, 1.0),
    );
  }

  static BioStatus _statusFromReadiness(DailyReadiness readiness) {
    if (readiness.status == 'recover') return BioStatus.fragile;
    if (readiness.status == 'adapt') return BioStatus.recovering;
    return BioStatus.optimal;
  }

  static String _recommendationFromReadiness(DailyReadiness readiness) {
    if (readiness.status == 'recover') {
      return "Readiness baixa. Considere reduzir volume ou intensidade.";
    }
    if (readiness.status == 'adapt') {
      return "Readiness moderada. Ajustando conforme necessário.";
    }
    return "Pronto para o estímulo ideal.";
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
