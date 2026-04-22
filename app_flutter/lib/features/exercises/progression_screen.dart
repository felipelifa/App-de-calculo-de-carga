import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/theme/app_theme.dart';
import '../exercises/exercise_provider.dart';
import '../workout/progression_service.dart';
import '../workout/progression_provider.dart';
import '../workout/progression_engine.dart';

// ═══════════════════════════════════════════════════════════════
// ProgressionScreen v2
//
// Combina dois motores:
// 1. ProgressionProvider (motor de RIR — pós-sessão, tempo real)
// 2. ProgressionService (motor histórico — baseado em logs de carga)
// ═══════════════════════════════════════════════════════════════

class ProgressionScreen extends StatefulWidget {
  const ProgressionScreen({super.key});

  @override
  State<ProgressionScreen> createState() => _ProgressionScreenState();
}

class _ProgressionScreenState extends State<ProgressionScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  Future<List<ProgressionSuggestion>>? _historicFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadHistoric();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadHistoric() {
    final exercises = context.read<ExerciseProvider>().filteredExercises;
    setState(() {
      _historicFuture = ProgressionService().generateSuggestions(exercises);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: const Text('Progressão',
            style: TextStyle(
                color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: AppTheme.textSecondary),
            onPressed: _loadHistoric,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.accent,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.accent,
          tabs: const [
            Tab(text: 'Após o Treino'),
            Tab(text: 'Histórico'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _RirDecisionsTab(),
          _HistoricTab(future: _historicFuture, onRefresh: _loadHistoric),
        ],
      ),
    );
  }
}

// ─── Tab 1: Motor de RIR ──────────────────────

class _RirDecisionsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProgressionProvider>();

    if (provider.isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.accent));
    }

    final decisions = provider.lastDecisions;
    final state = provider.state;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        if (state != null) ...[
          _CycleBanner(state: state),
          const SizedBox(height: 16),
        ],
        if (decisions.any((d) => d.type == ProgressionDecisionType.deload))
          _DeloadBanner(
            decision: decisions.firstWhere(
                (d) => d.type == ProgressionDecisionType.deload),
          )
        else if (decisions.isEmpty)
          _EmptyRirState()
        else ...[
          _RirInfoBanner(),
          const SizedBox(height: 16),
          ...decisions
              .where((d) => d.type != ProgressionDecisionType.deload)
              .map((d) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _RirDecisionCard(decision: d),
                  )),
        ],
      ],
    );
  }
}

class _CycleBanner extends StatelessWidget {
  final ProgressionState state;
  const _CycleBanner({required this.state});

  Color get _color {
    switch (state.currentPhase) {
      case 'accumulation': return AppTheme.accent;
      case 'intensification': return const Color(0xFFF59E0B);
      case 'peak': return AppTheme.success;
      case 'deload': return AppTheme.danger;
      default: return AppTheme.accent;
    }
  }

  String get _phaseLabel {
    switch (state.currentPhase) {
      case 'accumulation': return 'Acumulação';
      case 'intensification': return 'Intensificação';
      case 'peak': return 'Pico';
      case 'deload': return 'Deload';
      default: return state.currentPhase;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _color;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: c.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.loop_rounded, color: c, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Semana ${state.currentWeek}  •  Fase: $_phaseLabel',
                        style: TextStyle(
                            color: c,
                            fontWeight: FontWeight.bold,
                            fontSize: 13)),
                    if (state.isDeloadWeek) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                            color: AppTheme.danger.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6)),
                        child: const Text('DELOAD',
                            style: TextStyle(
                                color: AppTheme.danger,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  state.weeksUntilDeload <= 0
                      ? 'Deload programado para esta semana'
                      : '${state.weeksUntilDeload} semana(s) até o próximo deload',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DeloadBanner extends StatelessWidget {
  final ProgressionDecision decision;
  const _DeloadBanner({required this.decision});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.refresh_rounded, color: AppTheme.danger, size: 20),
              SizedBox(width: 10),
              Text('SEMANA DE DELOAD',
                  style: TextStyle(
                      color: AppTheme.danger,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 12),
          Text(decision.reason,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 13, height: 1.5)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: AppTheme.surfaceHighlight,
                borderRadius: BorderRadius.circular(12)),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('O que fazer esta semana:',
                    style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                SizedBox(height: 8),
                _Tip('Volume -45% — menos séries por exercício'),
                _Tip('Carga igual — não reduza os pesos'),
                _Tip('Mesma frequência — não pule treinos'),
                _Tip('Foco em técnica e qualidade de movimento'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tip extends StatelessWidget {
  final String text;
  const _Tip(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('→ ', style: TextStyle(color: AppTheme.danger, fontSize: 13)),
        Expanded(child: Text(text, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13))),
      ],
    ),
  );
}

class _EmptyRirState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Column(
            children: [
              Icon(Icons.fitness_center_rounded,
                  size: 56,
                  color: AppTheme.textSecondary.withValues(alpha: 0.3)),
              const SizedBox(height: 16),
              const Text('Sem decisões recentes',
                  style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              const Text(
                'Complete um treino e registre o RIR de cada exercício. O motor vai analisar e dizer exatamente o que fazer na próxima sessão.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppTheme.textSecondary, fontSize: 13, height: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _RirInfoBanner(),
      ],
    );
  }
}

class _RirInfoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.accent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: AppTheme.accent, size: 16),
              SizedBox(width: 8),
              Text('O que é RIR?',
                  style: TextStyle(
                      color: AppTheme.accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'RIR = Reps in Reserve. É o número de repetições que você ainda conseguiria fazer antes da falha. '
            'RIR 0 = falha. RIR 1-2 = zona ideal de hipertrofia. RIR 3+ = muito fácil.',
            style: TextStyle(
                color: AppTheme.textSecondary, fontSize: 12, height: 1.5),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            children: [
              _RirChip('RIR 0', AppTheme.danger, 'Falha'),
              _RirChip('RIR 1-2', AppTheme.success, 'Ideal'),
              _RirChip('RIR 3-4', AppTheme.accent, 'Moderado'),
              _RirChip('RIR 5+', AppTheme.textSecondary, 'Fácil'),
            ],
          ),
        ],
      ),
    );
  }
}

class _RirChip extends StatelessWidget {
  final String label, sub;
  final Color color;
  const _RirChip(this.label, this.color, this.sub);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Column(children: [
      Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
      Text(sub, style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 10)),
    ]),
  );
}

class _RirDecisionCard extends StatelessWidget {
  final ProgressionDecision decision;
  const _RirDecisionCard({required this.decision});

  Color get _color {
    switch (decision.type) {
      case ProgressionDecisionType.increaseLoad: return AppTheme.success;
      case ProgressionDecisionType.consolidate: return AppTheme.accent;
      case ProgressionDecisionType.decreaseLoad: return const Color(0xFFF59E0B);
      case ProgressionDecisionType.substituteExercise: return const Color(0xFF8B5CF6);
      case ProgressionDecisionType.advanceBodyweight: return AppTheme.success;
      case ProgressionDecisionType.continueBodyweight: return AppTheme.accent;
      case ProgressionDecisionType.deload: return AppTheme.danger;
    }
  }

  IconData get _icon {
    switch (decision.type) {
      case ProgressionDecisionType.increaseLoad: return Icons.trending_up_rounded;
      case ProgressionDecisionType.consolidate: return Icons.check_circle_outline_rounded;
      case ProgressionDecisionType.decreaseLoad: return Icons.trending_down_rounded;
      case ProgressionDecisionType.substituteExercise: return Icons.swap_horiz_rounded;
      case ProgressionDecisionType.advanceBodyweight: return Icons.upgrade_rounded;
      case ProgressionDecisionType.continueBodyweight: return Icons.pending_rounded;
      case ProgressionDecisionType.deload: return Icons.refresh_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _color;
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                      color: c.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(9)),
                  child: Icon(_icon, color: c, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(decision.title,
                      style: TextStyle(
                          color: c,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(decision.reason,
                    style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                        height: 1.4)),
                if (decision.suggestedWeightKg != null) ...[
                  const SizedBox(height: 12),
                  _WeightRow(value: decision.suggestedWeightKg!, color: c),
                ],
                if (decision.suggestedSubstituteId != null) ...[
                  const SizedBox(height: 10),
                  _InfoRow(
                      icon: Icons.swap_horiz_rounded,
                      text: 'Substituir por: ${decision.suggestedSubstituteId}',
                      color: c),
                ],
                if (decision.suggestedProgressionId != null) ...[
                  const SizedBox(height: 10),
                  _InfoRow(
                      icon: Icons.upgrade_rounded,
                      text: 'Avançar para: ${decision.suggestedProgressionId}',
                      color: c),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeightRow extends StatelessWidget {
  final double value;
  final Color color;
  const _WeightRow({required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
        color: AppTheme.surfaceHighlight,
        borderRadius: BorderRadius.circular(12)),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Carga sugerida',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        const SizedBox(width: 12),
        Icon(Icons.arrow_forward_rounded, color: color, size: 18),
        const SizedBox(width: 12),
        Text('${value.toStringAsFixed(1)} kg',
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 18)),
      ],
    ),
  );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _InfoRow({required this.icon, required this.text, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10)),
    child: Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: TextStyle(color: color, fontSize: 12))),
      ],
    ),
  );
}

// ─── Tab 2: Histórico ─────────────────────────

class _HistoricTab extends StatelessWidget {
  final Future<List<ProgressionSuggestion>>? future;
  final VoidCallback onRefresh;
  const _HistoricTab({required this.future, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ProgressionSuggestion>>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppTheme.accent));
        }
        if (snap.hasError) {
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.error_outline, color: AppTheme.danger, size: 48),
              const SizedBox(height: 16),
              Text('Erro: ${snap.error}',
                  style: const TextStyle(color: AppTheme.textSecondary)),
              const SizedBox(height: 16),
              TextButton(
                  onPressed: onRefresh,
                  child: const Text('Tentar novamente')),
            ]),
          );
        }
        final suggestions = snap.data ?? [];
        if (suggestions.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.insights_rounded,
                    size: 72,
                    color: AppTheme.textSecondary.withValues(alpha: 0.3)),
                const SizedBox(height: 24),
                const Text('Sem dados suficientes',
                    style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                const Text(
                  'Complete pelo menos 2 treinos com o mesmo exercício.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Verificar novamente'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.accent,
                    side: const BorderSide(color: AppTheme.accent),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ]),
            ),
          );
        }
        return RefreshIndicator(
          color: AppTheme.accent,
          backgroundColor: AppTheme.surface,
          onRefresh: () async => onRefresh(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppTheme.accent.withValues(alpha: 0.2)),
                ),
                child: const Row(children: [
                  Icon(Icons.history_rounded, color: AppTheme.accent, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Análise baseada no histórico de cargas e repetições registradas.',
                      style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                          height: 1.4),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 16),
              ..._buildGroups(suggestions),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildGroups(List<ProgressionSuggestion> suggestions) {
    final groups = <ProgressionType, List<ProgressionSuggestion>>{};
    for (final s in suggestions) {
      groups.putIfAbsent(s.type, () => []).add(s);
    }
    const order = [
      ProgressionType.increaseWeight,
      ProgressionType.increaseReps,
      ProgressionType.deloadWeek,
      ProgressionType.maintain,
      ProgressionType.decreaseWeight,
    ];
    final labels = {
      ProgressionType.increaseWeight: '🏋️  AUMENTAR CARGA',
      ProgressionType.increaseReps: '🔁  AUMENTAR REPETIÇÕES',
      ProgressionType.deloadWeek: '🔄  DELOAD RECOMENDADO',
      ProgressionType.maintain: '✅  MANTER RITMO',
      ProgressionType.decreaseWeight: '⬇️  REDUZIR CARGA',
    };
    final widgets = <Widget>[];
    for (final type in order) {
      final group = groups[type];
      if (group == null || group.isEmpty) continue;
      widgets.add(Text(labels[type]!,
          style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2)));
      widgets.add(const SizedBox(height: 10));
      for (final s in group) {
        widgets.add(SuggestionCard(suggestion: s));
        widgets.add(const SizedBox(height: 10));
      }
      widgets.add(const SizedBox(height: 12));
    }
    return widgets;
  }
}

// ─── SuggestionCard (reutilizável) ───────────

Color muscleColor(String muscle) {
  const map = {
    'chest': Color(0xFF6366F1),
    'back': Color(0xFF0EA5E9),
    'shoulders': Color(0xFF8B5CF6),
    'side_delt': Color(0xFF8B5CF6),
    'rear_delt': Color(0xFF8B5CF6),
    'biceps': Color(0xFF10B981),
    'triceps': Color(0xFF14B8A6),
    'quads': Color(0xFFF59E0B),
    'hamstrings': Color(0xFFEF4444),
    'glutes': Color(0xFFEC4899),
    'calves': Color(0xFF84CC16),
    'abs': Color(0xFFF97316),
    'core': Color(0xFFF97316),
  };
  return map[muscle] ?? AppTheme.accent;
}

class SuggestionCard extends StatelessWidget {
  final ProgressionSuggestion suggestion;
  const SuggestionCard({super.key, required this.suggestion});

  Color get _color {
    switch (suggestion.type) {
      case ProgressionType.increaseWeight: return AppTheme.success;
      case ProgressionType.increaseReps: return AppTheme.accent;
      case ProgressionType.deloadWeek: return AppTheme.danger;
      case ProgressionType.maintain: return const Color(0xFF8B5CF6);
      case ProgressionType.decreaseWeight: return const Color(0xFFF59E0B);
    }
  }

  IconData get _icon {
    switch (suggestion.type) {
      case ProgressionType.increaseWeight: return Icons.trending_up_rounded;
      case ProgressionType.increaseReps: return Icons.repeat_rounded;
      case ProgressionType.deloadWeek: return Icons.refresh_rounded;
      case ProgressionType.maintain: return Icons.check_circle_outline_rounded;
      case ProgressionType.decreaseWeight: return Icons.trending_down_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ex = suggestion.exercise;
    final c = _color;
    final pm = ex.primaryMuscles.isNotEmpty ? ex.primaryMuscles.first : 'Geral';
    final mc = muscleColor(pm);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: c.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10)),
                  child: Icon(_icon, color: c, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(suggestion.title,
                          style: TextStyle(
                              color: c,
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(ex.name,
                          style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w500,
                              fontSize: 13)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: mc.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: mc.withValues(alpha: 0.3)),
                  ),
                  child: Text(pm,
                      style: TextStyle(
                          color: mc,
                          fontSize: 10,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(suggestion.reason,
                    style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                        height: 1.4)),
                if (suggestion.suggestedWeight != null ||
                    suggestion.suggestedReps != null) ...[
                  const SizedBox(height: 14),
                  _ProgressionArrow(s: suggestion, color: c),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressionArrow extends StatelessWidget {
  final ProgressionSuggestion s;
  final Color color;
  const _ProgressionArrow({required this.s, required this.color});

  @override
  Widget build(BuildContext context) {
    final showW = s.currentWeight != null && s.suggestedWeight != null;
    final showR = s.currentReps != null && s.suggestedReps != null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: AppTheme.surfaceHighlight,
          borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(children: [
            const Text('ATUAL',
                style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1)),
            const SizedBox(height: 4),
            if (showW)
              Text('${s.currentWeight!.toStringAsFixed(1)} kg',
                  style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
            if (showR && !showW)
              Text('${s.currentReps} reps',
                  style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
            if (showW && showR)
              Text('${s.currentReps} reps',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12)),
          ]),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Icon(Icons.arrow_forward_rounded, color: color, size: 24),
          ),
          Column(children: [
            Text('SUGERIDO',
                style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1)),
            const SizedBox(height: 4),
            if (showW)
              Text('${s.suggestedWeight!.toStringAsFixed(1)} kg',
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
            if (showR && !showW)
              Text('${s.suggestedReps} reps',
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
            if (showW && showR)
              Text('${s.suggestedReps} reps',
                  style: TextStyle(
                      color: color.withValues(alpha: 0.7), fontSize: 12)),
          ]),
        ],
      ),
    );
  }
}
