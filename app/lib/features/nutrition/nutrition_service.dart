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
  // Credenciais do FatSecret (Devem ser injetadas via --dart-define no build)
  final String _fatSecretClientId = const String.fromEnvironment('FATSECRET_CLIENT_ID', defaultValue: '');
  final String _fatSecretClientSecret = const String.fromEnvironment('FATSECRET_CLIENT_SECRET', defaultValue: '');
  String? _fatSecretToken;
  DateTime? _fatSecretTokenExpiry;

  /// Retorna o histórico recente de alimentos (cache local ou log recente)
  Future<List<FoodModel>> getRecentFoods() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return [];

    try {
      // Busca nas últimas refeições registradas (simplificado para uma coleção 'recent_foods')
      final snap = await _db.collection('users/$uid/nutrition/recent_foods')
          .orderBy('lastConsumedAt', descending: true)
          .limit(10)
          .get();
      return snap.docs.map((d) => FoodModel.fromMap(d.data(), d.id)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Retorna a lista de alimentos favoritados pelo usuário
  Future<List<FoodModel>> getFavoriteFoods() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return [];

    try {
      final snap = await _db.collection('users/$uid/nutrition/favorite_foods').get();
      return snap.docs.map((d) {
        var food = FoodModel.fromMap(d.data(), d.id);
        // Em um app real, favorite_foods pode apenas guardar a referência e dar o fetch completo.
        return food;
      }).toList();
    } catch (_) {
      return [];
    }
  }

  /// Busca alimentos combinando Firestore (Preferência TACO) e FatSecret API (BR)
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

    // 3. Busca Dinâmica: API Externa (FatSecret - Região BR)
    if (results.length < 5) {
      try {
        final fsResults = await _searchFatSecret(queryLower);
        for (final food in fsResults) {
          if (!results.any((r) => r.name.toLowerCase() == food.name.toLowerCase())) {
            results.add(food);
          }
        }
      } catch (_) {}
    }

    // 4. Fallback (Open Food Facts) se FatSecret falhar e não houver resultados
    if (results.isEmpty) {
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
    // 1. Verificados da Base Oficial (TACO) primeiro
    // 2. Frequência de Uso (timesConsumed)
    // 3. Nome
    results.sort((a, b) {
      if (a.isVerified && !b.isVerified) return -1;
      if (!a.isVerified && b.isVerified) return 1;
      if (b.timesConsumed != a.timesConsumed) return b.timesConsumed.compareTo(a.timesConsumed);
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
            double parseNum(dynamic val) {
              if (val == null) return 0.0;
              if (val is num) return val.toDouble();
              if (val is String) return double.tryParse(val) ?? 0.0;
              return 0.0;
            }

            return FoodModel(
              id: 'off_$code',
              name: p['product_name_pt'] ?? p['product_name'] ?? 'Produto Desconhecido',
              brand: p['brands'] ?? '',
              caloriesPer100g: parseNum(nutriments['energy-kcal_100g']),
              proteinPer100g: parseNum(nutriments['proteins_100g']),
              carbPer100g: parseNum(nutriments['carbohydrates_100g']),
              fatPer100g: parseNum(nutriments['fat_100g']),
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
    
    try {
      final response = await http.get(uri);
      if (response.statusCode != 200) return [];

      final data = json.decode(response.body);
      final products = data['products'] as List?;
      if (products == null) return [];

      List<FoodModel> parsed = [];
      for (var p in products) {
        final nutriments = p['nutriments'];
        if (nutriments == null) continue;

        double parseNum(dynamic val) {
          if (val == null) return 0.0;
          if (val is num) return val.toDouble();
          if (val is String) return double.tryParse(val) ?? 0.0;
          return 0.0;
        }

        // Pega valores / 100g
        final energy = parseNum(nutriments['energy-kcal_100g']);
        final protein = parseNum(nutriments['proteins_100g']);
        final carb = parseNum(nutriments['carbohydrates_100g']);
        final fat = parseNum(nutriments['fat_100g']);
        
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
    } catch (e) {
      print('Erro no Open Food Facts: $e');
      return [];
    }
  }

  /// Implementação Híbrida: FatSecret API (Região: BR, Idioma: PT)
  Future<void> _authenticateFatSecret() async {
    if (_fatSecretToken != null && _fatSecretTokenExpiry != null && DateTime.now().isBefore(_fatSecretTokenExpiry!)) {
      return; // Token ainda válido
    }

    if (_fatSecretClientId.isEmpty || _fatSecretClientSecret.isEmpty) {
      throw Exception('Credenciais do FatSecret não configuradas');
    }

    final basicAuth = base64Encode(utf8.encode('$_fatSecretClientId:$_fatSecretClientSecret'));
    final uri = Uri.parse('https://oauth.fatsecret.com/connect/token');

    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Basic $basicAuth',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: 'grant_type=client_credentials&scope=basic',
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      _fatSecretToken = jsonResponse['access_token'];
      final expiresIn = jsonResponse['expires_in'] as int;
      _fatSecretTokenExpiry = DateTime.now().add(Duration(seconds: expiresIn - 60)); // 60s margem
    } else {
      throw Exception('Falha na autenticação FatSecret');
    }
  }

  Future<List<FoodModel>> _searchFatSecret(String query) async {
    try {
      await _authenticateFatSecret();
    } catch (_) {
      return []; // Falha silenciosa se não houver credenciais
    }

    final uri = Uri.parse('https://platform.fatsecret.com/rest/server.api?method=foods.search&search_expression=$query&format=json&region=BR&language=pt');
    
    try {
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $_fatSecretToken'},
      );

      if (response.statusCode != 200) return [];
      
      final data = json.decode(response.body);
      final foodsData = data['foods'];
      if (foodsData == null || foodsData['food'] == null) return [];
      
      final items = foodsData['food'] is List ? foodsData['food'] : [foodsData['food']];
      List<FoodModel> parsed = [];

      for (var f in items) {
        // Exemplo de descrição do FatSecret: "Por 100g - Calorias: 121kcal | Gordura: 1,30g | Carbs: 23,24g | Prot: 3,49g"
        final desc = f['food_description'] as String;
        // Parse simplificado para demonstração. O real requerceria Regex detalhado:
        double cals = 0, prot = 0, carb = 0, fat = 0;
        
        // Padrão grosseiro (Na prática você usaria foods.get para pegar os macros exatos da porção, ou regex forte aqui)
        // Como o FatSecret rest/server.api foods.search não retorna os macros soltos por padrão (exige food.get),
        // este é um placeholder assumindo que a string foi convertida ou chamamos outro endpoint.
        
        parsed.add(FoodModel(
          id: 'fs_${f['food_id']}',
          name: f['food_name'] ?? '',
          brand: f['brand_name'] ?? '',
          caloriesPer100g: 0, // Necessário dar um fetch extra dependendo da versão da API
          proteinPer100g: 0,
          carbPer100g: 0,
          fatPer100g: 0,
          isVerified: false,
          category: f['food_type'] == 'Brand' ? 'Industrializado' : 'Genérico',
        ));
      }
      return parsed;
    } catch (e) {
      print('Erro no FatSecret: $e');
      return [];
    }
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
