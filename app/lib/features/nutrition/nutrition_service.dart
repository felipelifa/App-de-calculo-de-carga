import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'food_model.dart';

class NutritionService {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  NutritionService({FirebaseFirestore? db, FirebaseAuth? auth})
      : _db = db ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Busca alimentos combinando Firestore e Open Food Facts
  Future<List<FoodModel>> searchFoods(String query) async {
    final queryLower = query.toLowerCase().trim();
    if (queryLower.isEmpty) return [];

    List<FoodModel> results = [];
    final uid = _auth.currentUser?.uid;

    // 1. Busca em Alimentos Customizados do Usuário
    if (uid != null) {
      try {
        final userSnap = await _db
            .collection('users/$uid/nutrition/custom_foods')
            .where('name', isGreaterThanOrEqualTo: queryLower)
            .where('name', isLessThanOrEqualTo: '$queryLower\uf8ff')
            .limit(5)
            .get();
        results.addAll(userSnap.docs.map((d) => FoodModel.fromMap(d.data(), d.id)));
      } catch (_) {}
    }

    // 2. Busca Local (Firestore - Base principal Verificada)
    try {
      final snap = await _db
          .collection('foods')
          .where('name', isGreaterThanOrEqualTo: queryLower)
          .where('name', isLessThanOrEqualTo: '$queryLower\uf8ff')
          .limit(10)
          .get();
      
      for (final doc in snap.docs) {
        final f = FoodModel.fromMap(doc.data(), doc.id);
        if (!results.any((r) => r.id == f.id)) {
          results.add(f);
        }
      }
    } catch (_) {}

    // 3. Tenta Open Food Facts se não houver muitos resultados locais
    if (results.length < 5) {
      try {
        final offResults = await _searchOpenFoodFacts(queryLower);
        for (final food in offResults) {
          if (!results.any((r) => r.name.toLowerCase() == food.name.toLowerCase())) {
            results.add(food);
          }
        }
      } catch (_) {}
    }

    // Ordenação Inteligente: 
    // 1. Frequência de Uso (timesConsumed)
    // 2. Verificação (isVerified)
    // 3. Nome
    results.sort((a, b) {
      if (b.timesConsumed != a.timesConsumed) return b.timesConsumed.compareTo(a.timesConsumed);
      if (a.isVerified && !b.isVerified) return -1;
      if (!a.isVerified && b.isVerified) return 1;
      return a.name.compareTo(b.name);
    });

    return results;
  }

  /// Busca alimento pelo código de barras
  Future<FoodModel?> searchByBarcode(String code) async {
    // 1. Tenta local
    final local = await _db.collection('foods').where('barcode', isEqualTo: code).limit(1).get();
    if (local.docs.isNotEmpty) {
      return FoodModel.fromMap(local.docs.first.data(), local.docs.first.id);
    }

    // 2. Tenta API Global (Open Food Facts)
    try {
      final uri = Uri.parse('https://world.openfoodfacts.org/api/v0/product/$code.json');
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 1) {
          final p = data['product'];
          final nutriments = p['nutriments'];
          if (nutriments != null) {
            return FoodModel(
              id: 'off_$code',
              name: p['product_name_pt'] ?? p['product_name'] ?? 'Produto Desconhecido',
              brand: p['brands'] ?? '',
              caloriesPer100g: (nutriments['energy-kcal_100g'] ?? 0).toDouble(),
              proteinPer100g: (nutriments['proteins_100g'] ?? 0).toDouble(),
              carbPer100g: (nutriments['carbohydrates_100g'] ?? 0).toDouble(),
              fatPer100g: (nutriments['fat_100g'] ?? 0).toDouble(),
              barcode: code,
            );
          }
        }
      }
    } catch (_) {}
    
    return null;
  }

  Future<List<FoodModel>> _searchOpenFoodFacts(String query) async {
    final uri = Uri.parse(
        'https://world.openfoodfacts.org/cgi/search.pl?search_terms=$query&search_simple=1&action=process&json=1&lc=pt&page_size=10');
    
    final response = await http.get(uri);
    if (response.statusCode != 200) return [];

    final data = json.decode(response.body);
    final products = data['products'] as List?;
    if (products == null) return [];

    List<FoodModel> parsed = [];
    for (var p in products) {
      final nutriments = p['nutriments'];
      if (nutriments == null) continue;

      // Pega valores / 100g
      final energy = (nutriments['energy-kcal_100g'] ?? 0).toDouble();
      final protein = (nutriments['proteins_100g'] ?? 0).toDouble();
      final carb = (nutriments['carbohydrates_100g'] ?? 0).toDouble();
      final fat = (nutriments['fat_100g'] ?? 0).toDouble();
      
      final nameStr = p['product_name_pt'] ?? p['product_name'] ?? '';
      if (nameStr.isEmpty || energy == 0) continue; // Ignora cadastro inútil

      parsed.add(FoodModel(
        id: 'off_${p['code']}',
        name: nameStr,
        brand: p['brands'] ?? '',
        caloriesPer100g: energy,
        proteinPer100g: protein,
        carbPer100g: carb,
        fatPer100g: fat,
        isVerified: false,
      ));
    }
    return parsed;
  }

  Future<void> addCustomFood(FoodModel food) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    
    final docRef = _db.collection('users/$uid/nutrition/custom_foods').doc();
    final userFood = FoodModel(
      id: docRef.id,
      name: food.name,
      brand: food.brand,
      caloriesPer100g: food.caloriesPer100g,
      proteinPer100g: food.proteinPer100g,
      carbPer100g: food.carbPer100g,
      fatPer100g: food.fatPer100g,
      isVerified: false,
      isUserCreated: true,
    );
    await docRef.set(userFood.toMap());
  }
}
