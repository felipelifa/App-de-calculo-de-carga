// ─────────────────────────────────────────────
// Coach Explainer Service
// Gera explicações em linguagem simples sobre
// cada decisão do motor de progressão.
// 100% local — sem custo de API.
// ─────────────────────────────────────────────

class CoachExplainerService {
  static const CoachExplainerService _instance = CoachExplainerService._internal();
  factory CoachExplainerService() => _instance;
  const CoachExplainerService._internal();

  // ── API pública ───────────────────────────────

  /// Gera explicação para uma sugestão de progressão
  String explainProgression({
    required String reason,
    int? rir,
    double? deltaKg,
    int? weeksWithoutProgress,
    int? consecutiveMisses,
    int? deloadWeeks,
    String? exerciseName,
  }) {
    switch (reason) {
      case 'increase_load':
        return _explainIncreaseLoad(rir: rir ?? 3, delta: deltaKg ?? 2.5);

      case 'consolidate':
        return _explainConsolidate(rir: rir ?? 2);

      case 'decrease_load':
        return _explainDecreaseLoad(misses: consecutiveMisses ?? 2);

      case 'plateau_swap':
        return _explainPlateau(weeks: weeksWithoutProgress ?? 3, exercise: exerciseName);

      case 'deload':
        return _explainDeload(weeks: deloadWeeks ?? 6);

      case 'exercise_rotation':
        return _explainRotation();

      case 'bodyweight_advance':
        return _explainBodyweightAdvance(exercise: exerciseName);

      default:
        return 'O motor de progressão avaliou seu desempenho e ajustou o treino conforme os princípios de periodização científica.';
    }
  }

  /// Gera explicação para o DUP da sessão
  String explainDupPhase(String phase) {
    switch (phase) {
      case 'strength':
        return 'Hoje é seu DIA DE FORÇA. Cargas máximas com menos repetições constroem mais densidade óssea e força neural. Descanse bem entre as séries (3-5 min) para recuperação total do SNC.';
      case 'hypertrophy':
        return 'Hoje é seu DIA DE HIPERTROFIA. A faixa de 8-12 repetições maximiza o estímulo metabólico e tensão mecânica — os dois principais gatilhos para crescimento muscular. Foco na conexão mente-músculo.';
      case 'endurance':
        return 'Hoje é seu DIA DE RESISTÊNCIA MUSCULAR. Repetições altas com descanso curto criam estresse metabólico e promovem capilarização muscular. Use ~60% da carga habitual e não pare cedo.';
      default:
        return 'Treinamento baseado em periodização científica para maximizar seus resultados.';
    }
  }

  /// Gera explicação para deload ativo
  String explainActiveDeload(int weeks) {
    return 'Você completou $weeks semanas de treino intenso. 🧠 Seu sistema nervoso central precisa de recuperação estruturada. Esta semana de deload é cientificamente o que vai permitir você bater novos recordes na próxima fase — não pule ela.';
  }

  /// Gera explicação para rotação de exercício
  String explainWeeklyRotation(String oldExercise, String newExercise) {
    return 'Após 2 semanas, trocamos "$oldExercise" por "$newExercise". Isso previne adaptação neural excessiva e mantém o crescimento muscular ativo — baseado em Schoenfeld (2021).';
  }

  // ── Explicações privadas ──────────────────────

  String _explainIncreaseLoad({required int rir, required double delta}) {
    final deltaStr = delta % 1 == 0 ? delta.toInt().toString() : delta.toStringAsFixed(1);
    return 'Você está completando as séries com facilidade (RIR $rir — ainda tem $rir repetições de reserva). O motor identificou adaptação neural completa — hora de aumentar a carga em ${deltaStr}kg para manter o estímulo de hipertrofia e continuar progredindo.';
  }

  String _explainConsolidate({required int rir}) {
    return 'Você está na zona ideal de esforço (RIR $rir). Continue nesta carga por mais uma sessão para consolidar completamente a adaptação antes de progredir — respeitar esse passo evita platôs precoces.';
  }

  String _explainDecreaseLoad({required int misses}) {
    return 'Você não completou as repetições alvo por $misses sessões seguidas. O motor reduziu a carga em 10% para reajustar a progressão de forma segura — isso é normal e faz parte do processo de periodização inteligente.';
  }

  String _explainPlateau({required int weeks, String? exercise}) {
    final exStr = exercise != null ? ' em "$exercise"' : '';
    return 'Detectamos um platô$exStr após $weeks sessões sem evolução de carga. O motor trocou o exercício por uma variação equivalente para criar novo estímulo neural e muscular — o princípio da variação de Bompa em ação.';
  }

  String _explainDeload({required int weeks}) {
    return 'Você completou $weeks semanas de treino progressivo. Seu sistema nervoso central (SNC) acumulou fadiga que não é visível mas limita a performance. Esta semana de deload (carga -40%, volume -50%) é o que vai permitir superar seus recordes pessoais na próxima fase.';
  }

  String _explainRotation() {
    return 'A cada 2 semanas, o motor troca 1-2 exercícios por grupo muscular. Isso previne adaptação neural excessiva e mantém o crescimento muscular ativo ao recrutar fibras musculares em ângulos ligeiramente diferentes — baseado em Schoenfeld, IUSCA 2021.';
  }

  String _explainBodyweightAdvance({String? exercise}) {
    final exStr = exercise != null ? ' "$exercise"' : '';
    return 'Você dominou a variação atual$exStr — completou 3 sessões no máximo de repetições com técnica consistente. O motor avançou você para a próxima progressão na cadeia de calistenia para continuar gerando sobrecarga progressiva.';
  }
}
