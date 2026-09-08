import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/router/app_router.dart';
import 'core/services/auth_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/api_service.dart';
import 'core/services/supabase_service.dart';
import 'core/services/workouts_api_service.dart';
import 'core/services/analytics_api_service.dart';
import 'core/services/nutrition_api_service.dart';
import 'core/services/progression_api_service.dart';
import 'core/services/prescription_api_service.dart';
import 'core/services/pr_api_service.dart';
import 'features/exercises/exercise_provider.dart';
import 'features/workout/workout_provider.dart';
import 'features/workout/workout_profile_provider.dart';
import 'features/workout/progression_provider.dart';
import 'features/nutrition/nutrition_provider.dart';
import 'features/workout/collective_profile_provider.dart';
import 'features/workout/athlete_rank_provider.dart';
import 'features/workout/home_workout/v2_home_source.dart';
import 'shared/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar internacionalização (pt_BR)
  await initializeDateFormatting('pt_BR', null);

  // Inicializar Supabase
  await SupabaseService.initialize();

  // Inicializar notificações locais
  await NotificationService.initialize();
  NotificationService.scheduleInactivityReminder();

  // Inicializar biblioteca V2 Home (46 exercícios)
  V2HomeSource.initialize();

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

        // Auth & Feature Providers
        ChangeNotifierProvider<AuthService>(create: (_) => AuthService()),
        ChangeNotifierProvider<ExerciseProvider>(
          create: (_) => ExerciseProvider(),
        ),
        ChangeNotifierProvider<WorkoutProvider>(
          create: (_) => WorkoutProvider(),
        ),
        ChangeNotifierProvider<WorkoutProfileProvider>(
          create: (context) => WorkoutProfileProvider(
            exerciseProvider: context.read<ExerciseProvider>(),
          ),
        ),
        ChangeNotifierProvider<ProgressionProvider>(
          create: (context) {
            final progressionProvider = ProgressionProvider();
            final workoutProvider = context.read<WorkoutProvider>();
            workoutProvider.connectProgressionProvider(progressionProvider);
            return progressionProvider;
          },
        ),
        ChangeNotifierProvider<NutritionProvider>(
          create: (_) => NutritionProvider(),
        ),
        ChangeNotifierProvider<CollectiveProfileProvider>(
          create: (_) => CollectiveProfileProvider(),
        ),
        ChangeNotifierProvider<AthleteRankProvider>(
          create: (_) => AthleteRankProvider()..startListening(),
        ),
      ],
      child: const _RouterHost(),
    );
  }
}

class _RouterHost extends StatefulWidget {
  const _RouterHost();

  @override
  State<_RouterHost> createState() => _RouterHostState();
}

class _RouterHostState extends State<_RouterHost> {
  GoRouter? _router;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _router ??= AppRouter.createRouter(context.read<AuthService>());
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'BuildFit',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      routerConfig: _router!,
    );
  }
}
