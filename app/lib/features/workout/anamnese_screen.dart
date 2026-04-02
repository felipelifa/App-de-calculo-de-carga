import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../shared/theme/app_theme.dart';
import 'workout_profile_model.dart';
import 'workout_profile_provider.dart';
import '../exercises/exercise_provider.dart';

// ─────────────────────────────────────────────
// Tela de Anamnese (Fluxo de Montagem do Perfil)
// ─────────────────────────────────────────────

class AnamneseScreen extends StatefulWidget {
  const AnamneseScreen({super.key});

  @override
  State<AnamneseScreen> createState() => _AnamneseScreenState();
}

class _AnamneseScreenState extends State<AnamneseScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // -- Step 1: Personal --
  int age = 25;
  String sex = 'male';
  double weight = 70.0;
  double height = 175.0;

  // -- Step 2: Experience --
  String level = 'beginner';
  int trainingAge = 0;
  String bodyFat = 'medium';

  // -- Step 3: Goals --
  String goal = 'hypertrophy';
  String style = 'compound_focus';
  int days = 3;
  int duration = 60;

  // -- Step 4: Constraints --
  String env = 'full_gym';
  List<String> restrictions = [];
  List<String> equipment = [];

  void _next() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  void _back() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _finish() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final profile = WorkoutProfile(
      uid: uid,
      age: age,
      biologicalSex: sex,
      weightKg: weight,
      heightCm: height,
      bodyFatCategory: bodyFat,
      primaryGoal: goal,
      experienceLevel: level,
      trainingAge: trainingAge,
      availableDaysPerWeek: days,
      sessionDurationMinutes: duration,
      environment: env,
      availableEquipment: equipment,
      healthRestrictions: restrictions,
      dislikedExercises: [],
      preferredStyle: style,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      _showLoadingDialog(context);
      
      final profileProvider = context.read<WorkoutProfileProvider>();
      final exerciseProvider = context.read<ExerciseProvider>();

      await profileProvider.saveProfile(profile);
      await profileProvider.generateAndSaveWorkout(exerciseProvider.filteredExercises);
      
      if (mounted) {
        Navigator.pop(context); // Close loading
        context.go('/prescribed');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e')),
        );
      }
    }
  }

  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppTheme.accent),
            const SizedBox(height: 20),
            const Text(
              'Gerando seu Mesociclo Científico...',
              style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Aguarde enquanto calculamos volumes e intensidades ideais.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (v) => setState(() => _currentPage = v),
                children: [
                  _StepPersonal(onAge: (v) => age = v, onSex: (v) => sex = v, onWeight: (v) => weight = v, onHeight: (v) => height = v),
                  _StepExperience(onLevel: (v) => level = v, onTrainingAge: (v) => trainingAge = v, onBodyFat: (v) => bodyFat = v),
                  _StepGoals(
                    onGoal: (v) => goal = v,
                    onStyle: (v) => style = v,
                    onDays: (v) => days = v,
                    onDuration: (v) => duration = v,
                  ),
                  _StepConstraints(onEnv: (v) => env = v, onRestrictions: (v) => restrictions = v),
                ],
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Passo ${_currentPage + 1} de 4',
                style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold),
              ),
              IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => context.go('/dashboard')),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (_currentPage + 1) / 4,
            backgroundColor: AppTheme.surfaceHighlight.withValues(alpha: 0.1),
            color: AppTheme.accent,
            borderRadius: BorderRadius.circular(10),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          if (_currentPage > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _back,
                child: const Text('Voltar'),
              ),
            ),
          if (_currentPage > 0) const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _next,
              child: Text(_currentPage == 3 ? 'FINALIZAR' : 'PRÓXIMO'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Sub-telas dos passos
// ─────────────────────────────────────────────

class _StepPersonal extends StatelessWidget {
  final ValueChanged<int> onAge;
  final ValueChanged<String> onSex;
  final ValueChanged<double> onWeight;
  final ValueChanged<double> onHeight;

  const _StepPersonal({required this.onAge, required this.onSex, required this.onWeight, required this.onHeight});

  @override
  Widget build(BuildContext context) {
    return _BaseStep(
      title: 'Conte um pouco sobre você',
      subtitle: 'Precisamos de dados básicos para calcular seus volumes ideais.',
      children: [
        _InputLabel('Qual sua idade?'),
        _Slider(min: 14, max: 80, initial: 25, unit: 'anos', onChanged: (v) => onAge(v.toInt())),
        const SizedBox(height: 24),
        _InputLabel('Sexo biológico'),
        _ChoiceGroup(
          choices: {'male': 'Masculino', 'female': 'Feminino'},
          initial: 'male',
          onChanged: onSex,
        ),
        const SizedBox(height: 24),
        _InputLabel('Peso atual (kg)'),
        _Slider(min: 40, max: 150, initial: 70, unit: 'kg', onChanged: onWeight),
        const SizedBox(height: 24),
        _InputLabel('Sua altura (cm)'),
        _Slider(min: 120, max: 220, initial: 175, unit: 'cm', onChanged: onHeight),
      ],
    );
  }
}

class _StepExperience extends StatelessWidget {
  final ValueChanged<String> onLevel;
  final ValueChanged<int> onTrainingAge;
  final ValueChanged<String> onBodyFat;

  const _StepExperience({required this.onLevel, required this.onTrainingAge, required this.onBodyFat});

  @override
  Widget build(BuildContext context) {
    return _BaseStep(
      title: 'Qual sua experiência no treino?',
      subtitle: 'Iniciantes progridem diferente de avançados.',
      children: [
        _InputLabel('Nível de experiência'),
        _ChoiceGroup(
          choices: {
            'beginner': 'Iniciante (0-12 meses)',
            'intermediate': 'Intermediário (1-3 anos)',
            'advanced': 'Avançado (+3 anos)'
          },
          initial: 'beginner',
          onChanged: onLevel,
        ),
        const SizedBox(height: 24),
        _InputLabel('Tempo total de treino (meses)'),
        _Slider(min: 0, max: 120, initial: 0, unit: 'meses', onChanged: (v) => onTrainingAge(v.toInt())),
        const SizedBox(height: 24),
        _InputLabel('Percentual de gordura (estimado)'),
        _ChoiceGroup(
          choices: {'low': 'Baixo', 'medium': 'Médio', 'high': 'Alto'},
          initial: 'medium',
          onChanged: onBodyFat,
        ),
      ],
    );
  }
}

class _StepGoals extends StatelessWidget {
  final ValueChanged<String> onGoal;
  final ValueChanged<String> onStyle;
  final ValueChanged<int> onDays;
  final ValueChanged<int> onDuration;

  const _StepGoals({
    required this.onGoal,
    required this.onStyle,
    required this.onDays,
    required this.onDuration,
  });

  @override
  Widget build(BuildContext context) {
    return _BaseStep(
      title: 'O que você quer alcançar?',
      subtitle: 'Seu treino será construído com base no seu objetivo.',
      children: [
        _InputLabel('Objetivo principal'),
        _ChoiceGroup(
          choices: {
            'hypertrophy': 'Hipertrofia',
            'fat_loss': 'Queima de gordura',
            'strength': 'Força bruta',
            'general_health': 'Saúde e longevidade'
          },
          initial: 'hypertrophy',
          onChanged: onGoal,
        ),
        const SizedBox(height: 24),
        _InputLabel('Dias disponíveis por semana'),
        _Slider(min: 2, max: 7, initial: 3, unit: 'dias', onChanged: (v) => onDays(v.toInt())),
        const SizedBox(height: 24),
        _InputLabel('Duração ideal da sessão'),
        _ChoiceGroup(
          choices: {'30': '30 min', '45': '45 min', '60': '1 hora', '90': '1.5 horas'},
          initial: '60',
          onChanged: (v) => onDuration(int.parse(v)),
        ),
      ],
    );
  }
}

class _StepConstraints extends StatelessWidget {
  final ValueChanged<String> onEnv;
  final ValueChanged<List<String>> onRestrictions;

  const _StepConstraints({required this.onEnv, required this.onRestrictions});

  @override
  Widget build(BuildContext context) {
    return _BaseStep(
      title: 'Ambiente e Restrições',
      subtitle: 'Garantimos que o treino seja seguro e viável.',
      children: [
        _InputLabel('Onde você treina?'),
        _ChoiceGroup(
          choices: {
            'full_gym': 'Academia Completa',
            'basic_gym': 'Academia Básica (Prédio)',
            'home_bodyweight': 'Em Casa (Peso do corpo)'
          },
          initial: 'full_gym',
          onChanged: onEnv,
        ),
        const SizedBox(height: 24),
        _InputLabel('Alguma restrição ou dor? (Selecione)'),
        // Simplesmente uma lista por enquanto para agilizar
        _MultiChoiceGroup(
          choices: {
            'knee': 'Joelho (LCA/Menisco)',
            'lower_back': 'Lombar (Hérnia/Dor)',
            'shoulder': 'Ombro (Manguito)',
            'elbow': 'Cotovelo (Epicondilite)',
            'wrist': 'Punho (Instabilidade)',
            'hypertension': 'Hipertensão',
            'post_surgery': 'Pós-cirurgia (Recuperação)'
          },
          onChanged: onRestrictions,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// UI Components
// ─────────────────────────────────────────────

class _BaseStep extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;

  const _BaseStep({required this.title, required this.subtitle, required this.children});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
        const SizedBox(height: 32),
        ...children,
      ],
    );
  }
}

class _InputLabel extends StatelessWidget {
  final String label;
  const _InputLabel(this.label);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(label, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
  );
}

class _Slider extends StatefulWidget {
  final double min, max, initial;
  final String unit;
  final ValueChanged<double> onChanged;

  const _Slider({required this.min, required this.max, required this.initial, required this.unit, required this.onChanged});

  @override
  State<_Slider> createState() => _SliderState();
}

class _SliderState extends State<_Slider> {
  late double _val;
  @override
  void initState() { super.initState(); _val = widget.initial; }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Slider(
          value: _val,
          min: widget.min,
          max: widget.max,
          onChanged: (v) { setState(() => _val = v); widget.onChanged(v); },
          activeColor: AppTheme.accent,
        ),
        Text('${_val.toInt()} ${widget.unit}', style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _ChoiceGroup extends StatefulWidget {
  final Map<String, String> choices;
  final String initial;
  final ValueChanged<String> onChanged;

  const _ChoiceGroup({required this.choices, required this.initial, required this.onChanged});

  @override
  State<_ChoiceGroup> createState() => _ChoiceGroupState();
}

class _ChoiceGroupState extends State<_ChoiceGroup> {
  late String _val;
  @override
  void initState() { super.initState(); _val = widget.initial; }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: widget.choices.entries.map((e) {
        final selected = _val == e.key;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () { setState(() => _val = e.key); widget.onChanged(e.key); },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: selected ? AppTheme.accent.withValues(alpha: 0.1) : AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: selected ? AppTheme.accent : Colors.white12),
              ),
              child: Row(
                children: [
                  Expanded(child: Text(e.value, style: TextStyle(color: selected ? AppTheme.accent : AppTheme.textPrimary))),
                  if (selected) const Icon(Icons.check_circle_rounded, color: AppTheme.accent),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _MultiChoiceGroup extends StatefulWidget {
  final Map<String, String> choices;
  final ValueChanged<List<String>> onChanged;

  const _MultiChoiceGroup({required this.choices, required this.onChanged});

  @override
  State<_MultiChoiceGroup> createState() => _MultiChoiceGroupState();
}

class _MultiChoiceGroupState extends State<_MultiChoiceGroup> {
  final List<String> _selected = [];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: widget.choices.entries.map((e) {
        final selected = _selected.contains(e.key);
        return FilterChip(
          label: Text(e.value),
          selected: selected,
          onSelected: (v) {
            setState(() {
              if (v) _selected.add(e.key); else _selected.remove(e.key);
            });
            widget.onChanged(_selected);
          },
        );
      }).toList(),
    );
  }
}
