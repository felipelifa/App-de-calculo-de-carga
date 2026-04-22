import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../shared/theme/app_theme.dart';

class MainLayoutScreen extends StatelessWidget {
  final Widget child;

  const MainLayoutScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: Border.all(color: Colors.white.withValues(alpha: 0.06), width: 1),
        ),
        child: BottomNavigationBar(
          backgroundColor: AppTheme.surface,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppTheme.accent,
          unselectedItemColor: AppTheme.textSecondary,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          elevation: 0,
          currentIndex: _calculateSelectedIndex(context),
          onTap: (int idx) => _onItemTapped(idx, context),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.fitness_center_rounded),
              label: 'Treino',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.local_dining_rounded),
              label: 'Nutrição',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_rounded),
              label: 'Progresso',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }

  static int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/dashboard') || location.startsWith('/prescribed')) {
      return 0; // The home/workout feed
    }
    if (location.startsWith('/nutrition')) {
      return 1;
    }
    if (location.startsWith('/analytics')) {
      return 2;
    }
    if (location.startsWith('/profile')) {
      return 3;
    }
    return 0; // fallback
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/nutrition');
        break;
      case 2:
        context.go('/analytics');
        break;
      case 3:
        context.go('/profile');
        break;
    }
  }
}
