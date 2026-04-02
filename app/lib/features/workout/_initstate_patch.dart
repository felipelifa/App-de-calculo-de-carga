  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final wpProvider = context.read<WorkoutProfileProvider>();
    final exerciseProvider = context.read<ExerciseProvider>();

    // ExerciseProvider carrega a biblioteca local imediatamente (sem async)
    // mas protegemos caso ainda esteja carregando por qualquer razão
    if (exerciseProvider.isLoading) {
      await Future.doWhile(() async {
        await Future.delayed(const Duration(milliseconds: 50));
        return exerciseProvider.isLoading && mounted;
      });
    }

    if (!mounted) return;

    // Sempre recarrega do Firestore — corrige exercícios sumindo após cancelar/deslogar
    await wpProvider.loadCurrentWorkout(exerciseProvider.getById);

    if (mounted) {
      setState(() => _isChecking = false);
    }
  }