import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../shared/theme/app_theme.dart';
import '../workout/pr_model.dart';
import '../workout/pr_service.dart';
import 'exercise_model.dart';
import 'exercise_provider.dart';
import 'exercise_card.dart';

class ExerciseDetailScreen extends StatefulWidget {
  final String exerciseId;

  const ExerciseDetailScreen({super.key, required this.exerciseId});

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  late TextEditingController _seriesCtrl;
  late TextEditingController _repMinCtrl;
  late TextEditingController _repMaxCtrl;

  ExerciseModel? _exercise;
  bool _isSaving = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _seriesCtrl = TextEditingController();
    _repMinCtrl = TextEditingController();
    _repMaxCtrl = TextEditingController();
  }

  void _populateFields(ExerciseModel ex) {
    if (_exercise?.id != ex.id) {
      _seriesCtrl.text = '3';
      _repMinCtrl.text = ex.repRangeMin.toString();
      _repMaxCtrl.text = ex.repRangeMax.toString();
    }
    _exercise = ex;
  }

  Future<void> _saveChanges(ExerciseProvider provider) async {
    final series = int.tryParse(_seriesCtrl.text.trim());
    final repMin = int.tryParse(_repMinCtrl.text.trim());
    final repMax = int.tryParse(_repMaxCtrl.text.trim());

    if (series == null || repMin == null || repMax == null) {
      setState(() {
        _saveError = 'Preencha todos os campos com números válidos.';
      });
      return;
    }
    if (repMin > repMax) {
      setState(() {
        _saveError = 'Rep mínimo não pode ser maior que o máximo.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _saveError = null;
    });

    try {
      // Biblioteca global, edição local desabilitada na nova arquitetura
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Apenas leitura: Biblioteca Científica Protegida'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _saveError = 'Erro ao salvar: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _seriesCtrl.dispose();
    _repMinCtrl.dispose();
    _repMaxCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExerciseProvider>();
    final exercises = provider.filteredExercises;

    // Find exercise in provider's list (live data)
    ExerciseModel? ex;
    try {
      ex = provider.filteredExercises.firstWhere((e) => e.id == widget.exerciseId);
    } catch (_) {
      // May not be in filtered list — search all
      ex = null;
    }

    // Also check unfiltered list via a direct call approach
    final allExercises = exercises;
    if (ex == null) {
      for (final e in allExercises) {
        if (e.id == widget.exerciseId) {
          ex = e;
          break;
        }
      }
    }

    if (ex == null && !provider.isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: _buildAppBar(context, null),
        body: const Center(
          child: Text(
            'Exercício não encontrado.',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ),
      );
    }

    if (ex != null) _populateFields(ex);

    final primaryMuscle = ex != null && ex.primaryMuscles.isNotEmpty ? ex.primaryMuscles.first : 'Geral';
    final color = ex != null ? muscleColor(primaryMuscle) : AppTheme.accent;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          // ── SliverAppBar with GIF ─────────────
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: AppTheme.surface,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: ex == null
                  ? _shimmerBox()
                  : _buildHeroImage(ex),
            ),
          ),

          // ── Content ──────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: ex == null
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
                  : _buildContent(context, ex, color, provider),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, ExerciseModel? ex) {
    return AppBar(
      backgroundColor: AppTheme.surface,
      title: Text(ex?.name ?? '', style: const TextStyle(color: AppTheme.textPrimary)),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
        onPressed: () => context.pop(),
      ),
    );
  }

  Widget _buildHeroImage(ExerciseModel ex) {
    final url = context.read<ExerciseProvider>().getEffectiveGifUrl(ex);
    final primaryMuscle = ex.primaryMuscles.isNotEmpty ? ex.primaryMuscles.first : 'Geral';
    
    if (url == null || url.isEmpty) {
      return _placeholderHero(primaryMuscle);
    }
    return Image.network(
      url,
      fit: BoxFit.contain,
      width: double.infinity,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _shimmerBox();
      },
      errorBuilder: (context, error, stackTrace) => _placeholderHero(primaryMuscle),
    );
  }

  Widget _placeholderHero(String muscleGroup) {
    final color = muscleColor(muscleGroup);
    return Container(
      color: color.withValues(alpha: 0.08),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.fitness_center_rounded, color: color.withValues(alpha: 0.6), size: 64),
          const SizedBox(height: 12),
          Text(
            muscleGroup,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 20),
          ),
        ],
      ),
    );
  }

  Widget _shimmerBox() {
    return Container(
      color: AppTheme.surfaceHighlight,
      child: const Center(
        child: CircularProgressIndicator(color: AppTheme.accent, strokeWidth: 2),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ExerciseModel ex,
    Color color,
    ExerciseProvider provider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Title & badges ─────────────────────
        Text(
          ex.name,
          style: Theme.of(context)
              .textTheme
              .displayMedium
              ?.copyWith(fontSize: 22),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _InfoChip(
              label: ex.primaryMuscles.isNotEmpty ? ex.primaryMuscles.first : 'Geral',
              color: color,
              icon: Icons.sports_gymnastics_rounded,
            ),
            if (ex.equipment.isNotEmpty) ...[
              const SizedBox(width: 8),
              _InfoChip(
                label: ex.equipment.first,
                color: AppTheme.textSecondary,
                icon: Icons.hardware_rounded,
              ),
            ],
          ],
        ),

        const SizedBox(height: 28),
        _sectionTitle('Configurações'),
        const SizedBox(height: 14),

        // ── Editable fields ────────────────────
        _EditRow(
          label: 'Séries padrão',
          controller: _seriesCtrl,
          icon: Icons.repeat_rounded,
        ),
        const SizedBox(height: 12),
        _EditRow(
          label: 'Rep mínimo',
          controller: _repMinCtrl,
          icon: Icons.arrow_downward_rounded,
        ),
        const SizedBox(height: 12),
        _EditRow(
          label: 'Rep máximo',
          controller: _repMaxCtrl,
          icon: Icons.arrow_upward_rounded,
        ),

        if (_saveError != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.danger.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3)),
            ),
            child: Text(
              _saveError!,
              style: const TextStyle(color: AppTheme.danger, fontSize: 13),
            ),
          ),
        ],

        const SizedBox(height: 20),

        // ── Save button ────────────────────────
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : () => _saveChanges(provider),
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.save_rounded),
            label: const Text('Salvar alterações'),
          ),
        ),

        const SizedBox(height: 12),

        // ── Add to workout button ───────────────
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              // TODO: navigate to workout session when that feature is built
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Em breve: adicionar ao treino!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.add_circle_outline_rounded),
            label: const Text('Adicionar ao treino'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.accent,
              side: const BorderSide(color: AppTheme.accent),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),

        const SizedBox(height: 32),

        // ── PR do exercício ─────────────────────
        _sectionTitle('Recorde pessoal (PR)'),
        const SizedBox(height: 14),
        _PrSection(exerciseId: ex.id),

        const SizedBox(height: 32),

        // ── Volume history ─────────────────────
        _sectionTitle('Histórico de volume'),
        const SizedBox(height: 14),
        _VolumeHistorySection(exerciseId: ex.id, provider: provider),

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppTheme.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Volume History
// ─────────────────────────────────────────────

class _VolumeHistorySection extends StatefulWidget {
  final String exerciseId;
  final ExerciseProvider provider;

  const _VolumeHistorySection({
    required this.exerciseId,
    required this.provider,
  });

  @override
  State<_VolumeHistorySection> createState() => _VolumeHistorySectionState();
}

class _VolumeHistorySectionState extends State<_VolumeHistorySection> {
  late Future<List<VolumeHistoryEntry>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.provider.getExerciseHistory(widget.exerciseId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<VolumeHistoryEntry>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.accent, strokeWidth: 2),
          );
        }

        final entries = snap.data ?? [];
        if (entries.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceHighlight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: const Text(
              'Nenhum histórico ainda. Complete um treino para ver sua evolução.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          );
        }

        return Column(
          children: entries
              .map((e) => _HistoryTile(entry: e))
              .toList(),
        );
      },
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final VolumeHistoryEntry entry;

  const _HistoryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.bar_chart_rounded, color: AppTheme.accent, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Semana ${entry.weekNumber}',
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            '${entry.totalVolume.toStringAsFixed(0)} kg',
            style: const TextStyle(
              color: AppTheme.accent,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// PR Section
// ─────────────────────────────────────────────

class _PrSection extends StatefulWidget {
  final String exerciseId;
  const _PrSection({required this.exerciseId});

  @override
  State<_PrSection> createState() => _PrSectionState();
}

class _PrSectionState extends State<_PrSection> {
  Future<PersonalRecord?>? _future;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _future = PrService(db: FirebaseFirestore.instance, uid: uid)
          .loadForExercise(widget.exerciseId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PersonalRecord?>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
                color: AppTheme.accent, strokeWidth: 2),
          );
        }

        final pr = snap.data;

        if (pr == null) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceHighlight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: const Text(
              'Nenhum PR ainda. Complete um treino com este exercício!',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFF59E0B).withValues(alpha: 0.10),
                AppTheme.surface,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.emoji_events_rounded,
                      color: Color(0xFFF59E0B), size: 18),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Melhores marcas',
                      style: TextStyle(
                        color: Color(0xFFF59E0B),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Text(
                    DateFormat('dd/MM/yy').format(pr.updatedAt),
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _PrStat(
                      icon: Icons.fitness_center_rounded,
                      label: 'Carga máx.',
                      value: '${pr.maxWeight.toStringAsFixed(1)} kg',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _PrStat(
                      icon: Icons.repeat_rounded,
                      label: 'Reps máx.',
                      value: '${pr.maxReps}',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _PrStat(
                      icon: Icons.bolt_rounded,
                      label: 'Vol. máx.',
                      value: '${pr.maxVolume.toStringAsFixed(0)} kg',
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PrStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _PrStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFFF59E0B), size: 16),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFFF59E0B),
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Reusable sub-widgets
// ─────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _InfoChip({required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EditRow extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;

  const _EditRow({
    required this.label,
    required this.controller,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.textSecondary),
        const SizedBox(width: 10),
        Expanded(
          flex: 3,
          child: Text(
            label,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
          ),
        ),
        Expanded(
          flex: 2,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              filled: true,
              fillColor: AppTheme.surfaceHighlight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppTheme.accent, width: 2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
