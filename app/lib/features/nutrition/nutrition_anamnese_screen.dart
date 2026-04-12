import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  String _goal = 'maintenance'; // 'cutting', 'bulking', 'maintenance'
  String _activityLevel = 'moderate'; // 'sedentary', 'light', 'moderate', 'active', 'very_active'
  String _macroMode = 'automatic';
  String _compensationStrategy = 'automatic';
  int _mealsPerDay = 4;
  bool _weeklyBudgetEnabled = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final wp = context.read<WorkoutProfileProvider>().profile;
    if (wp != null) {
      _goal = wp.goal;
      // Map activity level from workout profile if possible
    }
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
      final wp = context.read<WorkoutProfileProvider>().profile;
      if (wp == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, complete a anamnese de treino primeiro.')),
        );
        context.go('/anamnese');
        return;
      }

      final provider = context.read<NutritionProvider>();
      final newProfile = NutritionEngine.calculateProfile(
        wp,
        macroMode: _macroMode,
        dynamicAdaptationEnabled: _weeklyBudgetEnabled,
      ).copyWith(
        compensationStrategy: _compensationStrategy,
      );

      await provider.updateProfile(newProfile);
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
        title: const Text('Anamnese Nutricional'),
        backgroundColor: AppTheme.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vamos configurar sua dieta',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Estes dados ajudam a calcular seus macros com precisão científica.',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 32),

            _buildSectionTitle('Qual seu objetivo atual?'),
            _buildChoiceChip<String>(
              options: {
                'cutting': 'Cutting (Perder Gordura)',
                'maintenance': 'Manutenção',
                'bulking': 'Bulking (Ganhar Músculo)',
              },
              currentValue: _goal,
              onSelected: (val) => setState(() => _goal = val),
            ),

            const SizedBox(height: 24),
            _buildSectionTitle('Frequência de refeições'),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _mealsPerDay.toDouble(),
                    min: 2,
                    max: 8,
                    divisions: 6,
                    label: '$_mealsPerDay refeições',
                    activeColor: AppTheme.accent,
                    onChanged: (v) => setState(() => _mealsPerDay = v.toInt()),
                  ),
                ),
                Text('$_mealsPerDay refeições', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),

            const SizedBox(height: 24),
            _buildSectionTitle('Distribuição de Macronutrientes'),
            _buildChoiceChip<String>(
              options: {
                'automatic': 'Equilibrada (Sugerido)',
                'low_carb': 'Low Carb',
                'high_protein': 'Alta Proteína',
              },
              currentValue: _macroMode,
              onSelected: (val) => setState(() => _macroMode = val),
            ),

            const SizedBox(height: 24),
            _buildSectionTitle('Bio-Gestão: Como lidar com deslizes?'),
            const Text(
              'Caso você saia da dieta hoje, como o sistema deve agir?',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            _buildChoiceChip<String>(
              options: {
                'automatic': 'Diluir nos próximos dias (Suave)',
                'linear': 'Compensar no dia seguinte (Rígido)',
                'none': 'Ignorar e seguir o plano',
              },
              currentValue: _compensationStrategy,
              onSelected: (val) => setState(() => _compensationStrategy = val),
            ),

            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'GERAR MINHA DIETA',
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
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
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
          selectedColor: AppTheme.accent.withOpacity(0.2),
          labelStyle: TextStyle(
            color: isSelected ? AppTheme.accent : AppTheme.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: isSelected ? AppTheme.accent : Colors.transparent),
          ),
        );
      }).toList(),
    );
  }
}
