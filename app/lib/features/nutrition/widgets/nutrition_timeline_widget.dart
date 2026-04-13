import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../nutrition_provider.dart';
import '../nutrition_profile_model.dart';
import '../../../shared/theme/app_theme.dart';

class NutritionTimelineWidget extends StatelessWidget {
  const NutritionTimelineWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NutritionProvider>(
      builder: (context, provider, child) {
        final profile = provider.profile;
        if (profile == null) return const SizedBox.shrink();

        final today = DateTime.now().weekday;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                'Orçamento Semanal Adaptativo',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            SizedBox(
              height: 180,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(7, (index) {
                  final weekday = index + 1;
                  final goal = profile.weeklyGoals[weekday];
                  if (goal == null) return const SizedBox.shrink();

                  final isToday = weekday == DateTime.now().weekday;
                  final isSelected = weekday == provider.selectedWeekday;
                  final dayLabel = _getWeekdayLabel(weekday);
                  
                  // Encontra a cota máxima da semana para nivelar os gráficos
                  final maxCals = profile.weeklyGoals.values.fold(0, (maxVal, g) => g.calories > maxVal ? g.calories : maxVal);
                  final ratio = maxCals > 0 ? (goal.calories / maxCals) : 0.0;

                  return GestureDetector(
                    onTap: () => provider.selectWeekday(weekday),
                    child: _TimelineDayCard(
                      label: dayLabel,
                      goal: goal,
                      isToday: isToday,
                      isSelected: isSelected,
                      fillRatio: ratio.toDouble(),
                    ),
                  );
                }),
              ),
            ),
          ],
        );
      },
    );
  }

  String _getWeekdayLabel(int weekday) {
    switch (weekday) {
      case 1: return 'SEG';
      case 2: return 'TER';
      case 3: return 'QUA';
      case 4: return 'QUI';
      case 5: return 'SEX';
      case 6: return 'SAB';
      case 7: return 'DOM';
      default: return '';
    }
  }
}

class _TimelineDayCard extends StatelessWidget {
  final String label;
  final DailyNutritionalGoal goal;
  final bool isToday;
  final bool isSelected;
  final double fillRatio;

  const _TimelineDayCard({
    required this.label,
    required this.goal,
    required this.isToday,
    required this.isSelected,
    required this.fillRatio,
  });

  @override
  Widget build(BuildContext context) {
    final bool isHighDemand = goal.label.contains('Treino') || goal.label == 'Alta Demanda';
    final Color activeColor = isToday ? AppTheme.accent : AppTheme.accent.withOpacity(0.4);

    return Container(
      width: 45,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Valor Calórico
          Text(
            '${goal.calories}',
            style: TextStyle(
              color: isSelected ? AppTheme.accent : AppTheme.textPrimary,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          // Barra Proporcional
          Expanded(
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Container(
                  width: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.divider.withOpacity(0.1)),
                  ),
                ),
                FractionallySizedBox(
                  alignment: Alignment.bottomCenter,
                  heightFactor: fillRatio.clamp(0.1, 1.0),
                  child: Container(
                    width: 32,
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.accent : activeColor,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: isSelected ? [
                        BoxShadow(color: AppTheme.accent.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 2))
                      ] : null,
                    ),
                  ),
                ),
                // Indicador de Treino ou Compensação
                if (isHighDemand || goal.label.contains('Excesso'))
                  Positioned(
                    bottom: 4,
                    child: Icon(
                      goal.label.contains('Excesso') ? Icons.warning_rounded : Icons.fitness_center_rounded,
                      size: 10,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Dia da Semana e Bolinha de Hoje
          Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppTheme.accent : AppTheme.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: isToday ? AppTheme.accent : Colors.transparent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

