import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../shared/theme/app_theme.dart';
import 'nutrition_provider.dart';
import '../workout/workout_profile_provider.dart';

// ─────────────────────────────────────────────
// Tela de Nutrição Simplificada
// Resumo + sugestões, sem tabelas gigantes
// ─────────────────────────────────────────────

class SimpleNutritionScreen extends StatefulWidget {
  const SimpleNutritionScreen({super.key});

  @override
  State<SimpleNutritionScreen> createState() => _SimpleNutritionScreenState();
}

class _SimpleNutritionScreenState extends State<SimpleNutritionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<NutritionProvider>();
      provider.loadExistingProfile();
      if (provider.profile == null) {
        final wp = context.read<WorkoutProfileProvider>().profile;
        if (wp != null) {
          provider.initFromProfile(wp);
        }
      }
      provider.loadToday();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: const Text(
          'Alimentação',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      body: Consumer<NutritionProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.profile == null) {
            return _buildSetupScreen();
          }

          return _buildNutritionDashboard(provider);
        },
      ),
    );
  }

  Widget _buildSetupScreen() {
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
                color: AppTheme.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.restaurant,
                color: AppTheme.success,
                size: 64,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Configure sua alimentação',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Vou calcular suas metas automaticamente com base no seu objetivo e treino.',
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
                onPressed: () => context.push('/nutrition/anamnese'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.success,
                  foregroundColor: AppTheme.background,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'CONFIGURAR',
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

  Widget _buildNutritionDashboard(NutritionProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCalorieCard(provider),
          const SizedBox(height: 24),
          _buildMacrosCard(provider),
          const SizedBox(height: 24),
          _buildSuggestionCard(provider),
          const SizedBox(height: 24),
          _buildMealsSection(provider),
          const SizedBox(height: 24),
          _buildAddMealButton(),
        ],
      ),
    );
  }

  Widget _buildCalorieCard(NutritionProvider provider) {
    final consumed = provider.consumedCalories;
    final target = provider.targetCalories;
    final remaining = target - consumed;
    final progress = (consumed / target).clamp(0.0, 1.0);

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🍽️ ALIMENTAÇÃO',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${consumed.round()} kcal',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${remaining.round()} kcal restantes',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              // Indicador circular
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  value: progress,
                  backgroundColor: AppTheme.surfaceHighlight,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress > 0.9 ? AppTheme.danger : AppTheme.success,
                  ),
                  strokeWidth: 8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Barra de progresso
          LinearProgressIndicator(
            value: progress,
            backgroundColor: AppTheme.surfaceHighlight,
            valueColor: AlwaysStoppedAnimation<Color>(
              progress > 0.9 ? AppTheme.danger : AppTheme.success,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _buildMacrosCard(NutritionProvider provider) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'MACRONUTRIENTES',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          _buildMacroRow(
            'Proteína',
            provider.consumedProtein,
            provider.targetProtein,
            'g',
            AppTheme.success,
          ),
          const SizedBox(height: 12),
          _buildMacroRow(
            'Carboidratos',
            provider.consumedCarb,
            provider.targetCarb,
            'g',
            AppTheme.accent,
          ),
          const SizedBox(height: 12),
          _buildMacroRow(
            'Gorduras',
            provider.consumedFat,
            provider.targetFat,
            'g',
            AppTheme.danger,
          ),
        ],
      ),
    );
  }

  Widget _buildMacroRow(String label, double consumed, double target, String unit, Color color) {
    final progress = (consumed / target).clamp(0.0, 1.0);
    final percentage = (progress * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${consumed.round()} / ${target.round()} $unit',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppTheme.surfaceHighlight,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '$percentage%',
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSuggestionCard(NutritionProvider provider) {
    String suggestion = _getSuggestion(provider);

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '💡 SUGESTÃO DO BUILDFIT',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            suggestion,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  String _getSuggestion(NutritionProvider provider) {
    final proteinProgress = provider.consumedProtein / provider.targetProtein;
    final carbProgress = provider.consumedCarb / provider.targetCarb;
    final fatProgress = provider.consumedFat / provider.targetFat;

    if (proteinProgress < 0.8) {
      return 'Sua proteína está abaixo do ideal. Tente incluir mais fontes de proteína nas próximas refeições.';
    } else if (carbProgress < 0.7) {
      return 'Seus carboidratos estão baixos. Considere adicionar uma fonte de carboidrato complexo.';
    } else if (fatProgress > 1.1) {
      return 'Suas gorduras estão um pouco acima. Reduza óleos e gorduras nas próximas refeições.';
    } else {
      return 'Sua alimentação está equilibrada! Continue assim.';
    }
  }

  Widget _buildMealsSection(NutritionProvider provider) {
    final meals = provider.todayMeals;

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'REFEIÇÕES DE HOJE',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          if (meals.isEmpty)
            const Text(
              'Nenhuma refeição registrada ainda.',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            )
          else
            ...meals.map((meal) => _buildMealItem(meal)),
        ],
      ),
    );
  }

  Widget _buildMealItem(dynamic meal) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.restaurant,
              color: AppTheme.accent,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal.foodName ?? 'Refeição',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${meal.calories?.round() ?? 0} kcal',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              // Deletar refeição
            },
            icon: const Icon(
              Icons.delete_outline,
              color: AppTheme.danger,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddMealButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => context.push('/nutrition/search'),
        icon: const Icon(Icons.add),
        label: const Text('REGISTRAR REFEIÇÃO'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.accent,
          foregroundColor: AppTheme.background,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
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
