import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/services/auth_service.dart';
import '../../shared/theme/app_theme.dart';
import '../workout/workout_profile_provider.dart';
import '../exercises/exercise_provider.dart';

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
    profileProvider.loadCurrentWorkout(exerciseProvider.getById);

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
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: const Text(
          'Início',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.textSecondary),
            onPressed: _load,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.textSecondary),
            onPressed: () => auth.logout(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      body: RefreshIndicator(
        color: AppTheme.accent,
        backgroundColor: AppTheme.surface,
        onRefresh: () async => _load(),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Olá, ${user?.displayName ?? 'Atleta'} 👋',
              style: Theme.of(context).textTheme.displayMedium,
            ),
            const SizedBox(height: 4),
            const Text(
              'Como está seu progresso esta semana:',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 24),

            FutureBuilder<DashboardData>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const _StatsShimmer();
                }
                if (snap.hasError || !snap.hasData) {
                  return _ErrorBanner(onRetry: _load);
                }
                return _StatsSection(data: snap.data!);
              },
            ),

            const SizedBox(height: 28),

            const _SectionLabel('ATALHOS'),
            const SizedBox(height: 12),

            Consumer<WorkoutProfileProvider>(
              builder: (context, wp, child) {
                final hasPro = wp.hasWorkout;
                return _NavCard(
                  icon: Icons.auto_awesome_rounded,
                  label: hasPro ? 'MEU TREINO INTELIGENTE' : 'MONTAR MEU TREINO',
                  subtitle: hasPro ? 'Ver meu plano de exercícios' : 'Deixa nossa IA montar seu treino completo',
                  color: AppTheme.accent,
                  onTap: () => context.push(hasPro ? '/prescribed' : '/anamnese'),
                  isFeatured: true,
                );
              },
            ),
            const SizedBox(height: 12),
            _NavCard(
              icon: Icons.assignment_rounded,
              label: 'Meus Treinos (Manual)',
              subtitle: 'Templates que você mesmo montou',
              color: const Color(0xFF10B981),
              onTap: () => context.push('/routines'),
            ),
            const SizedBox(height: 10),
            _NavCard(
              icon: Icons.play_circle_rounded,
              label: 'Treino Rápido',
              subtitle: 'Iniciar sessão livre agora',
              color: AppTheme.success,
              onTap: () => context.go('/workout'),
            ),
            const SizedBox(height: 10),
            _NavCard(
              icon: Icons.fitness_center_rounded,
              label: 'Exercícios',
              subtitle: 'Catálogo e progressão de carga',
              color: AppTheme.accent,
              onTap: () => context.go('/exercises'),
            ),
            const SizedBox(height: 10),
            _NavCard(
              icon: Icons.insights_rounded,
              label: 'Progressão de Carga',
              subtitle: 'Sugestões inteligentes baseadas no seu histórico',
              color: const Color(0xFFF59E0B),
              onTap: () => context.push('/progression'),
            ),
            const SizedBox(height: 10),
            _NavCard(
              icon: Icons.bar_chart_rounded,
              label: 'Estatísticas',
              subtitle: 'Gráficos de volume, carga e evolução muscular',
              color: const Color(0xFF6366F1),
              onTap: () => context.push('/analytics'),
            ),
            const SizedBox(height: 10),
            _NavCard(
              icon: Icons.history_rounded,
              label: 'Histórico',
              subtitle: 'Treinos anteriores',
              color: const Color(0xFF8B5CF6),
              onTap: () => context.push('/workout/history'),
            ),

            const SizedBox(height: 28),

            FutureBuilder<DashboardData>(
              future: _future,
              builder: (context, snap) {
                if (!snap.hasData) return const SizedBox.shrink();
                final data = snap.data!;
                if (data.volumeByMuscle.isEmpty) return const SizedBox.shrink();
                return _VolumeByMuscleCard(data: data);
              },
            ),

            const SizedBox(height: 16),
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
        _VolumeCard(data: data),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SmallStat(
                icon: Icons.calendar_today_rounded,
                label: 'Treinos\nesta semana',
                value: '${data.weekSessions}',
                color: AppTheme.accent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SmallStat(
                icon: Icons.emoji_events_rounded,
                label: 'Total de\ntreinos',
                value: '${data.totalSessions}',
                color: const Color(0xFFF59E0B),
              ),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
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
    return Container(
      decoration: BoxDecoration(
        color: isFeatured ? color.withValues(alpha: 0.15) : AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isFeatured ? color.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.05),
          width: isFeatured ? 2 : 1,
        ),
        boxShadow: isFeatured ? [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ] : null,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppTheme.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
