import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/theme/app_theme.dart';
import 'nutrition_provider.dart';
import '../workout/workout_profile_provider.dart';
import 'nutrition_engine.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anon';
      final provider = context.read<NutritionProvider>();
      
      // Gera o perfil Bio-Gestão 7.0
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
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Configuração Bio-Gestão', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.accent, AppTheme.accent.withOpacity(0.7)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(Icons.auto_awesome, color: Colors.white, size: 32),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nutrição Adaptativa 7.0',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        Text(
                          'Sua dieta agora se ajusta aos seus treinos e falhas automaticamente.',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            _buildSectionTitle('Objetivo Fisiológico'),
            _buildChoiceChip<String>(
              options: {
                'cutting': 'Perda de Gordura',
                'maintenance': 'Estabilização / Performance',
                'bulking': 'Hipertrofia Ativa',
              },
              currentValue: _goal,
              onSelected: (val) => setState(() => _goal = val),
            ),

            const SizedBox(height: 24),
            _buildSectionTitle('Distribuição de Macros'),
            _buildChoiceChip<String>(
              options: {
                'automatic': 'Prioridade Proteica (Sugestão)',
                'percentage': 'Divisão Percentual',
                'grams': 'Ajuste Manual em Gramas',
              },
              currentValue: _macroMode,
              onSelected: (val) => setState(() => _macroMode = val),
            ),

            const SizedBox(height: 24),
            _buildSectionTitle('Motor de Compensação'),
            const Text(
              'Como o sistema deve reagir se você comer a mais em um dia?',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            _buildChoiceChip<String>(
              options: {
                'automatic': 'Redistribuição Suave (Flexível)',
                'linear': 'Compensação Direta (Focada)',
                'none': 'Meta Fixa (Sem compensação)',
              },
              currentValue: _compensationStrategy,
              onSelected: (val) => setState(() => _compensationStrategy = val),
            ),

            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Compensação Inteligente', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: const Text('Ajusta o orçamento de amanhã se você errar hoje (Bio-Gestão).', style: TextStyle(fontSize: 12)),
              value: _dynamicAdaptationEnabled,
              activeColor: AppTheme.accent,
              onChanged: (v) => setState(() => _dynamicAdaptationEnabled = v),
            ),
            
            SwitchListTile(
              title: const Text('Ciclagem de Carboidratos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: const Text('Distribui mais carboidratos nos seus dias de treino.', style: TextStyle(fontSize: 12)),
              value: _carbCyclingEnabled,
              activeColor: AppTheme.success,
              onChanged: (v) => setState(() => _carbCyclingEnabled = v),
            ),

            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 8,
                  shadowColor: AppTheme.accent.withOpacity(0.4),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'ATUALIZAR MEU PLANO',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
      ),
    );
  }

  Widget _buildChoiceChip<T>({
    required Map<T, String> options,
    required T currentValue,
    required Function(T) onSelected,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.entries.map((e) {
        final isSelected = e.key == currentValue;
        return ChoiceChip(
          label: Text(e.value),
          selected: isSelected,
          onSelected: (_) => onSelected(e.key),
          selectedColor: AppTheme.accent.withOpacity(0.15),
          labelStyle: TextStyle(
            color: isSelected ? AppTheme.accent : AppTheme.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: isSelected ? AppTheme.accent : AppTheme.divider.withOpacity(0.1)),
          ),
        );
      }).toList(),
    );
  }
}

