import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/nutrition/food_model.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Script para importar a base TACO (Unicamp) para o Cloud Firestore.
/// Instruções de Uso:
/// 1. Baixe uma versão JSON da Tabela TACO (ex: TACO API ou versão da Unicamp convertida).
/// 2. Coloque o arquivo em `assets/data/taco_db.json`.
/// 3. Adicione `assets/data/taco_db.json` ao `pubspec.yaml`.
/// 4. Execute esta função apenas UMA VEZ pelo app ou extraia para um script Node.js.
Future<void> seedTacoDatabase() async {
  final db = FirebaseFirestore.instance;
  
  print('Iniciando importação da tabela TACO...');
  
  try {
    // Carrega o arquivo JSON local
    final String jsonString = await rootBundle.loadString('assets/data/taco_db.json');
    final List<dynamic> tacoData = json.decode(jsonString);

    final batch = db.batch();
    int count = 0;

    for (var item in tacoData) {
      // De acordo com os formatos open-source da TACO em JSON:
      // A maioria dos IDs é sequencial. O nome geralmente vem no campo 'description' ou 'nome'.
      final String id = 'taco_${item['id']}';
      final String name = item['description'] ?? item['nome'] ?? 'Alimento Desconhecido';
      final String category = item['category'] ?? item['grupo'] ?? 'Geral';
      
      // Nutrientes por 100g (O padrão da TACO)
      final attributes = item['attributes'] ?? item['nutrientes'] ?? {};
      
      double parseNutrient(dynamic value) {
        if (value == null || value == 'Tr') return 0.0; // 'Tr' = Traços
        if (value is num) return value.toDouble();
        if (value is String) return double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
        return 0.0;
      }

      // Varia dependendo do JSON utilizado, estes são os mapeamentos mais comuns (TACO API v4):
      // Energia em kcal, Proteína, Carboidrato (geralmente por diferença), Lipídios
      final double calories = parseNutrient(attributes['energy_kcal'] ?? attributes['energia_kcal']);
      final double protein = parseNutrient(attributes['protein'] ?? attributes['proteina']);
      final double carb = parseNutrient(attributes['carbohydrate'] ?? attributes['carboidrato']);
      final double fat = parseNutrient(attributes['lipid'] ?? attributes['lipidios']);

      // Apenas adiciona alimentos com valores energéticos válidos
      if (calories > 0 || protein > 0 || carb > 0) {
        final food = FoodModel(
          id: id,
          name: name,
          brand: 'TACO Unicamp', // Fonte oficial
          caloriesPer100g: calories,
          proteinPer100g: protein,
          carbPer100g: carb,
          fatPer100g: fat,
          isVerified: true, // Garante o SELO DE VERFICADO no App
          category: category,
          timesConsumed: 0,
        );

        final docRef = db.collection('foods').doc(id);
        batch.set(docRef, food.toMap());
        count++;

        // Executa em lotes de 500 para respeitar os limites do Firestore
        if (count % 500 == 0) {
          await batch.commit();
          print('Lote $count inserido com sucesso.');
        }
      }
    }

    // Comita os restantes
    if (count % 500 != 0) {
      await batch.commit();
    }

    print('Importação finalizada! $count alimentos TACO verificados foram adicionados ao Firestore.');

  } catch (e) {
    print('Erro crítico ao importar base TACO: $e');
  }
}
