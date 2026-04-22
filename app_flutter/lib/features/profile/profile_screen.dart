import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
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
            floating: true,
            pinned: true,
            expandedHeight: 120,
            flexibleSpace: FlexibleSpaceBar(
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
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (profile != null) ...[
                    _buildSectionHeader('DADOS PESSOAIS', Icons.person_rounded),
                    _buildDataCard(profile),
                    const SizedBox(height: 32),
                  ],

                  _buildSectionHeader('NUTRIÇÃO E ESTRATÉGIA', Icons.restaurant_rounded),
                  _buildSettingsGroup([
                    _SettingsTile(
                      icon: Icons.auto_awesome,
                      title: 'Modo de Cálculo',
                      subtitle: 'Automático (Bio-Gestão)',
                      onTap: () {},
                    ),
                    _SettingsTile(
                      icon: Icons.track_changes_rounded,
                      title: 'Estratégia Nutricional',
                      subtitle: 'Recomposição Corporal',
                      onTap: () {},
                    ),
                    _SettingsTile(
                      icon: Icons.balance_rounded,
                      title: 'Compensação Semanal',
                      subtitle: 'Ativo (Diluição Automática)',
                      isToggle: true,
                      toggleValue: true,
                      onChanged: (v) {},
                    ),
                  ]),
                  const SizedBox(height: 32),

                  _buildSectionHeader('PREFERÊNCIAS', Icons.tune_rounded),
                  _buildSettingsGroup([
                    _SettingsTile(
                      icon: Icons.fitness_center_rounded,
                      title: 'Nível de Complexidade',
                      subtitle: profile != null ? profile.experienceLevel.toUpperCase() : 'INTERMEDIÁRIO',
                      onTap: () {},
                    ),
                    _SettingsTile(
                      icon: Icons.straighten_rounded,
                      title: 'Unidade de Medida',
                      subtitle: 'Sistema Métrico (kg, cm)',
                      onTap: () {},
                    ),
                    _SettingsTile(
                      icon: Icons.notifications_none_rounded,
                      title: 'Notificações',
                      subtitle: 'Ativadas',
                      onTap: () {},
                    ),
                  ]),
                  const SizedBox(height: 32),

                  _buildSectionHeader('APLICATIVO', Icons.phone_android_rounded),
                  _buildSettingsGroup([
                    _SettingsTile(
                      icon: Icons.download_rounded,
                      title: 'Baixar Aplicativo',
                      subtitle: 'Instale o APK nativo no Android',
                      iconColor: const Color(0xFF3DDC84),
                      onTap: () => _showDownloadDialog(context),
                    ),
                  ]),
                  const SizedBox(height: 32),

                  _buildSectionHeader('CONTA', Icons.shield_rounded),
                  _buildSettingsGroup([
                    _SettingsTile(
                      icon: Icons.data_usage_rounded,
                      title: 'Exportar Dados',
                      subtitle: 'Baixe um histórico em CSV',
                      onTap: () {},
                    ),
                    _SettingsTile(
                      icon: Icons.restart_alt_rounded,
                      title: 'Resetar Plano',
                      subtitle: 'Refazer anamnese e reiniciar metas',
                      onTap: () {},
                    ),
                    _SettingsTile(
                      icon: Icons.logout_rounded,
                      title: 'Sair da Conta',
                      subtitle: 'Desconectar dispositivo',
                      iconColor: AppTheme.danger,
                      textColor: AppTheme.danger,
                      onTap: () => context.read<AuthService>().logout(),
                    ),
                  ]),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.accent, size: 18),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.outfit(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataCard(WorkoutProfile profile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDataStat('Peso', '${profile.weightKg.toStringAsFixed(1)} kg'),
              _buildDataStat('Altura', '${profile.heightCm.toInt()} cm'),
              _buildDataStat('Idade', '${profile.age} anos'),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: Colors.white10, height: 1),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.ads_click_rounded, color: AppTheme.accent, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Foco Principal', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                  Text(
                    profile.primaryGoal.toUpperCase().replaceAll('_', ' '),
                    style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildDataStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Widget _buildSettingsGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: children.asMap().entries.map((entry) {
          final isLast = entry.key == children.length - 1;
          return Column(
            children: [
              entry.value,
              if (!isLast) const Divider(color: Colors.white10, height: 1, indent: 56, endIndent: 20),
            ],
          );
        }).toList(),
      ),
    );
  }
  
  void _showDownloadDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 32),
            const Icon(Icons.install_mobile_rounded, size: 64, color: Color(0xFF3DDC84)),
            const SizedBox(height: 20),
            const Text(
              'Instale o App no Android',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 12),
            const Text(
              'Acesse todos os recursos de forma nativa e muito mais rápida no seu celular Android.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Download iniciado...')),
                  );
                },
                icon: const Icon(Icons.download_rounded, color: Colors.white),
                label: const Text('BAIXAR INSTALADOR (APK)', 
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3DDC84), 
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Dica: Se o Android bloquear, habilite "Instalar de fontes desconhecidas".',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
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
    this.iconColor = AppTheme.accent,
    this.textColor = AppTheme.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      onTap: !isToggle ? onTap : () => onChanged?.call(!toggleValue),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
      ),
      trailing: isToggle
          ? Switch(
              value: toggleValue,
              onChanged: onChanged,
              activeColor: AppTheme.accent,
            )
          : Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary.withOpacity(0.5)),
    );
  }
}
