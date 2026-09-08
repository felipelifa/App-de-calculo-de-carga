/// Níveis de dificuldade do exercício.
/// 5 níveis representando demanda geral necessária.
enum V2Difficulty {
  level1,
  level2,
  level3,
  level4,
  level5,
}

extension V2DifficultyX on V2Difficulty {
  int get numeric => index + 1;

  static V2Difficulty fromLevel(int level) {
    return V2Difficulty.values[(level - 1).clamp(0, 4)];
  }
}
