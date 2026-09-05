import 'api_service.dart';

class CoachService {
  final ApiService _api;

  CoachService({ApiService? api})
      : _api = api ?? ApiService();

  Future<String> getWorkoutFeedback() async {
    final now = DateTime.now();
    final weekNumber = (now.difference(DateTime(now.year, 1, 1)).inDays / 7).ceil();

    try {
      final currentWeek = await _api.get<List<dynamic>>('/workouts', queryParams: {
        'weekNumber': weekNumber.toString(),
      });

      final lastWeek = await _api.get<List<dynamic>>('/workouts', queryParams: {
        'weekNumber': (weekNumber - 1).toString(),
      });

      final currentSessions = currentWeek.length;
      final lastSessions = lastWeek.length;

      final currentVolume = currentWeek.fold<double>(0, (sum, w) {
        return sum + ((w['totalVolume'] as num?)?.toDouble() ?? 0);
      });

      final lastVolume = lastWeek.fold<double>(0, (sum, w) {
        return sum + ((w['totalVolume'] as num?)?.toDouble() ?? 0);
      });

      if (currentSessions > lastSessions) {
        return 'Você treinou mais vezes esta semana! Continue assim!';
      } else if (currentVolume > lastVolume * 1.1) {
        return 'Você aumentou seu volume de treino! Seus músculos estão crescendo!';
      } else if (currentVolume < lastVolume * 0.9) {
        return 'Seu volume diminuiu um pouco. Não desanime, volte com tudo!';
      } else {
        return 'Seu treino está consistente! Que tal tentar aumentar um pouco a carga?';
      }
    } catch (_) {
      return 'Comece a registrar seus treinos para receber feedback personalizado!';
    }
  }

  Future<String> getNutritionFeedback() async {
    try {
      final daily = await _api.get<Map<String, dynamic>>('/nutrition/daily');

      final totalCalories = (daily['totalCalories'] as num?)?.toDouble() ?? 0;
      final totalProtein = (daily['totalProtein'] as num?)?.toDouble() ?? 0;

      final profile = await _api.get<Map<String, dynamic>>('/nutrition/profile');

      final targetCalories = (profile['targetCalories'] as num?)?.toDouble() ?? 2000;
      final targetProtein = (profile['targetProtein'] as num?)?.toDouble() ?? 150;

      final calorieProgress = totalCalories / targetCalories;
      final proteinProgress = totalProtein / targetProtein;

      if (calorieProgress < 0.7) {
        return 'Você comeu pouco hoje. Lembre-se de comer para ter energia para o treino!';
      } else if (calorieProgress > 1.2) {
        return 'Você comeu um pouco além da meta. Tente equilibrar amanhã.';
      } else if (proteinProgress < 0.8) {
        return 'Sua proteína está baixa. Tente incluir mais fontes de proteína.';
      } else {
        return 'Sua alimentação está equilibrada! Continue assim!';
      }
    } catch (_) {
      return 'Registre suas refeições para receber feedback nutricional personalizado!';
    }
  }

  Future<String> getHydrationFeedback() async {
    try {
      final daily = await _api.get<Map<String, dynamic>>('/nutrition/daily');

      final waterMl = (daily['waterMl'] as num?)?.toInt() ?? 0;
      final targetMl = 2500;

      final progress = waterMl / targetMl;

      if (progress < 0.5) {
        return 'Você bebeu pouca água hoje. Lembre-se de se hidratar!';
      } else if (progress < 0.8) {
        return 'Você está no caminho! Beba mais um pouco de água.';
      } else {
        return 'Ótima hidratação! Continue assim!';
      }
    } catch (_) {
      return 'Registre sua ingestão de água para acompanhar sua hidratação!';
    }
  }

  Future<String> getProgressFeedback() async {
    final now = DateTime.now();
    final weekNumber = (now.difference(DateTime(now.year, 1, 1)).inDays / 7).ceil();

    try {
      final weeklyVolumes = <int, double>{};
      for (int i = 0; i < 4; i++) {
        final week = weekNumber - i;
        final workouts = await _api.get<List<dynamic>>('/workouts', queryParams: {
          'weekNumber': week.toString(),
        });
        final volume = workouts.fold<double>(0, (sum, w) {
          return sum + ((w['totalVolume'] as num?)?.toDouble() ?? 0);
        });
        if (volume > 0) {
          weeklyVolumes[week] = volume;
        }
      }

      if (weeklyVolumes.length < 2) {
        return 'Continue treinando para ver seu progresso aqui!';
      }

      final volumes = weeklyVolumes.values.toList();
      final isIncreasing = volumes.last > volumes.first * 1.1;
      final isDecreasing = volumes.last < volumes.first * 0.9;

      if (isIncreasing) {
        return 'Seu volume está aumentando consistentemente! Excelente progresso!';
      } else if (isDecreasing) {
        return 'Seu volume diminuiu nas últimas semanas. Que tal voltar com mais intensidade?';
      } else {
        return 'Seu volume está estável. Para evoluir, tente aumentar gradualmente a carga.';
      }
    } catch (_) {
      return 'Continue treinando para ver seu progresso aqui!';
    }
  }

  String getMotivationMessage() {
    final messages = [
      'Você está no caminho certo! Continue assim!',
      'Cada treino te aproxima do seu objetivo!',
      'Lembre-se: consistência é mais importante que intensidade!',
      'Seu corpo está se adaptando. Não desanime!',
      'Você é mais forte do que pensa!',
    ];
    return messages[DateTime.now().millisecond % messages.length];
  }

  String getDailyTip() {
    final tips = [
      'Dica: Beba água antes, durante e após o treino.',
      'Dica: Durma pelo menos 7 horas para uma boa recuperação.',
      'Dica: Não pule o aquecimento! Ele previne lesões.',
      'Dica: Coma proteína em todas as refeições para construir músculos.',
      'Dica: Descanse entre os treinos. O músculo cresce durante o descanso.',
    ];
    return tips[DateTime.now().day % tips.length];
  }
}
