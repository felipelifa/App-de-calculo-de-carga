import '../exercises/exercise_model.dart';
import 'workout_profile_model.dart';

class CompatibilityResult {
  final bool allowed;
  final String reason;

  const CompatibilityResult(this.allowed, this.reason);
}

/// Fonte única das hard constraints de ambiente, equipamento e nível.
class ExerciseCompatibility {
  static const _equipmentAliases = <String, String>{
    'dumbbells': 'dumbbell',
    'dumbbell': 'dumbbell',
    'cables': 'cable',
    'cable': 'cable',
    'machines': 'machine',
    'machine': 'machine',
    'bands': 'band',
    'band': 'band',
    'pullup_bar': 'pull_up_bar',
    'pull_up_bar': 'pull_up_bar',
    'body_weight': 'bodyweight',
    'bodyweight': 'bodyweight',
    'none': 'none',
  };

  static String normalizeEquipment(String value) {
    final normalized = value.trim().toLowerCase();
    return _equipmentAliases[normalized] ?? normalized;
  }

  static List<String> normalizeEquipmentList(Iterable<String> equipment) =>
      equipment.map(normalizeEquipment).where((e) => e.isNotEmpty).toSet().toList();

  static bool isHome(String environment) {
    final value = environment.trim().toLowerCase();
    return value == 'home' || value.startsWith('home_') || value == 'outdoor';
  }

  static CompatibilityResult evaluate({
    required WorkoutProfile profile,
    required ExerciseModel exercise,
  }) {
    final environment = profile.environment.trim().toLowerCase();
    final exerciseEnvironments = exercise.environment
        .map((e) => e.trim().toLowerCase())
        .toSet();
    final available = normalizeEquipmentList(profile.availableEquipment);
    final exerciseEquipment = normalizeEquipmentList(exercise.equipment);
    final home = isHome(environment);

    final environmentAllowed = home
        ? exerciseEnvironments.contains('home') ||
            (environment == 'outdoor' &&
                exerciseEquipment.every((e) => e == 'bodyweight' || e == 'none'))
        : exerciseEnvironments.contains('gym');
    if (!environmentAllowed) {
      return CompatibilityResult(false, 'Ambiente incompatível com o exercício.');
    }

    if (home) {
      if (available.isEmpty) {
        // Quando não há lista de equipamentos, inferir pelo ambiente escolhido
        final isBodyweightOnly = environment == 'home_bodyweight' || environment == 'outdoor';
        if (isBodyweightOnly) {
          // Só permite bodyweight/none
          final requiresEquipment = exerciseEquipment.any(
            (equipment) => equipment != 'bodyweight' && equipment != 'none',
          );
          if (requiresEquipment) {
            return const CompatibilityResult(
              false,
              'Exige equipamento, mas o ambiente é apenas peso corporal.',
            );
          }
        } else {
          // home_dumbbell sem lista: permite bodyweight + dumbbell
          final allowedInferred = {'bodyweight', 'none', 'dumbbell'};
          final requiresUnavailable = exerciseEquipment.any(
            (equipment) => !allowedInferred.contains(equipment),
          );
          if (requiresUnavailable) {
            return const CompatibilityResult(
              false,
              'Exige equipamento não disponível no ambiente de casa.',
            );
          }
        }
      } else {
        final hasMatchingEquipment = exerciseEquipment.isEmpty ||
            exerciseEquipment.contains('bodyweight') ||
            exerciseEquipment.any(available.contains);
        if (!hasMatchingEquipment) {
          return const CompatibilityResult(false, 'Equipamento não disponível.');
        }
      }
    } else if (available.isNotEmpty) {
      final hasMatchingEquipment = exerciseEquipment.isEmpty ||
          exerciseEquipment.contains('bodyweight') ||
          exerciseEquipment.any(available.contains);
      if (!hasMatchingEquipment) {
        return const CompatibilityResult(false, 'Equipamento não disponível.');
      }
    }

    if (exercise.restrictions.any(profile.healthRestrictions.contains)) {
      return const CompatibilityResult(false, 'Conflita com uma restrição informada.');
    }
    if (profile.experienceLevel == 'beginner' && exercise.difficulty == 'advanced') {
      return const CompatibilityResult(false, 'Complexidade acima do nível atual.');
    }
    if (profile.dislikedExercises.contains(exercise.id)) {
      return const CompatibilityResult(false, 'Exercício marcado como indesejado.');
    }

    return const CompatibilityResult(true, 'Compatível com o contexto atual.');
  }

  static bool isCompatible(WorkoutProfile profile, ExerciseModel exercise) =>
      evaluate(profile: profile, exercise: exercise).allowed;
}
