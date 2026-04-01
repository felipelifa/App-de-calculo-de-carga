import 'dart:math';
import '../exercises/exercise_model.dart';
import 'workout_profile_model.dart';
import 'prescribed_workout_model.dart';

// ─────────────────────────────────────────────
// MOTOR DE PRESCRIÇÃO (WorkoutPrescriptionEngine)
// Baseado em regras científicas determinísticas
// ─────────────────────────────────────────────

class WorkoutPrescriptionEngine {
  final List<ExerciseModel> library;

  WorkoutPrescriptionEngine(this.library);

  GeneratedWorkout generate(WorkoutProfile profile) {
    // 1. Definir a Divisão de Treino (PPL, Full Body, Upper/Lower)
    final splitType = _selectSplit(profile.experienceLevel, profile.availableDaysPerWeek);
    
    // 2. Definir Modelo de Periodização
    final periodization = _selectPeriodization(profile.experienceLevel);
    
    // 3. Gerar as Sessões (A, B, C...)
    final sessions = _generateSessions(profile, splitType, periodization);

    return GeneratedWorkout(
      id: 'gen_${DateTime.now().millisecondsSinceEpoch}',
      userId: profile.uid,
      splitType: splitType,
      periodizationModel: periodization,
      sessions: sessions,
      mesocycleDurationWeeks: profile.experienceLevel == 'beginner' ? 8 : 12,
      generatedAt: DateTime.now(),
    );
  }

  // ── Step 1: Selecionar Divisão ───────────────────────────────
  String _selectSplit(String level, int days) {
    if (level == 'beginner') {
      if (days <= 3) return 'full_body';
      return 'upper_lower'; // Iniciante com 4+ dias raramente é boa ideia, mas se insistir usamos UL
    }
    
    if (level == 'intermediate') {
      if (days == 3) return 'ppl';
      if (days == 4) return 'upper_lower';
      return 'ppl_upper'; // 5 dias
    }

    if (level == 'advanced') {
      if (days <= 4) return 'upper_lower';
      return 'ppl_x2'; // 6 dias
    }

    return 'full_body';
  }

  // ── Step 2: Selecionar Periodização ──────────────────────────
  String _selectPeriodization(String level) {
    // Modelo Linear recomendado pelo CREF para ganho de base
    if (level == 'beginner') return 'linear_hypertrophy';
    if (level == 'intermediate') return 'linear_strength';
    return 'block_periodization';
  }

  // ── Step 3: Cálculo de Volume Semanal (Séries) ───────────────
  Map<String, int> _calculateWeeklyVolumes(String level) {
    // Valores ideais simplificados baseados na Tabela 3.3 (Israetel)
    if (level == 'beginner') {
      return {
        'chest': 9, 'back': 10, 'shoulders': 8, 'biceps': 6, 'triceps': 6,
        'quads': 8, 'hamstrings': 7, 'glutes': 6, 'calves': 8, 'abs': 4
      };
    }
    return { // Int/Adv (Intervalo médio entre 12-18)
      'chest': 14, 'back': 16, 'shoulders': 12, 'biceps': 10, 'triceps': 10,
      'quads': 14, 'hamstrings': 12, 'glutes': 10, 'calves': 12, 'abs': 8
    };
  }

  // ── Step 4: Geração de Sessões Reais ──────────────────────────
  List<PrescribedSession> _generateSessions(WorkoutProfile profile, String splitType, String periodization) {
    final weeklyVolumes = _calculateWeeklyVolumes(profile.experienceLevel);
    final List<PrescribedSession> sessions = [];

    // Lógica simplificada de divisão para esta etapa (Step 3 do Master Plan)
    if (splitType == 'full_body') {
      sessions.add(_buildFullBodySession('A', profile, weeklyVolumes));
      if (profile.availableDaysPerWeek > 1) {
        sessions.add(_buildFullBodySession('B', profile, weeklyVolumes));
      }
    } else if (splitType == 'upper_lower') {
      sessions.add(_buildUpperSession('A', profile, weeklyVolumes));
      sessions.add(_buildLowerSession('A', profile, weeklyVolumes));
      if (profile.availableDaysPerWeek >= 4) {
        sessions.add(_buildUpperSession('B', profile, weeklyVolumes));
        sessions.add(_buildLowerSession('B', profile, weeklyVolumes));
      }
    }

    return sessions;
  }

  // ── Auxiliares de Construção de Sessão ────────────────────────
  
  PrescribedSession _buildFullBodySession(String tag, WorkoutProfile profile, Map<String, int> weeklyVolumes) {
    final List<PrescribedExercise?> exercises = [];
    final days = profile.availableDaysPerWeek;

    // Pega um exercício principal de cada padrão motor fundamental
    // Chest (Push Horiz), Back (Pull Vert/Horiz), Quads (Squat), Hams (Hinge)
    exercises.add(_selectSingleExercise('chest', 'push_horizontal', profile, weeklyVolumes, days));
    exercises.add(_selectSingleExercise('back', 'pull_vertical', profile, weeklyVolumes, days));
    exercises.add(_selectSingleExercise('quads', 'squat', profile, weeklyVolumes, days));
    exercises.add(_selectSingleExercise('hamstrings', 'hinge', profile, weeklyVolumes, days));
    
    // Pequenos (Isoladores)
    exercises.add(_selectSingleExercise('shoulders', 'push_vertical', profile, weeklyVolumes, days, isCompound: false));
    exercises.add(_selectSingleExercise('biceps', 'isolation', profile, weeklyVolumes, days, isCompound: false));

    return PrescribedSession(
      id: 'session_fb_$tag',
      name: 'Treino Full Body $tag',
      objective: 'Frequência Total e Base Sólida',
      estimatedDurationMinutes: profile.sessionDurationMinutes,
      warmupInstructions: ['5 min cardio leve', 'Mobilidade articular geral', '1 série de 15 reps com 30% da carga no primeiro exercício'],
      exercises: exercises.where((e) => e != null).cast<PrescribedExercise>().toList(),
      progressionNote: profile.experienceLevel == 'beginner' ? 'Tente aumentar 1kg-2kg por semana se completar as repetições.' : 'Foque em consolidar a forma.',
    );
  }

  PrescribedSession _buildUpperSession(String tag, WorkoutProfile profile, Map<String, int> weeklyVolumes) {
    final List<PrescribedExercise?> exercises = [];
    final days = profile.availableDaysPerWeek; // Geralmente 4 ou 2 se for UL

    // Upper: Peito, Costas, Ombro, Braços
    exercises.add(_selectSingleExercise('chest', 'push_horizontal', profile, weeklyVolumes, days, setsModifier: 2));
    exercises.add(_selectSingleExercise('back', 'pull_horizontal', profile, weeklyVolumes, days, setsModifier: 2));
    exercises.add(_selectSingleExercise('shoulders', 'push_vertical', profile, weeklyVolumes, days, setsModifier: 2));
    exercises.add(_selectSingleExercise('back', 'pull_vertical', profile, weeklyVolumes, days, setsModifier: 1));
    exercises.add(_selectSingleExercise('triceps', 'isolation', profile, weeklyVolumes, days, isCompound: false));
    exercises.add(_selectSingleExercise('biceps', 'isolation', profile, weeklyVolumes, days, isCompound: false));

    return PrescribedSession(
      id: 'session_upper_$tag',
      name: 'Treino Superior $tag',
      objective: 'Hipertrofia de Braços e Tronco',
      estimatedDurationMinutes: profile.sessionDurationMinutes,
      warmupInstructions: ['Rotação de manguito', 'Escápulas dinâmicas', 'Aquecimento progressivo no primeiro exercício'],
      exercises: exercises.where((e) => e != null).cast<PrescribedExercise>().toList(),
      progressionNote: 'Busque bater seu PR no exercício de ${exercises.isNotEmpty && exercises[0] != null ? exercises[0]!.exercise.name : 'base'}.',
    );
  }

  PrescribedSession _buildLowerSession(String tag, WorkoutProfile profile, Map<String, int> weeklyVolumes) {
    final List<PrescribedExercise?> exercises = [];
    final days = profile.availableDaysPerWeek;

    // Lower: Quads, Hams, Glutes, Calves
    exercises.add(_selectSingleExercise('quads', 'squat', profile, weeklyVolumes, days, setsModifier: 2));
    exercises.add(_selectSingleExercise('hamstrings', 'hinge', profile, weeklyVolumes, days, setsModifier: 2));
    exercises.add(_selectSingleExercise('quads', 'isolation', profile, weeklyVolumes, days, isCompound: false));
    exercises.add(_selectSingleExercise('calves', 'isolation', profile, weeklyVolumes, days, setsModifier: 2, isCompound: false));

    return PrescribedSession(
      id: 'session_lower_$tag',
      name: 'Treino Inferior $tag',
      objective: 'Força e Base Muscular Inferior',
      estimatedDurationMinutes: profile.sessionDurationMinutes,
      warmupInstructions: ['Mobilidade de quadril', 'Tornozelos dinâmicos', 'Extensão de joelhos com carga leve'],
      exercises: exercises.where((e) => e != null).cast<PrescribedExercise>().toList(),
      progressionNote: 'Mantenha o tronco firme e o pé inteiro no chão.',
    );
  }

  // ── Seleção Inteligente de Exercício Único ────────────────────
  
  PrescribedExercise? _selectSingleExercise(
    String muscle, 
    String pattern, 
    WorkoutProfile profile, 
    Map<String, int> weeklyVolumes, 
    int daysPerWeek,
    {bool isCompound = true, int setsModifier = 1}
  ) {
    final candidates = library.where((ex) {
      // Filtros Absolutos (Section 3.4)
      if (!ex.environment.contains(profile.environment)) return false;
      if (ex.restrictions.any((r) => profile.healthRestrictions.contains(r))) return false;
      if (profile.dislikedExercises.contains(ex.id)) return false;
      
      // Filtro de Músculo e Padrão
      if (!ex.primaryMuscles.contains(muscle)) return false;
      if (ex.movementPattern != pattern) return false;
      
      // Filtro de Nível (Iniciantes não fazem Agachamento Barra Livre se marcarmos como advanced)
      if (profile.experienceLevel == 'beginner' && ex.difficulty == 'advanced') return false;

      return true;
    }).toList();

    if (candidates.isEmpty) return null;

    // Sorteia um dos candidatos (ou pega o primeiro se quiser ser 100% determinístico por ID)
    final ex = candidates[Random().nextInt(candidates.length)];

    // Calcula séries para esta sessão
    final targetWeeklySets = (weeklyVolumes[muscle] ?? 10);
    // Divisão de séries semanais pelo número de dias sugeridos para o grupo
    final setsPerSession = (targetWeeklySets / max(1, daysPerWeek / 2)).ceil(); 

    return PrescribedExercise(
      exercise: ex,
      sets: min(5, max(2, setsPerSession)), // Prescrição real entre 2 e 5 séries
      repsMax: ex.repRangeMax,
      rir: profile.experienceLevel == 'beginner' ? 2 : 1, 
      restSeconds: _getRestSeconds(profile.primaryGoal, ex.category),
      sessionCues: ex.cues.take(3).toList(),
      progressionNote: 'Ao completar ${ex.repRangeMax} reps em todas as séries, aumente a carga.',
    );
  }

  int _getRestSeconds(String goal, String category) {
    // Ajustado conforme CREF-SP: 2-3 min para garantir recuperação completa
    if (goal == 'strength' || category == 'compound') return 150; // 2.5 minutos
    return 90; // 1.5 minutos para isolados
  }
}
