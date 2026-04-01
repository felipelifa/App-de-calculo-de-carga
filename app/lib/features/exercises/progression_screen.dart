import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/theme/app_theme.dart';
import 'exercise_provider.dart';
import 'exercise_card.dart';
import 'progression_service.dart';

class ProgressionScreen extends StatefulWidget {
  const ProgressionScreen({super.key});

  @override
  State<ProgressionScreen> createState() => _ProgressionScreenState();
}

class _ProgressionScreenState extends State<ProgressionScreen> {
  Future<List<ProgressionSuggestion>>? _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final exercises = context.read<ExerciseProvider>().filteredExercises;
    final svc = ProgressionService();
    setState(() { _future = svc.generateSuggestions(exercises); });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: const Text(
          'Progressão de Carga',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.textSecondary),
            onPressed: _load,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      body: FutureBuilder<List<ProgressionSuggestion>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppTheme.accent),
                  SizedBox(height: 16),
                  Text(
                    'Analisando seu histórico…',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            );
          }

          if (snap.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: AppTheme.danger, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Erro: ${snap.error}',
                    style: const TextStyle(color: AppTheme.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextButton(onPressed: _load, child: const Text('Tentar novamente')),
                ],
              ),
            );
          }

          final suggestions = snap.data ?? [];

          if (suggestions.isEmpty) {
            return _EmptyState(onRefresh: _load);
          }

          return RefreshIndicator(
            color: AppTheme.accent,
            backgroundColor: AppTheme.surface,
            onRefresh: () async => _load(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                // Info banner
                _InfoBanner(),
                const SizedBox(height: 20),

                // Group by type
                ..._buildGroupedList(suggestions),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildGroupedList(List<ProgressionSuggestion> suggestions) {
    final groups = <ProgressionType, List<ProgressionSuggestion>>{};
    for (final s in suggestions) {
      groups.putIfAbsent(s.type, () => []).add(s);
    }

    final typeOrder = [
      ProgressionType.increaseWeight,
      ProgressionType.increaseReps,
      ProgressionType.deloadWeek,
      ProgressionType.maintain,
      ProgressionType.decreaseWeight,
    ];

    final widgets = <Widget>[];
    for (final type in typeOrder) {
      final group = groups[type];
      if (group == null || group.isEmpty) continue;

      widgets.add(_GroupHeader(type: type));
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

// ─────────────────────────────────────────────
// Group header
// ─────────────────────────────────────────────

class _GroupHeader extends StatelessWidget {
  final ProgressionType type;
  const _GroupHeader({required this.type});

  String get label {
    switch (type) {
      case ProgressionType.increaseWeight:
        return '🏋️ AUMENTAR CARGA';
      case ProgressionType.increaseReps:
        return '🔁 AUMENTAR REPETIÇÕES';
      case ProgressionType.deloadWeek:
        return '🔄 DELOAD RECOMENDADO';
      case ProgressionType.maintain:
        return '✅ MANTER RITMO';
      case ProgressionType.decreaseWeight:
        return '⬇️ REDUZIR CARGA';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AppTheme.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Suggestion card (public for reuse)
// ─────────────────────────────────────────────

class SuggestionCard extends StatelessWidget {
  final ProgressionSuggestion suggestion;

  const SuggestionCard({super.key, required this.suggestion});

  Color get _typeColor {
    switch (suggestion.type) {
      case ProgressionType.increaseWeight:
        return AppTheme.success;
      case ProgressionType.increaseReps:
        return AppTheme.accent;
      case ProgressionType.deloadWeek:
        return AppTheme.danger;
      case ProgressionType.maintain:
        return const Color(0xFF8B5CF6);
      case ProgressionType.decreaseWeight:
        return const Color(0xFFF59E0B);
    }
  }

  IconData get _typeIcon {
    switch (suggestion.type) {
      case ProgressionType.increaseWeight:
        return Icons.trending_up_rounded;
      case ProgressionType.increaseReps:
        return Icons.repeat_rounded;
      case ProgressionType.deloadWeek:
        return Icons.refresh_rounded;
      case ProgressionType.maintain:
        return Icons.check_circle_outline_rounded;
      case ProgressionType.decreaseWeight:
        return Icons.trending_down_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ex = suggestion.exercise;
    final color = _typeColor;
    final primaryMuscle = ex.primaryMuscles.isNotEmpty ? ex.primaryMuscles.first : 'Geral';
    final muscleColor_ = muscleColor(primaryMuscle);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_typeIcon, color: color, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        suggestion.title,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        ex.name,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: muscleColor_.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: muscleColor_.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    primaryMuscle,
                    style: TextStyle(
                      color: muscleColor_,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Body ───────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Reason
                Text(
                  suggestion.reason,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),

                // Current → Suggested
                if (suggestion.suggestedWeight != null || suggestion.suggestedReps != null) ...[
                  const SizedBox(height: 14),
                  _ProgressionArrow(
                    suggestion: suggestion,
                    color: color,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Progression arrow (atual → sugerido)
// ─────────────────────────────────────────────

class _ProgressionArrow extends StatelessWidget {
  final ProgressionSuggestion suggestion;
  final Color color;

  const _ProgressionArrow({required this.suggestion, required this.color});

  @override
  Widget build(BuildContext context) {
    final s = suggestion;
    final showWeight = s.currentWeight != null && s.suggestedWeight != null;
    final showReps = s.currentReps != null && s.suggestedReps != null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceHighlight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Atual
          Column(
            children: [
              const Text('ATUAL',
                  style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1)),
              const SizedBox(height: 4),
              if (showWeight)
                Text(
                  '${s.currentWeight!.toStringAsFixed(1)} kg',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              if (showReps && !showWeight)
                Text(
                  '${s.currentReps} reps',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              if (showWeight && showReps)
                Text(
                  '${s.currentReps} reps',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
            ],
          ),

          // Seta
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Icon(Icons.arrow_forward_rounded, color: color, size: 24),
          ),

          // Sugerido
          Column(
            children: [
              Text(
                'SUGERIDO',
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              if (showWeight)
                Text(
                  '${s.suggestedWeight!.toStringAsFixed(1)} kg',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              if (showReps && !showWeight)
                Text(
                  '${s.suggestedReps} reps',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              if (showWeight && showReps)
                Text(
                  '${s.suggestedReps} reps',
                  style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 12),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onRefresh;
  const _EmptyState({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.insights_rounded,
              size: 72,
              color: AppTheme.textSecondary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 24),
            const Text(
              'Sem dados suficientes',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'Complete pelo menos 2 treinos com o mesmo exercício para receber sugestões de progressão.',
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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Info banner
// ─────────────────────────────────────────────

class _InfoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome_rounded, color: AppTheme.accent, size: 18),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Sugestões baseadas no seu histórico de reps e carga. Atualize após cada treino.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
