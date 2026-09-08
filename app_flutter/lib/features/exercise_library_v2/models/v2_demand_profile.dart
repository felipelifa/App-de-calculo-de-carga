import '../enums/intensity.dart';

/// Demandas quantificadas de um exercício.
/// Cada campo representa uma dimensão de demanda.
/// O motor compara demandas do exercício com capacidades do usuário.
class V2DemandProfile {
  final V2Intensity strength;
  final V2Intensity stability;
  final V2Intensity mobility;
  final V2Intensity balance;
  final V2Intensity coordination;
  final V2Intensity technical;
  final V2Intensity impact;
  final V2Intensity speed;
  final V2Intensity cardiorespiratory;

  const V2DemandProfile({
    this.strength = V2Intensity.moderate,
    this.stability = V2Intensity.moderate,
    this.mobility = V2Intensity.moderate,
    this.balance = V2Intensity.none,
    this.coordination = V2Intensity.low,
    this.technical = V2Intensity.low,
    this.impact = V2Intensity.none,
    this.speed = V2Intensity.none,
    this.cardiorespiratory = V2Intensity.low,
  });

  Map<String, dynamic> toMap() => {
    'strength': strength.name,
    'stability': stability.name,
    'mobility': mobility.name,
    'balance': balance.name,
    'coordination': coordination.name,
    'technical': technical.name,
    'impact': impact.name,
    'speed': speed.name,
    'cardiorespiratory': cardiorespiratory.name,
  };

  factory V2DemandProfile.fromMap(Map<String, dynamic> m) => V2DemandProfile(
    strength: _parseIntensity(m['strength']),
    stability: _parseIntensity(m['stability']),
    mobility: _parseIntensity(m['mobility']),
    balance: _parseIntensity(m['balance']),
    coordination: _parseIntensity(m['coordination']),
    technical: _parseIntensity(m['technical']),
    impact: _parseIntensity(m['impact']),
    speed: _parseIntensity(m['speed']),
    cardiorespiratory: _parseIntensity(m['cardiorespiratory']),
  );

  static V2Intensity _parseIntensity(dynamic value) {
    if (value == null) return V2Intensity.moderate;
    return V2Intensity.values.firstWhere(
      (e) => e.name == value,
      orElse: () => V2Intensity.moderate,
    );
  }
}
