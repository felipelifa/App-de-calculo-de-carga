import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../shared/theme/app_theme.dart';
import '../exercises/exercise_provider.dart';
import '../workout/progression_service.dart';
import '../workout/progression_provider.dart';
import '../workout/progression_engine.dart';
import '../../core/services/coach_explainer_service.dart';

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
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppTheme.background,
            expandedHeight: 120,
            floating: true,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textPrimary, size: 20),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              title: Text(
                'Evolução',
                style: GoogleFonts.outfit(
                  color: AppTheme.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.white54,
                  indicatorSize: TabBarIndicatorSize.tab,
                  padding: const EdgeInsets.all(6),
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: const Color(0xFFCCFF00),
                  ),
                  labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 13),
                  unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13),
                  tabs: const [
                    Tab(text: 'DECISÕES RIR'),
                    Tab(text: 'HISTÓRICO'),
                  ],
                ),
              ),
            ),
          ),
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _RirDecisionsTab(),
                _HistoricTab(future: _historicFuture, onRefresh: _loadHistoric),
              ],
            ),
          ),
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
      return const Center(child: CircularProgressIndicator(color: Color(0xFFCCFF00)));
    }

    final decisions = provider.lastDecisions;
    final state = provider.state;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
      children: [
        if (state != null) ...[
          _CycleBanner(state: state).animate().fadeIn().slideX(begin: 0.1),
          const SizedBox(height: 24),
        ],
        _SectionHeader(title: 'SUGESTÕES DE CARGA'),
        const SizedBox(height: 16),
        if (decisions.isEmpty)
          _EmptyRirState().animate().fadeIn()
        else
          ...decisions.map((d) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _RirDecisionCard(decision: d),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1)),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(width: 4, height: 16, decoration: BoxDecoration(color: const Color(0xFFCCFF00), borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 12),
      Text(title, style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2)),
    ],
  );
}

class _CycleBanner extends StatelessWidget {
  final ProgressionState state;
  const _CycleBanner({required this.state});

  @override
  Widget build(BuildContext context) {
    final color = state.isDeloadWeek ? Colors.redAccent : const Color(0xFFCCFF00);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CICLO ATUAL', style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
                  Text('Semana ${state.currentWeek}', style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Text(
                  state.currentPhase.toUpperCase(),
                  style: GoogleFonts.outfit(color: color, fontWeight: FontWeight.w900, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          LinearProgressIndicator(
            value: (state.currentWeek / 4).clamp(0.0, 1.0),
            backgroundColor: Colors.white10,
            color: color,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 12),
          Text(
            state.isDeloadWeek ? 'Semana de recuperação ativa' : 'Foco em progressão constante de carga',
            style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 12),
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

  @override
  Widget build(BuildContext context) {
    final isPositive = decision.type == ProgressionDecisionType.increaseLoad;
    final color = isPositive ? const Color(0xFFCCFF00) : (decision.type == ProgressionDecisionType.deload ? Colors.redAccent : const Color(0xFF00E5FF));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(Icons.bolt_rounded, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  decision.title,
                  style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(decision.reason, style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 13, height: 1.4)),
          if (decision.suggestedWeightKg != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(16)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('CARGA SUGERIDA:', style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w900)),
                  const SizedBox(width: 12),
                  Text('${decision.suggestedWeightKg} kg', style: GoogleFonts.outfit(color: color, fontSize: 20, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          ],
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
          return const Center(child: CircularProgressIndicator(color: Color(0xFFCCFF00)));
        }
        if (snap.hasError) return _buildErrorState(snap.error.toString());
        
        final suggestions = snap.data ?? [];
        if (suggestions.isEmpty) return _buildEmptyState(context);

        return RefreshIndicator(
          color: const Color(0xFFCCFF00),
          backgroundColor: const Color(0xFF1E1E1E),
          onRefresh: () async => onRefresh(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
            children: [
              _buildHistoricHeader(),
              const SizedBox(height: 24),
              ..._buildGroups(suggestions),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHistoricHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFCCFF00).withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFCCFF00).withOpacity(0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.insights_rounded, color: Color(0xFFCCFF00), size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Análise baseada no seu histórico real de performance nas últimas semanas.',
              style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
          const SizedBox(height: 16),
          Text(error, style: GoogleFonts.outfit(color: AppTheme.textSecondary)),
          TextButton(onPressed: onRefresh, child: const Text('TENTAR NOVAMENTE')),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_rounded, size: 64, color: Colors.white10),
            const SizedBox(height: 24),
            Text('Sem dados suficientes', style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            Text(
              'Complete pelo menos 2 sessões para que possamos analisar sua evolução.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
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

  String _getExplanation() {
    final coach = CoachExplainerService();
    switch (suggestion.type) {
      case ProgressionType.increaseWeight:
        return coach.explainProgression(
          reason: 'increase_load',
          deltaKg: suggestion.suggestedWeight != null && suggestion.currentWeight != null
              ? (suggestion.suggestedWeight! - suggestion.currentWeight!)
              : 2.5,
        );
      case ProgressionType.decreaseWeight:
        return coach.explainProgression(reason: 'decrease_load', consecutiveMisses: 2);
      case ProgressionType.deloadWeek:
        return coach.explainProgression(reason: 'deload', deloadWeeks: 6);
      case ProgressionType.increaseReps:
        return coach.explainProgression(reason: 'consolidate', rir: 2);
      default:
        return coach.explainProgression(reason: 'consolidate', rir: 2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ex = suggestion.exercise;
    final color = suggestion.type == ProgressionType.increaseWeight
        ? const Color(0xFFCCFF00)
        : suggestion.type == ProgressionType.deloadWeek
            ? Colors.redAccent
            : const Color(0xFF00E5FF);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(suggestion.title,
                              style: GoogleFonts.outfit(
                                  color: color,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                  letterSpacing: 1)),
                          const SizedBox(height: 4),
                          Text(ex.name.toUpperCase(),
                              style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16)),
                        ],
                      ),
                    ),
                    Icon(Icons.trending_up_rounded, color: color, size: 24),
                  ],
                ),
                const SizedBox(height: 16),
                Text(suggestion.reason,
                    style: GoogleFonts.outfit(
                        color: AppTheme.textSecondary, fontSize: 13, height: 1.4)),
                if (suggestion.suggestedWeight != null || suggestion.suggestedReps != null) ...[
                  const SizedBox(height: 20),
                  _ProgressionArrow(s: suggestion, color: color),
                ],
              ],
            ),
          ),
          // ── Coach Explainer ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withOpacity(0.15)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.psychology_rounded, color: color, size: 16),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _getExplanation(),
                      style: GoogleFonts.outfit(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildVal('ATUAL', '${showW ? s.currentWeight!.toStringAsFixed(1) : s.currentReps}', showW ? 'kg' : 'reps', Colors.white54),
          Icon(Icons.east_rounded, color: color.withOpacity(0.5), size: 20),
          _buildVal('SUGERIDO', '${showW ? s.suggestedWeight!.toStringAsFixed(1) : s.suggestedReps}', showW ? 'kg' : 'reps', color),
        ],
      ),
    );
  }

  Widget _buildVal(String label, String val, String unit, Color c) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(val, style: GoogleFonts.outfit(color: c, fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(unit, style: GoogleFonts.outfit(color: c.withOpacity(0.5), fontSize: 10, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ],
    );
  }
}
