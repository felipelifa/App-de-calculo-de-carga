import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._();
  factory SupabaseService() => _instance;
  SupabaseService._();

  static const String _supabaseUrl = 'https://gqieijrasstgdddciuns.supabase.co';
  static const String _supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdxaWVpanJhc3N0Z2RkZGNpdW5zIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODg2Mzg0ODIsImV4cCI6MjEwNDIxNDQ4Mn0.4fIWuz7NUauAj39wQ5uyv3ymLegmUt2fcn6nurgAJ-0';

  SupabaseClient get client => Supabase.instance.client;
  User? get currentUser => client.auth.currentUser;
  bool get isAuthenticated => currentUser != null;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: _supabaseUrl,
      anonKey: _supabaseAnonKey,
    );
  }

  // ── Autenticação ──────────────────────────────────────────────

  Future<AuthResponse> signIn(String email, String password) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUp(String email, String password, String name) async {
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
    if (!isAuthenticated) return;
    
    try {
      final existing = await getProfile();
      if (existing != null) {
        await client
            .from('UserProfile')
            .update({...profile, 'updatedAt': DateTime.now().toIso8601String()})
            .eq('userId', currentUser!.id);
      } else {
        await client
            .from('UserProfile')
            .insert({...profile, 'userId': currentUser!.id, 'createdAt': DateTime.now().toIso8601String()});
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
    if (!isAuthenticated) return;
    
    // Desativar treinos anteriores
    await client
        .from('GeneratedWorkout')
        .update({'isActive': false})
        .eq('userId', currentUser!.id);
    
    // Salvar novo treino
    await client
        .from('GeneratedWorkout')
        .insert({
          ...workout,
          'userId': currentUser!.id,
          'isActive': true,
          'createdAt': DateTime.now().toIso8601String(),
        });
  }

  // ── Treinos Realizados ────────────────────────────────────────

  Future<void> saveWorkout(Map<String, dynamic> workout) async {
    if (!isAuthenticated) return;
    await client
        .from('Workout')
        .insert({...workout, 'userId': currentUser!.id});
  }

  Future<List<Map<String, dynamic>>> getWorkouts() async {
    if (!isAuthenticated) return [];
    final response = await client
        .from('Workout')
        .select()
        .eq('userId', currentUser!.id)
        .order('createdAt', ascending: false)
        .limit(50);
    return List<Map<String, dynamic>>.from(response);
  }

  // ── Progressão ────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getProgressionState() async {
    if (!isAuthenticated) return null;
    final response = await client
        .from('ProgressionState')
        .select()
        .eq('userId', currentUser!.id)
        .maybeSingle();
    return response;
  }

  Future<void> saveProgressionState(Map<String, dynamic> state) async {
    if (!isAuthenticated) return;
    
    final existing = await getProgressionState();
    if (existing != null) {
      await client
          .from('ProgressionState')
          .update({...state, 'lastUpdated': DateTime.now().toIso8601String()})
          .eq('userId', currentUser!.id);
    } else {
      await client
          .from('ProgressionState')
          .insert({...state, 'userId': currentUser!.id});
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
      await client
          .from('PersonalRecord')
          .insert({...pr, 'userId': currentUser!.id});
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
    final response = await client
        .from('Exercise')
        .select();
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
      await client
          .from('NutritionProfile')
          .insert({...profile, 'userId': currentUser!.id});
    }
  }

  Future<void> saveNutritionDay(Map<String, dynamic> day) async {
    if (!isAuthenticated) return;
    await client
        .from('NutritionDay')
        .upsert({...day, 'userId': currentUser!.id});
  }

  Future<List<Map<String, dynamic>>> getNutritionDays(DateTime from, DateTime to) async {
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
