import 'package:flutter/foundation.dart';

import '../../exercise_library_v2/v2_exercise_library.dart';
import '../../exercise_library_v2/data/home_exercises.dart';
import '../../exercise_library_v2/queries/exercise_query.dart';
import '../../exercise_library_v2/queries/compatibility_evaluator.dart';
import '../../exercise_library_v2/bridge/v2_home_bridge.dart';
import '../../exercise_library_v2/enums/exercise_block.dart';
import '../../exercise_library_v2/enums/environment.dart';
import '../../exercise_library_v2/enums/difficulty.dart';
import '../../exercise_library_v2/enums/joint.dart';
import '../../exercise_library_v2/enums/limitation_severity.dart';
import '../../exercise_library_v2/models/v2_exercise.dart';
import '../../exercises/exercise_model.dart';
import '../workout_profile_model.dart';

/// Fonte de exercícios Home V2 com fallback para V1.
///
/// Responsável por:
/// 1. Registrar os 46 exercícios V2 Home na V2ExerciseLibrary
/// 2. Fornecer exercícios V2 convertidos para ExerciseModel
/// 3. Usar V2CompatibilityEvaluator para filtrar por limitações
/// 4. Fallback para V1 quando V2 não está disponível
class V2HomeSource {
  static bool _initialized = false;

  /// Inicializa a V2ExerciseLibrary com os exercícios Home.
  /// Também registra no V2HomeBridge para lookup reverso.
  static void initialize() {
    if (_initialized) return;

    final library = V2ExerciseLibrary();
    final homeExercises = createHomeExercises();
    library.registerAll(homeExercises);
    V2HomeBridge.registerAll(homeExercises);
    _initialized = true;

    debugPrint(
      'V2_HOME: ${homeExercises.length} exercícios Home registrados na V2ExerciseLibrary.',
    );
  }

  /// Verifica se a V2 Home está disponível e populada.
  static bool get isAvailable {
    if (!_initialized) return false;
    final library = V2ExerciseLibrary();
    return library.getByBlock(V2ExerciseBlock.home).isNotEmpty;
  }

  /// Retorna o número de exercícios V2 Home disponíveis.
  static int get count {
    if (!isAvailable) return 0;
    return V2ExerciseLibrary().getByBlock(V2ExerciseBlock.home).length;
  }

  /// Consulta exercícios V2 Home compatíveis com o perfil do usuário.
  ///
  /// Fluxo:
  /// 1. Filtro básico por bloco/ambiente/dificuldade (ExerciseQuery)
  /// 2. Filtro de compatibilidade dinâmica (V2CompatibilityEvaluator)
  /// 3. Conversão para ExerciseModel via bridge
  ///
  /// Retorna ExerciseModel[] pronto para uso no motor V1.
  static List<ExerciseModel> queryHomeExercises({
    required WorkoutProfile profile,
    List<String>? excludeIds,
  }) {
    if (!isAvailable) {
      debugPrint('V2_HOME: indisponível — fallback será necessário.');
      return const [];
    }

    final library = V2ExerciseLibrary();
    final query = ExerciseQuery(
      blocks: const [V2ExerciseBlock.home],
      environments: const [V2Environment.home],
      availableEquipment: const [],
      maxDifficulty: _maxDifficulty(profile),
      excludeIds: excludeIds,
    );

    var v2Results = library.query(query);

    if (v2Results.isEmpty) {
      debugPrint('V2_HOME: consulta retornou 0 resultados.');
      return const [];
    }

    v2Results = _applyCompatibilityFilter(v2Results, profile);

    if (v2Results.isEmpty) {
      debugPrint('V2_HOME: todos filtrados por compatibilidade.');
      return const [];
    }

    final result = V2HomeBridge.toExerciseModelList(v2Results);
    debugPrint(
      'V2_HOME: ${result.length} exercícios consultados com sucesso.',
    );
    return result;
  }

  /// Retorna um exercício V2 Home pelo ID.
  /// Útil para resolução de persistência (Supabase → UI).
  static ExerciseModel? getById(String id) {
    if (!isAvailable) return null;

    final library = V2ExerciseLibrary();
    final v2 = library.getById(id);
    if (v2 == null) return null;
    if (v2.block != V2ExerciseBlock.home) return null;

    return V2HomeBridge.toExerciseModel(v2);
  }

  /// Retorna o V2Exercise original pelo ID (lookup reverso).
  static V2Exercise? getV2ById(String id) {
    if (!isAvailable) return null;
    final library = V2ExerciseLibrary();
    return library.getById(id);
  }

  /// Retorna todos os exercícios V2 Home como ExerciseModel.
  static List<ExerciseModel> getAllHomeAsExerciseModel() {
    if (!isAvailable) return const [];

    final library = V2ExerciseLibrary();
    final v2Home = library.getByBlock(V2ExerciseBlock.home);
    return V2HomeBridge.toExerciseModelList(v2Home);
  }

  /// Verifica se um exerciseId pertence ao V2 Home.
  static bool isV2HomeExercise(String exerciseId) {
    if (!isAvailable) return false;

    final library = V2ExerciseLibrary();
    final v2 = library.getById(exerciseId);
    return v2 != null && v2.block == V2ExerciseBlock.home;
  }

  /// Filtra exercícios usando V2CompatibilityEvaluator.
  ///
  /// Converte limitações do profile para UserLimitationInput
  /// e avalia cada exercício contra o contexto do usuário.
  static List<V2Exercise> _applyCompatibilityFilter(
    List<V2Exercise> exercises,
    WorkoutProfile profile,
  ) {
    final userLimitations = _convertLimitations(profile);
    final userDifficulty = _mapExperienceToDifficulty(profile.experienceLevel);

    return V2CompatibilityEvaluator.filterEligible(
      exercises: exercises,
      userEnvironments: const [V2Environment.home, V2Environment.any],
      userEquipment: const [],
      userDifficulty: userDifficulty,
      userLimitations: userLimitations,
      dislikedExerciseIds: profile.dislikedExercises,
    );
  }

  /// Converte limitações do profile para UserLimitationInput do V2.
  static List<UserLimitationInput> _convertLimitations(WorkoutProfile profile) {
    final limitations = <UserLimitationInput>[];
    final restrictions = profile.healthRestrictions;

    for (final restriction in restrictions) {
      final joint = _mapRestrictionToJoint(restriction);
      if (joint != null) {
        limitations.add(UserLimitationInput(
          joint: joint,
          severity: V2LimitationSeverity.moderate,
          symptoms: [restriction],
        ));
      }
    }

    return limitations;
  }

  /// Mapeia restrição de saúde para V2Joint.
  static V2Joint? _mapRestrictionToJoint(String restriction) {
    final lower = restriction.toLowerCase();
    if (lower.contains('joelho') || lower.contains('knee')) return V2Joint.knee;
    if (lower.contains('ombro') || lower.contains('shoulder')) {
      return V2Joint.shoulder;
    }
    if (lower.contains('costas') || lower.contains('lombar') || lower.contains('back')) {
      return V2Joint.spine;
    }
    if (lower.contains('quadril') || lower.contains('hip')) return V2Joint.hip;
    if (lower.contains('tornozelo') || lower.contains('ankle')) {
      return V2Joint.ankle;
    }
    if (lower.contains('cotovelo') || lower.contains('elbow')) {
      return V2Joint.elbow;
    }
    if (lower.contains('pulso') || lower.contains('wrist')) return V2Joint.wrist;
    return null;
  }

  /// Mapeia nível de experiência para V2Difficulty.
  static V2Difficulty _maxDifficulty(WorkoutProfile profile) {
    switch (profile.experienceLevel) {
      case 'beginner':
        return V2Difficulty.level2;
      case 'intermediate':
        return V2Difficulty.level4;
      case 'advanced':
        return V2Difficulty.level5;
      default:
        return V2Difficulty.level3;
    }
  }

  /// Mapeia nível de experiência para V2Difficulty do evaluador.
  static V2Difficulty _mapExperienceToDifficulty(String? level) {
    switch (level) {
      case 'beginner':
        return V2Difficulty.level2;
      case 'intermediate':
        return V2Difficulty.level3;
      case 'advanced':
        return V2Difficulty.level5;
      default:
        return V2Difficulty.level3;
    }
  }
}
