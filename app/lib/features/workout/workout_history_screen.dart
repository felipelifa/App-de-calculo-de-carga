import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../shared/theme/app_theme.dart';
import 'workout_provider.dart';
import 'workout_models.dart';

class WorkoutHistoryScreen extends StatefulWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  State<WorkoutHistoryScreen> createState() => _WorkoutHistoryScreenState();
}

class _WorkoutHistoryScreenState extends State<WorkoutHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WorkoutProvider>().loadHistory();
    });
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
          'Histórico',
          style: TextStyle(
              color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
              height: 1,
              color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      body: provider.isLoadingHistory
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.accent))
          : provider.history.isEmpty
              ? const Center(
                  child: Text(
                    'Nenhum treino registrado ainda.',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.history.length,
                  itemBuilder: (_, i) =>
                      _SessionCard(session: provider.history[i]),
                ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final WorkoutSession session;
  const _SessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final dateStr =
        DateFormat('dd/MM/yyyy  HH:mm').format(session.date);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        tilePadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Text(
          dateStr,
          style: const TextStyle(
              color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'Volume: ${session.totalVolume.toStringAsFixed(0)} kg  •  '
          '${session.exercises.length} exercícios  •  '
          'Semana ${session.weekNumber}',
          style:
              const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.danger, size: 20),
          onPressed: () => _confirmDelete(context, session.id),
        ),
        iconColor: AppTheme.textSecondary,
        collapsedIconColor: AppTheme.textSecondary,
        children: session.exercises
            .map((ex) => _ExerciseSummary(entry: ex))
            .toList(),
      ),
    );
  }
  void _confirmDelete(BuildContext context, String sessionId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Excluir treino?', style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text('Esta ação não pode ser desfeita e removerá este registro do seu histórico.', 
            style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await context.read<WorkoutProvider>().deleteSession(sessionId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Treino removido com sucesso.')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro ao excluir: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
}

class _ExerciseSummary extends StatelessWidget {
  final WorkoutExerciseEntry entry;
  const _ExerciseSummary({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  entry.exerciseName,
                  style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w500,
                      fontSize: 14),
                ),
              ),
              Text(
                '${entry.totalVolume.toStringAsFixed(0)} kg',
                style: const TextStyle(
                    color: AppTheme.success, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            children: entry.sets.asMap().entries.map((e) {
              final s = e.value;
              return Text(
                '${e.key + 1}× ${s.reps}×${s.weight.toStringAsFixed(1)}kg',
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 12),
              );
            }).toList(),
          ),
          const Divider(color: Color(0x1FFFFFFF), height: 16),
        ],
      ),
    );
  }
}
