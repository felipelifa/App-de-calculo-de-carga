import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'firebase_options.dart';
import 'core/router/app_router.dart';
import 'core/services/auth_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/api_service.dart';
import 'core/services/workouts_api_service.dart';
import 'core/services/analytics_api_service.dart';
import 'core/services/nutrition_api_service.dart';
import 'core/services/progression_api_service.dart';
import 'core/services/prescription_api_service.dart';
import 'core/services/pr_api_service.dart';
import 'core/services/pro_api_service.dart';
import 'features/exercises/exercise_provider.dart';
import 'features/workout/workout_provider.dart';
import 'features/workout/workout_profile_provider.dart';
import 'features/workout/progression_provider.dart';
import 'features/nutrition/nutrition_provider.dart';
import 'shared/theme/app_theme.dart';

// Background message handler — chamado quando o app está em background
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

Future<void> fcmSetup() async {
  // Registrar handler para mensagens com app em background/morto
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Solicitar permissão (iOS) + configuração Android
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // Obter e registrar token no Firestore
  final token = await FirebaseMessaging.instance.getToken();
  if (token != null) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set({'fcmToken': token}, SetOptions(merge: true));
    }
  }

  // Atualizar token quando rotacionar
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set({'fcmToken': newToken}, SetOptions(merge: true));
    }
  });

  // Handler com app em foreground — mostrar notificação local
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    final notification = message.notification;
    if (notification != null) {
      NotificationService.showLocalNotification(
        title: notification.title ?? 'Notificação',
        body: notification.body ?? '',
      );
    }
  });

  // Handler ao clicar na notificação (app veio de background)
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
    final type = message.data['type'];
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || type == null) return;

    if (type == 'pr') {
      // Navegar para PR (ação futura: ir para tela de histórico)
    } else if (type == 'deload') {
      // Navegar para progressão
    } else if (type == 'inactivity') {
      // Navegar para treino
    }
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Inicializar internacionalização (pt_BR)
  await initializeDateFormatting('pt_BR', null);

  // Inicializar notificações locais
  await NotificationService.initialize();
  NotificationService.scheduleInactivityReminder();

  // Setup FCM (push remoto) — apenas Android/iOS, não funciona no web
  if (!kIsWeb) {
    await fcmSetup();
  }

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
        // API Services
        Provider<ApiService>(create: (_) => ApiService()),
        Provider<WorkoutsApiService>(create: (_) => WorkoutsApiService()),
        Provider<AnalyticsApiService>(create: (_) => AnalyticsApiService()),
        Provider<NutritionApiService>(create: (_) => NutritionApiService()),
        Provider<ProgressionApiService>(create: (_) => ProgressionApiService()),
        Provider<PrescriptionApiService>(create: (_) => PrescriptionApiService()),
        Provider<PrApiService>(create: (_) => PrApiService()),
        Provider<ProApiService>(create: (_) => ProApiService()),

        // Auth & Feature Providers
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
        ChangeNotifierProvider<ProgressionProvider>(
          create: (_) => ProgressionProvider(),
        ),
        ChangeNotifierProvider<NutritionProvider>(
          create: (_) => NutritionProvider(),
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
