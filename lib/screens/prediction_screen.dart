import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/match.dart';
import '../models/player.dart';
import '../providers/match_provider.dart';
import '../providers/player_providers.dart';
import '../providers/timezone_provider.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../widgets/shimmer_loading.dart';

// ── Prediction model ───────────────────────────────────────────────────────────
class _Prediction {
  final double homeWinProb; // 0-1
  final double drawProb;
  final double awayWinProb;
  final int predictedHomeGoals;
  final int predictedAwayGoals;
  final String confidence; // 'High' | 'Medium' | 'Low'

  const _Prediction({
    required this.homeWinProb,
    required this.drawProb,
    required this.awayWinProb,
    required this.predictedHomeGoals,
    required this.predictedAwayGoals,
    required this.confidence,
  });
}

_Prediction _computePrediction(Match match) {
  final homeRank = match.homeTeam.fifaRanking;
  final awayRank = match.awayTeam.fifaRanking;

  // Draw always takes 25%
  const drawProb = 0.25;

  // Remaining 75% split by ranking difference
  // rankDiff > 0 => home is weaker, < 0 => home is stronger
  final rankDiff = (awayRank - homeRank).toDouble();
  // Scale into [-1, 1] over a ±40 ranking window
  final scaled = (rankDiff / 40.0).clamp(-1.0, 1.0);

  // home base 37.5%, scaled by edge
  final homeWin = (0.375 + scaled * 0.375).clamp(0.05, 0.70);
  final awayWin = (0.75 - homeWin).clamp(0.05, 0.70);

  // Predicted goals based on ranking tier
  int _goalsForRank(int rank) {
    if (rank <= 10) return 2;
    if (rank <= 30) return 2; // sometimes 1.5 → round to 2
    if (rank <= 60) return 1;
    return 1;
  }

  final homeGoals = _goalsForRank(homeRank);
  final awayGoals = _goalsForRank(awayRank);

  // Confidence based on ranking gap
  final gap = rankDiff.abs();
  final confidence = gap >= 25 ? 'High' : (gap >= 10 ? 'Medium' : 'Low');

  return _Prediction(
    homeWinProb: homeWin,
    drawProb: drawProb,
    awayWinProb: awayWin,
    predictedHomeGoals: homeGoals,
    predictedAwayGoals: awayGoals,
    confidence: confidence,
  );
}

// ── Timezone helper ────────────────────────────────────────────────────────────
String _localMatchDate(WidgetRef ref, DateTime utcTime) {
  final tzNotifier = ref.read(timezoneProvider.notifier);
  final tzState = ref.read(timezoneProvider);
  final local = tzNotifier.convertToLocal(utcTime);
  return '${DateFormat('MMM d').format(local)} ${tzState.timezoneAbbreviation}';
}

// ── Screen ─────────────────────────────────────────────────────────────────────
class PredictionScreen extends ConsumerStatefulWidget {
  const PredictionScreen({super.key});

  @override
  ConsumerState<PredictionScreen> createState() => _PredictionScreenState();
}

class _PredictionScreenState extends ConsumerState<PredictionScreen>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;

  // Animation controllers for progress bars
  late AnimationController _barAnimController;
  late Animation<double> _barAnim;

  @override
  void initState() {
    super.initState();
    _barAnimController = AnimationController(
      vsync: this,
      duration: AppConstants.longAnimation,
    );
    _barAnim = CurvedAnimation(
      parent: _barAnimController,
      curve: Curves.easeOutCubic,
    );
    _barAnimController.forward();
  }

  @override
  void dispose() {
    _barAnimController.dispose();
    super.dispose();
  }

  void _selectMatch(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
    _barAnimController
      ..reset()
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final matchState = ref.watch(matchProvider);
    final playersAsync = ref.watch(playersProvider);

    final upcoming = matchState.allMatches
        .where((m) => m.status == MatchStatus.scheduled)
        .take(5)
        .toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ─────────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI PREDICTION',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Match Predictions',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Horizontal match selector ──────────────────────────────────────
            SizedBox(
              height: 100,
              child: matchState.isLoading
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: ShimmerLoading(child: ShimmerLoading.scoreboardCarousel()),
                    )
                  : upcoming.isEmpty
                      ? const SizedBox.shrink()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          scrollDirection: Axis.horizontal,
                          itemCount: upcoming.length,
                          itemBuilder: (context, index) {
                            final m = upcoming[index];
                            final isSelected = index == _selectedIndex;
                            return GestureDetector(
                              onTap: () => _selectMatch(index),
                              child: AnimatedContainer(
                                duration: AppConstants.shortAnimation,
                                margin: const EdgeInsets.only(right: 12),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  gradient: isSelected
                                      ? LinearGradient(
                                          colors: [
                                            theme.colorScheme.primary,
                                            theme.colorScheme.primary.withOpacity(0.6),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        )
                                      : null,
                                  color: isSelected
                                      ? null
                                      : isDark
                                          ? Colors.white.withOpacity(0.05)
                                          : Colors.black.withOpacity(0.04),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.transparent
                                        : isDark
                                            ? Colors.white.withOpacity(0.1)
                                            : Colors.black.withOpacity(0.08),
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: theme.colorScheme.primary.withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          )
                                        ]
                                      : null,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _FlagImage(
                                          flagCode: m.homeTeam.flagCode,
                                          size: 20,
                                          radius: 3,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          m.homeTeam.code,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: isSelected ? Colors.black : null,
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 6),
                                          child: Text(
                                            'vs',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: isSelected
                                                  ? Colors.black54
                                                  : Colors.grey,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          m.awayTeam.code,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: isSelected ? Colors.black : null,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        _FlagImage(
                                          flagCode: m.awayTeam.flagCode,
                                          size: 20,
                                          radius: 3,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _localMatchDate(ref, m.kickoffTime),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isSelected ? Colors.black54 : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),

            const SizedBox(height: 20),

            // ── Prediction panel ───────────────────────────────────────────────
            Expanded(
              child: matchState.isLoading
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: ShimmerLoading(child: ShimmerLoading.cardList(count: 3)),
                    )
                  : upcoming.isEmpty
                      ? _EmptyState(isDark: isDark)
                      : SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: _PredictionPanel(
                            match: upcoming[_selectedIndex],
                            prediction: _computePrediction(upcoming[_selectedIndex]),
                            barAnim: _barAnim,
                            isDark: isDark,
                            playersAsync: playersAsync,
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Prediction Panel ───────────────────────────────────────────────────────────
class _PredictionPanel extends StatelessWidget {
  final Match match;
  final _Prediction prediction;
  final Animation<double> barAnim;
  final bool isDark;
  final AsyncValue<List<Player>> playersAsync;

  const _PredictionPanel({
    required this.match,
    required this.prediction,
    required this.barAnim,
    required this.isDark,
    required this.playersAsync,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Pick key players: highest-rated player per team (mock from players list)
    final Player? homeKeyPlayer = playersAsync.valueOrNull
        ?.where((p) => p.teamId == match.homeTeam.id)
        .fold<Player?>(null, (best, p) => best == null || p.rating > best.rating ? p : best);
    final Player? awayKeyPlayer = playersAsync.valueOrNull
        ?.where((p) => p.teamId == match.awayTeam.id)
        .fold<Player?>(null, (best, p) => best == null || p.rating > best.rating ? p : best);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Match header card ────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF1A2040), const Color(0xFF0D1226)]
                  : [Colors.white, const Color(0xFFF0F4FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              // Stage / group chip
              if (match.group != null || match.stage != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    match.group != null ? 'Group ${match.group}' : match.stage!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Teams row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        _FlagImage(flagCode: match.homeTeam.flagCode, size: 56, radius: 8),
                        const SizedBox(height: 8),
                        Text(
                          match.homeTeam.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Rank #${match.homeTeam.fifaRanking}',
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  // Predicted score
                  Column(
                    children: [
                      Row(
                        children: [
                          Text(
                            '${prediction.predictedHomeGoals}',
                            style: theme.textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              '-',
                              style: theme.textTheme.headlineLarge?.copyWith(
                                fontWeight: FontWeight.w300,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          Text(
                            '${prediction.predictedAwayGoals}',
                            style: theme.textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Predicted Score',
                        style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        _FlagImage(flagCode: match.awayTeam.flagCode, size: 56, radius: 8),
                        const SizedBox(height: 8),
                        Text(
                          match.awayTeam.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Rank #${match.awayTeam.fifaRanking}',
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Confidence badge (pulsing)
              _ConfidenceBadge(confidence: prediction.confidence),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ── Win probability card ──────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Win Probability',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _ProbBar(
                label: match.homeTeam.code,
                value: prediction.homeWinProb,
                color: theme.colorScheme.primary,
                animation: barAnim,
              ),
              const SizedBox(height: 10),
              _ProbBar(
                label: 'Draw',
                value: prediction.drawProb,
                color: AppTheme.warning,
                animation: barAnim,
              ),
              const SizedBox(height: 10),
              _ProbBar(
                label: match.awayTeam.code,
                value: prediction.awayWinProb,
                color: const Color(0xFFFF4081),
                animation: barAnim,
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ── Key players card ──────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Key Players to Watch',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _KeyPlayerTile(
                      player: homeKeyPlayer,
                      teamName: match.homeTeam.name,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _KeyPlayerTile(
                      player: awayKeyPlayer,
                      teamName: match.awayTeam.name,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // ── Disclaimer ────────────────────────────────────────────────────────
        Text(
          '⚡ Predictions are AI-generated based on FIFA rankings. For entertainment purposes only.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.grey.withOpacity(0.6),
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

// ── Probability Bar ────────────────────────────────────────────────────────────
class _ProbBar extends StatelessWidget {
  final String label;
  final double value; // 0-1
  final Color color;
  final Animation<double> animation;

  const _ProbBar({
    required this.label,
    required this.value,
    required this.color,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = (value * 100).round();

    return Row(
      children: [
        SizedBox(
          width: 44,
          child: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AnimatedBuilder(
              animation: animation,
              builder: (context, _) {
                return LinearProgressIndicator(
                  value: value * animation.value,
                  minHeight: 10,
                  backgroundColor: Colors.grey.withOpacity(0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                );
              },
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 38,
          child: Text(
            '$pct%',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}

// ── Confidence Badge (pulsing) ─────────────────────────────────────────────────
class _ConfidenceBadge extends StatefulWidget {
  final String confidence;
  const _ConfidenceBadge({required this.confidence});

  @override
  State<_ConfidenceBadge> createState() => _ConfidenceBadgeState();
}

class _ConfidenceBadgeState extends State<_ConfidenceBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color get _badgeColor {
    switch (widget.confidence) {
      case 'High':
        return AppTheme.success;
      case 'Medium':
        return AppTheme.warning;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _pulse,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: _badgeColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _badgeColor.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, size: 14, color: _badgeColor),
            const SizedBox(width: 6),
            Text(
              '${widget.confidence} Confidence',
              style: TextStyle(
                color: _badgeColor,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Key Player Tile ────────────────────────────────────────────────────────────
class _KeyPlayerTile extends StatelessWidget {
  final Player? player;
  final String teamName;
  final bool isDark;

  const _KeyPlayerTile({
    required this.player,
    required this.teamName,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (player == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
          ),
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey.withOpacity(0.2),
              child: const Icon(Icons.person, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(teamName,
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
            backgroundImage:
                player!.photoUrl.isNotEmpty ? NetworkImage(player!.photoUrl) : null,
            child: player!.photoUrl.isEmpty
                ? Text(
                    player!.name.split(' ').map((e) => e[0]).take(2).join(),
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 8),
          Text(
            player!.name,
            style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            player!.position,
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '⭐ ${player!.rating} OVR',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Flag image ─────────────────────────────────────────────────────────────────
class _FlagImage extends StatelessWidget {
  final String flagCode;
  final double size;
  final double radius;

  const _FlagImage({required this.flagCode, required this.size, required this.radius});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.network(
        AppConstants.getFlagUrl(flagCode),
        width: size,
        height: size * 0.67,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Icon(Icons.flag, size: size * 0.67),
      ),
    );
  }
}

// ── Empty State ────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final bool isDark;
  const _EmptyState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.sports_soccer,
            size: 64,
            color: Colors.grey.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No upcoming matches found',
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back when new matches are scheduled.',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.withOpacity(0.6)),
          ),
        ],
      ),
    );
  }
}
