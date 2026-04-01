import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import '../../shared/theme/app_theme.dart';
import 'analytics_service.dart';

// ─────────────────────────────────────────────
// Tela principal de Analytics
// ─────────────────────────────────────────────

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  Future<AnalyticsData>? _future;
  late TabController _tabController;

  // Para o gráfico de carga por exercício
  String? _selectedExerciseId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _load() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    setState(() {
      _future = AnalyticsService(
        db: FirebaseFirestore.instance,
        uid: uid,
      ).load();
      _selectedExerciseId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: const Text(
          'Estatísticas',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: BackButton(color: AppTheme.textSecondary),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.textSecondary),
            onPressed: _load,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(49),
          child: Column(
            children: [
              Container(height: 1, color: Colors.white.withValues(alpha: 0.06)),
              TabBar(
                controller: _tabController,
                indicatorColor: AppTheme.accent,
                indicatorWeight: 2,
                labelColor: AppTheme.accent,
                unselectedLabelColor: AppTheme.textSecondary,
                labelStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                tabs: const [
                  Tab(text: 'VOLUME'),
                  Tab(text: 'CARGA'),
                  Tab(text: 'MÚSCULOS'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: FutureBuilder<AnalyticsData>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const _LoadingState();
          }
          if (snap.hasError || !snap.hasData) {
            return _ErrorState(onRetry: _load);
          }

          final data = snap.data!;

          if (data.weeklyVolume.isEmpty) {
            return const _EmptyState();
          }

          return TabBarView(
            controller: _tabController,
            children: [
              // Tab 1 — Volume semanal
              _VolumeTab(data: data),

              // Tab 2 — Evolução de carga
              _LoadTab(
                data: data,
                selectedId: _selectedExerciseId,
                onSelectExercise: (id) {
                  setState(() {
                    _selectedExerciseId = id;
                  });
                },
              ),

              // Tab 3 — Volume por músculo
              _MuscleTab(data: data),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Tab 1 — Volume Semanal
// ─────────────────────────────────────────────

class _VolumeTab extends StatelessWidget {
  final AnalyticsData data;
  const _VolumeTab({required this.data});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Stats rápidos
        _QuickStatsRow(data: data),
        const SizedBox(height: 20),

        // Gráfico de linha — volume semanal
        _ChartCard(
          title: 'Volume por Semana',
          subtitle: 'Últimas ${data.weeklyVolume.length} semanas • kg totais',
          child: SfCartesianChart(
            plotAreaBorderWidth: 0,
            primaryXAxis: CategoryAxis(
              labelStyle: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 10,
              ),
              axisLine: const AxisLine(width: 0),
              majorTickLines: const MajorTickLines(size: 0),
              majorGridLines: const MajorGridLines(width: 0),
            ),
            primaryYAxis: NumericAxis(
              labelStyle: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 10,
              ),
              axisLine: const AxisLine(width: 0),
              majorTickLines: const MajorTickLines(size: 0),
              majorGridLines: MajorGridLines(
                color: Colors.white.withValues(alpha: 0.05),
              ),
              numberFormat: NumberFormat.compact(),
            ),
            tooltipBehavior: TooltipBehavior(
              enable: true,
              color: AppTheme.surfaceHighlight,
              textStyle: const TextStyle(color: AppTheme.textPrimary),
              format: 'point.x\npoint.y kg',
            ),
            series: <CartesianSeries>[
              // Área preenchida
              AreaSeries<WeeklyVolumePoint, String>(
                dataSource: data.weeklyVolume,
                xValueMapper: (p, _) => 'S${p.weekNumber}',
                yValueMapper: (p, _) => p.volume,
                gradient: LinearGradient(
                  colors: [
                    AppTheme.accent.withValues(alpha: 0.3),
                    AppTheme.accent.withValues(alpha: 0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderWidth: 0,
              ),
              // Linha principal
              SplineSeries<WeeklyVolumePoint, String>(
                dataSource: data.weeklyVolume,
                xValueMapper: (p, _) => 'S${p.weekNumber}',
                yValueMapper: (p, _) => p.volume,
                color: AppTheme.accent,
                width: 2.5,
                splineType: SplineType.monotonic,
                markerSettings: MarkerSettings(
                  isVisible: true,
                  color: AppTheme.accent,
                  borderColor: AppTheme.background,
                  borderWidth: 2,
                  height: 7,
                  width: 7,
                ),
                enableTooltip: true,
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Tabela de semanas
        _WeeklyTable(data: data),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Tab 2 — Evolução de Carga
// ─────────────────────────────────────────────

class _LoadTab extends StatelessWidget {
  final AnalyticsData data;
  final String? selectedId;
  final ValueChanged<String?> onSelectExercise;

  const _LoadTab({
    required this.data,
    required this.selectedId,
    required this.onSelectExercise,
  });

  @override
  Widget build(BuildContext context) {
    final exercises = data.exercises;

    if (exercises.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.show_chart_rounded,
                  size: 48, color: AppTheme.textSecondary.withValues(alpha: 0.4)),
              const SizedBox(height: 16),
              const Text(
                'Nenhum exercício com\n2 ou mais registros ainda.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 15),
              ),
            ],
          ),
        ),
      );
    }

    final activeId = selectedId ?? exercises.first.id;
    final activeExercise = exercises.firstWhere(
      (e) => e.id == activeId,
      orElse: () => exercises.first,
    );
    final points = data.exerciseLoad[activeId] ?? [];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Seletor de exercício
        _ExerciseSelector(
          exercises: exercises,
          selectedId: activeId,
          onSelect: onSelectExercise,
        ),

        const SizedBox(height: 16),

        // Gráfico de carga
        _ChartCard(
          title: activeExercise.name,
          subtitle: '${activeExercise.muscleGroup} • Evolução de peso (kg)',
          child: points.length < 2
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text(
                      'Registros insuficientes\npara este exercício.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                )
              : SfCartesianChart(
                  plotAreaBorderWidth: 0,
                  legend: Legend(
                    isVisible: true,
                    textStyle: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  primaryXAxis: DateTimeAxis(
                    labelStyle: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 10,
                    ),
                    axisLine: const AxisLine(width: 0),
                    majorTickLines: const MajorTickLines(size: 0),
                    majorGridLines: const MajorGridLines(width: 0),
                    dateFormat: DateFormat('dd/MM'),
                    intervalType: DateTimeIntervalType.days,
                  ),
                  primaryYAxis: NumericAxis(
                    labelStyle: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 10,
                    ),
                    axisLine: const AxisLine(width: 0),
                    majorTickLines: const MajorTickLines(size: 0),
                    majorGridLines: MajorGridLines(
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                    labelFormat: '{value} kg',
                  ),
                  tooltipBehavior: TooltipBehavior(
                    enable: true,
                    color: AppTheme.surfaceHighlight,
                    textStyle: const TextStyle(color: AppTheme.textPrimary),
                  ),
                  series: <CartesianSeries>[
                    SplineSeries<ExerciseLoadPoint, DateTime>(
                      name: 'Carga máx.',
                      dataSource: points,
                      xValueMapper: (p, _) => p.date,
                      yValueMapper: (p, _) => p.maxWeight,
                      color: AppTheme.accent,
                      width: 2.5,
                      splineType: SplineType.monotonic,
                      markerSettings: MarkerSettings(
                        isVisible: true,
                        color: AppTheme.accent,
                        borderColor: AppTheme.background,
                        borderWidth: 2,
                        height: 7,
                        width: 7,
                      ),
                    ),
                    SplineSeries<ExerciseLoadPoint, DateTime>(
                      name: 'Carga média',
                      dataSource: points,
                      xValueMapper: (p, _) => p.date,
                      yValueMapper: (p, _) => p.avgWeight,
                      color: AppTheme.success.withValues(alpha: 0.7),
                      width: 2,
                      dashArray: const <double>[5, 4],
                      splineType: SplineType.monotonic,
                      markerSettings: MarkerSettings(
                        isVisible: true,
                        color: AppTheme.success,
                        borderColor: AppTheme.background,
                        borderWidth: 2,
                        height: 5,
                        width: 5,
                      ),
                    ),
                  ],
                ),
        ),

        const SizedBox(height: 16),

        // PR destacado
        if (points.isNotEmpty) _PrCard(points: points, name: activeExercise.name),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Tab 3 — Volume por Músculo
// ─────────────────────────────────────────────

class _MuscleTab extends StatelessWidget {
  final AnalyticsData data;
  const _MuscleTab({required this.data});

  static const Map<String, Color> _colors = {
    'Peito': Color(0xFF6366F1),
    'Costas': Color(0xFF0EA5E9),
    'Ombro': Color(0xFF8B5CF6),
    'Bíceps': Color(0xFF10B981),
    'Tríceps': Color(0xFF14B8A6),
    'Quadríceps': Color(0xFFF59E0B),
    'Posterior': Color(0xFFEF4444),
    'Glúteo': Color(0xFFEC4899),
    'Core': Color(0xFFF97316),
    'Panturrilha': Color(0xFF84CC16),
  };

  @override
  Widget build(BuildContext context) {
    if (data.muscleVolume.isEmpty) {
      return const _EmptyState();
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Legenda temporal
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Row(
            children: [
              Container(width: 12, height: 12, color: AppTheme.accent),
              const SizedBox(width: 8),
              const Text('Últimas 4 semanas',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              const SizedBox(width: 20),
              Container(width: 12, height: 12, color: AppTheme.textSecondary.withValues(alpha: 0.4)),
              const SizedBox(width: 8),
              const Text('4 semanas anteriores',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Gráfico de barras agrupadas
        _ChartCard(
          title: 'Volume por Grupo Muscular',
          subtitle: 'Comparativo últimas 4 semanas vs 4 anteriores • kg',
          child: SfCartesianChart(
            plotAreaBorderWidth: 0,
            primaryXAxis: CategoryAxis(
              labelStyle: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 10,
              ),
              axisLine: const AxisLine(width: 0),
              majorTickLines: const MajorTickLines(size: 0),
              majorGridLines: const MajorGridLines(width: 0),
            ),
            primaryYAxis: NumericAxis(
              labelStyle: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 10,
              ),
              axisLine: const AxisLine(width: 0),
              majorTickLines: const MajorTickLines(size: 0),
              majorGridLines: MajorGridLines(
                color: Colors.white.withValues(alpha: 0.05),
              ),
              numberFormat: NumberFormat.compact(),
            ),
            tooltipBehavior: TooltipBehavior(
              enable: true,
              color: AppTheme.surfaceHighlight,
              textStyle: const TextStyle(color: AppTheme.textPrimary),
              format: 'point.x\npoint.y kg',
            ),
            series: <CartesianSeries>[
              ColumnSeries<MuscleVolumeBar, String>(
                name: 'Atual',
                dataSource: data.muscleVolume,
                xValueMapper: (d, _) => d.muscle,
                yValueMapper: (d, _) => d.volume,
                color: AppTheme.accent,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
                spacing: 0.1,
                width: 0.4,
              ),
              ColumnSeries<MuscleVolumeBar, String>(
                name: 'Anterior',
                dataSource: data.muscleVolume,
                xValueMapper: (d, _) => d.muscle,
                yValueMapper: (d, _) => d.lastPeriodVolume,
                color: AppTheme.textSecondary.withValues(alpha: 0.35),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
                spacing: 0.1,
                width: 0.4,
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Lista com barras horizontais + delta
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Label('DETALHE POR MÚSCULO'),
              const SizedBox(height: 16),
              ...data.muscleVolume.map((bar) {
                final color = _colors[bar.muscle] ?? AppTheme.accent;
                final hasPrev = bar.lastPeriodVolume > 0;
                final delta = hasPrev
                    ? ((bar.volume - bar.lastPeriodVolume) /
                            bar.lastPeriodVolume *
                            100)
                        .round()
                    : null;
                final isUp = delta != null && delta >= 0;
                final maxVol =
                    data.muscleVolume.first.volume; // já ordenado por volume

                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              bar.muscle,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Text(
                            '${bar.volume.toStringAsFixed(0)} kg',
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          if (delta != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isUp
                                    ? AppTheme.success.withValues(alpha: 0.15)
                                    : AppTheme.danger.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${delta >= 0 ? '+' : ''}$delta%',
                                style: TextStyle(
                                  color: isUp ? AppTheme.success : AppTheme.danger,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: maxVol > 0 ? bar.volume / maxVol : 0,
                          backgroundColor: color.withValues(alpha: 0.08),
                          valueColor: AlwaysStoppedAnimation(color),
                          minHeight: 5,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Componentes auxiliares
// ─────────────────────────────────────────────

class _QuickStatsRow extends StatelessWidget {
  final AnalyticsData data;
  const _QuickStatsRow({required this.data});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatChip(
            label: 'Sessões',
            value: '${data.totalSessions}',
            icon: Icons.calendar_month_rounded,
            color: AppTheme.accent,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatChip(
            label: 'Volume total',
            value: '${(data.totalVolume / 1000).toStringAsFixed(1)}t',
            icon: Icons.fitness_center_rounded,
            color: const Color(0xFF8B5CF6),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatChip(
            label: 'Melhor semana',
            value: '${data.bestWeekVolume.toStringAsFixed(0)} kg',
            icon: Icons.emoji_events_rounded,
            color: const Color(0xFFF59E0B),
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(height: 220, child: child),
        ],
      ),
    );
  }
}

class _WeeklyTable extends StatelessWidget {
  final AnalyticsData data;
  const _WeeklyTable({required this.data});

  @override
  Widget build(BuildContext context) {
    final weeks = data.weeklyVolume.reversed.take(6).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Label('HISTÓRICO SEMANAL'),
          const SizedBox(height: 12),
          ...weeks.asMap().entries.map((entry) {
            final i = entry.key;
            final week = entry.value;
            final prev = i < weeks.length - 1 ? weeks[i + 1] : null;
            final delta = prev != null && prev.volume > 0
                ? ((week.volume - prev.volume) / prev.volume * 100).round()
                : null;
            final isUp = delta != null && delta >= 0;
            final isBest = week.weekNumber == data.bestWeekNumber;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isBest
                    ? const Color(0xFFF59E0B).withValues(alpha: 0.08)
                    : AppTheme.surfaceHighlight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isBest
                      ? const Color(0xFFF59E0B).withValues(alpha: 0.3)
                      : Colors.transparent,
                ),
              ),
              child: Row(
                children: [
                  if (isBest)
                    const Padding(
                      padding: EdgeInsets.only(right: 6),
                      child: Icon(Icons.emoji_events_rounded,
                          color: Color(0xFFF59E0B), size: 14),
                    ),
                  Text(
                    'Semana ${week.weekNumber}',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat('dd/MM').format(week.weekStart),
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  const Spacer(),
                  if (delta != null)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isUp
                            ? AppTheme.success.withValues(alpha: 0.12)
                            : AppTheme.danger.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${delta >= 0 ? '+' : ''}$delta%',
                        style: TextStyle(
                          color: isUp ? AppTheme.success : AppTheme.danger,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  Text(
                    '${week.volume.toStringAsFixed(0)} kg',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ExerciseSelector extends StatelessWidget {
  final List<ExerciseSummary> exercises;
  final String selectedId;
  final ValueChanged<String?> onSelect;

  const _ExerciseSelector({
    required this.exercises,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedId,
          isExpanded: true,
          dropdownColor: AppTheme.surfaceHighlight,
          icon: const Icon(Icons.expand_more_rounded, color: AppTheme.textSecondary),
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
          items: exercises
              .map((e) => DropdownMenuItem(
                    value: e.id,
                    child: Row(
                      children: [
                        Expanded(child: Text(e.name)),
                        Text(
                          e.muscleGroup,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ))
              .toList(),
          onChanged: onSelect,
        ),
      ),
    );
  }
}

class _PrCard extends StatelessWidget {
  final List<ExerciseLoadPoint> points;
  final String name;

  const _PrCard({required this.points, required this.name});

  @override
  Widget build(BuildContext context) {
    final maxPoint = points.reduce((a, b) => a.maxWeight > b.maxWeight ? a : b);
    final firstPoint = points.first;
    final lastPoint = points.last;
    final evolution = firstPoint.maxWeight > 0
        ? ((lastPoint.maxWeight - firstPoint.maxWeight) /
                firstPoint.maxWeight *
                100)
            .round()
        : 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFF59E0B).withValues(alpha: 0.12),
            AppTheme.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: Color(0xFFF59E0B),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Melhor marca (PR)',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
                Text(
                  '${maxPoint.maxWeight.toStringAsFixed(1)} kg',
                  style: const TextStyle(
                    color: Color(0xFFF59E0B),
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
                Text(
                  DateFormat('dd/MM/yyyy').format(maxPoint.date),
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (evolution != 0)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'Evolução total',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
                Text(
                  '${evolution >= 0 ? '+' : ''}$evolution%',
                  style: TextStyle(
                    color: evolution >= 0 ? AppTheme.success : AppTheme.danger,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ─── Estados de Loading / Erro / Vazio ──────

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppTheme.accent, strokeWidth: 2),
          SizedBox(height: 16),
          Text(
            'Carregando estatísticas...',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded,
                color: AppTheme.danger, size: 40),
            const SizedBox(height: 12),
            const Text(
              'Não foi possível carregar as estatísticas.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart_rounded,
                size: 56,
                color: AppTheme.textSecondary.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            const Text(
              'Nenhum dado ainda.',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Registre alguns treinos para\nver seus gráficos de evolução.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppTheme.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }
}
