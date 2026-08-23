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
              icon: Icon(Icons.home_rounded),
              label: 'Hoje',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.fitness_center_rounded),
              label: 'Treinos',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.local_dining_rounded),
              label: 'Nutrição',
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
    if (location.startsWith('/dashboard')) {
      return 0; // Hoje
    }
    if (location.startsWith('/workout') || location.startsWith('/prescribed') || location.startsWith('/exercises')) {
      return 1; // Treinos
    }
    if (location.startsWith('/nutrition')) {
      return 2; // Nutrição
    }
    if (location.startsWith('/profile') || location.startsWith('/analytics') || location.startsWith('/change-history')) {
      return 3; // Perfil
    }
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/prescribed');
        break;
      case 2:
        context.go('/nutrition');
        break;
      case 3:
        context.go('/profile');
        break;
    }
  }
}
