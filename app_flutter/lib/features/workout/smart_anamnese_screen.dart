import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/services/supabase_service.dart';
import '../../shared/theme/app_theme.dart';
import 'workout_profile_model.dart';
import 'workout_profile_provider.dart';
import 'training_readiness.dart';

class SmartAnamneseScreen extends StatefulWidget {
  const SmartAnamneseScreen({super.key});
  @override
  State<SmartAnamneseScreen> createState() => _SmartAnamneseScreenState();
}

class _SmartAnamneseScreenState extends State<SmartAnamneseScreen> {
  int _currentStep = 0;
  final int _totalSteps = 10;
  bool _isSaving = false;

  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  String _sex = 'male';
  String _primaryGoal = '';
  List<String> _secondaryGoals = [];
  List<String> _musclePriorities = [];
  final _strengthController = TextEditingController();
  String? _sportModality;
  String _sportLevel = 'amateur';
  int _sportFrequency = 2;
  List<String> _sportDemands = [];
  String _experience = '';
  int _availableDays = 3;
  String _sessionDuration = '45_60';
  String _scheduleStability = 'mostly_stable';
  String _location = 'gym';
  List<String> _availableEquipment = [];
  bool _limitationsPresent = false;
  List<_LimitationInput> _limitations = [];
  String _selfReportedCapacity = 'regular';
  List<String> _movementConfidence = [];
  String _trainingStyle = 'no_preference';
  List<String> _preferredExercises = [];
  List<String> _dislikedExercises = [];
  String _sleepQuality = 'regular';
  String _stressLevel = 'moderate';
  String _occupationalLoad = 'none';
  List<_OtherActivityInput> _otherActivities = [];
  List<String> _specificNeeds = [];
  final _additionalController = TextEditingController();
  final _exerciseSearchController = TextEditingController();

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _strengthController.dispose();
    _additionalController.dispose();
    _exerciseSearchController.dispose();
    super.dispose();
  }

  int? get _age => int.tryParse(_ageController.text);
  double? get _height => double.tryParse(_heightController.text);
  double? get _weight => double.tryParse(_weightController.text);

  bool _validateStep() {
    switch (_currentStep) {
      case 0:
        return _age != null &&
            _age! >= 13 &&
            _age! <= 100 &&
            _height != null &&
            _height! >= 120 &&
            _height! <= 240 &&
            _weight != null &&
            _weight! >= 30 &&
            _weight! <= 300;
      case 1:
        return _primaryGoal.isNotEmpty;
      case 2:
        return _experience.isNotEmpty;
      default:
        return true;
    }
  }

  void _nextStep() {
    if (!_validateStep()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete as informações obrigatórias.')),
      );
      return;
    }
    if (_currentStep < _totalSteps - 1)
      setState(() => _currentStep++);
    else
      _finish();
  }

  void _prevStep() {
    if (_currentStep > 0) setState(() => _currentStep--);
  }

  int _computeTrainingAge() {
    switch (_experience) {
      case 'never':
        return 0;
      case 'starting':
        return 3;
      case 'returning':
        return 6;
      case 'regular':
        return 24;
      case 'veteran':
        return 60;
      default:
        return 6;
    }
  }

  String _computeBodyFat() {
    final bmi =
        (_weight ?? 70) / ((_height ?? 170) / 100 * (_height ?? 170) / 100);
    if (bmi < 22) return 'low';
    if (bmi < 28) return 'medium';
    return 'high';
  }

  List<String> _extractRestrictions() {
    if (!_limitationsPresent) return [];
    return _limitations
        .map((l) => l.location)
        .where((l) => l.isNotEmpty)
        .toSet()
        .toList();
  }

  String _mapExp(String e) {
    switch (e) {
      case 'never':
      case 'starting':
      case 'returning':
        return 'beginner';
      case 'regular':
        return 'intermediate';
      case 'veteran':
        return 'advanced';
      default:
        return 'beginner';
    }
  }

  String _mapGoal(String g) {
    switch (g) {
      case 'hypertrophy':
      case 'recomposition':
        return 'hypertrophy';
      case 'fat_loss':
        return 'fat_loss';
      case 'strength':
        return 'strength';
      case 'conditioning':
      case 'endurance':
        return 'running_hybrid';
      case 'power':
        return 'power_explosive';
      case 'sport':
        return 'sport_specific';
      case 'health':
      case 'return':
        return 'general_health';
      case 'functional':
        return 'functional_hiit';
      default:
        return 'hypertrophy';
    }
  }

  String _mapSport() {
    if (_sportModality == null) return 'none';
    final m = _sportModality!.toLowerCase();
    if (m.contains('corrida') || m.contains('running')) return 'run_5k';
    if (m.contains('futebol')) return 'soccer';
    if (m.contains('basquete')) return 'basketball';
    if (m.contains('nata')) return 'swimming';
    if (m.contains('cicl') || m.contains('bike')) return 'cycling';
    if (m.contains('bjj')) return 'bjj';
    if (m.contains('boxe')) return 'boxing';
    if (m.contains('mma') || m.contains('luta')) return 'mma';
    return 'none';
  }

  int _mapDur(String d) {
    switch (d) {
      case 'up_to_20':
        return 20;
      case '20_30':
        return 30;
      case '30_45':
        return 45;
      case '45_60':
        return 55;
      case '60_90':
        return 75;
      default:
        return 45;
    }
  }

  String _mapEnv(String l) => l == 'gym'
      ? 'full_gym'
      : l == 'outdoor'
      ? 'outdoor'
      : 'home';
  String _mapSleep(String s) {
    switch (s) {
      case 'very_poor':
      case 'poor':
        return 'poor';
      case 'good':
      case 'very_good':
        return 'good';
      default:
        return 'fair';
    }
  }

  String _mapStress(String s) {
    switch (s) {
      case 'very_low':
      case 'low':
        return 'low';
      case 'high':
      case 'very_high':
        return 'high';
      default:
        return 'moderate';
    }
  }

  String _mapStyle(String s) {
    switch (s) {
      case 'simple':
      case 'track_progress':
        return 'compound_focus';
      case 'varied':
      case 'try_new':
        return 'isolation_focus';
      default:
        return 'moderate_volume';
    }
  }

  LifeLoad _computeLifeLoad() {
    String pw = _occupationalLoad == 'heavy'
        ? 'high'
        : _occupationalLoad == 'moderate'
        ? 'moderate'
        : 'low';
    String ps = 'low';
    for (final a in _otherActivities) {
      if (a.frequency >= 3) ps = 'moderate';
      if (a.frequency >= 5) ps = 'high';
    }
    String dr = _occupationalLoad == 'heavy'
        ? 'high'
        : _occupationalLoad == 'moderate' || _otherActivities.isNotEmpty
        ? 'moderate'
        : 'low';
    return LifeLoad(physicalWork: pw, parallelSport: ps, dailyRoutine: dr);
  }

  Future<void> _finish() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final uid = SupabaseService().currentUser?.id ?? '';
      if (uid.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Erro: não autenticado.')));
        setState(() => _isSaving = false);
        return;
      }
      final profile = WorkoutProfile(
        uid: uid,
        age: _age ?? 25,
        biologicalSex: _sex,
        weightKg: _weight ?? 70,
        heightCm: _height ?? 170,
        bodyFatCategory: _computeBodyFat(),
        experienceLevel: _mapExp(_experience),
        trainingAge: _computeTrainingAge(),
        primaryGoal: _mapGoal(_primaryGoal),
        sportSubType: _mapSport(),
        trainingModality: 'none',
        availableDaysPerWeek: _availableDays,
        sessionDurationMinutes: _mapDur(_sessionDuration),
        preferredStyle: _mapStyle(_trainingStyle),
        sleepQuality: _mapSleep(_sleepQuality),
        stressLevel: _mapStress(_stressLevel),
        priorityMuscles: _musclePriorities,
        environment: _mapEnv(_location),
        availableEquipment: _location == 'gym'
            ? ['full_gym']
            : _availableEquipment,
        healthRestrictions: _extractRestrictions(),
        dislikedExercises: _dislikedExercises,
        favoriteExercises: _preferredExercises,
        lifeLoad: _computeLifeLoad(),
        calibrationActive: true,
        calibrationSessionsRemaining: 6,
        adaptive: const UserAdaptiveProfile(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final provider = context.read<WorkoutProfileProvider>();
      await provider.saveProfile(profile);
      await provider.generateAndSaveWorkout();
      if (mounted) context.go('/athlete-profile', extra: profile);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
                onPressed: _prevStep,
              )
            : null,
        title: Text(
          'Etapa ${_currentStep + 1} de $_totalSteps',
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: SizedBox(
                width: 100,
                child: LinearProgressIndicator(
                  value: (_currentStep + 1) / _totalSteps,
                  backgroundColor: AppTheme.surface,
                  valueColor: const AlwaysStoppedAnimation(AppTheme.accent),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _buildStep(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _nextStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _currentStep == _totalSteps - 1
                              ? 'Gerar Treino'
                              : 'Continuar',
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_currentStep) {
      case 0:
        return _step1();
      case 1:
        return _step2();
      case 2:
        return _step3();
      case 3:
        return _step4();
      case 4:
        return _step5();
      case 5:
        return _step6();
      case 6:
        return _step7();
      case 7:
        return _step8();
      case 8:
        return _step9();
      case 9:
        return _step10();
      default:
        return const SizedBox();
    }
  }

  Widget _step1() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Seu ponto de partida',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimary,
        ),
      ),
      const SizedBox(height: 24),
      _numField('Idade', _ageController, 'Ex: 25'),
      const SizedBox(height: 16),
      _chips(
        'Sexo',
        [_C('male', 'Masculino'), _C('female', 'Feminino')],
        _sex,
        (v) => setState(() => _sex = v),
      ),
      const SizedBox(height: 16),
      _numField('Altura (cm)', _heightController, 'Ex: 170'),
      const SizedBox(height: 16),
      _numField('Peso (kg)', _weightController, 'Ex: 70'),
    ],
  );

  Widget _step2() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Seu objetivo',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimary,
        ),
      ),
      const SizedBox(height: 24),
      _chips(
        'Objetivo principal',
        [
          _C('hypertrophy', 'Ganhar massa'),
          _C('fat_loss', 'Perder gordura'),
          _C('strength', 'Força'),
          _C('conditioning', 'Condição'),
          _C('power', 'Potência'),
          _C('sport', 'Esporte'),
          _C('health', 'Saúde'),
          _C('functional', 'Funcional'),
          _C('return', 'Voltar'),
          _C('recomposition', 'Recomposição'),
        ],
        _primaryGoal,
        (v) => setState(() => _primaryGoal = v),
        wrap: true,
      ),
      if (_primaryGoal == 'hypertrophy' || _primaryGoal == 'recomposition') ...[
        const SizedBox(height: 24),
        const Text(
          'Priorizar região?',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 8),
        _multi(
          [
            'chest',
            'back',
            'shoulders',
            'arms',
            'quads',
            'hamstrings',
            'glutes',
            'calves',
            'abs',
          ],
          _musclePriorities,
          (v) => setState(
            () => _musclePriorities.contains(v)
                ? _musclePriorities.remove(v)
                : _musclePriorities.add(v),
          ),
          labels: {
            'chest': 'Peito',
            'back': 'Costas',
            'shoulders': 'Ombros',
            'arms': 'Braços',
            'quads': 'Quadríceps',
            'hamstrings': 'Posteriores',
            'glutes': 'Glúteos',
            'calves': 'Panturrilhas',
            'abs': 'Abdômen',
          },
        ),
      ],
      if (_primaryGoal == 'strength') ...[
        const SizedBox(height: 24),
        _txtField(
          'Movimento específico? (opcional)',
          _strengthController,
          'Ex: agachamento',
        ),
      ],
      if (_primaryGoal == 'sport') ...[
        const SizedBox(height: 24),
        _txtField(
          'Qual esporte?',
          TextEditingController(),
          'Ex: futebol',
          onChanged: (v) => _sportModality = v,
        ),
        const SizedBox(height: 16),
        _chips(
          'Nível',
          [
            _C('recreational', 'Recreativo'),
            _C('amateur', 'Amador'),
            _C('competitive', 'Competitivo'),
          ],
          _sportLevel,
          (v) => setState(() => _sportLevel = v),
        ),
      ],
      if (_primaryGoal.isNotEmpty && _primaryGoal != 'sport') ...[
        const SizedBox(height: 24),
        const Text(
          'Objetivos secundários?',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 8),
        _multi(
          ['hypertrophy', 'fat_loss', 'strength', 'conditioning', 'health'],
          _secondaryGoals,
          (v) => setState(
            () => _secondaryGoals.contains(v)
                ? _secondaryGoals.remove(v)
                : _secondaryGoals.add(v),
          ),
          labels: {
            'hypertrophy': 'Massa',
            'fat_loss': 'Gordura',
            'strength': 'Força',
            'conditioning': 'Condição',
            'health': 'Saúde',
          },
        ),
      ],
    ],
  );

  Widget _step3() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Sua rotina',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimary,
        ),
      ),
      const SizedBox(height: 24),
      _chips(
        'Experiência',
        [
          _C('never', 'Nunca'),
          _C('starting', 'Começando'),
          _C('returning', 'Voltando'),
          _C('regular', 'Regular'),
          _C('veteran', 'Vários anos'),
        ],
        _experience,
        (v) => setState(() => _experience = v),
        wrap: true,
      ),
      const SizedBox(height: 24),
      Text(
        'Dias/semana: $_availableDays',
        style: const TextStyle(color: AppTheme.textPrimary),
      ),
      Slider(
        value: _availableDays.toDouble(),
        min: 1,
        max: 7,
        divisions: 6,
        activeColor: AppTheme.accent,
        onChanged: (v) => setState(() => _availableDays = v.toInt()),
      ),
      const SizedBox(height: 16),
      _chips(
        'Tempo/treino',
        [
          _C('up_to_20', '=20min'),
          _C('20_30', '20-30'),
          _C('30_45', '30-45'),
          _C('45_60', '45-60'),
          _C('60_90', '60-90'),
          _C('over_90', '90+'),
        ],
        _sessionDuration,
        (v) => setState(() => _sessionDuration = v),
        wrap: true,
      ),
    ],
  );

  Widget _step4() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Onde vai treinar?',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimary,
        ),
      ),
      const SizedBox(height: 24),
      _chips(
        'Local',
        [_C('gym', 'Academia'), _C('home', 'Casa'), _C('outdoor', 'Ar livre')],
        _location,
        (v) => setState(() => _location = v),
      ),
      if (_location == 'home') ...[
        const SizedBox(height: 24),
        const Text(
          'Equipamentos?',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 8),
        _multi(
          [
            'dumbbell',
            'barbell',
            'band',
            'kettlebell',
            'bench',
            'pull_up_bar',
          ],
          _availableEquipment,
          (v) => setState(
            () => _availableEquipment.contains(v)
                ? _availableEquipment.remove(v)
                : _availableEquipment.add(v),
          ),
          labels: {
            'dumbbell': 'Halteres',
            'barbell': 'Barra',
            'band': 'Elásticos',
            'kettlebell': 'KB',
            'bench': 'Banco',
            'pull_up_bar': 'Barra fixa',
          },
        ),
      ],
    ],
  );

  Widget _step5() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Seu corpo hoje',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimary,
        ),
      ),
      const SizedBox(height: 24),
      _chips(
        'Limitação?',
        [_C('none', 'Não'), _C('yes', 'Sim')],
        _limitationsPresent ? 'yes' : 'none',
        (v) => setState(() {
          _limitationsPresent = v == 'yes';
          if (_limitationsPresent && _limitations.isEmpty)
            _limitations.add(_LimitationInput());
          if (!_limitationsPresent) _limitations.clear();
        }),
      ),
      if (_limitationsPresent) ...[
        const SizedBox(height: 16),
        ..._limitations.asMap().entries.map((e) => _limCard(e.key, e.value)),
        TextButton.icon(
          onPressed: () => setState(() => _limitations.add(_LimitationInput())),
          icon: const Icon(Icons.add, color: AppTheme.accent),
          label: const Text(
            'Adicionar',
            style: TextStyle(color: AppTheme.accent),
          ),
        ),
      ],
    ],
  );

  Widget _limCard(int i, _LimitationInput lim) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Limitação ${i + 1}',
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (_limitations.length > 1)
              IconButton(
                icon: const Icon(Icons.close, color: AppTheme.danger, size: 20),
                onPressed: () => setState(() => _limitations.removeAt(i)),
              ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'Onde?',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children:
              [
                    'shoulder',
                    'knee',
                    'lower_back',
                    'elbow',
                    'wrist',
                    'hip',
                    'ankle',
                  ]
                  .map(
                    (l) => _sChip(
                      _locL(l),
                      lim.location == l,
                      () => setState(() => lim.location = l),
                    ),
                  )
                  .toList(),
        ),
        const SizedBox(height: 12),
        const Text(
          'O que acontece?',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: ['pain', 'weakness', 'stiffness', 'instability']
              .map(
                (t) => _sChip(
                  _typeL(t),
                  lim.type == t,
                  () => setState(() => lim.type = t),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 12),
        Text(
          'Intensidade: ${lim.intensity}/10',
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
        Slider(
          value: lim.intensity.toDouble(),
          min: 0,
          max: 10,
          divisions: 10,
          activeColor: AppTheme.accent,
          onChanged: (v) => setState(() => lim.intensity = v.toInt()),
        ),
        _txtField(
          'Movimento que piora? (opcional)',
          TextEditingController(),
          'Ex: agachamento',
          onChanged: (v) => lim.aggravatingMovement = v,
        ),
      ],
    ),
  );

  String _locL(String l) =>
      {
        'shoulder': 'Ombro',
        'knee': 'Joelho',
        'lower_back': 'Lombar',
        'elbow': 'Cotovelo',
        'wrist': 'Punho',
        'hip': 'Quadril',
        'ankle': 'Tornozelo',
      }[l] ??
      l;
  String _typeL(String t) =>
      {
        'pain': 'Dor',
        'weakness': 'Fraqueza',
        'stiffness': 'Rigidez',
        'instability': 'Instabilidade',
      }[t] ??
      t;

  Widget _step6() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Sua capacidade',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimary,
        ),
      ),
      const SizedBox(height: 24),
      _chips(
        'Capacidade física',
        [
          _C('very_low', 'Muito baixa'),
          _C('low', 'Baixa'),
          _C('regular', 'Regular'),
          _C('good', 'Boa'),
          _C('very_good', 'Muito boa'),
        ],
        _selfReportedCapacity,
        (v) => setState(() => _selfReportedCapacity = v),
        wrap: true,
      ),
      const SizedBox(height: 24),
      const Text(
        'Movimentos com segurança?',
        style: TextStyle(color: AppTheme.textSecondary),
      ),
      const SizedBox(height: 8),
      _multi(
        ['squat', 'hinge', 'push', 'pull', 'carry', 'lunge'],
        _movementConfidence,
        (v) => setState(
          () => _movementConfidence.contains(v)
              ? _movementConfidence.remove(v)
              : _movementConfidence.add(v),
        ),
        labels: {
          'squat': 'Agachar',
          'hinge': 'Levantar',
          'push': 'Empurrar',
          'pull': 'Puxar',
          'carry': 'Carregar',
          'lunge': 'Afundo',
        },
      ),
    ],
  );

  Widget _step7() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Preferências',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimary,
        ),
      ),
      const SizedBox(height: 24),
      _chips(
        'Estilo',
        [
          _C('simple', 'Simples'),
          _C('varied', 'Variado'),
          _C('track_progress', 'Evoluir'),
          _C('try_new', 'Novidades'),
        ],
        _trainingStyle,
        (v) => setState(() => _trainingStyle = v),
        wrap: true,
      ),
      const SizedBox(height: 24),
      const Text(
        'Exercícios favoritos? (opcional)',
        style: TextStyle(color: AppTheme.textSecondary),
      ),
      const SizedBox(height: 8),
      _exSearch(_preferredExercises, 'Adicionar favorito'),
      const SizedBox(height: 24),
      const Text(
        'Exercícios a evitar? (opcional)',
        style: TextStyle(color: AppTheme.textSecondary),
      ),
      const SizedBox(height: 8),
      _exSearch(_dislikedExercises, 'Adicionar a evitar'),
    ],
  );

  Widget _exSearch(List<String> list, String hint) => Column(
    children: [
      if (list.isNotEmpty)
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: list
              .map(
                (e) => Chip(
                  label: Text(e, style: const TextStyle(fontSize: 12)),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () => setState(() => list.remove(e)),
                ),
              )
              .toList(),
        ),
      const SizedBox(height: 8),
      TextField(
        controller: _exerciseSearchController,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: AppTheme.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          suffixIcon: IconButton(
            icon: const Icon(Icons.add, color: AppTheme.accent),
            onPressed: () {
              final v = _exerciseSearchController.text.trim();
              if (v.isNotEmpty && !list.contains(v))
                setState(() {
                  list.add(v);
                  _exerciseSearchController.clear();
                });
            },
          ),
        ),
      ),
    ],
  );

  Widget _step8() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Recuperação',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimary,
        ),
      ),
      const SizedBox(height: 24),
      _chips(
        'Sono',
        [
          _C('very_poor', 'Muito ruim'),
          _C('poor', 'Ruim'),
          _C('regular', 'Regular'),
          _C('good', 'Bom'),
          _C('very_good', 'Ótimo'),
        ],
        _sleepQuality,
        (v) => setState(() => _sleepQuality = v),
      ),
      const SizedBox(height: 16),
      _chips(
        'Estresse',
        [
          _C('very_low', 'Muito baixo'),
          _C('low', 'Baixo'),
          _C('moderate', 'Moderado'),
          _C('high', 'Alto'),
          _C('very_high', 'Muito alto'),
        ],
        _stressLevel,
        (v) => setState(() => _stressLevel = v),
      ),
      const SizedBox(height: 16),
      _chips(
        'Trabalho físico',
        [
          _C('none', 'Nenhum'),
          _C('little', 'Pouco'),
          _C('moderate', 'Moderado'),
          _C('heavy', 'Muito'),
        ],
        _occupationalLoad,
        (v) => setState(() => _occupationalLoad = v),
      ),
      const SizedBox(height: 16),
      const Text(
        'Outras atividades?',
        style: TextStyle(color: AppTheme.textSecondary),
      ),
      ..._otherActivities.asMap().entries.map(
        (e) => Row(
          children: [
            Expanded(
              child: Text(
                e.value.name,
                style: const TextStyle(color: AppTheme.textPrimary),
              ),
            ),
            Text(
              '${e.value.frequency}x/sem',
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 16, color: AppTheme.danger),
              onPressed: () => setState(() => _otherActivities.removeAt(e.key)),
            ),
          ],
        ),
      ),
      TextButton.icon(
        onPressed: () =>
            setState(() => _otherActivities.add(_OtherActivityInput())),
        icon: const Icon(Icons.add, color: AppTheme.accent),
        label: const Text(
          'Adicionar',
          style: TextStyle(color: AppTheme.accent),
        ),
      ),
    ],
  );

  Widget _step9() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Necessidades específicas',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimary,
        ),
      ),
      const SizedBox(height: 24),
      _multi(
        ['posture', 'mobility', 'short_time', 'none'],
        _specificNeeds,
        (v) => setState(() {
          if (v == 'none') {
            _specificNeeds = ['none'];
            return;
          }
          _specificNeeds.remove('none');
          _specificNeeds.contains(v)
              ? _specificNeeds.remove(v)
              : _specificNeeds.add(v);
        }),
        labels: {
          'posture': 'Postura',
          'mobility': 'Mobilidade',
          'short_time': 'Pouco tempo',
          'none': 'Nenhuma',
        },
      ),
      const SizedBox(height: 24),
      TextField(
        controller: _additionalController,
        maxLines: 3,
        decoration: InputDecoration(
          hintText: 'Algo mais? (opcional)',
          filled: true,
          fillColor: AppTheme.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    ],
  );

  Widget _step10() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Revisão',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimary,
        ),
      ),
      const SizedBox(height: 24),
      _rev('Objetivo', _goalL(_primaryGoal)),
      _rev('Experiência', _expL(_experience)),
      _rev('Dias', '$_availableDays/semana'),
      _rev('Tempo', _durL(_sessionDuration)),
      _rev('Local', _locL2(_location)),
      if (_limitationsPresent)
        _rev('Limitações', '${_limitations.length} limitação(ões)'),
      _rev('Sono', _slpL(_sleepQuality)),
      _rev('Estresse', _strL(_stressLevel)),
      if (_musclePriorities.isNotEmpty)
        _rev('Prioridades', _musclePriorities.map((m) => _musL(m)).join(', ')),
      if (_preferredExercises.isNotEmpty)
        _rev('Favoritos', _preferredExercises.join(', ')),
      if (_dislikedExercises.isNotEmpty)
        _rev('Evitar', _dislikedExercises.join(', ')),
    ],
  );

  Widget _numField(String l, TextEditingController c, String h) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        l,
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      const SizedBox(height: 8),
      TextField(
        controller: c,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          hintText: h,
          filled: true,
          fillColor: AppTheme.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    ],
  );
  Widget _txtField(
    String l,
    TextEditingController c,
    String h, {
    Function(String)? onChanged,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        l,
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      const SizedBox(height: 8),
      TextField(
        controller: c,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: h,
          filled: true,
          fillColor: AppTheme.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    ],
  );
  Widget _chips(
    String l,
    List<_C> o,
    String s,
    Function(String) f, {
    bool wrap = false,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        l,
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: o.map((c) => _chip(c.l, s == c.v, () => f(c.v))).toList(),
      ),
    ],
  );
  Widget _multi(
    List<String> o,
    List<String> s,
    Function(String) f, {
    Map<String, String>? labels,
  }) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: o
        .map((k) => _chip(labels?[k] ?? k, s.contains(k), () => f(k)))
        .toList(),
  );
  Widget _chip(String l, bool s, VoidCallback t) => GestureDetector(
    onTap: t,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: s ? AppTheme.accent : AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: s ? AppTheme.accent : AppTheme.divider),
      ),
      child: Text(
        l,
        style: TextStyle(
          color: s ? Colors.white : AppTheme.textPrimary,
          fontWeight: s ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    ),
  );
  Widget _sChip(String l, bool s, VoidCallback t) => GestureDetector(
    onTap: t,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: s ? AppTheme.accent : AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: s ? AppTheme.accent : AppTheme.divider),
      ),
      child: Text(
        l,
        style: TextStyle(
          color: s ? Colors.white : AppTheme.textPrimary,
          fontSize: 12,
        ),
      ),
    ),
  );
  Widget _rev(String l, String v) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(l, style: const TextStyle(color: AppTheme.textSecondary)),
        Flexible(
          child: Text(
            v,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    ),
  );

  String _goalL(String g) =>
      {
        'hypertrophy': 'Massa',
        'fat_loss': 'Gordura',
        'strength': 'Força',
        'conditioning': 'Condição',
        'power': 'Potência',
        'sport': 'Esporte',
        'health': 'Saúde',
        'functional': 'Funcional',
        'return': 'Voltar',
        'recomposition': 'Recomposição',
      }[g] ??
      g;
  String _expL(String e) =>
      {
        'never': 'Nunca',
        'starting': 'Começando',
        'returning': 'Voltando',
        'regular': 'Regular',
        'veteran': 'Vários anos',
      }[e] ??
      e;
  String _durL(String d) =>
      {
        'up_to_20': '=20min',
        '20_30': '20-30',
        '30_45': '30-45',
        '45_60': '45-60',
        '60_90': '60-90',
        'over_90': '90+',
      }[d] ??
      d;
  String _locL2(String l) =>
      {'gym': 'Academia', 'home': 'Casa', 'outdoor': 'Ar livre'}[l] ?? l;
  String _slpL(String s) =>
      {
        'very_poor': 'Muito ruim',
        'poor': 'Ruim',
        'regular': 'Regular',
        'good': 'Bom',
        'very_good': 'Ótimo',
      }[s] ??
      s;
  String _strL(String s) =>
      {
        'very_low': 'Muito baixo',
        'low': 'Baixo',
        'moderate': 'Moderado',
        'high': 'Alto',
        'very_high': 'Muito alto',
      }[s] ??
      s;
  String _musL(String m) =>
      {
        'chest': 'Peito',
        'back': 'Costas',
        'shoulders': 'Ombros',
        'arms': 'Braços',
        'quads': 'Quadríceps',
        'hamstrings': 'Posteriores',
        'glutes': 'Glúteos',
        'calves': 'Panturrilhas',
        'abs': 'Abdômen',
      }[m] ??
      m;
}

class _C {
  final String v;
  final String l;
  const _C(this.v, this.l);
}

class _LimitationInput {
  String location = '';
  String type = 'pain';
  String moment = 'during_exercise';
  int intensity = 5;
  String aggravatingMovement = '';
  String diagnosis = '';
}

class _OtherActivityInput {
  String name = '';
  int frequency = 2;
  int duration = 30;
}
