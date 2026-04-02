import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../shared/theme/app_theme.dart';
import '../exercises/exercise_provider.dart';
import 'workout_provider.dart';
import 'pr_celebration_dialog.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  late final Stream<int> _timerStream;
  bool _showingPrDialog = false;

  @override
  void initState() {
    super.initState();
    _timerStream = Stream.periodic(const Duration(seconds: 1), (tick) => tick);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Escuta novos PRs e mostra o dialog de celebração
    final provider = context.read<WorkoutProvider>();
    final newPrs = provider.newPrs;
    if (newPrs.isNotEmpty && !_showingPrDialog) {
      _showingPrDialog = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        PrCelebrationDialog.show(
          context,
          newPrs,
          () {
            Navigator.of(context).pop();
            provider.clearNewPrs();
            _showingPrDialog = false;
          },
        );
      });
    }
  }

  String _formatDuration(DateTime start) {
    final diff = DateTime.now().difference(start);
    final h = diff.inHours.toString().padLeft(2, '0');
    final m = (diff.inMinutes % 60).toString().padLeft(2, '0');
    final s = (diff.inSeconds % 60).toString().padLeft(2, '0');
    return diff.inHours > 0 ? '$h:$m:$s' : '$m:$s';
  }

  Future<void> _showAddExerciseDialog(BuildContext context) async {
    final exercises = context.read<ExerciseProvider>().filteredExercises;
    if (exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Nenhum exercício cadastrado. Cadastre um primeiro.')),
      );
      return;
    }

    await showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (_, scrollController) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textSecondary.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Escolha o exercício',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: exercises.length,
                itemBuilder: (ctx, i) {
                  final ex = exercises[i];
                  return ListTile(
                    title: Text(ex.name,
                        style:
                            const TextStyle(color: AppTheme.textPrimary)),
                    subtitle: Text(ex.primaryMuscles.isNotEmpty ? ex.primaryMuscles.first : 'Geral',
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12)),
                    onTap: () {
                      ctx.read<WorkoutProvider>().addExerciseToSession(
                            exerciseId: ex.id,
                            exerciseName: ex.name,
                            muscleGroup: ex.primaryMuscles.isNotEmpty ? ex.primaryMuscles.first : 'Geral',
                            defaultSeries: 3,
                            defaultReps: ex.repRangeMin,
                            defaultWeight: 20,
                          );
                      Navigator.pop(ctx);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmFinish(BuildContext context) async {
    final provider = context.read<WorkoutProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Finalizar treino?',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: Text(
          'Volume total: ${provider.currentTotalVolume.toStringAsFixed(0)} kg\n'
          'Exercícios: ${provider.currentExercises.length}',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await provider.finishSession();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Treino salvo! Cargas recalculadas com sucesso! 🚀'),
              backgroundColor: AppTheme.success,
            ),
          );
          // Volta para a tela de plano (prescribed)
          Navigator.pop(context);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao salvar: $e')),
          );
        }
      }
    }
  }

  Future<void> _confirmCancel(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Cancelar treino?',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text(
          'Todo o progresso desta sessão será perdido.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continuar treinando',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancelar treino',
                style: TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<WorkoutProvider>().cancelSession();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkoutProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: const Text(
          'Treino',
          style: TextStyle(
              color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (provider.isSessionActive) ...[
            TextButton(
              onPressed: () => _confirmCancel(context),
              child: const Text('Cancelar',
                  style: TextStyle(color: AppTheme.danger)),
            ),
            TextButton(
              onPressed: () => _confirmFinish(context),
              child: const Text('Finalizar',
                  style: TextStyle(
                      color: AppTheme.accent, fontWeight: FontWeight.w600)),
            ),
          ],
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
              height: 1, color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      floatingActionButton: provider.isSessionActive
          ? FloatingActionButton.extended(
              onPressed: () => _showAddExerciseDialog(context),
              backgroundColor: AppTheme.accent,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Exercício',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            )
          : null,
      body: provider.isSessionActive
          ? _ActiveSession(
              timerStream: _timerStream,
              formatDuration: _formatDuration,
              onAddExercise: () => _showAddExerciseDialog(context),
            )
          : _EmptyState(onStart: () => provider.startSession()),
    );
  }
}

// ── Tela vazia ────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onStart;
  const _EmptyState({required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.fitness_center_rounded,
                size: 72,
                color: AppTheme.textSecondary.withValues(alpha: 0.4)),
            const SizedBox(height: 24),
            const Text(
              'Nenhum treino em andamento',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Inicie uma sessão para registrar seus exercícios e acompanhar sua evolução.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onStart,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Iniciar treino'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sessão ativa ──────────────────────────────

class _ActiveSession extends StatelessWidget {
  final Stream<int> timerStream;
  final String Function(DateTime) formatDuration;
  final VoidCallback onAddExercise;

  const _ActiveSession({
    required this.timerStream,
    required this.formatDuration,
    required this.onAddExercise,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkoutProvider>();
    final exercises = provider.currentExercises;

    return Column(
      children: [
        // Timer banner
        Container(
          color: AppTheme.surface,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.timer_outlined, color: AppTheme.accent, size: 18),
              const SizedBox(width: 8),
              StreamBuilder<int>(
                stream: timerStream,
                builder: (_, _) => Text(
                  formatDuration(provider.sessionStart!),
                  style: const TextStyle(
                    color: AppTheme.accent,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'Volume: ${provider.currentTotalVolume.toStringAsFixed(0)} kg',
                style:
                    const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),

        // Lista de exercícios
        Expanded(
          child: exercises.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Nenhum exercício adicionado',
                          style: TextStyle(color: AppTheme.textSecondary)),
                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: onAddExercise,
                        icon: const Icon(Icons.add),
                        label: const Text('Adicionar exercício'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 100),
                  itemCount: exercises.length,
                  itemBuilder: (_, i) => _ExerciseCard(
                    exerciseIndex: i,
                    entry: exercises[i],
                  ),
                ),
        ),
      ],
    );
  }
}

// ── Card de exercício ─────────────────────────

class _ExerciseCard extends StatelessWidget {
  final int exerciseIndex;
  final dynamic entry;

  const _ExerciseCard({required this.exerciseIndex, required this.entry});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<WorkoutProvider>();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.exerciseName,
                          style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 15)),
                      if (entry.injuryNote != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded, size: 12, color: AppTheme.danger),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(entry.injuryNote!,
                                    style: const TextStyle(
                                        color: AppTheme.danger,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                      Text(entry.muscleGroup,
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: AppTheme.danger, size: 20),
                  onPressed: () =>
                      provider.removeExerciseFromSession(exerciseIndex),
                ),
              ],
            ),

            const SizedBox(height: 12),

            const Row(
              children: [
                SizedBox(
                    width: 32,
                    child: Text('Série',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 11))),
                SizedBox(width: 8),
                Expanded(
                    child: Text('Reps',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 11),
                        textAlign: TextAlign.center)),
                SizedBox(width: 8),
                Expanded(
                    child: Text('Carga (kg)',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 11),
                        textAlign: TextAlign.center)),
                SizedBox(width: 8),
                Expanded(
                    child: Text('Volume',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 11),
                        textAlign: TextAlign.center)),
                SizedBox(width: 36),
              ],
            ),

            const SizedBox(height: 8),

            ...List.generate(entry.sets.length, (si) {
              final set = entry.sets[si];
              return _SetRow(
                setNumber: si + 1,
                reps: set.reps,
                weight: set.weight,
                volume: set.volume,
                onChanged: (reps, weight) => provider.updateSet(
                  exerciseIndex: exerciseIndex,
                  setIndex: si,
                  reps: reps,
                  weight: weight,
                ),
                onRemove: entry.sets.length > 1
                    ? () => provider.removeSet(exerciseIndex, si)
                    : null,
              );
            }),

            const SizedBox(height: 8),

            TextButton.icon(
              onPressed: () => provider.addSet(exerciseIndex),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Adicionar série'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.accent,
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Linha de série editável ───────────────────

class _SetRow extends StatefulWidget {
  final int setNumber;
  final int reps;
  final double weight;
  final double volume;
  final void Function(int reps, double weight) onChanged;
  final VoidCallback? onRemove;

  const _SetRow({
    required this.setNumber,
    required this.reps,
    required this.weight,
    required this.volume,
    required this.onChanged,
    this.onRemove,
  });

  @override
  State<_SetRow> createState() => _SetRowState();
}

class _SetRowState extends State<_SetRow> {
  late final TextEditingController _repsCtrl;
  late final TextEditingController _weightCtrl;

  @override
  void initState() {
    super.initState();
    _repsCtrl = TextEditingController(text: widget.reps.toString());
    _weightCtrl =
        TextEditingController(text: widget.weight.toStringAsFixed(1));
  }

  @override
  void dispose() {
    _repsCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  void _notify() {
    final reps = int.tryParse(_repsCtrl.text) ?? widget.reps;
    final weight = double.tryParse(_weightCtrl.text) ?? widget.weight;
    widget.onChanged(reps, weight);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text('${widget.setNumber}',
                style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _repsCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppTheme.textPrimary, fontSize: 14),
              decoration: const InputDecoration(
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                isDense: true,
              ),
              onChanged: (_) => _notify(),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _weightCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppTheme.textPrimary, fontSize: 14),
              decoration: const InputDecoration(
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                isDense: true,
              ),
              onChanged: (_) => _notify(),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.volume.toStringAsFixed(0),
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppTheme.success,
                  fontWeight: FontWeight.w600,
                  fontSize: 14),
            ),
          ),
          SizedBox(
            width: 36,
            child: widget.onRemove != null
                ? IconButton(
                    icon: const Icon(Icons.remove_circle_outline,
                        size: 18, color: AppTheme.textSecondary),
                    onPressed: widget.onRemove,
                    padding: EdgeInsets.zero,
                  )
                : const SizedBox(),
          ),
        ],
      ),
    );
  }
}
