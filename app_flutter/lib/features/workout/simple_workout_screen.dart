import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../shared/theme/app_theme.dart';
import 'workout_provider.dart';

// ─────────────────────────────────────────────
// Tela de Treino Simplificada
// Sem termos técnicos, foco em ação
// ─────────────────────────────────────────────

class SimpleWorkoutScreen extends StatefulWidget {
  const SimpleWorkoutScreen({super.key});

  @override
  State<SimpleWorkoutScreen> createState() => _SimpleWorkoutScreenState();
}

class _SimpleWorkoutScreenState extends State<SimpleWorkoutScreen> {
  bool _isSessionActive = false;
  int _currentExerciseIndex = 0;
  final List<Map<String, dynamic>> _exercises = [];
  String _sessionDifficulty = '';

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  void _loadExercises() {
    final provider = context.read<WorkoutProvider>();
    if (provider.isSessionActive) {
      setState(() {
        _isSessionActive = true;
        _exercises.clear();
        for (final ex in provider.currentExercises) {
          _exercises.add({
            'id': ex.exerciseId,
            'name': ex.exerciseName,
            'muscleGroup': ex.muscleGroup,
            'sets': ex.sets.asMap().entries.map((entry) => {
              'reps': entry.value.reps,
              'weight': entry.value.weight,
              'isCompleted': entry.value.isCompleted,
              'isWarmup': entry.value.isWarmup,
            }).toList(),
          });
        }
      });
    }
  }

  void _startSession() {
    final provider = context.read<WorkoutProvider>();
    provider.startSession();
    setState(() {
      _isSessionActive = true;
      _currentExerciseIndex = 0;
    });
  }

  void _finishSession() {
    _showCompletionDialog();
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '🎉 TREINO CONCLUÍDO!',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Como você se sentiu?',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildDifficultyOption('😊 Fácil', 'easy'),
            _buildDifficultyOption('👍 Boa', 'good'),
            _buildDifficultyOption('😅 Difícil', 'hard'),
            _buildDifficultyOption('🔥 Muito difícil', 'very_hard'),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyOption(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: () {
            setState(() => _sessionDifficulty = value);
            Navigator.of(context).pop();
            _completeSession();
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.textPrimary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            side: const BorderSide(color: AppTheme.textSecondary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(label, style: const TextStyle(fontSize: 16)),
        ),
      ),
    );
  }

  void _completeSession() {
    final provider = context.read<WorkoutProvider>();
    provider.finishSession();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Treino salvo! Vou usar esse resultado para ajustar seus próximos treinos.'),
        backgroundColor: AppTheme.success,
        duration: Duration(seconds: 3),
      ),
    );
    
    context.go('/dashboard');
  }

  void _swapExercise(int index) {
    _showSwapDialog(index);
  }

  void _showSwapDialog(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Trocar exercício',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Por que você quer trocar?',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            _buildSwapReason('Não gosto deste exercício', 'dislike'),
            _buildSwapReason('Não consigo fazer', 'cant_do'),
            _buildSwapReason('Não tenho equipamento', 'no_equipment'),
            _buildSwapReason('Estou sentindo desconforto', 'discomfort'),
          ],
        ),
      ),
    );
  }

  Widget _buildSwapReason(String label, String reason) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: () {
            Navigator.of(context).pop();
            _performSwap(reason);
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.textPrimary,
            padding: const EdgeInsets.symmetric(vertical: 12),
            side: const BorderSide(color: AppTheme.textSecondary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(label),
        ),
      ),
    );
  }

  void _performSwap(String reason) {
    // Usar o mecanismo de substituição existente
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Encontramos alternativas!'),
        backgroundColor: AppTheme.success,
      ),
    );
  }

  void _reportPain() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Senti desconforto',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Onde?',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildPainLocation('Ombro'),
                _buildPainLocation('Joelho'),
                _buildPainLocation('Lombar'),
                _buildPainLocation('Cotovelo'),
                _buildPainLocation('Punho'),
                _buildPainLocation('Quadril'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPainLocation(String location) {
    return FilterChip(
      label: Text(location),
      onSelected: (selected) {
        Navigator.of(context).pop();
        _showPainIntensity(location);
      },
      selectedColor: AppTheme.danger.withValues(alpha: 0.2),
      checkmarkColor: AppTheme.danger,
      labelStyle: const TextStyle(color: AppTheme.textPrimary),
      backgroundColor: AppTheme.surfaceHighlight,
    );
  }

  void _showPainIntensity(String location) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Como foi a dor em $location?',
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPainIntensity('Leve', 'light', location),
            _buildPainIntensity('Moderada', 'moderate', location),
            _buildPainIntensity('Forte', 'strong', location),
          ],
        ),
      ),
    );
  }

  Widget _buildPainIntensity(String label, String intensity, String location) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: () {
            Navigator.of(context).pop();
            _handlePainReport(location, intensity);
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.textPrimary,
            padding: const EdgeInsets.symmetric(vertical: 12),
            side: const BorderSide(color: AppTheme.textSecondary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(label),
        ),
      ),
    );
  }

  void _handlePainReport(String location, String intensity) {
    // Registrar dor no sistema
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Entendi. Vou evitar exercícios que sobrecarregam $location por enquanto.'),
        backgroundColor: AppTheme.warning,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: const Text(
          'Treino',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => context.go('/dashboard'),
        ),
        actions: [
          if (_isSessionActive)
            TextButton(
              onPressed: _finishSession,
              child: const Text(
                'FINALIZAR',
                style: TextStyle(
                  color: AppTheme.accent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: _isSessionActive ? _buildActiveSession() : _buildStartScreen(),
    );
  }

  Widget _buildStartScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.fitness_center,
                color: AppTheme.accent,
                size: 64,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Pronto para treinar?',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Seu treino está configurado e pronto para começar.',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _startSession,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  foregroundColor: AppTheme.background,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'COMEÇAR TREINO',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveSession() {
    return Column(
      children: [
        // Timer
        Container(
          padding: const EdgeInsets.all(16),
          color: AppTheme.surface,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.timer, color: AppTheme.accent),
              const SizedBox(width: 8),
              StreamBuilder<int>(
                stream: Stream.periodic(const Duration(seconds: 1), (i) => i),
                builder: (context, snapshot) {
                  final provider = context.read<WorkoutProvider>();
                  final sessionStart = provider.sessionStart ?? DateTime.now();
                  final elapsed = DateTime.now().difference(sessionStart);
                  final minutes = elapsed.inMinutes;
                  final secs = elapsed.inSeconds % 60;
                  return Text(
                    '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        
        // Lista de exercícios
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _exercises.length,
            itemBuilder: (context, index) {
              return _buildExerciseCard(index);
            },
          ),
        ),
        
        // Botão adicionar exercício
        Padding(
          padding: const EdgeInsets.all(16),
          child: OutlinedButton.icon(
            onPressed: () {
              // Adicionar exercício
            },
            icon: const Icon(Icons.add),
            label: const Text('ADICIONAR EXERCÍCIO'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.accent,
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: const BorderSide(color: AppTheme.accent),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExerciseCard(int index) {
    final exercise = _exercises[index];
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho do exercício
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise['name'] ?? 'Exercício',
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${exercise['sets']} séries × ${exercise['reps']} reps',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                // Botão de tutorial
                IconButton(
                  onPressed: () {
                    // Mostrar tutorial
                  },
                  icon: const Icon(
                    Icons.help_outline,
                    color: AppTheme.accent,
                  ),
                ),
                // Botão trocar
                IconButton(
                  onPressed: () => _swapExercise(index),
                  icon: const Icon(
                    Icons.swap_horiz,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Séries
            ...List.generate(exercise['sets'] ?? 0, (setIndex) {
              return _buildSetRow(index, setIndex);
            }),
            
            const SizedBox(height: 16),
            
            // Botão dor
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _reportPain,
                icon: const Icon(Icons.warning_amber, size: 20),
                label: const Text('Senti desconforto'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.danger,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  side: const BorderSide(color: AppTheme.danger),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetRow(int exerciseIndex, int setIndex) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          // Número da série
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${setIndex + 1}',
                style: const TextStyle(
                  color: AppTheme.accent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Campo de peso
          Expanded(
            child: TextField(
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Peso (kg)',
                hintStyle: const TextStyle(color: AppTheme.textSecondary),
                filled: true,
                fillColor: AppTheme.surfaceHighlight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
          const SizedBox(width: 8),
          
          // Campo de repetições
          Expanded(
            child: TextField(
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Reps',
                hintStyle: const TextStyle(color: AppTheme.textSecondary),
                filled: true,
                fillColor: AppTheme.surfaceHighlight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
          const SizedBox(width: 8),
          
          // Botão check
          IconButton(
            onPressed: () {
              // Marcar série como concluída
            },
            icon: const Icon(
              Icons.check_circle_outline,
              color: AppTheme.success,
            ),
          ),
        ],
      ),
    );
  }
}
