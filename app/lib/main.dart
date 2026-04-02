import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'core/router/app_router.dart';
import 'core/services/auth_service.dart';
import 'features/exercises/exercise_provider.dart';
import 'features/workout/workout_provider.dart';
import 'features/workout/workout_profile_provider.dart';
import 'features/workout/progression_provider.dart';
import 'shared/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Para desenvolvimento local com emuladores, descomente:
  // const String host = '127.0.0.1';
  // FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
  // FirebaseAuth.instance.useAuthEmulator(host, 9099);

  runApp(const WorkoutApp());
}

class WorkoutApp extends StatelessWidget {
  const WorkoutApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>(create: (_) => AuthService()),
        ChangeNotifierProvider<ExerciseProvider>(
          create: (_) => ExerciseProvider(),
        ),
        ChangeNotifierProvider<WorkoutProvider>(
          create: (_) => WorkoutProvider(),
        ),
        ChangeNotifierProvider<WorkoutProfileProvider>(
          create: (_) => WorkoutProfileProvider(),
        ),
        // Motor de Progressão — registrado globalmente
        ChangeNotifierProvider<ProgressionProvider>(
          create: (_) => ProgressionProvider(),
        ),
        Provider.value(value: FirebaseFirestore.instance),
      ],
      child: Consumer<AuthService>(
        builder: (context, authService, child) {
          return MaterialApp.router(
            title: 'Controle de Carga',
            theme: AppTheme.darkTheme,
            debugShowCheckedModeBanner: false,
            routerConfig: AppRouter.createRouter(authService),
          );
        },
      ),
    );
  }
}
