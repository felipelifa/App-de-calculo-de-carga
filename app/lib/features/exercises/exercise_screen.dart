import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../shared/theme/app_theme.dart';
import 'exercise_provider.dart';
import 'exercise_card.dart';

const List<String> _muscleGroups = [
  'Peito',
  'Costas',
  'Ombro',
  'Bíceps',
  'Tríceps',
  'Quadríceps',
  'Posterior',
  'Glúteo',
  'Core',
  'Panturrilha',
];

class ExerciseScreen extends StatefulWidget {
  const ExerciseScreen({super.key});

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExerciseProvider>();
    final exercises = provider.filteredExercises;

    return Scaffold(
      // ── AppBar ──────────────────────────────
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: const Text(
          'Exercícios',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => context.go('/dashboard'),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),

      backgroundColor: AppTheme.background,

      // ── Body ────────────────────────────────
      body: Column(
        children: [
          // Search field
          _SearchBar(
            controller: _searchCtrl,
            onChanged: (v) => provider.setSearch(v),
          ),

          // Muscle group filter chips
          _MuscleFilterChips(
            selected: provider.selectedMuscle,
            onSelect: (m) => provider.setMuscleFilter(m),
          ),

          // Exercise list
          Expanded(
            child: _buildBody(provider, exercises),
          ),
        ],
      ),

      // ── FAB ─────────────────────────────────
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/exercises/add'),
        backgroundColor: AppTheme.accent,
        elevation: 6,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBody(ExerciseProvider provider, List<ExerciseModel> exercises) {
    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.accent),
      );
    }

    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, color: AppTheme.danger, size: 48),
            const SizedBox(height: 16),
            Text(
              provider.error!,
              style: const TextStyle(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (exercises.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              color: AppTheme.textSecondary.withValues(alpha: 0.4),
              size: 56,
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum exercício encontrado.',
              style: TextStyle(
                color: AppTheme.textSecondary.withValues(alpha: 0.7),
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Toque em + para adicionar.',
              style: TextStyle(
                color: AppTheme.textSecondary.withValues(alpha: 0.4),
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 96),
      itemCount: exercises.length,
      itemBuilder: (context, i) {
        final ex = exercises[i];
        return ExerciseCard(
          exercise: ex,
          onTap: () => context.push('/exercises/${ex.id}'),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(color: AppTheme.textPrimary),
        decoration: InputDecoration(
          hintText: 'Buscar exercício…',
          prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: AppTheme.textSecondary),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                )
              : null,
        ),
      ),
    );
  }
}

class _MuscleFilterChips extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onSelect;

  const _MuscleFilterChips({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        children: _muscleGroups.map((group) {
          final isSelected = selected == group;
          final color = muscleColor(group);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(group),
              selected: isSelected,
              onSelected: (_) => onSelect(group),
              backgroundColor: AppTheme.surfaceHighlight,
              selectedColor: color.withValues(alpha: 0.2),
              checkmarkColor: color,
              labelStyle: TextStyle(
                color: isSelected ? color : AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected ? color.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.08),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
          );
        }).toList(),
      ),
    );
  }
}
