import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../shared/theme/app_theme.dart';
import 'nutrition_provider.dart';
import 'widgets/nutrition_timeline_widget.dart';
import 'meal_model.dart';
import '../workout/workout_profile_provider.dart';
import 'bio_intelligence.dart';

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
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(child: CircularProgressIndicator(color: AppTheme.accent)),
      );
    }

    if (provider.profile == null) {
      final error = provider.lastError;
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  error != null ? Icons.error_outline : Icons.no_meals_outlined,
                  size: 64,
                  color: error != null ? AppTheme.accent : AppTheme.textSecondary,
                ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
                const SizedBox(height: 24),
                Text(
                  error ?? 'Configure seu perfil nutricional para começar a Bio-Gestão baseada em ciência.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    color: AppTheme.textSecondary,
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    final wp = context.read<WorkoutProfileProvider>().profile;
                    if (wp != null) {
                      context.push('/nutrition/anamnese');
                    } else {
                      context.go('/anamnese');
                    }
                  },
                  child: Text(error != null ? 'TENTAR NOVAMENTE' : 'CONFIGURAR BIO-DIETA'),
                ),
              ],
            ),
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
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppTheme.background,
            expandedHeight: 120,
            floating: true,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textPrimary, size: 20),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.insights_rounded, color: AppTheme.accentLime),
                onPressed: () => context.push('/nutrition/dashboard'),
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              title: Text(
                'Bio-Management',
                style: GoogleFonts.outfit(
                  color: AppTheme.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
          
          SliverToBoxAdapter(
            child: RefreshIndicator(
              onRefresh: () async => provider.loadToday(),
              color: AppTheme.accent,
              backgroundColor: AppTheme.surface,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    // Calendário Action Strip (Navegação de Dias)
                    _buildCalendarStrip(context, provider).animate().fadeIn(duration: 400.ms),

                    const SizedBox(height: 12),
                    // Timeline Semanal Interativa
                    const NutritionTimelineWidget().animate().slideX(begin: 0.1, duration: 500.ms),

                    const SizedBox(height: 24),

                    // Insight do Gêmeo Digital (Destaque Neon)
                    _buildInsightPanel(provider).animate().scale(delay: 200.ms, curve: Curves.easeOutBack),

                    const SizedBox(height: 24),

                    // Header - Gráfico de Calorias
                    GestureDetector(
                      onTap: () => _showManualOverrideDialog(context, provider),
                      child: _buildCalorieDonut(chartData, target, consumed.toInt(), remaining.toInt(), provider)
                          .animate()
                          .fadeIn(delay: 400.ms),
                    ),

                    const SizedBox(height: 32),

                    // Macros Row (Estilo Challenger)
                    _buildMacrosRow(provider).animate().slideY(begin: 0.2, delay: 600.ms),

                    const SizedBox(height: 32),

                    // Diversidade Plant Based (Gamificação)
                    BioIntelligence.buildPlantGamificationPanel(provider.weeklyPlantScore),

                    const SizedBox(height: 24),

                    // Bento Grid para Hidratação e Bio-Gestão
                    Row(
                      children: [
                        Expanded(child: _buildHydrationCard(provider)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildBioManagementStats(provider)),
                      ],
                    ),

                    const SizedBox(height: 40),
                    
                    // Seções de Refeições
                    _SectionHeader(title: 'Protocolo de Hoje'),
                    const SizedBox(height: 16),
                    _buildMealSection(context, provider, 'Café da manhã', 'breakfast', meals),
                    _buildMealSection(context, provider, 'Almoço', 'lunch', meals),
                    _buildMealSection(context, provider, 'Jantar', 'dinner', meals),
                    _buildMealSection(context, provider, 'Lanches', 'snack', meals),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
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
        _buildMacroCard('Proteína', provider.consumedProtein, provider.targetProtein, AppTheme.accent, isAdjusted: provider.isProteinAdjusted),
        const SizedBox(width: 12),
        _buildMacroCard('Carbo', provider.consumedCarb, provider.targetCarb, AppTheme.success, isAdjusted: provider.isCarbAdjusted),
        const SizedBox(width: 12),
        _buildMacroCard('Gordura', provider.consumedFat, provider.targetFat, Colors.orange, isAdjusted: provider.isFatAdjusted),
      ],
    );
  }

  Widget _buildMacroCard(String label, double consumed, double target, Color color, {bool isAdjusted = false}) {
    final pct = target > 0 ? (consumed / target).clamp(0.0, 1.0) : 0.0;
    final isDone = pct >= 1.0;
    final displayColor = isDone ? AppTheme.success : color;
    
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: isDone ? Border.all(color: AppTheme.success.withOpacity(0.3)) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
                if (isAdjusted) ...[
                  const SizedBox(width: 4),
                  Tooltip(
                    message: 'Ajustado',
                    child: Icon(Icons.bolt_rounded, size: 12, color: displayColor),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${consumed.round()} / ${target.round()}g',
              style: TextStyle(color: isDone ? AppTheme.success : AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                backgroundColor: displayColor.withOpacity(0.1),
                color: displayColor,
                minHeight: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalorieDonut(List<_ChartData> chartData, int target, int consumed, int remaining, NutritionProvider provider) {
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
                  Text(
                    provider.profile?.weeklyGoals[provider.selectedWeekday]?.isManual == true 
                        ? 'META DO DIA (FIXA)' 
                        : (provider.isCaloriesAdjusted ? 'META DO DIA (AJUSTADA)' : 'META DIÁRIA'), 
                    style: TextStyle(
                      color: provider.profile?.weeklyGoals[provider.selectedWeekday]?.isManual == true ? AppTheme.success : (provider.isCaloriesAdjusted ? AppTheme.accent : AppTheme.textSecondary), 
                      fontSize: 10, 
                      fontWeight: FontWeight.bold, 
                      letterSpacing: 1.1
                    )
                  ),
                  Text(
                    target.toString(),
                    style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  const Text('kcal', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                  const SizedBox(height: 2),
                  const Icon(Icons.edit, size: 12, color: AppTheme.textSecondary),
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

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.divider.withOpacity(0.05)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$title - $totalKcal kcal', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: AppTheme.accent),
                    onPressed: () => context.push('/nutrition/search?type=$type'),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_horiz, color: AppTheme.textSecondary),
                    color: AppTheme.surfaceHighlight,
                    onSelected: (val) {
                      if (val == 'copy') {
                        provider.copyMealFromPreviousDay(type);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Refeição ($title) copiada de ontem!')));
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'copy', child: Text('Copiar de ontem', style: TextStyle(color: AppTheme.textPrimary))),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (meals.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text('Nenhum alimento registrado.', style: TextStyle(color: AppTheme.textSecondary.withOpacity(0.5), fontStyle: FontStyle.italic, fontSize: 13)),
            )
          else
            ...meals.map((m) {
              final tags = BioIntelligence.analyzeFood(m.foodName, category: '');
              final discountedKcal = BioIntelligence.calculateDiscountedCalories(m.calories.round(), tags);
              final hasDiscount = discountedKcal < m.calories.round();

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(child: Text(m.foodName, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14))),
                              if (tags.isNotEmpty) const SizedBox(width: 6),
                              ...tags.map((t) => BioIntelligence.buildBadge(t, context)),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text('${m.portionG}g • ${m.protein.round()}P | ${m.carb.round()}C | ${m.fat.round()}G', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (hasDiscount)
                          Text('${m.calories.round()} kcal', style: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.6), fontSize: 10, decoration: TextDecoration.lineThrough)),
                        Text('$discountedKcal kcal', style: TextStyle(color: hasDiscount ? Colors.greenAccent : AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16, color: Colors.redAccent),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => provider.removeMeal(m.id),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildCalendarStrip(BuildContext context, NutritionProvider provider) {
    final now = DateTime.now();
    // Identifica o início da semana atual para alinhar aos _selectedWeekday (1 = SEG, 7 = DOM)
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 7,
        itemBuilder: (context, index) {
          final targetDate = startOfWeek.add(Duration(days: index));
          final weekdayNum = index + 1;
          final isSelected = provider.selectedWeekday == weekdayNum;
          final isToday = now.day == targetDate.day && now.month == targetDate.month;
          
          final profile = provider.profile;
          final goal = profile?.weeklyGoals[weekdayNum];
          final isHighDemand = goal?.label.contains('Treino') == true || goal?.label == 'Alta Demanda';

          // Calculando o progresso (mocking com selectedDayMeals ou todayMeals dependendo do dia para UI)
          double progress = 0.0;
          if (isSelected && goal != null && goal.calories > 0) {
            progress = (provider.consumedCalories / goal.calories).clamp(0.0, 1.0);
          } else if (goal != null && targetDate.isBefore(now)) {
            // Histórico simulado na view (Na real pegaria isso do logs do histórico)
            progress = 0.8; 
          }

          final weekLabels = ['SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SAB', 'DOM'];
          final dayName = weekLabels[index];

          return GestureDetector(
            onTap: () => provider.selectWeekday(weekdayNum),
            child: Container(
              width: 55,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.accent.withOpacity(0.15) : AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? AppTheme.accent : (isToday ? AppTheme.textSecondary.withOpacity(0.2) : Colors.transparent),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(dayName, style: TextStyle(color: isSelected ? AppTheme.accent : AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('${targetDate.day}', style: TextStyle(color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  
                  // Indicador Visual Circular com Ícone de Halter no meio se Treino
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 2,
                          color: AppTheme.accent,
                          backgroundColor: AppTheme.surfaceHighlight,
                        ),
                        if (isHighDemand)
                          Icon(Icons.fitness_center, size: 10, color: isSelected ? AppTheme.accent : AppTheme.textSecondary),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showManualOverrideDialog(BuildContext context, NutritionProvider provider) async {
    final goal = provider.profile?.weeklyGoals[provider.selectedWeekday];
    if (goal == null) return;

    final controller = TextEditingController(text: goal.calories.toString());

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Meta Manual (Manual Override)', style: TextStyle(color: AppTheme.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Defina um valor calórico fixo apenas para este dia. O Gêmeo Digital ajustará o restante da semana automaticamente.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Calorias Fixas (kcal)',
                labelStyle: TextStyle(color: AppTheme.accent),
                filled: true,
                fillColor: AppTheme.background,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
          ElevatedButton(
            onPressed: () {
              final newCals = int.tryParse(controller.text);
              if (newCals != null && newCals > 0) {
                // Manter macros relativos à nova caloria
                final ratio = newCals / (goal.calories == 0 ? 1 : goal.calories);
                final newGoal = goal.copyWith(
                  calories: newCals,
                  protein: goal.protein * ratio,
                  carb: goal.carb * ratio,
                  fat: goal.fat * ratio,
                  isManual: true, // Aciona a Lógica de Override!
                  label: 'Usuário (Fixa)',
                );
                provider.updateDailyManualGoal(provider.selectedWeekday, newGoal);
                
                // Recalibrar a semana forçando compensação global se esse dia impactou 
                // A Lógica no Bio Gestão é avisada via o reload!
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Meta do dia reajustada. Compensação semanal ativada.')));
                Navigator.pop(context);
              }
            }, 
            child: const Text('SALVAR')
          ),
        ],
      ),
    );
  }
}

  Widget _buildHydrationCard(NutritionProvider provider) {
    final consumed = provider.waterConsumed;
    final target = provider.waterTarget;
    final pct = (consumed / target).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade900.withValues(alpha: 0.8), Colors.blue.shade700.withValues(alpha: 0.5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(color: Colors.blue.withValues(alpha: 0.2), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.waves_rounded, color: Colors.cyanAccent, size: 22),
                  SizedBox(width: 10),
                  Text('HIDRATAÇÃO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('$consumed / $target ml', style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 12,
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  color: Colors.cyanAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildWaterBtn(provider, 200, 'COPO'),
              _buildWaterBtn(provider, 350, 'CANECA'),
              _buildWaterBtn(provider, 500, 'GARRAFA'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsightPanel(NutritionProvider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: AppTheme.accent, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Gêmeo Digital Insights', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 4),
                Text(
                  provider.smartInsight,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaterBtn(NutritionProvider provider, int ml, String label) {
    return InkWell(
      onTap: () => provider.addWater(ml),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 90,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Text('+$ml', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

class _ChartData {
  _ChartData(this.x, this.y, this.color);
  final String x;
  final double y;
  final Color color;
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 4, height: 20, decoration: BoxDecoration(color: AppTheme.accent, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 12),
        Text(
          title.toUpperCase(),
          style: GoogleFonts.outfit(
            color: AppTheme.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}
