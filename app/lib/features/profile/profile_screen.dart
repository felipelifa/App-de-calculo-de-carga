import 'package:flutter/material.dart';
import '../../shared/theme/app_theme.dart';
import '../../core/services/auth_service.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Perfil'),
        backgroundColor: AppTheme.surface,
        elevation: 0,
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            context.read<AuthService>().logout();
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
          child: const Text('Sair / Logout'),
        ),
      ),
    );
  }
}
