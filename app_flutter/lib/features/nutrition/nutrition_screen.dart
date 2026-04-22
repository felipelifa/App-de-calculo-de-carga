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
                icon: const Icon(Icons.insights_rounded, color: Color(0xFFCCFF00)),
                onPressed: () => context.push('/nutrition/dashboard'),
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              title: Text(
                'Nutrição',
                style: GoogleFonts.outfit(
                  color: AppTheme.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
          
          SliverToBoxAdapter(
            child: RefreshIndicator(
              onRefresh: () async => provider.loadToday(),
              color: const Color(0xFFCCFF00),
              backgroundColor: AppTheme.surface,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    // Calendário Action Strip (Navegação de Dias)
                    _buildCalendarStrip(context, provider).animate().fadeIn(duration: 400.ms),

                    const SizedBox(height: 24),

                    // Insight do Gêmeo Digital (Destaque Neon)
                    _buildInsightPanel(provider).animate().scale(delay: 200.ms, curve: Curves.easeOutBack),

                    const SizedBox(height: 32),

                    // Header - Gráfico de Calorias
                    GestureDetector(
                      onTap: () => _showManualOverrideDialog(context, provider),
                      child: _buildCalorieDonut(chartData, target, consumed.toInt(), remaining.toInt(), provider)
                          .animate()
                          .fadeIn(delay: 400.ms),
                    ),

                    const SizedBox(height: 48),

                    // Macros Row (Estilo Challenger)
                    _buildMacrosRow(provider).animate().slideY(begin: 0.2, delay: 600.ms),

                    const SizedBox(height: 32),

                    // Bento Grid para Hidratação e Bio-Gestão
                    _buildHydrationCard(provider),
                    const SizedBox(height: 16),
                    _buildBioManagementStats(provider),

                    const SizedBox(height: 48),
                    
                    // Seções de Refeições
                    Row(
                      children: [
                        const Icon(Icons.restaurant_menu_rounded, color: Color(0xFFCCFF00), size: 20),
                        const SizedBox(width: 12),
                        Text(
                          'PROTOCOLO DIÁRIO',
                          style: GoogleFonts.outfit(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildMealSection(context, provider, 'Café da manhã', 'breakfast', meals),
                    _buildMealSection(context, provider, 'Almoço', 'lunch', meals),
                    _buildMealSection(context, provider, 'Jantar', 'dinner', meals),
                    _buildMealSection(context, provider, 'Lanches', 'snack', meals),
                    
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBioManagementStats(NutritionProvider provider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMonitoringIcon(Icons.verified_user_rounded, 'Aderência', '${(provider.adherenceScore * 100).toInt()}%', const Color(0xFFCCFF00)),
          _buildMonitoringIcon(Icons.battery_alert_rounded, 'Fadiga', provider.fatigueLevel > 7 ? 'ALTA' : 'NORMAL', provider.fatigueLevel > 7 ? Colors.redAccent : Colors.white),
          _buildMonitoringIcon(Icons.auto_awesome_rounded, 'Status', 'Bio-Ativo', const Color(0xFF00E5FF)),
        ],
      ),
    );
  }

  Widget _buildMonitoringIcon(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 8),
        Text(label, style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w600)),
        Text(value, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
      ],
    );
  }

  Widget _buildMacrosRow(NutritionProvider provider) {
    return Row(
      children: [
        _buildMacroCard('Proteína', provider.consumedProtein, provider.targetProtein, const Color(0xFFCCFF00)),
        const SizedBox(width: 12),
        _buildMacroCard('Carbo', provider.consumedCarb, provider.targetCarb, const Color(0xFF00E5FF)),
        const SizedBox(width: 12),
        _buildMacroCard('Gordura', provider.consumedFat, provider.targetFat, const Color(0xFFFF4081)),
      ],
    );
  }

  Widget _buildMacroCard(String label, double consumed, double target, Color color) {
    final pct = target > 0 ? (consumed / target).clamp(0.0, 1.0) : 0.0;
    
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.03)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
            const SizedBox(height: 8),
            Text(
              '${consumed.round()}g',
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
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

  Widget _buildCalorieDonut(List<_ChartData> chartData, int target, int consumed, int remaining, NutritionProvider provider) {
    return Column(
      children: [
        SizedBox(
          height: 220,
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
                    innerRadius: '85%',
                    radius: '100%',
                  )
                ],
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'CALORIAS RESTANTES',
                    style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    remaining.abs().toString(),
                    style: GoogleFonts.outfit(fontSize: 54, fontWeight: FontWeight.w900, color: Colors.white, height: 1),
                  ),
                  Text(
                    remaining < 0 ? 'excedido' : 'disponível',
                    style: GoogleFonts.outfit(color: remaining < 0 ? Colors.redAccent : const Color(0xFFCCFF00), fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              )
            ],
          ),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildMiniStat('CONSUMIDO', '$consumed', Colors.white),
            const SizedBox(width: 48),
            _buildMiniStat('META', '$target', const Color(0xFFCCFF00)),
          ],
        ),
      ],
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
        const SizedBox(height: 6),
        Text(value, style: GoogleFonts.outfit(color: color, fontWeight: FontWeight.w900, fontSize: 20)),
      ],
    );
  }

  Widget _buildMealSection(BuildContext context, NutritionProvider provider, String title, String type, List<MealEntry> allMeals) {
    final meals = allMeals.where((m) => m.mealType == type).toList();
    final totalKcal = meals.fold(0, (sum, m) => sum + m.calories.round());

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                  Text('$totalKcal kcal totais', style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 12)),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_rounded, color: Color(0xFFCCFF00), size: 32),
                onPressed: () => context.push('/nutrition/search?type=$type'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (meals.isEmpty)
            Text('Toque no + para adicionar', style: GoogleFonts.outfit(color: Colors.white10, fontSize: 14))
          else
            ...meals.map((m) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m.foodName, style: GoogleFonts.outfit(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                        Text('${m.portionG}g • ${m.calories.round()} kcal', style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline_rounded, color: Colors.white24, size: 20),
                    onPressed: () => provider.removeMeal(m.id),
                  ),
                ],
              ),
            )),
        ],
      ),
    );
  }

  Widget _buildCalendarStrip(BuildContext context, NutritionProvider provider) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    return SizedBox(
      height: 95,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        itemBuilder: (context, index) {
          final targetDate = startOfWeek.add(Duration(days: index));
          final weekdayNum = index + 1;
          final isSelected = provider.selectedWeekday == weekdayNum;
          
          return GestureDetector(
            onTap: () => provider.selectWeekday(weekdayNum),
            child: Container(
              width: 60,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFCCFF00) : const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isSelected ? const Color(0xFFCCFF00) : Colors.white.withOpacity(0.05)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    ['SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SAB', 'DOM'][index],
                    style: GoogleFonts.outfit(
                      color: isSelected ? Colors.black : AppTheme.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${targetDate.day}',
                    style: GoogleFonts.outfit(
                      color: isSelected ? Colors.black : Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
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
        title: const Text('Meta Manual', style: TextStyle(color: AppTheme.textPrimary)),
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
                const Text('Insights do Gêmeo Digital', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
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
