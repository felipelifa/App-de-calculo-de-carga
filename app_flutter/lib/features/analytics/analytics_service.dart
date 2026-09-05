import '../../core/services/api_service.dart';

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
// Service — agora usa API em vez de Firestore
// ─────────────────────────────────────────────

class AnalyticsService {
  final String _uid;
  final ApiService _api = ApiService();

  AnalyticsService({required String uid}) : _uid = uid;

  Future<AnalyticsData> load({int limitWeeks = 12}) async {
    try {
      final response = await _api.get('/analytics/summary', queryParams: {
        'limitWeeks': limitWeeks.toString(),
      });

      final weeklyVolumeRaw = (response['weeklyVolume'] as List<dynamic>?) ?? [];
      final weeklyVolume = weeklyVolumeRaw.map((w) {
        final wm = w as Map<String, dynamic>;
        return WeeklyVolumePoint(
          weekNumber: (wm['weekNumber'] as num?)?.toInt() ?? 0,
          volume: (wm['volume'] as num?)?.toDouble() ?? 0,
          weekStart: DateTime.tryParse(wm['weekStart'] as String? ?? '') ?? DateTime.now(),
        );
      }).toList();

      final exerciseLoadRaw = response['exerciseLoad'] as Map<String, dynamic>? ?? {};
      final exerciseLoad = <String, List<ExerciseLoadPoint>>{};
      exerciseLoadRaw.forEach((key, value) {
        final points = (value as List<dynamic>).map((p) {
          final pm = p as Map<String, dynamic>;
          return ExerciseLoadPoint(
            date: DateTime.tryParse(pm['date'] as String? ?? '') ?? DateTime.now(),
            maxWeight: (pm['maxWeight'] as num?)?.toDouble() ?? 0,
            avgWeight: (pm['avgWeight'] as num?)?.toDouble() ?? 0,
          );
        }).toList();
        exerciseLoad[key] = points;
      });

      final muscleVolumeRaw = (response['muscleVolume'] as List<dynamic>?) ?? [];
      final muscleVolume = muscleVolumeRaw.map((m) {
        final mm = m as Map<String, dynamic>;
        return MuscleVolumeBar(
          muscle: mm['muscle'] as String? ?? '',
          volume: (mm['volume'] as num?)?.toDouble() ?? 0,
          lastPeriodVolume: (mm['lastPeriodVolume'] as num?)?.toDouble() ?? 0,
        );
      }).toList();

      final exercisesRaw = (response['exercises'] as List<dynamic>?) ?? [];
      final exercises = exercisesRaw.map((e) {
        final em = e as Map<String, dynamic>;
        return ExerciseSummary(
          id: em['id'] as String? ?? '',
          name: em['name'] as String? ?? '',
          muscleGroup: em['muscleGroup'] as String? ?? '',
        );
      }).toList();

      return AnalyticsData(
        weeklyVolume: weeklyVolume,
        exerciseLoad: exerciseLoad,
        muscleVolume: muscleVolume,
        exercises: exercises,
        totalSessions: (response['totalSessions'] as num?)?.toInt() ?? 0,
        totalVolume: (response['totalVolume'] as num?)?.toDouble() ?? 0,
        bestWeekVolume: (response['bestWeekVolume'] as num?)?.toDouble() ?? 0,
        bestWeekNumber: (response['bestWeekNumber'] as num?)?.toInt() ?? 0,
      );
    } catch (e) {
      // Fallback: retorna dados vazios em caso de erro
      return const AnalyticsData(
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
  }
}
