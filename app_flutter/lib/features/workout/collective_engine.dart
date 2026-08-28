import 'collective_training.dart';

/// Motor de treinamento coletivo.
///
/// Gera sessões para duplas e grupos, criando:
/// - Núcleo comum (exercícios que todos podem fazer)
/// - Divergência controlada (variações individuais quando necessário)
///
/// Princípio: qualidade individual > igualdade absoluta.
class CollectiveTrainingEngine {

  /// Gera sessão coletiva para uma dupla.
  List<CollectiveSessionBlock> buildDuoSession({
    required DuoProfile duo,
    required int sessionDurationMinutes,
  }) {
    final compat = duo.compatibility;
    final syncLevel = duo.syncLevel;

    // Determinar grau de sincronização baseado na compatibilidade e preferência
    final effectiveSync = _effectiveSyncLevel(compat, syncLevel);

    final blocks = <CollectiveSessionBlock>[];

    // Bloco 1: Aquecimento (sempre comum)
    blocks.add(_buildWarmupBlock(duo.personA, duo.personB));

    // Bloco 2: Composto principal
    blocks.add(_buildMainCompoundBlock(
      duo.personA, duo.personB, effectiveSync, sessionDurationMinutes,
    ));

    // Bloco 3: Trabalho acessório
    blocks.add(_buildAccessoryBlock(
      duo.personA, duo.personB, effectiveSync,
    ));

    // Bloco 4: Finalização
    blocks.add(_buildFinishBlock(duo.personA, duo.personB));

    return blocks;
  }

  /// Gera sessão coletiva para um grupo.
  List<CollectiveSessionBlock> buildGroupSession({
    required GroupProfile group,
  }) {
    final compat = group.compatibility;
    final syncLevel = group.syncLevel;
    final effectiveSync = _effectiveSyncLevel(compat, syncLevel);

    final blocks = <CollectiveSessionBlock>[];

    // Aquecimento comum
    blocks.add(_buildGroupWarmupBlock(group.participants));

    // Composto principal
    blocks.add(_buildGroupMainBlock(group.participants, effectiveSync, group));

    // Acessório
    blocks.add(_buildGroupAccessoryBlock(group.participants, effectiveSync));

    // Finalização
    blocks.add(_buildGroupFinishBlock(group.participants));

    return blocks;
  }

  // ── Lógica de sincronização ──────────────────────────────

  SyncLevel _effectiveSyncLevel(CompatibilityLevel compat, SyncLevel desired) {
    // Se compatibilidade é alta, sincronização desejada é respeitada.
    // Se compatibilidade é baixa, reduzir sincronização para preservar qualidade individual.
    switch (compat) {
      case CompatibilityLevel.high:
        return desired;
      case CompatibilityLevel.medium:
        return desired == SyncLevel.high ? SyncLevel.medium : desired;
      case CompatibilityLevel.low:
        return SyncLevel.low;
    }
  }

  // ── Blocos para dupla ────────────────────────────────────

  CollectiveSessionBlock _buildWarmupBlock(
      ParticipantProfile a, ParticipantProfile b) {
    // Aquecimento é sempre comum — mobilidade e ativação
    return CollectiveSessionBlock(
      blockName: 'aquecimento',
      isCommon: true,
      commonExerciseName: 'Mobilidade articular + ativação muscular',
    );
  }

  CollectiveSessionBlock _buildMainCompoundBlock(
    ParticipantProfile a,
    ParticipantProfile b,
    SyncLevel sync,
    int durationMinutes,
  ) {
    if (sync == SyncLevel.high || (a.primaryGoal == b.primaryGoal && a.experienceLevel == b.experienceLevel)) {
      // Alto sync: exercício comum com possível variação
      final commonPattern = _bestCommonPattern(a, b);
      return CollectiveSessionBlock(
        blockName: 'bloco_principal',
        isCommon: true,
        commonExerciseName: commonPattern,
        individualVariations: {
          a.name: _variationForPerson(a, commonPattern),
          b.name: _variationForPerson(b, commonPattern),
        },
      );
    }

    // Sync médio/baixo: exercícios diferentes mas no mesmo bloco
    return CollectiveSessionBlock(
      blockName: 'bloco_principal',
      isCommon: false,
      individualVariations: {
        a.name: _bestExerciseForPerson(a),
        b.name: _bestExerciseForPerson(b),
      },
      individualSets: {
        a.name: _setsForGoal(a.primaryGoal),
        b.name: _setsForGoal(b.primaryGoal),
      },
      individualReps: {
        a.name: _repsForGoal(a.primaryGoal),
        b.name: _repsForGoal(b.primaryGoal),
      },
    );
  }

  CollectiveSessionBlock _buildAccessoryBlock(
    ParticipantProfile a,
    ParticipantProfile b,
    SyncLevel sync,
  ) {
    if (sync == SyncLevel.high && a.primaryGoal == b.primaryGoal) {
      return CollectiveSessionBlock(
        blockName: 'bloco_acessorio',
        isCommon: true,
        commonExerciseName: 'Trabalho acessório complementar',
      );
    }

    return CollectiveSessionBlock(
      blockName: 'bloco_acessorio',
      isCommon: false,
      individualVariations: {
        a.name: _accessoryForPerson(a),
        b.name: _accessoryForPerson(b),
      },
    );
  }

  CollectiveSessionBlock _buildFinishBlock(
      ParticipantProfile a, ParticipantProfile b) {
    // Finalização comum: mobilidade e voltagem
    return CollectiveSessionBlock(
      blockName: 'finalizacao',
      isCommon: true,
      commonExerciseName: 'Mobilidade e relaxamento',
    );
  }

  // ── Blocos para grupo ────────────────────────────────────

  CollectiveSessionBlock _buildGroupWarmupBlock(List<ParticipantProfile> participants) {
    return CollectiveSessionBlock(
      blockName: 'aquecimento',
      isCommon: true,
      commonExerciseName: 'Aquecimento grupal: mobilidade + ativação',
    );
  }

  CollectiveSessionBlock _buildGroupMainBlock(
    List<ParticipantProfile> participants,
    SyncLevel sync,
    GroupProfile group,
  ) {
    if (sync == SyncLevel.high || group.levelDifference == 'small') {
      // Alto sync: exercício comum com variações individuais
      final commonPattern = _bestCommonPatternForGroup(participants);
      final variations = <String, String>{};
      for (final p in participants) {
        variations[p.name] = _variationForPerson(p, commonPattern);
      }
      return CollectiveSessionBlock(
        blockName: 'bloco_principal',
        isCommon: true,
        commonExerciseName: commonPattern,
        individualVariations: variations,
      );
    }

    // Sync médio/baixo ou diferenças grandes: exercícios individuais
    final variations = <String, String>{};
    for (final p in participants) {
      variations[p.name] = _bestExerciseForPerson(p);
    }
    return CollectiveSessionBlock(
      blockName: 'bloco_principal',
      isCommon: false,
      individualVariations: variations,
    );
  }

  CollectiveSessionBlock _buildGroupAccessoryBlock(
      List<ParticipantProfile> participants, SyncLevel sync) {
    if (sync == SyncLevel.high) {
      return CollectiveSessionBlock(
        blockName: 'bloco_acessorio',
        isCommon: true,
        commonExerciseName: 'Trabalho acessório complementar',
      );
    }

    final variations = <String, String>{};
    for (final p in participants) {
      variations[p.name] = _accessoryForPerson(p);
    }
    return CollectiveSessionBlock(
      blockName: 'bloco_acessorio',
      isCommon: false,
      individualVariations: variations,
    );
  }

  CollectiveSessionBlock _buildGroupFinishBlock(List<ParticipantProfile> participants) {
    return CollectiveSessionBlock(
      blockName: 'finalizacao',
      isCommon: true,
      commonExerciseName: 'Mobilidade e relaxamento grupal',
    );
  }

  // ── Seleção de exercícios ────────────────────────────────

  String _bestCommonPattern(ParticipantProfile a, ParticipantProfile b) {
    // Busca padrão que ambos podem executar
    final commonGoals = {
      a.primaryGoal, b.primaryGoal,
    };
    if (commonGoals.length == 1) {
      final goal = commonGoals.first;
      switch (goal) {
        case 'hypertrophy': return 'Composto de empurrar';
        case 'strength': return 'Agachamento ou variante';
        case 'fat_loss': return 'Circuito funcional';
        case 'endurance': return 'Circuito de resistência';
        default: return 'Composto multiarticular';
      }
    }
    return 'Composto multiarticular';
  }

  String _bestCommonPatternForGroup(List<ParticipantProfile> participants) {
    // Busca padrão mais compatível com todos
    final goalCounts = <String, int>{};
    for (final p in participants) {
      goalCounts[p.primaryGoal] = (goalCounts[p.primaryGoal] ?? 0) + 1;
    }
    final mostCommonGoal = goalCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    return _bestCommonPattern(
      ParticipantProfile(
        name: 'temp', age: 25, biologicalSex: 'male', weightKg: 70,
        heightCm: 175, experienceLevel: 'beginner', trainingAge: 0,
        primaryGoal: mostCommonGoal, environment: 'full_gym',
        availableEquipment: [], healthRestrictions: [],
        sessionDurationMinutes: 60,
      ),
      ParticipantProfile(
        name: 'temp2', age: 25, biologicalSex: 'male', weightKg: 70,
        heightCm: 175, experienceLevel: 'beginner', trainingAge: 0,
        primaryGoal: mostCommonGoal, environment: 'full_gym',
        availableEquipment: [], healthRestrictions: [],
        sessionDurationMinutes: 60,
      ),
    );
  }

  String _variationForPerson(ParticipantProfile person, String commonPattern) {
    // Adapta o padrão comum para a pessoa
    if (person.healthRestrictions.isNotEmpty) {
      return '$commonPattern (regressão para ${person.healthRestrictions.first})';
    }
    if (person.experienceLevel == 'beginner') {
      return '$commonPattern (versão simplificada)';
    }
    if (person.age >= 55) {
      return '$commonPattern (com controle de amplitude)';
    }
    return commonPattern;
  }

  String _bestExerciseForPerson(ParticipantProfile person) {
    // Seleciona melhor exercício baseado no perfil individual
    if (person.primaryGoal == 'hypertrophy') return 'Composto de empurrar (3x10)';
    if (person.primaryGoal == 'strength') return 'Agachamento pesado (4x6)';
    if (person.primaryGoal == 'fat_loss') return 'Circuito funcional (3x15)';
    if (person.primaryGoal == 'endurance') return 'Circuito de resistência (2x20)';
    if (person.primaryGoal == 'general_health') return 'Exercícios funcionais (3x12)';
    return 'Composto multiarticular (3x10)';
  }

  String _accessoryForPerson(ParticipantProfile person) {
    if (person.primaryGoal == 'hypertrophy') return 'Isolamento complementar (3x12)';
    if (person.primaryGoal == 'strength') return 'Estabilidade e controle (3x8)';
    if (person.primaryGoal == 'fat_loss') return 'Exercício aeróbico (3x30s)';
    return 'Trabalho acessório (3x12)';
  }

  int _setsForGoal(String goal) {
    switch (goal) {
      case 'hypertrophy': return 3;
      case 'strength': return 4;
      case 'fat_loss': return 3;
      case 'endurance': return 2;
      default: return 3;
    }
  }

  int _repsForGoal(String goal) {
    switch (goal) {
      case 'hypertrophy': return 10;
      case 'strength': return 6;
      case 'fat_loss': return 15;
      case 'endurance': return 20;
      default: return 10;
    }
  }
}
