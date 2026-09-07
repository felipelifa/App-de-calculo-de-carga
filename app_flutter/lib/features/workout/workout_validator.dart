import 'prescribed_workout_model.dart';
import 'workout_profile_model.dart';
import 'exercise_compatibility.dart';

class WorkoutValidationIssue {
  final String code;
  final String message;
  final String? sessionId;
  final String? exerciseId;

  const WorkoutValidationIssue({
    required this.code,
    required this.message,
    this.sessionId,
    this.exerciseId,
  });
}

class WorkoutValidationResult {
  final List<WorkoutValidationIssue> issues;

  const WorkoutValidationResult(this.issues);

  bool get isValid => issues.isEmpty;

  String get summary => issues.map((issue) => issue.message).join(' ');
}

class WorkoutValidator {
  const WorkoutValidator._();

  static WorkoutValidationResult validate({
    required WorkoutProfile profile,
    required GeneratedWorkout workout,
    bool requireExpectedSessionCount = true,
  }) {
    final issues = <WorkoutValidationIssue>[];

    if (workout.sessions.isEmpty) {
      issues.add(
        const WorkoutValidationIssue(
          code: 'no_sessions',
          message: 'O treino não possui sessões.',
        ),
      );
    }

    if (requireExpectedSessionCount &&
        workout.sessions.length != profile.availableDaysPerWeek) {
      issues.add(
        WorkoutValidationIssue(
          code: 'session_count_mismatch',
          message: 'O treino não respeita a quantidade de dias solicitada.',
        ),
      );
    }

    var totalExercises = 0;
    for (final session in workout.sessions) {
      if (session.id.trim().isEmpty) {
        issues.add(
          const WorkoutValidationIssue(
            code: 'invalid_session_id',
            message: 'Existe uma sessão sem identificador.',
          ),
        );
      }
      for (final unresolvedId in session.unresolvedExerciseIds) {
        issues.add(
          WorkoutValidationIssue(
            code: 'unresolved_exercise',
            message:
                'O exercício $unresolvedId não foi encontrado na biblioteca.',
            sessionId: session.id,
            exerciseId: unresolvedId,
          ),
        );
      }
      if (session.exercises.isEmpty) {
        issues.add(
          WorkoutValidationIssue(
            code: 'empty_session',
            message: 'A sessão ${session.name} não possui exercícios.',
            sessionId: session.id,
          ),
        );
        continue;
      }

      final ids = <String>{};
      for (final prescribed in session.exercises) {
        totalExercises++;
        final exercise = prescribed.exercise;
        if (exercise.id.trim().isEmpty) {
          issues.add(
            WorkoutValidationIssue(
              code: 'invalid_exercise_id',
              message: 'Existe um exercício sem identificador.',
              sessionId: session.id,
            ),
          );
        }
        if (!ids.add(exercise.id)) {
          issues.add(
            WorkoutValidationIssue(
              code: 'duplicate_exercise',
              message:
                  'O exercício ${exercise.name} foi repetido na mesma sessão.',
              sessionId: session.id,
              exerciseId: exercise.id,
            ),
          );
        }

        final compatibility = ExerciseCompatibility.evaluate(
          profile: profile,
          exercise: exercise,
        );
        if (!compatibility.allowed) {
          issues.add(
            WorkoutValidationIssue(
              code: compatibility.code,
              message: '${exercise.name}: ${compatibility.reason}',
              sessionId: session.id,
              exerciseId: exercise.id,
            ),
          );
        }

        if (prescribed.sets < 1 || prescribed.sets > 20) {
          issues.add(
            WorkoutValidationIssue(
              code: 'invalid_sets',
              message: '${exercise.name} possui quantidade de séries inválida.',
              sessionId: session.id,
              exerciseId: exercise.id,
            ),
          );
        }
        if (prescribed.repsMin < 1 ||
            prescribed.repsMax < prescribed.repsMin ||
            prescribed.repsMax > 100) {
          issues.add(
            WorkoutValidationIssue(
              code: 'invalid_reps',
              message: '${exercise.name} possui faixa de repetições inválida.',
              sessionId: session.id,
              exerciseId: exercise.id,
            ),
          );
        }
        if (prescribed.rir < 0 || prescribed.rir > 5) {
          issues.add(
            WorkoutValidationIssue(
              code: 'invalid_rir',
              message: '${exercise.name} possui RIR inválido.',
              sessionId: session.id,
              exerciseId: exercise.id,
            ),
          );
        }
        if (prescribed.restSeconds < 0 || prescribed.restSeconds > 900) {
          issues.add(
            WorkoutValidationIssue(
              code: 'invalid_rest',
              message: '${exercise.name} possui descanso inválido.',
              sessionId: session.id,
              exerciseId: exercise.id,
            ),
          );
        }
      }
    }

    if (totalExercises == 0) {
      issues.add(
        const WorkoutValidationIssue(
          code: 'NO_COMPATIBLE_EXERCISES',
          message: 'A geração falhou: o treino não possui exercícios.',
        ),
      );
      // Keep the legacy diagnostic while exposing the explicit generation
      // failure code to callers that need a controlled fallback.
      issues.add(
        const WorkoutValidationIssue(
          code: 'no_exercises',
          message: 'Nenhum exercício compatível pode ser persistido.',
        ),
      );
    }

    return WorkoutValidationResult(issues);
  }
}
