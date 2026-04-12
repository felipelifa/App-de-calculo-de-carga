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
              height: 110,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: 7,
                itemBuilder: (context, index) {
                  final weekday = index + 1;
                  final goal = profile.weeklyGoals[weekday];
                  if (goal == null) return const SizedBox.shrink();

                  final isToday = weekday == today;
                  final dayLabel = _getWeekdayLabel(weekday);

                  return _TimelineDayCard(
                    label: dayLabel,
                    goal: goal,
                    isToday: isToday,
                    isPast: weekday < today,
                  );
                },
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
  final bool isPast;

  const _TimelineDayCard({
    required this.label,
    required this.goal,
    required this.isToday,
    required this.isPast,
  });

  @override
  Widget build(BuildContext context) {
    final bool isHighDemand = goal.label == 'Alta Demanda';

    return Container(
      width: 80,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: isToday ? AppTheme.accent : AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isToday ? AppTheme.accent : AppTheme.divider.withOpacity(0.1),
          width: 2,
        ),
        boxShadow: isToday ? [
          BoxShadow(
            color: AppTheme.accent.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ] : [],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isToday ? Colors.white : AppTheme.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${goal.calories}',
            style: TextStyle(
              color: isToday ? Colors.white : AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isToday ? Colors.white.withOpacity(0.2) : (isHighDemand ? AppTheme.accent.withOpacity(0.1) : Colors.transparent),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              isHighDemand ? 'TREINO' : 'RELAS',
              style: TextStyle(
                color: isToday ? Colors.white : (isHighDemand ? AppTheme.accent : AppTheme.textSecondary.withOpacity(0.5)),
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
