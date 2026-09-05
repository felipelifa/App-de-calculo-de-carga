import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:async';
import '../../shared/theme/app_theme.dart';
import 'workout_provider.dart';
import 'package:provider/provider.dart';

// ─────────────────────────────────────────────
// WarmupScreen
// Tela de aquecimento antes do treino prescrito
// Estrutura: Aquecimento Geral (3-5 min) +
//            Aquecimento Específico (2-3 min)
// ─────────────────────────────────────────────

class WarmupScreen extends StatefulWidget {
  final String sessionId;
  final String sessionName;
  final List<Map<String, dynamic>> prescribedExercises;
  final String? dupPhase;

  const WarmupScreen({
    super.key,
    required this.sessionId,
    required this.sessionName,
    required this.prescribedExercises,
    this.dupPhase,
  });

  @override
  State<WarmupScreen> createState() => _WarmupScreenState();
}

class _WarmupScreenState extends State<WarmupScreen>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  int _currentPhase = 0; // 0 = geral, 1 = específico
  int _currentStep = 0;
  Timer? _timer;
  int _secondsLeft = 0;
  bool _timerRunning = false;

  // ── Fases do warm-up ──
  late final List<_WarmupPhase> _phases;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _phases = _buildPhases();
    _startCurrentTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  List<_WarmupPhase> _buildPhases() {
    // Aquecimento Geral
    final general = _WarmupPhase(
      title: 'AQUECIMENTO GERAL',
      subtitle: '3-5 minutos',
      icon: Icons.directions_run_rounded,
      color: const Color(0xFF00E5FF),
      steps: [
        _WarmupStep(
          name: 'Cardio Leve',
          description: 'Corrida leve, pular corda ou bike. Eleve a frequência cardíaca gradualmente.',
          durationSeconds: 180,
          icon: Icons.directions_run_rounded,
        ),
        _WarmupStep(
          name: 'Mobilidade de Quadril',
          description: 'Círculos de quadril lentos, 10 em cada direção. Libere a articulação.',
          durationSeconds: 45,
          icon: Icons.rotate_right_rounded,
        ),
        _WarmupStep(
          name: 'Mobilidade de Ombro',
          description: 'Rotações de braço para frente e para trás, 10 em cada direção.',
          durationSeconds: 45,
          icon: Icons.accessibility_new_rounded,
        ),
        _WarmupStep(
          name: 'Mobilidade de Tornozelo',
          description: 'Círculos de tornozelo, 10 em cada direção. Estabiliza a base.',
          durationSeconds: 30,
          icon: Icons.directions_walk_rounded,
        ),
      ],
    );

    // Monta os exercícios de aquecimento específico a partir do primeiro exercício prescrito
    final List<_WarmupStep> specificSteps = [];
    if (widget.prescribedExercises.isNotEmpty) {
      final firstEx = widget.prescribedExercises.first;
      final exName = firstEx['exerciseName'] as String? ?? 'Primeiro exercício';
      final lastWeight = (firstEx['defaultWeightKg'] as num?)?.toDouble() ?? 20.0;
      final reps = (firstEx['repsMax'] as int?) ?? 12;

      specificSteps.addAll([
        _WarmupStep(
          name: 'Aquecimento Série 1',
          description: '$exName\n${(lastWeight * 0.5).toStringAsFixed(1)} kg × ${(reps * 1.2).round()} reps  |  50% da carga — preparo articular',
          durationSeconds: 60,
          icon: Icons.fitness_center_rounded,
          loadPercent: 50,
        ),
        _WarmupStep(
          name: 'Aquecimento Série 2',
          description: '$exName\n${(lastWeight * 0.75).toStringAsFixed(1)} kg × ${(reps * 0.6).round()} reps  |  75% da carga — ativação neuromuscular',
          durationSeconds: 45,
          icon: Icons.fitness_center_rounded,
          loadPercent: 75,
        ),
      ]);

      // Segundo exercício prescrito (se existir)
      if (widget.prescribedExercises.length > 1) {
        final secondEx = widget.prescribedExercises[1];
        final exName2 = secondEx['exerciseName'] as String? ?? 'Segundo exercício';
        final lastWeight2 = (secondEx['defaultWeightKg'] as num?)?.toDouble() ?? 20.0;
        final reps2 = (secondEx['repsMax'] as int?) ?? 12;

        specificSteps.add(_WarmupStep(
          name: 'Aquecimento Série 3',
          description: '$exName2\n${(lastWeight2 * 0.5).toStringAsFixed(1)} kg × ${(reps2).round()} reps  |  50% da carga',
          durationSeconds: 45,
          icon: Icons.fitness_center_rounded,
          loadPercent: 50,
        ));
      }
    } else {
      specificSteps.add(_WarmupStep(
        name: 'Aquecimento Específico',
        description: 'Realize 2 séries leves do primeiro exercício antes de começar o treino principal.',
        durationSeconds: 90,
        icon: Icons.fitness_center_rounded,
      ));
    }

    final specific = _WarmupPhase(
      title: 'AQUECIMENTO ESPECÍFICO',
      subtitle: '2-3 minutos',
      icon: Icons.fitness_center_rounded,
      color: const Color(0xFFCCFF00),
      steps: specificSteps,
    );

    return [general, specific];
  }

  void _startCurrentTimer() {
    _timer?.cancel();
    if (_currentPhase >= _phases.length) return;
    final step = _phases[_currentPhase].steps[_currentStep];
    _secondsLeft = step.durationSeconds;
    _timerRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft--;
          if (_secondsLeft == 3) HapticFeedback.mediumImpact();
        } else {
          _advanceStep();
        }
      });
    });
  }

  void _advanceStep() {
    _timer?.cancel();
    final phase = _phases[_currentPhase];
    if (_currentStep < phase.steps.length - 1) {
      setState(() {
        _currentStep++;
        _startCurrentTimer();
      });
    } else if (_currentPhase < _phases.length - 1) {
      setState(() {
        _currentPhase++;
        _currentStep = 0;
        _pageController.animateToPage(
          _currentPhase,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
        _startCurrentTimer();
      });
    } else {
      _finishWarmup();
    }
  }

  void _finishWarmup() {
    _timer?.cancel();
    // Inicia a sessão no provider antes de navegar
    context.read<WorkoutProvider>().startSessionFromPrescribed(
      sessionId: widget.sessionId,
      sessionName: widget.sessionName,
      prescribedExercises: widget.prescribedExercises,
      dupPhase: widget.dupPhase,
    );
    context.go('/workout');
  }

  void _skipWarmup() {
    _timer?.cancel();
    _showSkipWarning();
  }

  void _showSkipWarning() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFFFA500), size: 22),
            const SizedBox(width: 10),
            Text('Pular aquecimento?',
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
          ],
        ),
        content: Text(
          'O aquecimento reduz o risco de lesões em até 30% e melhora a performance nas primeiras séries.\n\nRecomendamos não pular.',
          style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CONTINUAR AQUECENDO', style: GoogleFonts.outfit(color: const Color(0xFFCCFF00), fontWeight: FontWeight.w900)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _finishWarmup();
            },
            child: Text('PULAR MESMO ASSIM', style: GoogleFonts.outfit(color: AppTheme.textSecondary)),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  double get _timerProgress {
    if (_currentPhase >= _phases.length) return 0;
    final total = _phases[_currentPhase].steps[_currentStep].durationSeconds;
    if (total == 0) return 0;
    return 1.0 - (_secondsLeft / total);
  }

  @override
  Widget build(BuildContext context) {
    if (_currentPhase >= _phases.length) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(child: CircularProgressIndicator(color: Color(0xFFCCFF00))),
      );
    }

    final phase = _phases[_currentPhase];
    final step = phase.steps[_currentStep];
    final totalSteps = _phases.fold(0, (sum, p) => sum + p.steps.length);
    final completedSteps = _phases
        .take(_currentPhase)
        .fold(0, (sum, p) => sum + p.steps.length) + _currentStep;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary, size: 22),
                    onPressed: _skipWarmup,
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'AQUECIMENTO',
                          style: GoogleFonts.outfit(
                            color: phase.color,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Barra de progresso geral
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: totalSteps > 0 ? completedSteps / totalSteps : 0,
                            backgroundColor: Colors.white.withValues(alpha: 0.05),
                            valueColor: AlwaysStoppedAnimation(phase.color),
                            minHeight: 3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _skipWarmup,
                    child: Text(
                      'PULAR',
                      style: GoogleFonts.outfit(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Tabs de fase ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: _phases.asMap().entries.map((entry) {
                  final i = entry.key;
                  final p = entry.value;
                  final isActive = i == _currentPhase;
                  final isDone = i < _currentPhase;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: i < _phases.length - 1 ? 8 : 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isActive
                              ? p.color.withValues(alpha: 0.12)
                              : isDone
                                  ? const Color(0xFF22C55E).withValues(alpha: 0.08)
                                  : const Color(0xFF161616),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isActive ? p.color.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.04),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isDone)
                              const Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF22C55E))
                            else
                              Icon(p.icon, size: 12, color: isActive ? p.color : AppTheme.textSecondary),
                            const SizedBox(width: 6),
                            Text(
                              i == 0 ? 'GERAL' : 'ESPECÍFICO',
                              style: GoogleFonts.outfit(
                                color: isDone
                                    ? const Color(0xFF22C55E)
                                    : isActive ? p.color : AppTheme.textSecondary,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const Spacer(),

            // ── Timer circular ──
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 180,
                  height: 180,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: _timerProgress),
                    duration: const Duration(milliseconds: 400),
                    builder: (_, value, __) => CircularProgressIndicator(
                      value: value,
                      strokeWidth: 8,
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                      valueColor: AlwaysStoppedAnimation(phase.color),
                    ),
                  ),
                ),
                Column(
                  children: [
                    Text(
                      _formatTime(_secondsLeft),
                      style: GoogleFonts.outfit(
                        color: phase.color,
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -2,
                      ),
                    ),
                    Text(
                      'restantes',
                      style: GoogleFonts.outfit(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),

            const SizedBox(height: 40),

            // ── Step atual ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: phase.color.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(step.icon, color: phase.color, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        step.name,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(duration: 400.ms),

                  const SizedBox(height: 16),

                  Text(
                    step.description,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ).animate().fadeIn(duration: 400.ms, delay: 100.ms),

                  if (step.loadPercent != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: phase.color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: phase.color.withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        '${step.loadPercent}% da carga de trabalho',
                        style: GoogleFonts.outfit(
                          color: phase.color,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const Spacer(),

            // ── Botões de controle ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: Column(
                children: [
                  // Indicadores de step
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: phase.steps.asMap().entries.map((e) {
                      final isDoneStep = e.key < _currentStep;
                      final isCurrentStep = e.key == _currentStep;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: isCurrentStep ? 20 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isDoneStep
                              ? const Color(0xFF22C55E)
                              : isCurrentStep
                                  ? phase.color
                                  : Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  // Botão avançar
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _advanceStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: phase.color,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 0,
                      ),
                      child: Text(
                        _currentPhase == _phases.length - 1 &&
                                _currentStep == phase.steps.length - 1
                            ? 'COMEÇAR TREINO →'
                            : 'PRÓXIMO →',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          letterSpacing: 1,
                        ),
                      ),
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
}

// ─────────────────────────────────────────────
// Modelos internos
// ─────────────────────────────────────────────

class _WarmupPhase {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<_WarmupStep> steps;

  const _WarmupPhase({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.steps,
  });
}

class _WarmupStep {
  final String name;
  final String description;
  final int durationSeconds;
  final IconData icon;
  final int? loadPercent;

  const _WarmupStep({
    required this.name,
    required this.description,
    required this.durationSeconds,
    required this.icon,
    this.loadPercent,
  });
}
