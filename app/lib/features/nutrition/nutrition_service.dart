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

    // 1. Busca Local (Firestore - Base principal)
    try {
      final snap = await _db
          .collection('foods')
          .where('name', isGreaterThanOrEqualTo: queryLower)
          .where('name', isLessThanOrEqualTo: '$queryLower\uf8ff')
          .limit(10)
          .get();
      
      results.addAll(snap.docs.map((doc) => FoodModel.fromMap(doc.data(), doc.id)));
    } catch (_) {
      // Ignora erro local e tenta API
    }

    // 2. Tenta Open Food Facts se não houver muitos resultados locais
    if (results.length < 5) {
      try {
        final offResults = await _searchOpenFoodFacts(queryLower);
        // Filtra duplicatas básicas por nome
        for (final food in offResults) {
          if (!results.any((r) => r.name.toLowerCase() == food.name.toLowerCase())) {
            results.add(food);
          }
        }
      } catch (_) {
        // Ignora erro da API
      }
    }

    // Ordena priorizando "Verificados"
    results.sort((a, b) {
      if (a.isVerified && !b.isVerified) return -1;
      if (!a.isVerified && b.isVerified) return 1;
      return 0;
    });

    return results;
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
