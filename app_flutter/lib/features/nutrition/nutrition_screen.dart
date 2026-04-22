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
import 'nutrition_profile_model.dart';

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
            expandedHeight: 80,
            floating: true,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textPrimary, size: 20),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                'NUTRIÇÃO',
                style: GoogleFonts.outfit(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
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
                    // Calendário Action Strip (Turbo)
                    _buildCalendarStrip(context, provider).animate().fadeIn(duration: 400.ms),

                    const SizedBox(height: 32),

                    // Foco Primário: Calorias
                    GestureDetector(
                      onTap: () => _showManualOverrideDialog(context, provider),
                      child: _buildCalorieDonut(chartData, target.toInt(), consumed.toInt(), remaining.toInt())
                          .animate()
                          .fadeIn()
                          .scale(begin: const Offset(0.95, 0.95)),
                    ),

                    const SizedBox(height: 32),

                    // Ação Primária: Registrar Refeição
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton.icon(
                        onPressed: () => context.push('/nutrition/search?type=breakfast'),
                        icon: const Icon(Icons.add_rounded, color: Colors.black, size: 28),
                        label: Text(
                          'REGISTRAR ALIMENTAÇÃO',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            color: Colors.black,
                            letterSpacing: 1,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFCCFF00),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          elevation: 8,
                          shadowColor: const Color(0xFFCCFF00).withValues(alpha: 0.3),
                        ),
                      ),
                    ).animate().slideY(begin: 0.2, delay: 200.ms).fadeIn(),

                    const SizedBox(height: 40),

                    // Insight sutil
                    _buildInsightPanel(provider).animate().fadeIn(delay: 400.ms),

                    const SizedBox(height: 40),

                    // Macros (Compact cards)
                    _buildMacrosGrid(provider).animate().slideY(begin: 0.1, delay: 600.ms).fadeIn(),

                    const SizedBox(height: 16),

                    // Hidratação (Mesmo estilo dos macros)
                    _buildHydrationCompact(provider).animate().slideY(begin: 0.1, delay: 700.ms).fadeIn(),

                    const SizedBox(height: 40),
                    
                    // Seções de Refeições
                    Row(
                      children: [
                        const Icon(Icons.restaurant_menu_rounded, color: Color(0xFFCCFF00), size: 18),
                        const SizedBox(width: 12),
                        Text(
                          'REGISTROS DO DIA',
                          style: GoogleFonts.outfit(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
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

  Widget _buildMacrosGrid(NutritionProvider provider) {
    return Row(
      children: [
        _buildCompactMacroCard('PROTEÍNA', '${provider.consumedProtein.round()}g / ${provider.targetProtein.round()}g', 
          provider.consumedProtein / (provider.targetProtein > 0 ? provider.targetProtein : 1), const Color(0xFFCCFF00)),
        const SizedBox(width: 8),
        _buildCompactMacroCard('CARBO', '${provider.consumedCarb.round()}g / ${provider.targetCarb.round()}g', 
          provider.consumedCarb / (provider.targetCarb > 0 ? provider.targetCarb : 1), const Color(0xFF00E5FF)),
        const SizedBox(width: 8),
        _buildCompactMacroCard('GORDURA', '${provider.consumedFat.round()}g / ${provider.targetFat.round()}g', 
          provider.consumedFat / (provider.targetFat > 0 ? provider.targetFat : 1), const Color(0xFFFF4081)),
      ],
    );
  }

  Widget _buildCompactMacroCard(String label, String value, double pct, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
            const SizedBox(height: 4),
            Text(value, style: GoogleFonts.outfit(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: pct.clamp(0.0, 1.0),
                backgroundColor: Colors.white.withValues(alpha: 0.05),
                color: color,
                minHeight: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHydrationCompact(NutritionProvider provider) {
    final pct = (provider.waterConsumed / (provider.waterTarget > 0 ? provider.waterTarget : 1)).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.opacity_rounded, color: Color(0xFF00E5FF), size: 16),
                  const SizedBox(width: 8),
                  Text('HIDRATAÇÃO', style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                ],
              ),
              Row(
                children: [
                  Text('${provider.waterConsumed} / ${provider.waterTarget} ml', 
                    style: GoogleFonts.outfit(color: const Color(0xFF00E5FF), fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 12),
                  _buildIconAction(Icons.remove_circle_outline_rounded, () => _showWaterRemovalDialog(context, provider), color: Colors.white24),
                  const SizedBox(width: 8),
                  _buildIconAction(Icons.add_circle_outline_rounded, () => _showCustomWaterDialog(context, provider), color: const Color(0xFF00E5FF)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              color: const Color(0xFF00E5FF),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCompactWaterBtn(provider, 200, '200ml'),
              _buildCompactWaterBtn(provider, 350, '350ml'),
              _buildCompactWaterBtn(provider, 500, '500ml'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconAction(IconData icon, VoidCallback onTap, {Color? color}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Icon(icon, size: 18, color: color ?? Colors.white70),
      ),
    );
  }

  Future<void> _showCustomWaterDialog(BuildContext context, NutritionProvider provider) async {
    final ctrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text('Quanto você bebeu?', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: 'Quantidade em ml (ex: 750)', hintStyle: TextStyle(color: Colors.white24)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCELAR')),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(ctrl.text);
              if (val != null && val > 0) {
                provider.addWater(val);
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF)),
            child: const Text('ADICIONAR', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  Future<void> _showWaterRemovalDialog(BuildContext context, NutritionProvider provider) async {
    final ctrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text('Remover água?', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: 'Quantidade para tirar (ml)', hintStyle: TextStyle(color: Colors.white24)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCELAR')),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(ctrl.text);
              if (val != null && val > 0) {
                provider.removeWater(val);
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('REMOVER'),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactWaterBtn(NutritionProvider provider, int ml, String label) {
    return InkWell(
      onTap: () => provider.addWater(ml),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(label, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildCalorieDonut(List<_ChartData> chartData, int target, int consumed, int remaining) {
    return Column(
      children: [
        SizedBox(
          height: 240,
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
                    innerRadius: '88%',
                    radius: '100%',
                    animationDuration: 1500,
                  )
                ],
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'HOJE',
                    style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 3),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    remaining.abs().toString(),
                    style: GoogleFonts.outfit(fontSize: 64, fontWeight: FontWeight.w900, color: Colors.white, height: 1),
                  ),
                  Text(
                    'kcal ${remaining < 0 ? 'excedidas' : 'disponíveis'}',
                    style: GoogleFonts.outfit(
                      color: remaining < 0 ? Colors.redAccent : const Color(0xFFCCFF00), 
                      fontSize: 14, 
                      fontWeight: FontWeight.bold
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Meta: $target • Consumido: $consumed',
                    style: GoogleFonts.outfit(color: AppTheme.textSecondary.withValues(alpha: 0.7), fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ],
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMealSection(BuildContext context, NutritionProvider provider, String title, String type, List<MealEntry> allMeals) {
    final meals = allMeals.where((m) => m.mealType == type).toList();
    final totalKcal = meals.fold(0, (sum, m) => sum + m.calories.round());

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.02)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title.toUpperCase(), style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              Text('$totalKcal kcal', style: GoogleFonts.outfit(color: const Color(0xFFCCFF00), fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          if (meals.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...meals.map((m) => Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(m.foodName, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13)),
                  ),
                  Text('${m.calories.round()} kcal', style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 12)),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white12, size: 16),
                    onPressed: () => provider.removeMeal(m.id),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildCalendarStrip(BuildContext context, NutritionProvider provider) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        itemBuilder: (context, index) {
          final targetDate = startOfWeek.add(Duration(days: index));
          final weekdayNum = index + 1;
          final isSelected = provider.selectedWeekday == weekdayNum;
          
          final goal = provider.profile?.weeklyGoals[weekdayNum];
          final kcal = goal?.calories.toString() ?? '-';
          final p = goal?.protein.round().toString() ?? '-';
          final c = goal?.carb.round().toString() ?? '-';
          final f = goal?.fat.round().toString() ?? '-';

          return GestureDetector(
            onTap: () => provider.selectWeekday(weekdayNum),
            onLongPress: () {
                provider.selectWeekday(weekdayNum);
                _showManualOverrideDialog(context, provider);
            },
            child: Container(
              width: 70,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFCCFF00) : Colors.white.withValues(alpha: 0.02),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isSelected ? const Color(0xFFCCFF00) : Colors.white.withValues(alpha: 0.03)),
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
                  const SizedBox(height: 2),
                  Text(
                    '${targetDate.day}',
                    style: GoogleFonts.outfit(
                      color: isSelected ? Colors.black : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                        color: isSelected ? Colors.black.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(4)
                    ),
                    child: Column(
                      children : [
                        Text('$kcal kcal', style: GoogleFonts.outfit(color: isSelected ? Colors.black87 : AppTheme.accent, fontSize: 8, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 1),
                        Text('P:$p C:$c G:$f', style: GoogleFonts.outfit(color: isSelected ? Colors.black54 : AppTheme.textSecondary, fontSize: 7, fontWeight: FontWeight.bold)),
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

  Widget _buildInsightPanel(NutritionProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCCFF00).withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFFCCFF00), size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('💡 INSIGHT DO DIA', style: GoogleFonts.outfit(color: const Color(0xFFCCFF00), fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1)),
                const SizedBox(height: 4),
                Text(
                  provider.smartInsight,
                  style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 11, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showManualOverrideDialog(BuildContext context, NutritionProvider provider) async {
    final goal = provider.profile?.weeklyGoals[provider.selectedWeekday];
    if (goal == null) return;

    final kcalCtrl = TextEditingController(text: goal.calories.toString());
    final proteinCtrl = TextEditingController(text: goal.protein.round().toString());
    final carbCtrl = TextEditingController(text: goal.carb.round().toString());
    final fatCtrl = TextEditingController(text: goal.fat.round().toString());

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161616),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Ajuste de Meta', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Defina metas específicas para sua Bio-Gestão hoje.', style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 12)),
              const SizedBox(height: 24),
              _buildModernInput(kcalCtrl, 'Calorias (kcal)', const Color(0xFFCCFF00)),
              const SizedBox(height: 16),
              _buildModernInput(proteinCtrl, 'Proteína (g)', const Color(0xFFCCFF00)),
              const SizedBox(height: 16),
              _buildModernInput(carbCtrl, 'Carboidrato (g)', const Color(0xFF00E5FF)),
              const SizedBox(height: 16),
              _buildModernInput(fatCtrl, 'Gordura (g)', const Color(0xFFFF4081)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('CANCELAR', style: GoogleFonts.outfit(color: AppTheme.textSecondary))),
          ElevatedButton(
            onPressed: () {
              final kc = int.tryParse(kcalCtrl.text) ?? goal.calories;
              final p = double.tryParse(proteinCtrl.text) ?? goal.protein;
              final c = double.tryParse(carbCtrl.text) ?? goal.carb;
              final f = double.tryParse(fatCtrl.text) ?? goal.fat;

              final newGoal = goal.copyWith(
                calories: kc,
                protein: p,
                carb: c,
                fat: f,
                isManual: true,
                label: 'Personalizada',
              );
              provider.updateDailyManualGoal(provider.selectedWeekday, newGoal);
              Navigator.pop(context);
            }, 
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFCCFF00),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('SALVAR', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );
  }

  Widget _buildModernInput(TextEditingController ctrl, String label, Color accent) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.outfit(color: accent, fontSize: 12, fontWeight: FontWeight.w900),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.03),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white10)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: accent)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
