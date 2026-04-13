import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../shared/theme/app_theme.dart';
import 'nutrition_provider.dart';
import 'nutrition_profile_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NutritionSettingsScreen extends StatefulWidget {
  const NutritionSettingsScreen({super.key});

  @override
  State<NutritionSettingsScreen> createState() => _NutritionSettingsScreenState();
}

class _NutritionSettingsScreenState extends State<NutritionSettingsScreen> {
  final TextEditingController _kcalController = TextEditingController();
  final TextEditingController _proteinController = TextEditingController();
  final TextEditingController _carbController = TextEditingController();
  final TextEditingController _fatController = TextEditingController();

  String _macroMode = 'automatic';
  bool _dynamicAdaptation = false;
  bool _carbCycling = false;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final profile = context.read<NutritionProvider>().profile;
    if (profile != null) {
      _kcalController.text = profile.targetCalories.toString();
      _proteinController.text = profile.targetProtein.round().toString();
      _carbController.text = profile.targetCarb.round().toString();
      _fatController.text = profile.targetFat.round().toString();
      _macroMode = profile.macroMode;
      _dynamicAdaptation = profile.dynamicAdaptationEnabled;
      _carbCycling = profile.carbCyclingEnabled;
    }
  }

  @override
  void dispose() {
    _kcalController.dispose();
    _proteinController.dispose();
    _carbController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    final provider = context.read<NutritionProvider>();
    final current = provider.profile;

    if (current == null) return;

    setState(() => _isLoading = true);

    int newKcal = int.tryParse(_kcalController.text) ?? current.targetCalories;
    double newP = double.tryParse(_proteinController.text) ?? current.targetProtein;
    double newC = double.tryParse(_carbController.text) ?? current.targetCarb;
    double newF = double.tryParse(_fatController.text) ?? current.targetFat;

    // Se continuar no automático, as mudanças manuais de macro não são salvas forçadas 
    // mas por garantia a gente vai forçar o modo "grams" (manual) se quisermos metas personalizadas fixas.
    if (_macroMode == 'automatic') {
      // Automatico recalcula pelo motor quando initFromProfile rodar novamente, 
      // mas vamos salvar a caloria base e deixar o engine entender da próxima vez, ou apenas forçar o novo macro.
    }

    final updated = current.copyWith(
      targetCalories: newKcal,
      targetProtein: newP,
      targetCarb: newC,
      targetFat: newF,
      macroMode: _macroMode,
      dynamicAdaptationEnabled: _dynamicAdaptation,
      carbCyclingEnabled: _carbCycling,
    );

    // Save bypassing provider just to force immediate write, and reload
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await FirebaseFirestore.instance.doc('users/$uid/nutrition/settings').set(updated.toMap(), SetOptions(merge: true));
      await provider.updateProfile(updated); // We need to add this method in Provider
    }

    if (mounted) {
      setState(() => _isLoading = false);
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Configurações Nutricionais'),
        backgroundColor: AppTheme.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Metas Diárias Fixas', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildTextField('Calorias (kcal)', _kcalController, AppTheme.accent),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildTextField('Proteína (g)', _proteinController, AppTheme.accent)),
                const SizedBox(width: 12),
                Expanded(child: _buildTextField('Carboidratos (g)', _carbController, AppTheme.success)),
                const SizedBox(width: 12),
                Expanded(child: _buildTextField('Gorduras (g)', _fatController, Colors.orange)),
              ],
            ),
            
            const SizedBox(height: 24),
            const Text('Modo de Criação de Dieta', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _macroMode,
              dropdownColor: AppTheme.surfaceHighlight,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppTheme.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              items: const [
                DropdownMenuItem(value: 'automatic', child: Text('Automático (Gêmeo Digital)', style: TextStyle(color: AppTheme.textPrimary))),
                DropdownMenuItem(value: 'grams', child: Text('Manual (Respeita números acima)', style: TextStyle(color: AppTheme.textPrimary))),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _macroMode = val);
              },
            ),

            const SizedBox(height: 32),
            const Text('Estratégias Avançadas (Adaptativas)', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Row(
                children: [
                  const Text('Sensibilidade de Treino (Motor Digital)', style: TextStyle(color: AppTheme.textPrimary)),
                  const SizedBox(width: 8),
                  Tooltip(
                    message: 'Adiciona ~10% das kcal na Meta do Dia baseando-se no volume/duração do treino recém-concluído.',
                    preferBelow: false,
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    child: Icon(Icons.info_outline, color: AppTheme.accent.withOpacity(0.7), size: 16),
                  ),
                ],
              ),
              subtitle: const Text('Aumenta calorias automaticamente de acordo com o treino diário para regeneração celular.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              value: _dynamicAdaptation,
              activeColor: AppTheme.accent,
              onChanged: (val) => setState(() => _dynamicAdaptation = val),
            ),
            
            const Divider(color: Colors.white12),

            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Row(
                children: [
                  const Text('Ciclagem de Carboidratos', style: TextStyle(color: AppTheme.textPrimary)),
                  const SizedBox(width: 8),
                  Tooltip(
                    message: 'Dias de treino: +10% de calorias puxadas dos Carbos. Dias de descanso: -15% de calorias e carbos. Se as duas estratégias estiverem ligadas, esta dita a divisão inicial da semana, e a Sensibilidade bonifica o Custo do Treino no dia.',
                    preferBelow: false,
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    child: Icon(Icons.info_outline, color: AppTheme.accent.withOpacity(0.7), size: 16),
                  ),
                ],
              ),
              subtitle: const Text('Aumenta os carboidratos em dias de treino e os reduz em dias de descanso.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              value: _carbCycling,
              activeColor: AppTheme.accent,
              onChanged: (val) => setState(() => _carbCycling = val),
            ),

            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text('SALVAR CONFIGURAÇÕES', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, Color stripColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppTheme.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: stripColor.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: stripColor),
            ),
          ),
        ),
      ],
    );
  }
}
