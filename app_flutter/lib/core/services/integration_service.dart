import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ─────────────────────────────────────────────
// Serviço de Integração Treino + Nutrição
// Fornece mensagens contextuais em linguagem simples
// ─────────────────────────────────────────────

class IntegrationService {
  final FirebaseFirestore _db;
  final String _uid;

  IntegrationService({FirebaseFirestore? db, String? uid})
      : _db = db ?? FirebaseFirestore.instance,
        _uid = uid ?? FirebaseAuth.instance.currentUser?.uid ?? '';

  /// Retorna mensagem contextual sobre o dia
  Future<String> getTodayMessage() async {
    final now = DateTime.now();
    final weekNumber = (now.difference(DateTime(now.year, 1, 1)).inDays / 7).ceil();
    final weekday = now.weekday; // 1=Segunda, 7=Domingo

    // Buscar treinos da semana
    final workoutsSnap = await _db
        .collection('users/$_uid/workouts')
        .where('weekNumber', isEqualTo: weekNumber)
        .get();

    final weekSessions = workoutsSnap.docs.length;
    final todayWorkout = workoutsSnap.docs.where((doc) {
      final date = (doc.data()['date'] as Timestamp?)?.toDate();
      return date != null && _isSameDay(date, now);
    }).toList();

    // Verificar se treinou hoje
    if (todayWorkout.isNotEmpty) {
      return _getPostWorkoutMessage();
    }

    // Verificar se é dia de treino
    final profile = await _getProfile();
    final targetDays = profile?['availableDaysPerWeek'] ?? 3;

    if (weekSessions < targetDays) {
      return _getPreWorkoutMessage(weekSessions, targetDays);
    } else {
      return _getRestDayMessage();
    }
  }

  /// Retorna mensagem sobre nutrição baseada no treino
  Future<String> getNutritionMessage() async {
    final now = DateTime.now();
    final weekNumber = (now.difference(DateTime(now.year, 1, 1)).inDays / 7).ceil();

    // Buscar treinos da semana
    final workoutsSnap = await _db
        .collection('users/$_uid/workouts')
        .where('weekNumber', isEqualTo: weekNumber)
        .get();

    final weekSessions = workoutsSnap.docs.length;
    final todayWorkout = workoutsSnap.docs.where((doc) {
      final date = (doc.data()['date'] as Timestamp?)?.toDate();
      return date != null && _isSameDay(date, now);
    }).toList();

    if (todayWorkout.isNotEmpty) {
      return 'Hoje é um dia de treino. Sua meta de carboidratos está um pouco maior para acompanhar a demanda.';
    } else {
      return 'Hoje é dia de descanso. Sua meta de calorias está um pouco menor para recuperar.';
    }
  }

  /// Retorna mensagem sobre hidratação
  Future<String> getHydrationMessage() async {
    final now = DateTime.now();
    final weekNumber = (now.difference(DateTime(now.year, 1, 1)).inDays / 7).ceil();

    final workoutsSnap = await _db
        .collection('users/$_uid/workouts')
        .where('weekNumber', isEqualTo: weekNumber)
        .get();

    final todayWorkout = workoutsSnap.docs.where((doc) {
      final date = (doc.data()['date'] as Timestamp?)?.toDate();
      return date != null && _isSameDay(date, now);
    }).toList();

    if (todayWorkout.isNotEmpty) {
      return 'Você treinou hoje! Beba pelo menos 500ml de água a mais para repor o que perdeu no treino.';
    } else {
      return 'Mantenha-se hidratado! Beba água ao longo do dia.';
    }
  }

  /// Retorna mensagem sobre progresso
  Future<String> getProgressMessage() async {
    final now = DateTime.now();
    final weekNumber = (now.difference(DateTime(now.year, 1, 1)).inDays / 7).ceil();

    // Buscar treinos da semana atual e anterior
    final currentWeekSnap = await _db
        .collection('users/$_uid/workouts')
        .where('weekNumber', isEqualTo: weekNumber)
        .get();

    final lastWeekSnap = await _db
        .collection('users/$_uid/workouts')
        .where('weekNumber', isEqualTo: weekNumber - 1)
        .get();

    final currentVolume = currentWeekSnap.docs.fold<double>(0, (sum, doc) {
      return sum + ((doc.data()['totalVolume'] as num?)?.toDouble() ?? 0);
    });

    final lastVolume = lastWeekSnap.docs.fold<double>(0, (sum, doc) {
      return sum + ((doc.data()['totalVolume'] as num?)?.toDouble() ?? 0);
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
    final doc = await _db.collection('users/$_uid/profile/current').get();
    return doc.data();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
