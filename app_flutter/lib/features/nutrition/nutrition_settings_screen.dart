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
  bool _dynamicAdaptation = true;
  bool _carbCycling = false;
  bool _useDailyGoals = false;
  Map<int, DailyNutritionalGoal> _dailySpecificGoals = {};
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
      _useDailyGoals = profile.useDailyGoals;
      _dailySpecificGoals = Map.from(profile.dailySpecificGoals);
    }
    
    _proteinController.addListener(_updateKcalFromMacros);
    _carbController.addListener(_updateKcalFromMacros);
    _fatController.addListener(_updateKcalFromMacros);
  }

  void _updateKcalFromMacros() {
    double p = double.tryParse(_proteinController.text) ?? 0;
    double c = double.tryParse(_carbController.text) ?? 0;
    double f = double.tryParse(_fatController.text) ?? 0;
    final derivedKcal = ((p * 4) + (c * 4) + (f * 9)).round().toString();
    if (_kcalController.text != derivedKcal) {
      _kcalController.text = derivedKcal;
    }
  }

  @override
  void dispose() {
    _proteinController.removeListener(_updateKcalFromMacros);
    _carbController.removeListener(_updateKcalFromMacros);
    _fatController.removeListener(_updateKcalFromMacros);
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

    double newP = double.tryParse(_proteinController.text) ?? current.targetProtein;
    double newC = double.tryParse(_carbController.text) ?? current.targetCarb;
    double newF = double.tryParse(_fatController.text) ?? current.targetFat;
    int newKcal = ((newP * 4) + (newC * 4) + (newF * 9)).round();

    final updated = current.copyWith(
      targetCalories: newKcal,
      targetProtein: newP,
      targetCarb: newC,
      targetFat: newF,
      macroMode: _macroMode,
      dynamicAdaptationEnabled: _dynamicAdaptation,
      carbCyclingEnabled: _carbCycling,
      useDailyGoals: _useDailyGoals,
      dailySpecificGoals: _dailySpecificGoals,
    );

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await FirebaseFirestore.instance.doc('users/$uid/nutrition/settings').set(updated.toMap(), SetOptions(merge: true));
      await provider.updateProfile(updated);
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
        actions: [
          if (_isLoading)
            const Center(child: Padding(padding: EdgeInsets.only(right: 16), child: CircularProgressIndicator(strokeWidth: 2)))
          else
            IconButton(icon: const Icon(Icons.check, color: AppTheme.accent), onPressed: _saveSettings),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Configuração de Metas', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                Switch(
                  value: _useDailyGoals,
                  onChanged: (v) => setState(() => _useDailyGoals = v),
                  activeColor: AppTheme.accent,
                ),
              ],
            ),
            Text(
              _useDailyGoals ? 'Seletor de Metas Diárias (Personalizado)' : 'Meta Única Fixa (Todos os dias)',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 20),

            if (_useDailyGoals)
              _buildDailySelector()
            else
              _buildFixedMetaInputs(),

            const SizedBox(height: 32),
            const Text('Comportamento', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildSwitch('Adaptação Dinâmica (Bio-Gestão 7.5)', 'Ajusta macros se você sair da meta ontem.', _dynamicAdaptation, (v) => setState(() => _dynamicAdaptation = v)),
            _buildSwitch('Ciclo de Carboidratos', 'Alterna entre metas altas e baixas de carbo automaticamente.', _carbCycling, (v) => setState(() => _carbCycling = v)),
            
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildFixedMetaInputs() {
    return Column(
      children: [
        _buildTextField('Calorias Totais (Auto)', _kcalController, AppTheme.accent, readOnly: true),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildTextField('Prot (g)', _proteinController, AppTheme.accent)),
            const SizedBox(width: 8),
            Expanded(child: _buildTextField('Carb (g)', _carbController, AppTheme.success)),
            const SizedBox(width: 8),
            Expanded(child: _buildTextField('Gord (g)', _fatController, Colors.orange)),
          ],
        ),
      ],
    );
  }

  Widget _buildDailySelector() {
    final days = ['Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo'];
    return Column(
      children: List.generate(7, (i) {
        final weekday = i + 1;
        final goal = _dailySpecificGoals[weekday] ?? const DailyNutritionalGoal(calories: 2000, protein: 150, carb: 200, fat: 66);
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.accent.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(days[i], style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildMiniField('kcal', goal.calories.toString(), (v) {}, readOnly: true)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildMiniField('P', goal.protein.round().toString(), (v) => _updateGoal(weekday, protein: double.tryParse(v)))),
                  const SizedBox(width: 8),
                  Expanded(child: _buildMiniField('C', goal.carb.round().toString(), (v) => _updateGoal(weekday, carb: double.tryParse(v)))),
                  const SizedBox(width: 8),
                  Expanded(child: _buildMiniField('G', goal.fat.round().toString(), (v) => _updateGoal(weekday, fat: double.tryParse(v)))),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }

  void _updateGoal(int weekday, {double? protein, double? carb, double? fat}) {
    final current = _dailySpecificGoals[weekday] ?? const DailyNutritionalGoal(calories: 2000, protein: 150, carb: 200, fat: 66);
    
    double p = protein ?? current.protein;
    double c = carb ?? current.carb;
    double f = fat ?? current.fat;
    int newCals = ((p * 4) + (c * 4) + (f * 9)).round();

    setState(() {
      _dailySpecificGoals[weekday] = current.copyWith(
        calories: newCals,
        protein: p,
        carb: c,
        fat: f,
      );
    });
  }

  Widget _buildMiniField(String label, String initial, Function(String) onChanged, {bool readOnly = false}) {
    return TextFormField(
      key: ValueKey('${label}_$initial'),
      initialValue: initial,
      readOnly: readOnly,
      keyboardType: TextInputType.number,
      onChanged: onChanged,
      style: TextStyle(
          color: readOnly ? AppTheme.accent : AppTheme.textPrimary, 
          fontSize: 13, 
          fontWeight: FontWeight.bold
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
        isDense: true,
        filled: true,
        fillColor: readOnly ? AppTheme.accent.withValues(alpha: 0.05) : AppTheme.background,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, Color color, {bool readOnly = false}) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: TextInputType.number,
      style: TextStyle(
          color: readOnly ? color : AppTheme.textPrimary, 
          fontWeight: FontWeight.bold
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: color, fontSize: 12),
        filled: true,
        fillColor: readOnly ? color.withValues(alpha: 0.05) : AppTheme.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildSwitch(String title, String subtitle, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      title: Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
      contentPadding: EdgeInsets.zero,
      activeColor: AppTheme.accent,
    );
  }
}
