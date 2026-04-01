import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../shared/theme/app_theme.dart';
import 'pr_model.dart';

// ─────────────────────────────────────────────
// Dialog de celebração de PR
// ─────────────────────────────────────────────

class PrCelebrationDialog extends StatelessWidget {
  final List<PrAchievement> achievements;
  final VoidCallback onDismiss;

  const PrCelebrationDialog({
    super.key,
    required this.achievements,
    required this.onDismiss,
  });

  static void show(
    BuildContext context,
    List<PrAchievement> achievements,
    VoidCallback onDismiss,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (_) => PrCelebrationDialog(
        achievements: achievements,
        onDismiss: onDismiss,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: _PrCard(achievements: achievements, onDismiss: onDismiss),
    );
  }
}

class _PrCard extends StatelessWidget {
  final List<PrAchievement> achievements;
  final VoidCallback onDismiss;

  const _PrCard({required this.achievements, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
            blurRadius: 40,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header dourado ─────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFF59E0B).withValues(alpha: 0.2),
                  const Color(0xFFEF4444).withValues(alpha: 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                // Troféu animado
                const Text('🏆', style: TextStyle(fontSize: 52))
                    .animate()
                    .scale(
                      begin: const Offset(0, 0),
                      end: const Offset(1, 1),
                      duration: 500.ms,
                      curve: Curves.elasticOut,
                    )
                    .then()
                    .shake(duration: 300.ms, hz: 3),

                const SizedBox(height: 10),

                const Text(
                  'NOVO RECORDE PESSOAL!',
                  style: TextStyle(
                    color: Color(0xFFF59E0B),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 1.5,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 300.ms, duration: 400.ms)
                    .slideY(begin: 0.3, end: 0),

                const SizedBox(height: 4),

                Text(
                  achievements.length == 1
                      ? '1 exercício com novo PR'
                      : '${achievements.length} exercícios com novo PR',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 300.ms),
              ],
            ),
          ),

          // ── Lista de PRs ────────────────────────
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                children: achievements.asMap().entries.map((e) {
                  return _PrItem(
                    achievement: e.value,
                    delay: Duration(milliseconds: 500 + e.key * 100),
                  );
                }).toList(),
              ),
            ),
          ),

          // ── Botão dismiss ───────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onDismiss,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Incrível! 💪',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            )
                .animate()
                .fadeIn(delay: 700.ms, duration: 300.ms)
                .slideY(begin: 0.5, end: 0),
          ),
        ],
      ),
    )
        .animate()
        .scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1, 1),
          duration: 400.ms,
          curve: Curves.easeOutBack,
        )
        .fadeIn(duration: 300.ms);
  }
}

class _PrItem extends StatelessWidget {
  final PrAchievement achievement;
  final Duration delay;

  const _PrItem({required this.achievement, required this.delay});

  @override
  Widget build(BuildContext context) {
    final a = achievement;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceHighlight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nome do exercício
          Row(
            children: [
              const Icon(Icons.emoji_events_rounded,
                  color: Color(0xFFF59E0B), size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  a.exerciseName,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  a.muscleGroup,
                  style: const TextStyle(
                    color: AppTheme.accent,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // PRs
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (a.hasWeightPr)
                _PrBadge(
                  label: 'Carga',
                  value: '${a.newMaxWeight!.toStringAsFixed(1)} kg',
                  prev: a.prevMaxWeight != null
                      ? 'antes: ${a.prevMaxWeight!.toStringAsFixed(1)} kg'
                      : 'primeira vez!',
                  icon: Icons.fitness_center_rounded,
                ),
              if (a.hasRepsPr)
                _PrBadge(
                  label: 'Reps',
                  value: '${a.newMaxReps!}',
                  prev: a.prevMaxReps != null
                      ? 'antes: ${a.prevMaxReps}'
                      : 'primeira vez!',
                  icon: Icons.repeat_rounded,
                ),
              if (a.hasVolumePr)
                _PrBadge(
                  label: 'Volume',
                  value: '${a.newMaxVolume!.toStringAsFixed(0)} kg',
                  prev: a.prevMaxVolume != null
                      ? 'antes: ${a.prevMaxVolume!.toStringAsFixed(0)} kg'
                      : 'primeira vez!',
                  icon: Icons.bolt_rounded,
                ),
            ],
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: delay, duration: 350.ms)
        .slideX(begin: 0.3, end: 0);
  }
}

class _PrBadge extends StatelessWidget {
  final String label;
  final String value;
  final String prev;
  final IconData icon;

  const _PrBadge({
    required this.label,
    required this.value,
    required this.prev,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFFF59E0B)),
          const SizedBox(width: 5),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$label: $value',
                style: const TextStyle(
                  color: Color(0xFFF59E0B),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              Text(
                prev,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
