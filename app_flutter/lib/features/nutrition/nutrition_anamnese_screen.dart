import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/services/auth_service.dart';
import '../../shared/theme/app_theme.dart';
import 'nutrition_provider.dart';
import '../workout/workout_profile_provider.dart';
import 'nutrition_engine.dart';
import 'package:go_router/go_router.dart';

class NutritionAnamneseScreen extends StatefulWidget {
  const NutritionAnamneseScreen({super.key});

  @override
  State<NutritionAnamneseScreen> createState() => _NutritionAnamneseScreenState();
}

class _NutritionAnamneseScreenState extends State<NutritionAnamneseScreen> {
  String _goal = 'maintenance'; 
  String _macroMode = 'automatic';
  String _compensationStrategy = 'automatic';
  bool _dynamicAdaptationEnabled = true;
  bool _carbCyclingEnabled = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final wp = context.read<WorkoutProfileProvider>().profile;
    if (wp != null) {
      if (wp.primaryGoal == 'fat_loss') {
        _goal = 'cutting';
      } else if (wp.primaryGoal == 'hypertrophy') {
        _goal = 'bulking';
      } else {
        _goal = 'maintenance';
      }
    }
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
      final wp = context.read<WorkoutProfileProvider>().profile;
      if (wp == null) {
        context.go('/anamnese');
        return;
      }

      final uid = context.read<AuthService>().currentUser?.id ?? 'anon';
      final provider = context.read<NutritionProvider>();
      
      final initialProfile = NutritionEngine.generateInitialProfile(
        wp,
        id: uid,
        macroMode: _macroMode,
        dynamicAdaptationEnabled: _dynamicAdaptationEnabled,
        carbCyclingEnabled: _carbCyclingEnabled,
      );
      
      final finalProfile = initialProfile.copyWith(
        compensationStrategy: _compensationStrategy,
      );

      await provider.updateProfile(finalProfile);
      if (mounted) context.go('/nutrition');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const neon = Color(0xFFCCFF00);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'BIO-GESTÃO CONFIG',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16),
        ),
        backgroundColor: AppTheme.background,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroBanner(neon).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1),
            const SizedBox(height: 32),

            _buildSectionTitle('Objetivo Fisiológico'),
            _buildChoiceChip<String>(
              neon: neon,
              options: {
                'cutting': 'Perda de Gordura',
                'maintenance': 'Estabilidade / Performance',
                'bulking': 'Hipertrofia Ativa',
              },
              currentValue: _goal,
              onSelected: (val) => setState(() => _goal = val),
            ).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 32),
            _buildSectionTitle('Distribuição de Macros'),
            _buildChoiceChip<String>(
              neon: neon,
              options: {
                'automatic': 'Prioridade Proteica (Bio)',
                'percentage': 'Divisão Percentual',
                'grams': 'Ajuste em Gramas',
              },
              currentValue: _macroMode,
              onSelected: (val) => setState(() => _macroMode = val),
            ).animate().fadeIn(delay: 300.ms),

            const SizedBox(height: 32),
            _buildSectionTitle('Motor de Compensação'),
            Text(
              'Como o sistema reage se você comer a mais em um dia?',
              style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            _buildChoiceChip<String>(
              neon: neon,
              options: {
                'automatic': 'Redistribuição Flexível',
                'linear': 'Compensação Focada',
                'none': 'Meta Fixa (Rígida)',
              },
              currentValue: _compensationStrategy,
              onSelected: (val) => setState(() => _compensationStrategy = val),
            ).animate().fadeIn(delay: 400.ms),

            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF161616),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
              ),
              child: Column(
                children: [
                   _buildNeonSwitch(
                    title: 'Compensação Inteligente',
                    subtitle: 'Ajusta seu saldo de amanhã se errar hoje.',
                    value: _dynamicAdaptationEnabled,
                    neon: neon,
                    onChanged: (v) => setState(() => _dynamicAdaptationEnabled = v),
                  ),
                  const Divider(height: 1, color: Colors.white10, indent: 20, endIndent: 20),
                  _buildNeonSwitch(
                    title: 'Ciclagem de Carboidratos',
                    subtitle: 'Mais macros em dias de treino intenso.',
                    value: _carbCyclingEnabled,
                    neon: neon,
                    onChanged: (v) => setState(() => _carbCyclingEnabled = v),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 500.ms).scale(begin: const Offset(0.95, 0.95)),

            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: neon,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 12,
                  shadowColor: neon.withValues(alpha: 0.3),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.black)
                    : Text(
                        'ATUALIZAR MEU PLANO',
                        style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 1),
                      ),
              ),
            ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroBanner(Color neon) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: neon.withValues(alpha: 0.1)),
        boxShadow: [
            BoxShadow(color: neon.withValues(alpha: 0.05), blurRadius: 40, offset: const Offset(0, 10))
        ]
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: neon.withValues(alpha: 0.1),
                shape: BoxShape.circle,
            ),
            child: Icon(Icons.bolt_rounded, color: neon, size: 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nutrição Adaptativa 7.0',
                  style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
                ),
                const SizedBox(height: 4),
                Text(
                  'O motor recalcula suas metas automaticamente.',
                  style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNeonSwitch({
    required String title,
    required String subtitle,
    required bool value,
    required Color neon,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
      subtitle: Text(subtitle, style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 11)),
      value: value,
      activeColor: neon,
      activeTrackColor: neon.withValues(alpha: 0.2),
      inactiveThumbColor: Colors.white24,
      inactiveTrackColor: Colors.white10,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      onChanged: onChanged,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.outfit(
            fontSize: 11, 
            fontWeight: FontWeight.w900, 
            color: AppTheme.textSecondary,
            letterSpacing: 1.5
        ),
      ),
    );
  }

  Widget _buildChoiceChip<T>({
    required Map<T, String> options,
    required T currentValue,
    required Function(T) onSelected,
    required Color neon,
  }) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: options.entries.map((e) {
        final isSelected = e.key == currentValue;
        return GestureDetector(
          onTap: () => onSelected(e.key),
          child: AnimatedContainer(
            duration: 200.ms,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? neon.withValues(alpha: 0.1) : const Color(0xFF161616),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? neon : Colors.white.withValues(alpha: 0.05),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Text(
              e.value,
              style: GoogleFonts.outfit(
                color: isSelected ? neon : AppTheme.textSecondary,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
