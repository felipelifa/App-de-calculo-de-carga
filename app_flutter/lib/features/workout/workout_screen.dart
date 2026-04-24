import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../shared/theme/app_theme.dart';
import '../exercises/exercise_provider.dart';
import '../exercises/exercise_model.dart';
// cached_network_image removido: não suporta GIF animado.
// Usando Image.network nativo do Flutter (suporta GIF no Android, iOS e Web).
import 'workout_provider.dart';
import 'workout_profile_provider.dart';
import 'pr_celebration_dialog.dart';
import 'progression_provider.dart';
import '../nutrition/nutrition_provider.dart';

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
              'CONTINUAR',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('SALVAR TREINO'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        // Obter métricas da sessão antes de finalizar para notificar nutrição
        final durationMinutes = provider.sessionStart != null 
            ? DateTime.now().difference(provider.sessionStart!).inMinutes 
            : 60;
        final exCount = provider.currentExercises.length;
        final vol = provider.currentTotalVolume;

        await provider.finishSession(experienceLevel: experienceLevel);

        if (context.mounted) {
          // Notifica o NutritionProvider sobre o treino concluído
          context.read<NutritionProvider>().applyPostWorkoutBonus(
            sessionName: provider.activeSessionName ?? 'Treino',
            durationMinutes: durationMinutes,
            exerciseCount: exCount,
            totalVolume: vol,
          );
        }

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
              Builder(
                builder: (context) {
                  final url = context.read<ExerciseProvider>().getEffectiveGifUrl(exercise);
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Container(
                      width: double.infinity,
                      height: 320,
                      color: AppTheme.background,
                      child: url == null || url.isEmpty
                          ? _buildNoGifPlaceholder()
                          : _AnimatedGifWidget(
                              url: url,
                              onError: () => debugPrint('Erro ao carregar GIF: $url'),
                            ),
                    ),
                  );
                },
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
        backgroundColor: AppTheme.background,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Sessão Ativa',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 24,
          ),
        ),
        actions: [
          if (provider.isSessionActive) ...[
            TextButton(
              onPressed: () => _confirmCancel(context),
              child: Text(
                'CANCELAR',
                style: GoogleFonts.outfit(color: Colors.redAccent, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1),
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: ElevatedButton(
                onPressed: () => _confirmFinish(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFCCFF00),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  'FINALIZAR',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1),
                ),
              ),
            ),
          ],
        ],
      ),
      floatingActionButton: provider.isSessionActive
          ? FloatingActionButton.extended(
              onPressed: () => _showAddExerciseDialog(context),
              backgroundColor: const Color(0xFFCCFF00),
              icon: const Icon(Icons.add_rounded, color: Colors.black),
              label: Text(
                'EXERCÍCIO',
                style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.w900, letterSpacing: 1),
              ),
            ).animate().scale(delay: 400.ms, curve: Curves.easeOutBack)
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
  Widget _buildNoGifPlaceholder({bool isError = false}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.video_library_rounded,
            size: 48,
            color: isError ? AppTheme.danger.withValues(alpha: 0.5) : AppTheme.textSecondary,
          ),
          const SizedBox(height: 12),
          Text(
            isError ? 'Erro ao carregar animação' : 'Tutorial em vídeo sendo processado',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
              fontStyle: isError ? FontStyle.normal : FontStyle.italic,
            ),
          ),
          if (isError)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Verifique sua conexão ou tente mais tarde',
                style: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.7), fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Widget de GIF animado ─────────────────────
// Usa Image.network que suporta GIF animado nativo em todas as plataformas.
// CachedNetworkImage NÃO anima GIFs — exibe apenas o 1º frame estático.

class _AnimatedGifWidget extends StatefulWidget {
  final String url;
  final VoidCallback? onError;

  const _AnimatedGifWidget({required this.url, this.onError});

  @override
  State<_AnimatedGifWidget> createState() => _AnimatedGifWidgetState();
}

class _AnimatedGifWidgetState extends State<_AnimatedGifWidget> {
  bool _hasError = false;
  bool _isLoading = true;

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: AppTheme.danger.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            const Text(
              'Erro ao carregar animação',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Text(
              'Verifique sua conexão ou tente mais tarde',
              style: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.7), fontSize: 11),
            ),
          ],
        ),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        // Image.network suporta GIF animado nativamente no Flutter
        Image.network(
          widget.url,
          fit: BoxFit.contain,
          width: double.infinity,
          height: double.infinity,
          // gaplessPlayback mantém o último frame enquanto carrega novo GIF
          gaplessPlayback: true,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              // Carregado — oculta o indicador
              if (_isLoading) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) setState(() => _isLoading = false);
                });
              }
              return child;
            }
            // Calculando progresso de download
            final progress = loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                : null;
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    value: progress,
                    color: AppTheme.accent,
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    progress != null
                        ? 'Carregando ${(progress * 100).toStringAsFixed(0)}%'
                        : 'Carregando animação...',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            widget.onError?.call();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _hasError = true);
            });
            return const SizedBox.shrink();
          },
        ),
      ],
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
        // ── Timer & Meta Bar ──────────────────
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            children: [
              const Icon(Icons.timer_outlined, color: Color(0xFFCCFF00), size: 18),
              const SizedBox(width: 10),
              StreamBuilder<int>(
                stream: timerStream,
                builder: (_, __) => Text(
                  formatDuration(provider.sessionStart!),
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFCCFF00),
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const Spacer(),
              _buildSimpleStat('Volume', '${provider.currentTotalVolume.toInt()} kg'),
            ],
          ),
        ),

        // ── Rest Timer Banner ─────────────────
        if (provider.activeRestSeconds > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _RestTimerBanner(),
          ),

        // ── Monitor de Fadiga ─────────────────
        if (exercises.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: _FatigueMonitorWidget(exercises: exercises),
          ),

        // Exercícios
        Expanded(
          child: exercises.isEmpty
              ? _buildEmptyExercises()
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 120, left: 16, right: 16),
                  itemCount: exercises.length,
                  itemBuilder: (_, i) => _ExerciseCard(
                    exerciseIndex: i,
                    entry: exercises[i],
                    onShowTutorial: onShowTutorial,
                  ).animate().fadeIn(delay: (i * 100).ms).slideY(begin: 0.1),
                ),
        ),
      ],
    );
  }

  Widget _buildSimpleStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(label, style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
        Text(value, style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _buildEmptyExercises() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.fitness_center_rounded, color: Colors.white10, size: 64),
          const SizedBox(height: 16),
          Text(
            'Nenhum exercício ainda',
            style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 16),
          ),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: onAddExercise,
            icon: const Icon(Icons.add_rounded, color: Color(0xFFCCFF00)),
            label: Text('ADICIONAR', style: GoogleFonts.outfit(color: const Color(0xFFCCFF00), fontWeight: FontWeight.w900, letterSpacing: 1)),
          ),
        ],
      ),
    );
  }
}

// ── Monitor de Fadiga em Tempo Real ──────────

class _FatigueMonitorWidget extends StatefulWidget {
  final List<dynamic> exercises;
  const _FatigueMonitorWidget({required this.exercises});

  @override
  State<_FatigueMonitorWidget> createState() => _FatigueMonitorWidgetState();
}

class _FatigueMonitorWidgetState extends State<_FatigueMonitorWidget> {
  bool _expanded = false;

  // Calcula fadiga a partir dos exercícios na sessão
  // Usando os dados de spinalLoad, shoulderStress, kneeStress, cnsLoad do ExerciseModel
  Map<String, double> _calcFatigue(BuildContext context) {
    final ep = context.read<ExerciseProvider>();
    double spinal = 0, shoulder = 0, knee = 0, cns = 0;

    for (final entry in widget.exercises) {
      final model = ep.getById(entry.exerciseId);
      if (model == null) continue;
      final sets = (entry.sets as List).length.toDouble();
      // Acumula fadiga ponderada pelo número de séries
      spinal += model.spinalLoad * sets * 0.2;
      shoulder += model.shoulderStress * sets * 0.2;
      knee += model.kneeStress * sets * 0.2;
      cns += model.cnsLoad * sets * 0.2;
    }

    return {
      'spinal': spinal.clamp(0.0, 1.0),
      'shoulder': shoulder.clamp(0.0, 1.0),
      'knee': knee.clamp(0.0, 1.0),
      'cns': cns.clamp(0.0, 1.0),
    };
  }

  Color _barColor(double value) {
    if (value >= 1.0) return const Color(0xFFEF4444);
    if (value >= 0.81) return const Color(0xFFF97316);
    if (value >= 0.61) return const Color(0xFFEAB308);
    return const Color(0xFF22C55E);
  }

  String _barStatus(double value) {
    if (value >= 1.0) return '⚠ LIMITE';
    if (value >= 0.81) return '⚠ Atenção';
    if (value >= 0.61) return '⚡ Moderado';
    return '✓ OK';
  }

  void _checkCritical(BuildContext context, Map<String, double> fatigue) {
    final labels = {'spinal': 'LOMBAR', 'shoulder': 'OMBRO', 'knee': 'JOELHO', 'cns': 'SNC'};
    for (final entry in fatigue.entries) {
      if (entry.value >= 1.0) {
        HapticFeedback.heavyImpact();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              title: Row(
                children: [
                  const Icon(Icons.warning_rounded, color: Color(0xFFEF4444)),
                  const SizedBox(width: 10),
                  Text('Carga Máxima: ${labels[entry.key]}',
                      style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                ],
              ),
              content: Text(
                'Carga máxima atingida para ${labels[entry.key]}.\n\nRecomendamos não adicionar mais exercícios que estressem esta articulação nesta sessão.',
                style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 13, height: 1.5),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
                  child: const Text('ENTENDIDO'),
                ),
              ],
            ),
          );
        });
        break; // Uma notificação por vez
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fatigue = _calcFatigue(context);

    // Check for critical values
    _checkCritical(context, fatigue);

    final maxVal = fatigue.values.fold(0.0, (a, b) => a > b ? a : b);
    final headerColor = maxVal >= 1.0
        ? const Color(0xFFEF4444)
        : maxVal >= 0.81
            ? const Color(0xFFF97316)
            : maxVal >= 0.61
                ? const Color(0xFFEAB308)
                : const Color(0xFF22C55E);

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF161616),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: headerColor.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            // ── Header (sempre visível) ──
            Row(
              children: [
                Icon(Icons.monitor_heart_rounded, color: headerColor, size: 16),
                const SizedBox(width: 10),
                Text(
                  'MONITOR DE FADIGA',
                  style: GoogleFonts.outfit(
                    color: headerColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const Spacer(),
                // Mini indicadores condensados
                if (!_expanded) ...[
                  _MiniBar(value: fatigue['spinal']!, color: _barColor(fatigue['spinal']!)),
                  const SizedBox(width: 4),
                  _MiniBar(value: fatigue['shoulder']!, color: _barColor(fatigue['shoulder']!)),
                  const SizedBox(width: 4),
                  _MiniBar(value: fatigue['knee']!, color: _barColor(fatigue['knee']!)),
                  const SizedBox(width: 4),
                  _MiniBar(value: fatigue['cns']!, color: _barColor(fatigue['cns']!)),
                  const SizedBox(width: 8),
                ],
                Icon(
                  _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                  color: AppTheme.textSecondary,
                  size: 18,
                ),
              ],
            ),
            // ── Barras expandidas ──
            if (_expanded) ...[
              const SizedBox(height: 16),
              _FatigueBar(label: 'LOMBAR', value: fatigue['spinal']!, color: _barColor(fatigue['spinal']!), status: _barStatus(fatigue['spinal']!)),
              const SizedBox(height: 10),
              _FatigueBar(label: 'OMBRO', value: fatigue['shoulder']!, color: _barColor(fatigue['shoulder']!), status: _barStatus(fatigue['shoulder']!)),
              const SizedBox(height: 10),
              _FatigueBar(label: 'JOELHO', value: fatigue['knee']!, color: _barColor(fatigue['knee']!), status: _barStatus(fatigue['knee']!)),
              const SizedBox(height: 10),
              _FatigueBar(label: 'SNC', value: fatigue['cns']!, color: _barColor(fatigue['cns']!), status: _barStatus(fatigue['cns']!)),
              const SizedBox(height: 8),
              Text(
                'Toque para expandir/recolher. Baseado nos exercícios da sessão atual.',
                style: GoogleFonts.outfit(color: AppTheme.textSecondary.withValues(alpha: 0.4), fontSize: 10),
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

class _FatigueBar extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final String status;

  const _FatigueBar({required this.label, required this.value, required this.color, required this.status});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            SizedBox(
              width: 60,
              child: Text(label, style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: value),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOut,
                  builder: (_, v, __) => LinearProgressIndicator(
                    value: v,
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                    valueColor: AlwaysStoppedAnimation(color),
                    minHeight: 7,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 70,
              child: Text(
                '${(value * 100).toInt()}%  $status',
                style: GoogleFonts.outfit(color: color, fontSize: 10, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MiniBar extends StatelessWidget {
  final double value;
  final Color color;
  const _MiniBar({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 6,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(3),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: value,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
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
    final exerciseModel = context.read<ExerciseProvider>().getById(entry.exerciseId);

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
          // Header do exercício
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 12, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.exerciseName.toUpperCase(),
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        entry.muscleGroup,
                        style: GoogleFonts.outfit(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.play_circle_fill_rounded, color: Color(0xFFCCFF00), size: 28),
                  onPressed: () {
                    if (exerciseModel != null) onShowTutorial(context, exerciseModel);
                  },
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, color: Colors.white24),
                  onSelected: (val) {
                    if (val == 'swap') _showSwapDialog(context, exerciseIndex, entry, exerciseModel);
                    if (val == 'delete') provider.removeExerciseFromSession(exerciseIndex);
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'swap', child: Text('Trocar Exercício')),
                    const PopupMenuItem(value: 'delete', child: Text('Remover', style: TextStyle(color: Colors.redAccent))),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Colors.white10),

          // Tabela de Séries
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildTableHeader(),
                const SizedBox(height: 12),
                ...List.generate(entry.sets.length, (si) {
                  final set = entry.sets[si];
                  return _SetRow(
                    setNumber: si + 1,
                    reps: set.reps,
                    weight: set.weight,
                    volume: set.volume,
                    isWarmup: set.isWarmup,
                    isCompleted: set.isCompleted,
                    onChanged: (reps, weight, isWarmup, isCompleted) => provider.updateSet(
                      exerciseIndex: exerciseIndex,
                      setIndex: si,
                      reps: reps,
                      weight: weight,
                      isWarmup: isWarmup,
                      isCompleted: isCompleted,
                    ),
                    onRemove: entry.sets.length > 1 ? () => provider.removeSet(exerciseIndex, si) : null,
                  );
                }),
                const SizedBox(height: 16),
                _RirSelector(exerciseId: entry.exerciseId, exerciseName: entry.exerciseName),
              ],
            ),
          ),

          // Footer - Adicionar Série
          InkWell(
            onTap: () => provider.addSet(exerciseIndex),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.02),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_rounded, color: Color(0xFFCCFF00), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'ADICIONAR SÉRIE',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFFCCFF00),
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      letterSpacing: 1,
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

  Widget _buildTableHeader() {
    return Row(
      children: [
        _headerCell('SÉRIE', width: 40),
        _headerCell('REPS', expanded: true),
        _headerCell('PESO (KG)', expanded: true),
        _headerCell('CHECK', width: 40),
      ],
    );
  }

  Widget _headerCell(String label, {double? width, bool expanded = false}) {
    final text = Text(
      label,
      style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
      textAlign: TextAlign.center,
    );
    return expanded ? Expanded(child: text) : SizedBox(width: width, child: text);
  }

  void _showSwapDialog(BuildContext context, int index, dynamic entry, ExerciseModel? oldEx) {
    if (oldEx == null) return;
    
    final exerciseProvider = context.read<ExerciseProvider>();
    final workoutProvider = context.read<WorkoutProvider>();
    final profile = context.read<WorkoutProfileProvider>().profile;
    
    // Busca substitutos
    List<ExerciseModel> replacements = [];
    
    // 1. Substitutos diretos e regressões
    final directIds = [...oldEx.substituteIds, ...oldEx.regressionIds];
    for (final id in directIds) {
      final ex = exerciseProvider.getById(id);
      if (ex != null && !replacements.any((r) => r.id == ex.id)) replacements.add(ex);
    }
    
    // 2. Fallback por padrão e músculo
    if (replacements.length < 4) {
      final fallbacks = exerciseProvider.filteredExercises.where((ex) =>
        ex.id != oldEx.id &&
        ex.primaryMuscles.contains(oldEx.primaryMuscles.first) &&
        ex.movementPattern == oldEx.movementPattern &&
        !replacements.any((r) => r.id == ex.id) &&
        !(profile?.experienceLevel == 'beginner' && ex.difficulty == 'advanced')
      ).take(6);
      replacements.addAll(fallbacks);
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Trocar exercício', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Sugestões para substituir ${oldEx.name}:', style: const TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 20),
            if (replacements.isEmpty)
              const Center(child: Text('Nenhuma alternativa encontrada.', style: TextStyle(color: AppTheme.textSecondary)))
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: replacements.length,
                  itemBuilder: (context, i) {
                    final ex = replacements[i];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(ex.name, style: const TextStyle(color: AppTheme.textPrimary)),
                      subtitle: Text('${ex.category == 'compound' ? 'Composto' : 'Isolador'} • ${ex.difficulty}', 
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                      trailing: const Icon(Icons.swap_horiz_rounded, color: AppTheme.accent),
                      onTap: () {
                        workoutProvider.replaceExerciseInSession(index, ex);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Exercício trocado por ${ex.name}!'), backgroundColor: AppTheme.accent),
                        );
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
                    'Intensidade (RIR):',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                  ),
                ),
              ],
            ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              _rirLabel(currentRir),
              style: TextStyle(
                color: _rirColor(currentRir),
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.help_outline_rounded, size: 16, color: AppTheme.accent),
              onPressed: () => _showRirExplanation(context),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              visualDensity: VisualDensity.compact,
              tooltip: 'O que é RIR?',
            ),
          ],
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

  void _showRirExplanation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Row(
          children: [
            Icon(Icons.speed_rounded, color: AppTheme.accent),
            SizedBox(width: 12),
            Text('O que é RIR?', style: TextStyle(color: AppTheme.textPrimary)),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'RIR (Repetições em Reserva) é quantas repetições você sente que conseguiria fazer além das que já fez.',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
              ),
              SizedBox(height: 16),
              _RirHelpItem(num: '0', label: 'Falha Total', desc: 'Não conseguiria fazer mais NENHUMA.'),
              _RirHelpItem(num: '1', label: 'Muito difícil', desc: 'Talvez saísse mais uma com esforço máximo.'),
              _RirHelpItem(num: '2', label: 'Zona Ideal', desc: 'Conseguiria fazer mais 2 com boa técnica.'),
              _RirHelpItem(num: '3', label: 'Moderado', desc: 'Daria para fazer mais 3 repetições.'),
              _RirHelpItem(num: '4-5', label: 'Leve', desc: 'Carga de aquecimento ou muito fácil.'),
              SizedBox(height: 16),
              Text(
                'DICA: Tente manter a maioria dos seus exercícios no RIR 2 para o melhor equilíbrio entre ganho e recuperação.',
                style: TextStyle(color: AppTheme.accent, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ENTENDI'),
          ),
        ],
      ),
    );
  }
}

class _RirHelpItem extends StatelessWidget {
  final String num;
  final String label;
  final String desc;
  const _RirHelpItem({required this.num, required this.label, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(num, style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                Text(desc, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
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
  final bool isCompleted;
  final void Function(int reps, double weight, bool isWarmup, bool isCompleted) onChanged;
  final VoidCallback? onRemove;

  const _SetRow({
    required this.setNumber,
    required this.reps,
    required this.weight,
    required this.volume,
    required this.isWarmup,
    required this.isCompleted,
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

  void _notify({bool? isWarmup, bool? isCompleted}) {
    final reps = int.tryParse(_repsCtrl.text) ?? widget.reps;
    final weight = double.tryParse(_weightCtrl.text) ?? widget.weight;
    widget.onChanged(reps, weight, isWarmup ?? widget.isWarmup, isCompleted ?? widget.isCompleted);
  }

  void _toggleComplete() {
    final newStatus = !widget.isCompleted;
    _notify(isCompleted: newStatus);
    if (newStatus && !widget.isWarmup) {
      final reps = int.tryParse(_repsCtrl.text) ?? widget.reps;
      int rest = 60;
      if (reps <= 6) rest = 180;
      else if (reps <= 12) rest = 90;
      context.read<WorkoutProvider>().startRestTimer(rest);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          // Número da série (toca para alternar Warmup)
          GestureDetector(
            onTap: () => _notify(isWarmup: !widget.isWarmup),
            child: SizedBox(
              width: 40,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: widget.isWarmup ? const Color(0xFF00E5FF).withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.isWarmup) const Icon(Icons.bolt_rounded, color: Color(0xFF00E5FF), size: 14),
                    Text(
                      '${widget.setNumber}',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        color: widget.isWarmup ? const Color(0xFF00E5FF) : Colors.white24,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Campo de Reps
          Expanded(
            child: _buildInputField(_repsCtrl, '0', isDigits: true),
          ),
          const SizedBox(width: 12),
          
          // Campo de Peso
          Expanded(
            child: _buildInputField(_weightCtrl, '0.0'),
          ),
          const SizedBox(width: 12),

          // Botão de Check
          SizedBox(
            width: 40,
            child: IconButton(
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                child: Icon(
                  widget.isCompleted ? Icons.check_circle_rounded : Icons.circle_outlined,
                  key: ValueKey(widget.isCompleted),
                  color: widget.isCompleted ? const Color(0xFFCCFF00) : Colors.white24,
                  size: 26,
                ),
              ),
              onPressed: _toggleComplete,
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(TextEditingController ctrl, String hint, {bool isDigits = false}) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: TextField(
        controller: ctrl,
        keyboardType: TextInputType.numberWithOptions(decimal: !isDigits),
        inputFormatters: isDigits ? [FilteringTextInputFormatter.digitsOnly] : [],
        textAlign: TextAlign.center,
        style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        onChanged: (_) => _notify(),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white10),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }
}

class _RestTimerBanner extends StatelessWidget {
  const _RestTimerBanner();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkoutProvider>();
    final seconds = provider.activeRestSeconds;
    
    final min = seconds ~/ 60;
    final sec = seconds % 60;
    final timeStr = '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF00E5FF).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.timer_rounded, color: Color(0xFF00E5FF), size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tempo de Descanso',
                  style: GoogleFonts.outfit(color: const Color(0xFF00E5FF), fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1),
                ),
                Text(
                  timeStr,
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => context.read<WorkoutProvider>().stopRestTimer(),
            icon: const Icon(Icons.skip_next_rounded, color: Colors.white54, size: 28),
            tooltip: 'Pular descanso',
          ),
        ],
      ),
    );
  }
}


