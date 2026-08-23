import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../shared/theme/app_theme.dart';
import 'workout_profile_model.dart';
import 'workout_profile_provider.dart';

// ─────────────────────────────────────────────
// Onboarding Simplificado — 7 etapas
// Linguagem simples, sem termos técnicos
// ─────────────────────────────────────────────

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;

  // Etapa 1: Objetivo
  String? _goal;

  // Etapa 2: Modalidade
  String? _modality;

  // Etapa 3: Nível
  String? _level;

  // Etapa 4: Disponibilidade
  int _days = 3;

  // Etapa 5: Tempo
  int _duration = 60;

  // Etapa 6: Local/Equipamentos
  String? _environment;
  final List<String> _equipment = [];

  // Etapa 7: Restrições
  final List<String> _restrictions = [];

  // Dados pessoais (coletados automaticamente quando possível)
  int _age = 25;
  String _sex = 'male';
  double _weight = 70.0;
  double _height = 175.0;

  void _next() {
    if (_currentPage < 6) {
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

  bool _canProceed() {
    switch (_currentPage) {
      case 0: return _goal != null;
      case 1: return _modality != null;
      case 2: return _level != null;
      case 3: return true; // dias sempre tem valor padrão
      case 4: return true; // duração sempre tem valor padrão
      case 5: return _environment != null;
      case 6: return true; // restrições são opcionais
      default: return true;
    }
  }

  Future<void> _finish() async {
    setState(() => _isLoading = true);

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _isLoading = false);
      return;
    }

    // Mapear objetivo simples para objetivo técnico
    String technicalGoal = _mapGoalToTechnical(_goal);
    String technicalLevel = _mapLevelToTechnical(_level);
    String technicalModality = _mapModalityToTechnical(_modality);

    final profile = WorkoutProfile(
      uid: uid,
      age: _age,
      biologicalSex: _sex,
      weightKg: _weight,
      heightCm: _height,
      bodyFatCategory: 'medium', // padrão, não obrigatório
      primaryGoal: technicalGoal,
      sportSubType: 'none',
      trainingModality: technicalModality,
      experienceLevel: technicalLevel,
      trainingAge: _level == 'beginner' ? 0 : (_level == 'intermediate' ? 18 : 48),
      availableDaysPerWeek: _days,
      sessionDurationMinutes: _duration,
      preferredStyle: 'compound_focus',
      sleepQuality: 'regular',
      stressLevel: 'medium',
      priorityMuscles: [],
      environment: _environment ?? 'full_gym',
      availableEquipment: List.from(_equipment),
      dislikedExercises: [],
      favoriteExercises: [],
      healthRestrictions: List.from(_restrictions),
    );

    try {
      final provider = context.read<WorkoutProfileProvider>();
      await provider.saveProfile(profile);
      await provider.generateAndSaveWorkout(profile);

      if (mounted) {
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _mapGoalToTechnical(String? goal) {
    switch (goal) {
      case 'muscle': return 'hypertrophy';
      case 'fat_loss': return 'fat_loss';
      case 'strength': return 'strength';
      case 'health': return 'general_health';
      case 'conditioning': return 'endurance';
      default: return 'hypertrophy';
    }
  }

  String _mapLevelToTechnical(String? level) {
    switch (level) {
      case 'beginner': return 'beginner';
      case 'some_experience': return 'intermediate';
      case 'experienced': return 'advanced';
      default: return 'beginner';
    }
  }

  String _mapModalityToTechnical(String? modality) {
    switch (modality) {
      case 'gym': return 'traditional';
      case 'running': return 'none';
      case 'mobility': return 'mobility';
      case 'rehab': return 'rehab';
      case 'functional': return 'functional';
      case 'calisthenics': return 'calisthenics';
      case 'combat': return 'none';
      case 'cycling': return 'none';
      case 'swimming': return 'none';
      default: return 'traditional';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header com progresso
            _buildHeader(),

            // Conteúdo
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollScrollPhysics(),
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  _buildGoalStep(),
                  _buildModalityStep(),
                  _buildLevelStep(),
                  _buildDaysStep(),
                  _buildDurationStep(),
                  _buildEnvironmentStep(),
                  _buildRestrictionsStep(),
                ],
              ),
            ),

            // Footer com botões
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
        children: [
          // Barra de progresso
          Row(
            children: List.generate(7, (index) {
              return Expanded(
                child: Container(
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: index <= _currentPage
                        ? AppTheme.accent
                        : AppTheme.surfaceHighlight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          // Texto do passo
          Text(
            'Passo ${_currentPage + 1} de 7',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // ── ETAPA 1: OBJETIVO ──
  Widget _buildGoalStep() {
    return _buildStepContainer(
      title: 'O que você quer alcançar?',
      subtitle: 'Escolha o que mais importante para você',
      child: Column(
        children: [
          _buildOptionCard(
            icon: '💪',
            title: 'Ganhar músculo',
            value: 'muscle',
            groupValue: _goal,
            onChanged: (v) => setState(() => _goal = v),
          ),
          _buildOptionCard(
            icon: '🔥',
            title: 'Perder gordura',
            value: 'fat_loss',
            groupValue: _goal,
            onChanged: (v) => setState(() => _goal = v),
          ),
          _buildOptionCard(
            icon: '⚡',
            title: 'Ficar mais forte',
            value: 'strength',
            groupValue: _goal,
            onChanged: (v) => setState(() => _goal = v),
          ),
          _buildOptionCard(
            icon: '❤️',
            title: 'Melhorar minha saúde',
            value: 'health',
            groupValue: _goal,
            onChanged: (v) => setState(() => _goal = v),
          ),
          _buildOptionCard(
            icon: '🏃',
            title: 'Melhorar meu condicionamento',
            value: 'conditioning',
            groupValue: _goal,
            onChanged: (v) => setState(() => _goal = v),
          ),
          _buildOptionCard(
            icon: '❓',
            title: 'Não sei',
            value: 'unknown',
            groupValue: _goal,
            onChanged: (v) => setState(() => _goal = v),
          ),
        ],
      ),
    );
  }

  // ── ETAPA 2: MODALIDADE ──
  Widget _buildModalityStep() {
    return _buildStepContainer(
      title: 'Qual atividade você pratica?',
      subtitle: 'Escolha o tipo de exercício',
      child: Column(
        children: [
          _buildOptionCard(
            icon: '🏋️',
            title: 'Musculação',
            value: 'gym',
            groupValue: _modality,
            onChanged: (v) => setState(() => _modality = v),
          ),
          _buildOptionCard(
            icon: '🏃',
            title: 'Corrida',
            value: 'running',
            groupValue: _modality,
            onChanged: (v) => setState(() => _modality = v),
          ),
          _buildOptionCard(
            icon: '🧘',
            title: 'Mobilidade',
            value: 'mobility',
            groupValue: _modality,
            onChanged: (v) => setState(() => _modality = v),
          ),
          _buildOptionCard(
            icon: '🩹',
            title: 'Reabilitação',
            value: 'rehab',
            groupValue: _modality,
            onChanged: (v) => setState(() => _modality = v),
          ),
          _buildOptionCard(
            icon: '⚡',
            title: 'Funcional',
            value: 'functional',
            groupValue: _modality,
            onChanged: (v) => setState(() => _modality = v),
          ),
          _buildOptionCard(
            icon: '🤸',
            title: 'Calistenia',
            value: 'calisthenics',
            groupValue: _modality,
            onChanged: (v) => setState(() => _modality = v),
          ),
          _buildOptionCard(
            icon: '🥊',
            title: 'Lutas',
            value: 'combat',
            groupValue: _modality,
            onChanged: (v) => setState(() => _modality = v),
          ),
          _buildOptionCard(
            icon: '🚴',
            title: 'Ciclismo',
            value: 'cycling',
            groupValue: _modality,
            onChanged: (v) => setState(() => _modality = v),
          ),
          _buildOptionCard(
            icon: '🏊',
            title: 'Natação',
            value: 'swimming',
            groupValue: _modality,
            onChanged: (v) => setState(() => _modality = v),
          ),
        ],
      ),
    );
  }

  // ── ETAPA 3: NÍVEL ──
  Widget _buildLevelStep() {
    return _buildStepContainer(
      title: 'Como você se considera?',
      subtitle: 'Seja honesto, isso ajuda a montar seu treino',
      child: Column(
        children: [
          _buildOptionCard(
            icon: '🌱',
            title: 'Estou começando',
            subtitle: 'Nunca treinei ou treinei pouco',
            value: 'beginner',
            groupValue: _level,
            onChanged: (v) => setState(() => _level = v),
          ),
          _buildOptionCard(
            icon: '🌿',
            title: 'Já tenho alguma experiência',
            subtitle: 'Treino há alguns meses',
            value: 'some_experience',
            groupValue: _level,
            onChanged: (v) => setState(() => _level = v),
          ),
          _buildOptionCard(
            icon: '🌳',
            title: 'Tenho bastante experiência',
            subtitle: 'Treino há mais de 2 anos',
            value: 'experienced',
            groupValue: _level,
            onChanged: (v) => setState(() => _level = v),
          ),
          _buildOptionCard(
            icon: '❓',
            title: 'Não sei',
            value: 'unknown',
            groupValue: _level,
            onChanged: (v) => setState(() => _level = v),
          ),
        ],
      ),
    );
  }

  // ── ETAPA 4: DIAS ──
  Widget _buildDaysStep() {
    return _buildStepContainer(
      title: 'Quantos dias por semana você consegue treinar?',
      subtitle: 'Escolha o que você realmente consegue manter',
      child: Column(
        children: [
          _buildNumberSelector(
            value: _days,
            min: 2,
            max: 6,
            onChanged: (v) => setState(() => _days = v),
          ),
          const SizedBox(height: 16),
          const Text(
            'Não se preocupe em ser perfeito. O importante é começar!',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── ETAPA 5: DURAÇÃO ──
  Widget _buildDurationStep() {
    return _buildStepContainer(
      title: 'Quanto tempo você tem para treinar?',
      subtitle: 'Tempo normal de cada sessão',
      child: Column(
        children: [
          _buildOptionCard(
            icon: '⏱️',
            title: 'Até 30 minutos',
            value: 30,
            groupValue: _duration,
            onChanged: (v) => setState(() => _duration = v),
          ),
          _buildOptionCard(
            icon: '⏱️',
            title: '30–45 minutos',
            value: 45,
            groupValue: _duration,
            onChanged: (v) => setState(() => _duration = v),
          ),
          _buildOptionCard(
            icon: '⏱️',
            title: '45–60 minutos',
            value: 60,
            groupValue: _duration,
            onChanged: (v) => setState(() => _duration = v),
          ),
          _buildOptionCard(
            icon: '⏱️',
            title: '60–90 minutos',
            value: 75,
            groupValue: _duration,
            onChanged: (v) => setState(() => _duration = v),
          ),
          _buildOptionCard(
            icon: '⏱️',
            title: 'Mais de 90 minutos',
            value: 90,
            groupValue: _duration,
            onChanged: (v) => setState(() => _duration = v),
          ),
        ],
      ),
    );
  }

  // ── ETAPA 6: AMBIENTE ──
  Widget _buildEnvironmentStep() {
    return _buildStepContainer(
      title: 'Onde você treina?',
      subtitle: 'Isso ajuda a escolher os exercícios certos',
      child: Column(
        children: [
          _buildOptionCard(
            icon: '🏢',
            title: 'Academia',
            value: 'full_gym',
            groupValue: _environment,
            onChanged: (v) => setState(() => _environment = v),
          ),
          _buildOptionCard(
            icon: '🏠',
            title: 'Em casa',
            value: 'home',
            groupValue: _environment,
            onChanged: (v) => setState(() {
              _environment = v;
              _equipment.clear();
            }),
          ),
          _buildOptionCard(
            icon: '🌳',
            title: 'Ao ar livre',
            value: 'outdoor',
            groupValue: _environment,
            onChanged: (v) => setState(() {
              _environment = v;
              _equipment.clear();
            }),
          ),
          if (_environment == 'home') ...[
            const SizedBox(height: 16),
            const Text(
              'O que você tem em casa?',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _buildEquipmentChips(),
          ],
        ],
      ),
    );
  }

  Widget _buildEquipmentChips() {
    final equipmentOptions = [
      {'icon': '🏋️', 'label': 'Halteres', 'value': 'dumbbell'},
      {'icon': '🏋️', 'label': 'Barra', 'value': 'barbell'},
      {'icon': '🏋️', 'label': 'Banco', 'value': 'bench'},
      {'icon': '💪', 'label': 'Barra de pull-up', 'value': 'pull_up_bar'},
      {'icon': '🧘', 'label': 'Colchonete', 'value': 'mat'},
      {'icon': '⭕', 'label': 'Elásticos', 'value': 'bands'},
      {'icon': '🏋️', 'label': 'Kettlebell', 'value': 'kettlebell'},
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: equipmentOptions.map((eq) {
        final isSelected = _equipment.contains(eq['value']);
        return FilterChip(
          label: Text('${eq['icon']} ${eq['label']}'),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _equipment.add(eq['value'] as String);
              } else {
                _equipment.remove(eq['value']);
              }
            });
          },
          selectedColor: AppTheme.accent.withValues(alpha: 0.2),
          checkmarkColor: AppTheme.accent,
          labelStyle: TextStyle(
            color: isSelected ? AppTheme.accent : AppTheme.textPrimary,
          ),
          backgroundColor: AppTheme.surfaceHighlight,
          side: BorderSide(
            color: isSelected ? AppTheme.accent : Colors.transparent,
          ),
        );
      }).toList(),
    );
  }

  // ── ETAPA 7: RESTRIÇÕES ──
  Widget _buildRestrictionsStep() {
    return _buildStepContainer(
      title: 'Existe alguma coisa que devemos levar em consideração?',
      subtitle: 'Alguma dor, lesão ou limitação',
      child: Column(
        children: [
          _buildRestrictionChip('Nenhuma', 'none'),
          _buildRestrictionChip('Ombro', 'shoulder'),
          _buildRestrictionChip('Joelho', 'knee'),
          _buildRestrictionChip('Lombar', 'lower_back'),
          _buildRestrictionChip('Cotovelo', 'elbow'),
          _buildRestrictionChip('Punho', 'wrist'),
          _buildRestrictionChip('Quadril', 'hip'),
          _buildRestrictionChip('Tornozelo', 'ankle'),
          const SizedBox(height: 16),
          const Text(
            'Se tiver alguma limitação, o BuildFit vai adaptar seus exercícios automaticamente.',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRestrictionChip(String label, String value) {
    final isSelected = _restrictions.contains(value);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            if (value == 'none') {
              _restrictions.clear();
            } else {
              if (selected) {
                _restrictions.remove('none');
                _restrictions.add(value);
              } else {
                _restrictions.remove(value);
              }
            }
          });
        },
        selectedColor: AppTheme.danger.withValues(alpha: 0.2),
        checkmarkColor: AppTheme.danger,
        labelStyle: TextStyle(
          color: isSelected ? AppTheme.danger : AppTheme.textPrimary,
        ),
        backgroundColor: AppTheme.surfaceHighlight,
        side: BorderSide(
          color: isSelected ? AppTheme.danger : Colors.transparent,
        ),
      ),
    );
  }

  // ── COMPONENTES REUTILIZÁVEIS ──

  Widget _buildStepContainer({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 32),
          child,
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required String icon,
    required String title,
    String? subtitle,
    required dynamic value,
    required dynamic groupValue,
    required ValueChanged<dynamic> onChanged,
  }) {
    final isSelected = value == groupValue;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => onChanged(value),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.accent.withValues(alpha: 0.1)
                : AppTheme.surfaceHighlight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppTheme.accent : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isSelected ? AppTheme.accent : AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: AppTheme.accent,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumberSelector({
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: value > min ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove_circle_outline),
          color: AppTheme.accent,
          iconSize: 32,
        ),
        const SizedBox(width: 24),
        Column(
          children: [
            Text(
              '$value',
              style: const TextStyle(
                color: AppTheme.accent,
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'dias',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(width: 24),
        IconButton(
          onPressed: value < max ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add_circle_outline),
          color: AppTheme.accent,
          iconSize: 32,
        ),
      ],
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
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: AppTheme.textSecondary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Voltar',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
            ),
          if (_currentPage > 0) const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _canProceed() && !_isLoading ? _next : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent,
                foregroundColor: AppTheme.background,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.background,
                      ),
                    )
                  : Text(
                      _currentPage == 6 ? 'Começar!' : 'Próximo',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
