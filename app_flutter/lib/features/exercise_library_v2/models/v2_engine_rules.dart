/// Regras de configuração do motor para um exercício.
/// Parâmetros que o motor usa para prescrever séries, repetições, descanso.
class V2EngineRules {
  final int repRangeMin;
  final int repRangeMax;
  final int defaultRestSeconds;
  final bool isUnilateral;
  final bool isCompound;
  final String category;
  final bool loadProgressable;
  final bool repsProgressable;
  final bool complexityProgressable;

  const V2EngineRules({
    this.repRangeMin = 8,
    this.repRangeMax = 12,
    this.defaultRestSeconds = 120,
    this.isUnilateral = false,
    this.isCompound = false,
    this.category = 'isolation',
    this.loadProgressable = true,
    this.repsProgressable = true,
    this.complexityProgressable = true,
  });

  Map<String, dynamic> toMap() => {
    'repRangeMin': repRangeMin,
    'repRangeMax': repRangeMax,
    'defaultRestSeconds': defaultRestSeconds,
    'isUnilateral': isUnilateral,
    'isCompound': isCompound,
    'category': category,
    'loadProgressable': loadProgressable,
    'repsProgressable': repsProgressable,
    'complexityProgressable': complexityProgressable,
  };

  factory V2EngineRules.fromMap(Map<String, dynamic> m) => V2EngineRules(
    repRangeMin: (m['repRangeMin'] as num?)?.toInt() ?? 8,
    repRangeMax: (m['repRangeMax'] as num?)?.toInt() ?? 12,
    defaultRestSeconds: (m['defaultRestSeconds'] as num?)?.toInt() ?? 120,
    isUnilateral: m['isUnilateral'] as bool? ?? false,
    isCompound: m['isCompound'] as bool? ?? false,
    category: m['category'] as String? ?? 'isolation',
    loadProgressable: m['loadProgressable'] as bool? ?? true,
    repsProgressable: m['repsProgressable'] as bool? ?? true,
    complexityProgressable: m['complexityProgressable'] as bool? ?? true,
  );
}
