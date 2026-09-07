import 'package:flutter/foundation.dart';
import '../exercises/exercise_model.dart';
import 'workout_profile_model.dart';

class CompatibilityResult {
  final bool allowed;
  final String reason;
  final String code;
  final List<String> requiredEquipment;
  final List<String> availableEquipment;

  const CompatibilityResult(
    this.allowed,
    this.reason, [
    this.code = 'eligible',
    this.requiredEquipment = const [],
    this.availableEquipment = const [],
  ]);
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
    'smith_machine': 'smith',
    'smith': 'smith',
    'olympic_bar': 'barbell',
    'bar': 'barbell',
    'bars': 'barbell',
    'trx_suspension': 'trx',
    'suspension': 'trx',
    'body_weight': 'bodyweight',
    'bodyweight': 'bodyweight',
    'none': 'none',
  };

  static String normalizeEquipment(String value) {
    final normalized = value.trim().toLowerCase();
    return _equipmentAliases[normalized] ?? normalized;
  }

  static List<String> normalizeEquipmentList(Iterable<String> equipment) =>
      equipment
          .map(normalizeEquipment)
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList();

  /// `bodyweight` is a capability marker, not a piece of equipment.
  static List<String> requiredEquipment(Iterable<String> equipment) =>
      normalizeEquipmentList(
        equipment,
      ).where((item) => item != 'bodyweight' && item != 'none').toList();

  static bool areEquipmentRequirementsMet({
    required Iterable<String> required,
    required Iterable<String> available,
  }) {
    final requiredSet = requiredEquipment(required).toSet();
    final availableSet = normalizeEquipmentList(available).toSet();
    return requiredSet.every(availableSet.contains);
  }

  static bool isEnvironmentCompatible(
    WorkoutProfile profile,
    ExerciseModel exercise,
  ) {
    final environment = profile.environment.trim().toLowerCase();
    final exerciseEnvironments = exercise.environment
        .map((value) => value.trim().toLowerCase())
        .toSet();
    final required = requiredEquipment(exercise.equipment);
    final home = isHome(environment);
    return home
        ? exerciseEnvironments.contains('home') &&
              (environment != 'outdoor' || required.isEmpty)
        : exerciseEnvironments.contains('gym');
  }

  /// Removes ineligible exercises before objective, adequacy or ranking logic.
  static List<ExerciseModel> filterEligible({
    required WorkoutProfile profile,
    required Iterable<ExerciseModel> exercises,
  }) => exercises.where((exercise) {
    final result = evaluate(
      profile: profile,
      exercise: exercise,
      log: false,
    );
    if (!result.allowed) {
      _logRejected(
        exercise: exercise,
        required: result.requiredEquipment,
        available: result.availableEquipment,
        environment: profile.environment,
        reason: result.code,
      );
    }
    return result.allowed;
  }).toList();

  static bool areProfileEquipmentRequirementsMet(
    WorkoutProfile profile,
    ExerciseModel exercise,
  ) {
    final available = normalizeEquipmentList(profile.availableEquipment);
    final home = isHome(profile.environment);
    final fullGym = !home && available.contains('full_gym');
    if (fullGym) return true;
    return areEquipmentRequirementsMet(
      required: exercise.equipment,
      available: available,
    );
  }

  static bool isHome(String environment) {
    final value = environment.trim().toLowerCase();
    return value == 'home' || value.startsWith('home_') || value == 'outdoor';
  }

  static CompatibilityResult evaluate({
    required WorkoutProfile profile,
    required ExerciseModel exercise,
    bool log = true,
  }) {
    final environment = profile.environment.trim().toLowerCase();
    final available = normalizeEquipmentList(profile.availableEquipment);
    final exerciseEquipment = normalizeEquipmentList(exercise.equipment);
    final required = requiredEquipment(exerciseEquipment);

    if (!exercise.equipmentMetadataVerified) {
      return _rejected(
        false,
        'Requisitos de equipamento não auditados.',
        'equipment_metadata_unverified',
        exercise,
        required,
        available,
        environment,
        log: log,
      );
    }

    if (!isEnvironmentCompatible(profile, exercise)) {
      return _rejected(
        false,
        'Ambiente incompatível com o exercício.',
        'environment_not_supported',
        exercise,
        required,
        available,
        environment,
        log: log,
      );
    }

    if (!areProfileEquipmentRequirementsMet(profile, exercise)) {
      return _rejected(
        false,
        'Equipamento não disponível.',
        'equipment_not_available',
        exercise,
        required,
        available,
        environment,
        log: log,
      );
    }

    if (exercise.restrictions.any(profile.healthRestrictions.contains)) {
      return _rejected(
        false,
        'Conflita com uma restrição informada.',
        'health_restriction',
        exercise,
        required,
        available,
        environment,
        log: log,
      );
    }
    if (profile.dislikedExercises.contains(exercise.id)) {
      return _rejected(
        false,
        'Exercício marcado como indesejado.',
        'user_disliked',
        exercise,
        required,
        available,
        environment,
        log: log,
      );
    }

    final result = CompatibilityResult(
      true,
      'Compatível com o contexto atual.',
      'eligible',
      required,
      available,
    );
    if (log) {
      debugPrint(
        'ELIGIBLE Exercise: ${exercise.name} | Environment: $environment | '
        'Available equipment: ${available.isEmpty ? '[]' : available} | '
        'Required equipment: ${required.isEmpty ? '[]' : required} | '
        'Reason: ${required.isEmpty ? 'NO_EQUIPMENT_REQUIRED' : 'EQUIPMENT_AVAILABLE'}',
      );
    }
    return result;
  }

  static CompatibilityResult _rejected(
    bool allowed,
    String reason,
    String code,
    ExerciseModel exercise,
    List<String> required,
    List<String> available,
    String environment,
    {bool log = true}
  ) {
    if (log) {
      _logRejected(
        exercise: exercise,
        required: required,
        available: available,
        environment: environment,
        reason: code,
      );
    }
    return CompatibilityResult(allowed, reason, code, required, available);
  }

  static void _logRejected({
    required ExerciseModel exercise,
    required List<String> required,
    required List<String> available,
    required String environment,
    required String reason,
  }) {
    debugPrint(
      'REJECTED Exercise: ${exercise.name} | Environment: $environment | '
      'Available equipment: ${available.isEmpty ? '[]' : available} | '
      'Required equipment: ${required.isEmpty ? '[]' : required} | '
      'Reason: ${reason == 'equipment_not_available'
          ? 'EQUIPMENT_NOT_AVAILABLE'
          : reason}',
    );
  }

  static bool isCompatible(WorkoutProfile profile, ExerciseModel exercise) =>
      evaluate(profile: profile, exercise: exercise).allowed;
}
