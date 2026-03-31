
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/exercises/exercise_screen.dart';
import '../../features/exercises/exercise_detail_screen.dart';
import '../../features/exercises/add_exercise_screen.dart';

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
        // /exercises/add MUST be declared before /exercises/:id
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
      ],
    );
  }
}
