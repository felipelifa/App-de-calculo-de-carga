import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../shared/theme/app_theme.dart';
import 'workout_profile_provider.dart';
import 'prescribed_workout_model.dart';
import 'workout_provider.dart';
import '../../core/services/coach_explainer_service.dart';

// ─────────────────────────────────────────────
// DeloadScreen
// Tela dedicada ao treino de deload semanal
// Baseado nos protocolos NSCA/Bompa
// ─────────────────────────────────────────────

class DeloadScreen extends StatefulWidget {
  const DeloadScreen({super.key});

  @override
  State<DeloadScreen> createState() => _DeloadScreenState();
}

class _DeloadScreenState extends State<DeloadScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  /// Gera o plano de deload com base no último treino prescrito
  List<_DeloadExercise> _buildDeloadPlan(GeneratedWorkout? workout) {
    if (workout == null || workout.sessions.isEmpty) return _defaultDeloadPlan();

    // Pega o primeiro treino do plano ativo como referência
    final session = workout.sessions.first;

    // Filtra exercícios de alto spinal load (Terra, Agachamento pesado)
    final highSpinalIds = {
      'terra', 'deadlift', 'agachamento_livre', 'agachamento_barra',
      'levantamento_terra', 'back_squat', 'squat',
    };

    final deloadExercises = <_DeloadExercise>[];
    for (final pe in session.exercises) {
      final id = pe.exercise.id.toLowerCase();
      final name = pe.exercise.name;

      // Substitui exercícios de alto spinal load por variações mais leves
      if (highSpinalIds.any((key) => id.contains(key))) {
        deloadExercises.add(_DeloadExercise(
          name: 'Agachamento no Goblet (Deload)',
          sets: (pe.sets * 0.5).ceil().clamp(1, 3),
          reps: '12-15',
          loadPercent: 40,
          note: 'Substituto de baixa carga espinhal — foco em técnica e ROM.',
        ));
      } else {
        deloadExercises.add(_DeloadExercise(
          name: name,
          sets: (pe.sets * 0.5).ceil().clamp(1, 3),
          reps: '12-15',
          loadPercent: 60,
          note: 'RIR alvo: 4-5. Longe da falha. Cadência 3-1-3.',
        ));
      }
    }

    return deloadExercises.take(5).toList();
  }

  List<_DeloadExercise> _defaultDeloadPlan() => [
    _DeloadExercise(name: 'Agachamento Goblet', sets: 2, reps: '12-15', loadPercent: 40, note: 'Foco em mobilidade e técnica.'),
    _DeloadExercise(name: 'Supino Inclinado Haltere', sets: 2, reps: '12-15', loadPercent: 60, note: 'Cadência lenta: 3-1-3.'),
    _DeloadExercise(name: 'Remada Unilateral', sets: 2, reps: '12-15', loadPercent: 60, note: 'ROM completa, sem compensação.'),
    _DeloadExercise(name: 'Desenvolvimento Haltere', sets: 2, reps: '12-15', loadPercent: 60, note: 'Foco em mobilidade de ombro.'),
    _DeloadExercise(name: 'Prancha Isométrica', sets: 2, reps: '30s', loadPercent: 0, note: 'Ativação de core — sem carga adicional.'),
  ];

  void _completeDeload() {
    HapticFeedback.heavyImpact();
    setState(() => _completed = true);
  }

  @override
  Widget build(BuildContext context) {
    final wp = context.watch<WorkoutProfileProvider>();
    final activeWorkout = wp.activeWorkout;
    final deloadPlan = _buildDeloadPlan(activeWorkout);
    final coach = CoachExplainerService();
    final weeksTraining = activeWorkout != null ? (activeWorkout.mesocycleDurationWeeks) : 6;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: _completed ? _buildCompletionScreen(context) : _buildDeloadBody(context, deloadPlan, coach, weeksTraining),
    );
  }

  Widget _buildDeloadBody(
    BuildContext context,
    List<_DeloadExercise> plan,
    CoachExplainerService coach,
    int weeks,
  ) {
    return CustomScrollView(
      slivers: [
        // ── AppBar ──
        SliverAppBar(
          backgroundColor: Colors.transparent,
          floating: true,
          pinned: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Colors.white),
            onPressed: () => context.go('/dashboard'),
          ),
          title: Text(
            'SEMANA DE DELOAD',
            style: GoogleFonts.outfit(
              color: const Color(0xFFFF6B6B),
              fontSize: 13,
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
                // ── Banner de deload ──
                _DeloadBannerWidget(
                  explanation: coach.explainActiveDeload(weeks),
                ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.1),

                const SizedBox(height: 32),

                // ── Parâmetros da sessão ──
                _ParametersRow()
                    .animate().fadeIn(duration: 500.ms, delay: 200.ms),

                const SizedBox(height: 32),

                // ── Título ──
                Row(
                  children: [
                    Container(width: 3, height: 16, decoration: BoxDecoration(color: const Color(0xFFFF6B6B), borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 10),
                    Text(
                      'EXERCÍCIOS DO DELOAD',
                      style: GoogleFonts.outfit(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: 500.ms, delay: 300.ms),

                const SizedBox(height: 16),

                // ── Lista de exercícios ──
                ...plan.asMap().entries.map((entry) {
                  return _DeloadExerciseCard(exercise: entry.value)
                      .animate()
                      .fadeIn(duration: 500.ms, delay: (300 + entry.key * 80).ms)
                      .slideY(begin: 0.1);
                }),

                const SizedBox(height: 32),

                // ── Botão concluir ──
                _CompleteButton(onTap: _completeDeload)
                    .animate().fadeIn(duration: 600.ms, delay: 600.ms),

                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompletionScreen(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── Ícone de celebração ──
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFFCCFF00).withValues(alpha: 0.1),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFCCFF00).withValues(alpha: 0.3),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: const Icon(Icons.bolt_rounded, color: Color(0xFFCCFF00), size: 64),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.05, 1.05), duration: 1200.ms),

            const SizedBox(height: 40),

            Text(
              'RECUPERAÇÃO CONCLUÍDA',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: const Color(0xFFCCFF00),
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
              ),
            ).animate().fadeIn(delay: 300.ms),

            const SizedBox(height: 16),

            Text(
              'Deload feito. 💪',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w900,
              ),
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),

            const SizedBox(height: 20),

            Text(
              'Próxima semana você vai superar seus recordes.\nO descanso é parte do treino — não é fraqueza.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: AppTheme.textSecondary,
                fontSize: 15,
                height: 1.6,
              ),
            ).animate().fadeIn(delay: 500.ms),

            const SizedBox(height: 48),

            GestureDetector(
              onTap: () => context.go('/dashboard'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFCCFF00), Color(0xFF99FF00)]),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFCCFF00).withValues(alpha: 0.4),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Text(
                  'VOLTAR AO INÍCIO',
                  style: GoogleFonts.outfit(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 700.ms).scale(begin: const Offset(0.9, 0.9)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Componentes internos
// ─────────────────────────────────────────────

class _DeloadBannerWidget extends StatelessWidget {
  final String explanation;
  const _DeloadBannerWidget({required this.explanation});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFF6B6B).withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFF6B6B).withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B6B).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.refresh_rounded, color: Color(0xFFFF6B6B), size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'POR QUE DELOAD?',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFFFF6B6B),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Protocolo científico NSCA/Bompa',
                      style: GoogleFonts.outfit(
                        color: AppTheme.textSecondary.withValues(alpha: 0.6),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            explanation,
            style: GoogleFonts.outfit(
              color: AppTheme.textPrimary,
              fontSize: 13,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _ParametersRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _ParamItem(label: 'VOLUME', value: '-50%', icon: Icons.compress_rounded, color: const Color(0xFFFF6B6B)),
          _ParamItem(label: 'CARGA', value: '-40%', icon: Icons.speed_rounded, color: const Color(0xFFFFA500)),
          _ParamItem(label: 'RIR ALVO', value: '4-5', icon: Icons.battery_full_rounded, color: const Color(0xFF00E5FF)),
          _ParamItem(label: 'DESCANSO', value: '60-90s', icon: Icons.timer_rounded, color: const Color(0xFFCCFF00)),
        ],
      ),
    );
  }
}

class _ParamItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _ParamItem({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.outfit(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.outfit(
            color: AppTheme.textSecondary,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

class _DeloadExerciseCard extends StatelessWidget {
  final _DeloadExercise exercise;
  const _DeloadExerciseCard({required this.exercise});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Ícone de sets
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B6B).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.fitness_center_rounded, color: Color(0xFFFF6B6B), size: 16),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  exercise.name,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _ExerciseParam(label: 'SÉRIES', value: '${exercise.sets}x'),
              const SizedBox(width: 20),
              _ExerciseParam(label: 'REPS', value: exercise.reps),
              const SizedBox(width: 20),
              if (exercise.loadPercent > 0)
                _ExerciseParam(
                  label: 'CARGA',
                  value: '${exercise.loadPercent}%',
                  color: const Color(0xFFFFA500),
                )
              else
                _ExerciseParam(label: 'CARGA', value: 'Peso corporal', color: const Color(0xFF00E5FF)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 12, color: Color(0xFFCCFF00)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    exercise.note,
                    style: GoogleFonts.outfit(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                      height: 1.4,
                    ),
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

class _ExerciseParam extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _ExerciseParam({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            color: AppTheme.textSecondary.withValues(alpha: 0.6),
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.outfit(
            color: color ?? Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _CompleteButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CompleteButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)]),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF6B6B).withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
              const SizedBox(width: 12),
              Text(
                'CONCLUIR DELOAD',
                style: GoogleFonts.outfit(
                  color: Colors.white,
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
// Modelo de exercício de deload
// ─────────────────────────────────────────────

class _DeloadExercise {
  final String name;
  final int sets;
  final String reps;
  final int loadPercent; // % do último peso registrado; 0 = peso corporal
  final String note;

  const _DeloadExercise({
    required this.name,
    required this.sets,
    required this.reps,
    required this.loadPercent,
    required this.note,
  });
}
