// ─────────────────────────────────────────────
// Motor Principal para Treino em Casa Sem Equipamento
// ─────────────────────────────────────────────

import 'dart:math';
import 'home_exercise_model.dart';
import 'home_exercise_library.dart';
import 'limitation_analyzer.dart';

class HomeWorkoutEngine {
  final List<HomeExercise> _library;
  final int _seed;

  HomeWorkoutEngine({
    List<HomeExercise>? library,
    String? userId,
  }) : _library = library ?? homeExerciseLibrary,
       _seed = _computeSeed(userId ?? '');

  static int _computeSeed(String userId) {
    int sum = 0;
    for (final code in userId.codeUnits) {
      sum += code;
    }
    return sum;
  }

  // ── API Pública ───────────────────────────────────────────────

  // Gera um treino completo para casa sem equipamento
  HomeWorkout generateWorkout({
    required String userId,
    required int availableMinutes,
    required List<HomeUserLimitation> limitations,
    required String experienceLevel,
    required double balanceCapability,
    required double strengthCapability,
    required double mobilityCapability,
    int? dayOfWeek,
  }) {
    final random = Random(_seed + (dayOfWeek ?? 0));
    
    // Determina quais padrões incluir baseado no tempo disponível
    final patterns = _selectPatterns(
      availableMinutes: availableMinutes,
      limitations: limitations,
    );
    
    // Seleciona exercícios para cada padrão
    final exercises = <HomeWorkoutExercise>[];
    
    for (final pattern in patterns) {
      final exercise = _selectExerciseForPattern(
        pattern: pattern,
        limitations: limitations,
        experienceLevel: experienceLevel,
        balanceCapability: balanceCapability,
        strengthCapability: strengthCapability,
        mobilityCapability: mobilityCapability,
        random: random,
      );
      
      if (exercise != null) {
        exercises.add(exercise);
      }
    }
    
    // Calcula duração estimada
    final estimatedDuration = _estimateDuration(exercises);
    
    return HomeWorkout(
      id: 'home_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      exercises: exercises,
      estimatedDurationMinutes: estimatedDuration,
      patterns: patterns.map((p) => p.name).toList(),
      limitations: limitations.map((l) => l.description).toList(),
      generatedAt: DateTime.now(),
    );
  }

  // Analisa um exercício específico para uma pessoa
  HomeExerciseAnalysis analyzeExercise({
    required HomeExercise exercise,
    required List<HomeUserLimitation> limitations,
    required String experienceLevel,
    required double balanceCapability,
    required double strengthCapability,
    required double mobilityCapability,
  }) {
    return HomeLimitationAnalyzer.analyze(
      exercise: exercise,
      limitations: limitations,
      experienceLevel: experienceLevel,
      balanceCapability: balanceCapability,
      strengthCapability: strengthCapability,
      mobilityCapability: mobilityCapability,
    );
  }

  // Processa feedback e sugere próximos passos
  HomeFeedbackAnalysis processFeedback({
    required HomeFeedback feedback,
    required HomeExercise exercise,
  }) {
    return HomeLimitationAnalyzer.analyzeFeedback(
      feedback: feedback,
      exercise: exercise,
    );
  }

  // Busca exercícios por padrão de movimento
  List<HomeExercise> getExercisesByPattern(HomeMovementPattern pattern) {
    return _library.where((e) => e.pattern == pattern).toList();
  }

  // Busca exercício por ID
  HomeExercise? getExerciseById(String id) {
    try {
      return _library.firstWhere((e) => e.id == id);
    } catch (e) {
      return null;
    }
  }

  // Busca regressão de um exercício
  HomeExercise? getRegression(HomeExercise exercise) {
    if (exercise.regressionId == null) return null;
    return getExerciseById(exercise.regressionId!);
  }

  // Busca progressão de um exercício
  HomeExercise? getProgression(HomeExercise exercise) {
    if (exercise.progressionId == null) return null;
    return getExerciseById(exercise.progressionId!);
  }

  // Busca alternativas de um exercício
  List<HomeExercise> getAlternatives(HomeExercise exercise) {
    return exercise.alternativeIds
        .map((id) => getExerciseById(id))
        .where((e) => e != null)
        .cast<HomeExercise>()
        .toList();
  }

  // ── Métodos Privados ──────────────────────────────────────────

  // Seleciona padrões de movimento baseado no tempo disponível
  List<HomeMovementPattern> _selectPatterns({
    required int availableMinutes,
    required List<HomeUserLimitation> limitations,
  }) {
    // Padrões essenciais (sempre incluir se possível)
    final essentialPatterns = [
      HomeMovementPattern.squat,
      HomeMovementPattern.pushHorizontal,
      HomeMovementPattern.coreAntiExtension,
    ];
    
    // Padrões importantes (incluir se houver tempo)
    final importantPatterns = [
      HomeMovementPattern.hipHinge,
      HomeMovementPattern.unilateral,
      HomeMovementPattern.calf,
      HomeMovementPattern.hipExtension,
    ];
    
    // Padrões complementares (incluir se houver muito tempo)
    final complementaryPatterns = [
      HomeMovementPattern.coreLateral,
      HomeMovementPattern.coreRotation,
      HomeMovementPattern.coreFlexion,
      HomeMovementPattern.hipAbduction,
      HomeMovementPattern.hipAdduction,
      HomeMovementPattern.kneeExtension,
      HomeMovementPattern.kneeFlexion,
      HomeMovementPattern.pushVertical,
      HomeMovementPattern.pullHorizontal,
      HomeMovementPattern.locomotion,
      HomeMovementPattern.conditioning,
      HomeMovementPattern.power,
      HomeMovementPattern.balance,
      HomeMovementPattern.mobility,
    ];
    
    final selectedPatterns = <HomeMovementPattern>[];
    
    // Adiciona padrões essenciais
    selectedPatterns.addAll(essentialPatterns);
    
    // Adiciona padrões importantes baseado no tempo
    if (availableMinutes >= 30) {
      selectedPatterns.addAll(importantPatterns.take(2));
    }
    if (availableMinutes >= 45) {
      selectedPatterns.addAll(importantPatterns.skip(2));
    }
    
    // Adiciona padrões complementares baseado no tempo
    if (availableMinutes >= 60) {
      selectedPatterns.addAll(complementaryPatterns.take(3));
    }
    if (availableMinutes >= 75) {
      selectedPatterns.addAll(complementaryPatterns.skip(3).take(3));
    }
    
    // Filtra padrões que podem ser inadequados pelas limitações
    return selectedPatterns.where((pattern) {
      return !_isPatternContraindicated(pattern, limitations);
    }).toList();
  }

  // Verifica se um padrão é contraindicado pelas limitações
  bool _isPatternContraindicated(
    HomeMovementPattern pattern,
    List<HomeUserLimitation> limitations,
  ) {
    // Puxar horizontal e vertical são condicionais
    if (pattern == HomeMovementPattern.pullHorizontal ||
        pattern == HomeMovementPattern.pullVertical) {
      return true; // Será verificado separadamente
    }
    
    // Potência exige capacidade básica
    if (pattern == HomeMovementPattern.power) {
      final hasSevereLimitation = limitations.any(
        (l) => l.severity == HomeLimitationSeverity.severe,
      );
      return hasSevereLimitation;
    }
    
    return false;
  }

  // Seleciona um exercício para um padrão específico
  HomeWorkoutExercise? _selectExerciseForPattern({
    required HomeMovementPattern pattern,
    required List<HomeUserLimitation> limitations,
    required String experienceLevel,
    required double balanceCapability,
    required double strengthCapability,
    required double mobilityCapability,
    required Random random,
  }) {
    // Busca exercícios do padrão
    var exercises = _library.where((e) => e.pattern == pattern).toList();
    
    if (exercises.isEmpty) return null;
    
    // Filtra exercícios condicionais
    exercises = exercises.where((e) => !e.isConditional).toList();
    
    if (exercises.isEmpty) return null;
    
    // Analisa cada exercício
    final analyzedExercises = exercises.map((exercise) {
      final analysis = HomeLimitationAnalyzer.analyze(
        exercise: exercise,
        limitations: limitations,
        experienceLevel: experienceLevel,
        balanceCapability: balanceCapability,
        strengthCapability: strengthCapability,
        mobilityCapability: mobilityCapability,
      );
      return _AnalyzedExercise(exercise: exercise, analysis: analysis);
    }).toList();
    
    // Prioriza exercícios compatíveis
    final compatible = analyzedExercises
        .where((a) => a.analysis.compatibility == HomeCompatibility.compatible)
        .toList();
    
    if (compatible.isNotEmpty) {
      final selected = compatible[random.nextInt(compatible.length)];
      return HomeWorkoutExercise(
        exercise: selected.exercise,
        analysis: selected.analysis,
        sets: _calculateSets(selected.exercise, experienceLevel),
        reps: _calculateReps(selected.exercise, experienceLevel),
        restSeconds: _calculateRest(selected.exercise, experienceLevel),
      );
    }
    
    // Se não houver compatíveis, tenta adaptáveis
    final adaptable = analyzedExercises
        .where((a) => a.analysis.compatibility == HomeCompatibility.adaptable)
        .toList();
    
    if (adaptable.isNotEmpty) {
      final selected = adaptable[random.nextInt(adaptable.length)];
      return HomeWorkoutExercise(
        exercise: selected.exercise,
        analysis: selected.analysis,
        sets: _calculateSets(selected.exercise, experienceLevel),
        reps: _calculateReps(selected.exercise, experienceLevel),
        restSeconds: _calculateRest(selected.exercise, experienceLevel),
      );
    }
    
    // Se não houver adaptáveis, usa o mais fácil do padrão
    exercises.sort((a, b) => a.difficulty.index.compareTo(b.difficulty.index));
    final easiest = exercises.first;
    
    final analysis = HomeLimitationAnalyzer.analyze(
      exercise: easiest,
      limitations: limitations,
      experienceLevel: experienceLevel,
      balanceCapability: balanceCapability,
      strengthCapability: strengthCapability,
      mobilityCapability: mobilityCapability,
    );
    
    return HomeWorkoutExercise(
      exercise: easiest,
      analysis: analysis,
      sets: _calculateSets(easiest, experienceLevel),
      reps: _calculateReps(easiest, experienceLevel),
      restSeconds: _calculateRest(easiest, experienceLevel),
    );
  }

  // Calcula séries baseado no nível de experiência
  int _calculateSets(HomeExercise exercise, String experienceLevel) {
    switch (experienceLevel) {
      case 'beginner':
        return 2;
      case 'intermediate':
        return 3;
      case 'advanced':
        return 4;
      default:
        return 3;
    }
  }

  // Calcula repetições baseado no exercício e nível
  int _calculateReps(HomeExercise exercise, String experienceLevel) {
    // Exercícios isométricos usam tempo
    if (exercise.id.contains('plank') || 
        exercise.id.contains('wall_sit') ||
        exercise.id.contains('hold')) {
      switch (experienceLevel) {
        case 'beginner':
          return 20; // 20 segundos
        case 'intermediate':
          return 30;
        case 'advanced':
          return 45;
        default:
          return 30;
      }
    }
    
    // Exercícios dinâmicos
    switch (experienceLevel) {
      case 'beginner':
        return 8;
      case 'intermediate':
        return 12;
      case 'advanced':
        return 15;
      default:
        return 12;
    }
  }

  // Calcula descanso baseado no exercício e nível
  int _calculateRest(HomeExercise exercise, String experienceLevel) {
    // Exercícios de maior demanda precisam de mais descanso
    if (exercise.strengthDemand > 0.7) {
      switch (experienceLevel) {
        case 'beginner':
          return 90;
        case 'intermediate':
          return 60;
        case 'advanced':
          return 45;
        default:
          return 60;
      }
    }
    
    // Exercícios de menor demanda
    switch (experienceLevel) {
      case 'beginner':
        return 60;
      case 'intermediate':
        return 45;
      case 'advanced':
        return 30;
      default:
        return 45;
    }
  }

  // Estima duração total do treino
  int _estimateDuration(List<HomeWorkoutExercise> exercises) {
    int totalSeconds = 0;
    
    for (final exercise in exercises) {
      // Tempo por série (estimativa: 30 segundos por série)
      final timePerSet = 30;
      final totalTime = exercise.sets * timePerSet;
      final restTime = exercise.sets * exercise.restSeconds;
      
      totalSeconds += totalTime + restTime;
    }
    
    // Adiciona 5 minutos de aquecimento
    totalSeconds += 300;
    
    return (totalSeconds / 60).ceil();
  }
}

// Classe auxiliar para análise de exercícios
class _AnalyzedExercise {
  final HomeExercise exercise;
  final HomeExerciseAnalysis analysis;

  const _AnalyzedExercise({
    required this.exercise,
    required this.analysis,
  });
}

// Modelo de treino para casa
class HomeWorkout {
  final String id;
  final String userId;
  final List<HomeWorkoutExercise> exercises;
  final int estimatedDurationMinutes;
  final List<String> patterns;
  final List<String> limitations;
  final DateTime generatedAt;

  const HomeWorkout({
    required this.id,
    required this.userId,
    required this.exercises,
    required this.estimatedDurationMinutes,
    required this.patterns,
    required this.limitations,
    required this.generatedAt,
  });
}

// Modelo de exercício no treino
class HomeWorkoutExercise {
  final HomeExercise exercise;
  final HomeExerciseAnalysis analysis;
  final int sets;
  final int reps;
  final int restSeconds;

  const HomeWorkoutExercise({
    required this.exercise,
    required this.analysis,
    required this.sets,
    required this.reps,
    required this.restSeconds,
  });
}
