import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/services/api_service.dart';
import 'food_model.dart';
import 'package:flutter/services.dart' show rootBundle;

class NutritionService {
  final ApiService _api;

  NutritionService({ApiService? api}) : _api = api ?? ApiService();

  final String _fatSecretClientId = const String.fromEnvironment('FATSECRET_CLIENT_ID', defaultValue: '');
  final String _fatSecretClientSecret = const String.fromEnvironment('FATSECRET_CLIENT_SECRET', defaultValue: '');
  final String _usdaApiKey = const String.fromEnvironment('USDA_API_KEY', defaultValue: 'DEMO_KEY');
  
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
        source: 'tbca',
      )).toList();
    } catch (_) {
      _cachedTbca = [];
    }
  }

  String _normalize(String s) {
    if (s.isEmpty) return '';
    String normalized = s.toLowerCase()
      .replaceAll(RegExp(r'[áàâãä]'), 'a')
      .replaceAll(RegExp(r'[éèêë]'), 'e')
      .replaceAll(RegExp(r'[íìîï]'), 'i')
      .replaceAll(RegExp(r'[óòôõö]'), 'o')
      .replaceAll(RegExp(r'[úùûü]'), 'u')
      .replaceAll('ç', 'c')
      .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');

    final stopWords = {'de', 'com', 'da', 'do', 'em', 'para', 'um', 'uma', 'o', 'a', 'com', 'sem', 'ao', 'aos', 'em'};
    
    final synonyms = {
      'bolacha': 'biscoito',
      'bolachas': 'biscoitos',
      'nesfit': 'nesfit biscoito cereal integral',
      'pepsi': 'pepsi refrigerante cola',
      'coke': 'coca cola',
      'sucrilhos': 'cereal matinal',
      'light': 'baixo teor',
    };

    List<String> words = normalized.split(RegExp(r'\s+'))
        .where((w) => w.length > 1 && !stopWords.contains(w))
        .toList();

    for (int i = 0; i < words.length; i++) {
        if (synonyms.containsKey(words[i])) {
            words[i] = synonyms[words[i]]!;
        }
    }

    return words.join(' ').trim();
  }

  Future<List<FoodModel>> searchFoods(String originalQuery) async {
    final query = originalQuery.trim();
    if (query.isEmpty) return [];
    
    final normalized = _normalize(query);
    if (normalized.isEmpty) return await _getEmergencyStaples(query);

    List<FoodModel> results = [];

    // CAMADA 1: BUSCA INTERNA (API + CACHE LOCAL)
    final internalTasks = <Future<List<FoodModel>>>[
      _searchApiLibrary(normalized),
      _searchApiRecents(normalized),
      _getEmergencyStaples(normalized),
    ];

    final internalBatches = await Future.wait(internalTasks);
    for (var batch in internalBatches) {
      results.addAll(batch);
    }

    // CAMADA 2: BUSCA EXTERNA PARALELA
    if (results.length < 15) {
      final externalTasks = <Future<List<FoodModel>>>[
        _searchOpenFoodFacts(query),
        _searchFatSecret(query),
        _searchUSDA(query),
      ];

      final externalBatches = await Future.wait(externalTasks);
      for (var batch in externalBatches) {
        for (var food in batch) {
          final isDuplicate = results.any((r) => 
            _normalize(r.name) == _normalize(food.name) && 
            _normalize(r.brand) == _normalize(food.brand)
          );
          if (!isDuplicate) {
            results.add(food);
            _persistExternalFood(food);
          }
        }
      }
    }

    return _rankResults(results, normalized);
  }

  Future<List<FoodModel>> _searchApiLibrary(String normalizedQuery) async {
    try {
      final result = await _api.get('/nutrition/foods/search', queryParams: {
        'q': normalizedQuery,
        'limit': '20',
      });
      final data = result['data'] as List<dynamic>? ?? [];
      return data.map((d) => FoodModel.fromMap(d as Map<String, dynamic>, d['id'] as String? ?? '')).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<FoodModel>> _searchApiRecents(String normalizedQuery) async {
    try {
      final result = await _api.get('/nutrition/recent-foods', queryParams: {
        'q': normalizedQuery,
        'limit': '20',
      });
      final data = result['data'] as List<dynamic>? ?? [];
      return data.map((d) => FoodModel.fromMap(d as Map<String, dynamic>, d['id'] as String? ?? '')).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<FoodModel>> _searchOpenFoodFacts(String query) async {
    try {
      final uri = Uri.parse('https://world.openfoodfacts.org/cgi/search.pl?search_terms=${Uri.encodeComponent(query)}&search_simple=1&action=process&json=1&page_size=15&lc=pt');
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List products = data['products'] ?? [];
        return products.map<FoodModel?>((p) {
          final nutriments = p['nutriments'];
          if (nutriments == null) return null;
          double parse(dynamic v) => (v is num) ? v.toDouble() : 0.0;
          final name = p['product_name_pt'] ?? p['product_name'] ?? '';
          if (name.isEmpty) return null;
          return FoodModel(
            id: 'off_${p['code']}',
            name: name,
            brand: p['brands'] ?? '',
            caloriesPer100g: parse(nutriments['energy-kcal_100g']),
            proteinPer100g: parse(nutriments['proteins_100g']),
            carbPer100g: parse(nutriments['carbohydrates_100g']),
            fatPer100g: parse(nutriments['fat_100g']),
            category: 'Industrializado',
            source: 'off',
            barcode: p['code']?.toString(),
          );
        }).whereType<FoodModel>().toList();
      }
    } catch (_) {}
    return [];
  }

  Future<List<FoodModel>> _searchUSDA(String query) async {
    try {
      final uri = Uri.parse('https://api.nal.usda.gov/fdc/v1/foods/search?api_key=$_usdaApiKey&query=${Uri.encodeComponent(query)}&pageSize=10');
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List foods = data['foods'] ?? [];
        return foods.map<FoodModel?>((f) {
           final nutrients = f['foodNutrients'] as List?;
           if (nutrients == null) return null;
           
           double findNutrient(int id) {
             final n = nutrients.firstWhere((n) => n['nutrientId'] == id || n['nutrientNumber'] == id.toString(), orElse: () => null);
             return (n != null && n['value'] != null) ? (n['value'] as num).toDouble() : 0.0;
           }

           return FoodModel(
             id: 'usda_${f['fdcId']}',
             name: f['description'] ?? '',
             brand: f['brandOwner'] ?? '',
             caloriesPer100g: findNutrient(1008),
             proteinPer100g: findNutrient(1003),
             carbPer100g: findNutrient(1005),
             fatPer100g: findNutrient(1004),
             category: 'Genérico',
             source: 'usda',
           );
        }).whereType<FoodModel>().toList();
      }
    } catch (_) {}
    return [];
  }

  Future<List<FoodModel>> _searchFatSecret(String query) async {
    try {
      await _authenticateFatSecret();
      final uri = Uri.parse('https://platform.fatsecret.com/rest/server.api?method=foods.search&search_expression=${Uri.encodeComponent(query)}&format=json&region=BR&language=pt');
      final response = await http.get(uri, headers: {'Authorization': 'Bearer $_fatSecretToken'});
      if (response.statusCode != 200) return [];
      final data = json.decode(response.body);
      final foodsData = data['foods'];
      if (foodsData == null || foodsData['food'] == null) return [];
      final items = foodsData['food'] is List ? foodsData['food'] : [foodsData['food']];
      
      return items.map<FoodModel>((f) {
        final desc = f['food_description'] as String? ?? '';
        double kcal = 0, p = 0, c = 0, fat = 0;
        kcal = _parseFatSecretValue(desc, 'Calories:');
        fat = _parseFatSecretValue(desc, 'Fat:');
        c = _parseFatSecretValue(desc, 'Carbs:');
        p = _parseFatSecretValue(desc, 'Protein:');

        return FoodModel(
          id: 'fs_${f['food_id']}',
          name: f['food_name'] ?? '',
          brand: f['brand_name'] ?? '',
          caloriesPer100g: kcal,
          proteinPer100g: p,
          carbPer100g: c,
          fatPer100g: fat,
          category: f['food_type'] == 'Brand' ? 'Industrializado' : 'Genérico',
          source: 'fs',
        );
      }).toList();
    } catch (_) { return []; }
  }

  double _parseFatSecretValue(String desc, String key) {
    final match = RegExp('$key (\\d+\\.?\\d*)').firstMatch(desc);
    return match != null ? double.tryParse(match.group(1)!) ?? 0.0 : 0.0;
  }

  void _persistExternalFood(FoodModel food) {
    if (food.source == 'local' || food.source == 'tbca') return;
    _api.post('/nutrition/foods', body: food.toMap()).catchError((_) => null);
  }

  List<FoodModel> _rankResults(List<FoodModel> results, String normalizedQuery) {
    final scored = results.map((f) {
      int score = 0;
      final fNorm = _normalize(f.name);
      final bNorm = _normalize(f.brand);
      final combined = "$fNorm $bNorm".trim();

      if (combined == normalizedQuery) score += 500;
      else if (fNorm == normalizedQuery) score += 400;
      else if (combined.startsWith(normalizedQuery)) score += 300;
      else if (combined.contains(normalizedQuery)) score += 200;

      if (f.source == 'tbca' || f.isVerified) score += 100;
      if (f.source == 'local') score += 50;
      
      score += (f.timesConsumed * 5);

      if (f.caloriesPer100g == 0) score -= 100;

      return {'food': f, 'score': score};
    }).toList();

    scored.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));
    
    final Map<String, FoodModel> unique = {};
    for (var item in scored) {
      final f = item['food'] as FoodModel;
      final key = _normalize('${f.name}_${f.brand}');
      if (!unique.containsKey(key)) {
        unique[key] = f;
      }
    }

    return unique.values.toList();
  }

  Future<FoodModel?> searchByBarcode(String code) async {
    try {
      final result = await _api.get('/nutrition/foods/barcode/$code');
      if (result != null && result is Map<String, dynamic>) {
        return FoodModel.fromMap(result, result['id'] as String? ?? '');
      }
    } catch (_) {}
    
    try {
      final uri = Uri.parse('https://world.openfoodfacts.org/api/v0/product/$code.json');
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 1) {
          final p = data['product'];
          final nut = p['nutriments'];
          if (nut != null) {
            double parse(dynamic v) => (v is num) ? v.toDouble() : 0.0;
            final food = FoodModel(
              id: 'off_$code',
              name: p['product_name_pt'] ?? p['product_name'] ?? 'Produto Desconhecido',
              brand: p['brands'] ?? '',
              caloriesPer100g: parse(nut['energy-kcal_100g']),
              proteinPer100g: parse(nut['proteins_100g']),
              carbPer100g: parse(nut['carbohydrates_100g']),
              fatPer100g: parse(nut['fat_100g']),
              isVerified: true,
              source: 'off',
              barcode: code,
            );
            _persistExternalFood(food);
            return food;
          }
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> _authenticateFatSecret() async {
    if (_fatSecretToken != null && _fatSecretTokenExpiry != null && DateTime.now().isBefore(_fatSecretTokenExpiry!)) return;
    if (_fatSecretClientId.isEmpty || _fatSecretClientSecret.isEmpty) return;
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

  Future<List<FoodModel>> getRecentFoods() async {
    try {
      final result = await _api.get('/nutrition/recent-foods', queryParams: {'limit': '15'});
      final data = result['data'] as List<dynamic>? ?? [];
      return data.map((d) => FoodModel.fromMap(d as Map<String, dynamic>, d['id'] as String? ?? '')).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<FoodModel>> getFavoriteFoods() async {
    try {
      final result = await _api.get('/nutrition/favorite-foods');
      final data = result['data'] as List<dynamic>? ?? [];
      return data.map((d) => FoodModel.fromMap(d as Map<String, dynamic>, d['id'] as String? ?? '')).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<FoodModel>> _getEmergencyStaples(String query) async {
    await _loadTbcaCache();
    final staples = [
       FoodModel(id: 'st_1', name: 'Frango (Peito Grelhado)', caloriesPer100g: 165, proteinPer100g: 31, carbPer100g: 0, fatPer100g: 3.6, isVerified: true, category: 'Carnes'),
       FoodModel(id: 'st_2', name: 'Arroz Branco Cozido', caloriesPer100g: 130, proteinPer100g: 2.7, carbPer100g: 28, fatPer100g: 0.3, isVerified: true, category: 'Grãos'),
       FoodModel(id: 'st_3', name: 'Feijão Carioca Cozido', caloriesPer100g: 76, proteinPer100g: 4.8, carbPer100g: 14, fatPer100g: 0.5, isVerified: true, category: 'Grãos'),
       FoodModel(id: 'st_4', name: 'Ovo Inteiro Cozido', caloriesPer100g: 155, proteinPer100g: 13, carbPer100g: 1.1, fatPer100g: 11, isVerified: true, category: 'Proteínas'),
       FoodModel(id: 'st_5', name: 'Banana Prata', caloriesPer100g: 89, proteinPer100g: 1.1, carbPer100g: 23, fatPer100g: 0.3, isVerified: true, category: 'Frutas'),
       FoodModel(id: 'st_6', name: 'Whey Protein', caloriesPer100g: 400, proteinPer100g: 80, carbPer100g: 5, fatPer100g: 6, isVerified: true, category: 'Suplementos'),
       FoodModel(id: 'st_7', name: 'Pão Francês', caloriesPer100g: 300, proteinPer100g: 8, carbPer100g: 58.6, fatPer100g: 3.1, isVerified: true, category: 'Padaria'),
    ];

    final List<FoodModel> combined = [...staples, ...(_cachedTbca ?? <FoodModel>[])];
    final norm = _normalize(query);
    return combined.where((f) => _normalize(f.name).contains(norm)).take(20).toList();
  }
}
