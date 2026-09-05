import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/api_service.dart';
import '../../shared/theme/app_theme.dart';
import '../workout/workout_profile_provider.dart';
import '../workout/progression_provider.dart';
import '../exercises/exercise_provider.dart';
import '../nutrition/nutrition_provider.dart';
import '../exercises/exercise_model.dart';
import '../workout/workout_routine_model.dart';
import '../workout/athlete_rank.dart';
import '../workout/athlete_rank_provider.dart';

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
  final ApiService _api = ApiService();

  _DashboardService();

  Future<DashboardData> load() async {
    try {
      final response = await _api.get('/dashboard/summary');

      return DashboardData(
        weekVolume: (response['weekVolume'] as num?)?.toDouble() ?? 0,
        lastWeekVolume: (response['lastWeekVolume'] as num?)?.toDouble() ?? 0,
        weekSessions: (response['weekSessions'] as num?)?.toInt() ?? 0,
        totalSessions: (response['totalSessions'] as num?)?.toInt() ?? 0,
        volumeByMuscle: Map<String, double>.from(
          (response['volumeByMuscle'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, (value as num?)?.toDouble() ?? 0),
          ) ?? {},
        ),
        lastSessionDate: response['lastSessionDate'] != null
            ? DateTime.tryParse(response['lastSessionDate'] as String)
            : null,
      );
    } catch (e) {
      return const DashboardData(
        weekVolume: 0,
        lastWeekVolume: 0,
        weekSessions: 0,
        totalSessions: 0,
        volumeByMuscle: {},
      );
    }
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

  void _load() {
    final uid = context.read<AuthService>().currentUser?.id;
    if (uid == null) return;
    
    final profileProvider = context.read<WorkoutProfileProvider>();
    final exerciseProvider = context.read<ExerciseProvider>();
    final nutritionProvider = context.read<NutritionProvider>();
    
    profileProvider.connectExerciseProvider(exerciseProvider);
    
    final profile = profileProvider.profile;
    if (profile != null && nutritionProvider.profile == null) {
      Future.microtask(() {
        if (mounted) nutritionProvider.initFromProfile(profile);
      });
    }

    final future = _DashboardService().load();
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
            expandedHeight: 120,
            leadingWidth: 0,
            leading: const SizedBox.shrink(),
            flexibleSpace: FlexibleSpaceBar(
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
                    const SizedBox(height: 8),

                    _WeeklyCalendarWidget().animate().fadeIn(duration: 500.ms),
                    const SizedBox(height: 20),

                    _buildTrainingHeroCard(context),
                    
                    const SizedBox(height: 20),

                    _buildRankCard(context).animate().fadeIn(delay: 100.ms),
                    
                    const SizedBox(height: 32),

                    _buildStatsTitle('RESUMO DA SEMANA'),
                    const SizedBox(height: 16),
                    FutureBuilder<DashboardData>(
                      future: _future,
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const SizedBox(height: 80, child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
                        }
                        final data = snap.data;
                        if (snap.hasError || data == null) return const SizedBox.shrink();
                        return _buildCompactWeeklyStats(data);
                      },
                    ).animate().fadeIn(delay: 200.ms),

                    const SizedBox(height: 32),

                    _buildStatsTitle('FERRAMENTAS'),
                    const SizedBox(height: 16),
                    _buildFeatureNavList(context),
                    
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

  Widget _buildHeaderTopBar(AuthUser? user, AuthService auth) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 52, 24, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppTheme.surfaceHighlight,
            child: const Icon(Icons.person, color: AppTheme.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'BuildFit',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Consumer<AthleteRankProvider>(
                      builder: (context, rankProvider, _) {
                        final rank = rankProvider.rankResult;
                        if (rank == null) return const SizedBox.shrink();
                        return Row(
                          children: [
                            Text(
                              rank.currentRank.icon,
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${rank.currentRank.name} · ${formatXP(rank.totalXP)} XP',
                              style: GoogleFonts.outfit(
                                color: rank.currentRank.color,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: AppTheme.textPrimary, size: 24),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildDailyStatus() {
    return Consumer<WorkoutProfileProvider>(
      builder: (context, wp, _) {
        final hasPro = wp.activeWorkout != null;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
             color: AppTheme.surface,
             borderRadius: BorderRadius.circular(20),
             border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: hasPro ? AppTheme.accent.withOpacity(0.15) : AppTheme.surfaceHighlight,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  hasPro ? Icons.fitness_center_rounded : Icons.bed_rounded,
                  color: hasPro ? AppTheme.accent : AppTheme.textSecondary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasPro ? 'Dia de Treino' : 'Descanso Ativo',
                      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasPro ? 'Seu plano está pronto para hoje.' : 'Recuperação também faz parte do processo.',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildTrainingHeroCard(BuildContext context) {
    return Consumer<WorkoutProfileProvider>(
      builder: (context, wp, _) {
        final hasPro = wp.activeWorkout != null;
        
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Seus treinos',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Escolha e inicie um treino',
                        style: GoogleFonts.outfit(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFCCFF00).withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.bolt_rounded, color: Color(0xFFCCFF00), size: 24),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: () => context.push(hasPro ? '/prescribed' : '/routines'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFCCFF00),
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.play_arrow_rounded, size: 28),
                      const SizedBox(width: 8),
                      Text(
                        'VER TREINOS',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildRankCard(BuildContext context) {
    return Consumer<AthleteRankProvider>(
      builder: (context, rankProvider, _) {
        if (rankProvider.isLoading) {
          return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
        }

        final rank = rankProvider.rankResult;
        if (rank == null) return const SizedBox.shrink();

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: rank.currentRank.color.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: rank.currentRank.glowColor,
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: rank.currentRank.color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(color: rank.currentRank.color.withValues(alpha: 0.3)),
                    ),
                    child: Center(
                      child: Text(rank.currentRank.icon, style: const TextStyle(fontSize: 28)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rank.currentRank.name.toUpperCase(),
                          style: GoogleFonts.outfit(
                            color: rank.currentRank.color,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          rank.nextRank != null
                              ? '${formatXP(rank.xpInCurrentRank)} / ${formatXP(rank.xpForNext)} XP para ${rank.nextRank!.name}'
                              : 'Rank máximo alcançado!',
                          style: GoogleFonts.outfit(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatXP(rank.totalXP),
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'XP TOTAL',
                        style: GoogleFonts.outfit(
                          color: AppTheme.textSecondary,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (rank.nextRank != null) ...[
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: rank.progressPercent,
                    minHeight: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.06),
                    valueColor: AlwaysStoppedAnimation<Color>(rank.currentRank.color),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${(rank.progressPercent * 100).toStringAsFixed(1)}%',
                      style: GoogleFonts.outfit(
                        color: rank.currentRank.color,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${rankProvider.totalSessions} sessões',
                      style: GoogleFonts.outfit(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsTitle(String label) {
    return Text(
      label,
      style: GoogleFonts.outfit(
        color: AppTheme.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 2,
      ),
    );
  }

  Widget _buildCompactWeeklyStats(DashboardData data) {
    return Row(
      children: [
        _buildStatTile(
          icon: Icons.bolt_rounded,
          value: '${data.weekVolume.toStringAsFixed(0)}kg',
          label: 'Volume',
          color: const Color(0xFFCCFF00),
        ),
        const SizedBox(width: 12),
        _buildStatTile(
          icon: Icons.calendar_today_rounded,
          value: '${data.weekSessions}',
          label: 'Sessões',
          color: Colors.white,
        ),
        const SizedBox(width: 12),
        _buildStatTile(
          icon: Icons.emoji_events_rounded,
          value: '${data.totalSessions}',
          label: 'Recordes',
          color: const Color(0xFFFFA500),
        ),
      ],
    );
  }

  Widget _buildStatTile({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.04)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 10),
            Text(
              value,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label.toUpperCase(),
              style: GoogleFonts.outfit(
                color: AppTheme.textSecondary,
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureNavList(BuildContext context) {
    return Column(
      children: [
        _buildNavActionCard(
          title: 'Exercícios',
          subtitle: 'Veja seus exercícios e cargas',
          icon: Icons.fitness_center_rounded,
          color: const Color(0xFFCCFF00),
          onTap: () => context.push('/exercises'),
        ),
        const SizedBox(height: 14),
        _buildNavActionCard(
          title: 'Evolução',
          subtitle: 'Acompanhe seu progresso',
          icon: Icons.trending_up_rounded,
          color: const Color(0xFF00E5FF),
          onTap: () => context.push('/progression'),
        ),
        const SizedBox(height: 14),
        _buildNavActionCard(
          title: 'Nutrição',
          subtitle: 'Acompanhe sua alimentação',
          icon: Icons.restaurant_rounded,
          color: const Color(0xFFFF4081),
          onTap: () => context.push('/nutrition'),
        ),
      ],
    );
  }

  Widget _buildNavActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.white.withOpacity(0.2), size: 28),
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
                label: 'SESSÕES',
                value: '${data.weekSessions}',
                color: AppTheme.accentBlue,
              ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.1),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _SmallStat(
                icon: Icons.emoji_events_rounded,
                label: 'RECORDE',
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

// ─────────────────────────────────────────────
// Calendário Semanal Visual
// ─────────────────────────────────────────────

class _WeeklyCalendarWidget extends StatelessWidget {
  static const _dayLabels = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

  List<bool> _trainingDays(int daysPerWeek) {
    switch (daysPerWeek) {
      case 2: return [true,  false, true,  false, false, false, false];
      case 3: return [true,  false, true,  false, true,  false, false];
      case 4: return [true,  true,  false, true,  true,  false, false];
      case 5: return [true,  true,  false, true,  true,  true,  false];
      case 6: return [true,  true,  true,  false, true,  true,  true];
      case 7: return [true,  true,  true,  true,  true,  true,  true];
      default: return [true, false, true,  false, true,  false, false];
    }
  }

  List<String> _sessionLabels(String splitType, int daysPerWeek) {
    switch (splitType.toLowerCase()) {
      case 'ppl':
      case 'push_pull_legs':
        const cycle = ['PUSH', 'PULL', 'PERNAS', 'PUSH', 'PULL', 'PERNAS', ''];
        return cycle;
      case 'upper_lower':
        return ['UPPER', 'LOWER', '', 'UPPER', 'LOWER', '', ''];
      case 'full_body':
        if (daysPerWeek == 3) return ['FULL A', '', 'FULL B', '', 'FULL C', '', ''];
        return ['FULL A', '', 'FULL B', '', 'FULL C', '', ''];
      default:
        return ['TREINO A', 'TREINO B', '', 'TREINO C', 'TREINO D', '', ''];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkoutProfileProvider>(
      builder: (context, wp, _) {
        final profile = wp.profile;
        final activeWorkout = wp.activeWorkout;
        final daysPerWeek = profile?.availableDaysPerWeek ?? 3;
        final splitType = activeWorkout?.splitType ?? 'full_body';

        final trainingDays = _trainingDays(daysPerWeek);
        final labels = _sessionLabels(splitType, daysPerWeek);

        final todayWeekday = DateTime.now().weekday;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'SEMANA ATUAL',
                  style: GoogleFonts.outfit(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                if (wp.activeWorkout != null)
                  GestureDetector(
                    onTap: () => context.push('/deload'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B6B).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFFF6B6B).withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        'DELOAD',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFFFF6B6B),
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            SizedBox(
              height: 82,
              child: Row(
                children: List.generate(7, (i) {
                  final isToday = (i + 1) == todayWeekday;
                  final isTraining = trainingDays[i];
                  final label = labels[i];

                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: i < 6 ? 6 : 0),
                      child: _DayCard(
                        dayLabel: _dayLabels[i],
                        isToday: isToday,
                        isTraining: isTraining,
                        sessionLabel: label,
                        onTap: isTraining
                            ? () => context.push('/prescribed')
                            : null,
                      ).animate(delay: (i * 60).ms).fadeIn().scale(begin: const Offset(0.9, 0.9)),
                    ),
                  );
                }),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DayCard extends StatelessWidget {
  final String dayLabel;
  final bool isToday;
  final bool isTraining;
  final String sessionLabel;
  final VoidCallback? onTap;

  const _DayCard({
    required this.dayLabel,
    required this.isToday,
    required this.isTraining,
    required this.sessionLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const neon = Color(0xFFCCFF00);
    final borderColor = isToday
        ? neon.withValues(alpha: 0.6)
        : Colors.white.withValues(alpha: 0.04);
    final bgColor = isToday
        ? neon.withValues(alpha: 0.06)
        : isTraining
            ? const Color(0xFF1E1E1E)
            : const Color(0xFF141414);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: isToday ? 1.5 : 1),
          boxShadow: isToday
              ? [BoxShadow(color: neon.withValues(alpha: 0.1), blurRadius: 12)]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              dayLabel,
              style: GoogleFonts.outfit(
                color: isToday ? neon : AppTheme.textSecondary,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),

            if (isTraining && sessionLabel.isNotEmpty)
              Text(
                sessionLabel,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  color: isToday ? neon : Colors.white.withValues(alpha: 0.7),
                  fontSize: 7,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.3,
                ),
              )
            else if (isTraining)
              Icon(Icons.fitness_center_rounded,
                  size: 14,
                  color: isToday ? neon : Colors.white.withValues(alpha: 0.5))
            else
              Icon(Icons.hotel_rounded,
                  size: 14,
                  color: Colors.white.withValues(alpha: 0.15)),

            if (isToday) ...[
              const SizedBox(height: 4),
              Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(color: neon, shape: BoxShape.circle),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
