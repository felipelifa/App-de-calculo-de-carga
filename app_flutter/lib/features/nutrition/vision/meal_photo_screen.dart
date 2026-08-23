import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../shared/theme/app_theme.dart';
import 'food_detection_model.dart';
import 'vision_provider.dart';
import 'confidence_engine.dart';
import 'food_matching_engine.dart';
import 'portion_estimation_engine.dart';
import '../food_model.dart';

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
            // Botão câmera
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
            // Botão galeria
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
          // Imagem sendo analisada
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
          // Imagem analisada
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
          
          // Título
          const Text(
            'Encontrei isso na sua refeição:',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Lista de alimentos detectados
          if (detections.isEmpty) ...[
            const Text(
              'Não consegui identificar alimentos nesta foto.',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _imageFile = null;
                    _analysisResult = null;
                  });
                },
                child: const Text('TENTAR NOVAMENTE'),
              ),
            ),
          ] else ...[
            ...detections.map((detection) => _buildDetectionCard(detection)),
            const SizedBox(height: 24),
            
            // Botão confirmar todos
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _confirmAll,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  foregroundColor: AppTheme.background,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'CONFIRMAR TUDO',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            // Botão adicionar manualmente
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _addFoodManually,
                icon: const Icon(Icons.add),
                label: const Text('ADICIONAR ALIMENTO'),
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
        ],
      ),
    );
  }

  // ── Card de Detecção ──
  Widget _buildDetectionCard(FoodDetection detection) {
    final confidenceColor = Color(ConfidenceEngine.getConfidenceColor(detection.confidenceLevel));
    final confidenceIcon = ConfidenceEngine.getConfidenceIcon(detection.confidenceLevel);
    final confidenceMessage = ConfidenceEngine.getConfidenceMessage(detection.confidenceLevel);
    
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
                // Ícone de confiança
                Text(confidenceIcon, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                // Nome do alimento
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
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),
                // Botão de ação
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: AppTheme.textSecondary),
                  onSelected: (value) => _handleDetectionAction(value, detection),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Editar'),
                    ),
                    const PopupMenuItem(
                      value: 'remove',
                      child: Text('Remover'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Mensagem de confiança
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: confidenceColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: confidenceColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      confidenceMessage,
                      style: TextStyle(
                        color: confidenceColor,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Estimativa de porção
            if (detection.portionEstimate != null) ...[
              const SizedBox(height: 12),
              _buildPortionSelector(detection),
            ],
          ],
        ),
      ),
    );
  }

  // ── Seletor de Porção ──
  Widget _buildPortionSelector(FoodDetection detection) {
    final portion = detection.portionEstimate!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quantidade:',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildPortionButton(
              'Pouco',
              PortionSize.small,
              detection,
              portion.sizeCategory == PortionSize.small,
            ),
            const SizedBox(width: 8),
            _buildPortionButton(
              'Normal',
              PortionSize.normal,
              detection,
              portion.sizeCategory == PortionSize.normal,
            ),
            const SizedBox(width: 8),
            _buildPortionButton(
              'Bastante',
              PortionSize.large,
              detection,
              portion.sizeCategory == PortionSize.large,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPortionButton(
    String label,
    PortionSize size,
    FoodDetection detection,
    bool isSelected,
  ) {
    return Expanded(
      child: OutlinedButton(
        onPressed: () => _updatePortion(detection, size),
        style: OutlinedButton.styleFrom(
          backgroundColor: isSelected
              ? AppTheme.accent.withValues(alpha: 0.1)
              : Colors.transparent,
          side: BorderSide(
            color: isSelected ? AppTheme.accent : AppTheme.textSecondary,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
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
            const Icon(
              Icons.error_outline,
              color: AppTheme.danger,
              size: 64,
            ),
            const SizedBox(height: 24),
            Text(
              _error ?? 'Erro desconhecido',
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _imageFile = null;
                    _error = null;
                  });
                },
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
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image == null) return;
      
      setState(() {
        _imageFile = File(image.path);
        _isAnalyzing = true;
        _error = null;
      });
      
      await _analyzeImage();
    } catch (e) {
      setState(() {
        _error = 'Erro ao capturar imagem: $e';
      });
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

  void _handleDetectionAction(String action, FoodDetection detection) {
    switch (action) {
      case 'edit':
        _editDetection(detection);
        break;
      case 'remove':
        _removeDetection(detection);
        break;
    }
  }

  void _editDetection(FoodDetection detection) {
    // TODO: Abrir tela de edição
  }

  void _removeDetection(FoodDetection detection) {
    setState(() {
      _analysisResult = MealAnalysisResult(
        id: _analysisResult!.id,
        imagePath: _analysisResult!.imagePath,
        detections: _analysisResult!.detections
            .where((d) => d.id != detection.id)
            .toList(),
        analyzedAt: _analysisResult!.analyzedAt,
        visionModelVersion: _analysisResult!.visionModelVersion,
        overallConfidence: _analysisResult!.overallConfidence,
        requiresConfirmation: _analysisResult!.requiresConfirmation,
      );
    });
  }

  void _updatePortion(FoodDetection detection, PortionSize size) {
    // Atualizar porção do alimento
    final updatedDetection = detection.copyWith(
      portionEstimate: PortionEstimate(
        grams: PortionEstimationEngine.estimate(
          category: detection.category,
          sizeCategory: size,
        ).grams,
        sizeCategory: size,
        confidence: 0.8,
      ),
    );
    
    setState(() {
      final index = _analysisResult!.detections
          .indexWhere((d) => d.id == detection.id);
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
    // TODO: Confirmar todos os alimentos e salvar refeição
    Navigator.of(context).pop(_confirmedFoods);
  }

  void _addFoodManually() {
    // TODO: Abrir tela de busca manual
  }

  void _saveMeal() {
    // TODO: Salvar refeição confirmada
    Navigator.of(context).pop(_confirmedFoods);
  }
}

// ─────────────────────────────────────────────
// Modelo interno para alimento confirmado
// ─────────────────────────────────────────────

class _ConfirmedFood {
  final FoodDetection detection;
  final FoodModel? matchedFood;
  final double? portionGrams;

  const _ConfirmedFood({
    required this.detection,
    this.matchedFood,
    this.portionGrams,
  });
}
