import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'core/router/app_router.dart';
import 'core/services/auth_service.dart';
import 'features/exercises/exercise_provider.dart';
import 'shared/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  const String host = 'localhost';

  FirebaseFirestore.instance.settings = const Settings(
    host: '$host:8080',
    sslEnabled: false,
    persistenceEnabled: false,
  );

  await FirebaseAuth.instance.useAuthEmulator(host, 9099);

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

