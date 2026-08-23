import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ─────────────────────────────────────────────
// Serviço de Coach Digital
// Fornece feedback contextual em linguagem simples
// ─────────────────────────────────────────────

class CoachService {
  final FirebaseFirestore _db;
  final String _uid;

  CoachService({FirebaseFirestore? db, String? uid})
      : _db = db ?? FirebaseFirestore.instance,
        _uid = uid ?? FirebaseAuth.instance.currentUser?.uid ?? '';

  /// Retorna feedback sobre o treino
  Future<String> getWorkoutFeedback() async {
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

    final currentSessions = currentWeekSnap.docs.length;
    final lastSessions = lastWeekSnap.docs.length;

    final currentVolume = currentWeekSnap.docs.fold<double>(0, (sum, doc) {
      return sum + ((doc.data()['totalVolume'] as num?)?.toDouble() ?? 0);
    });

    final lastVolume = lastWeekSnap.docs.fold<double>(0, (sum, doc) {
      return sum + ((doc.data()['totalVolume'] as num?)?.toDouble() ?? 0);
    });

    // Feedback baseado em progresso
    if (currentSessions > lastSessions) {
      return 'Você treinou mais vezes esta semana! Continue assim!';
    } else if (currentVolume > lastVolume * 1.1) {
      return 'Você aumentou seu volume de treino! Seus músculos estão crescendo!';
    } else if (currentVolume < lastVolume * 0.9) {
      return 'Seu volume diminuiu um pouco. Não desanime, volte com tudo!';
    } else {
      return 'Seu treino está consistente! Que tal tentar aumentar um pouco a carga?';
    }
  }

  /// Retorna feedback sobre a nutrição
  Future<String> getNutritionFeedback() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Buscar refeições de hoje
    final mealsSnap = await _db
        .collection('users/$_uid/nutrition/logs/${_formatDate(today)}/meals')
        .get();

    final totalCalories = mealsSnap.docs.fold<double>(0, (sum, doc) {
      return sum + ((doc.data()['calories'] as num?)?.toDouble() ?? 0);
    });

    final totalProtein = mealsSnap.docs.fold<double>(0, (sum, doc) {
      return sum + ((doc.data()['protein'] as num?)?.toDouble() ?? 0);
    });

    // Buscar perfil nutricional
    final profileSnap = await _db
        .collection('users/$_uid/nutrition/settings')
        .doc('settings')
        .get();

    final targetCalories = (profileSnap.data()?['targetCalories'] as num?)?.toDouble() ?? 2000;
    final targetProtein = (profileSnap.data()?['targetProtein'] as num?)?.toDouble() ?? 150;

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
  }

  /// Retorna feedback sobre hidratação
  Future<String> getHydrationFeedback() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Buscar registro de água de hoje
    final waterSnap = await _db
        .collection('users/$_uid/nutrition/logs/${_formatDate(today)}')
        .doc('summary')
        .get();

    final waterMl = (waterSnap.data()?['waterMl'] as num?)?.toInt() ?? 0;
    final targetMl = 2500; // Meta padrão

    final progress = waterMl / targetMl;

    if (progress < 0.5) {
      return 'Você bebeu pouca água hoje. Lembre-se de se hidratar!';
    } else if (progress < 0.8) {
      return 'Você está no caminho! Beba mais um pouco de água.';
    } else {
      return 'Ótima hidratação! Continue assim!';
    }
  }

  /// Retorna feedback sobre progresso geral
  Future<String> getProgressFeedback() async {
    final now = DateTime.now();
    final weekNumber = (now.difference(DateTime(now.year, 1, 1)).inDays / 7).ceil();

    // Buscar treinos das últimas 4 semanas
    final workoutsSnap = await _db
        .collection('users/$_uid/workouts')
        .where('weekNumber', isGreaterThanOrEqualTo: weekNumber - 3)
        .get();

    final weeklyVolumes = <int, double>{};
    for (final doc in workoutsSnap.docs) {
      final week = (doc.data()['weekNumber'] as num?)?.toInt() ?? 0;
      final volume = (doc.data()['totalVolume'] as num?)?.toDouble() ?? 0;
      weeklyVolumes[week] = (weeklyVolumes[week] ?? 0) + volume;
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
  }

  /// Retorna mensagem de motivação
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

  /// Retorna dica do dia
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

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
