import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../features/exercises/exercise_model.dart';
import '../../core/data/mock_exercises.dart';
import '../../firebase_options.dart';

Future<void> main() async {
  print('--- INICIANDO CARGA DE EXERCÍCIOS NA NUVEM ---');
  
  // No emulators, hitting PRODUCTION Cloud Firestore!
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final db = FirebaseFirestore.instance;
  
  for (var ex in mockExercises) {
    print('Enviando: ${ex.name}...');
    await db.collection('exercises').doc(ex.id).set(ex.toMap());
  }

  print('--- CARGA FINALIZADA COM SUCESSO! ---');
}
