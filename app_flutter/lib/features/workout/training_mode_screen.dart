import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../shared/theme/app_theme.dart';
import 'collective_training.dart';
import 'collective_profile_provider.dart';

/// Tela de seleção do modo de treinamento.
/// O usuário escolhe: Individual, Dupla ou Grupo.
class TrainingModeScreen extends StatelessWidget {
  const TrainingModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textPrimary, size: 20),
          onPressed: () => context.go('/dashboard'),
        ),
        title: Text(
          'MODO DE TREINAMENTO',
          style: GoogleFonts.outfit(
            color: AppTheme.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Como você vai treinar?',
              style: GoogleFonts.outfit(
                color: AppTheme.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Escolha o modo que melhor descreve sua sessão.',
              style: GoogleFonts.outfit(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),
            _ModeCard(
              icon: Icons.person_rounded,
              title: 'Individual',
              subtitle: 'Treino personalizado só para você.',
              onTap: () => context.go('/anamnese'),
            ),
            const SizedBox(height: 16),
            _ModeCard(
              icon: Icons.people_rounded,
              title: 'Dupla',
              subtitle: 'Treine com um parceiro. Exercícios compartilhados ou individuais.',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DuoQuestionnaireScreen()),
              ),
            ),
            const SizedBox(height: 16),
            _ModeCard(
              icon: Icons.groups_rounded,
              title: 'Grupo',
              subtitle: 'Treine em grupo. Núcleo comum com adaptações individuais.',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GroupQuestionnaireScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF161616),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppTheme.accent, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.outfit(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// QUESTIONÁRIO DE DUPLA
// ═══════════════════════════════════════════════════════════════

class DuoQuestionnaireScreen extends StatefulWidget {
  const DuoQuestionnaireScreen({super.key});

  @override
  State<DuoQuestionnaireScreen> createState() => _DuoQuestionnaireScreenState();
}

class _DuoQuestionnaireScreenState extends State<DuoQuestionnaireScreen> {
  int _step = 0;

  // Dados da Pessoa A
  String _nameA = '';
  int _ageA = 25;
  String _sexA = 'male';
  String _goalA = 'hypertrophy';
  String _levelA = 'beginner';
  String _envA = 'full_gym';
  final List<String> _equipA = [];
  final List<String> _restrictionsA = [];

  // Dados da Pessoa B
  String _nameB = '';
  int _ageB = 25;
  String _sexB = 'male';
  String _goalB = 'hypertrophy';
  String _levelB = 'beginner';
  String _envB = 'full_gym';
  final List<String> _equipB = [];
  final List<String> _restrictionsB = [];

  // Dados da dupla
  bool _wantSameWorkout = false;
  bool _wantToTrainTogether = true;
  SyncLevel _syncLevel = SyncLevel.medium;
  ParticipantRelation _relation = ParticipantRelation.friends;

  DuoProfile _buildProfile() {
    return DuoProfile(
      personA: ParticipantProfile(
        name: _nameA.isEmpty ? 'Pessoa A' : _nameA,
        age: _ageA, biologicalSex: _sexA, weightKg: 70, heightCm: 170,
        experienceLevel: _levelA, trainingAge: _levelA == 'beginner' ? 0 : 18,
        primaryGoal: _goalA, environment: _envA,
        availableEquipment: List.from(_equipA),
        healthRestrictions: List.from(_restrictionsA),
        sessionDurationMinutes: 60,
      ),
      personB: ParticipantProfile(
        name: _nameB.isEmpty ? 'Pessoa B' : _nameB,
        age: _ageB, biologicalSex: _sexB, weightKg: 70, heightCm: 170,
        experienceLevel: _levelB, trainingAge: _levelB == 'beginner' ? 0 : 18,
        primaryGoal: _goalB, environment: _envB,
        availableEquipment: List.from(_equipB),
        healthRestrictions: List.from(_restrictionsB),
        sessionDurationMinutes: 60,
      ),
      wantSameWorkout: _wantSameWorkout,
      wantToTrainTogether: _wantToTrainTogether,
      haveSameGoals: _goalA == _goalB,
      haveSimilarLevels: _levelA == _levelB,
      haveSimilarEquipment: _envA == _envB,
      haveDifferentRestrictions: _restrictionsA.isNotEmpty && _restrictionsB.isNotEmpty,
      wantToFinishTogether: true,
      acceptDifferentExercises: !_wantSameWorkout,
      syncLevel: _syncLevel,
      relation: _relation,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textPrimary, size: 20),
          onPressed: () {
            if (_step > 0) setState(() => _step--);
            else Navigator.pop(context);
          },
        ),
        title: Text(
          'DUPLA — PASSO ${_step + 1} de 5',
          style: GoogleFonts.outfit(
            color: AppTheme.textPrimary, fontSize: 12,
            fontWeight: FontWeight.w900, letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body: _buildStep(),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0: return _buildNamesStep();
      case 1: return _buildPersonStep('A', _nameA, _ageA, _sexA, _goalA, _levelA, _envA, _equipA, _restrictionsA,
        onName: (v) => setState(() => _nameA = v),
        onAge: (v) => setState(() => _ageA = v),
        onSex: (v) => setState(() => _sexA = v),
        onGoal: (v) => setState(() => _goalA = v),
        onLevel: (v) => setState(() => _levelA = v),
        onEnv: (v) => setState(() => _envA = v),
        onEquip: (v) => setState(() { _equipA.clear(); _equipA.addAll(v); }),
        onRestrictions: (v) => setState(() { _restrictionsA.clear(); _restrictionsA.addAll(v); }),
      );
      case 2: return _buildPersonStep('B', _nameB, _ageB, _sexB, _goalB, _levelB, _envB, _equipB, _restrictionsB,
        onName: (v) => setState(() => _nameB = v),
        onAge: (v) => setState(() => _ageB = v),
        onSex: (v) => setState(() => _sexB = v),
        onGoal: (v) => setState(() => _goalB = v),
        onLevel: (v) => setState(() => _levelB = v),
        onEnv: (v) => setState(() => _envB = v),
        onEquip: (v) => setState(() { _equipB.clear(); _equipB.addAll(v); }),
        onRestrictions: (v) => setState(() { _restrictionsB.clear(); _restrictionsB.addAll(v); }),
      );
      case 3: return _buildPreferencesStep();
      case 4: return _buildSummaryStep();
      default: return const SizedBox();
    }
  }

  Widget _buildNamesStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nomes dos participantes', style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          _inputField('Nome da Pessoa A', (v) => setState(() => _nameA = v)),
          const SizedBox(height: 16),
          _inputField('Nome da Pessoa B', (v) => setState(() => _nameB = v)),
          const Spacer(),
          _nextButton(() => setState(() => _step++)),
        ],
      ),
    );
  }

  Widget _buildPersonStep(
    String label,
    String name, int age, String sex, String goal, String level, String env,
    List<String> equip, List<String> restrictions, {
    required ValueChanged<String> onName,
    required ValueChanged<int> onAge,
    required ValueChanged<String> onSex,
    required ValueChanged<String> onGoal,
    required ValueChanged<String> onLevel,
    required ValueChanged<String> onEnv,
    required ValueChanged<List<String>> onEquip,
    required ValueChanged<List<String>> onRestrictions,
  }) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: ListView(
        children: [
          Text('Perfil da Pessoa $label', style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _inputField(name.isEmpty ? 'Nome' : name, onName),
          const SizedBox(height: 16),
          _numberField('Idade', age, onAge),
          const SizedBox(height: 16),
          Text('Objetivo', style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 12)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: ['hypertrophy', 'strength', 'fat_loss', 'general_health'].map((g) =>
              ChoiceChip(
                label: Text(g.replaceAll('_', ' '), style: GoogleFonts.outfit(fontSize: 12)),
                selected: goal == g,
                selectedColor: AppTheme.accent,
                backgroundColor: AppTheme.surfaceHighlight,
                onSelected: (_) => onGoal(g),
              ),
            ).toList(),
          ),
          const SizedBox(height: 16),
          Text('Nível', style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 12)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: ['beginner', 'intermediate', 'advanced'].map((l) =>
              ChoiceChip(
                label: Text(l, style: GoogleFonts.outfit(fontSize: 12)),
                selected: level == l,
                selectedColor: AppTheme.accent,
                backgroundColor: AppTheme.surfaceHighlight,
                onSelected: (_) => onLevel(l),
              ),
            ).toList(),
          ),
          const SizedBox(height: 32),
          _nextButton(() => setState(() => _step++)),
        ],
      ),
    );
  }

  Widget _buildPreferencesStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: ListView(
        children: [
          Text('Preferências da dupla', style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _switchTile('Querem fazer o mesmo treino?', _wantSameWorkout, (v) => setState(() => _wantSameWorkout = v)),
          _switchTile('O objetivo é treinar juntos (mesmo com exercícios diferentes)?', _wantToTrainTogether, (v) => setState(() => _wantToTrainTogether = v)),
          const SizedBox(height: 16),
          Text('Grau de sincronização', style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 12)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: SyncLevel.values.map((s) =>
              ChoiceChip(
                label: Text(s.name, style: GoogleFonts.outfit(fontSize: 12)),
                selected: _syncLevel == s,
                selectedColor: AppTheme.accent,
                backgroundColor: AppTheme.surfaceHighlight,
                onSelected: (_) => setState(() => _syncLevel = s),
              ),
            ).toList(),
          ),
          const SizedBox(height: 16),
          Text('Relação', style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 12)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: ParticipantRelation.values.map((r) =>
              ChoiceChip(
                label: Text(_relationLabel(r), style: GoogleFonts.outfit(fontSize: 12)),
                selected: _relation == r,
                selectedColor: AppTheme.accent,
                backgroundColor: AppTheme.surfaceHighlight,
                onSelected: (_) => setState(() => _relation = r),
              ),
            ).toList(),
          ),
          const SizedBox(height: 32),
          _nextButton(() => setState(() => _step++)),
        ],
      ),
    );
  }

  Widget _buildSummaryStep() {
    final duo = _buildProfile();
    final compat = duo.compatibility;
    final compatLabel = compat == CompatibilityLevel.high ? 'Alta' :
        compat == CompatibilityLevel.medium ? 'Média' : 'Baixa';
    final compatColor = compat == CompatibilityLevel.high ? AppTheme.success :
        compat == CompatibilityLevel.medium ? const Color(0xFFF59E0B) : AppTheme.danger;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: ListView(
        children: [
          Text('Resumo da Dupla', style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: compatColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: compatColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.analytics_rounded, color: compatColor, size: 24),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Compatibilidade: $compatLabel', style: GoogleFonts.outfit(color: compatColor, fontWeight: FontWeight.bold)),
                    Text('Sincronização: ${_syncLevel.name}', style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _summaryRow('Pessoa A', '${_nameA.isEmpty ? "A" : _nameA} — ${_goalA.replaceAll("_", " ")} — ${_levelA}'),
          _summaryRow('Pessoa B', '${_nameB.isEmpty ? "B" : _nameB} — ${_goalB.replaceAll("_", " ")} — ${_levelB}'),
          _summaryRow('Mesmo treino?', _wantSameWorkout ? 'Sim' : 'Não'),
          _summaryRow('Sincronização', _syncLevel.name),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final provider = context.read<CollectiveProfileProvider>();
                final duo = _buildProfile();
                await provider.saveDuoProfile(duo);
                await provider.generateDuoSession(duo);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(provider.currentBlocks != null
                          ? 'Treino da dupla gerado! ${provider.currentBlocks!.length} blocos criados.'
                          : 'Dupla configurada com sucesso!'),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent, padding: const EdgeInsets.symmetric(vertical: 16)),
              child: Text('GERAR TREINO DA DUPLA', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────

  Widget _inputField(String hint, ValueChanged<String> onChanged) {
    return TextField(
      onChanged: onChanged,
      style: GoogleFonts.outfit(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.outfit(color: AppTheme.textSecondary),
        filled: true, fillColor: AppTheme.surfaceHighlight,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _numberField(String label, int value, ValueChanged<int> onChanged) {
    return Row(
      children: [
        Text('$label: ', style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 14)),
        IconButton(
          icon: const Icon(Icons.remove_circle_outline, size: 20),
          color: AppTheme.textSecondary,
          onPressed: () => onChanged(max(13, value - 1)),
        ),
        Text('$value', style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        IconButton(
          icon: const Icon(Icons.add_circle_outline, size: 20),
          color: AppTheme.accent,
          onPressed: () => onChanged(min(100, value + 1)),
        ),
      ],
    );
  }

  Widget _switchTile(String label, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      title: Text(label, style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontSize: 13)),
      value: value,
      activeColor: AppTheme.accent,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text('$label: ', style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 13)),
          Expanded(child: Text(value, style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _nextButton(VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent, padding: const EdgeInsets.symmetric(vertical: 16)),
        child: Text(_step < 4 ? 'PRÓXIMO' : 'CONFIRMAR', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  String _relationLabel(ParticipantRelation r) {
    switch (r) {
      case ParticipantRelation.couple: return 'Casal';
      case ParticipantRelation.friends: return 'Amigos';
      case ParticipantRelation.family: return 'Familiares';
      case ParticipantRelation.trainingPartner: return 'Parceiros';
      case ParticipantRelation.athletes: return 'Atletas';
      case ParticipantRelation.other: return 'Outro';
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// QUESTIONÁRIO DE GRUPO
// ═══════════════════════════════════════════════════════════════

class GroupQuestionnaireScreen extends StatefulWidget {
  const GroupQuestionnaireScreen({super.key});

  @override
  State<GroupQuestionnaireScreen> createState() => _GroupQuestionnaireScreenState();
}

class _GroupQuestionnaireScreenState extends State<GroupQuestionnaireScreen> {
  int _step = 0;
  int _participantCount = 3;
  String _collectiveGoal = 'hypertrophy';
  SyncLevel _syncLevel = SyncLevel.medium;
  bool _wantToFinishTogether = true;
  bool _allowDifferentExercises = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textPrimary, size: 20),
          onPressed: () {
            if (_step > 0) setState(() => _step--);
            else Navigator.pop(context);
          },
        ),
        title: Text(
          'GRUPO — PASSO ${_step + 1} de 3',
          style: GoogleFonts.outfit(
            color: AppTheme.textPrimary, fontSize: 12,
            fontWeight: FontWeight.w900, letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body: _buildStep(),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0: return _buildCountStep();
      case 1: return _buildCollectiveStep();
      case 2: return _buildSummaryStep();
      default: return const SizedBox();
    }
  }

  Widget _buildCountStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quantas pessoas?', style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, size: 28),
                color: AppTheme.textSecondary,
                onPressed: () => setState(() => _participantCount = max(2, _participantCount - 1)),
              ),
              const SizedBox(width: 24),
              Text('$_participantCount', style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontSize: 48, fontWeight: FontWeight.bold)),
              const SizedBox(width: 24),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 28),
                color: AppTheme.accent,
                onPressed: () => setState(() => _participantCount = min(20, _participantCount + 1)),
              ),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => setState(() => _step++),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent, padding: const EdgeInsets.symmetric(vertical: 16)),
              child: Text('PRÓXIMO', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollectiveStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: ListView(
        children: [
          Text('Preferências do grupo', style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Text('Objetivo coletivo', style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 12)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: ['hypertrophy', 'strength', 'fat_loss', 'general_health'].map((g) =>
              ChoiceChip(
                label: Text(g.replaceAll('_', ' '), style: GoogleFonts.outfit(fontSize: 12)),
                selected: _collectiveGoal == g,
                selectedColor: AppTheme.accent,
                backgroundColor: AppTheme.surfaceHighlight,
                onSelected: (_) => setState(() => _collectiveGoal = g),
              ),
            ).toList(),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: Text('Todos terminam juntos?', style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontSize: 13)),
            value: _wantToFinishTogether,
            activeColor: AppTheme.accent,
            onChanged: (v) => setState(() => _wantToFinishTogether = v),
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            title: Text('Exercícios diferentes são permitidos?', style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontSize: 13)),
            value: _allowDifferentExercises,
            activeColor: AppTheme.accent,
            onChanged: (v) => setState(() => _allowDifferentExercises = v),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 16),
          Text('Sincronização', style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 12)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: SyncLevel.values.map((s) =>
              ChoiceChip(
                label: Text(s.name, style: GoogleFonts.outfit(fontSize: 12)),
                selected: _syncLevel == s,
                selectedColor: AppTheme.accent,
                backgroundColor: AppTheme.surfaceHighlight,
                onSelected: (_) => setState(() => _syncLevel = s),
              ),
            ).toList(),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => setState(() => _step++),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent, padding: const EdgeInsets.symmetric(vertical: 16)),
              child: Text('CONFIRMAR', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: ListView(
        children: [
          Text('Resumo do Grupo', style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _summaryRow('Participantes', '$_participantCount pessoas'),
          _summaryRow('Objetivo', _collectiveGoal.replaceAll('_', ' ')),
          _summaryRow('Sincronização', _syncLevel.name),
          _summaryRow('Exercícios diferentes', _allowDifferentExercises ? 'Sim' : 'Não'),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final provider = context.read<CollectiveProfileProvider>();
                final group = GroupProfile(
                  name: 'Grupo',
                  participants: List.generate(_participantCount, (i) => ParticipantProfile(
                    name: 'P${i + 1}', age: 25, biologicalSex: 'male', weightKg: 70,
                    heightCm: 170, experienceLevel: 'beginner', trainingAge: 0,
                    primaryGoal: _collectiveGoal, environment: 'full_gym',
                    availableEquipment: [], healthRestrictions: [],
                    sessionDurationMinutes: 60,
                  )),
                  collectiveGoal: _collectiveGoal,
                  targetDurationMinutes: 60,
                  targetFrequencyPerWeek: 3,
                  environment: 'full_gym',
                  availableEquipment: [],
                  wantToFinishTogether: _wantToFinishTogether,
                  allowDifferentExercises: _allowDifferentExercises,
                  syncLevel: _syncLevel,
                  collectiveLevel: 'beginner',
                  levelDifference: 'small',
                );
                await provider.saveGroupProfile(group);
                await provider.generateGroupSession(group);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(provider.currentBlocks != null
                          ? 'Treino do grupo gerado! ${provider.currentBlocks!.length} blocos criados.'
                          : 'Grupo configurado com sucesso!'),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent, padding: const EdgeInsets.symmetric(vertical: 16)),
              child: Text('GERAR TREINO DO GRUPO', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text('$label: ', style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 13)),
          Expanded(child: Text(value, style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
