import '../../core/services/api_service.dart';
import '../../features/exercises/exercise_model.dart';

// ─────────────────────────────────────────────
// Enum de tipo de sugestão
// ─────────────────────────────────────────────

enum ProgressionType {
  increaseWeight,
  increaseReps,
  decreaseWeight,
  maintain,
  deloadWeek,
}

// ─────────────────────────────────────────────
// Model de sugestão
// ─────────────────────────────────────────────

class ProgressionSuggestion {
  final ExerciseModel exercise;
  final ProgressionType type;
  final String title;
  final String reason;
  final double? suggestedWeight;
  final int? suggestedReps;
  final double? currentWeight;
  final int? currentReps;
  final int consecutiveWeeks;

  const ProgressionSuggestion({
    required this.exercise,
    required this.type,
    required this.title,
    required this.reason,
    this.suggestedWeight,
    this.suggestedReps,
    this.currentWeight,
    this.currentReps,
    this.consecutiveWeeks = 0,
  });
}

// ─────────────────────────────────────────────
// Serviço principal
// ─────────────────────────────────────────────

class ProgressionService {
  final ApiService _api;

  ProgressionService({ApiService? api}) : _api = api ?? ApiService();

  Future<List<ProgressionSuggestion>> generateSuggestions(
    List<ExerciseModel> exercises,
  ) async {
    if (exercises.isEmpty) return [];

    try {
      final exerciseIds = exercises.map((e) => e.id).toList();
      final result = await _api.get('/progression/suggestions', queryParams: {
        'exerciseIds': exerciseIds.join(','),
      });

      final suggestionsData = result['suggestions'] as List<dynamic>? ?? [];
      final suggestions = <ProgressionSuggestion>[];

      for (final item in suggestionsData) {
        final m = item as Map<String, dynamic>;
        final exId = m['exerciseId'] as String? ?? '';
        final exercise = exercises.where((e) => e.id == exId).firstOrNull;
        if (exercise == null) continue;

        final typeStr = m['type'] as String? ?? 'maintain';
        final type = ProgressionType.values.firstWhere(
          (t) => t.name == typeStr,
          orElse: () => ProgressionType.maintain,
        );

        suggestions.add(ProgressionSuggestion(
          exercise: exercise,
          type: type,
          title: m['title'] as String? ?? '',
          reason: m['reason'] as String? ?? '',
          suggestedWeight: (m['suggestedWeight'] as num?)?.toDouble(),
          suggestedReps: (m['suggestedReps'] as num?)?.toInt(),
          currentWeight: (m['currentWeight'] as num?)?.toDouble(),
          currentReps: (m['currentReps'] as num?)?.toInt(),
          consecutiveWeeks: (m['consecutiveWeeks'] as num?)?.toInt() ?? 0,
        ));
      }

      suggestions.sort((a, b) {
        const order = {
          ProgressionType.increaseWeight: 0,
          ProgressionType.increaseReps: 1,
          ProgressionType.maintain: 2,
          ProgressionType.deloadWeek: 3,
          ProgressionType.decreaseWeight: 4,
        };
        return (order[a.type] ?? 5).compareTo(order[b.type] ?? 5);
      });

      return suggestions;
    } catch (e) {
      return [];
    }
  }
}
