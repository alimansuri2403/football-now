import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/match.dart';
import '../providers/match_provider.dart';
import '../providers/player_providers.dart';
import '../widgets/match_stat_bar.dart';
import '../widgets/shimmer_loading.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../services/ad_service.dart';
import '../services/espn_api.dart';

class MatchDetailScreen extends ConsumerStatefulWidget {
  final String matchId;

  const MatchDetailScreen({super.key, required this.matchId});

  @override
  ConsumerState<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends ConsumerState<MatchDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Track match detail open count and show interstitial ad on every 5th open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        AdService().incrementMatchDetailOpensAndShow(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final matchAsync = ref.watch(matchDetailProvider(widget.matchId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Match Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            tooltip: 'Live Fan Chat',
            onPressed: () {
              matchAsync.whenData((match) {
                if (match != null) {
                  final title = '${match.homeTeam.code} vs ${match.awayTeam.code}';
                  context.push('/chat/${match.id}/${Uri.encodeComponent(title)}');
                }
              });
            },
          ),
        ],
      ),
      body: matchAsync.when(
        data: (match) {
          if (match == null) {
            return const Center(child: Text('Match not found'));
          }
          return DefaultTabController(
            length: 5,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  _buildScoreboardHeader(theme, match),
                  const SizedBox(height: 24),
                  TabBar(
                    dividerColor: Colors.transparent,
                    indicatorColor: theme.colorScheme.primary,
                    labelColor: theme.colorScheme.primary,
                    unselectedLabelColor: Colors.grey,
                    isScrollable: true,
                    tabs: const [
                      Tab(text: 'Statistics'),
                      Tab(text: 'Timeline'),
                      Tab(text: 'Lineups'),
                      Tab(text: 'H2H'),
                      Tab(text: 'AI Summary'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 520,
                    child: TabBarView(
                      children: [
                        _buildStatsTab(match),
                        _buildTimelineTab(theme, match),
                        _buildLineupsTab(ref, match),
                        _buildH2hTab(match),
                        _buildAiSummaryTab(match),
                      ],
                    ),
                  )
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildScoreboardHeader(ThemeData theme, Match match) {
    final isLive = match.status == MatchStatus.live;
    final isFinished = match.status == MatchStatus.finished;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          // Match Venue & Group Info
          Text(
            '${match.group} • ${match.venue}',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            DateFormat('MMMM d, yyyy - HH:mm').format(match.dateTime),
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          // Scores and Flags
          Row(
            children: [
              // Home Team
              Expanded(
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        AppConstants.getFlagUrl(match.homeTeam.flagCode),
                        width: 72,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.flag, size: 48),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      match.homeTeam.name,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              // Score Line
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          isFinished || isLive ? '${match.homeScore}' : '-',
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            fontSize: 48,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          ':',
                          style: theme.textTheme.headlineLarge?.copyWith(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          isFinished || isLive ? '${match.awayScore}' : '-',
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            fontSize: 48,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Live status / Scheduled marker
                    if (isLive)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "LIVE ${match.currentMinute}'",
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else if (isFinished)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "FULL TIME",
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "SCHEDULED",
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                  ],
                ),
              ),
              // Away Team
              Expanded(
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        AppConstants.getFlagUrl(match.awayTeam.flagCode),
                        width: 72,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.flag, size: 48),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      match.awayTeam.name,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildStatsTab(Match match) {
    if (match.status == MatchStatus.scheduled) {
      return const Center(child: Text('Statistics will be available when match starts.'));
    }

    final stats = match.stats;
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      children: [
        MatchStatBar(label: 'Ball Possession', homeVal: stats.homePossession, awayVal: stats.awayPossession, isPercentage: true),
        MatchStatBar(label: 'Shots on Target', homeVal: stats.homeShotsOnGoal, awayVal: stats.awayShotsOnGoal),
        MatchStatBar(label: 'Total Shots', homeVal: stats.homeTotalShots, awayVal: stats.awayTotalShots),
        MatchStatBar(label: 'Corners', homeVal: stats.homeCorners, awayVal: stats.awayCorners),
        MatchStatBar(label: 'Fouls Committed', homeVal: stats.homeFouls, awayVal: stats.awayFouls),
        MatchStatBar(label: 'Yellow Cards', homeVal: stats.homeYellowCards, awayVal: stats.awayYellowCards),
        MatchStatBar(label: 'Offsides', homeVal: stats.homeOffsides, awayVal: stats.awayOffsides),
      ],
    );
  }

  Widget _buildTimelineTab(ThemeData theme, Match match) {
    if (match.events.isEmpty) {
      return const Center(child: Text('No timeline events recorded yet.'));
    }

    return ListView.builder(
      itemCount: match.events.length,
      itemBuilder: (context, index) {
        final event = match.events[index];
        final isHome = event.teamId == match.homeTeam.id;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: isHome ? MainAxisAlignment.start : MainAxisAlignment.end,
            children: [
              if (isHome) ...[
                _buildTimelineIcon(event.type),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          "${event.minute}'",
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Text(event.playerName, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Text(event.detail, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                  ],
                ),
              ] else ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Text(event.playerName, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        Text(
                          "${event.minute}'",
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Text(event.detail, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                  ],
                ),
                const SizedBox(width: 12),
                _buildTimelineIcon(event.type),
              ]
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimelineIcon(MatchEventType type) {
    switch (type) {
      case MatchEventType.goal:
        return const CircleAvatar(
          radius: 14,
          backgroundColor: Colors.green,
          child: Icon(Icons.sports_soccer, size: 16, color: Colors.white),
        );
      case MatchEventType.card:
        return const CircleAvatar(
          radius: 14,
          backgroundColor: Colors.amber,
          child: Icon(Icons.style, size: 14, color: Colors.black),
        );
      case MatchEventType.substitution:
        return const CircleAvatar(
          radius: 14,
          backgroundColor: Colors.blue,
          child: Icon(Icons.swap_horiz, size: 16, color: Colors.white),
        );
    }
  }

  Widget _buildLineupsTab(WidgetRef ref, Match match) {
    final homePlayersAsync = ref.watch(teamPlayersProvider(match.homeTeam.id));
    final awayPlayersAsync = ref.watch(teamPlayersProvider(match.awayTeam.id));

    return homePlayersAsync.when(
      data: (homePlayers) {
        return awayPlayersAsync.when(
          data: (awayPlayers) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: homePlayers.length,
                    itemBuilder: (context, index) {
                      final p = homePlayers[index];
                      return ListTile(
                        leading: CircleAvatar(child: Text('${p.number}')),
                        title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(p.position),
                      );
                    },
                  ),
                ),
                const VerticalDivider(),
                Expanded(
                  child: ListView.builder(
                    itemCount: awayPlayers.length,
                    itemBuilder: (context, index) {
                      final p = awayPlayers[index];
                      return ListTile(
                        trailing: CircleAvatar(child: Text('${p.number}')),
                        title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right),
                        subtitle: Text(p.position, textAlign: TextAlign.right),
                      );
                    },
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(child: Text('Error: $e')),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildH2hTab(Match match) {
    final espnApi = ref.read(espnApiProvider);
    final theme = Theme.of(context);

    return FutureBuilder<List<H2hMeeting>>(
      future: espnApi.fetchMatchSummary(match.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error loading H2H records: ${snapshot.error}'));
        }

        final meetings = snapshot.data ?? [];
        if (meetings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey.withOpacity(0.5)),
                const SizedBox(height: 16),
                Text(
                  'No historical head-to-head records found.',
                  style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: meetings.length,
          itemBuilder: (context, index) {
            final meeting = meetings[index];
            final kickoffDate = DateTime.tryParse(meeting.date);
            final formattedDate = kickoffDate != null
                ? DateFormat('MMMM d, yyyy').format(kickoffDate)
                : meeting.date;

            // Determine meeting result badge color
            Color badgeColor = Colors.grey;
            if (meeting.result.toUpperCase() == 'W') {
              badgeColor = Colors.green;
            } else if (meeting.result.toUpperCase() == 'L') {
              badgeColor = Colors.red;
            } else if (meeting.result.toUpperCase() == 'D') {
              badgeColor = Colors.amber;
            }

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          meeting.competition,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: badgeColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            meeting.result,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: badgeColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formattedDate,
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Primary Team (from scoreboard perspective)
                        Expanded(
                          child: Text(
                            meeting.isHome ? match.homeTeam.name : match.awayTeam.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        // Score
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            meeting.score,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        // Opponent Team
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Flexible(
                                child: Text(
                                  meeting.opponentName,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.end,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (meeting.opponentLogo.isNotEmpty)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Image.network(
                                    meeting.opponentLogo,
                                    width: 28,
                                    height: 20,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Icon(Icons.flag, size: 20),
                                  ),
                                )
                              else
                                const Icon(Icons.flag, size: 20),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAiSummaryTab(Match match) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Generate dynamic summary
    String summaryTitle = '';
    String summaryBody = '';
    String starPlayer = 'Not decided yet';
    String starPlayerDetail = '';

    if (match.status == MatchStatus.scheduled) {
      summaryTitle = 'Upcoming Clash Analysis';
      summaryBody = 'This is an upcoming match scheduled at ${match.venue} in ${match.city ?? 'host city'}. '
          'According to current FIFA rankings, ${match.homeTeam.name} (#${match.homeTeam.fifaRanking}) is set to face '
          '${match.awayTeam.name} (#${match.awayTeam.fifaRanking}). This looks to be a highly competitive encounter '
          'with both teams aiming to secure crucial points in the tournament.';
      starPlayer = '${match.homeTeam.name} / ${match.awayTeam.name}';
      starPlayerDetail = 'Look out for key playmakers on both sides to dominate midfield possession.';
    } else if (match.status == MatchStatus.live || match.status == MatchStatus.halftime) {
      summaryTitle = 'Live Match Summary';
      summaryBody = 'A live battle is currently unfolding! The score is ${match.homeScore} - ${match.awayScore} in the ${match.currentMinute}th minute. '
          'Both sides have shown high intensity. ${match.homeTeam.name} is working to enforce possession, while '
          '${match.awayTeam.name} is posing a severe threat on counter-attacks. Everything is still to play for.';
      starPlayer = 'Active Midfielders';
      starPlayerDetail = 'Playmakers are controlling the tempo as the tension escalates in real-time.';
    } else if (match.status == MatchStatus.finished) {
      summaryTitle = 'Post-Match AI Report';
      final homeName = match.homeTeam.name;
      final awayName = match.awayTeam.name;
      final homeScore = match.homeScore;
      final awayScore = match.awayScore;

      if (homeScore > awayScore) {
        summaryBody = 'A dominant performance by $homeName resulted in a $homeScore - $awayScore victory over $awayName at ${match.venue}. '
            'The home team asserted their dominance early on, converting key opportunities and maintaining defensive discipline. '
            'Despite late pressure from $awayName, $homeName successfully closed out the match to claim all three points.';
        starPlayer = '$homeName Attacker';
        starPlayerDetail = 'Made the difference by finding spaces in the box and clinching the decisive goal.';
      } else if (awayScore > homeScore) {
        summaryBody = 'An outstanding away display saw $awayName snatch a $homeScore - $awayScore win against $homeName. '
            'Capitalizing on tactical opportunities, the visitors broke down $homeName\'s backline to secure the goals. '
            'An intense defensive effort in the final minutes guaranteed they took home the win.';
        starPlayer = '$awayName Forward';
        starPlayerDetail = 'Posed a constant threat to the defenders, creating multiple chances and scoring.';
      } else {
        summaryBody = 'A tactical stalemate ended in a $homeScore - $awayScore draw between $homeName and $awayName. '
            'Both teams had their chances to win it, but stout defending and top-tier goalkeeping kept the score level. '
            'Both federations will take a point from this closely contested affair.';
        starPlayer = 'Starting Goalkeepers';
        starPlayerDetail = 'Pulled off several crucial saves to deny the attackers and secure the draw.';
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Explain in 30 seconds card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: AppTheme.glassDecoration(context: context, radius: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.video_camera_back_outlined, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    const Text(
                      '30-SECOND SUMMARY',
                      style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  summaryTitle,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  summaryBody,
                  style: const TextStyle(fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Star Player card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: AppTheme.glassDecoration(context: context, radius: 20),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
                  radius: 24,
                  child: Icon(Icons.star, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'MATCH STAR PLAYER',
                        style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        starPlayer,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        starPlayerDetail,
                        style: const TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Match summary highlights key moments
          if (match.events.isNotEmpty) ...[
            Text(
              'Key Moments Timeline',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: match.events.length,
              itemBuilder: (context, idx) {
                final e = match.events[idx];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${e.minute}\'',
                          style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary, fontSize: 11),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${e.playerName} - ${e.detail}',
                          style: const TextStyle(fontSize: 12.5),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
