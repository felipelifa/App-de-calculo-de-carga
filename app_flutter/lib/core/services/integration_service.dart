import 'api_service.dart';

class IntegrationService {
  final ApiService _api;

  IntegrationService({ApiService? api})
      : _api = api ?? ApiService();

  Future<String> getTodayMessage() async {
    final now = DateTime.now();
    final weekNumber = (now.difference(DateTime(now.year, 1, 1)).inDays / 7).ceil();
    final weekday = now.weekday;

    try {
      final workouts = await _api.get<List<dynamic>>('/workouts', queryParams: {
        'weekNumber': weekNumber.toString(),
      });

      final weekSessions = workouts.length;
      final todayWorkout = workouts.where((w) {
        final dateStr = w['date'] as String?;
        if (dateStr == null) return false;
        final date = DateTime.tryParse(dateStr);
        return date != null && _isSameDay(date, now);
      }).toList();

      if (todayWorkout.isNotEmpty) {
        return _getPostWorkoutMessage();
      }

      final profile = await _getProfile();
      final targetDays = profile?['availableDaysPerWeek'] ?? 3;

      if (weekSessions < targetDays) {
        return _getPreWorkoutMessage(weekSessions, targetDays);
      } else {
        return _getRestDayMessage();
      }
    } catch (_) {
      return 'Bem-vindo! Comece seu primeiro treino hoje!';
    }
  }

  Future<String> getNutritionMessage() async {
    final now = DateTime.now();
    final weekNumber = (now.difference(DateTime(now.year, 1, 1)).inDays / 7).ceil();

    try {
      final workouts = await _api.get<List<dynamic>>('/workouts', queryParams: {
        'weekNumber': weekNumber.toString(),
      });

      final todayWorkout = workouts.where((w) {
        final dateStr = w['date'] as String?;
        if (dateStr == null) return false;
        final date = DateTime.tryParse(dateStr);
        return date != null && _isSameDay(date, now);
      }).toList();

      if (todayWorkout.isNotEmpty) {
        return 'Hoje é um dia de treino. Sua meta de carboidratos está um pouco maior para acompanhar a demanda.';
      } else {
        return 'Hoje é dia de descanso. Sua meta de calorias está um pouco menor para recuperar.';
      }
    } catch (_) {
      return 'Mantenha uma alimentação equilibrada para atingir seus objetivos!';
    }
  }

  Future<String> getHydrationMessage() async {
    final now = DateTime.now();
    final weekNumber = (now.difference(DateTime(now.year, 1, 1)).inDays / 7).ceil();

    try {
      final workouts = await _api.get<List<dynamic>>('/workouts', queryParams: {
        'weekNumber': weekNumber.toString(),
      });

      final todayWorkout = workouts.where((w) {
        final dateStr = w['date'] as String?;
        if (dateStr == null) return false;
        final date = DateTime.tryParse(dateStr);
        return date != null && _isSameDay(date, now);
      }).toList();

      if (todayWorkout.isNotEmpty) {
        return 'Você treinou hoje! Beba pelo menos 500ml de água a mais para repor o que perdeu no treino.';
      } else {
        return 'Mantenha-se hidratado! Beba água ao longo do dia.';
      }
    } catch (_) {
      return 'Mantenha-se hidratado! Beba água ao longo do dia.';
    }
  }

  Future<String> getProgressMessage() async {
    final now = DateTime.now();
    final weekNumber = (now.difference(DateTime(now.year, 1, 1)).inDays / 7).ceil();

    try {
      final currentWeek = await _api.get<List<dynamic>>('/workouts', queryParams: {
        'weekNumber': weekNumber.toString(),
      });

      final lastWeek = await _api.get<List<dynamic>>('/workouts', queryParams: {
        'weekNumber': (weekNumber - 1).toString(),
      });

      final currentVolume = currentWeek.fold<double>(0, (sum, w) {
        return sum + ((w['totalVolume'] as num?)?.toDouble() ?? 0);
      });

      final lastVolume = lastWeek.fold<double>(0, (sum, w) {
        return sum + ((w['totalVolume'] as num?)?.toDouble() ?? 0);
      });

      if (lastVolume == 0) {
        return 'Comece a treinar para ver seu progresso aqui!';
      }

      final change = ((currentVolume - lastVolume) / lastVolume * 100).round();

      if (change > 0) {
        return 'Você aumentou seu volume em $change% esta semana! Continue assim!';
      } else if (change < 0) {
        return 'Seu volume diminuiu $change% esta semana. Não desanime, volte com tudo!';
      } else {
        return 'Seu volume está estável esta semana. Que tal tentar aumentar um pouco?';
      }
    } catch (_) {
      return 'Comece a treinar para ver seu progresso aqui!';
    }
  }

  String _getPostWorkoutMessage() {
    final messages = [
      'Ótimo treino! Lembre-se de comer algo com proteína nas próximas 2 horas.',
      'Treino concluído! Sua refeição pós-treino é importante para a recuperação.',
      'Parabéns! Agora é hora de recuperar. Beba água e coma bem.',
    ];
    return messages[DateTime.now().millisecond % messages.length];
  }

  String _getPreWorkoutMessage(int current, int target) {
    final remaining = target - current;
    if (remaining == 1) {
      return 'Falta 1 treino para completar sua semana! Vamos lá!';
    } else {
      return 'Faltam $remaining treinos para completar sua semana. Você consegue!';
    }
  }

  String _getRestDayMessage() {
    return 'Você completou todos os treinos da semana! Hoje é dia de descanso e recuperação.';
  }

  Future<Map<String, dynamic>?> _getProfile() async {
    try {
      return await _api.get<Map<String, dynamic>>('/users/profile');
    } catch (_) {
      return null;
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
