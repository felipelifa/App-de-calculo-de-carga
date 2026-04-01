import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../shared/theme/app_theme.dart';
import 'workout_profile_provider.dart';
import 'prescribed_workout_model.dart';
import 'workout_provider.dart';
import 'workout_routine_model.dart';

// ─────────────────────────────────────────────
// Tela de Visualização do Treino Gerado (Pro)
// ─────────────────────────────────────────────

class PrescribedWorkoutScreen extends StatelessWidget {
  const PrescribedWorkoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final wpAuth = context.watch<WorkoutProfileProvider>();

    if (wpAuth.isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(child: CircularProgressIndicator(color: AppTheme.accent)),
      );
    }

    final workout = wpAuth.currentWorkout;
    if (workout == null) {
      // Isso não deveria acontecer porque só entramos aqui se existir, mas por prevenção:
      WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/anamnese'));
      return const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Seu Treino PRO', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
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
        title: const Text('Excluir Treino PRO?', style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text(
          'Isso apagará o seu mesociclo atual. Você pode refazer a anamnese e gerar um novo treino quando desejar.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            child: const Text('CANCELAR', style: TextStyle(color: AppTheme.textSecondary)),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(context);
              final wp = context.read<WorkoutProfileProvider>();
              await wp.deleteCurrentWorkout();
              context.go('/anamnese');
            },
            child: const Text('EXCLUIR E REFAZER', style: TextStyle(color: Colors.white)),
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
          border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
        ),
        child: Column(
          children: [
            const Icon(Icons.auto_awesome_rounded, size: 48, color: AppTheme.accent),
            const SizedBox(height: 16),
            const Text(
              'Mesociclo Científico',
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Duração: ${workout.mesocycleDurationWeeks} Semanas  •  Modelo: ${_formatPeriodization(workout.periodizationModel)}',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPeriodization(String p) {
    switch (p) {
      case 'linear': return 'Linear';
      case 'dup': return 'Ondulatória Diária';
      case 'block': return 'Em Bloco';
      default: return p.toUpperCase();
    }
  }
}

class _SessionCard extends StatelessWidget {
  final PrescribedSession session;

  const _SessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceHighlight.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        session.name,
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${session.estimatedDurationMinutes} min',
                        style: const TextStyle(color: AppTheme.accent, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 8),
                Text(session.objective, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          
          // Corpo do Card (Exercícios)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: session.exercises.map((ex) => _buildExerciseRow(ex)).toList(),
            ),
          ),

          // Footer (Botão de Iniciar)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: ElevatedButton.icon(
              onPressed: () {
                _startSession(context);
              },
              icon: const Icon(Icons.play_circle_fill_rounded),
              label: const Text('INICIAR ESTE TREINO'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildExerciseRow(PrescribedExercise ex) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.fitness_center_rounded, size: 20, color: AppTheme.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ex.exercise.name,
                  style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  '${ex.sets} séries  •  ${ex.repsMin}-${ex.repsMax} reps  •  Rest: ${ex.restSeconds}s',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _startSession(BuildContext context) {
    final wp = context.read<WorkoutProvider>();
    
    // Converte de PrescribedSession para um Routine temporária para iniciar
    final routine = WorkoutRoutine(
      id: session.id,
      name: session.name,
      description: session.objective,
      createdAt: DateTime.now(),
      exercises: session.exercises.map((e) => RoutineExercise(
        exerciseId: e.exercise.id,
        name: e.exercise.name,
        muscleGroup: e.exercise.primaryMuscles.isNotEmpty ? e.exercise.primaryMuscles.first : '',
        sets: e.sets,
        reps: e.repsMax,
      )).toList(),
    );

    wp.startSessionFromRoutine(routine);
    context.go('/workout');
  }
}
