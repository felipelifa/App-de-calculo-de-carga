import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../shared/theme/app_theme.dart';
import 'workout_profile_provider.dart';
import 'prescribed_workout_model.dart';
import 'workout_provider.dart';
import '../exercises/exercise_provider.dart';
import '../exercises/exercise_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'bio_adaptive_engine.dart';

class PrescribedWorkoutScreen extends StatefulWidget {
  const PrescribedWorkoutScreen({super.key});

  @override
  State<PrescribedWorkoutScreen> createState() => _PrescribedWorkoutScreenState();
}

class _PrescribedWorkoutScreenState extends State<PrescribedWorkoutScreen> {
  @override
  void initState() {
    super.initState();
    // Garantir hidratação dos exercícios ao abrir a tela de treinos prescritos
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final wp = context.read<WorkoutProfileProvider>();
      final ep = context.read<ExerciseProvider>();
      wp.connectExerciseProvider(ep);
    });
  }

  @override
  Widget build(BuildContext context) {
    final wpAuth = context.watch<WorkoutProfileProvider>();
    final allWorkouts = wpAuth.allWorkouts;
    final activeWorkout = wpAuth.activeWorkout;

    if (wpAuth.isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(child: CircularProgressIndicator(color: AppTheme.accent)),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
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
                'Meus Treinos',
                style: GoogleFonts.outfit(
                  color: AppTheme.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded, color: AppTheme.accent),
                onPressed: () => _generateNewWorkout(context),
              ),
              const SizedBox(width: 8),
            ],
          ),

          if (allWorkouts.isEmpty)
            SliverFillRemaining(
              child: _buildEmptyState(context),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final workout = allWorkouts[index];
                    return _WorkoutPlanCard(
                      workout: workout,
                      isActive: workout.id == activeWorkout?.id,
                      onDelete: () => _confirmDeletion(context, workout.id),
                      onSelect: () => wpAuth.setActiveWorkout(workout.id),
                      onView: () => _showWorkoutDetails(context, workout),
                    ).animate().fadeIn(delay: (index * 100).ms).slideX(begin: 0.1);
                  },
                  childCount: allWorkouts.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.fitness_center_rounded, size: 64, color: AppTheme.textSecondary),
          const SizedBox(height: 24),
          Text(
            'Nenhum treino gerado ainda.',
            style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Responda a anamnese para criar seu plano.',
            style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => context.go('/anamnese'),
            child: const Text('GERAR MEU TREINO'),
          ),
        ],
      ),
    );
  }

  void _generateNewWorkout(BuildContext context) {
     context.go('/anamnese');
  }

  void _confirmDeletion(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Excluir Plano?', style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text('Esta ação não pode ser desfeita.', style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCELAR')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              context.read<WorkoutProfileProvider>().deleteWorkout(id);
              Navigator.pop(ctx);
            },
            child: const Text('EXCLUIR'),
          ),
        ],
      ),
    );
  }

  void _showWorkoutDetails(BuildContext context, GeneratedWorkout workout) {
    // Aqui poderíamos abrir uma tela com as sessões deste treino específico
    // Para simplificar, vamos definir como ativo e mostrar as sessões.
    context.read<WorkoutProfileProvider>().setActiveWorkout(workout.id);
    _showSessionsList(context, workout);
  }

  void _showSessionsList(BuildContext context, GeneratedWorkout workout) {
     showModalBottomSheet(
       context: context,
       isScrollControlled: true,
       backgroundColor: AppTheme.background,
       shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
       builder: (context) => _WorkoutSessionsSheet(workout: workout),
     );
  }
}

class _WorkoutPlanCard extends StatelessWidget {
  final GeneratedWorkout workout;
  final bool isActive;
  final VoidCallback onDelete;
  final VoidCallback onSelect;
  final VoidCallback onView;

  const _WorkoutPlanCard({
    required this.workout,
    required this.isActive,
    required this.onDelete,
    required this.onSelect,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isActive ? AppTheme.accent.withOpacity(0.6) : Colors.white10,
          width: isActive ? 2.5 : 1,
        ),
        boxShadow: isActive ? [
          BoxShadow(color: AppTheme.accent.withOpacity(0.15), blurRadius: 30, offset: const Offset(0, 10))
        ] : [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                   Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (isActive ? AppTheme.accent : AppTheme.surfaceHighlight).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          isActive ? Icons.auto_awesome_rounded : Icons.fitness_center_rounded,
                          color: isActive ? AppTheme.accent : AppTheme.textSecondary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              workout.name,
                              style: GoogleFonts.outfit(
                                color: AppTheme.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            if (isActive)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.accent.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppTheme.accent.withOpacity(0.3))
                                ),
                                child: Text('PLANO ATIVO', style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.w900, color: AppTheme.accent, letterSpacing: 1)),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
                        onPressed: onDelete,
                        tooltip: 'Excluir Treino',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInfoField('Divisão', _formatSplit(workout.splitType), Icons.grid_view_rounded),
                      _buildInfoField('Período', '${workout.mesocycleDurationWeeks} Semanas', Icons.calendar_month_rounded),
                      _buildInfoField('Estilo', _formatStyle(workout.preferredStyle), Icons.psychology_rounded),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              color: Colors.white.withOpacity(0.03),
              child: Row(
                children: [
                  if (!isActive)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onSelect,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.accent),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('ATIVAR ESTE PLANO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ),
                  if (!isActive) const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onView,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isActive ? AppTheme.accent : AppTheme.surfaceHighlight,
                        foregroundColor: isActive ? Colors.black : AppTheme.textPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(isActive ? 'VER SESSÕES DE HOJE' : 'DETALHES', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoField(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: AppTheme.textSecondary),
            const SizedBox(width: 4),
            Text(label.toUpperCase(), style: GoogleFonts.outfit(fontSize: 10, color: AppTheme.textSecondary, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.outfit(fontSize: 13, color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

String _formatStyle(String? s) {
  switch (s) {
    case 'compound_focus': return 'Poliarticular';
    case 'isolation_focus': return 'Isoladores';
    case 'circuit': return 'Circuito';
    default: return 'Equilibrado';
  }
}


class _WorkoutSessionsSheet extends StatelessWidget {
  final GeneratedWorkout workout;
  const _WorkoutSessionsSheet({required this.workout});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, controller) => Column(
        children: [
           Container(
             margin: const EdgeInsets.only(top: 12),
             width: 40, height: 4,
             decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
           ),
           Padding(
             padding: const EdgeInsets.all(24),
             child: Row(
               children: [
                 Text(
                   workout.name,
                   style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                 ),
                 const Spacer(),
                 IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: AppTheme.textSecondary)),
               ],
             ),
           ),
           Expanded(
             child: ListView.builder(
               controller: controller,
               padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
               itemCount: workout.sessions.length,
               itemBuilder: (context, index) {
                 final session = workout.sessions[index];
                 return Container(
                   margin: const EdgeInsets.only(bottom: 16),
                   padding: const EdgeInsets.all(20),
                   decoration: BoxDecoration(
                     color: AppTheme.surface,
                     borderRadius: BorderRadius.circular(20),
                     border: Border.all(color: Colors.white.withOpacity(0.05)),
                   ),
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Row(
                         children: [
                           Expanded(
                             child: Text(session.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textPrimary)),
                           ),
                           Text('${session.estimatedDurationMinutes} min', style: const TextStyle(color: AppTheme.accent, fontSize: 12, fontWeight: FontWeight.bold)),
                         ],
                       ),
                       const SizedBox(height: 4),
                       Text(session.objective, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                       const Divider(height: 32, color: Colors.white10),
                       ...session.exercises.take(3).map((e) => Padding(
                         padding: const EdgeInsets.only(bottom: 8),
                         child: Row(
                           children: [
                             const Icon(Icons.check_circle_outline, size: 14, color: AppTheme.accent),
                             const SizedBox(width: 8),
                             Text(e.exercise.name, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                           ],
                         ),
                       )),
                       if (session.exercises.length > 3)
                         Text('+ ${session.exercises.length - 3} exercícios...', style: const TextStyle(color: Colors.white24, fontSize: 10)),
                       const SizedBox(height: 20),
                       SizedBox(
                         width: double.infinity,
                         child: ElevatedButton(
                           onPressed: () {
                              // Carrega exercícios prescritos no WorkoutProvider
                              context.read<WorkoutProvider>().startSessionFromPrescribed(
                                sessionId: session.id,
                                sessionName: session.name,
                                prescribedExercises: session.exercises.map((e) => e.toMap()).toList(),
                              );
                              // Captura o router antes de fechar o bottom sheet
                              final router = GoRouter.of(context);
                              Navigator.of(context).pop();
                              router.go('/workout');
                            },
                           child: const Text('COMEÇAR TREINO'),
                         ),
                       ),
                     ],
                   ),
                 );
               },
             ),
           ),
        ],
      ),
    );
  }
}

String _formatPeriodization(String p) {
  switch (p) {
    case 'linear': return 'Linear';
    case 'dup': return 'Ondulatória (DUP)';
    case 'block': return 'Em Bloco';
    default: return p.toUpperCase();
  }
}

String _formatSplit(String s) {
  switch (s) {
    case 'full_body': return 'Corpo Todo';
    case 'upper_lower': return 'Superior/Inferior';
    case 'ppl': return 'Empurrar/Puxar/Pernas';
    default: return s;
  }
}

String _periodizationExplainer(String p) {
  switch (p) {
    case 'linear': return 'Ideal para progressão de força constante.';
    case 'dup': return 'Variação diária para evitar estagnação.';
    case 'block': return 'Fases específicas de força e volume.';
    default: return '';
  }
}
