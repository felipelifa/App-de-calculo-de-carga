import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../shared/theme/app_theme.dart';
import 'exercise_model.dart';
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
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          // ── App Header ──────────────────────────
          SliverAppBar(
            backgroundColor: AppTheme.background,
            floating: true,
            pinned: true,
            expandedHeight: 120,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textPrimary, size: 20),
              onPressed: () => context.go('/dashboard'),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              title: Text(
                'Exercícios',
                style: GoogleFonts.outfit(
                  color: AppTheme.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),

          // ── Search & Filter ─────────────────────
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildModernSearchBar(provider),
                const SizedBox(height: 16),
                _buildModernFilterChips(provider),
                const SizedBox(height: 24),
              ],
            ),
          ),

          // ── Exercise List ───────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
            sliver: _buildSliverBody(provider, exercises),
          ),
        ],
      ),

      // ── FAB ─────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/exercises/add'),
        backgroundColor: const Color(0xFFCCFF00),
        icon: const Icon(Icons.add_rounded, color: Colors.black, weight: 800),
        label: Text(
          'NOVO',
          style: GoogleFonts.outfit(
            color: Colors.black,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
      ).animate().scale(delay: 400.ms, curve: Curves.easeOutBack),
    );
  }

  Widget _buildModernSearchBar(ExerciseProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: TextField(
          controller: _searchCtrl,
          onChanged: (v) => provider.setSearch(v),
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Buscar exercício...',
            hintStyle: GoogleFonts.outfit(color: AppTheme.textSecondary.withOpacity(0.5), fontSize: 16),
            prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFCCFF00), size: 22),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 15),
            suffixIcon: _searchCtrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white24, size: 20),
                    onPressed: () {
                      _searchCtrl.clear();
                      provider.setSearch('');
                    },
                  )
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildModernFilterChips(ExerciseProvider provider) {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _muscleGroups.length,
        itemBuilder: (context, i) {
          final group = _muscleGroups[i];
          final isSelected = provider.selectedMuscle == group;
          final color = isSelected ? const Color(0xFFCCFF00) : Colors.white24;

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: FilterChip(
              label: Text(
                group,
                style: GoogleFonts.outfit(
                  color: isSelected ? Colors.black : Colors.white70,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
                ),
              ),
              selected: isSelected,
              onSelected: (_) => provider.setMuscleFilter(group),
              showCheckmark: false,
              backgroundColor: const Color(0xFF1A1A1A),
              selectedColor: const Color(0xFFCCFF00),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: color.withOpacity(0.1), width: 1),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSliverBody(ExerciseProvider provider, List<ExerciseModel> exercises) {
    if (provider.isLoading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator(color: Color(0xFFCCFF00))),
      );
    }

    if (exercises.isEmpty) {
      return SliverFillRemaining(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, color: Colors.white10, size: 64),
            const SizedBox(height: 16),
            Text(
              'Nenhum exercício encontrado',
              style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, i) {
          final ex = exercises[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ExerciseCard(
              exercise: ex,
              onTap: () => context.push('/exercises/${ex.id}'),
            ),
          ).animate().fadeIn(delay: (i * 50).ms).slideY(begin: 0.1);
        },
        childCount: exercises.length,
      ),
    );
  }
}

