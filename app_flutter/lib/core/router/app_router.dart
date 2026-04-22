import 'package:go_router/go_router.dart';
import '../../shared/widgets/pro_gate_dialog.dart';
import '../services/auth_service.dart';
import '../services/pro_service.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/exercises/exercise_screen.dart';
import '../../features/exercises/exercise_detail_screen.dart';
import '../../features/exercises/add_exercise_screen.dart';
import '../../features/exercises/progression_screen.dart';
import '../../features/workout/workout_screen.dart';
import '../../features/workout/workout_history_screen.dart';
import '../../features/analytics/analytics_screen.dart';
import '../../features/workout/routine_list_screen.dart';
import '../../features/workout/routine_detail_screen.dart';
import '../../features/workout/workout_routine_model.dart';
import '../../features/workout/anamnese_screen.dart';
import '../../features/workout/prescribed_workout_screen.dart';
import '../../features/auth/splash_screen.dart';
import 'main_layout_screen.dart';
import '../../features/nutrition/nutrition_screen.dart';
import '../../features/nutrition/food_search_screen.dart';
import '../../features/nutrition/nutrition_settings_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/nutrition/nutrition_anamnese_screen.dart';
import '../../features/nutrition/nutrition_dashboard_screen.dart';

class AppRouter {
  static GoRouter createRouter(AuthService authService) {
    return GoRouter(
      initialLocation: '/',
      refreshListenable: authService,
      redirect: (context, state) {
        final isLoggedIn = authService.currentUser != null;
        final isAuthRoute =
            state.uri.path == '/login' || state.uri.path == '/register' || state.uri.path == '/';

        if (!isLoggedIn && !isAuthRoute) return '/login';
        if (isLoggedIn && isAuthRoute && state.uri.path != '/') return '/dashboard';

        return null;
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),
        
        // --- CORE SHELL WRAPPER ---
        ShellRoute(
          builder: (context, state, child) => MainLayoutScreen(child: child),
          routes: [
            GoRoute(
              path: '/dashboard',
              builder: (context, state) => const DashboardScreen(),
            ),
            GoRoute(
              path: '/nutrition',
              builder: (context, state) => const NutritionScreen(),
            ),
            GoRoute(
              path: '/analytics',
              builder: (context, state) => const AnalyticsScreen(),
            ),
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
        // --------------------------

        GoRoute(
          path: '/nutrition/search',
          builder: (context, state) {
            final type = state.uri.queryParameters['type'] ?? 'snack';
            return FoodSearchScreen(mealType: type);
          },
        ),
        GoRoute(
          path: '/nutrition/settings',
          builder: (context, state) => const NutritionSettingsScreen(),
        ),
        GoRoute(
          path: '/nutrition/dashboard',
          builder: (context, state) => const NutritionDashboardScreen(),
        ),
        GoRoute(
          path: '/nutrition/anamnese',
          builder: (context, state) => const NutritionAnamneseScreen(),
        ),
        GoRoute(
          path: '/exercises',
          builder: (context, state) => const ExerciseScreen(),
        ),
        GoRoute(
          path: '/exercises/add',
          builder: (context, state) => const AddExerciseScreen(),
        ),
        GoRoute(
          path: '/exercises/:id',
          builder: (_, state) => ExerciseDetailScreen(
            exerciseId: state.pathParameters['id']!,
          ),
        ),
        GoRoute(
          path: '/progression',
          builder: (context, state) => const ProgressionScreen(),
        ),
        GoRoute(
          path: '/workout',
          builder: (context, state) => const WorkoutScreen(),
        ),
        GoRoute(
          path: '/workout/history',
          builder: (context, state) => const WorkoutHistoryScreen(),
        ),
        GoRoute(
          path: '/routines',
          builder: (context, state) => const RoutineListScreen(),
        ),
        GoRoute(
          path: '/routines/detail',
          builder: (context, state) {
            final routine = state.extra as WorkoutRoutine;
            return RoutineDetailScreen(routine: routine);
          },
        ),
        GoRoute(
          path: '/anamnese',
          builder: (context, state) => const AnamneseScreen(),
        ),
        GoRoute(
          path: '/prescribed',
          builder: (context, state) => const PrescribedWorkoutScreen(),
        ),
      ],
    );
  }
}
