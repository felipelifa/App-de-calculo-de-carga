import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────────
// Modelos de dados para Analytics
// ─────────────────────────────────────────────

class WeeklyVolumePoint {
  final int weekNumber;
  final double volume;
  final DateTime weekStart;

  const WeeklyVolumePoint({
    required this.weekNumber,
    required this.volume,
    required this.weekStart,
  });
}

class ExerciseLoadPoint {
  final DateTime date;
  final double maxWeight;
  final double avgWeight;

  const ExerciseLoadPoint({
    required this.date,
    required this.maxWeight,
    required this.avgWeight,
  });
}

class MuscleVolumeBar {
  final String muscle;
  final double volume;
  final double lastPeriodVolume;

  const MuscleVolumeBar({
    required this.muscle,
    required this.volume,
    required this.lastPeriodVolume,
  });
}

class ExerciseSummary {
  final String id;
  final String name;
  final String muscleGroup;

  const ExerciseSummary({
    required this.id,
    required this.name,
    required this.muscleGroup,
  });
}

class AnalyticsData {
  final List<WeeklyVolumePoint> weeklyVolume;
  final Map<String, List<ExerciseLoadPoint>> exerciseLoad;
  final List<MuscleVolumeBar> muscleVolume;
  final List<ExerciseSummary> exercises;
  final int totalSessions;
  final double totalVolume;
  final double bestWeekVolume;
  final int bestWeekNumber;

  const AnalyticsData({
    required this.weeklyVolume,
    required this.exerciseLoad,
    required this.muscleVolume,
    required this.exercises,
    required this.totalSessions,
    required this.totalVolume,
    required this.bestWeekVolume,
    required this.bestWeekNumber,
  });
}

// ─────────────────────────────────────────────
// Service
// ─────────────────────────────────────────────

class AnalyticsService {
  final FirebaseFirestore _db;
  final String _uid;

  AnalyticsService({required FirebaseFirestore db, required String uid})
      : _db = db,
        _uid = uid;

  Future<AnalyticsData> load({int limitWeeks = 12}) async {
    // Busca as últimas sessões (máximo 200 para cobrir 12 semanas com vários treinos)
    final snap = await _db
        .collection('users/$_uid/workouts')
        .orderBy('date', descending: false)
        .limit(200)
        .get();

    if (snap.docs.isEmpty) {
      return AnalyticsData(
        weeklyVolume: [],
        exerciseLoad: {},
        muscleVolume: [],
        exercises: [],
        totalSessions: 0,
        totalVolume: 0,
        bestWeekVolume: 0,
        bestWeekNumber: 0,
      );
    }

    // ── Volume semanal ──
    final Map<int, double> weekVolumeMap = {};
    final Map<int, DateTime> weekStartMap = {};

    // ── Carga por exercício ──
    final Map<String, String> exerciseNames = {};
    final Map<String, String> exerciseMuscles = {};
    final Map<String, List<ExerciseLoadPoint>> exerciseLoadMap = {};

    // ── Volume por músculo (últimas 4 semanas vs 4 anteriores) ──
    final int currentWeek = _currentWeekNumber();
    final Map<String, double> recentMuscleVol = {};
    final Map<String, double> prevMuscleVol = {};

    double totalVolume = 0;

    for (final doc in snap.docs) {
      final d = doc.data();
      final week = (d['weekNumber'] as num?)?.toInt() ?? 0;
      final vol = (d['totalVolume'] as num?)?.toDouble() ?? 0;
      final date = (d['date'] as Timestamp?)?.toDate() ?? DateTime.now();

      weekVolumeMap[week] = (weekVolumeMap[week] ?? 0) + vol;
      weekStartMap.putIfAbsent(week, () => _weekStart(date));
      totalVolume += vol;

      final exercises = (d['exercises'] as List<dynamic>?) ?? [];
      for (final ex in exercises) {
        final em = ex as Map<String, dynamic>;
        final exId = em['exerciseId'] as String? ?? '';
        final exName = em['exerciseName'] as String? ?? 'Exercício';
        final muscle = em['muscleGroup'] as String? ?? 'Outro';
        final exVol = (em['volume'] as num?)?.toDouble() ?? 0;

        exerciseNames[exId] = exName;
        exerciseMuscles[exId] = muscle;

        // Volume por músculo
        final weeksAgo = currentWeek - week;
        if (weeksAgo >= 0 && weeksAgo < 4) {
          recentMuscleVol[muscle] = (recentMuscleVol[muscle] ?? 0) + exVol;
        } else if (weeksAgo >= 4 && weeksAgo < 8) {
          prevMuscleVol[muscle] = (prevMuscleVol[muscle] ?? 0) + exVol;
        }

        // Carga por exercício
        if (exId.isNotEmpty) {
          final sets = (em['sets'] as List<dynamic>?) ?? [];
          if (sets.isNotEmpty) {
            double maxW = 0;
            double totalW = 0;
            int count = 0;
            for (final s in sets) {
              final sm = s as Map<String, dynamic>;
              final w = (sm['weight'] as num?)?.toDouble() ?? 0;
              if (w > maxW) maxW = w;
              totalW += w;
              count++;
            }
            final avgW = count > 0 ? totalW / count : 0.0;

            exerciseLoadMap.putIfAbsent(exId, () => []);
            // Agrupa por sessão (uma entrada por dia)
            final existing = exerciseLoadMap[exId]!;
            final sameDay = existing.indexWhere((p) =>
                p.date.year == date.year &&
                p.date.month == date.month &&
                p.date.day == date.day);
            if (sameDay == -1) {
              exerciseLoadMap[exId]!.add(ExerciseLoadPoint(
                date: DateTime(date.year, date.month, date.day),
                maxWeight: maxW,
                avgWeight: avgW,
              ));
            } else {
              // Mantém o maior peso do dia
              final prev = existing[sameDay];
              existing[sameDay] = ExerciseLoadPoint(
                date: prev.date,
                maxWeight: maxW > prev.maxWeight ? maxW : prev.maxWeight,
                avgWeight: (avgW + prev.avgWeight) / 2,
              );
            }
          }
        }
      }
    }

    // ── Montar lista de volume semanal ordenada ──
    final allWeeks = weekVolumeMap.keys.toList()..sort();
    // Pega as últimas limitWeeks semanas
    final recentWeeks = allWeeks.length > limitWeeks
        ? allWeeks.sublist(allWeeks.length - limitWeeks)
        : allWeeks;

    final weeklyVolume = recentWeeks.map((w) {
      return WeeklyVolumePoint(
        weekNumber: w,
        volume: weekVolumeMap[w]!,
        weekStart: weekStartMap[w] ?? DateTime.now(),
      );
    }).toList();

    // ── Melhor semana ──
    double bestWeekVolume = 0;
    int bestWeekNumber = 0;
    for (final entry in weekVolumeMap.entries) {
      if (entry.value > bestWeekVolume) {
        bestWeekVolume = entry.value;
        bestWeekNumber = entry.key;
      }
    }

    // ── Volume por músculo ──
    final allMuscles = {
      ...recentMuscleVol.keys,
      ...prevMuscleVol.keys,
    };
    final muscleVolume = allMuscles.map((m) {
      return MuscleVolumeBar(
        muscle: m,
        volume: recentMuscleVol[m] ?? 0,
        lastPeriodVolume: prevMuscleVol[m] ?? 0,
      );
    }).toList()
      ..sort((a, b) => b.volume.compareTo(a.volume));

    // ── Lista de exercícios com histórico ──
    final exercises = exerciseNames.entries
        .where((e) =>
            exerciseLoadMap[e.key] != null &&
            exerciseLoadMap[e.key]!.length >= 2)
        .map((e) => ExerciseSummary(
              id: e.key,
              name: e.value,
              muscleGroup: exerciseMuscles[e.key] ?? '',
            ))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return AnalyticsData(
      weeklyVolume: weeklyVolume,
      exerciseLoad: exerciseLoadMap,
      muscleVolume: muscleVolume.take(8).toList(),
      exercises: exercises,
      totalSessions: snap.docs.length,
      totalVolume: totalVolume,
      bestWeekVolume: bestWeekVolume,
      bestWeekNumber: bestWeekNumber,
    );
  }

  int _currentWeekNumber() {
    final now = DateTime.now();
    return (now.difference(DateTime(now.year, 1, 1)).inDays / 7).ceil();
  }

  DateTime _weekStart(DateTime date) {
    final weekday = date.weekday;
    return date.subtract(Duration(days: weekday - 1));
  }
}
