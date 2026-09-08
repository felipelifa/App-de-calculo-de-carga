import 'package:flutter/foundation.dart';
import '../../core/services/notification_service.dart';
import 'workout_models.dart';
import 'progression_engine.dart';

class ProgressionProvider extends ChangeNotifier {
  final ProgressionEngine _engine;

  ProgressionProvider() : _engine = ProgressionEngine() {
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

  Future<void> processCompletedSession({
    required List<WorkoutExerciseEntry> exercises,
    required Map<String, int> rirByExercise,
    required Map<String, Map<String, dynamic>> exerciseMetadata,
    required String experienceLevel,
    int sessionsPerWeek = 3,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      _lastDecisions = await _engine.processSession(
        workoutEntries: exercises,
        rirByExercise: rirByExercise,
        exerciseMetadata: exerciseMetadata,
        experienceLevel: experienceLevel,
        sessionsPerWeek: sessionsPerWeek,
      );
      _state = await _engine.loadState();

      if (_state?.isDeloadWeek == true) {
        await NotificationService.scheduleDeloadAlert();
      }
    } catch (e) {
      _error = 'Erro ao processar progressão: $e';
      debugPrint('ProgressionProvider.processCompletedSession error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  ProgressionDecision? decisionForExercise(String exerciseId) {
    try {
      return _lastDecisions.firstWhere((d) => d.exerciseId == exerciseId);
    } catch (_) {
      return null;
    }
  }

  double? suggestedWeightFor(String exerciseId) {
    return decisionForExercise(exerciseId)?.suggestedWeightKg;
  }

  void clearDecisions() {
    _lastDecisions = [];
    notifyListeners();
  }
}
