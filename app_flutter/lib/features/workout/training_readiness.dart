enum ConfidenceLevel { high, moderate, low, absent }

class LifeLoad {
  final String physicalWork;
  final String parallelSport;
  final String dailyRoutine;

  const LifeLoad({
    this.physicalWork = 'moderate',
    this.parallelSport = 'low',
    this.dailyRoutine = 'moderate',
  });

  double get multiplier {
    double value = 1.0;
    value -= _loadValue(physicalWork) * 0.08;
    value -= _loadValue(parallelSport) * 0.08;
    value -= _loadValue(dailyRoutine) * 0.04;
    return value.clamp(0.7, 1.0).toDouble();
  }

  static double _loadValue(String value) {
    switch (value) {
      case 'high': return 1.0;
      case 'moderate': return 0.5;
      default: return 0.0;
    }
  }

  Map<String, dynamic> toMap() => {
        'physicalWork': physicalWork,
        'parallelSport': parallelSport,
        'dailyRoutine': dailyRoutine,
      };

  factory LifeLoad.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const LifeLoad();
    return LifeLoad(
      physicalWork: map['physicalWork'] as String? ?? 'moderate',
      parallelSport: map['parallelSport'] as String? ?? 'low',
      dailyRoutine: map['dailyRoutine'] as String? ?? 'moderate',
    );
  }
}

class DailyReadiness {
  final double sleepScore;
  final double stressScore;
  final double lifeLoadMultiplier;

  const DailyReadiness({
    required this.sleepScore,
    required this.stressScore,
    required this.lifeLoadMultiplier,
  });

  double get volumeMultiplier {
    final recovery = (sleepScore + stressScore) / 2;
    return (recovery * 0.25 + 0.75) * lifeLoadMultiplier;
  }

  String get status {
    if (volumeMultiplier >= 0.9) return 'ready';
    if (volumeMultiplier >= 0.78) return 'adapt';
    return 'recover';
  }

  static DailyReadiness fromProfile({
    required String sleepQuality,
    required String stressLevel,
    required LifeLoad lifeLoad,
  }) {
    double score(String value) {
      switch (value) {
        case 'good':
        case 'low': return 1.0;
        case 'regular':
        case 'medium': return 0.7;
        default: return 0.4;
      }
    }

    return DailyReadiness(
      sleepScore: score(sleepQuality),
      stressScore: score(stressLevel),
      lifeLoadMultiplier: lifeLoad.multiplier,
    );
  }
}
