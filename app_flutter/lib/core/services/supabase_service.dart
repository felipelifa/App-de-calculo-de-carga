import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._();
  factory SupabaseService() => _instance;
  SupabaseService._();

  static const String _supabaseUrl = 'https://gqieijrasstgdddciuns.supabase.co';
  static const String _supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdxaWVpanJhc3N0Z2RkZGNpdW5zIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODg2Mzg0ODIsImV4cCI6MjEwNDIxNDQ4Mn0.4fIWuz7NUauAj39wQ5uyv3ymLegmUt2fcn6nurgAJ-0';

  SupabaseClient get client => Supabase.instance.client;
  User? get currentUser => client.auth.currentUser;
  bool get isAuthenticated => currentUser != null;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: _supabaseUrl,
      publishableKey: _supabaseAnonKey,
    );
  }

  // ── Autenticação ──────────────────────────────────────────────

  Future<AuthResponse> signIn(String email, String password) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUp(
    String email,
    String password,
    String name,
  ) async {
    return await client.auth.signUp(
      email: email,
      password: password,
      data: {'name': name},
    );
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }

  // ── Perfil do Usuário ─────────────────────────────────────────

  Future<Map<String, dynamic>?> getProfile() async {
    if (!isAuthenticated) return null;
    final response = await client
        .from('UserProfile')
        .select()
        .eq('userId', currentUser!.id)
        .maybeSingle();
    return response;
  }

  Future<void> saveProfile(Map<String, dynamic> profile) async {
    if (!isAuthenticated) throw StateError('Usuário não autenticado');

    try {
      final existing = await getProfile();
      if (existing != null) {
        await client
            .from('UserProfile')
            .update({...profile, 'updatedAt': DateTime.now().toIso8601String()})
            .eq('userId', currentUser!.id);
      } else {
        await client.from('UserProfile').insert({
          ...profile,
          'userId': currentUser!.id,
          'createdAt': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint('Erro ao salvar perfil: $e');
      rethrow;
    }
  }

  // ── Treinos Gerados ───────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getGeneratedWorkouts() async {
    if (!isAuthenticated) return [];
    final response = await client
        .from('GeneratedWorkout')
        .select()
        .eq('userId', currentUser!.id)
        .order('createdAt', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> saveGeneratedWorkout(Map<String, dynamic> workout) async {
    if (!isAuthenticated) throw StateError('Usuário não autenticado');

    // Salvar novo treino
    final inserted = await client
        .from('GeneratedWorkout')
        .insert({
          ...workout,
          'userId': currentUser!.id,
          'isActive': true,
          'createdAt': DateTime.now().toIso8601String(),
        })
        .select('id')
        .single();

    // Só desativa o plano anterior depois que o novo foi persistido.
    await client
        .from('GeneratedWorkout')
        .update({'isActive': false})
        .eq('userId', currentUser!.id)
        .neq('id', inserted['id']);
  }

  Future<void> activateGeneratedWorkout(String id) async {
    if (!isAuthenticated) throw StateError('Usuário não autenticado');

    await client
        .from('GeneratedWorkout')
        .update({'isActive': false})
        .eq('userId', currentUser!.id);
    await client
        .from('GeneratedWorkout')
        .update({'isActive': true})
        .eq('id', id)
        .eq('userId', currentUser!.id);
  }

  Future<void> updateGeneratedWorkout(
    String id,
    Map<String, dynamic> workout,
  ) async {
    if (!isAuthenticated) throw StateError('Usuário não autenticado');
    await client
        .from('GeneratedWorkout')
        .update({...workout, 'updatedAt': DateTime.now().toIso8601String()})
        .eq('id', id)
        .eq('userId', currentUser!.id);
  }

  Future<void> deleteGeneratedWorkout(String id) async {
    if (!isAuthenticated) throw StateError('Usuário não autenticado');
    await client
        .from('GeneratedWorkout')
        .delete()
        .eq('id', id)
        .eq('userId', currentUser!.id);
  }

  // ── Treinos Realizados ────────────────────────────────────────

  Future<void> saveWorkout(Map<String, dynamic> workout) async {
    if (!isAuthenticated) throw StateError('Usuário não autenticado');

    final now = DateTime.now();
    final exercises = List<Map<String, dynamic>>.from(
      workout['exercises'] ?? const [],
    );
    final totalVolume = (workout['totalVolume'] as num?)?.toDouble() ?? 0;
    final weekNumber =
        ((now.difference(DateTime(now.year, 1, 1)).inDays) / 7).floor() + 1;

    final insertedWorkout = await client
        .from('Workout')
        .insert({
          'userId': currentUser!.id,
          'date': now.toIso8601String(),
          'weekNumber': weekNumber,
          'totalVolume': totalVolume,
          'exerciseCount': exercises.length,
          'durationMinutes': workout['durationMinutes'],
          'notes': workout['notes'],
          'sessionType': workout['sessionType'],
        })
        .select('id')
        .single();
    final workoutId = insertedWorkout['id'].toString();

    try {
      for (
        var exerciseIndex = 0;
        exerciseIndex < exercises.length;
        exerciseIndex++
      ) {
        final exercise = exercises[exerciseIndex];
        final insertedExercise = await client
            .from('WorkoutExercise')
            .insert({
              'workoutId': workoutId,
              'exerciseOrder':
                  (exercise['exerciseOrder'] as num?)?.toInt() ?? exerciseIndex,
              'exerciseId': exercise['exerciseId'],
              'exerciseName': exercise['exerciseName'],
              'muscleGroup': exercise['muscleGroup'],
            })
            .select('id')
            .single();
        final workoutExerciseId = insertedExercise['id'].toString();

        final sets = List<Map<String, dynamic>>.from(
          exercise['sets'] ?? const [],
        );
        for (var setIndex = 0; setIndex < sets.length; setIndex++) {
          final set = sets[setIndex];
          final reps = (set['reps'] as num?)?.toInt() ?? 0;
          final weight = (set['weight'] as num?)?.toDouble() ?? 0;
          await client.from('WorkoutSet').insert({
            'workoutExerciseId': workoutExerciseId,
            'setNumber': (set['setNumber'] as num?)?.toInt() ?? setIndex + 1,
            'reps': reps,
            'weight': weight,
            'volume': reps * weight,
            'isWarmup': set['isWarmup'] ?? false,
          });
        }
      }
    } catch (_) {
      // Compensating delete prevents a parent Workout without all children
      // when a child insert fails.
      await client
          .from('Workout')
          .delete()
          .eq('id', workoutId)
          .eq('userId', currentUser!.id);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getWorkouts({
    int? week,
    int? limit,
  }) async {
    if (!isAuthenticated) return [];
    var query = client.from('Workout').select().eq('userId', currentUser!.id);
    if (week != null) query = query.eq('weekNumber', week);
    final response = await query
        .order('createdAt', ascending: false)
        .limit(limit ?? 50);
    final workouts = List<Map<String, dynamic>>.from(response);

    for (final workout in workouts) {
      final exerciseRows = await client
          .from('WorkoutExercise')
          .select()
          .eq('workoutId', workout['id']);
      exerciseRows.sort(
        (a, b) => ((a['exerciseOrder'] as num?)?.toInt() ?? 0).compareTo(
          (b['exerciseOrder'] as num?)?.toInt() ?? 0,
        ),
      );
      final exercises = <Map<String, dynamic>>[];
      for (final exercise in List<Map<String, dynamic>>.from(exerciseRows)) {
        final setRows = await client
            .from('WorkoutSet')
            .select()
            .eq('workoutExerciseId', exercise['id'])
            .order('setNumber');
        exercises.add({
          ...exercise,
          'sets': List<Map<String, dynamic>>.from(setRows),
        });
      }
      workout['exercises'] = exercises;
    }
    return workouts;
  }

  // ── Progressão ────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getProgressionState() async {
    if (!isAuthenticated) return null;
    final response = await client
        .from('ProgressionState')
        .select()
        .eq('userId', currentUser!.id)
        .maybeSingle();
    if (response == null) return null;
    return {
      ...response,
      'currentPhase': response['phase'] ?? 'accumulation',
      'exerciseProgress': response['exerciseStates'] ?? {},
    };
  }

  Future<void> saveProgressionState(Map<String, dynamic> state) async {
    if (!isAuthenticated) return;

    final existing = await getProgressionState();
    final payload = {
      'currentWeek': state['currentWeek'] ?? 1,
      'isDeloadWeek': state['isDeloadWeek'] ?? false,
      'phase': state['currentPhase'] ?? 'accumulation',
      'exerciseStates': state['exerciseProgress'] ?? {},
      'lastUpdated': DateTime.now().toIso8601String(),
      'userId': currentUser!.id,
    };
    if (existing != null) {
      await client
          .from('ProgressionState')
          .update(payload)
          .eq('userId', currentUser!.id);
    } else {
      await client.from('ProgressionState').insert(payload);
    }
  }

  // ── Personal Records ──────────────────────────────────────────

  Future<void> savePR(Map<String, dynamic> pr) async {
    if (!isAuthenticated) return;

    final existing = await client
        .from('PersonalRecord')
        .select()
        .eq('userId', currentUser!.id)
        .eq('exerciseId', pr['exerciseId'])
        .maybeSingle();

    if (existing != null) {
      await client
          .from('PersonalRecord')
          .update({...pr, 'updatedAt': DateTime.now().toIso8601String()})
          .eq('id', existing['id']);
    } else {
      await client.from('PersonalRecord').insert({
        ...pr,
        'userId': currentUser!.id,
      });
    }
  }

  Future<List<Map<String, dynamic>>> getPRs() async {
    if (!isAuthenticated) return [];
    final response = await client
        .from('PersonalRecord')
        .select()
        .eq('userId', currentUser!.id);
    return List<Map<String, dynamic>>.from(response);
  }

  // ── Exercícios ────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getExercises() async {
    final response = await client.from('Exercise').select();
    return List<Map<String, dynamic>>.from(response);
  }

  // ── Nutrição ──────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getNutritionProfile() async {
    if (!isAuthenticated) return null;
    final response = await client
        .from('NutritionProfile')
        .select()
        .eq('userId', currentUser!.id)
        .maybeSingle();
    return response;
  }

  Future<void> saveNutritionProfile(Map<String, dynamic> profile) async {
    if (!isAuthenticated) return;

    final existing = await getNutritionProfile();
    if (existing != null) {
      await client
          .from('NutritionProfile')
          .update({...profile, 'updatedAt': DateTime.now().toIso8601String()})
          .eq('userId', currentUser!.id);
    } else {
      await client.from('NutritionProfile').insert({
        ...profile,
        'userId': currentUser!.id,
      });
    }
  }

  Future<void> saveNutritionDay(Map<String, dynamic> day) async {
    if (!isAuthenticated) return;
    await client.from('NutritionDay').upsert({
      ...day,
      'userId': currentUser!.id,
    });
  }

  Future<List<Map<String, dynamic>>> getNutritionDays(
    DateTime from,
    DateTime to,
  ) async {
    if (!isAuthenticated) return [];
    final response = await client
        .from('NutritionDay')
        .select()
        .eq('userId', currentUser!.id)
        .gte('date', from.toIso8601String().substring(0, 10))
        .lte('date', to.toIso8601String().substring(0, 10))
        .order('date', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> saveMealEntry(Map<String, dynamic> entry) async {
    await client.from('MealEntry').insert(entry);
  }

  Future<void> deleteMealEntry(String id) async {
    await client.from('MealEntry').delete().eq('id', id);
  }
}
