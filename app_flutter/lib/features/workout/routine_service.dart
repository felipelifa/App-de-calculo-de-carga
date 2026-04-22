import 'package:cloud_firestore/cloud_firestore.dart';
import 'workout_routine_model.dart';

// ─────────────────────────────────────────────
// Serviço de Rotinas (Templates)
// ─────────────────────────────────────────────

class RoutineService {
  final FirebaseFirestore _db;
  final String _uid;

  RoutineService({required FirebaseFirestore db, required String uid})
      : _db = db,
        _uid = uid;

  String get _col => 'users/$_uid/routines';

  /// Carrega todas as rotinas do usuário
  Future<List<WorkoutRoutine>> loadAll() async {
    final snap = await _db.collection(_col).orderBy('createdAt').get();
    return snap.docs
        .map((doc) => WorkoutRoutine.fromMap(doc.id, doc.data()))
        .toList();
  }

  /// Salva ou cria uma nova rotina
  Future<void> save(WorkoutRoutine routine) async {
    final map = routine.toMap();
    if (routine.id.isEmpty || routine.id == 'new') {
      await _db.collection(_col).add(map);
    } else {
      await _db.collection(_col).doc(routine.id).set(map);
    }
  }

  /// Deleta uma rotina
  Future<void> delete(String routineId) async {
    await _db.collection(_col).doc(routineId).delete();
  }
}
