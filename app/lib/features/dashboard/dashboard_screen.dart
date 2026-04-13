import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/auth_service.dart';
import '../../shared/theme/app_theme.dart';
import '../workout/workout_profile_provider.dart';
import '../workout/progression_provider.dart';
import '../exercises/exercise_provider.dart';
import '../nutrition/nutrition_provider.dart';
import '../exercises/exercise_model.dart';

class DashboardData {
  final double weekVolume;
  final double lastWeekVolume;
  final int weekSessions;
  final int totalSessions;
  final Map<String, double> volumeByMuscle;
  final DateTime? lastSessionDate;

  const DashboardData({
    required this.weekVolume,
    required this.lastWeekVolume,
    required this.weekSessions,
    required this.totalSessions,
    required this.volumeByMuscle,
    this.lastSessionDate,
  });

  double get volumeDelta => weekVolume - lastWeekVolume;
  bool get isUp => volumeDelta >= 0;

  String get deltaPercent {
    if (lastWeekVolume == 0) return weekVolume > 0 ? '+100%' : '—';
    final pct = (volumeDelta / lastWeekVolume * 100).round();
    return '${pct >= 0 ? '+' : ''}$pct%';
  }
}

class _DashboardService {
  final FirebaseFirestore _db;
  final String _uid;

  _DashboardService({required FirebaseFirestore db, required String uid})
      : _db = db,
        _uid = uid;

  int get _currentWeek {
    final now = DateTime.now();
    return (now.difference(DateTime(now.year, 1, 1)).inDays / 7).ceil();
  }

  int get _lastWeek => _currentWeek == 1 ? 52 : _currentWeek - 1;

  Future<DashboardData> load() async {
    final snap = await _db
        .collection('users/$_uid/workouts')
        .orderBy('date', descending: true)
        .limit(50)
        .get();

    double weekVolume = 0;
    double lastWeekVolume = 0;
    int weekSessions = 0;
    final int totalSessions = snap.docs.length;
    final Map<String, double> volumeByMuscle = {};
    DateTime? lastSessionDate;

    for (final doc in snap.docs) {
      final d = doc.data();
      final week = (d['weekNumber'] as num?)?.toInt() ?? 0;
      final vol = (d['totalVolume'] as num?)?.toDouble() ?? 0;
      final date = (d['date'] as Timestamp?)?.toDate();

      if (week == _currentWeek) {
        weekVolume += vol;
        weekSessions++;
        if (lastSessionDate == null ||
            (date != null && date.isAfter(lastSessionDate))) {
          lastSessionDate = date;
        }
        final exercises = (d['exercises'] as List<dynamic>?) ?? [];
        for (final ex in exercises) {
          final em = ex as Map<String, dynamic>;
          final muscle = em['muscleGroup'] as String? ?? 'Outro';
          final exVol = (em['volume'] as num?)?.toDouble() ?? 0;
          volumeByMuscle[muscle] = (volumeByMuscle[muscle] ?? 0) + exVol;
        }
      } else if (week == _lastWeek) {
        lastWeekVolume += vol;
      }
    }

    return DashboardData(
      weekVolume: weekVolume,
      lastWeekVolume: lastWeekVolume,
      weekSessions: weekSessions,
      totalSessions: totalSessions,
      volumeByMuscle: volumeByMuscle,
      lastSessionDate: lastSessionDate,
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Future<DashboardData>? _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ── CORREÇÃO: separar o Future do setState ──
  void _load() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    
    // Assegura que o profile e o treino gerado estejam carregados
    final profileProvider = context.read<WorkoutProfileProvider>();
    final exerciseProvider = context.read<ExerciseProvider>();
    final nutritionProvider = context.read<NutritionProvider>();
    
    profileProvider.loadCurrentWorkout(exerciseProvider.getById).then((_) {
      if (!mounted) return;
      final profile = profileProvider.profile;
      if (profile != null) {
        // Usa microtask para evitar problemas de sincronia de estado no build
        Future.microtask(() {
          if (mounted) {
            context.read<NutritionProvider>().initFromProfile(profile);
          }
        });
      }
    });

    final future = _DashboardService(
      db: FirebaseFirestore.instance,
      uid: uid,
    ).load();
    setState(() { _future = future; });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppTheme.background,
            floating: true,
            pinned: true,
            expandedHeight: 140,
            leadingWidth: 0,
            leading: const SizedBox.shrink(),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              title: Text(
                'Evolução',
                style: GoogleFonts.outfit(
                  color: AppTheme.textPrimary,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.2),
              background: _buildHeaderTopBar(user, auth),
            ),
          ),
          
          SliverToBoxAdapter(
            child: RefreshIndicator(
              color: AppTheme.accent,
              backgroundColor: AppTheme.surface,
              onRefresh: () async => _load(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Bio-Metric Selector (Tracker, PB, Achievements, etc)
                    _buildQuickTabSelector().animate().fadeIn(delay: 200.ms),
                    
                    const SizedBox(height: 32),

                    // Daily Statistics (Cards com Física)
                    FutureBuilder<DashboardData>(
                      future: _future,
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const _StatsShimmer();
                        }
                        final data = snap.data;
                        if (snap.hasError || data == null) {
                          return const _ErrorCard();
                        }
                        return _StatsSection(data: data);
                      },
                    ),

                    const SizedBox(height: 24),

                    // Main Training Card (Destaque)
                    _buildTrainingHeroCard(context).animate().scale(delay: 400.ms, curve: Curves.elasticOut),

                    const SizedBox(height: 24),

                    // Grid de Módulos (Bento Style)
                    _buildBentoModules(context),

                    const SizedBox(height: 24),

                    // NOVO: Card de Download do APK
                    _NavCard(
                      icon: Icons.android_rounded,
                      label: 'APLICATIVO PARA CELULAR',
                      subtitle: 'Baixe o APK para instalar e usar como um app nativo',
                      color: const Color(0xFF3DDC84), // Android Green
                      onTap: () => _showDownloadDialog(context),
                      isFeatured: true,
                    ).animate().fadeIn(delay: 600.ms),

                    const SizedBox(height: 24),

                    FutureBuilder<DashboardData>(
                      future: _future,
                      builder: (context, snap) {
                        final data = snap.data;
                        if (data == null) return const SizedBox.shrink();
                        if (data.volumeByMuscle.isEmpty) return const SizedBox.shrink();
                        return _VolumeByMuscleCard(data: data);
                      },
                    ).animate().fadeIn(delay: 800.ms),

                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderTopBar(User? user, AuthService auth) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppTheme.surfaceHighlight,
            backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
            child: user?.photoURL == null ? const Icon(Icons.person, color: AppTheme.textSecondary) : null,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.accentOrange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Text('2', style: TextStyle(color: AppTheme.accentOrange, fontWeight: FontWeight.bold, fontSize: 10)),
                    const SizedBox(width: 4),
                    Text('DESAFIANTE', style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1)),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.local_fire_department_rounded, color: AppTheme.accent, size: 14),
                  const SizedBox(width: 4),
                  Text('145', style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: AppTheme.textPrimary),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppTheme.textSecondary, size: 20),
            onPressed: () => auth.logout(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickTabSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _TabItem(label: 'RASTREAMENTO', isSelected: true),
          _TabItem(label: 'RECORDES'),
          _TabItem(label: 'CONQUISTAS'),
          _TabItem(label: '10,000'),
        ],
      ),
    );
  }

  Widget _buildTrainingHeroCard(BuildContext context) {
    return Consumer<WorkoutProfileProvider>(
      builder: (context, wp, _) {
        final activeWorkout = wp.activeWorkout;
        final hasPro = activeWorkout != null;
        
        return InkWell(
          onTap: () => context.push(hasPro ? '/prescribed' : '/anamnese'),
          borderRadius: BorderRadius.circular(32),
          child: Container(
            height: 280,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(32),
              image: const DecorationImage(
                image: NetworkImage('https://images.unsplash.com/photo-1517836357463-d25dfeac3438?q=80&w=2070&auto=format&fit=crop'),
                fit: BoxFit.cover,
                opacity: 0.3,
              ),
              boxShadow: [BoxShadow(color: AppTheme.accent.withOpacity(0.1), blurRadius: 40, offset: const Offset(0, 20))],
            ),
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                 Container(
                   padding: const EdgeInsets.all(12),
                   decoration: const BoxDecoration(color: AppTheme.accent, shape: BoxShape.circle),
                   child: Icon(hasPro ? Icons.play_arrow_rounded : Icons.add, color: Colors.black, size: 24),
                 ),
                 const Spacer(),
                 Text(
                   hasPro ? activeWorkout.name : 'Vazio', 
                   style: GoogleFonts.outfit(fontSize: 42, fontWeight: FontWeight.w900, color: AppTheme.textPrimary, height: 1.1)
                 ),
                 const SizedBox(height: 8),
                 Text(
                   hasPro ? 'MEU PLANO ATIVO' : 'COMECE AQUI', 
                   style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.accent, letterSpacing: 2)
                 ),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildBentoModules(BuildContext context) {
    return Column(
      children: [
        Row(
           children: [
             Expanded(
               child: _BentoCard(
                 title: 'Técnica', 
                 value: '16', 
                 unit: 'MIN', 
                 color: AppTheme.accent, 
                 icon: Icons.directions_run,
                 onTap: () => context.push('/exercises'),
               ),
             ),
             const SizedBox(width: 16),
             Expanded(
               child: _BentoCard(
                 title: 'Tática', 
                 value: '10', 
                 unit: 'MIN', 
                 color: AppTheme.accentBlue, 
                 icon: Icons.psychology,
                 onTap: () => context.push('/progression'),
               ),
             ),
           ],
        ),
        const SizedBox(height: 16),
        _BentoCard(
          title: 'Bio-Gestão', 
          value: 'ATIVO', 
          unit: '', 
          color: AppTheme.accentLime, 
          icon: Icons.auto_awesome, 
          fullWidth: true,
          onTap: () => context.push('/nutrition'),
        ),
      ],
    );
  }


  void _showDownloadDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 32),
            const Icon(Icons.install_mobile_rounded, size: 64, color: Color(0xFF3DDC84)),
            const SizedBox(height: 20),
            const Text(
              'Instale o App no Android',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 12),
            const Text(
              'Acesse todos os recursos de forma nativa e muito mais rápida no seu celular Android.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Download iniciado...')),
                  );
                },
                icon: const Icon(Icons.download_rounded, color: Colors.white),
                label: const Text('BAIXAR INSTALADOR (APK)', 
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3DDC84), 
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Dica: Se o Android bloquear, habilite "Instalar de fontes desconhecidas".',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Stats ────────────────────────────────────

class _StatsSection extends StatelessWidget {
  final DashboardData data;
  const _StatsSection({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _VolumeCard(data: data).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _SmallStat(
                icon: Icons.calendar_today_rounded,
                label: 'SESSIONS',
                value: '${data.weekSessions}',
                color: AppTheme.accentBlue,
              ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.1),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _SmallStat(
                icon: Icons.emoji_events_rounded,
                label: 'RECORDS',
                value: '${data.totalSessions}',
                color: AppTheme.accentOrange,
              ).animate().fadeIn(delay: 500.ms).slideX(begin: 0.1),
            ),
          ],
        ),
      ],
    );
  }
}

class _VolumeCard extends StatelessWidget {
  final DashboardData data;
  const _VolumeCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final hasData = data.weekVolume > 0;
    final deltaColor = data.isUp ? AppTheme.success : AppTheme.danger;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.accent.withValues(alpha: 0.15),
            AppTheme.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.bolt_rounded, color: AppTheme.accent, size: 20),
              ),
              const SizedBox(width: 10),
              const Text(
                'Volume desta semana',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!hasData)
            const Text(
              'Nenhum treino esta semana.\nVamos lá! 💪',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 15),
            )
          else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  data.weekVolume.toStringAsFixed(0),
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 6),
                const Padding(
                  padding: EdgeInsets.only(bottom: 6),
                  child: Text(
                    'kg',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
                  ),
                ),
                const Spacer(),
                if (data.lastWeekVolume > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: deltaColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: deltaColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          data.isUp
                              ? Icons.trending_up_rounded
                              : Icons.trending_down_rounded,
                          color: deltaColor,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          data.deltaPercent,
                          style: TextStyle(
                            color: deltaColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              data.lastWeekVolume > 0
                  ? 'Semana passada: ${data.lastWeekVolume.toStringAsFixed(0)} kg levantados'
                  : 'Começando sua jornada agora! 🚀',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

class _SmallStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SmallStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: GoogleFonts.outfit(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 28,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.outfit(
              color: AppTheme.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Volume por músculo ───────────────────────

const Map<String, Color> _muscleColors = {
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

class _NutritionSummaryCard extends StatelessWidget {
  final NutritionProvider provider;
  const _NutritionSummaryCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final remaining = provider.remainingCalories;
    final target = provider.targetCalories;
    final pct = target > 0 ? (provider.consumedCalories / target).clamp(0.0, 1.0) : 0.0;
    
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _SectionLabel('NUTRIÇÃO DO DIA'),
              GestureDetector(
                onTap: () => context.push('/nutrition'),
                child: const Text('DETALHES', style: TextStyle(color: AppTheme.accent, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '$target',
                          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 32, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'kcal',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                        ),
                      ],
                    ),
                    if (provider.isCaloriesAdjusted)
                      Row(
                        children: [
                          const Icon(Icons.bolt_rounded, color: AppTheme.accent, size: 12),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Ajustada (${provider.currentGoalLabel})',
                              style: const TextStyle(color: AppTheme.accent, fontSize: 10, fontWeight: FontWeight.w600),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      )
                    else
                      const Text('Meta de hoje', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    const SizedBox(height: 8),
                    Text('$remaining kcal restantes', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              _buildMacroMini('P', provider.consumedProtein, provider.activeTargetProtein, AppTheme.accent, isAdjusted: provider.isProteinAdjusted),
              const SizedBox(width: 8),
              _buildMacroMini('C', provider.consumedCarb, provider.activeTargetCarb, AppTheme.success, isAdjusted: provider.isCarbAdjusted),
              const SizedBox(width: 8),
              _buildMacroMini('G', provider.consumedFat, provider.activeTargetFat, Colors.orange, isAdjusted: provider.isFatAdjusted),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: AppTheme.accent.withValues(alpha: 0.1),
              color: AppTheme.accent,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroMini(String label, double consumed, double target, Color color, {bool isAdjusted = false}) {
    final pct = target > 0 ? (consumed / target).clamp(0.0, 1.0) : 0.0;
    final isDone = pct >= 1.0;
    final displayColor = isDone ? AppTheme.success : color;

    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TextStyle(color: displayColor, fontWeight: FontWeight.bold, fontSize: 10)),
            if (isAdjusted) ...[
              const SizedBox(width: 2),
              Tooltip(
                message: 'Ajustado pelo algoritmo',
                child: Icon(Icons.bolt_rounded, size: 10, color: displayColor),
              ),
            ],
          ],
        ),
        const SizedBox(height: 2),
        Text('${consumed.round()}g', style: TextStyle(color: isDone ? AppTheme.success : AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
        Text('${target.round()}g', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9)),
      ],
    );
  }
}

class _VolumeByMuscleCard extends StatelessWidget {
  final DashboardData data;
  const _VolumeByMuscleCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final sorted = data.volumeByMuscle.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxVol = sorted.first.value;

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
          const _SectionLabel('VOLUME POR GRUPO MUSCULAR'),
          const SizedBox(height: 16),
          ...sorted.take(6).map((entry) {
            final translatedName = _translateMuscle(entry.key);
            final color = _muscleColors[entry.key] ?? _muscleColors[translatedName] ?? AppTheme.accent;
            final ratio = entry.value / maxVol;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          translatedName,
                          style: const TextStyle(
                              color: AppTheme.textPrimary, fontSize: 13),
                        ),
                      ),
                      Text(
                        '${entry.value.toStringAsFixed(0)} kg',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: ratio,
                      backgroundColor: color.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation(color),
                      minHeight: 6,
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

// ─── Shimmer / Error ──────────────────────────

class _StatsShimmer extends StatelessWidget {
  const _StatsShimmer();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 140,
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Center(
            child: CircularProgressIndicator(
                color: AppTheme.accent, strokeWidth: 2),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorBanner({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.danger.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, color: AppTheme.danger, size: 20),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Não foi possível carregar os dados.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Tentar novamente',
                style: TextStyle(color: AppTheme.accent, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

// ─── Reutilizáveis ────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: AppTheme.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }
}

// Helper de tradução para leigos
String _translateMuscle(String m) {
  final map = {
    'chest': 'Peitoral',
    'back': 'Costas',
    'shoulders': 'Ombros',
    'side_delt': 'Ombro Lateral',
    'rear_delt': 'Ombro Posterior',
    'biceps': 'Bíceps',
    'triceps': 'Tríceps',
    'quads': 'Coxa (Frente)',
    'hamstrings': 'Coxa (Atrás)',
    'glutes': 'Glúteos',
    'calves': 'Panturrilha',
    'abs': 'Abdômen',
    'core': 'Abdominal',
    'upper_chest': 'Peito Superior',
    'lower_chest': 'Peito Inferior',
    'traps': 'Trapézio',
    'forearms': 'Antebraço',
  };
  return map[m.toLowerCase()] ?? m;
}

class _NavCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final bool isFeatured;

  const _NavCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.isFeatured = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isFeatured ? color.withOpacity(0.05) : AppTheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isFeatured ? color.withOpacity(0.3) : Colors.white.withOpacity(0.05),
              width: isFeatured ? 2 : 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.outfit(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.outfit(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: color.withOpacity(0.5)),
            ],
          ),
        ).animate(onPlay: (controller) => controller.repeat(reverse: true))
         .shimmer(delay: isFeatured ? 2.seconds : 100.seconds, duration: 2.seconds, color: color.withOpacity(0.2)),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final String label;
  final bool isSelected;
  const _TabItem({required this.label, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: isSelected ? Colors.transparent : AppTheme.surface,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: isSelected ? AppTheme.textPrimary : Colors.white.withOpacity(0.1), width: 1.5),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
          fontWeight: FontWeight.w900,
          fontSize: 12,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _BentoCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  final bool fullWidth;

  const _BentoCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.color,
    required this.icon,
    required this.onTap,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(0.2), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
                Icon(icon, color: color, size: 20),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 32,
                    height: 1,
                  ),
                ),
                if (unit.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Text(
                    unit,
                    style: GoogleFonts.outfit(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard();
  @override
  Widget build(BuildContext context) => const SizedBox(height: 100, child: Center(child: Icon(Icons.error_outline, color: AppTheme.textSecondary)));
}

// ─── Card de status do ciclo de periodização ──

class _CycleStatusCard extends StatelessWidget {
  final ProgressionProvider provider;
  const _CycleStatusCard({required this.provider});

  Color get _phaseColor {
    switch (provider.currentPhase) {
      case 'accumulation': return AppTheme.accent;
      case 'intensification': return const Color(0xFFF59E0B);
      case 'peak': return AppTheme.success;
      case 'deload': return AppTheme.danger;
      default: return AppTheme.accent;
    }
  }

  String get _phaseLabel {
    switch (provider.currentPhase) {
      case 'accumulation': return 'Acumulação';
      case 'intensification': return 'Intensificação';
      case 'peak': return 'Pico';
      case 'deload': return 'Deload';
      default: return provider.currentPhase;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _phaseColor;
    final isDeload = provider.isDeloadWeek;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: c.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(
              isDeload ? Icons.refresh_rounded : Icons.loop_rounded,
              color: c, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isDeload
                          ? '🔄  SEMANA DE DELOAD'
                          : 'Semana ${provider.currentWeek}  •  Fase: $_phaseLabel',
                      style: TextStyle(
                          color: c,
                          fontWeight: FontWeight.bold,
                          fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  isDeload
                      ? 'Reduza o volume em 45%. Carga igual. Foco em técnica.'
                      : provider.weeksUntilDeload <= 1
                          ? 'Próximo deload na semana que vem'
                          : '${provider.weeksUntilDeload} semana(s) até o próximo deload',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right_rounded,
              color: c.withValues(alpha: 0.5), size: 18),
        ],
      ),
    );
  }
}
