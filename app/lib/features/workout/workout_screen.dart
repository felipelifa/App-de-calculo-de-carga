import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../shared/theme/app_theme.dart';
import '../exercises/exercise_provider.dart';
import '../exercises/exercise_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'workout_provider.dart';
import 'workout_profile_provider.dart';
import 'pr_celebration_dialog.dart';
import 'progression_provider.dart';

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
    final provider = context.read<WorkoutProvider>();
    final newPrs = provider.newPrs;
    if (newPrs.isNotEmpty && !_showingPrDialog) {
      _showingPrDialog = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        PrCelebrationDialog.show(context, newPrs, () {
          Navigator.of(context).pop();
          provider.clearNewPrs();
          _showingPrDialog = false;
        });
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
        const SnackBar(content: Text('Nenhum exercício cadastrado.')),
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
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: exercises.length,
                itemBuilder: (ctx, i) {
                  final ex = exercises[i];
                  return ListTile(
                    title: Text(
                      ex.name,
                      style: const TextStyle(color: AppTheme.textPrimary),
                    ),
                    subtitle: Text(
                      ex.primaryMuscles.isNotEmpty
                          ? ex.primaryMuscles.first
                          : 'Geral',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    onTap: () {
                      ctx.read<WorkoutProvider>().addExerciseToSession(
                        exerciseId: ex.id,
                        exerciseName: ex.name,
                        muscleGroup: ex.primaryMuscles.isNotEmpty
                            ? ex.primaryMuscles.first
                            : 'Geral',
                        defaultSeries: 3,
                        defaultReps: ex.repRangeMin,
                        defaultWeight: 20,
                        exerciseModel: ex,
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
    final profileProvider = context.read<WorkoutProfileProvider>();
    final experienceLevel =
        profileProvider.profile?.experienceLevel ?? 'beginner';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text(
          'Finalizar treino?',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: Text(
          'Volume total: ${provider.currentTotalVolume.toStringAsFixed(0)} kg\n'
          'Exercícios: ${provider.currentExercises.length}',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
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
        await provider.finishSession(experienceLevel: experienceLevel);

        // Dispara o motor de progressão no provider global
        if (context.mounted) {
          final progressionProvider = context.read<ProgressionProvider>();
          // O motor já foi acionado dentro do WorkoutProvider.finishSession
          // Apenas notifica que há novas decisões
          progressionProvider.clearDecisions();
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Treino salvo! Progressão calculada. 🚀'),
              backgroundColor: AppTheme.success,
              duration: Duration(seconds: 3),
            ),
          );
          context.go('/prescribed');
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Erro ao salvar: $e')));
        }
      }
    }
  }

  Future<void> _confirmCancel(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text(
          'Cancelar treino?',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: const Text(
          'Todo o progresso desta sessão será perdido.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Continuar treinando',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Cancelar treino',
              style: TextStyle(color: AppTheme.danger),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<WorkoutProvider>().cancelSession();
      if (context.mounted) context.go('/dashboard');
    }
  }

  void _showTutorial(BuildContext context, ExerciseModel exercise) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, sc) => SingleChildScrollView(
          controller: sc,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                exercise.name,
                style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (exercise.nameEn.isNotEmpty)
                Text(
                  exercise.nameEn,
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
              const SizedBox(height: 24),
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  width: double.infinity,
                  height: 250,
                  color: AppTheme.background,
                  child: exercise.gifUrl != null && exercise.gifUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: exercise.gifUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              const Center(child: CircularProgressIndicator()),
                          errorWidget: (_, __, ___) => const Center(
                            child: Icon(
                              Icons.video_library_rounded,
                              size: 50,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        )
                      : const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.video_library_rounded,
                                size: 48,
                                color: AppTheme.textSecondary,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Tutorial em breve',
                                style: TextStyle(color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
              if (exercise.videoUrl != null &&
                  exercise.videoUrl!.isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () async {
                      final url = Uri.parse(exercise.videoUrl!);
                      if (await canLaunchUrl(url)) {
                        await launchUrl(
                          url,
                          mode: LaunchMode.externalApplication,
                        );
                      }
                    },
                    icon: const Icon(
                      Icons.play_circle_fill,
                      color: AppTheme.accent,
                    ),
                    label: const Text(
                      'VER VÍDEO DE EXECUÇÃO',
                      style: TextStyle(
                        color: AppTheme.accent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: AppTheme.accent.withValues(alpha: 0.1),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              DefaultTabController(
                length: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TabBar(
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      indicatorColor: AppTheme.accent,
                      labelColor: AppTheme.accent,
                      unselectedLabelColor: AppTheme.textSecondary,
                      dividerColor: Colors.transparent,
                      tabs: const [
                        Tab(text: 'Instruções'),
                        Tab(text: 'Dicas'),
                        Tab(text: 'Aquecimento'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 300,
                      child: TabBarView(
                        children: [
                          // Instruções
                          ListView(
                            children: [
                              if (exercise.instructions.isEmpty)
                                const Text(
                                  'Sem instruções detalhadas no momento.',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                  ),
                                )
                              else
                                ...exercise.instructions.asMap().entries.map(
                                  (entry) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        CircleAvatar(
                                          radius: 10,
                                          backgroundColor: AppTheme.accent
                                              .withValues(alpha: 0.1),
                                          child: Text(
                                            '${entry.key + 1}',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: AppTheme.accent,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            entry.value,
                                            style: const TextStyle(
                                              color: AppTheme.textPrimary,
                                              height: 1.4,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          // Dicas (Cues)
                          ListView(
                            children: [
                              if (exercise.cues.isEmpty)
                                const Text(
                                  'Nenhuma dica extra disponível.',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                  ),
                                )
                              else
                                ...exercise.cues.map(
                                  (cue) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Icon(
                                          Icons.check_circle_outline_rounded,
                                          size: 18,
                                          color: AppTheme.success,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            cue,
                                            style: const TextStyle(
                                              color: AppTheme.textPrimary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          // Aquecimento
                          ListView(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppTheme.accent.withValues(
                                    alpha: 0.05,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppTheme.accent.withValues(
                                      alpha: 0.1,
                                    ),
                                  ),
                                ),
                                child: const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Guia de Aquecimento Específico',
                                      style: TextStyle(
                                        color: AppTheme.accent,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      '• Série 1: 12-15 reps com 40-50% da carga (Preparo articular)',
                                      style: TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontSize: 13,
                                        height: 1.5,
                                      ),
                                    ),
                                    Text(
                                      '• Série 2: 6-8 reps com 70% da carga (Ativação neuromuscular)',
                                      style: TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontSize: 13,
                                        height: 1.5,
                                      ),
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      'Dica: O aquecimento não deve gerar fadiga, apenas preparar o movimento.',
                                      style: TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () {
                                  context
                                      .read<WorkoutProvider>()
                                      .addWarmupSetForExercise(exercise.id);
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Série de aquecimento adicionada!',
                                      ),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.wb_sunny_outlined),
                                label: const Text(
                                  'ADICIONAR SÉRIE DE AQUECIMENTO',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.surfaceHighlight,
                                  foregroundColor: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('FECHAR'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (provider.isSessionActive) ...[
            TextButton(
              onPressed: () => _confirmCancel(context),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: AppTheme.danger),
              ),
            ),
            TextButton(
              onPressed: () => _confirmFinish(context),
              child: const Text(
                'Finalizar',
                style: TextStyle(
                  color: AppTheme.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.06),
          ),
        ),
      ),
      floatingActionButton: provider.isSessionActive
          ? FloatingActionButton.extended(
              onPressed: () => _showAddExerciseDialog(context),
              backgroundColor: AppTheme.accent,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Exercício',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : null,
      body: provider.isSessionActive
          ? _ActiveSession(
              timerStream: _timerStream,
              formatDuration: _formatDuration,
              onAddExercise: () => _showAddExerciseDialog(context),
              onShowTutorial: (ctx, e) => _showTutorial(ctx, e),
            )
          : _EmptyState(onStart: () => provider.startSession()),
    );
  }
}

// ── Empty state ───────────────────────────────

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
            Icon(
              Icons.fitness_center_rounded,
              size: 72,
              color: AppTheme.textSecondary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 24),
            const Text(
              'Nenhum treino em andamento',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Inicie uma sessão para registrar seus exercícios e acompanhar sua evolução.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onStart,
                icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                label: const Text(
                  'INICIAR TREINO LIVRE',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.go('/dashboard'),
              child: const Text(
                'VOLTAR PARA O INÍCIO',
                style: TextStyle(color: AppTheme.textSecondary),
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
  final Function(BuildContext, ExerciseModel) onShowTutorial;

  const _ActiveSession({
    required this.timerStream,
    required this.formatDuration,
    required this.onAddExercise,
    required this.onShowTutorial,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkoutProvider>();
    final exercises = provider.currentExercises;

    return Column(
      children: [
        // Timer + volume
        Container(
          color: AppTheme.surface,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              const Icon(
                Icons.timer_outlined,
                color: AppTheme.accent,
                size: 18,
              ),
              const SizedBox(width: 8),
              StreamBuilder<int>(
                stream: timerStream,
                builder: (_, __) => Text(
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
                'Vol: ${provider.currentTotalVolume.toStringAsFixed(0)} kg',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        // Exercícios
        Expanded(
          child: exercises.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Nenhum exercício adicionado',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
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
                    onShowTutorial: onShowTutorial,
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
  final Function(BuildContext, ExerciseModel) onShowTutorial;

  const _ExerciseCard({
    required this.exerciseIndex,
    required this.entry,
    required this.onShowTutorial,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.read<WorkoutProvider>();
    final profileProvider = context.read<WorkoutProfileProvider>();
    final restrictions = profileProvider.profile?.healthRestrictions ?? [];

    // Verifica se exercício tem restrição ativa
    final exerciseModel = context.read<ExerciseProvider>().getById(
      entry.exerciseId,
    );
    final hasInjuryConflict =
        exerciseModel != null &&
        exerciseModel.restrictions.any((r) => restrictions.contains(r));

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header do exercício
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.exerciseName,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        entry.muscleGroup,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppTheme.danger,
                    size: 20,
                  ),
                  onPressed: () =>
                      provider.removeExerciseFromSession(exerciseIndex),
                ),
              ],
            ),

            // Badge de lesão — aparece quando exercício conflita com restrições
            if (hasInjuryConflict) ...[
              const SizedBox(height: 8),
              _InjuryWarningBadge(
                exerciseModel: exerciseModel!,
                activeRestrictions: restrictions,
              ),
            ],

            const SizedBox(height: 12),

            // Cabeçalho das colunas
            const Row(
              children: [
                SizedBox(
                  width: 32,
                  child: Text(
                    'Sér.',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Reps',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Carga (kg)',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Volume',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
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
                isWarmup: set.isWarmup,
                onChanged: (reps, weight, isWarmup) => provider.updateSet(
                  exerciseIndex: exerciseIndex,
                  setIndex: si,
                  reps: reps,
                  weight: weight,
                  isWarmup: isWarmup,
                ),
                onRemove: entry.sets.length > 1
                    ? () => provider.removeSet(exerciseIndex, si)
                    : null,
              );
            }),

            const SizedBox(height: 12),

            // RIR selector + botões de ação
            _RirSelector(
              exerciseId: entry.exerciseId,
              exerciseName: entry.exerciseName,
            ),

            const Divider(height: 20, color: Colors.white10),

            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => provider.addSet(exerciseIndex),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Série'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.accent,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    if (exerciseModel != null) {
                      onShowTutorial(context, exerciseModel);
                    }
                  },
                  icon: const Icon(Icons.play_circle_outline, size: 16),
                  label: const Text('Tutorial'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.textSecondary,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── RIR Selector ─────────────────────────────

class _RirSelector extends StatelessWidget {
  final String exerciseId;
  final String exerciseName;
  const _RirSelector({required this.exerciseId, required this.exerciseName});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkoutProvider>();
    final currentRir = provider.getRirForExercise(exerciseId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            const Icon(
              Icons.speed_rounded,
              size: 14,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Intensidade (RIR): Quantas reps você ainda aguentaria fz?',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          _rirLabel(currentRir),
          style: TextStyle(
            color: _rirColor(currentRir),
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(6, (i) {
            final selected = currentRir == i;
            final color = _rirColor(i);
            return Expanded(
              child: GestureDetector(
                onTap: () => provider.setRirForExercise(exerciseId, i),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  decoration: BoxDecoration(
                    color: selected
                        ? color.withValues(alpha: 0.2)
                        : AppTheme.surfaceHighlight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selected ? color : Colors.transparent,
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Text(
                    '$i',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: selected ? color : AppTheme.textSecondary,
                      fontWeight: selected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  String _rirLabel(int rir) {
    switch (rir) {
      case 0: return 'Falha máxima (0 reps de sobra)';
      case 1: return 'Muito difícil (1 rep de sobra)';
      case 2: return 'Zona ideal de força (2 reps de sobra)';
      case 3: return 'Moderado (3 reps de sobra)';
      case 4: return 'Fácil (4 reps de sobra)';
      default: return 'Aquecimento leve (+5 reps de sobra)';
    }
  }

  Color _rirColor(int rir) {
    if (rir == 0) return AppTheme.danger;
    if (rir <= 2) return AppTheme.success;
    if (rir <= 4) return AppTheme.accent;
    return AppTheme.textSecondary;
  }
}

// ── Badge de aviso de lesão ───────────────────

class _InjuryWarningBadge extends StatelessWidget {
  final ExerciseModel exerciseModel;
  final List<String> activeRestrictions;

  const _InjuryWarningBadge({
    required this.exerciseModel,
    required this.activeRestrictions,
  });

  List<String> get _conflictingRestrictions => exerciseModel.restrictions
      .where((r) => activeRestrictions.contains(r))
      .toList();

  String _translateRestriction(String r) {
    const map = {
      'knee': 'Joelho',
      'lower_back': 'Lombar',
      'shoulder': 'Ombro',
      'wrist': 'Punho',
      'elbow': 'Cotovelo',
      'hypertension': 'Hipertensão',
      'hernia': 'Hérnia',
    };
    return map[r] ?? r;
  }

  @override
  Widget build(BuildContext context) {
    final conflicts = _conflictingRestrictions;
    if (conflicts.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 16,
            color: AppTheme.danger,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ATENÇÃO — Exercício contraindicado',
                  style: TextStyle(
                    color: AppTheme.danger,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Conflito com sua restrição de ${conflicts.map(_translateRestriction).join(", ")}. '
                  'Execute com cautela máxima ou substitua por uma variante mais segura.',
                  style: const TextStyle(
                    color: AppTheme.danger,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
                if (exerciseModel.substituteIds.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Substitutos disponíveis: ${exerciseModel.substituteIds.take(2).join(", ")}',
                    style: TextStyle(
                      color: AppTheme.danger.withValues(alpha: 0.7),
                      fontSize: 10,
                    ),
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

// ── Linha de série editável ───────────────────

class _SetRow extends StatefulWidget {
  final int setNumber;
  final int reps;
  final double weight;
  final double volume;
  final bool isWarmup;
  final void Function(int reps, double weight, bool isWarmup) onChanged;
  final VoidCallback? onRemove;

  const _SetRow({
    required this.setNumber,
    required this.reps,
    required this.weight,
    required this.volume,
    required this.isWarmup,
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
    _weightCtrl = TextEditingController(text: widget.weight.toStringAsFixed(1));
  }

  @override
  void dispose() {
    _repsCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  void _notify({bool? isWarmup}) {
    final reps = int.tryParse(_repsCtrl.text) ?? widget.reps;
    final weight = double.tryParse(_weightCtrl.text) ?? widget.weight;
    widget.onChanged(reps, weight, isWarmup ?? widget.isWarmup);
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isWarmup
        ? AppTheme.textSecondary.withValues(alpha: 0.5)
        : AppTheme.textPrimary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _notify(isWarmup: !widget.isWarmup),
            child: SizedBox(
              width: 32,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    '${widget.setNumber}',
                    style: TextStyle(
                      color: widget.isWarmup
                          ? AppTheme.accent.withValues(alpha: 0.6)
                          : AppTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (widget.isWarmup)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Icon(
                        Icons.wb_sunny_outlined,
                        size: 10,
                        color: AppTheme.accent,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _repsCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textAlign: TextAlign.center,
              style: TextStyle(color: color, fontSize: 14),
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
                isDense: true,
              ),
              onChanged: (_) => _notify(),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _weightCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textAlign: TextAlign.center,
              style: TextStyle(color: color, fontSize: 14),
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
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
              style: TextStyle(
                color: widget.isWarmup
                    ? AppTheme.success.withValues(alpha: 0.5)
                    : AppTheme.success,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          SizedBox(
            width: 36,
            child: widget.onRemove != null
                ? IconButton(
                    icon: const Icon(
                      Icons.remove_circle_outline,
                      size: 18,
                      color: AppTheme.textSecondary,
                    ),
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
