import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final imc = wp.weightKg / math.pow(wp.heightCm / 100, 2);
    
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Meu Perfil Bio-Nutri'),
        backgroundColor: AppTheme.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header Biométrico
            _buildBiometricHeader(wp),
            const SizedBox(height: 24),
            
            // Objetivo Atual
            _buildGoalCard(wp.primaryGoal),
            const SizedBox(height: 24),

            // Grid de Métricas (TMB, IMC, Água, Calorias)
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
              children: [
                _buildMetricCard(
                  'TAXA METABÓLICA BASAL', 
                  '${np.profile!.tmb} kcal', 
                  Icons.local_fire_department, 
                  Colors.orange
                ),
                _buildMetricCard(
                  'ÍNDICE MASSA CORPORAL', 
                  imc.toStringAsFixed(1), 
                  Icons.person_outline, 
                  Colors.blue
                ),
                _buildMetricCard(
                  'REQUISITOS DE ÁGUA', 
                  '${np.waterTarget} ml', 
                  Icons.water_drop, 
                  Colors.cyan
                ),
                _buildMetricCard(
                  'CALORIAS DIÁRIAS (BASE)', 
                  '${np.profile!.targetCalories} kcal', 
                  Icons.bolt, 
                  AppTheme.accent
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Distribuição de Macros
            _buildMacroDistributionCard(np),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildBiometricHeader(wp) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInfoItem('${wp.heightCm.toInt()}', 'ALTURA'),
          _buildInfoItem('${wp.weightKg.toInt()}', 'PESO'),
          _buildInfoItem(wp.biologicalSex == 'male' ? 'Homem' : 'Mulher', 'GÊNERO'),
          _buildInfoItem('${wp.age}', 'IDADE'),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildGoalCard(String goal) {
    String label = 'Manter Peso';
    if (goal == 'fat_loss') label = 'Perder Gordura';
    else if (goal == 'hypertrophy') label = 'Aumentar Massa Muscular';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.accent, AppTheme.accent.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppTheme.accent.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          const Text('OBJETIVO', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Text(label.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.divider.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Icon(icon, color: color, size: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 8, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroDistributionCard(NutritionProvider np) {
    final total = np.targetProtein + np.targetCarb + np.targetFat;
    final pPct = (np.targetProtein / total * 100).round();
    final cPct = (np.targetCarb / total * 100).round();
    final fPct = (np.targetFat / total * 100).round();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('DISTRIBUIÇÃO DE MACROS', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMacroInfo('Carbos', '${np.targetCarb.round()}g', AppTheme.success, '$cPct%'),
              _buildMacroInfo('Proteína', '${np.targetProtein.round()}g', AppTheme.accent, '$pPct%'),
              _buildMacroInfo('Gordura', '${np.targetFat.round()}g', Colors.orange, '$fPct%'),
            ],
          ),
          const SizedBox(height: 32),
          // Barra de progresso visual
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  Expanded(flex: cPct, child: Container(color: AppTheme.success)),
                  Expanded(flex: pPct, child: Container(color: AppTheme.accent)),
                  Expanded(flex: fPct, child: Container(color: Colors.orange)),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMacroInfo(String label, String value, Color color, String pct) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(pct, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
      ],
    );
  }
}
