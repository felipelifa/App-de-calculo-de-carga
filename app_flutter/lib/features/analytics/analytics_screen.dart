import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../shared/theme/app_theme.dart';
import 'analytics_service.dart';

// ─────────────────────────────────────────────
// Tela principal de Analytics — Redesenhada (Premium Neon)
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

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverAppBar(
                backgroundColor: AppTheme.background,
                expandedHeight: 120,
                floating: true,
                pinned: true,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textPrimary, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  title: Text(
                    'ESTATÍSTICAS',
                    style: GoogleFonts.outfit(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: AppTheme.textSecondary),
                    onPressed: _load,
                  ),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(48),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicatorColor: const Color(0xFFCCFF00),
                      indicatorWeight: 3,
                      indicatorSize: TabBarIndicatorSize.label,
                      labelColor: const Color(0xFFCCFF00),
                      unselectedLabelColor: AppTheme.textSecondary,
                      labelStyle: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                      tabs: const [
                        Tab(text: 'TREINOS'),
                        Tab(text: 'PESO'),
                        Tab(text: 'MÚSCULOS'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                _VolumeTab(data: data),
                _LoadTab(
                  data: data,
                  selectedId: _selectedExerciseId,
                  onSelectExercise: (id) {
                    setState(() {
                      _selectedExerciseId = id;
                    });
                  },
                ),
                _MuscleTab(data: data),
              ],
            ),
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      children: [
        // Stats rápidos
        _QuickStatsRow(data: data).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
        const SizedBox(height: 32),

        // Gráfico de linha — volume semanal
        _ChartCard(
          title: 'HISTÓRICO DE TREINOS',
          subtitle: 'Volume total semanal (toneladas)',
          child: SfCartesianChart(
            plotAreaBorderWidth: 0,
            margin: EdgeInsets.zero,
            primaryXAxis: CategoryAxis(
              labelStyle: GoogleFonts.outfit(
                color: AppTheme.textSecondary.withValues(alpha: 0.5),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              axisLine: const AxisLine(width: 0),
              majorTickLines: const MajorTickLines(size: 0),
              majorGridLines: const MajorGridLines(width: 0),
            ),
            primaryYAxis: NumericAxis(
              labelStyle: GoogleFonts.outfit(
                color: AppTheme.textSecondary.withValues(alpha: 0.5),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              axisLine: const AxisLine(width: 0),
              majorTickLines: const MajorTickLines(size: 0),
              majorGridLines: MajorGridLines(
                color: Colors.white.withValues(alpha: 0.03),
                width: 1,
              ),
              numberFormat: NumberFormat.compact(),
            ),
            tooltipBehavior: TooltipBehavior(
              enable: true,
              color: const Color(0xFF161616),
              textStyle: GoogleFonts.outfit(color: AppTheme.textPrimary, fontSize: 12),
              format: 'point.x: point.y kg',
              shouldAlwaysShow: false,
              canShowMarker: true,
            ),
            series: <CartesianSeries>[
              AreaSeries<WeeklyVolumePoint, String>(
                dataSource: data.weeklyVolume,
                xValueMapper: (p, _) => 'S${p.weekNumber}',
                yValueMapper: (p, _) => p.volume,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFCCFF00).withValues(alpha: 0.2),
                    const Color(0xFFCCFF00).withValues(alpha: 0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderWidth: 0,
                animationDuration: 1500,
              ),
              SplineSeries<WeeklyVolumePoint, String>(
                dataSource: data.weeklyVolume,
                xValueMapper: (p, _) => 'S${p.weekNumber}',
                yValueMapper: (p, _) => p.volume,
                color: const Color(0xFFCCFF00),
                width: 3,
                splineType: SplineType.monotonic,
                markerSettings: const MarkerSettings(
                  isVisible: true,
                  color: Color(0xFFCCFF00),
                  borderColor: AppTheme.background,
                  borderWidth: 2,
                  height: 8,
                  width: 8,
                ),
                enableTooltip: true,
                animationDuration: 1500,
              ),
            ],
          ),
        ).animate().fadeIn(duration: 500.ms, delay: 100.ms).slideY(begin: 0.1),

        const SizedBox(height: 32),

        // Tabela de semanas
        _WeeklyTable(data: data).animate().fadeIn(duration: 500.ms, delay: 200.ms).slideY(begin: 0.1),
        const SizedBox(height: 48),
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
                  size: 64, color: AppTheme.textSecondary.withValues(alpha: 0.2)),
              const SizedBox(height: 24),
              Text(
                'HISTÓRICO INSUFICIENTE',
                style: GoogleFonts.outfit(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Complete mais treinos para visualizar a evolução de carga por exercício.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 13),
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      children: [
        // Seletor de exercício
        Text(
          'SELECIONE O EXERCÍCIO',
          style: GoogleFonts.outfit(
            color: AppTheme.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ).animate().fadeIn(),
        const SizedBox(height: 12),
        _ExerciseSelector(
          exercises: exercises,
          selectedId: activeId,
          onSelect: onSelectExercise,
        ).animate().fadeIn().slideX(begin: 0.05),

        const SizedBox(height: 32),

        // Gráfico de carga
        _ChartCard(
          title: activeExercise.name.toUpperCase(),
          subtitle: '${_translateMuscle(activeExercise.muscleGroup)} • Evolução do Peso (kg)',
          child: points.length < 2
              ? Center(
                  child: Text(
                    'DADOS INSUFICIENTES',
                    style: GoogleFonts.outfit(color: AppTheme.textSecondary.withValues(alpha: 0.5), fontWeight: FontWeight.bold),
                  ),
                )
              : SfCartesianChart(
                  plotAreaBorderWidth: 0,
                  margin: EdgeInsets.zero,
                  legend: Legend(
                    isVisible: true,
                    position: LegendPosition.top,
                    alignment: ChartAlignment.center,
                    textStyle: GoogleFonts.outfit(
                      color: AppTheme.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  primaryXAxis: DateTimeAxis(
                    labelStyle: GoogleFonts.outfit(
                      color: AppTheme.textSecondary.withValues(alpha: 0.5),
                      fontSize: 10,
                    ),
                    axisLine: const AxisLine(width: 0),
                    majorTickLines: const MajorTickLines(size: 0),
                    majorGridLines: const MajorGridLines(width: 0),
                    dateFormat: DateFormat('dd/MM'),
                    intervalType: DateTimeIntervalType.days,
                  ),
                  primaryYAxis: NumericAxis(
                    labelStyle: GoogleFonts.outfit(
                      color: AppTheme.textSecondary.withValues(alpha: 0.5),
                      fontSize: 10,
                    ),
                    axisLine: const AxisLine(width: 0),
                    majorTickLines: const MajorTickLines(size: 0),
                    majorGridLines: MajorGridLines(
                      color: Colors.white.withValues(alpha: 0.03),
                    ),
                    labelFormat: '{value} kg',
                  ),
                  tooltipBehavior: TooltipBehavior(
                    enable: true,
                    color: const Color(0xFF161616),
                    textStyle: GoogleFonts.outfit(color: AppTheme.textPrimary),
                  ),
                  series: <CartesianSeries>[
                    SplineSeries<ExerciseLoadPoint, DateTime>(
                      name: 'Carga Máxima',
                      dataSource: points,
                      xValueMapper: (p, _) => p.date,
                      yValueMapper: (p, _) => p.maxWeight,
                      color: const Color(0xFFCCFF00),
                      width: 3,
                      splineType: SplineType.monotonic,
                      markerSettings: const MarkerSettings(
                        isVisible: true,
                        color: Color(0xFFCCFF00),
                        borderColor: AppTheme.background,
                        borderWidth: 2,
                        height: 8,
                        width: 8,
                      ),
                      animationDuration: 1500,
                    ),
                    SplineSeries<ExerciseLoadPoint, DateTime>(
                      name: 'Carga Média',
                      dataSource: points,
                      xValueMapper: (p, _) => p.date,
                      yValueMapper: (p, _) => p.avgWeight,
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.6),
                      width: 2,
                      dashArray: const <double>[6, 4],
                      splineType: SplineType.monotonic,
                      markerSettings: const MarkerSettings(
                        isVisible: true,
                        color: Color(0xFF00E5FF),
                        borderColor: AppTheme.background,
                        borderWidth: 1.5,
                        height: 6,
                        width: 6,
                      ),
                      animationDuration: 1500,
                    ),
                  ],
                ),
        ).animate().fadeIn(duration: 500.ms, delay: 100.ms).slideY(begin: 0.1),

        const SizedBox(height: 24),

        // PR destacado
        if (points.isNotEmpty) 
          _PrCard(points: points, name: activeExercise.name)
            .animate().fadeIn(duration: 500.ms, delay: 200.ms).slideY(begin: 0.1),
        
        const SizedBox(height: 48),
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
    'Peito': Color(0xFFCCFF00),
    'Costas': Color(0xFF00E5FF),
    'Ombro': Color(0xFFFE2D55),
    'Bíceps': Color(0xFFA855F7),
    'Tríceps': Color(0xFFF97316),
    'Quadríceps': Color(0xFF22C55E),
    'Posterior': Color(0xFF3B82FF),
    'Glúteo': Color(0xFFEC4899),
    'Core': Color(0xFFFFD600),
    'Panturrilha': Color(0xFF94A3B8),
  };

  @override
  Widget build(BuildContext context) {
    if (data.muscleVolume.isEmpty) {
      return const _EmptyState();
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      children: [
        // Legenda temporal
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF161616),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.02)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('Atual (4 sem)', const Color(0xFFCCFF00)),
              const SizedBox(width: 24),
              _buildLegendItem('Anterior', AppTheme.textSecondary.withValues(alpha: 0.3)),
            ],
          ),
        ).animate().fadeIn(),

        const SizedBox(height: 32),

        // Gráfico de barras agrupadas
        _ChartCard(
          title: 'FOCO POR MÚSCULO',
          subtitle: 'Distribuição de volume (kg)',
          child: SfCartesianChart(
            plotAreaBorderWidth: 0,
            margin: EdgeInsets.zero,
            primaryXAxis: CategoryAxis(
              labelStyle: GoogleFonts.outfit(
                color: AppTheme.textSecondary.withValues(alpha: 0.5),
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
              axisLine: const AxisLine(width: 0),
              majorTickLines: const MajorTickLines(size: 0),
              majorGridLines: const MajorGridLines(width: 0),
              labelRotation: -45,
            ),
            primaryYAxis: NumericAxis(
              labelStyle: GoogleFonts.outfit(
                color: AppTheme.textSecondary.withValues(alpha: 0.5),
                fontSize: 10,
              ),
              axisLine: const AxisLine(width: 0),
              majorTickLines: const MajorTickLines(size: 0),
              majorGridLines: MajorGridLines(
                color: Colors.white.withValues(alpha: 0.03),
              ),
              numberFormat: NumberFormat.compact(),
            ),
            tooltipBehavior: TooltipBehavior(
              enable: true,
              color: const Color(0xFF161616),
              textStyle: GoogleFonts.outfit(color: Colors.white, fontSize: 12),
              builder: (data, point, series, pointIndex, seriesIndex) {
                 final bar = data as MuscleVolumeBar;
                 return Container(
                   padding: const EdgeInsets.all(10),
                   child: Text(
                     '${_translateMuscle(bar.muscle)}: ${bar.volume.toStringAsFixed(0)} kg',
                     style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                   ),
                 );
              },
            ),
            series: <CartesianSeries>[
              ColumnSeries<MuscleVolumeBar, String>(
                name: 'Atual',
                dataSource: data.muscleVolume,
                xValueMapper: (d, _) => _translateMuscle(d.muscle),
                yValueMapper: (d, _) => d.volume,
                color: const Color(0xFFCCFF00),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                spacing: 0.2,
                width: 0.5,
                animationDuration: 1500,
              ),
              ColumnSeries<MuscleVolumeBar, String>(
                name: 'Anterior',
                dataSource: data.muscleVolume,
                xValueMapper: (d, _) => _translateMuscle(d.muscle),
                yValueMapper: (d, _) => d.lastPeriodVolume,
                color: AppTheme.textSecondary.withValues(alpha: 0.15),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                spacing: 0.2,
                width: 0.5,
                animationDuration: 1500,
              ),
            ],
          ),
        ).animate().fadeIn(duration: 500.ms, delay: 100.ms).slideY(begin: 0.1),

        const SizedBox(height: 32),

        // Lista com barras horizontais + delta
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF161616),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.02)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DETALHE POR MÚSCULO',
                style: GoogleFonts.outfit(
                  color: AppTheme.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 24),
              ...data.muscleVolume.asMap().entries.map((entry) {
                final bar = entry.value;
                final color = _colors[bar.muscle] ?? const Color(0xFFCCFF00);
                final hasPrev = bar.lastPeriodVolume > 0;
                final delta = hasPrev
                    ? ((bar.volume - bar.lastPeriodVolume) /
                            bar.lastPeriodVolume *
                            100)
                        .round()
                    : null;
                final isUp = delta != null && delta >= 0;
                final maxVol = data.muscleVolume.isNotEmpty ? data.muscleVolume.first.volume : 1.0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(3),
                              boxShadow: [
                                BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8)
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _translateMuscle(bar.muscle),
                              style: GoogleFonts.outfit(
                                color: AppTheme.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            '${(bar.volume / 1000).toStringAsFixed(1)}t',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                          if (delta != null) ...[
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isUp
                                    ? const Color(0xFF22C55E).withValues(alpha: 0.1)
                                    : const Color(0xFFEF4444).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isUp ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                                    size: 10,
                                    color: isUp ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${delta.abs()}%',
                                    style: GoogleFonts.outfit(
                                      color: isUp ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: maxVol > 0 ? bar.volume / maxVol : 0,
                          backgroundColor: Colors.white.withValues(alpha: 0.05),
                          valueColor: AlwaysStoppedAnimation(color),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: (entry.key * 100).ms).slideX(begin: 0.05);
              }),
            ],
          ),
        ).animate().fadeIn(duration: 500.ms, delay: 200.ms).slideY(begin: 0.1),
        const SizedBox(height: 48),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label.toUpperCase(),
          style: GoogleFonts.outfit(
            color: AppTheme.textSecondary,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
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
        _buildStatCard(
          'TREINOS',
          '${data.totalSessions}',
          Icons.calendar_today_rounded,
          const Color(0xFFFE2D55),
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          'VOLUME',
          '${(data.totalVolume / 1000).toStringAsFixed(1)}t',
          Icons.fitness_center_rounded,
          const Color(0xFFCCFF00),
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          'MELHOR',
          '${(data.bestWeekVolume / 1000).toStringAsFixed(1)}t',
          Icons.emoji_events_rounded,
          const Color(0xFFFFD600),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color accent) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF161616),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.02)),
        ),
        child: Column(
          children: [
            Icon(icon, color: accent.withValues(alpha: 0.8), size: 18),
            const SizedBox(height: 12),
            Text(
              value,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: AppTheme.textSecondary,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.02)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.outfit(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.bar_chart_rounded, color: Color(0xFFCCFF00), size: 16),
              ),
            ],
          ),
          const SizedBox(height: 32),
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.02)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HISTÓRICO SEMANAL',
            style: GoogleFonts.outfit(
              color: AppTheme.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 24),
          ...weeks.asMap().entries.map((entry) {
            final i = entry.key;
            final week = entry.value;
            final prev = i < weeks.length - 1 ? weeks[i + 1] : null;
            final delta = prev != null && prev.volume > 0
                ? ((week.volume - prev.volume) / prev.volume * 100).round()
                : null;
            final isUp = delta != null && delta >= 0;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.02),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFCCFF00).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'S${week.weekNumber}',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFFCCFF00),
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Semana de ${DateFormat('dd MMM').format(week.weekStart)}',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${(week.volume / 1000).toStringAsFixed(1)} toneladas levantadas',
                          style: GoogleFonts.outfit(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (delta != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isUp ? const Color(0xFF22C55E).withValues(alpha: 0.1) : const Color(0xFFEF4444).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${isUp ? '+' : ''}$delta%',
                        style: GoogleFonts.outfit(
                          color: isUp ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
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
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: exercises.length,
        itemBuilder: (context, index) {
          final ex = exercises[index];
          final isSelected = ex.id == selectedId;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ChoiceChip(
              label: Text(ex.name.toUpperCase()),
              selected: isSelected,
              onSelected: (val) => onSelect(val ? ex.id : null),
              backgroundColor: const Color(0xFF161616),
              selectedColor: const Color(0xFFCCFF00),
              labelStyle: GoogleFonts.outfit(
                color: isSelected ? Colors.black : Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: isSelected ? const Color(0xFFCCFF00) : Colors.white.withValues(alpha: 0.05),
                ),
              ),
              showCheckmark: false,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          );
        },
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
    double max = 0;
    for (final p in points) {
      if (p.maxWeight > max) max = p.maxWeight;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFCCFF00), Color(0xFF99FF00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFCCFF00).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.emoji_events_rounded, color: Colors.black, size: 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RECORD PESSOAL (PR)',
                  style: GoogleFonts.outfit(
                    color: Colors.black.withValues(alpha: 0.6),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  '${max.toStringAsFixed(1)} kg',
                  style: GoogleFonts.outfit(
                    color: Colors.black,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'No exercício $name',
                  style: GoogleFonts.outfit(
                    color: Colors.black.withValues(alpha: 0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator(color: Color(0xFFCCFF00)));
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, color: AppTheme.danger, size: 48),
          const SizedBox(height: 16),
          const Text('Erro ao carregar dados', style: TextStyle(color: AppTheme.textPrimary)),
          TextButton(onPressed: onRetry, child: const Text('Tentar novamente')),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.analytics_outlined, size: 64, color: AppTheme.textSecondary.withValues(alpha: 0.2)),
          const SizedBox(height: 24),
          Text(
            'SEM DADOS AINDA',
            style: GoogleFonts.outfit(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete seu primeiro treino para ver suas estatísticas aqui.',
            style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

String _translateMuscle(String m) {
  switch (m.toLowerCase()) {
    case 'chest': return 'Peito';
    case 'back': return 'Costas';
    case 'shoulders': return 'Ombro';
    case 'biceps': return 'Bíceps';
    case 'triceps': return 'Tríceps';
    case 'quadriceps': return 'Quadríceps';
    case 'hamstrings': return 'Posterior';
    case 'glutes': return 'Glúteo';
    case 'abs': case 'core': return 'Core';
    case 'calves': return 'Panturrilha';
    default: return m;
  }
}
