import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/api_service.dart';
import '../../shared/theme/app_theme.dart';
import '../exercises/exercise_provider.dart';
import 'workout_routine_model.dart';

class RoutineDetailScreen extends StatefulWidget {
  final WorkoutRoutine routine;
  const RoutineDetailScreen({super.key, required this.routine});

  @override
  State<RoutineDetailScreen> createState() => _RoutineDetailScreenState();
}

class _RoutineDetailScreenState extends State<RoutineDetailScreen> {
  late WorkoutRoutine _current;

  @override
  void initState() {
    super.initState();
    _current = widget.routine;
  }

  Future<void> _save() async {
    try {
      final api = ApiService();
      if (_current.id.isEmpty || _current.id == 'new') {
        await api.post('/routines', body: _current.toMap());
      } else {
        await api.put('/routines/${_current.id}', body: _current.toMap());
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Treino salvo com sucesso!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(_current.name),
        backgroundColor: AppTheme.surface,
        actions: [
          IconButton(icon: const Icon(Icons.save_rounded), onPressed: _save),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _current.exercises.length + 1,
        itemBuilder: (context, index) {
          if (index == _current.exercises.length) {
            return Column(
              children: [
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => _addExercise(context),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('ADICIONAR EXERCÍCIO'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  ),
                ),
                const SizedBox(height: 100),
              ],
            );
          }

          final ex = _current.exercises[index];
          return _ExerciseInRoutineTile(
            exercise: ex,
            onDelete: () {
              setState(() {
                _current.exercises.removeAt(index);
              });
            },
            onUpdate: (sets, reps) {
              setState(() {
                _current.exercises[index] = RoutineExercise(
                  exerciseId: ex.exerciseId,
                  name: ex.name,
                  muscleGroup: ex.muscleGroup,
                  sets: sets,
                  reps: reps,
                );
              });
            },
          );
        },
      ),
    );
  }

  void _addExercise(BuildContext context) {
    final ep = context.read<ExerciseProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (_, scroll) => Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Escolha um exercício',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scroll,
                itemCount: ep.filteredExercises.length,
                itemBuilder: (c, i) {
                  final ex = ep.filteredExercises[i];
                  return ListTile(
                    title: Text(ex.name, style: const TextStyle(color: AppTheme.textPrimary)),
                    subtitle: Text(ex.primaryMuscles.isNotEmpty ? ex.primaryMuscles.first : 'Geral', style: const TextStyle(color: AppTheme.textSecondary)),
                    onTap: () {
                      setState(() {
                        _current.exercises.add(RoutineExercise(
                          exerciseId: ex.id,
                          name: ex.name,
                          muscleGroup: ex.primaryMuscles.isNotEmpty ? ex.primaryMuscles.first : 'Geral',
                          sets: 3,
                          reps: ex.repRangeMax,
                        ));
                      });
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
}

class _ExerciseInRoutineTile extends StatelessWidget {
  final RoutineExercise exercise;
  final VoidCallback onDelete;
  final Function(int, int) onUpdate;

  const _ExerciseInRoutineTile({
    required this.exercise,
    required this.onDelete,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.drag_handle_rounded, color: AppTheme.textSecondary, size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  exercise.name,
                  style: const TextStyle(
                      color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AppTheme.danger, size: 18),
                onPressed: onDelete,
              ),
            ],
          ),
          const Divider(color: Colors.white12, height: 24),
          Row(
            children: [
              _Counter(
                label: 'Séries',
                value: exercise.sets,
                onChanged: (v) => onUpdate(v, exercise.reps),
              ),
              const Spacer(),
              _Counter(
                label: 'Reps',
                value: exercise.reps,
                onChanged: (v) => onUpdate(exercise.sets, v),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Counter extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  const _Counter({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('$label: ', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        IconButton(
          icon: const Icon(Icons.remove_circle_outline_rounded, size: 20),
          onPressed: () { if (value > 1) onChanged(value - 1); },
          color: AppTheme.textSecondary,
        ),
        Text('$value', style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        IconButton(
          icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
          onPressed: () => onChanged(value + 1),
          color: AppTheme.accent,
        ),
      ],
    );
  }
}
