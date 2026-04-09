import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../shared/theme/app_theme.dart';
import 'workout_profile_model.dart';
import 'workout_profile_provider.dart';
import '../exercises/exercise_provider.dart';

// ─────────────────────────────────────────────
// Tela de Anamnese — 5 passos
// ─────────────────────────────────────────────

class AnamneseScreen extends StatefulWidget {
  const AnamneseScreen({super.key});

  @override
  State<AnamneseScreen> createState() => _AnamneseScreenState();
}

class _AnamneseScreenState extends State<AnamneseScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Passo 1: Pessoal
  int age = 25;
  String sex = 'male';
  double weight = 70.0;
  double height = 175.0;

  // Passo 2: Experiência
  String level = 'beginner';
  int trainingAge = 0;
  String bodyFat = 'medium';

  // Passo 3: Metas + Estilo
  String goal = 'hypertrophy';
  String style = 'compound_focus';
  int days = 3;
  int duration = 60;

  // Passo 4: Recuperação + Prioridades
  String sleepQuality = 'regular';
  String stressLevel = 'medium';
  final List<String> priorityMuscles = [];

  // Passo 5: Preferências + Restrições
  String env = 'full_gym';
  final List<String> availableEquipment = [];
  final List<String> dislikedExercises = [];
  final List<String> favoriteExercises = [];
  final List<String> restrictions = [];

  void _next() {
    if (_currentPage < 4) {
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
      preferredStyle: style,
      sleepQuality: sleepQuality,
      stressLevel: stressLevel,
      priorityMuscles: List.from(priorityMuscles),
      environment: env,
      availableEquipment: List.from(availableEquipment),
      dislikedExercises: List.from(dislikedExercises),
      favoriteExercises: List.from(favoriteExercises),
      healthRestrictions: List.from(restrictions),
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
        Navigator.pop(context);
        context.go('/prescribed');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
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
                  _StepGoals(onGoal: (v) => goal = v, onStyle: (v) => style = v, onDays: (v) => days = v, onDuration: (v) => duration = v),
                  _StepRecovery(onSleep: (v) => sleepQuality = v, onStress: (v) => stressLevel = v, onPriorities: (v) { priorityMuscles.clear(); priorityMuscles.addAll(v); }),
                  _StepPreferences(
                    onEnv: (v) => env = v,
                    onEquipment: (v) { availableEquipment.clear(); availableEquipment.addAll(v); },
                    onDisliked: (v) { dislikedExercises.clear(); dislikedExercises.addAll(v); },
                    onFavorite: (v) { favoriteExercises.clear(); favoriteExercises.addAll(v); },
                    onRestrictions: (v) { restrictions.clear(); restrictions.addAll(v); },
                  ),
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
                'Passo ${_currentPage + 1} de 5',
                style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold),
              ),
              IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => context.go('/dashboard')),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (_currentPage + 1) / 5,
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
              child: Text(_currentPage == 4 ? 'GERAR TREINO' : 'PRÓXIMO'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Passo 1: Pessoal
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
      title: 'Sobre você',
      subtitle: 'Dados básicos para calcular volumes ideais.',
      children: [
        _InputLabel('Qual a sua idade?'),
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

// ─────────────────────────────────────────────
// Passo 2: Experiência
// ─────────────────────────────────────────────

class _StepExperience extends StatelessWidget {
  final ValueChanged<String> onLevel;
  final ValueChanged<int> onTrainingAge;
  final ValueChanged<String> onBodyFat;

  const _StepExperience({required this.onLevel, required this.onTrainingAge, required this.onBodyFat});

  @override
  Widget build(BuildContext context) {
    return _BaseStep(
      title: 'Experiência de treino',
      subtitle: 'Iniciantes progridem diferente de avançados.',
      children: [
        _InputLabel('Nível de experiência'),
        _ChoiceGroup(
          choices: {
            'beginner': 'Iniciante (0–12 meses)',
            'intermediate': 'Intermediário (1–3 anos)',
            'advanced': 'Avançado (+3 anos)',
          },
          initial: 'beginner',
          onChanged: onLevel,
        ),
        const SizedBox(height: 24),
        _InputLabel('Tempo total de treino (meses)'),
        _Slider(min: 0, max: 120, initial: 0, unit: 'meses', stepped: true, onChanged: (v) => onTrainingAge(v.toInt())),
        const SizedBox(height: 24),
        _InputLabel('Percentual de gordura (estimado)'),
        _ChoiceGroup(
          choices: {'low': 'Baixo (< 15%)', 'medium': 'Médio (15–25%)', 'high': 'Alto (> 25%)'},
          initial: 'medium',
          onChanged: onBodyFat,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Passo 3: Metas + Estilo
// ─────────────────────────────────────────────

class _StepGoals extends StatelessWidget {
  final ValueChanged<String> onGoal;
  final ValueChanged<String> onStyle;
  final ValueChanged<int> onDays;
  final ValueChanged<int> onDuration;

  const _StepGoals({required this.onGoal, required this.onStyle, required this.onDays, required this.onDuration});

  @override
  Widget build(BuildContext context) {
    return _BaseStep(
      title: 'Objetivo e disponibilidade',
      subtitle: 'Seu treino será construído com base no seu objetivo.',
      children: [
        _InputLabel('Objetivo principal'),
        _ChoiceGroup(
          choices: {
            'hypertrophy': 'Hipertrofia Estética',
            'strength': 'Força Máxima (Powerlifting)',
            'combat_sports': 'Lutas e Artes Marciais',
            'power_explosive': 'Potência e Explosão',
            'running_hybrid': 'Performance em Corrida / Híbrido',
            'fat_loss': 'Emagrecimento / Definição',
            'athletic_agility': 'Agilidade e Coordenação',
            'general_health': 'Saúde e Longevidade',
          },
          initial: 'hypertrophy',
          onChanged: onGoal,
        ),
        const SizedBox(height: 24),
        _InputLabel('Dias disponíveis por semana'),
        _Slider(min: 1, max: 6, initial: 3, unit: 'dias', stepped: true, onChanged: (v) => onDays(v.toInt())),
        const SizedBox(height: 24),
        _InputLabel('Duração ideal da sessão'),
        _ChoiceGroup(
          choices: {'30': '30 min', '45': '45 min', '60': '1 hora', '75': '1h15', '90': '1h30'},
          initial: '60',
          onChanged: (v) => onDuration(int.parse(v)),
        ),
        const SizedBox(height: 24),
        _InputLabel('Estilo de treino preferido'),
        _ChoiceGroup(
          choices: {
            'compound_focus': 'Multiarticulares (base)',
            'isolation_focus': 'Isoladores (detalhe)',
            'moderate_volume': 'Volume moderado',
            'circuit': 'Circuito (intenso)',
          },
          initial: 'compound_focus',
          onChanged: onStyle,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Passo 4: Recuperação + Prioridades
// ─────────────────────────────────────────────

class _StepRecovery extends StatelessWidget {
  final ValueChanged<String> onSleep;
  final ValueChanged<String> onStress;
  final ValueChanged<List<String>> onPriorities;

  const _StepRecovery({required this.onSleep, required this.onStress, required this.onPriorities});

  @override
  Widget build(BuildContext context) {
    return _BaseStep(
      title: 'Recuperação e prioridades',
      subtitle: 'Sono e estresse afetam diretamente sua capacidade de recuperação.',
      children: [
        _InputLabel('Como é seu sono em geral?'),
        _ChoiceGroup(
          choices: {
            'good': 'Bom (7–9h por noite)',
            'regular': 'Regular (5–7h)',
            'poor': 'Ruim (< 5h ou fragmentado)',
          },
          initial: 'regular',
          onChanged: onSleep,
        ),
        const SizedBox(height: 24),
        _InputLabel('Nível de estresse diário'),
        _ChoiceGroup(
          choices: {
            'low': 'Baixo',
            'medium': 'Moderado',
            'high': 'Alto',
          },
          initial: 'medium',
          onChanged: onStress,
        ),
        const SizedBox(height: 24),
        _InputLabel('Grupos musculares que quer priorizar?'),
        Text(
          'O volume desses músculos será aumentado no plano.',
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 12),
        _MultiChoiceGroup(
          choices: {
            'chest': 'Peito',
            'back': 'Costas',
            'shoulders': 'Ombros',
            'biceps': 'Bíceps',
            'triceps': 'Tríceps',
            'side_delt': 'Deltóide Lateral',
            'rear_delt': 'Deltóide Posterior',
            'quads': 'Quadríceps',
            'hamstrings': 'Posterior de coxa',
            'glutes': 'Glúteos',
            'calves': 'Panturrilhas',
            'abs': 'Abdômen',
          },
          onChanged: onPriorities,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Passo 5: Preferências + Restrições
// ─────────────────────────────────────────────

class _StepPreferences extends StatefulWidget {
  final ValueChanged<String> onEnv;
  final ValueChanged<List<String>> onEquipment;
  final ValueChanged<List<String>> onDisliked;
  final ValueChanged<List<String>> onFavorite;
  final ValueChanged<List<String>> onRestrictions;

  const _StepPreferences({
    required this.onEnv,
    required this.onEquipment,
    required this.onDisliked,
    required this.onFavorite,
    required this.onRestrictions,
  });

  @override
  State<_StepPreferences> createState() => _StepPreferencesState();
}

class _StepPreferencesState extends State<_StepPreferences> {
  String _env = 'full_gym';
  final List<String> _equipment = [];
  final List<String> _disliked = [];
  final List<String> _favorite = [];
  final List<String> _restrictions = [];

  void _emit() {
    widget.onEnv(_env);
    widget.onEquipment(_equipment);
    widget.onDisliked(_disliked);
    widget.onFavorite(_favorite);
    widget.onRestrictions(_restrictions);
  }

  @override
  Widget build(BuildContext context) {
    return _BaseStep(
      title: 'Preferências e segurança',
      subtitle: 'Garantimos que o treino seja seguro e aderente.',
      children: [
        _InputLabel('Onde você treina?'),
        _ChoiceGroup(
          choices: {
            'full_gym': 'Academia completa',
            'basic_gym': 'Academia básica',
            'home_dumbbell': 'Em casa (com halteres)',
            'home_bodyweight': 'Em casa (peso do corpo)',
            'outdoor': 'Ao ar livre',
          },
          initial: 'full_gym',
          onChanged: (v) => setState(() { _env = v; _emit(); }),
        ),
        const SizedBox(height: 24),
        _InputLabel('Equipamentos disponíveis?'),
        Text('(Selecione os que tem acesso)', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        const SizedBox(height: 8),
        _MultiChoiceGroup(
          choices: {
            'barbell': 'Barra longa',
            'dumbbells': 'Halteres',
            'cables': 'Cabos/Polia',
            'machines': 'Máquinas',
            'smith': 'Smith Machine',
            'pullup_bar': 'Barra fixa',
            'dip_station': 'Paralelas',
            'bands': 'Elásticos/Bands',
            'kettlebell': 'Kettlebell',
            'trx': 'TRX/Suspension',
          },
          onChanged: (v) { _equipment.clear(); _equipment.addAll(v); _emit(); },
        ),
        const SizedBox(height: 24),
        _InputLabel('Exercícios que você GOSTA?'),
        Text('(Serão priorizados no plano)', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        const SizedBox(height: 8),
        _ExercisePicker(
          selected: _favorite,
          title: 'Preferidos',
          onChanged: (v) { _favorite.clear(); _favorite.addAll(v); _emit(); },
        ),
        const SizedBox(height: 24),
        _InputLabel('Exercícios que você NÃO GOSTA?'),
        Text('(Serão removidos da biblioteca)', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        const SizedBox(height: 8),
        _ExercisePicker(
          selected: _disliked,
          title: 'Evitar',
          onChanged: (v) { _disliked.clear(); _disliked.addAll(v); _emit(); },
        ),
        const SizedBox(height: 24),
        _InputLabel('Alguma restrição ou lesão?'),
        _MultiChoiceGroup(
          choices: {
            'knee': 'Joelho',
            'lower_back': 'Lombar',
            'shoulder': 'Ombro',
            'elbow': 'Cotovelo',
            'wrist': 'Punho',
            'hip': 'Quadril',
            'hypertension': 'Hipertensão',
            'hernia': 'Hérnia',
            'post_surgery': 'Pós-cirurgia',
          },
          onChanged: (v) { _restrictions.clear(); _restrictions.addAll(v); _emit(); },
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Exercício Picker (lista expandida com busca)
// ─────────────────────────────────────────────

class _ExercisePicker extends StatefulWidget {
  final List<String> selected;
  final String title;
  final ValueChanged<List<String>> onChanged;

  const _ExercisePicker({required this.selected, required this.title, required this.onChanged});

  @override
  State<_ExercisePicker> createState() => _ExercisePickerState();
}

class _ExercisePickerState extends State<_ExercisePicker> {
  final TextEditingController _search = TextEditingController();
  bool _open = false;

  // Lista consolidada de exercícios comuns
  static const Map<String, String> _exercises = {
    'supino_reto_barra': 'Supino Reto Barra',
    'supino_inclinado_halteres': 'Supino Inclinado Halteres',
    'supino_declinado': 'Supino Declinado',
    'crucifixo_halteres': 'Crucifixo Halteres',
    'crossover': 'Crossover Cabos',
    'peck_deck': 'Peck Deck / Voador',
    'flexao_aps': 'Flexão de Braços',
    'terra_convensonal': 'Levantamento Terra',
    'remada_curvada': 'Remada Curvada',
    'remada_cavaleiro': 'Remada Cavaleiro',
    'puxada_frente': 'Puxada Frente',
    'remada_baixa': 'Remada Baixa',
    'barra_fixa': 'Barra Fixa',
    'pullover': 'Pullover',
    'desenvolvimento_halteres': 'Desenvolvimento Halteres',
    'desenvolvimento_barra': 'Desenvolvimento Barra',
    'elevacao_lateral': 'Elevação Lateral',
    'face_pull': 'Face Pull',
    'y_raise_trap3': 'Y-Raise (Trap 3)',
    'rotacao_externa_elastico': 'Rotação Externa Elástico',
    'band_pull_apart': 'Band Pull Apart',
    'agachamento_livre': 'Agachamento Livre',
    'agachamento_smith': 'Agachamento Smith',
    'agachamento_bulgaro': 'Agachamento Búlgaro',
    'leg_press': 'Leg Press',
    'extensora': 'Extensão de Pernas',
    'flexora': 'Flexão de Pernas',
    'stiff': 'Stiff',
    'elevacao_pelvica': 'Elevação Pélvica',
    'panturrilha_em_pe': 'Panturrilha em Pé',
    'panturrilha_sentado': 'Panturrilha Sentado',
    'rosca_direta': 'Rosca Direta',
    'rosca_martelo': 'Rosca Martelo',
    'rosca_scott': 'Rosca Scott',
    'rosca_polia': 'Rosca na Polia',
    'triceps_corda': 'Tríceps Corda',
    'triceps_testa': 'Tríceps Testa',
    'triceps_frances': 'Tríceps Francês',
    'mergulho': 'Mergulho (Paralelas)',
    'abd_sup': 'Abdominal Supra',
    'prancha': 'Prancha Isométrica',
    'paloff_press': 'Pallof Press',
  };

  List<String> get _filtered {
    final q = _search.text.toLowerCase();
    return _exercises.entries
        .where((e) => e.value.toLowerCase().contains(q))
        .map((e) => e.key)
        .toList();
  }

  void _toggle(String id) {
    setState(() {
      if (widget.selected.contains(id)) {
        widget.selected.remove(id);
      } else {
        widget.selected.add(id);
      }
      widget.onChanged(List.from(widget.selected));
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _search,
                decoration: InputDecoration(
                  hintText: 'Buscar exercício...',
                  hintStyle: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                style: const TextStyle(fontSize: 13),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 8),
            if (!_open)
              TextButton(
                onPressed: () => setState(() => _open = true),
                child: const Text('Selecionar', style: TextStyle(color: AppTheme.accent)),
              )
            else
              TextButton(
                onPressed: () => setState(() => _open = false),
                child: const Text('Fechar', style: TextStyle(color: AppTheme.accent)),
              ),
          ],
        ),
        if (widget.selected.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: widget.selected.map((id) {
                final name = _exercises[id] ?? id;
                return InputChip(
                  label: Text(name, style: const TextStyle(fontSize: 11)),
                  deleteIcon: const Icon(Icons.close_rounded, size: 16),
                  onDeleted: () => _toggle(id),
                  selected: true,
                  selectedColor: AppTheme.accent.withValues(alpha: 0.15),
                  side: const BorderSide(color: AppTheme.accent),
                );
              }).toList(),
            ),
          ),
        if (_open)
          Container(
            constraints: const BoxConstraints(maxHeight: 250),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white12),
            ),
            margin: const EdgeInsets.only(top: 8),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: items.length,
              itemBuilder: (context, i) {
                final id = items[i];
                final name = _exercises[id]!;
                final selected = widget.selected.contains(id);
                return ListTile(
                  dense: true,
                  leading: Icon(Icons.fitness_center_rounded, size: 18, color: selected ? AppTheme.accent : Colors.white38),
                  title: Text(name, style: TextStyle(color: selected ? AppTheme.accent : AppTheme.textPrimary, fontSize: 13)),
                  trailing: Icon(selected ? Icons.check_circle_rounded : Icons.circle_outlined, size: 20, color: selected ? AppTheme.accent : Colors.white38),
                  onTap: () => _toggle(id),
                );
              },
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Componentes UI genéricos
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
  final bool stepped;

  const _Slider({required this.min, required this.max, required this.initial, required this.unit, required this.onChanged, this.stepped = false});

  @override
  State<_Slider> createState() => _SliderState();
}

class _SliderState extends State<_Slider> {
  late double _val;
  @override
  void initState() { super.initState(); _val = widget.initial; }

  @override
  Widget build(BuildContext context) {
    final displayed = widget.stepped ? _val.round() : _val.toInt();
    return Column(
      children: [
        Slider(
          value: _val,
          min: widget.min,
          max: widget.max,
          divisions: widget.stepped ? ((widget.max - widget.min).toInt()) : null,
          onChanged: (v) { setState(() => _val = v); widget.onChanged(v); },
          activeColor: AppTheme.accent,
        ),
        Text('$displayed ${widget.unit}', style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold)),
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
            widget.onChanged(List.from(_selected));
          },
        );
      }).toList(),
    );
  }
}
