import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;

import '../../shared/theme/app_theme.dart';
import '../workout/workout_profile_provider.dart';
import 'nutrition_provider.dart';

class NutritionDashboardScreen extends StatelessWidget {
  const NutritionDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final wp = context.watch<WorkoutProfileProvider>().profile;
    final np = context.watch<NutritionProvider>();
    
    if (wp == null || np.profile == null) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(child: CircularProgressIndicator(color: AppTheme.accent))
      );
    }

    final imc = wp.weightKg / math.pow(wp.heightCm / 100, 2);
    
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
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              title: Text(
                'Bio-Analítica',
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                   // Avatar e Status Rapido
                   _buildStatHeader(wp).animate().fadeIn().slideY(begin: 0.1),
                   
                   const SizedBox(height: 24),
                   
                   // Objetivo Principal (Hero Card)
                   _buildGoalHeroCard(wp.primaryGoal).animate().scale(delay: 200.ms),
                   
                   const SizedBox(height: 32),
                   
                   // Grid de Métricas (Bento Style)
                   GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.1,
                      children: [
                        _buildMetricCard('TMB (Basal)', '${np.profile!.tmb}', 'kcal', AppTheme.accentOrange, Icons.local_fire_department_rounded),
                        _buildMetricCard('IMC (Corporal)', imc.toStringAsFixed(1), 'index', AppTheme.accentBlue, Icons.person_search_rounded),
                        _buildMetricCard('ÁGUA', '${np.waterTarget}', 'ml', Colors.cyan, Icons.water_drop_rounded),
                        _buildMetricCard('BASE-CAL', '${np.profile!.targetCalories}', 'kcal', AppTheme.accentLime, Icons.bolt_rounded),
                      ],
                   ).animate().fadeIn(delay: 400.ms),

                   const SizedBox(height: 32),

                   // Macros Distribution
                   _buildAdvancedMacroDistribution(np).animate().slideY(begin: 0.2, delay: 600.ms),

                   const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatHeader(wp) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildInfoItem('${wp.heightCm.toInt()}', 'CM', 'ALTURA'),
          _buildDivider(),
          _buildInfoItem('${wp.weightKg.toInt()}', 'KG', 'PESO'),
          _buildDivider(),
          _buildInfoItem('${wp.age}', 'ANOS', 'IDADE'),
        ],
      ),
    );
  }

  Widget _buildDivider() => Container(width: 1, height: 30, color: Colors.white10);

  Widget _buildInfoItem(String value, String unit, String label) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(value, style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontWeight: FontWeight.w900, fontSize: 24)),
            const SizedBox(width: 2),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(unit, style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontWeight: FontWeight.bold, fontSize: 10)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
      ],
    );
  }

  Widget _buildGoalHeroCard(String goal) {
    String label = 'MANUTENÇÃO';
    IconData icon = Icons.balance_rounded;
    if (goal == 'fat_loss') {
      label = 'PERDA DE GORDURA';
      icon = Icons.trending_down_rounded;
    } else if (goal == 'hypertrophy') {
      label = 'GANHO DE MASSA';
      icon = Icons.fitness_center_rounded;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.accent,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: AppTheme.accent.withOpacity(0.3), blurRadius: 40, offset: const Offset(0, 20))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 32),
          const SizedBox(height: 24),
          Text('OBJETIVO PRINCIPAL', style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.6), fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 24)),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, String unit, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(value, style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w900)),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(unit, style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedMacroDistribution(NutritionProvider np) {
    final total = np.targetProtein + np.targetCarb + np.targetFat;
    final pPct = (np.targetProtein / total * 100).round();
    final cPct = (np.targetCarb / total * 100).round();
    final fPct = (np.targetFat / total * 100).round();

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('MACRONUTRIENT RATIO', style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1)),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMacroDetail('CARBS', '${np.targetCarb.round()}g', AppTheme.success, '$cPct%'),
              _buildMacroDetail('PROT', '${np.targetProtein.round()}g', AppTheme.accent, '$pPct%'),
              _buildMacroDetail('FAT', '${np.targetFat.round()}g', AppTheme.accentOrange, '$fPct%'),
            ],
          ),
          const SizedBox(height: 32),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  Expanded(flex: cPct, child: Container(color: AppTheme.success)),
                  Expanded(flex: pPct, child: Container(color: AppTheme.accent)),
                  Expanded(flex: fPct, child: Container(color: AppTheme.accentOrange)),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMacroDetail(String label, String value, Color color, String pct) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(label, style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w900)),
          ],
        ),
        const SizedBox(height: 8),
        Text(value, style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w900)),
        Text(pct, style: GoogleFonts.outfit(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
