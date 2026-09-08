import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/auth_service.dart';
import '../../shared/theme/app_theme.dart';
import '../workout/workout_profile_provider.dart';
import '../nutrition/nutrition_provider.dart';
import '../workout/workout_provider.dart';
import '../../core/services/integration_service.dart';
import '../../core/services/coach_service.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _todayData = {};
  String _todayMessage = '';
  String _nutritionMessage = '';
  String _hydrationMessage = '';
  String _progressMessage = '';
  String _coachFeedback = '';
  String _dailyTip = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final uid = context.read<AuthService>().currentUser?.id;
    if (uid == null) return;

    try {
        final profileProvider = context.read<WorkoutProfileProvider>();
        final workoutProvider = context.read<WorkoutProvider>();
        await workoutProvider.loadHistory();
        if (!mounted) return;
      final profile = profileProvider.profile;
      final targetDays = profile?.availableDaysPerWeek ?? 3;
      final currentWeek = workoutProvider.currentWeekNumber;
      final weekWorkouts = workoutProvider.history
          .where((session) => session.weekNumber == currentWeek)
          .toList();

      final integrationService = IntegrationService();
      final todayMsg = await integrationService.getTodayMessage();
      final nutritionMsg = await integrationService.getNutritionMessage();
      final hydrationMsg = await integrationService.getHydrationMessage();
      final progressMsg = await integrationService.getProgressMessage();

      final coachService = CoachService();
      final coachFeedback = await coachService.getWorkoutFeedback();
      final dailyTip = coachService.getDailyTip();

      setState(() {
        _todayData = {
          'weekSessions': weekWorkouts.length,
          'targetDays': targetDays,
          'weekVolume': weekWorkouts.fold<double>(
            0,
            (total, session) => total + session.totalVolume,
          ),
          'hasWorkoutToday': profileProvider.activeWorkout != null,
        };
        _todayMessage = todayMsg;
        _nutritionMessage = nutritionMsg;
        _hydrationMessage = hydrationMsg;
        _progressMessage = progressMsg;
        _coachFeedback = coachFeedback;
        _dailyTip = dailyTip;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 32),
                      _buildTrainingCard(),
                      const SizedBox(height: 24),
                      _buildNutritionCard(),
                      const SizedBox(height: 24),
                      _buildHydrationCard(),
                      const SizedBox(height: 24),
                      _buildProgressCard(),
                      const SizedBox(height: 24),
                      _buildCoachCard(),
                      const SizedBox(height: 24),
                      _buildQuickActions(),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Bom dia!';
    } else if (hour < 18) {
      greeting = 'Boa tarde!';
    } else {
      greeting = 'Boa noite!';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _todayMessage.isNotEmpty ? _todayMessage : 'Seu treino está pronto.',
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 18),
        ),
      ],
    );
  }

  Widget _buildTrainingCard() {
    final hasWorkout = _todayData['hasWorkoutToday'] ?? false;
    final weekSessions = _todayData['weekSessions'] ?? 0;
    final targetDays = _todayData['targetDays'] ?? 3;

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.fitness_center,
                  color: AppTheme.accent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TREINO DE HOJE',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasWorkout ? 'Pronto para treinar!' : 'Descanso hoje',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: weekSessions / targetDays,
                  backgroundColor: AppTheme.surfaceHighlight,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppTheme.accent,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$weekSessions / $targetDays treinos',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: hasWorkout ? () => context.push('/prescribed') : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent,
                foregroundColor: AppTheme.background,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                hasWorkout ? 'COMEÇAR TREINO' : 'TREINO CONCLUÍDO',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.restaurant,
                  color: AppTheme.success,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ALIMENTAÇÃO',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _nutritionMessage.isNotEmpty
                          ? _nutritionMessage
                          : 'Ver resumo do dia',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: AppTheme.textSecondary,
                size: 16,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Consumer<NutritionProvider>(
            builder: (context, nutrition, _) {
              final consumed = nutrition.consumedCalories;
              final target = nutrition.targetCalories;

              return Column(
                children: [
                  _buildNutritionRow(
                    'Calorias',
                    '${consumed.round()} / ${target.round()} kcal',
                    consumed / target,
                    AppTheme.accent,
                  ),
                  const SizedBox(height: 8),
                  _buildNutritionRow(
                    'Proteína',
                    '${nutrition.consumedProtein.round()}g / ${nutrition.targetProtein.round()}g',
                    nutrition.consumedProtein / nutrition.targetProtein,
                    AppTheme.success,
                  ),
                  const SizedBox(height: 8),
                  _buildNutritionRow(
                    'Carboidratos',
                    '${nutrition.consumedCarb.round()}g / ${nutrition.targetCarb.round()}g',
                    nutrition.consumedCarb / nutrition.targetCarb,
                    AppTheme.accent,
                  ),
                  const SizedBox(height: 8),
                  _buildNutritionRow(
                    'Gorduras',
                    '${nutrition.consumedFat.round()}g / ${nutrition.targetFat.round()}g',
                    nutrition.consumedFat / nutrition.targetFat,
                    AppTheme.danger,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.push('/nutrition'),
              icon: const Icon(Icons.add, size: 20),
              label: const Text('REGISTRAR REFEIÇÃO'),
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
      ),
    );
  }

  Widget _buildNutritionRow(
    String label,
    String value,
    double progress,
    Color color,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
        ),
        Expanded(
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: AppTheme.surfaceHighlight,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 120,
          child: Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildHydrationCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.water_drop,
                  color: Colors.blue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'HIDRATAÇÃO',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _hydrationMessage.isNotEmpty
                          ? _hydrationMessage
                          : 'Beba água!',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildWaterButton('200ml', 200),
              const SizedBox(width: 8),
              _buildWaterButton('350ml', 350),
              const SizedBox(width: 8),
              _buildWaterButton('500ml', 500),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWaterButton(String label, int ml) {
    return Expanded(
      child: OutlinedButton(
        onPressed: () {},
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.blue,
          padding: const EdgeInsets.symmetric(vertical: 12),
          side: const BorderSide(color: Colors.blue),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(label),
      ),
    );
  }

  Widget _buildProgressCard() {
    final weekVolume = _todayData['weekVolume'] ?? 0.0;

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.trending_up,
                  color: AppTheme.accent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PROGRESSO',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _progressMessage.isNotEmpty
                          ? _progressMessage
                          : '${(weekVolume / 1000).toStringAsFixed(1)}k kg esta semana',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCoachCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.psychology,
                  color: AppTheme.accent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'COACH DIGITAL',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _coachFeedback.isNotEmpty ? _coachFeedback : 'Continue treinando!',
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              height: 1.5,
            ),
          ),
          if (_dailyTip.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    color: AppTheme.accent,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _dailyTip,
                      style: const TextStyle(
                        color: AppTheme.accent,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ações rápidas',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildActionButton(
              icon: Icons.list_alt,
              label: 'Meus Treinos',
              onTap: () => context.push('/prescribed'),
            ),
            const SizedBox(width: 12),
            _buildActionButton(
              icon: Icons.fitness_center,
              label: 'Exercícios',
              onTap: () => context.push('/exercises'),
            ),
            const SizedBox(width: 12),
            _buildActionButton(
              icon: Icons.history,
              label: 'Histórico',
              onTap: () => context.push('/workout/history'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildActionButton(
              icon: Icons.analytics,
              label: 'Progresso',
              onTap: () => context.push('/analytics'),
            ),
            const SizedBox(width: 12),
            _buildActionButton(
              icon: Icons.settings,
              label: 'Config',
              onTap: () => context.push('/profile'),
            ),
            const SizedBox(width: 12),
            const Expanded(child: SizedBox()),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceHighlight,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppTheme.accent, size: 24),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.textSecondary.withValues(alpha: 0.1),
        ),
      ),
      child: child,
    );
  }
}
