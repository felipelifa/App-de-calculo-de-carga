import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../shared/theme/app_theme.dart';
import 'nutrition_provider.dart';
import 'widgets/nutrition_timeline_widget.dart';
import 'meal_model.dart';
import '../workout/workout_profile_provider.dart';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<NutritionProvider>();
      if (provider.profile == null && !provider.isLoading) {
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
    final provider = context.watch<NutritionProvider>();

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.accent));
    }

    if (provider.profile == null) {
      final error = provider.lastError;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                error != null ? Icons.error_outline : Icons.no_meals_outlined,
                size: 64,
                color: error != null ? Colors.redAccent : AppTheme.textSecondary,
              ),
              const SizedBox(height: 16),
              Text(
                error ?? 'Perfil Nutricional não inicializado.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: error != null ? Colors.redAccent : AppTheme.textSecondary,
                  fontWeight: error != null ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  final wp = context.read<WorkoutProfileProvider>().profile;
                  if (wp != null) {
                    context.push('/nutrition/anamnese');
                  } else {
                    context.go('/anamnese');
                  }
                },
                child: Text(error != null ? 'TENTAR NOVAMENTE' : 'CONFIGURAR DIETA'),
              ),
            ],
          ),
        ),
      );
    }

    final target = provider.targetCalories;
    final consumed = provider.consumedCalories;
    final remaining = provider.remainingCalories;
    final meals = provider.selectedDayMeals;

    // Charts Data
    final List<_ChartData> chartData = [
      _ChartData('Consumido', consumed.toDouble(), AppTheme.accent),
      _ChartData('Restante', remaining > 0 ? remaining.toDouble() : 0, AppTheme.surfaceHighlight),
    ];

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Nutrição Inteligente', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.surface,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async => provider.loadToday(),
        color: AppTheme.accent,
        backgroundColor: AppTheme.surface,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const SizedBox(height: 12),
            // Timeline Semanal Interativa
            const NutritionTimelineWidget(),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Header - Gráfico de Calorias
                  _buildCalorieDonut(chartData, target, consumed, remaining),

                  const SizedBox(height: 16),
                  
                  // Botões de Ação Rápida (Visibilidade Superior)
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.tune_rounded,
                          label: 'Ajustar Macros',
                          onTap: () => context.push('/nutrition/settings'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.refresh_rounded,
                          label: 'Refazer Anamnese',
                          onTap: () => context.push('/nutrition/anamnese'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  
                  // Card de Bio-Gestão e Aderência
                  _buildBioManagementStats(provider),

                  const SizedBox(height: 24),
                  // Macros Cards
                  _buildMacrosRow(provider),

                  const SizedBox(height: 32),
                  // Seções de Refeições (do dia selecionado)
                  _buildMealSection(context, provider, 'Café da manhã', 'breakfast', meals),
                  _buildMealSection(context, provider, 'Almoço', 'lunch', meals),
                  _buildMealSection(context, provider, 'Jantar', 'dinner', meals),
                  _buildMealSection(context, provider, 'Lanches', 'snack', meals),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.accent.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.accent, size: 20),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildBioManagementStats(NutritionProvider provider) {
    final score = provider.adherenceScore;
    final fatigue = provider.fatigueLevel;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.divider.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMonitoringIcon(
            Icons.verified_user_rounded,
            'Aderência',
            '${(score * 100).toInt()}%',
            score > 0.8 ? AppTheme.success : Colors.orange,
          ),
          _buildVerticalDivider(),
          _buildMonitoringIcon(
            Icons.battery_alert_rounded,
            'Fadiga',
            fatigue > 7 ? 'ALTA' : (fatigue > 3 ? 'MOD' : 'BAIXA'),
            fatigue > 7 ? Colors.redAccent : (fatigue > 3 ? Colors.orange : AppTheme.success),
          ),
          _buildVerticalDivider(),
          _buildMonitoringIcon(
            Icons.auto_awesome_rounded,
            'Bio-Gestão',
            'ATIVA',
            AppTheme.accent,
          ),
        ],
      ),
    );
  }

  Widget _buildMonitoringIcon(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(height: 30, width: 1, color: AppTheme.divider.withOpacity(0.1));
  }

  Widget _buildMacrosRow(NutritionProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildMacroCard('Proteína', provider.consumedProtein, provider.targetProtein, AppTheme.accent),
        const SizedBox(width: 12),
        _buildMacroCard('Carbo', provider.consumedCarb, provider.targetCarb, AppTheme.success),
        const SizedBox(width: 12),
        _buildMacroCard('Gordura', provider.consumedFat, provider.targetFat, Colors.orange),
      ],
    );
  }

  Widget _buildMacroCard(String label, double consumed, double target, Color color) {
    final pct = target > 0 ? (consumed / target).clamp(0.0, 1.0) : 0.0;
    
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(
              '${consumed.round()} / ${target.round()}g',
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                backgroundColor: color.withOpacity(0.1),
                color: color,
                minHeight: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalorieDonut(List<_ChartData> chartData, int target, int consumed, int remaining) {
    return Column(
      children: [
        SizedBox(
          height: 190,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SfCircularChart(
                margin: EdgeInsets.zero,
                series: <DoughnutSeries<_ChartData, String>>[
                  DoughnutSeries<_ChartData, String>(
                    dataSource: chartData,
                    xValueMapper: (_ChartData data, _) => data.x,
                    yValueMapper: (_ChartData data, _) => data.y,
                    pointColorMapper: (_ChartData data, _) => data.color,
                    cornerStyle: CornerStyle.bothCurve,
                    innerRadius: '82%',
                    radius: '100%',
                  )
                ],
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   const Text('META DIÁRIA', style: TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                  Text(
                    target.toString(),
                    style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  const Text('kcal', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                ],
              )
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildMiniStat('CONSUMIDO', consumed.toString(), AppTheme.accent),
            const SizedBox(width: 40),
            _buildMiniStat('RESTANTE', remaining.toString(), remaining >= 0 ? AppTheme.textSecondary : Colors.redAccent),
          ],
        ),
      ],
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 20)),
      ],
    );
  }

  Widget _buildMealSection(BuildContext context, NutritionProvider provider, String title, String type, List<MealEntry> allMeals) {
    final meals = allMeals.where((m) => m.mealType == type).toList();
    final totalKcal = meals.fold(0, (sum, m) => sum + m.calories.round());
    final bool isFuture = provider.selectedWeekday > DateTime.now().weekday;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Text('$totalKcal kcal', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                  if (!isFuture)
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: AppTheme.accent),
                      onPressed: () => context.push('/nutrition/search?type=$type'),
                    ),
                ],
              ),
            ],
          ),
          if (meals.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(isFuture ? 'Planejamento pendente.' : 'Nenhum registro hoje.', style: TextStyle(color: AppTheme.textSecondary.withOpacity(0.5), fontStyle: FontStyle.italic, fontSize: 13)),
            )
          else
            ...meals.map((m) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(m.foodName, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
              subtitle: Text('${m.portionG}g • ${m.protein.round()}g P | ${m.carb.round()}g C | ${m.fat.round()}g G', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              trailing: Text('${m.calories.round()} kcal', style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
              onLongPress: isFuture ? null : () => provider.removeMeal(m.id),
            )),
        ],
      ),
    );
  }
}

class _ChartData {
  _ChartData(this.x, this.y, this.color);
  final String x;
  final double y;
  final Color color;
}
