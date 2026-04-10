import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../shared/theme/app_theme.dart';
import 'nutrition_provider.dart';

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
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.no_meals_outlined, size: 64, color: AppTheme.textSecondary),
            const SizedBox(height: 16),
            const Text(
              'Perfil Nutricional não inicializado.',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                final wp = context.read<WorkoutProfileProvider>().profile;
                if (wp != null) {
                  provider.initFromProfile(wp);
                } else {
                  context.go('/anamnese');
                }
              },
              child: const Text('CONFIGURAR DIETA'),
            ),
          ],
        ),
      );
    }

    final target = provider.targetCalories;
    final consumed = provider.consumedCalories;
    final remaining = provider.remainingCalories;

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
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppTheme.textSecondary),
            onPressed: () => context.push('/nutrition/settings'),
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => provider.loadToday(),
        color: AppTheme.accent,
        backgroundColor: AppTheme.surface,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Banner Pós-Treino
            if (provider.postWorkoutBonusKcal != null && provider.postWorkoutBonusKcal! > 0)
              _buildPostWorkoutBanner(provider.postWorkoutBonusKcal!),

            // Header - Calorias
            _buildCalorieDonut(chartData, target, consumed, remaining),

            const SizedBox(height: 24),
            // Macros Cards
            _buildMacrosRow(provider),

            const SizedBox(height: 32),
            // Seções de Refeições
            _buildMealSection(context, provider, 'Café da manhã', 'breakfast'),
            _buildMealSection(context, provider, 'Almoço', 'lunch'),
            _buildMealSection(context, provider, 'Jantar', 'dinner'),
            _buildMealSection(context, provider, 'Lanches', 'snack'),
          ],
        ),
      ),
    );
  }

  Widget _buildPostWorkoutBanner(int bonus) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.bolt_rounded, color: AppTheme.success, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bônus Pós-Treino!',
                  style: TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  'Diet adaptado. +$bonus kcal adicionadas para recuperação.',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalorieDonut(List<_ChartData> chartData, int target, int consumed, int remaining) {
    return Column(
      children: [
        Text(
          DateFormat('EEEE, d MMM', 'pt_BR').format(DateTime.now()).toUpperCase(),
          style: const TextStyle(color: AppTheme.textSecondary, letterSpacing: 1.2, fontSize: 12),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
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
                    innerRadius: '80%',
                    radius: '100%',
                  )
                ],
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    remaining.toString(),
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  const Text('restantes', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                ],
              )
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildMiniStat('Meta', target.toString()),
            _buildMiniStat('Consumo', consumed.toString()),
          ],
        ),
      ],
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
      ],
    );
  }

  Widget _buildMacrosRow(NutritionProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildMacroCard('Proteína', provider.consumedProtein, provider.activeTargetProtein, AppTheme.accent),
        const SizedBox(width: 12),
        _buildMacroCard('Carbo', provider.consumedCarb, provider.activeTargetCarb, AppTheme.success),
        const SizedBox(width: 12),
        _buildMacroCard('Gordura', provider.consumedFat, provider.activeTargetFat, Colors.orange),
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
            Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            const SizedBox(height: 6),
            Text(
              '${consumed.round()} / ${target.round()}g',
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                backgroundColor: color.withValues(alpha: 0.1),
                color: color,
                minHeight: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealSection(BuildContext context, NutritionProvider provider, String title, String type) {
    final meals = provider.todayMeals.where((m) => m.mealType == type).toList();
    final totalKcal = meals.fold(0, (sum, m) => sum + m.calories.round());

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
              child: Text('Nenhum alimento registrado.', style: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.5), fontStyle: FontStyle.italic)),
            )
          else
            ...meals.map((m) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(m.foodName, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
              subtitle: Text('${m.portionG}g • ${m.protein.round()}g P | ${m.carb.round()}g C | ${m.fat.round()}g G', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              trailing: Text('${m.calories.round()} kcal', style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
              onLongPress: () {
                provider.removeMeal(m.id);
              },
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
