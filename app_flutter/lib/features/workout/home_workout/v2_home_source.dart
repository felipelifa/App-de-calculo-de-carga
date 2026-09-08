import 'package:flutter/foundation.dart';

import '../../exercise_library_v2/v2_exercise_library.dart';
import '../../exercise_library_v2/data/home_exercises.dart';
import '../../exercise_library_v2/queries/exercise_query.dart';
import '../../exercise_library_v2/bridge/v2_home_bridge.dart';
import '../../exercise_library_v2/enums/exercise_block.dart';
import '../../exercise_library_v2/enums/environment.dart';
import '../../exercise_library_v2/enums/difficulty.dart';
import '../../exercise_library_v2/enums/equipment.dart';
import '../../exercises/exercise_model.dart';
import '../workout_profile_model.dart';

/// Fonte de exercícios Home V2 com fallback para V1.
///
/// Responsável por:
/// 1. Registrar os 46 exercícios V2 Home na V2ExerciseLibrary
/// 2. Fornecer exercícios V2 convertidos para ExerciseModel
/// 3. Fallback para V1 quando V2 não está disponível
class V2HomeSource {
  static bool _initialized = false;

  /// Inicializa a V2ExerciseLibrary com os exercícios Home.
  /// Chamado uma única vez no startup do app.
  static void initialize() {
    if (_initialized) return;

    final library = V2ExerciseLibrary();
    final homeExercises = createHomeExercises();
    library.registerAll(homeExercises);
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
  /// Retorna ExerciseModel[] pronto para uso no motor V1.
  /// O ExerciseModel.id será o V2Exercise.id original.
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
      availableEquipment: _availableEquipmentList(profile),
      maxDifficulty: _maxDifficulty(profile),
      excludeIds: excludeIds,
    );

    final v2Results = library.query(query);

    if (v2Results.isEmpty) {
      debugPrint('V2_HOME: consulta retornou 0 resultados.');
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

  // ── Helpers privados ──

  static List<V2Equipment> _availableEquipmentList(WorkoutProfile profile) {
    // Home sem equipamento: lista vazia (bodyweight não é equipamento)
    final equipment = List<String>.from(profile.availableEquipment);
    equipment.remove('bodyweight');
    equipment.remove('none');
    // Para home sem equipamento, retorna lista vazia
    // (V2Home não requer equipamento externo)
    return const [];
  }

  static V2Difficulty _maxDifficulty(WorkoutProfile profile) {
    switch (profile.experienceLevel) {
      case 'beginner':
        return V2Difficulty.level3;
      case 'intermediate':
        return V2Difficulty.level4;
      case 'advanced':
        return V2Difficulty.level5;
      default:
        return V2Difficulty.level3;
    }
  }
}
