import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> main() async {
    final query = "frango";
    final uri = Uri.parse(
        'https://world.openfoodfacts.org/cgi/search.pl?search_terms=$query&search_simple=1&action=process&json=1&lc=pt&page_size=10');
    
    final response = await http.get(uri);
    final data = json.decode(response.body);
    final products = data['products'] as List?;
    
    for (var p in products!) {
      final nutriments = p['nutriments'];
      if (nutriments == null) continue;

      try {
        final energy = (nutriments['energy-kcal_100g'] ?? 0).toDouble();
        final protein = (nutriments['proteins_100g'] ?? 0).toDouble();
        final carb = (nutriments['carbohydrates_100g'] ?? 0).toDouble();
        final fat = (nutriments['fat_100g'] ?? 0).toDouble();
        print("${p['product_name']}: $energy kcal");
      } catch (e) {
        print("Error: $e for ${p['product_name']}");
      }
    }
}
