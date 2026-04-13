import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'food_model.dart';
import 'package:flutter/services.dart' show rootBundle;

class NutritionService {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  NutritionService({FirebaseFirestore? db, FirebaseAuth? auth})
      : _db = db ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final String _fatSecretClientId = const String.fromEnvironment('FATSECRET_CLIENT_ID', defaultValue: '');
  final String _fatSecretClientSecret = const String.fromEnvironment('FATSECRET_CLIENT_SECRET', defaultValue: '');
  String? _fatSecretToken;
  DateTime? _fatSecretTokenExpiry;

  static List<FoodModel>? _cachedTbca;

  Future<void> _loadTbcaCache() async {
    if (_cachedTbca != null) return;
    try {
      final String jsonString = await rootBundle.loadString('assets/data/tbca_minified.json');
      final List<dynamic> data = json.decode(jsonString);
      _cachedTbca = data.map((item) => FoodModel(
        id: item['id'],
        name: item['name'],
        caloriesPer100g: (item['kcal'] as num).toDouble(),
        proteinPer100g: (item['p'] as num).toDouble(),
        carbPer100g: (item['c'] as num).toDouble(),
        fatPer100g: (item['f'] as num).toDouble(),
        category: item['cat'],
        isVerified: true,
      )).toList();
    } catch (_) {
      _cachedTbca = [];
    }
  }

  Future<List<FoodModel>> getRecentFoods() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return [];
    try {
      final snap = await _db.collection('users/$uid/nutrition/recent_foods')
          .orderBy('lastConsumedAt', descending: true)
          .limit(10)
          .get();
      return snap.docs.map((d) => FoodModel.fromMap(d.data(), d.id)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<FoodModel>> getFavoriteFoods() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return [];
    try {
      final snap = await _db.collection('users/$uid/nutrition/favorite_foods').get();
      return snap.docs.map((d) => FoodModel.fromMap(d.data(), d.id)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<FoodModel>> searchFoods(String query) async {
    final queryLower = query.toLowerCase().trim();
    if (queryLower.isEmpty) return [];
    final normalizedQuery = _normalize(queryLower);

    List<FoodModel> results = [];
    final uid = _auth.currentUser?.uid;

    // 1. Search Local Custom Foods (Firestore)
    if (uid != null) {
      try {
        final userSnap = await _db
            .collection('users/$uid/nutrition/custom_foods')
            .get(); // Get all and filter locally for better normalization
        results.addAll(userSnap.docs
            .map((d) => FoodModel.fromMap(d.data(), d.id))
            .where((f) => _normalize(f.name).contains(normalizedQuery)));
      } catch (_) {}
    }

    // 2. Search TBCA (Brazilian Gold Standard)
    final tbcaResults = await _getEmergencyStaples(queryLower);
    for (final food in tbcaResults) {
      if (!results.any((r) => _normalize(r.name) == _normalize(food.name))) {
        results.add(food);
      }
    }

    // 3. Search Cloud Foods (Firestore)
    try {
      final snap = await _db
          .collection('foods')
          .limit(50)
          .get(); // Ideally we'd have a search index, but for now we filter locally or use prefix
      final cloudResults = snap.docs
          .map((d) => FoodModel.fromMap(d.data(), d.id))
          .where((f) => _normalize(f.name).contains(normalizedQuery));
      
      for (final f in cloudResults) {
        if (!results.any((r) => r.id == f.id)) results.add(f);
      }
    } catch (_) {}

    // 4. Search External (Open Food Facts - Recommended for Industrialized)
    if (results.length < 20) {
      final offResults = await _searchOpenFoodFacts(queryLower);
      for (final f in offResults) {
        if (!results.any((r) => _normalize(r.name) == _normalize(f.name))) {
          results.add(f);
        }
      }
    }

    // 5. Search External Fallback (FatSecret)
    if (results.length < 10) {
      try {
        final fsResults = await _searchFatSecret(queryLower);
        for (final food in fsResults) {
          if (!results.any((r) => _normalize(r.name) == _normalize(food.name))) {
            results.add(food);
          }
        }
      } catch (_) {}
    }

    // Ranking Logic:
    // 1. Exact Name Match (Normalized)
    // 2. Starts with query
    // 3. Verified / TBCA
    // 4. Others
    results.sort((a, b) {
      final aNorm = _normalize(a.name);
      final bNorm = _normalize(b.name);
      
      bool aExact = aNorm == normalizedQuery;
      bool bExact = bNorm == normalizedQuery;
      if (aExact && !bExact) return -1;
      if (!aExact && bExact) return 1;

      bool aStarts = aNorm.startsWith(normalizedQuery);
      bool bStarts = bNorm.startsWith(normalizedQuery);
      if (aStarts && !bStarts) return -1;
      if (!aStarts && bStarts) return 1;

      if (a.isVerified && !b.isVerified) return -1;
      if (!a.isVerified && b.isVerified) return 1;

      return a.name.length.compareTo(b.name.length); // Shorter names usually more relevant
    });

    return results.take(40).toList();
  }

  Future<List<FoodModel>> _searchOpenFoodFacts(String query) async {
    try {
      final uri = Uri.parse('https://world.openfoodfacts.org/cgi/search.pl?search_terms=$query&search_simple=1&action=process&json=1&page_size=20&lc=pt');
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List products = data['products'] ?? [];
        return products.map<FoodModel?>((p) {
          final nutriments = p['nutriments'];
          if (nutriments == null) return null;
          
          double parseNum(dynamic val) => (val is num) ? val.toDouble() : 0.0;
          
          final name = p['product_name_pt'] ?? p['product_name'] ?? '';
          if (name.isEmpty) return null;

          return FoodModel(
            id: 'off_${p['_id'] ?? p['code']}',
            name: name,
            brand: p['brands'] ?? '',
            caloriesPer100g: parseNum(nutriments['energy-kcal_100g']),
            proteinPer100g: parseNum(nutriments['proteins_100g']),
            carbPer100g: parseNum(nutriments['carbohydrates_100g']),
            fatPer100g: parseNum(nutriments['fat_100g']),
            category: 'Industrializado',
            isVerified: true,
          );
        }).whereType<FoodModel>().toList();
      }
    } catch (_) {}
    return [];
  }

  Future<FoodModel?> searchByBarcode(String code) async {
    final local = await _db.collection('foods').where('barcode', isEqualTo: code).limit(1).get();
    if (local.docs.isNotEmpty) {
      return FoodModel.fromMap(local.docs.first.data(), local.docs.first.id);
    }
    try {
      final uri = Uri.parse('https://world.openfoodfacts.org/api/v0/product/$code.json');
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 1) {
          final p = data['product'];
          final nutriments = p['nutriments'];
          if (nutriments != null) {
            double parseNum(dynamic val) => (val is num) ? val.toDouble() : 0.0;
            return FoodModel(
              id: 'off_$code',
              name: p['product_name_pt'] ?? p['product_name'] ?? 'Desconhecido',
              brand: p['brands'] ?? '',
              caloriesPer100g: parseNum(nutriments['energy-kcal_100g']),
              proteinPer100g: parseNum(nutriments['proteins_100g']),
              carbPer100g: parseNum(nutriments['carbohydrates_100g']),
              fatPer100g: parseNum(nutriments['fat_100g']),
              isVerified: true,
            );
          }
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> _authenticateFatSecret() async {
    if (_fatSecretToken != null && _fatSecretTokenExpiry != null && DateTime.now().isBefore(_fatSecretTokenExpiry!)) return;
    if (_fatSecretClientId.isEmpty || _fatSecretClientSecret.isEmpty) throw Exception();
    final basicAuth = base64Encode(utf8.encode('$_fatSecretClientId:$_fatSecretClientSecret'));
    final response = await http.post(
      Uri.parse('https://oauth.fatsecret.com/connect/token'),
      headers: {'Authorization': 'Basic $basicAuth', 'Content-Type': 'application/x-www-form-urlencoded'},
      body: 'grant_type=client_credentials&scope=basic',
    );
    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      _fatSecretToken = jsonResponse['access_token'];
      _fatSecretTokenExpiry = DateTime.now().add(Duration(seconds: (jsonResponse['expires_in'] as int) - 60));
    }
  }

  Future<List<FoodModel>> _searchFatSecret(String query) async {
    try { await _authenticateFatSecret(); } catch (_) { return []; }
    final uri = Uri.parse('https://platform.fatsecret.com/rest/server.api?method=foods.search&search_expression=$query&format=json&region=BR&language=pt');
    try {
      final response = await http.get(uri, headers: {'Authorization': 'Bearer $_fatSecretToken'});
      if (response.statusCode != 200) return [];
      final data = json.decode(response.body);
      final foodsData = data['foods'];
      if (foodsData == null || foodsData['food'] == null) return [];
      final items = foodsData['food'] is List ? foodsData['food'] : [foodsData['food']];
      
      return items.map<FoodModel>((f) {
        // Parse food_description: "Per 100g - Calories: 123kcal | Fat: 5.00g | Carbs: 10.00g | Protein: 8.00g"
        final desc = f['food_description'] as String? ?? '';
        double kcal = 0, p = 0, c = 0, fat = 0;
        
        final kcalMatch = RegExp(r'Calories: (\d+)').firstMatch(desc);
        if (kcalMatch != null) kcal = double.tryParse(kcalMatch.group(1)!) ?? 0;
        
        final fatMatch = RegExp(r'Fat: ([\d\.]+)g').firstMatch(desc);
        if (fatMatch != null) fat = double.tryParse(fatMatch.group(1)!) ?? 0;
        
        final carbMatch = RegExp(r'Carbs: ([\d\.]+)g').firstMatch(desc);
        if (carbMatch != null) c = double.tryParse(carbMatch.group(1)!) ?? 0;
        
        final protMatch = RegExp(r'Protein: ([\d\.]+)g').firstMatch(desc);
        if (protMatch != null) p = double.tryParse(protMatch.group(1)!) ?? 0;

        return FoodModel(
          id: 'fs_${f['food_id']}',
          name: f['food_name'] ?? '',
          brand: f['brand_name'] ?? '',
          caloriesPer100g: kcal,
          proteinPer100g: p,
          carbPer100g: c,
          fatPer100g: fat,
          category: f['food_type'] == 'Brand' ? 'Industrializado' : 'Genérico',
        );
      }).toList();
    } catch (_) { return []; }
  }

  String _normalize(String s) {
    return s.toLowerCase()
      .replaceAll(RegExp(r'[áàâãä]'), 'a')
      .replaceAll(RegExp(r'[éèêë]'), 'e')
      .replaceAll(RegExp(r'[íìîï]'), 'i')
      .replaceAll(RegExp(r'[óòôõö]'), 'o')
      .replaceAll(RegExp(r'[úùûü]'), 'u')
      .replaceAll('ç', 'c');
  }

  Future<List<FoodModel>> _getEmergencyStaples(String query) async {
    await _loadTbcaCache();

    final allStaples = [
       FoodModel(id: 'st_1', name: 'Frango (Peito Grelhado)', caloriesPer100g: 165, proteinPer100g: 31, carbPer100g: 0, fatPer100g: 3.6, isVerified: true, category: 'Carnes'),
       FoodModel(id: 'st_2', name: 'Arroz Branco Cozido', caloriesPer100g: 130, proteinPer100g: 2.7, carbPer100g: 28, fatPer100g: 0.3, isVerified: true, category: 'Grãos'),
       FoodModel(id: 'st_3', name: 'Feijão Carioca Cozido', caloriesPer100g: 76, proteinPer100g: 4.8, carbPer100g: 14, fatPer100g: 0.5, isVerified: true, category: 'Grãos'),
       FoodModel(id: 'st_4', name: 'Ovo Inteiro Cozido', caloriesPer100g: 155, proteinPer100g: 13, carbPer100g: 1.1, fatPer100g: 11, isVerified: true, category: 'Proteínas'),
       FoodModel(id: 'st_5', name: 'Banana Prata', caloriesPer100g: 89, proteinPer100g: 1.1, carbPer100g: 23, fatPer100g: 0.3, isVerified: true, category: 'Frutas'),
       FoodModel(id: 'st_6', name: 'Whey Protein (Médio)', caloriesPer100g: 400, proteinPer100g: 80, carbPer100g: 5, fatPer100g: 6, isVerified: true, category: 'Suplementos'),
       FoodModel(id: 'st_7', name: 'Pão de Forma Branco', caloriesPer100g: 265, proteinPer100g: 9, carbPer100g: 49, fatPer100g: 3, isVerified: true, category: 'Padaria'),
       FoodModel(id: 'st_8', name: 'Leite Desnatado', caloriesPer100g: 35, proteinPer100g: 3.4, carbPer100g: 5, fatPer100g: 0, isVerified: true, category: 'Laticínios'),
       FoodModel(id: 'st_9', name: 'Macarrão Cozido (Trigo)', caloriesPer100g: 157, proteinPer100g: 5.8, carbPer100g: 30.9, fatPer100g: 0.9, isVerified: true, category: 'Massas'),
       FoodModel(id: 'st_10', name: 'Pão Francês', caloriesPer100g: 300, proteinPer100g: 8, carbPer100g: 58.6, fatPer100g: 3.1, isVerified: true, category: 'Padaria'),
       FoodModel(id: 'st_11', name: 'Carne Moída (Patinho)', caloriesPer100g: 219, proteinPer100g: 35.9, carbPer100g: 0, fatPer100g: 7.3, isVerified: true, category: 'Carnes'),
       FoodModel(id: 'st_12', name: 'Aveia em Flocos', caloriesPer100g: 394, proteinPer100g: 13.9, carbPer100g: 66.6, fatPer100g: 8.5, isVerified: true, category: 'Grãos'),
       FoodModel(id: 'st_13', name: 'Batata Doce Cozida', caloriesPer100g: 77, proteinPer100g: 0.6, carbPer100g: 18.4, fatPer100g: 0.1, isVerified: true, category: 'Raízes'),
       FoodModel(id: 'st_14', name: 'Tapioca', caloriesPer100g: 336, proteinPer100g: 0, carbPer100g: 83, fatPer100g: 0, isVerified: true, category: 'Raízes'),
       FoodModel(id: 'st_15', name: 'Leite Integral', caloriesPer100g: 60, proteinPer100g: 3.2, carbPer100g: 4.8, fatPer100g: 3.2, isVerified: true, category: 'Laticínios'),
       FoodModel(id: 'st_16', name: 'Azeite de Oliva', caloriesPer100g: 884, proteinPer100g: 0, carbPer100g: 0, fatPer100g: 100, isVerified: true, category: 'Óleos'),
       FoodModel(id: 'st_17', name: 'Manteiga', caloriesPer100g: 717, proteinPer100g: 0.8, carbPer100g: 0.1, fatPer100g: 81.1, isVerified: true, category: 'Laticínios'),
       FoodModel(id: 'st_18', name: 'Maçã (Fuji/Gala)', caloriesPer100g: 52, proteinPer100g: 0.3, carbPer100g: 13.8, fatPer100g: 0.2, isVerified: true, category: 'Frutas'),
    ];

    final List<FoodModel> combined = [...allStaples, ...(_cachedTbca ?? [])];
    final normalizedQuery = _normalize(query);
    return combined.where((s) => _normalize(s.name).contains(normalizedQuery)).take(30).toList();
  }
}
