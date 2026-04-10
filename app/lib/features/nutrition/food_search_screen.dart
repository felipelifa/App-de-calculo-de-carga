import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../shared/theme/app_theme.dart';
import 'nutrition_service.dart';
import 'nutrition_provider.dart';
import 'food_model.dart';
import 'meal_model.dart';

class FoodSearchScreen extends StatefulWidget {
  final String mealType;
  const FoodSearchScreen({super.key, required this.mealType});

  @override
  State<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends State<FoodSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final NutritionService _service = NutritionService();
  
  Timer? _debounce;
  List<FoodModel> _results = [];
  bool _isSearching = false;

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.trim().isEmpty) {
        setState(() {
          _results = [];
          _isSearching = false;
        });
        return;
      }

      setState(() => _isSearching = true);
      final res = await _service.searchFoods(query);
      if (mounted) {
        setState(() {
          _results = res;
          _isSearching = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Adicionar Alimento'),
        backgroundColor: AppTheme.surface,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            color: AppTheme.surface,
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Buscar alimento (ex: Frango, Arroz)...',
                hintStyle: const TextStyle(color: AppTheme.textSecondary),
                prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
                filled: true,
                fillColor: AppTheme.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          if (_isSearching)
            const Expanded(child: Center(child: CircularProgressIndicator(color: AppTheme.accent)))
          else if (_results.isEmpty && _searchController.text.isNotEmpty)
            const Expanded(
              child: Center(
                child: Text('Nenhum alimento encontrado.', style: TextStyle(color: AppTheme.textSecondary)),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final food = _results[index];
                  return ListTile(
                    title: Row(
                      children: [
                        Expanded(child: Text(food.name, style: const TextStyle(color: AppTheme.textPrimary))),
                        if (food.isVerified)
                          const Icon(Icons.verified, color: AppTheme.accent, size: 16),
                      ],
                    ),
                    subtitle: Text(
                      '${food.caloriesPer100g.round()} kcal / 100g' + (food.brand.isNotEmpty ? ' • ${food.brand}' : ''),
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                    onTap: () => _openPortionSelector(context, food),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  void _openPortionSelector(BuildContext context, FoodModel food) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _PortionSelectorSheet(food: food, mealType: widget.mealType),
    );
  }
}

class _PortionSelectorSheet extends StatefulWidget {
  final FoodModel food;
  final String mealType;
  
  const _PortionSelectorSheet({required this.food, required this.mealType});

  @override
  State<_PortionSelectorSheet> createState() => _PortionSelectorSheetState();
}

class _PortionSelectorSheetState extends State<_PortionSelectorSheet> {
  double _portionG = 100.0;
  final TextEditingController _gController = TextEditingController(text: '100');

  @override
  void dispose() {
    _gController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ratio = _portionG / 100.0;
    final kcal = widget.food.caloriesPer100g * ratio;
    final p = widget.food.proteinPer100g * ratio;
    final c = widget.food.carbPer100g * ratio;
    final f = widget.food.fatPer100g * ratio;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24, right: 24, top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.food.name, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _gController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    suffixText: 'gramas',
                    suffixStyle: TextStyle(color: AppTheme.textSecondary),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _portionG = double.tryParse(val) ?? 0.0;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMacroInfo('Calorias', '${kcal.round()} kcal', AppTheme.textPrimary),
              _buildMacroInfo('Prot', '${p.round()}g', AppTheme.accent),
              _buildMacroInfo('Carb', '${c.round()}g', AppTheme.success),
              _buildMacroInfo('Gord', '${f.round()}g', Colors.orange),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () async {
                if (_portionG <= 0) return;
                
                final entry = MealEntry(
                  id: '', // provider creates ID
                  foodId: widget.food.id,
                  foodName: widget.food.name,
                  portionG: _portionG,
                  calories: kcal,
                  protein: p,
                  carb: c,
                  fat: f,
                  mealType: widget.mealType,
                  loggedAt: DateTime.now(),
                );
                
                await context.read<NutritionProvider>().addMeal(entry);
                if (context.mounted) {
                  Navigator.pop(context); // close sheet
                  context.pop(); // close search
                }
              },
              child: const Text('ADICIONAR REFEIÇÃO', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildMacroInfo(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
}
