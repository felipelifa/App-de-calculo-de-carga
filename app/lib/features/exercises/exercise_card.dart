import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/theme/app_theme.dart';
import 'exercise_model.dart';
import 'exercise_provider.dart';

// ─────────────────────────────────────────────
// Muscle group colour map
// ─────────────────────────────────────────────

const Map<String, Color> _muscleColors = {
  'Peito': Color(0xFF6366F1),       // indigo
  'Costas': Color(0xFF0EA5E9),      // sky blue
  'Ombro': Color(0xFF8B5CF6),       // purple
  'Bíceps': Color(0xFF10B981),      // emerald
  'Tríceps': Color(0xFF14B8A6),     // teal
  'Quadríceps': Color(0xFFF59E0B),  // amber
  'Posterior': Color(0xFFEF4444),   // red
  'Glúteo': Color(0xFFEC4899),      // pink
  'Core': Color(0xFFF97316),        // orange
  'Panturrilha': Color(0xFF84CC16), // lime
};

Color muscleColor(String group) =>
    _muscleColors[group] ?? AppTheme.accent;

// ─────────────────────────────────────────────
// Private placeholder widget
// ─────────────────────────────────────────────

class _MuscleGroupPlaceholder extends StatelessWidget {
  final String muscleGroup;

  const _MuscleGroupPlaceholder({
    required this.muscleGroup,
  });

  String get _initials {
    final words = muscleGroup.trim().split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return muscleGroup.isEmpty ? '??' : muscleGroup.substring(0, 2).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final color = muscleColor(muscleGroup);
    return Container(
      width: double.infinity,
      height: 140,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.fitness_center_rounded, color: color.withValues(alpha: 0.7), size: 28),
          const SizedBox(height: 4),
          Text(
            _initials,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// ExerciseCard
// ─────────────────────────────────────────────

class ExerciseCard extends StatelessWidget {
  final ExerciseModel exercise;
  final VoidCallback onTap;

  const ExerciseCard({
    super.key,
    required this.exercise,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primaryMuscle = exercise.primaryMuscles.isNotEmpty ? exercise.primaryMuscles.first : 'Geral';
    final color = muscleColor(primaryMuscle);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── GIF / Placeholder ────────────────
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: _buildImage(context),
            ),

            // ── Info ─────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.name,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _Badge(label: primaryMuscle, color: color),
                      const SizedBox(width: 8),
                      if (exercise.equipment.isNotEmpty) _EquipmentChip(label: exercise.equipment.first),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    final url = context.read<ExerciseProvider>().getEffectiveGifUrl(exercise);

    // No URL — show placeholder directly, no network attempt
    if (url == null || url.isEmpty) {
      final primaryMuscle = exercise.primaryMuscles.isNotEmpty ? exercise.primaryMuscles.first : 'Geral';
      return _MuscleGroupPlaceholder(muscleGroup: primaryMuscle);
    }

    // URL present — use Image.network to support GIF animation natively
    return Image.network(
      url,
      height: 140,
      width: double.infinity,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return SizedBox(
          height: 140,
          child: Center(
            child: CircularProgressIndicator(
              color: AppTheme.accent,
              strokeWidth: 2.5,
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      (loadingProgress.expectedTotalBytes ?? 1)
                  : null,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        final primaryMuscle = exercise.primaryMuscles.isNotEmpty ? exercise.primaryMuscles.first : 'Geral';
        return _MuscleGroupPlaceholder(muscleGroup: primaryMuscle);
      },
    );
  }
}

// ─────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EquipmentChip extends StatelessWidget {
  final String label;

  const _EquipmentChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceHighlight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.hardware_rounded, size: 11, color: AppTheme.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
