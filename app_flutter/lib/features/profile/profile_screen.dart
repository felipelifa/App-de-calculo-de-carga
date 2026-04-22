import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../shared/theme/app_theme.dart';
import '../../core/services/auth_service.dart';
import '../workout/workout_profile_model.dart';
import '../workout/workout_profile_provider.dart';
import '../nutrition/nutrition_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final wpAuth = context.watch<WorkoutProfileProvider>();
    final profile = wpAuth.profile;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppTheme.background,
            expandedHeight: 120,
            floating: true,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              title: Text(
                'Perfil',
                style: GoogleFonts.outfit(
                  color: AppTheme.textPrimary,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (profile != null) ...[
                    _buildDataCard(profile).animate().fadeIn().slideY(begin: 0.1),
                    const SizedBox(height: 32),
                  ],

                  _buildSectionHeader('ESTRATÉGIA'),
                  _buildSettingsGroup([
                    _SettingsTile(
                      icon: Icons.auto_awesome_rounded,
                      title: 'Bio-Gestão 7.0',
                      subtitle: 'Recalibração automática ativa',
                      onTap: () {},
                    ),
                    _SettingsTile(
                      icon: Icons.track_changes_rounded,
                      title: 'Estratégia de Treino',
                      subtitle: profile != null ? profile.primaryGoal.toUpperCase().replaceAll('_', ' ') : '-',
                      onTap: () {},
                    ),
                  ]),
                  const SizedBox(height: 24),

                  _buildSectionHeader('PREFERÊNCIAS'),
                  _buildSettingsGroup([
                    _SettingsTile(
                      icon: Icons.fitness_center_rounded,
                      title: 'Nível de Experiência',
                      subtitle: profile != null ? profile.experienceLevel.toUpperCase() : '-',
                      onTap: () {},
                    ),
                    _SettingsTile(
                      icon: Icons.notifications_none_rounded,
                      title: 'Lembretes de Treino',
                      subtitle: 'Ativado para todos os dias',
                      isToggle: true,
                      toggleValue: true,
                      onChanged: (v) {},
                    ),
                  ]),
                  const SizedBox(height: 24),

                  _buildSectionHeader('APLICATIVO'),
                  _buildSettingsGroup([
                    _SettingsTile(
                      icon: Icons.download_rounded,
                      title: 'Versão Android (APK)',
                      subtitle: 'Baixar aplicativo nativo',
                      iconColor: const Color(0xFFCCFF00),
                      onTap: () => _showDownloadDialog(context),
                    ),
                    _SettingsTile(
                      icon: Icons.logout_rounded,
                      title: 'Sair da Conta',
                      subtitle: 'Desconectar deste dispositivo',
                      iconColor: Colors.redAccent,
                      textColor: Colors.redAccent,
                      onTap: () => context.read<AuthService>().logout(),
                    ),
                  ]),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 0, 12),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          color: AppTheme.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildDataCard(WorkoutProfile profile) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStat('PESO', '${profile.weightKg.toStringAsFixed(1)}', 'kg'),
              Container(width: 1, height: 40, color: Colors.white10),
              _buildStat('ALTURA', '${profile.heightCm.toInt()}', 'cm'),
              Container(width: 1, height: 40, color: Colors.white10),
              _buildStat('IDADE', '${profile.age}', 'anos'),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_rounded, color: Color(0xFFCCFF00), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Inscrição ativa · Assinante PRO',
                    style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String val, String unit) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(val, style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
            const SizedBox(width: 2),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(unit, style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSettingsGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(children: children),
    );
  }

  void _showDownloadDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 32),
            const Icon(Icons.install_mobile_rounded, size: 64, color: Color(0xFFCCFF00)),
            const SizedBox(height: 24),
            Text(
              'EXPERIÊNCIA COMPLETA',
              style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text(
              'Instale a versão nativa Android para ter acesso instantâneo e notificações em tempo real do seu treino.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFCCFF00),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: Text('BAIXAR AGORA', style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.w900, letterSpacing: 1)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool isToggle;
  final bool toggleValue;
  final Function(bool)? onChanged;
  final Color iconColor;
  final Color textColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.isToggle = false,
    this.toggleValue = false,
    this.onChanged,
    this.iconColor = const Color(0xFFCCFF00),
    this.textColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      onTap: !isToggle ? onTap : () => onChanged?.call(!toggleValue),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title, style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.w900, fontSize: 15)),
      subtitle: Text(subtitle, style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 12)),
      trailing: isToggle
          ? Switch(
              value: toggleValue,
              onChanged: onChanged,
              activeColor: const Color(0xFFCCFF00),
              activeTrackColor: const Color(0xFFCCFF00).withOpacity(0.3),
            )
          : const Icon(Icons.chevron_right_rounded, color: Colors.white24),
    );
  }
}

