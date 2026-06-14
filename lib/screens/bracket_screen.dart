import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/match.dart';
import '../providers/match_provider.dart';
import '../core/constants.dart';
import '../core/theme.dart';

class BracketScreen extends ConsumerWidget {
  const BracketScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final matchState = ref.watch(matchProvider);

    // Separate knockout matches (no group) that have a stage
    final knockoutMatches = matchState.allMatches
        .where((m) => m.group == null && m.stage != null)
        .toList()
      ..sort((a, b) => a.kickoffTime.compareTo(b.kickoffTime));

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'KNOCKOUT STAGE',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tournament Bracket',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),

            // Bracket
            Expanded(
              child: matchState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _BracketView(knockoutMatches: knockoutMatches),
            ),
          ],
        ),
      ),
    );
  }
}

class _BracketView extends StatelessWidget {
  final List<Match> knockoutMatches;

  const _BracketView({required this.knockoutMatches});

  @override
  Widget build(BuildContext context) {
    // Group by round
    final rounds = <String, List<Match>>{};
    final roundOrder = ['Round of 32', 'Round of 16', 'Quarterfinal', 'Semifinal', 'Final'];

    for (final m in knockoutMatches) {
      final stage = _normalizeStage(m.stage ?? '');
      rounds.putIfAbsent(stage, () => []).add(m);
    }

    // If no knockout matches from API, show placeholder bracket
    final hasData = rounds.isNotEmpty;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: hasData
            ? roundOrder
                .where((r) => rounds.containsKey(r))
                .map((roundName) => _RoundColumn(
                      roundName: roundName,
                      matches: rounds[roundName]!,
                    ))
                .toList()
            : _buildPlaceholderBracket(context),
      ),
    );
  }

  String _normalizeStage(String stage) {
    final s = stage.toLowerCase();
    if (s.contains('32') || s.contains('r32')) return 'Round of 32';
    if (s.contains('16') || s.contains('r16')) return 'Round of 16';
    if (s.contains('quarter') || s.contains('qf')) return 'Quarterfinal';
    if (s.contains('semi') || s.contains('sf')) return 'Semifinal';
    if (s.contains('final') && !s.contains('semi')) return 'Final';
    if (s.contains(' f') || s == 'f') return 'Final';
    return stage;
  }

  List<Widget> _buildPlaceholderBracket(BuildContext context) {
    final rounds = [
      ('Round of 32', 16),
      ('Round of 16', 8),
      ('Quarterfinal', 4),
      ('Semifinal', 2),
      ('Final', 1),
    ];
    return rounds
        .map((r) => _RoundColumn(
              roundName: r.$1,
              matches: List.generate(
                r.$2,
                (i) => _TbdMatch(index: i),
              ),
              isTbd: true,
            ))
        .toList();
  }
}

// Dummy TBD match
class _TbdMatch {
  final int index;
  _TbdMatch({required this.index});
}

class _RoundColumn extends StatelessWidget {
  final String roundName;
  final List<dynamic> matches; // Match or _TbdMatch
  final bool isTbd;

  const _RoundColumn({
    required this.roundName,
    required this.matches,
    this.isTbd = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Round label
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              roundName,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Match cards
          ...matches.map((m) {
            if (m is _TbdMatch || isTbd) {
              return _TbdMatchCard(isDark: isDark, theme: theme);
            }
            return _MatchBracketCard(match: m as Match, theme: theme, isDark: isDark);
          }),
        ],
      ),
    );
  }
}

class _MatchBracketCard extends StatelessWidget {
  final Match match;
  final ThemeData theme;
  final bool isDark;

  const _MatchBracketCard({
    required this.match,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isLive = match.status == MatchStatus.live || match.status == MatchStatus.halftime;
    final isFinished = match.status == MatchStatus.finished;
    final homeWon = isFinished && match.homeScore > match.awayScore;
    final awayWon = isFinished && match.awayScore > match.homeScore;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLive
              ? AppTheme.liveColor
              : isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.08),
        ),
      ),
      child: Column(
        children: [
          _TeamRow(
            teamName: match.homeTeam.name,
            teamCode: match.homeTeam.code,
            flagCode: match.homeTeam.flagCode,
            score: isFinished || isLive ? match.homeScore : null,
            isWinner: homeWon,
            theme: theme,
          ),
          Divider(height: 1, color: isDark ? Colors.white12 : Colors.black12),
          _TeamRow(
            teamName: match.awayTeam.name,
            teamCode: match.awayTeam.code,
            flagCode: match.awayTeam.flagCode,
            score: isFinished || isLive ? match.awayScore : null,
            isWinner: awayWon,
            theme: theme,
          ),
        ],
      ),
    );
  }
}

class _TeamRow extends StatelessWidget {
  final String teamName;
  final String teamCode;
  final String flagCode;
  final int? score;
  final bool isWinner;
  final ThemeData theme;

  const _TeamRow({
    required this.teamName,
    required this.teamCode,
    required this.flagCode,
    required this.score,
    required this.isWinner,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: Image.network(
              AppConstants.getFlagUrl(flagCode),
              width: 22,
              height: 15,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(Icons.flag, size: 15),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              teamCode,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
                color: isWinner ? theme.colorScheme.primary : null,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (score != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isWinner
                    ? theme.colorScheme.primary.withOpacity(0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$score',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isWinner ? theme.colorScheme.primary : Colors.grey,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TbdMatchCard extends StatelessWidget {
  final bool isDark;
  final ThemeData theme;

  const _TbdMatchCard({required this.isDark, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.07) : Colors.black.withOpacity(0.06),
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          _TbdTeamRow(theme: theme),
          Divider(height: 1, color: isDark ? Colors.white12 : Colors.black12),
          _TbdTeamRow(theme: theme),
        ],
      ),
    );
  }
}

class _TbdTeamRow extends StatelessWidget {
  final ThemeData theme;
  const _TbdTeamRow({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 15,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'TBD',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
