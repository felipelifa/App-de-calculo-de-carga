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
        body: Center(child: CircularProgressIndicator(color: Color(0xFFCCFF00))),
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
            expandedHeight: 80,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textPrimary, size: 20),
              onPressed: () => context.go('/dashboard'),
            ),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                'MEUS TREINOS',
                style: GoogleFonts.outfit(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFFCCFF00)),
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final workout = allWorkouts[index];
                    return _WorkoutPlanCard(
                      workout: workout,
                      isActive: workout.id == activeWorkout?.id,
                       onDelete: () => _confirmDeletion(context, workout.id),
                      onSelect: () async {
                        await wpAuth.setActiveWorkout(workout.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Plano "${workout.name}" ativado!'),
                              backgroundColor: const Color(0xFFCCFF00),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
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
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFCCFF00)),
            child: const Text('GERAR MEU TREINO', style: TextStyle(color: Colors.black)),
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
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await context.read<WorkoutProfileProvider>().deleteWorkout(id);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro ao excluir: $e')),
                  );
                }
              }
            },
            child: const Text('EXCLUIR'),
          ),
        ],
      ),
    );
  }

  void _showWorkoutDetails(BuildContext context, GeneratedWorkout workout) {
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
    const neon = Color(0xFFCCFF00);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isActive ? neon.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.03),
          width: isActive ? 2 : 1,
        ),
        boxShadow: isActive ? [
          BoxShadow(color: neon.withValues(alpha: 0.1), blurRadius: 40, offset: const Offset(0, 10))
        ] : [],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                 Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (isActive ? neon : Colors.white).withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isActive ? Icons.auto_awesome_rounded : Icons.fitness_center_rounded,
                        color: isActive ? neon : AppTheme.textSecondary,
                        size: 20,
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
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          if (isActive)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: neon.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: neon.withValues(alpha: 0.2))
                              ),
                              child: Text('PLANO ATIVO', style: GoogleFonts.outfit(fontSize: 8, fontWeight: FontWeight.w900, color: neon, letterSpacing: 1)),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.white12, size: 20),
                      onPressed: onDelete,
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
                if (workout.planExplanation != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: neon.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: neon.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.auto_awesome, color: neon.withValues(alpha: 0.7), size: 16),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            workout.planExplanation!,
                            style: GoogleFonts.outfit(
                              color: AppTheme.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.01),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Row(
              children: [
                if (!isActive)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onSelect,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: neon.withValues(alpha: 0.3)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('ATIVAR ESTE PLANO', style: TextStyle(color: neon, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
                    ),
                  ),
                if (!isActive) const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onView,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isActive ? neon : const Color(0xFF222222),
                      foregroundColor: isActive ? Colors.black : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: isActive ? 10 : 0,
                      shadowColor: neon.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(isActive ? 'VER SESSÕES DE HOJE' : 'DETALHES', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoField(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 10, color: AppTheme.textSecondary.withValues(alpha: 0.5)),
            const SizedBox(width: 4),
            Text(label.toUpperCase(), style: GoogleFonts.outfit(fontSize: 8, color: AppTheme.textSecondary.withValues(alpha: 0.6), fontWeight: FontWeight.w900, letterSpacing: 1)),
          ],
        ),
        const SizedBox(height: 6),
        Text(value, style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _WorkoutSessionsSheet extends StatelessWidget {
  final GeneratedWorkout workout;
  const _WorkoutSessionsSheet({required this.workout});

  @override
  Widget build(BuildContext context) {
    const neon = Color(0xFFCCFF00);

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
             decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(2)),
           ),
           Padding(
             padding: const EdgeInsets.all(24),
             child: Row(
               children: [
                 Expanded(
                   child: Text(
                     workout.name,
                     style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.textPrimary),
                   ),
                 ),
                 IconButton(
                  onPressed: () => Navigator.pop(context), 
                  icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary, size: 20)
                ),
               ],
             ),
           ),
           Expanded(
             child: ListView.builder(
               controller: controller,
               padding: const EdgeInsets.symmetric(horizontal: 20),
               itemCount: workout.sessions.length,
               itemBuilder: (context, index) {
                 final session = workout.sessions[index];
                 
                 final obj = session.objective.toLowerCase();
                 String dupPhase = 'Equilíbrio ⚖️';
                 Color dupColor = Colors.white70;
                 if (obj.contains('força')) { dupPhase = 'Sessão de Força 💪'; dupColor = Colors.orangeAccent; }
                 else if (obj.contains('hipertrofia')) { dupPhase = 'Sessão de Hipertrofia 🔥'; dupColor = const Color(0xFF00E5FF); }
                 else if (obj.contains('resistência')) { dupPhase = 'Sessão de Resistência 🏃'; dupColor = const Color(0xFFCCFF00); }

                 return Container(
                   margin: const EdgeInsets.only(bottom: 16),
                   padding: const EdgeInsets.all(20),
                   decoration: BoxDecoration(
                     color: const Color(0xFF161616),
                     borderRadius: BorderRadius.circular(24),
                     border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
                   ),
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Row(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Expanded(
                             child: Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                 Text(session.name, style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.textPrimary)),
                                 const SizedBox(height: 6),
                                 Container(
                                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                   decoration: BoxDecoration(
                                     color: dupColor.withOpacity(0.1),
                                     borderRadius: BorderRadius.circular(6),
                                     border: Border.all(color: dupColor.withOpacity(0.3)),
                                   ),
                                   child: Text(dupPhase, style: GoogleFonts.outfit(color: dupColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                                 ),
                               ],
                             ),
                           ),
                           Text('${session.estimatedDurationMinutes} min', style: GoogleFonts.outfit(color: neon, fontSize: 11, fontWeight: FontWeight.w900)),
                         ],
                       ),
                        const SizedBox(height: 12),
                        Text(session.objective, style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
                        if (session.userExplanation != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: neon.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              session.userExplanation!,
                              style: GoogleFonts.outfit(
                                color: neon.withValues(alpha: 0.8),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                        const Divider(height: 32, color: Colors.white10),
                        ...session.exercises.take(3).map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children : [
                              const Icon(Icons.check_circle_rounded, size: 14, color: neon),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(e.exercise.name, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13)),
                                    if (e.decisionReason != null)
                                      Text(
                                        e.decisionReason!,
                                        style: GoogleFonts.outfit(
                                          color: Colors.white24,
                                          fontSize: 10,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )),
                       if (session.exercises.length > 3)
                         Padding(
                           padding: const EdgeInsets.only(left: 26, top: 4),
                           child: Text('+ ${session.exercises.length - 3} exercícios...', style: GoogleFonts.outfit(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.w500)),
                         ),
                       const SizedBox(height: 24),
                       SizedBox(
                         width: double.infinity,
                         height: 54,
                         child: ElevatedButton(
                           onPressed: () {
                             // Passa pelo aquecimento antes de iniciar
                             final router = GoRouter.of(context);
                             Navigator.of(context).pop();
                             router.go('/warmup', extra: {
                               'sessionId': session.id,
                               'sessionName': session.name,
                               'prescribedExercises': session.exercises.map((e) => e.toMap()).toList(),
                             });
                           },
                           style: ElevatedButton.styleFrom(
                             backgroundColor: neon,
                             foregroundColor: Colors.black,
                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                             elevation: 0,
                           ),
                           child: const Text('COMEÇAR TREINO', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1)),
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

String _formatStyle(String? s) {
  switch (s) {
    case 'compound_focus': return 'Poliarticular';
    case 'isolation_focus': return 'Isoladores';
    case 'circuit': return 'Circuito';
    default: return 'Equilibrado';
  }
}

String _formatSplit(String s) {
  switch (s) {
    case 'full_body': return 'Corpo Todo';
    case 'upper_lower': return 'Superior/Inferior';
    case 'ppl': return 'Empurrar/Puxar/Pernas';
    case 'running_none': return 'Corrida - Geral';
    case 'push_pull_legs': return 'Empurrar/Puxar/Pernas';
    default: return s.split('_').map((str) => str[0].toUpperCase() + str.substring(1)).join(' ');
  }
}
