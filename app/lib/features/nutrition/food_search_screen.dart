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
  List<FoodModel> _recentFoods = [];
  List<FoodModel> _favoriteFoods = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadRecents();
  }

  Future<void> _loadRecents() async {
    final recents = await _service.getRecentFoods();
    final favs = await _service.getFavoriteFoods();
    if (mounted) {
      setState(() {
        _recentFoods = recents;
        _favoriteFoods = favs;
      });
    }
  }

  Future<void> _scanBarcode() async {
    // Lógica de Scan (em Web mostra um input, em mobile abriria câmera)
    String? code = await _showBarcodeInputDialog();
    if (code != null && code.isNotEmpty) {
      setState(() => _isSearching = true);
      final food = await _service.searchByBarcode(code);
      if (mounted) {
        setState(() => _isSearching = false);
        if (food != null) {
          _openPortionSelector(context, food);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Produto não encontrado na base global.')),
          );
        }
      }
    }
  }

  Future<String?> _showBarcodeInputDialog() async {
    String? code;
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Escanear Produto', style: TextStyle(color: AppTheme.textPrimary)),
        content: TextField(
          autofocus: true,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(
            hintText: 'Digite o código de barras...',
            hintStyle: TextStyle(color: AppTheme.textSecondary),
          ),
          onChanged: (v) => code = v,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
          ElevatedButton(onPressed: () => Navigator.pop(context, code), child: const Text('BUSCAR')),
        ],
      ),
    );
  }

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
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: const Text('Adicionar Alimento'),
          backgroundColor: AppTheme.surface,
          elevation: 0,
          bottom: const TabBar(
            indicatorColor: AppTheme.accent,
            labelColor: AppTheme.accent,
            unselectedLabelColor: AppTheme.textSecondary,
            tabs: [
              Tab(text: 'RECENTES'),
              Tab(text: 'MEUS ITENS'),
              Tab(text: 'BIBLIOTECA'),
            ],
          ),
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
                  hintText: 'Buscar na biblioteca...',
                  hintStyle: const TextStyle(color: AppTheme.textSecondary),
                  prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.qr_code_scanner, color: AppTheme.accent),
                    onPressed: _scanBarcode,
                  ),
                  filled: true,
                  fillColor: AppTheme.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // Tab 1: RECENTES
                  _recentFoods.isEmpty 
                    ? _buildEmptyState('Nenhum consumo recente.')
                    : ListView(children: _recentFoods.map((f) => _buildFoodTile(f)).toList()),
                  
                  // Tab 2: MEUS ITENS (Favoritos + Receitas)
                  ListView(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: ElevatedButton.icon(
                          onPressed: () => _showCreateRecipeDialog(context),
                          icon: const Icon(Icons.add_circle_outline),
                          label: const Text('CRIAR NOVA RECEITA'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accent.withValues(alpha: 0.1),
                            foregroundColor: AppTheme.accent,
                            side: const BorderSide(color: AppTheme.accent),
                            padding: const EdgeInsets.all(16),
                          ),
                        ),
                      ),
                      if (_favoriteFoods.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Text('FAVORITOS', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                        ..._favoriteFoods.map((f) => _buildFoodTile(f)),
                      ],
                      // Aqui poderiam entrar receitas salvas filtradas do NutritionProvider
                    ],
                  ),

                  // Tab 3: BIBLIOTECA (Busca)
                  _isSearching 
                    ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
                    : _results.isEmpty 
                      ? _buildEmptyState('Busque frango, arroz, etc.')
                      : ListView(children: _results.map((f) => _buildFoodTile(f)).toList()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Center(
      child: Text(msg, style: const TextStyle(color: AppTheme.textSecondary, fontStyle: FontStyle.italic)),
    );
  }

  void _showCreateRecipeDialog(BuildContext context) {
    // Placeholder para abertura de tela de receita ou diálogo simples
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Módulo de criação de receitas em breve!')));
  }

  Widget _buildFoodTile(FoodModel food) {
    final provider = context.watch<NutritionProvider>();
    final isFav = provider.isFoodFavorite(food.id);
    
    return ListTile(
      title: Row(
        children: [
          Expanded(child: Text(food.name, style: const TextStyle(color: AppTheme.textPrimary))),
          if (food.isVerified)
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Icon(Icons.verified, color: AppTheme.accent, size: 16),
            ),
        ],
      ),
      subtitle: Text(
        '${food.caloriesPer100g.round()} kcal / 100g' + (food.brand.isNotEmpty ? ' • ${food.brand}' : ''),
        style: const TextStyle(color: AppTheme.textSecondary),
      ),
      trailing: IconButton(
        icon: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: isFav ? Colors.redAccent : AppTheme.textSecondary, size: 20),
        onPressed: () {
          provider.toggleFavoriteFood(food);
        },
      ),
      onTap: () => _openPortionSelector(context, food),
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
  bool _isCheatMeal = false;
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
          const SizedBox(height: 16),
          CheckboxListTile(
            title: const Text('Marcar como Besteira (Furo na dieta)', style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
            subtitle: const Text('O app irá diluir os macros excedentes nos próximos dias.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
            value: _isCheatMeal,
            activeColor: AppTheme.accent,
            checkColor: Colors.white,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            onChanged: (val) {
              setState(() {
                _isCheatMeal = val ?? false;
              });
            },
          ),
          const SizedBox(height: 24),
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
                  isCheatMeal: _isCheatMeal,
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
