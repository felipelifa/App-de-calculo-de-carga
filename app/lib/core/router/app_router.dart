import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
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

class AppRouter {
  static GoRouter createRouter(AuthService authService) {
    return GoRouter(
      initialLocation: '/login',
      refreshListenable: authService,
      redirect: (context, state) {
        final isLoggedIn = authService.currentUser != null;
        final isAuthRoute =
            state.uri.path == '/login' || state.uri.path == '/register';

        if (!isLoggedIn && !isAuthRoute) return '/login';
        if (isLoggedIn && isAuthRoute) return '/dashboard';
        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardScreen(),
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
          path: '/analytics',
          builder: (context, state) => const AnalyticsScreen(),
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
