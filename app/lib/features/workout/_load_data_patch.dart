  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final wpProvider = context.read<WorkoutProfileProvider>();
    final exerciseProvider = context.read<ExerciseProvider>();

    // ExerciseProvider agora carrega a biblioteca local imediatamente (sem async)
    // então isLoading já é false na prática — mas protegemos caso mude no futuro
    if (exerciseProvider.isLoading) {
      await Future.doWhile(() async {
        await Future.delayed(const Duration(milliseconds: 50));
        return exerciseProvider.isLoading && mounted;
      });
    }

    if (!mounted) return;

    // Sempre recarrega do Firestore — corrige exercícios sumindo após cancelar/deslogar
    // O _currentWorkoutRaw é limpo pelo _cleanup() no logout, então isso garante
    // que o treino seja re-hidratado corretamente na volta
    await wpProvider.loadCurrentWorkout(exerciseProvider.getById);

    if (mounted) {
      setState(() => _isChecking = false);
    }
  }