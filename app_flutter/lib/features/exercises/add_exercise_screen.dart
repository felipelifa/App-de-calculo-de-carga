import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../shared/theme/app_theme.dart';
import 'exercise_provider.dart';
import 'exercise_card.dart';

const List<String> _muscleGroups = [
  'Peito',
  'Costas',
  'Ombro',
  'Bíceps',
  'Tríceps',
  'Quadríceps',
  'Posterior',
  'Glúteo',
  'Core',
  'Panturrilha',
];

const List<String> _equipments = [
  'Barra',
  'Halteres',
  'Máquina',
  'Cabo',
  'Polia',
  'Barra Fixa',
  'Peso Corporal',
  'Kettlebell',
  'Elástico',
  'Smith',
  'Outros',
];

class AddExerciseScreen extends StatefulWidget {
  const AddExerciseScreen({super.key});

  @override
  State<AddExerciseScreen> createState() => _AddExerciseScreenState();
}

class _AddExerciseScreenState extends State<AddExerciseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _gifUrlCtrl = TextEditingController();
  final _seriesCtrl = TextEditingController(text: '3');
  final _repMinCtrl = TextEditingController(text: '8');
  final _repMaxCtrl = TextEditingController(text: '12');

  String? _selectedMuscle;
  String? _selectedEquipment;
  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _gifUrlCtrl.dispose();
    _seriesCtrl.dispose();
    _repMinCtrl.dispose();
    _repMaxCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final provider = context.read<ExerciseProvider>();
      await provider.addExercise(
        name: _nameCtrl.text.trim(),
        muscleGroup: _selectedMuscle!,
        equipment: _selectedEquipment!,
        seriesDefault: int.parse(_seriesCtrl.text.trim()),
        repMin: int.parse(_repMinCtrl.text.trim()),
        repMax: int.parse(_repMaxCtrl.text.trim()),
        gifUrl: _gifUrlCtrl.text.trim().isEmpty ? null : _gifUrlCtrl.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_nameCtrl.text.trim()} adicionado!'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Erro ao salvar: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: const Text(
          'Novo Exercício',
          style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppTheme.textPrimary),
          onPressed: () => context.pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Error banner ─────────────────────
              if (_error != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.danger.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: AppTheme.danger, fontSize: 13),
                  ),
                ),

              // ── Name ─────────────────────────────
              _sectionLabel('Nome do exercício *'),
              TextFormField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Ex: Supino Reto',
                  prefixIcon: Icon(Icons.edit_rounded, color: AppTheme.textSecondary),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Nome obrigatório' : null,
              ),

              const SizedBox(height: 20),

              // ── Muscle Group ─────────────────────
              _sectionLabel('Grupo muscular *'),
              DropdownButtonFormField<String>(
                initialValue: _selectedMuscle,
                dropdownColor: AppTheme.surface,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  prefixIcon:
                      Icon(Icons.sports_gymnastics_rounded, color: AppTheme.textSecondary),
                ),
                hint: const Text(
                  'Selecionar grupo',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
                items: _muscleGroups.map((g) {
                  final color = muscleColor(g);
                  return DropdownMenuItem(
                    value: g,
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Text(g),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (v) {
                  setState(() {
                    _selectedMuscle = v;
                  });
                },
                validator: (v) =>
                    v == null ? 'Selecione um grupo muscular' : null,
              ),

              const SizedBox(height: 20),

              // ── Equipment ────────────────────────
              _sectionLabel('Equipamento *'),
              DropdownButtonFormField<String>(
                initialValue: _selectedEquipment,
                dropdownColor: AppTheme.surface,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  prefixIcon:
                      Icon(Icons.hardware_rounded, color: AppTheme.textSecondary),
                ),
                hint: const Text(
                  'Selecionar equipamento',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
                items: _equipments
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) {
                  setState(() {
                    _selectedEquipment = v;
                  });
                },
                validator: (v) =>
                    v == null ? 'Selecione um equipamento' : null,
              ),

              const SizedBox(height: 24),
              _sectionLabel('Configurações de volume'),
              const SizedBox(height: 14),

              // ── Series / Reps row ─────────────────
              Row(
                children: [
                  Expanded(
                    child: _NumericField(
                      label: 'Séries',
                      controller: _seriesCtrl,
                      min: 1,
                      max: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _NumericField(
                      label: 'Rep mín.',
                      controller: _repMinCtrl,
                      min: 1,
                      max: 30,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _NumericField(
                      label: 'Rep máx.',
                      controller: _repMaxCtrl,
                      min: 1,
                      max: 30,
                      extraValidator: (_) {
                        final min = int.tryParse(_repMinCtrl.text) ?? 0;
                        final max = int.tryParse(_repMaxCtrl.text) ?? 0;
                        if (max < min) return 'Máx < mín';
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── GIF URL (optional) ────────────────
              _sectionLabel('URL do GIF (opcional)'),
              TextFormField(
                controller: _gifUrlCtrl,
                keyboardType: TextInputType.url,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'https://…gif',
                  prefixIcon:
                      Icon(Icons.gif_box_rounded, color: AppTheme.textSecondary),
                ),
              ),

              const SizedBox(height: 32),

              // ── Submit ───────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _submit,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check_rounded),
                  label: const Text('Criar exercício'),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Numeric field with built-in range validator
// ─────────────────────────────────────────────

class _NumericField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final int min;
  final int max;
  final String? Function(String?)? extraValidator;

  const _NumericField({
    required this.label,
    required this.controller,
    required this.min,
    required this.max,
    this.extraValidator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: AppTheme.textPrimary,
        fontWeight: FontWeight.bold,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
      ),
      validator: (v) {
        final n = int.tryParse(v ?? '');
        if (n == null) return 'Inválido';
        if (n < min || n > max) return '$min–$max';
        return extraValidator?.call(v);
      },
    );
  }
}
