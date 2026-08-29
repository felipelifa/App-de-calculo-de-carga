import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../shared/theme/app_theme.dart';
import 'workout_profile_model.dart';
import 'workout_profile_provider.dart';
import 'training_readiness.dart';

// ─────────────────────────────────────────────
// Onboarding Simplificado — 9 etapas
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
  String? _sportSubtype;
  String _rehabTarget = 'rehab_general';

  // Etapa 3: Nível
  String? _level;
  int _trainingAge = 0;
  String _bodyFatCategory = 'medium';

  // Etapa 4: Disponibilidade
  int _days = 3;

  // Etapa 5: Tempo
  int _duration = 60;

  // Etapa 6: Local/Equipamentos
  String? _environment;
  final List<String> _equipment = [];

  // Etapa 7: Restrições
  final List<String> _restrictions = [];

  // Etapa 8: Recuperação
  String _sleepQuality = 'regular';
  String _stressLevel = 'medium';
  final List<String> _priorityMuscles = [];
  String _preferredStyle = 'compound_focus';

  // Dados pessoais mínimos para personalização e cálculo nutricional.
  int? _age;
  String? _sex;
  double? _weight;
  double? _height;

  void _next() {
    if (_isLoading || !_canProceed()) return;
    if (_currentPage < 8) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
      case 1:
        if (_modality == null) return false;
        if (_modality == 'running' ||
            _modality == 'combat' ||
            _modality == 'field_sports') {
          return _sportSubtype != null;
        }
        if (_modality == 'rehab') return _rehabTarget != 'rehab_general';
        return true;
      case 2: return _level != null;
      case 3:
        return _sex != null &&
            _age != null && _age! >= 13 && _age! <= 100 &&
            _weight != null && _weight! >= 30 && _weight! <= 300 &&
            _height != null && _height! >= 120 && _height! <= 240;
      case 4: return true;
      case 5: return true;
      case 6: return _environment != null;
      case 7: return true;
      case 8: return true;
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
    final technicalModality = _mapModalityToTechnical(_modality);
    final technicalGoal = _mapGoalForModality(_modality) ?? _mapGoalToTechnical(_goal);
    String technicalLevel = _mapLevelToTechnical(_level);

    final profile = WorkoutProfile(
      uid: uid,
      age: _age!,
      biologicalSex: _sex!,
      weightKg: _weight!,
      heightCm: _height!,
      bodyFatCategory: _bodyFatCategory,
      primaryGoal: technicalGoal,
      sportSubType: _sportSubtype ?? _mapSportSubtype(_modality),
      trainingModality: technicalModality,
      experienceLevel: technicalLevel,
      trainingAge: _trainingAge,
      availableDaysPerWeek: _days,
      sessionDurationMinutes: _duration,
      preferredStyle: _preferredStyle,
      sleepQuality: _sleepQuality,
      stressLevel: _stressLevel,
      priorityMuscles: List.from(_priorityMuscles),
      environment: _environment ?? 'full_gym',
      availableEquipment: List.from(_equipment),
      dislikedExercises: [],
      favoriteExercises: [],
      healthRestrictions: List.from(_restrictions),
      calibrationActive: true,
      calibrationSessionsRemaining: 6,
      confidenceByVariable: {
        'experienceLevel': ConfidenceLevel.low,
        'primaryGoal': ConfidenceLevel.low,
        'environment': ConfidenceLevel.low,
        'availableEquipment': ConfidenceLevel.low,
        'healthRestrictions': ConfidenceLevel.low,
        'availableDaysPerWeek': ConfidenceLevel.moderate,
        'sessionDurationMinutes': ConfidenceLevel.moderate,
        'age': ConfidenceLevel.moderate,
        'biologicalSex': ConfidenceLevel.moderate,
        'weightKg': ConfidenceLevel.moderate,
        'heightCm': ConfidenceLevel.moderate,
      },
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      final provider = context.read<WorkoutProfileProvider>();
      await provider.saveProfile(profile);
      await provider.generateAndSaveWorkout();

      if (mounted) {
        context.go('/athlete-profile', extra: profile);
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
      case 'sport_specific': return 'sport_specific';
      case 'power_explosive': return 'power_explosive';
      case 'calisthenics': return 'calisthenics';
      case 'functional_hiit': return 'functional_hiit';
      case 'mobility_rehab': return 'mobility_rehab';
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
    if (_goal == 'calisthenics') return 'calisthenics';
    if (_goal == 'functional_hiit') return 'functional';
    if (_goal == 'mobility_rehab' && modality != 'mobility' && modality != 'rehab') {
      return 'mobility';
    }
    switch (modality) {
      case 'gym': return 'traditional';
      case 'running': return 'none';
      case 'mobility': return 'mobility';
      case 'rehab': return _rehabTarget;
      case 'functional': return 'functional';
      case 'calisthenics': return 'calisthenics';
      case 'combat': return 'none';
      case 'cycling': return 'none';
      case 'swimming': return 'none';
      case 'field_sports': return 'none';
      default: return 'traditional';
    }
  }

  String? _mapGoalForModality(String? modality) {
    switch (modality) {
      case 'running': return 'running_hybrid';
      case 'combat': return 'combat_sports';
      case 'cycling':
      case 'swimming': return 'sport_specific';
      case 'field_sports': return 'sport_specific';
      case 'calisthenics': return 'calisthenics';
      case 'functional': return 'functional_hiit';
      case 'mobility':
      case 'rehab': return 'mobility_rehab';
      default: return null;
    }
  }

  String _mapSportSubtype(String? modality) {
    switch (modality) {
      case 'running': return 'run_5k';
      case 'combat': return 'mma';
      case 'cycling': return 'cycling';
      case 'swimming': return 'swimming';
      case 'field_sports': return 'soccer';
      default: return 'none';
    }
  }

  void _setModality(String? modality) {
    setState(() {
      _modality = modality;
      switch (modality) {
        case 'running': _sportSubtype = 'run_5k'; break;
        case 'combat': _sportSubtype = 'mma'; break;
        case 'cycling': _sportSubtype = 'cycling'; break;
        case 'swimming': _sportSubtype = 'swimming'; break;
        case 'field_sports': _sportSubtype = 'soccer'; break;
        default: _sportSubtype = null;
      }
    });
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
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  _buildGoalStep(),
                  _buildModalityStep(),
                  _buildLevelStep(),
                  _buildPersonalDataStep(),
                  _buildDaysStep(),
                  _buildDurationStep(),
                  _buildEnvironmentStep(),
                  _buildRecoveryStep(),
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

  Widget _buildPersonalDataStep() {
    return _buildStepContainer(
      title: 'Sobre você',
      subtitle: 'Esses dados ajudam a ajustar o treino e a recuperação',
      child: Column(
        children: [
          _numberField(
            label: 'Idade',
            suffix: 'anos',
            onChanged: (value) => setState(() => _age = int.tryParse(value)),
          ),
          const SizedBox(height: 12),
          _numberField(
            label: 'Peso',
            suffix: 'kg',
            decimal: true,
            onChanged: (value) => setState(() => _weight = double.tryParse(value.replaceAll(',', '.'))),
          ),
          const SizedBox(height: 12),
          _numberField(
            label: 'Altura',
            suffix: 'cm',
            decimal: true,
            onChanged: (value) => setState(() => _height = double.tryParse(value.replaceAll(',', '.'))),
          ),
          const SizedBox(height: 20),
          _buildOptionCard(
            icon: '♂️',
            title: 'Masculino',
            value: 'male',
            groupValue: _sex,
            onChanged: (value) => setState(() => _sex = value),
          ),
          _buildOptionCard(
            icon: '♀️',
            title: 'Feminino',
            value: 'female',
            groupValue: _sex,
            onChanged: (value) => setState(() => _sex = value),
          ),
        ],
      ),
    );
  }

  Widget _numberField({
    required String label,
    required String suffix,
    required ValueChanged<String> onChanged,
    bool decimal = false,
  }) {
    return TextField(
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      onChanged: onChanged,
      style: const TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        labelStyle: const TextStyle(color: AppTheme.textSecondary),
        suffixStyle: const TextStyle(color: AppTheme.textSecondary),
        filled: true,
        fillColor: AppTheme.surfaceHighlight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
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
            children: List.generate(9, (index) {
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
            'Passo ${_currentPage + 1} de 9',
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
            icon: '🏅',
            title: 'Performance esportiva',
            subtitle: 'Treino complementar para seu esporte',
            value: 'sport_specific',
            groupValue: _goal,
            onChanged: (v) => setState(() => _goal = v),
          ),
          _buildOptionCard(
            icon: '⚡',
            title: 'Potência e explosão',
            value: 'power_explosive',
            groupValue: _goal,
            onChanged: (v) => setState(() => _goal = v),
          ),
          _buildOptionCard(
            icon: '🤸',
            title: 'Calistenia',
            value: 'calisthenics',
            groupValue: _goal,
            onChanged: (v) => setState(() => _goal = v),
          ),
          _buildOptionCard(
            icon: '🔄',
            title: 'Funcional / HIIT',
            value: 'functional_hiit',
            groupValue: _goal,
            onChanged: (v) => setState(() => _goal = v),
          ),
          _buildOptionCard(
            icon: '🧘',
            title: 'Mobilidade e reabilitação',
            value: 'mobility_rehab',
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
            onChanged: (v) => _setModality(v),
          ),
          _buildOptionCard(
            icon: '🏃',
            title: 'Corrida',
            value: 'running',
            groupValue: _modality,
            onChanged: (v) => _setModality(v),
          ),
          _buildOptionCard(
            icon: '🧘',
            title: 'Mobilidade',
            value: 'mobility',
            groupValue: _modality,
            onChanged: (v) => _setModality(v),
          ),
          _buildOptionCard(
            icon: '🩹',
            title: 'Reabilitação',
            value: 'rehab',
            groupValue: _modality,
            onChanged: (v) => _setModality(v),
          ),
          _buildOptionCard(
            icon: '⚡',
            title: 'Funcional',
            value: 'functional',
            groupValue: _modality,
            onChanged: (v) => _setModality(v),
          ),
          _buildOptionCard(
            icon: '🤸',
            title: 'Calistenia',
            value: 'calisthenics',
            groupValue: _modality,
            onChanged: (v) => _setModality(v),
          ),
          _buildOptionCard(
            icon: '🥊',
            title: 'Lutas',
            value: 'combat',
            groupValue: _modality,
            onChanged: (v) => _setModality(v),
          ),
          _buildOptionCard(
            icon: '🚴',
            title: 'Ciclismo',
            value: 'cycling',
            groupValue: _modality,
            onChanged: (v) => _setModality(v),
          ),
          _buildOptionCard(
            icon: '🏊',
            title: 'Natação',
            value: 'swimming',
            groupValue: _modality,
            onChanged: (v) => _setModality(v),
          ),
          _buildOptionCard(
            icon: '🏅',
            title: 'Esportes de campo',
            value: 'field_sports',
            groupValue: _modality,
            onChanged: (v) => _setModality(v),
          ),
          if (_modality == 'running') ...[
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Distância principal', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
            ),
            _detailChoice('5 km', 'run_5k'),
            _detailChoice('10 km', 'run_10k'),
            _detailChoice('Meia maratona', 'run_half'),
            _detailChoice('Maratona', 'run_marathon'),
          ],
          if (_modality == 'combat') ...[
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Modalidade de luta', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
            ),
            _detailChoice('MMA', 'mma'),
            _detailChoice('Jiu-jitsu', 'bjj'),
            _detailChoice('Boxe / Muay Thai', 'boxing'),
          ],
          if (_modality == 'field_sports') ...[
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Esporte de campo', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
            ),
            _detailChoice('Futebol', 'soccer'),
            _detailChoice('Basquete', 'basketball'),
            _detailChoice('Agilidade / campo', 'agility'),
          ],
          if (_modality == 'rehab') ...[
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Região de atenção', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
            ),
            _detailChoice('Ombro', 'rehab_shoulder'),
            _detailChoice('Joelho', 'rehab_knee'),
            _detailChoice('Lombar', 'rehab_lower_back'),
          ],
        ],
      ),
    );
  }

  Widget _detailChoice(String title, String value) {
    return _buildOptionCard(
      icon: '•',
      title: title,
      value: value,
      groupValue: _sportSubtype ?? _rehabTarget,
      onChanged: (selected) => setState(() {
        if (_modality == 'rehab') {
          _rehabTarget = selected as String;
        } else {
          _sportSubtype = selected as String;
        }
      }),
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
          const SizedBox(height: 16),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Tempo total de treino', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
          ),
          _buildNumberSelector(
            value: _trainingAge,
            min: 0,
            max: 120,
            unit: 'meses',
            onChanged: (value) => setState(() => _trainingAge = value),
          ),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Percentual de gordura estimado', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
          ),
          _buildOptionCard(
            icon: '•',
            title: 'Baixo (menos de 15%)',
            value: 'low',
            groupValue: _bodyFatCategory,
            onChanged: (v) => setState(() => _bodyFatCategory = v),
          ),
          _buildOptionCard(
            icon: '•',
            title: 'Médio (15% a 25%)',
            value: 'medium',
            groupValue: _bodyFatCategory,
            onChanged: (v) => setState(() => _bodyFatCategory = v),
          ),
          _buildOptionCard(
            icon: '•',
            title: 'Alto (mais de 25%)',
            value: 'high',
            groupValue: _bodyFatCategory,
            onChanged: (v) => setState(() => _bodyFatCategory = v),
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
          const SizedBox(height: 16),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Estilo de treino preferido', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
          ),
          _buildOptionCard(
            icon: '🏋️',
            title: 'Multiarticulares (base)',
            value: 'compound_focus',
            groupValue: _preferredStyle,
            onChanged: (v) => setState(() => _preferredStyle = v),
          ),
          _buildOptionCard(
            icon: '🎯',
            title: 'Mais isoladores (detalhe)',
            value: 'isolation_focus',
            groupValue: _preferredStyle,
            onChanged: (v) => setState(() => _preferredStyle = v),
          ),
          _buildOptionCard(
            icon: '🔄',
            title: 'Circuito / intenso',
            value: 'circuit',
            groupValue: _preferredStyle,
            onChanged: (v) => setState(() => _preferredStyle = v),
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
      {'icon': '⭕', 'label': 'Elásticos', 'value': 'band'},
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

  // ── ETAPA 8: RECUPERAÇÃO ──
  Widget _buildRecoveryStep() {
    return _buildStepContainer(
      title: 'Como está sua recuperação?',
      subtitle: 'Isso ajusta a intensidade e o volume do seu treino',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Qualidade do sono',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildOptionCard(
            icon: '😴',
            title: 'Dormo mal (até 5h ou acordo muito)',
            value: 'poor',
            groupValue: _sleepQuality,
            onChanged: (v) => setState(() => _sleepQuality = v),
          ),
          _buildOptionCard(
            icon: '🌙',
            title: 'Dormo mais ou menos (5-7h)',
            value: 'regular',
            groupValue: _sleepQuality,
            onChanged: (v) => setState(() => _sleepQuality = v),
          ),
          _buildOptionCard(
            icon: '💤',
            title: 'Dormo bem (7-9h e descansado)',
            value: 'good',
            groupValue: _sleepQuality,
            onChanged: (v) => setState(() => _sleepQuality = v),
          ),
          const SizedBox(height: 24),
          const Text(
            'Nível de estresse',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildOptionCard(
            icon: '😰',
            title: 'Muito estressado (trabalho, vida, etc.)',
            value: 'high',
            groupValue: _stressLevel,
            onChanged: (v) => setState(() => _stressLevel = v),
          ),
          _buildOptionCard(
            icon: '😐',
            title: 'Moderado (algum estresse normal)',
            value: 'medium',
            groupValue: _stressLevel,
            onChanged: (v) => setState(() => _stressLevel = v),
          ),
          _buildOptionCard(
            icon: '😌',
            title: 'Tranquilo (pouco ou nenhum estresse)',
            value: 'low',
            groupValue: _stressLevel,
            onChanged: (v) => setState(() => _stressLevel = v),
          ),
          const SizedBox(height: 24),
          const Text(
            'Músculos que quer priorizar',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Opcional — o treino vai focar mais nessas áreas',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _muscleChip('Peito'),
              _muscleChip('Costas'),
              _muscleChip('Ombros'),
              _muscleChip('Braços'),
              _muscleChip('Pernas'),
              _muscleChip('Glúteos'),
              _muscleChip('Abdômen'),
              _muscleChip('Panturrilhas'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _muscleChip(String muscle) {
    const values = {
      'Peito': 'chest',
      'Costas': 'back',
      'Ombros': 'shoulders',
      'Braços': 'biceps',
      'Pernas': 'quads',
      'Glúteos': 'glutes',
      'Abdômen': 'abs',
      'Panturrilhas': 'calves',
    };
    final value = values[muscle] ?? muscle.toLowerCase();
    final isSelected = _priorityMuscles.contains(value);
    return FilterChip(
      label: Text(muscle),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _priorityMuscles.add(value);
          } else {
            _priorityMuscles.remove(value);
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
  }

  // ── ETAPA 9: RESTRIÇÕES ──
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
          _buildRestrictionChip('Hipertensão', 'hypertension'),
          _buildRestrictionChip('Hérnia', 'hernia'),
          _buildRestrictionChip('Pós-cirurgia', 'post_surgery'),
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
    String unit = 'dias',
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
              unit,
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
                      _currentPage == 8 ? 'Começar!' : 'Próximo',
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
