import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../shared/theme/app_theme.dart';
import 'workout_routine_model.dart';
import 'routine_service.dart';
import 'workout_provider.dart';

// ─────────────────────────────────────────────
// Tela de Listagem de Rotinas (Templates)
// ─────────────────────────────────────────────

class RoutineListScreen extends StatefulWidget {
  const RoutineListScreen({super.key});

  @override
  State<RoutineListScreen> createState() => _RoutineListScreenState();
}

class _RoutineListScreenState extends State<RoutineListScreen> {
  late Future<List<WorkoutRoutine>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _future = RoutineService(db: FirebaseFirestore.instance, uid: uid).loadAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Meus Treinos',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => setState(_load),
          ),
        ],
      ),
      body: FutureBuilder<List<WorkoutRoutine>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppTheme.accent));
          }

          final routines = snap.data ?? [];

          if (routines.isEmpty) {
            return _EmptyRoutines(onAdd: () => _createNewRoutine(context));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: routines.length,
            itemBuilder: (context, index) {
              final r = routines[index];
              return _RoutineCard(routine: r, onRefresh: () => setState(_load));
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createNewRoutine(context),
        backgroundColor: AppTheme.accent,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Criar Treino',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _createNewRoutine(BuildContext context) {
    // Para simplificar, vamos usar um dialog rápido para o nome e depois abrir edição
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Nome do Treino',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(hintText: 'Ex: Treino A - Empurre'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.isEmpty) return;
              final uid = FirebaseAuth.instance.currentUser?.uid;
              if (uid != null) {
                final routine = WorkoutRoutine(
                  id: '',
                  name: ctrl.text.trim(),
                  exercises: [],
                  createdAt: DateTime.now(),
                );
                await RoutineService(db: FirebaseFirestore.instance, uid: uid)
                    .save(routine);
                if (mounted) {
                  Navigator.pop(ctx);
                  setState(_load);
                }
              }
            },
            child: const Text('Criar'),
          ),
        ],
      ),
    );
  }
}

class _RoutineCard extends StatelessWidget {
  final WorkoutRoutine routine;
  final VoidCallback onRefresh;

  const _RoutineCard({required this.routine, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onLongPress: () => _confirmDelete(context),
          onTap: () {
            context.push('/routines/detail', extra: routine);
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        routine.name,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        color: AppTheme.textSecondary),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    _Badge(
                        label: '${routine.exercises.length} exercícios',
                        icon: Icons.fitness_center_rounded),
                    if (routine.exercises.isNotEmpty)
                      _Badge(
                        label: routine.exercises
                            .map((e) => e.muscleGroup)
                            .toSet()
                            .join(', '),
                        icon: Icons.category_rounded,
                        color: AppTheme.accent,
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      context.read<WorkoutProvider>().startSessionFromRoutine(routine);
                      context.go('/workout');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.success.withValues(alpha: 0.1),
                      foregroundColor: AppTheme.success,
                      elevation: 0,
                      side: BorderSide(color: AppTheme.success.withValues(alpha: 0.3)),
                    ),
                    child: const Text('INICIAR ESTE TREINO 💪'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Excluir?',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text('Deseja realmente excluir este treino?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Não')),
          TextButton(
            onPressed: () async {
              final uid = FirebaseAuth.instance.currentUser?.uid;
              if (uid != null) {
                await RoutineService(db: FirebaseFirestore.instance, uid: uid)
                    .delete(routine.id);
                onRefresh();
                if (context.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Excluir', style: TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? color;

  const _Badge({required this.label, required this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: c),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
                color: c, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _EmptyRoutines extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyRoutines({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.assignment_rounded, size: 64, color: AppTheme.surfaceHighlight),
          const SizedBox(height: 16),
          const Text(
            'Você ainda não montou seus treinos.',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onAdd,
            child: const Text('Monte seu primeiro treino agora 🏋️'),
          ),
        ],
      ),
    );
  }
}
