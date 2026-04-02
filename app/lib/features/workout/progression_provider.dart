import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'workout_models.dart';
import 'progression_engine.dart';

// ═══════════════════════════════════════════════════════════════
// Provider do Motor de Progressão
//
// Expõe o estado de progressão para a UI e coordena as
// chamadas ao ProgressionEngine após cada sessão concluída.
// ═══════════════════════════════════════════════════════════════

class ProgressionProvider extends ChangeNotifier {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final ProgressionEngine _engine;

  ProgressionProvider({FirebaseFirestore? db, FirebaseAuth? auth})
      : _db = db ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _engine = ProgressionEngine(
          db: db ?? FirebaseFirestore.instance,
          auth: auth ?? FirebaseAuth.instance,
        ) {
    _load();
  }

  ProgressionState? _state;
  List<ProgressionDecision> _lastDecisions = [];
  bool _isLoading = false;
  String? _error;

  ProgressionState? get state => _state;
  List<ProgressionDecision> get lastDecisions =>
      List.unmodifiable(_lastDecisions);
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isDeloadWeek => _state?.isDeloadWeek ?? false;
  String get currentPhase => _state?.currentPhase ?? 'accumulation';
  int get currentWeek => _state?.currentWeek ?? 1;
  int get weeksUntilDeload => _state?.weeksUntilDeload ?? 4;

  Future<void> _load() async {
    _isLoading = true;
    notifyListeners();
    try {
      _state = await _engine.loadState();
    } catch (e) {
      _error = 'Erro ao carregar progressão: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Inicializa estado quando um novo treino é gerado
  Future<void> initForNewWorkout({
    required String periodizationModel,
    required String experienceLevel,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      _state = await _engine.initializeForNewWorkout(
        periodizationModel: periodizationModel,
        experienceLevel: experienceLevel,
      );
      _lastDecisions = [];
    } catch (e) {
      _error = 'Erro ao inicializar progressão: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Chamado pelo WorkoutProvider após finishSession()
  Future<void> processCompletedSession({
    required List<WorkoutExerciseEntry> exercises,
    required Map<String, int> rirByExercise,
    required Map<String, Map<String, dynamic>> exerciseMetadata,
    required String experienceLevel,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      _lastDecisions = await _engine.processSession(
        workoutEntries: exercises,
        rirByExercise: rirByExercise,
        exerciseMetadata: exerciseMetadata,
        experienceLevel: experienceLevel,
      );
      _state = await _engine.loadState(); // recarrega estado atualizado
    } catch (e) {
      _error = 'Erro ao processar progressão: $e';
      debugPrint('ProgressionProvider.processCompletedSession error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Retorna sugestão para um exercício específico
  ProgressionDecision? decisionForExercise(String exerciseId) {
    try {
      return _lastDecisions.firstWhere((d) => d.exerciseId == exerciseId);
    } catch (_) {
      return null;
    }
  }

  // Retorna a carga sugerida para um exercício
  double? suggestedWeightFor(String exerciseId) {
    return decisionForExercise(exerciseId)?.suggestedWeightKg;
  }

  void clearDecisions() {
    _lastDecisions = [];
    notifyListeners();
  }
}
