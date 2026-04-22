import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../shared/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateWhenReady();
  }

  Future<void> _navigateWhenReady() async {
    // Aguarda no máximo 1s para o Firebase Auth resolver o estado inicial
    // Se resolver antes, navega imediatamente
    final completer = Future.any([
      FirebaseAuth.instance.authStateChanges().first,
      Future.delayed(const Duration(milliseconds: 800)),
    ]);

    // Exibe splash por no mínimo 1.2s para o logo aparecer
    await Future.wait([
      completer,
      Future.delayed(const Duration(milliseconds: 1200)),
    ]);

    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      context.go('/dashboard');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          Center(
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accent.withValues(alpha: 0.15),
                    blurRadius: 100,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(duration: 600.ms),

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                        color: AppTheme.accent.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(
                    Icons.bolt_rounded,
                    color: AppTheme.accent,
                    size: 60,
                  ),
                )
                    .animate()
                    .scale(duration: 500.ms, curve: Curves.easeOutBack)
                    .shimmer(delay: 600.ms, duration: 900.ms),

                const SizedBox(height: 32),

                const Text(
                  'CONTROLE DE CARGA',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                  ),
                ).animate().fadeIn(delay: 300.ms, duration: 500.ms).slideY(begin: 0.2, end: 0),

                const SizedBox(height: 8),

                const Text(
                  'Treinamento de Alta Performance',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                    letterSpacing: 1.5,
                  ),
                ).animate().fadeIn(delay: 600.ms, duration: 500.ms),
              ],
            ),
          ),

          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Column(
              children: [
                const SizedBox(
                  width: 40,
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation(AppTheme.accent),
                    minHeight: 2,
                  ),
                ).animate().fadeIn(delay: 800.ms),
                const SizedBox(height: 20),
                const Text(
                  'POWERED BY ANTIGRAVITY AI',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 10,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w600,
                  ),
                ).animate().fadeIn(delay: 1000.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
