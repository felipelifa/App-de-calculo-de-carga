import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../shared/theme/app_theme.dart';
import 'workout_profile_provider.dart';
import 'prescribed_workout_model.dart';
import 'workout_provider.dart';
import 'workout_routine_model.dart';
import '../exercises/exercise_provider.dart';

// ─────────────────────────────────────────────
// Tela de Visualização do Treino Prescrito
// Exibe RIR, cadência, cues e notas de progressão
// ─────────────────────────────────────────────

class PrescribedWorkoutScreen extends StatefulWidget {
  const PrescribedWorkoutScreen({super.key});

  @override
  State<PrescribedWorkoutScreen> createState() => _PrescribedWorkoutScreenState();
}

class _PrescribedWorkoutScreenState extends State<PrescribedWorkoutScreen> {
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final wpAuth = context.read<WorkoutProfileProvider>();
    final exerciseProvider = context.read<ExerciseProvider>();
    
    // Se o treino não estiver na memória, tenta carregar do Firestore antes de desistir
    if (wpAuth.currentWorkout == null) {
      await wpAuth.loadCurrentWorkout(exerciseProvider.getById);
    }
    
    if (mounted) {
      setState(() { _isChecking = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final wpAuth = context.watch<WorkoutProfileProvider>();

    if (wpAuth.isLoading || _isChecking) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(child: CircularProgressIndicator(color: AppTheme.accent)),
      );
    }

    final workout = wpAuth.currentWorkout;
    if (workout == null) {
      // Somente redireciona após ter certeza absoluta que o workout não existe no banco
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          backgroundColor: AppTheme.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textSecondary),
            onPressed: () => context.go('/dashboard'),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.fitness_center_rounded, size: 64, color: AppTheme.textSecondary),
              const SizedBox(height: 24),
              const Text('Nenhum treino gerado ainda.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 18)),
              const SizedBox(height: 8),
              const Text('Responda a anamnese para criar seu plano.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => context.go('/anamnese'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                ),
                child: const Text('GERAR MEU TREINO'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go('/dashboard'),
                child: const Text('VOLTAR PARA O INÍCIO', 
                    style: TextStyle(color: AppTheme.textSecondary)),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Meu Plano de Treino',
            style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textSecondary),
          onPressed: () => context.go('/dashboard'),
          tooltip: 'Página Inicial',
        ),
        backgroundColor: AppTheme.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                color: Colors.redAccent),
            tooltip: 'Excluir Treino',
            onPressed: () => _confirmDeletion(context),
          )
        ],
      ),
      body: CustomScrollView(
        slivers: [
          _buildHeader(context, workout),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final session = workout.sessions[index];
                  return _SessionCard(session: session);
                },
                childCount: workout.sessions.length,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 60),
              child: TextButton.icon(
                onPressed: () => _confirmDeletion(context),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('LIMPAR TREINO E REFAZER ANAMNESE'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.redAccent.withValues(alpha: 0.8),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeletion(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Excluir Treino?',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text(
          'Isso apagará o mesociclo atual. Você pode refazer a anamnese e gerar um novo treino quando quiser.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            child: const Text('CANCELAR',
                style: TextStyle(color: AppTheme.textSecondary)),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(context);
              await context.read<WorkoutProfileProvider>().deleteCurrentWorkout();
              context.go('/anamnese');
            },
            child: const Text('EXCLUIR',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, GeneratedWorkout workout) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.surfaceHighlight.withValues(alpha: 0.1),
          border: Border(
              bottom:
                  BorderSide(color: Colors.white.withValues(alpha: 0.05))),
        ),
        child: Column(
          children: [
            const Icon(Icons.auto_awesome_rounded,
                size: 48, color: AppTheme.accent),
            const SizedBox(height: 16),
            const Text(
              'Mesociclo Científico',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '${workout.mesocycleDurationWeeks} semanas  •  ${_formatPeriodization(workout.periodizationModel)}  •  ${_formatSplit(workout.splitType)}',
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            // Badge de periodização
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppTheme.accent.withValues(alpha: 0.3)),
              ),
              child: Text(
                _periodizationExplainer(workout.periodizationModel),
                style: const TextStyle(
                    color: AppTheme.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPeriodization(String p) {
    switch (p) {
      case 'linear':
        return 'Linear';
      case 'dup':
        return 'Ondulatória Diária (DUP)';
      case 'block':
        return 'Em Bloco';
      default:
        return p.toUpperCase();
    }
  }

  String _formatSplit(String s) {
    switch (s) {
      case 'full_body':
        return 'Full Body';
      case 'upper_lower':
        return 'Superior/Inferior';
      case 'ppl_3days':
      case 'ppl_5days':
      case 'ppl_6days':
        return 'Push/Pull/Legs';
      default:
        return s;
    }
  }

  String _periodizationExplainer(String p) {
    switch (p) {
      case 'linear':
        return 'Foco: Aumentar o peso um pouquinho toda semana';
      case 'dup':
        return 'Foco: Variar entre carga pesada e mais repetições';
      case 'block':
        return 'Foco: Fases de força e fases de definição';
      default:
        return p;
    }
  }
}

// ─────────────────────────────────────────────
// Card de Sessão
// ─────────────────────────────────────────────

class _SessionCard extends StatefulWidget {
  final PrescribedSession session;
  const _SessionCard({required this.session});

  @override
  State<_SessionCard> createState() => _SessionCardState();
}

class _SessionCardState extends State<_SessionCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.05), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          _buildCardHeader(),
          // Progressão note
          _buildProgressionNote(),
          // Exercícios
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: _expanded
                ? _buildExercisesList()
                : const SizedBox.shrink(),
          ),
          // Botões
          _buildButtons(context),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildCardHeader() {
    return InkWell(
      onTap: () => setState(() => _expanded = !_expanded),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceHighlight.withValues(alpha: 0.05),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.session.name,
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${widget.session.estimatedDurationMinutes} min',
                    style: const TextStyle(
                        color: AppTheme.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: AppTheme.textSecondary,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              widget.session.objective,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            // Mini lista de exercícios (sempre visível)
            Text(
              '${widget.session.exercises.length} exercícios  •  ${_countCompostos()} compostos',
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  int _countCompostos() => widget.session.exercises
      .where((e) => e.exercise.category == 'compound')
      .length;

  Widget _buildProgressionNote() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.accent.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: AppTheme.accent.withValues(alpha: 0.2), width: 1),
        ),
        child: Row(
          children: [
            const Icon(Icons.trending_up_rounded,
                size: 16, color: AppTheme.accent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.session.progressionNote,
                style: const TextStyle(
                    color: AppTheme.accent, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExercisesList() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Column(
        children: [
          // Aquecimento
          _buildWarmupBlock(),
          const SizedBox(height: 12),
          // Exercícios
          ...widget.session.exercises.map((ex) => _ExerciseRow(ex: ex)),
        ],
      ),
    );
  }

  Widget _buildWarmupBlock() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: Colors.orange.withValues(alpha: 0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.local_fire_department_rounded,
                  size: 14, color: Colors.orange),
              SizedBox(width: 6),
              Text('AQUECIMENTO',
                  style: TextStyle(
                      color: Colors.orange,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 8),
          ...widget.session.warmupInstructions.map((w) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ',
                        style: TextStyle(
                            color: Colors.orange, fontSize: 12)),
                    Expanded(
                      child: Text(w,
                          style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: ElevatedButton.icon(
        onPressed: () => _startSession(context),
        icon: const Icon(Icons.play_circle_fill_rounded),
        label: const Text('INICIAR ESTE TREINO'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.accent,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  void _startSession(BuildContext context) {
    final wp = context.read<WorkoutProvider>();
    final profileProvider = context.read<WorkoutProfileProvider>();

    // Sobrepõe os dados estáticos com as cargas calculadas pela progressão
    final prescribedData = widget.session.exercises.map((e) {
      final map = e.toMap();
      final latestWeight = profileProvider.getLatestWeightForExercise(e.exercise.id);
      
      // Se tivermos carga na progressão, ela vira o novo default
      if (latestWeight > 0) {
        map['defaultWeightKg'] = latestWeight;
      }
      return map;
    }).toList();

    wp.startSessionFromPrescribed(
      sessionId: widget.session.id,
      sessionName: widget.session.name,
      prescribedExercises: prescribedData,
    );

    context.go('/workout');
  }
}

// ─────────────────────────────────────────────
// Linha de Exercício com detalhes completos
// ─────────────────────────────────────────────

class _ExerciseRow extends StatefulWidget {
  final PrescribedExercise ex;
  const _ExerciseRow({required this.ex});

  @override
  State<_ExerciseRow> createState() => _ExerciseRowState();
}

class _ExerciseRowState extends State<_ExerciseRow> {
  bool _showCues = false;

  Color get _categoryColor {
    return widget.ex.exercise.category == 'compound'
        ? AppTheme.accent
        : AppTheme.success;
  }

  String get _categoryLabel {
    return widget.ex.exercise.category == 'compound' ? 'COMPOSTO' : 'ISOLADOR';
  }

  @override
  Widget build(BuildContext context) {
    final ex = widget.ex;
    final profileProvider = context.watch<WorkoutProfileProvider>();
    final suggestedWeight = (profileProvider.getLatestWeightForExercise(ex.exercise.id) as num?)?.toDouble() ?? 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: _categoryColor.withValues(alpha: 0.15), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nome + badge
            Row(
              children: [
                Expanded(
                  child: Text(
                    ex.exercise.name,
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _categoryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _categoryLabel,
                    style: TextStyle(
                        color: _categoryColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            
            // Alerta de Lesão/Segurança
            if (ex.injuryNote != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.danger.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.danger.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 14, color: AppTheme.danger),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        ex.injuryNote!,
                        style: const TextStyle(
                          color: AppTheme.danger,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 10),
            // Métricas em linha
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _MetricChip(
                    icon: Icons.layers_rounded,
                    label: '${ex.sets} séries'),
                _MetricChip(
                    icon: Icons.repeat_rounded,
                    label: '${ex.repsMin}–${ex.repsMax} reps'),
                _MetricChip(
                    icon: Icons.timer_outlined,
                    label: '${ex.restSeconds}s descanso'),
                if (suggestedWeight > 0)
                  _MetricChip(
                      icon: Icons.fitness_center_rounded,
                      label: '${suggestedWeight.toStringAsFixed(1)} kg',
                      highlight: true),
                _MetricChip(
                    icon: Icons.speed_rounded,
                    label: _friendlyRir(ex.rir),
                    highlight: true),
                _MetricChip(
                    icon: Icons.av_timer_rounded,
                    label: ex.tempo),
              ],
            ),
            // Cues expansíveis
            if (ex.sessionCues.isNotEmpty) ...[
              const SizedBox(height: 8),
              InkWell(
                onTap: () => setState(() => _showCues = !_showCues),
                child: Row(
                  children: [
                    Icon(
                      _showCues
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.lightbulb_outline_rounded,
                      size: 14,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _showCues ? 'Ocultar dicas' : 'Ver dicas técnicas',
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (_showCues) ...[
                const SizedBox(height: 8),
                ...ex.sessionCues.map((cue) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('→ ',
                              style: TextStyle(
                                  color: AppTheme.accent, fontSize: 12)),
                          Expanded(
                            child: Text(cue,
                                style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12)),
                          ),
                        ],
                      ),
                    )),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool highlight;

  const _MetricChip({
    required this.icon,
    required this.label,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = highlight ? AppTheme.accent : AppTheme.textSecondary;
    final bg = highlight
        ? AppTheme.accent.withValues(alpha: 0.12)
        : AppTheme.surfaceHighlight.withValues(alpha: 0.3);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Helpers de Idioma e Simplicidade
// ─────────────────────────────────────────────

String _translateMuscle(String m) {
  final map = {
    'chest': 'Peitoral',
    'back': 'Costas',
    'shoulders': 'Ombros',
    'side_delt': 'Ombro Lateral',
    'rear_delt': 'Ombro Posterior',
    'biceps': 'Bíceps',
    'triceps': 'Tríceps',
    'quads': 'Coxa (Frente)',
    'hamstrings': 'Coxa (Atrás)',
    'glutes': 'Glúteos',
    'calves': 'Panturrilha',
    'abs': 'Abdômen',
    'core': 'Abdominal',
  };
  return map[m.toLowerCase()] ?? m;
}

String _friendlyRir(int rir) {
  if (rir <= 0) return 'Até o limite (Difícil)';
  if (rir == 1) return 'Quase no limite';
  if (rir == 2) return 'Esforço intenso';
  if (rir == 3) return 'Carga moderada';
  return 'Carga leve';
}
