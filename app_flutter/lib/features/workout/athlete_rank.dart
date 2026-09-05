import 'dart:ui';

/// Sistema de Rank do Atleta baseado em Volume Total (XP).
///
/// XP = volume total deslocado em kg ao longo da vida do usuário.
/// Cada rank tem um threshold de XP e uma cor associada.
class AthleteRank {
  final String name;
  final String icon;
  final int minXP;
  final Color color;
  final Color glowColor;

  const AthleteRank({
    required this.name,
    required this.icon,
    required this.minXP,
    required this.color,
    required this.glowColor,
  });
}

/// Tabela de ranks ordenada do menor para o maior XP.
const List<AthleteRank> athleteRanks = [
  AthleteRank(
    name: 'Ferro',
    icon: '🏋️',
    minXP: 0,
    color: Color(0xFF6B7280),
    glowColor: Color(0x336B7280),
  ),
  AthleteRank(
    name: 'Bronze',
    icon: '🥉',
    minXP: 50000,
    color: Color(0xFFCD7F32),
    glowColor: Color(0x33CD7F32),
  ),
  AthleteRank(
    name: 'Prata',
    icon: '🥈',
    minXP: 200000,
    color: Color(0xFFC0C0C0),
    glowColor: Color(0x33C0C0C0),
  ),
  AthleteRank(
    name: 'Ouro',
    icon: '🥇',
    minXP: 500000,
    color: Color(0xFFFFD700),
    glowColor: Color(0x33FFD700),
  ),
  AthleteRank(
    name: 'Diamante',
    icon: '💎',
    minXP: 1000000,
    color: Color(0xFF00BFFF),
    glowColor: Color(0x3300BFFF),
  ),
  AthleteRank(
    name: 'Mestre',
    icon: '👑',
    minXP: 2500000,
    color: Color(0xFF9B59B6),
    glowColor: Color(0x339B59B6),
  ),
  AthleteRank(
    name: 'Lenda',
    icon: '⚡',
    minXP: 5000000,
    color: Color(0xFFFF4500),
    glowColor: Color(0x33FF4500),
  ),
];

/// Resultado do cálculo de rank.
class RankResult {
  final AthleteRank currentRank;
  final AthleteRank? nextRank;
  final int totalXP;
  final double progressPercent;
  final int xpForNext;
  final int xpInCurrentRank;

  const RankResult({
    required this.currentRank,
    this.nextRank,
    required this.totalXP,
    required this.progressPercent,
    required this.xpForNext,
    required this.xpInCurrentRank,
  });
}

/// Calcula o rank atual do atleta baseado no XP total.
RankResult calculateRank(int totalXP) {
  AthleteRank current = athleteRanks.first;
  AthleteRank? next;

  for (int i = athleteRanks.length - 1; i >= 0; i--) {
    if (totalXP >= athleteRanks[i].minXP) {
      current = athleteRanks[i];
      next = i + 1 < athleteRanks.length ? athleteRanks[i + 1] : null;
      break;
    }
  }

  final xpInCurrent = totalXP - current.minXP;
  final xpNeeded = next != null ? next.minXP - current.minXP : 0;
  final progress = next != null && xpNeeded > 0
      ? (xpInCurrent / xpNeeded).clamp(0.0, 1.0)
      : 1.0;

  return RankResult(
    currentRank: current,
    nextRank: next,
    totalXP: totalXP,
    progressPercent: progress,
    xpForNext: xpNeeded,
    xpInCurrentRank: xpInCurrent,
  );
}

/// Formata XP para exibição amigável.
String formatXP(int xp) {
  if (xp >= 1000000) {
    return '${(xp / 1000000).toStringAsFixed(1)}M';
  } else if (xp >= 1000) {
    return '${(xp / 1000).toStringAsFixed(1)}k';
  }
  return xp.toString();
}

/// Formata volume em kg para exibição.
String formatVolume(double kg) {
  if (kg >= 1000000) {
    return '${(kg / 1000000).toStringAsFixed(1)}M kg';
  } else if (kg >= 1000) {
    return '${(kg / 1000).toStringAsFixed(1)}k kg';
  }
  return '${kg.toStringAsFixed(0)} kg';
}
