import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/app_theme.dart';
import 'food_detection_model.dart';
import 'vision_provider.dart';
import 'confidence_engine.dart';
import 'food_matching_engine.dart';
import 'portion_estimation_engine.dart';
import '../food_model.dart';
import '../nutrition_service.dart';
import '../nutrition_provider.dart';
import '../meal_model.dart';

// ─────────────────────────────────────────────
// Tela de Análise de Foto de Refeição
// Captura foto e identifica alimentos
// ─────────────────────────────────────────────

class MealPhotoScreen extends StatefulWidget {
  const MealPhotoScreen({super.key});

  @override
  State<MealPhotoScreen> createState() => _MealPhotoScreenState();
}

class _MealPhotoScreenState extends State<MealPhotoScreen> {
  final ImagePicker _picker = ImagePicker();
  final VisionProvider _visionProvider = VisionProviderFactory.create();
  final FoodMatchingEngine _matchingEngine = FoodMatchingEngine();
  
  File? _imageFile;
  MealAnalysisResult? _analysisResult;
  bool _isAnalyzing = false;
  String? _error;
  
  // Resultados confirmados pelo usuário
  final List<_ConfirmedFood> _confirmedFoods = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: const Text(
          'Foto da Refeição',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_confirmedFoods.isNotEmpty)
            TextButton(
              onPressed: _saveMeal,
              child: const Text(
                'SALVAR',
                style: TextStyle(
                  color: AppTheme.accent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: _imageFile == null
          ? _buildCaptureScreen()
          : _isAnalyzing
              ? _buildAnalyzingScreen()
              : _analysisResult != null
                  ? _buildResultScreen()
                  : _buildErrorScreen(),
    );
  }

  // ── Tela de Captura ──
  Widget _buildCaptureScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt,
                color: AppTheme.accent,
                size: 64,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Fotografe sua refeição',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'O BuildFit vai identificar os alimentos automaticamente.',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _captureImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text('TIRAR FOTO'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  foregroundColor: AppTheme.background,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _captureImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('ESCOLHER DA GALERIA'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.accent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: AppTheme.accent),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Tela de Análise ──
  Widget _buildAnalyzingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_imageFile != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                _imageFile!,
                height: 200,
                width: 200,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(height: 32),
          const CircularProgressIndicator(color: AppTheme.accent),
          const SizedBox(height: 24),
          const Text(
            'Analisando sua refeição...',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Identificando alimentos',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  // ── Tela de Resultado ──
  Widget _buildResultScreen() {
    final detections = _analysisResult!.detections;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(
              _imageFile!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 24),
          
          const Text(
            'Encontrei isso na sua refeição:',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          if (detections.isEmpty) ...[
            const Text(
              'Não consegui identificar alimentos nesta foto.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
            ),
            const SizedBox(height: 24),
            _buildActionButton('TENTAR NOVAMENTE', () {
              setState(() {
                _imageFile = null;
                _analysisResult = null;
              });
            }),
          ] else ...[
            ...detections.map((detection) => _buildDetectionCard(detection)),
            const SizedBox(height: 24),
            _buildActionButton('CONFIRMAR TUDO', _confirmAll, isPrimary: true),
            const SizedBox(height: 12),
            _buildActionButton('ADICIONAR ALIMENTO', _addFoodManually),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, VoidCallback onPressed, {bool isPrimary = false}) {
    return SizedBox(
      width: double.infinity,
      child: isPrimary
          ? ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent,
                foregroundColor: AppTheme.background,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            )
          : OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.accent,
                side: const BorderSide(color: AppTheme.accent),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(label, style: const TextStyle(fontSize: 16)),
            ),
    );
  }

  // ── Card de Detecção ──
  Widget _buildDetectionCard(FoodDetection detection) {
    final confidenceColor = Color(ConfidenceEngine.getConfidenceColor(detection.confidenceLevel));
    final confidenceIcon = ConfidenceEngine.getConfidenceIcon(detection.confidenceLevel);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(confidenceIcon, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        detection.name,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (detection.category != null)
                        Text(
                          detection.category!,
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                  onPressed: () => _removeDetection(detection),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildPortionSelector(detection),
          ],
        ),
      ),
    );
  }

  Widget _buildPortionSelector(FoodDetection detection) {
    final portion = detection.portionEstimate;
    final currentSize = portion?.sizeCategory ?? PortionSize.normal;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quantidade:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildPortionButton('Pouco', PortionSize.small, detection, currentSize == PortionSize.small),
            const SizedBox(width: 8),
            _buildPortionButton('Normal', PortionSize.normal, detection, currentSize == PortionSize.normal),
            const SizedBox(width: 8),
            _buildPortionButton('Bastante', PortionSize.large, detection, currentSize == PortionSize.large),
          ],
        ),
      ],
    );
  }

  Widget _buildPortionButton(String label, PortionSize size, FoodDetection detection, bool isSelected) {
    return Expanded(
      child: OutlinedButton(
        onPressed: () => _updatePortion(detection, size),
        style: OutlinedButton.styleFrom(
          backgroundColor: isSelected ? AppTheme.accent.withValues(alpha: 0.1) : Colors.transparent,
          side: BorderSide(color: isSelected ? AppTheme.accent : AppTheme.textSecondary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppTheme.accent : AppTheme.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // ── Tela de Erro ──
  Widget _buildErrorScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppTheme.danger, size: 64),
            const SizedBox(height: 24),
            Text(
              _error ?? 'Erro desconhecido',
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => setState(() { _imageFile = null; _error = null; }),
                child: const Text('TENTAR NOVAMENTE'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Ações ──

  Future<void> _captureImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source, maxWidth: 1024, maxHeight: 1024, imageQuality: 85);
      if (image == null) return;
      
      setState(() {
        _imageFile = File(image.path);
        _isAnalyzing = true;
        _error = null;
      });
      
      await _analyzeImage();
    } catch (e) {
      setState(() => _error = 'Erro ao capturar imagem: $e');
    }
  }

  Future<void> _analyzeImage() async {
    if (_imageFile == null) return;
    
    try {
      final result = await _visionProvider.detectFoods(_imageFile!);
      setState(() {
        _analysisResult = result;
        _isAnalyzing = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erro ao analisar imagem: $e';
        _isAnalyzing = false;
      });
    }
  }

  void _removeDetection(FoodDetection detection) {
    setState(() {
      _analysisResult = MealAnalysisResult(
        id: _analysisResult!.id,
        imagePath: _analysisResult!.imagePath,
        detections: _analysisResult!.detections.where((d) => d.id != detection.id).toList(),
        analyzedAt: _analysisResult!.analyzedAt,
        visionModelVersion: _analysisResult!.visionModelVersion,
        overallConfidence: _analysisResult!.overallConfidence,
        requiresConfirmation: _analysisResult!.requiresConfirmation,
      );
    });
  }

  void _updatePortion(FoodDetection detection, PortionSize size) {
    final updatedDetection = detection.copyWith(
      portionEstimate: PortionEstimate(
        grams: PortionEstimationEngine.estimate(category: detection.category, sizeCategory: size).grams,
        sizeCategory: size,
        confidence: 0.8,
      ),
    );
    
    setState(() {
      final index = _analysisResult!.detections.indexWhere((d) => d.id == detection.id);
      if (index != -1) {
        final detections = List<FoodDetection>.from(_analysisResult!.detections);
        detections[index] = updatedDetection;
        _analysisResult = MealAnalysisResult(
          id: _analysisResult!.id,
          imagePath: _analysisResult!.imagePath,
          detections: detections,
          analyzedAt: _analysisResult!.analyzedAt,
          visionModelVersion: _analysisResult!.visionModelVersion,
          overallConfidence: _analysisResult!.overallConfidence,
          requiresConfirmation: _analysisResult!.requiresConfirmation,
        );
      }
    });
  }

  void _confirmAll() {
    // Confirmar todos os alimentos detectados
    for (final detection in _analysisResult!.detections) {
      _confirmedFoods.add(_ConfirmedFood(detection: detection));
    }
    _saveMeal();
  }

  void _addFoodManually() {
    // Abrir tela de busca manual
    Navigator.of(context).pop();
    // Navegar para food_search_screen
  }

  void _saveMeal() async {
    if (_confirmedFoods.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhum alimento confirmado')),
      );
      return;
    }

    final nutritionProvider = context.read<NutritionProvider>();
    final nutritionService = NutritionService();
    
    for (final confirmed in _confirmedFoods) {
      // Buscar alimento no banco
      final results = await nutritionService.searchFoods(confirmed.detection.name);
      
      if (results.isNotEmpty) {
        final food = results.first;
        final portionGrams = confirmed.detection.portionEstimate?.grams ?? 150.0;
        
        // Calcular macros
        final multiplier = portionGrams / 100;
        
        final meal = MealEntry(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          foodId: food.id,
          foodName: food.name,
          portionG: portionGrams,
          calories: food.caloriesPer100g * multiplier,
          protein: food.proteinPer100g * multiplier,
          carb: food.carbPer100g * multiplier,
          fat: food.fatPer100g * multiplier,
          mealType: 'lunch',
          loggedAt: DateTime.now(),
        );
        
        await nutritionProvider.addMeal(meal);
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_confirmedFoods.length} alimento(s) registrado(s)!'),
          backgroundColor: AppTheme.success,
        ),
      );
      Navigator.of(context).pop();
    }
  }
}

// ── Modelo interno ──
class _ConfirmedFood {
  final FoodDetection detection;
  const _ConfirmedFood({required this.detection});
}
