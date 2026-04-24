import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'workout_profile_model.dart';
import '../../shared/theme/app_theme.dart';

// ─────────────────────────────────────────────
// Tela de Perfil de Atleta — exibida pós-anamnese
// ─────────────────────────────────────────────

class AthleteProfileScreen extends StatelessWidget {
  final WorkoutProfile profile;
  const AthleteProfileScreen({super.key, required this.profile});

  // ── Helpers de interpretação ──────────────────

  String get _levelLabel {
    switch (profile.experienceLevel) {
      case 'advanced': return 'AVANÇADO';
      case 'intermediate': return 'INTERMEDIÁRIO';
      default: return 'INICIANTE';
    }
  }

  Color get _levelColor {
    switch (profile.experienceLevel) {
      case 'advanced': return const Color(0xFFFE2D55);
      case 'intermediate': return const Color(0xFF00E5FF);
      default: return const Color(0xFFCCFF00);
    }
  }

  String get _splitLabel {
    final days = profile.availableDaysPerWeek;
    final level = profile.experienceLevel;
    if (level == 'beginner') {
      return days <= 3 ? 'Full Body' : 'Upper / Lower';
    }
    if (level == 'intermediate') {
      if (days <= 3) return 'PPL 3 dias';
      if (days == 4) return 'Upper / Lower';
      if (days == 5) return 'PPL + Upper/Lower Híbrido';
      return 'PPL 6 dias';
    }
    if (profile.primaryGoal == 'strength') {
      return days <= 4 ? 'Upper/Lower Força' : 'PPL Força';
    }
    if (days >= 5) return 'Arnold Split';
    if (days == 4) return 'Upper / Lower';
    return 'PPL 3 dias';
  }

  String get _goalLabel {
    const map = {
      'hypertrophy': 'Hipertrofia Estética',
      'strength': 'Força Máxima',
      'fat_loss': 'Emagrecimento',
      'general_health': 'Saúde e Longevidade',
      'sport_specific': 'Treinamento Esportivo',
      'combat_sports': 'Lutas e Artes Marciais',
      'running_hybrid': 'Performance em Corrida',
      'calisthenics': 'Calistenia',
      'functional_hiit': 'Funcional / HIIT',
      'mobility_rehab': 'Mobilidade e Reabilitação',
    };
    return map[profile.primaryGoal] ?? profile.primaryGoal;
  }

  String get _deloadFrequency {
    switch (profile.experienceLevel) {
      case 'advanced': return 'A cada 8 semanas';
      case 'intermediate': return 'A cada 6 semanas';
      default: return 'A cada 4 semanas';
    }
  }

  String get _rirTarget {
    switch (profile.experienceLevel) {
      case 'advanced': return 'RIR 0-1 (próximo à falha)';
      case 'intermediate': return 'RIR 1-2 (zona de hipertrofia)';
      default: return 'RIR 3-4 (aprendizado técnico)';
    }
  }

  String get _planRationale {
    final level = profile.experienceLevel;
    final days = profile.availableDaysPerWeek;
    final goal = _goalLabel;

    if (level == 'beginner') {
      return 'Como iniciante com $days dias disponíveis, o $_splitLabel maximiza frequência por músculo e aprendizado motor, pilares do ganho inicial.';
    }
    if (level == 'intermediate') {
      return 'Com $days dias e experiência intermediária, o $_splitLabel garante volume ideal por músculo com recuperação adequada para $goal.';
    }
    return 'Atleta avançado com $days dias — o $_splitLabel permite volume máximo por grupo com DUP integrada para $goal.';
  }

  // Volumes alvo semanais (simplificado para exibição)
  Map<String, int> get _weeklyVolumes {
    final isBegin = profile.experienceLevel == 'beginner';
    final isAdv = profile.experienceLevel == 'advanced';
    return {
      'Peito': isBegin ? 10 : isAdv ? 18 : 14,
      'Costas': isBegin ? 12 : isAdv ? 20 : 16,
      'Ombro': isBegin ? 10 : isAdv ? 16 : 13,
      'Bíceps': isBegin ? 7 : isAdv ? 14 : 10,
      'Tríceps': isBegin ? 7 : isAdv ? 14 : 10,
      'Quad': isBegin ? 10 : isAdv ? 18 : 14,
      'Post/Glúteo': isBegin ? 8 : isAdv ? 16 : 12,
      'Core': isBegin ? 5 : isAdv ? 12 : 8,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── AppBar ──
            SliverAppBar(
              backgroundColor: AppTheme.background,
              floating: true,
              pinned: false,
              automaticallyImplyLeading: false,
              title: Text(
                'SEU PERFIL DE ATLETA',
                style: GoogleFonts.outfit(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              centerTitle: true,
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Badge de nível ──
                    _LevelBadge(label: _levelLabel, color: _levelColor)
                        .animate()
                        .fadeIn(duration: 600.ms)
                        .scale(begin: const Offset(0.8, 0.8)),

                    const SizedBox(height: 32),

                    // ── Diagnóstico principal ──
                    _DiagnosticCard(profile: profile, splitLabel: _splitLabel, goalLabel: _goalLabel)
                        .animate().fadeIn(duration: 500.ms, delay: 200.ms).slideY(begin: 0.1),

                    const SizedBox(height: 24),

                    // ── Parâmetros de treinamento ──
                    _ParametersCard(
                      rirTarget: _rirTarget,
                      deloadFrequency: _deloadFrequency,
                      daysPerWeek: profile.availableDaysPerWeek,
                      sessionMinutes: profile.sessionDurationMinutes,
                    ).animate().fadeIn(duration: 500.ms, delay: 300.ms).slideY(begin: 0.1),

                    const SizedBox(height: 24),

                    // ── Volume por músculo ──
                    _VolumeCard(volumes: _weeklyVolumes, levelColor: _levelColor)
                        .animate().fadeIn(duration: 500.ms, delay: 400.ms).slideY(begin: 0.1),

                    const SizedBox(height: 24),

                    // ── Por que este plano ──
                    _RationaleCard(rationale: _planRationale)
                        .animate().fadeIn(duration: 500.ms, delay: 500.ms).slideY(begin: 0.1),

                    const SizedBox(height: 32),

                    // ── CTA ──
                    _CtaButton(onTap: () => context.go('/prescribed'))
                        .animate().fadeIn(duration: 600.ms, delay: 600.ms).slideY(begin: 0.2),

                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Componentes internos
// ─────────────────────────────────────────────

class _LevelBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _LevelBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 20, spreadRadius: 4),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.emoji_events_rounded, color: color, size: 20),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Diagnóstico concluído com sucesso',
            style: GoogleFonts.outfit(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _DiagnosticCard extends StatelessWidget {
  final WorkoutProfile profile;
  final String splitLabel;
  final String goalLabel;
  const _DiagnosticCard({required this.profile, required this.splitLabel, required this.goalLabel});

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'SEU PLANO',
      icon: Icons.auto_awesome_rounded,
      children: [
        _DiagRow(
          icon: Icons.fitness_center_rounded,
          label: 'Divisão semanal',
          value: splitLabel,
          valueColor: const Color(0xFFCCFF00),
        ),
        _DiagRow(
          icon: Icons.flag_rounded,
          label: 'Objetivo',
          value: goalLabel,
        ),
        _DiagRow(
          icon: Icons.calendar_today_rounded,
          label: 'Frequência',
          value: '${profile.availableDaysPerWeek} dias / semana',
        ),
        _DiagRow(
          icon: Icons.timer_rounded,
          label: 'Duração da sessão',
          value: '${profile.sessionDurationMinutes} minutos',
        ),
        _DiagRow(
          icon: Icons.place_rounded,
          label: 'Ambiente',
          value: _envLabel(profile.environment),
        ),
      ],
    );
  }

  String _envLabel(String e) {
    const map = {
      'full_gym': 'Academia Completa',
      'basic_gym': 'Academia Básica',
      'home_dumbbell': 'Em Casa (Halteres)',
      'home_bodyweight': 'Em Casa (Peso Corporal)',
      'outdoor': 'Ao Ar Livre',
    };
    return map[e] ?? e;
  }
}

class _ParametersCard extends StatelessWidget {
  final String rirTarget;
  final String deloadFrequency;
  final int daysPerWeek;
  final int sessionMinutes;
  const _ParametersCard({
    required this.rirTarget,
    required this.deloadFrequency,
    required this.daysPerWeek,
    required this.sessionMinutes,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'PARÂMETROS DE TREINO',
      icon: Icons.tune_rounded,
      children: [
        _DiagRow(
          icon: Icons.speed_rounded,
          label: 'Intensidade alvo',
          value: rirTarget,
          valueColor: const Color(0xFFFFA500),
        ),
        _DiagRow(
          icon: Icons.refresh_rounded,
          label: 'Deload programado',
          value: deloadFrequency,
        ),
      ],
    );
  }
}

class _VolumeCard extends StatelessWidget {
  final Map<String, int> volumes;
  final Color levelColor;
  const _VolumeCard({required this.volumes, required this.levelColor});

  @override
  Widget build(BuildContext context) {
    final maxVol = volumes.values.fold(0, (a, b) => a > b ? a : b).toDouble();

    return _Card(
      title: 'VOLUME SEMANAL INICIAL',
      icon: Icons.bar_chart_rounded,
      subtitle: 'Séries por grupo muscular / semana',
      children: [
        const SizedBox(height: 8),
        ...volumes.entries.map((entry) {
          final fraction = maxVol > 0 ? entry.value / maxVol : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.key,
                      style: GoogleFonts.outfit(
                        color: AppTheme.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${entry.value} séries',
                      style: GoogleFonts.outfit(
                        color: levelColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: fraction,
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                    valueColor: AlwaysStoppedAnimation(levelColor.withValues(alpha: 0.7)),
                    minHeight: 5,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _RationaleCard extends StatelessWidget {
  final String rationale;
  const _RationaleCard({required this.rationale});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFCCFF00).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFCCFF00).withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.science_rounded, color: Color(0xFFCCFF00), size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'POR QUE ESTE PLANO?',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFCCFF00),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  rationale,
                  style: GoogleFonts.outfit(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CtaButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CtaButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFCCFF00), Color(0xFF99FF00)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFCCFF00).withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 24),
              const SizedBox(width: 12),
              Text(
                'COMEÇAR MEU PRIMEIRO TREINO',
                style: GoogleFonts.outfit(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Widgets auxiliares
// ─────────────────────────────────────────────

class _Card extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? subtitle;
  final List<Widget> children;

  const _Card({
    required this.title,
    required this.icon,
    this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFFCCFF00), size: 16),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.outfit(
                  color: AppTheme.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 26),
              child: Text(
                subtitle!,
                style: GoogleFonts.outfit(
                  color: AppTheme.textSecondary.withValues(alpha: 0.6),
                  fontSize: 11,
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }
}

class _DiagRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DiagRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textSecondary.withValues(alpha: 0.5), size: 16),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.outfit(
                color: AppTheme.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.outfit(
              color: valueColor ?? AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
