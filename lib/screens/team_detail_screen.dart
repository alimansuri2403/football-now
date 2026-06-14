import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/team.dart';
import '../models/player.dart';
import '../models/match.dart';
import '../providers/team_providers.dart';
import '../providers/player_providers.dart';
import '../providers/favourites_provider.dart';
import '../providers/match_provider.dart';
import '../providers/timezone_provider.dart';
import '../widgets/player_avatar.dart';
import '../core/constants.dart';
import '../core/theme.dart';

class TeamDetailScreen extends ConsumerWidget {
  final String teamId;

  const TeamDetailScreen({super.key, required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final teamAsync = ref.watch(teamDetailProvider(teamId));
    final playersAsync = ref.watch(teamPlayersProvider(teamId));
    final isFav = ref.watch(favouritesProvider).contains(teamId.toUpperCase());
    final matchState = ref.watch(matchProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Team Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            tooltip: isFav ? 'Remove from favourites' : 'Add to favourites',
            icon: Icon(
              isFav ? Icons.star : Icons.star_border,
              color: isFav ? Colors.amber : null,
            ),
            onPressed: () {
              ref.read(favouritesProvider.notifier).toggleFavourite(teamId);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isFav
                      ? 'Removed from favourites'
                      : 'Added to favourites ⭐'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: teamAsync.when(
        data: (team) {
          if (team == null) {
            return const Center(child: Text('Team not found'));
          }

          return DefaultTabController(
            length: 3,
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: _buildTeamHeader(theme, team),
                    ),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _SliverAppBarDelegate(
                      TabBar(
                        dividerColor: Colors.transparent,
                        indicatorColor: theme.colorScheme.primary,
                        labelColor: theme.colorScheme.primary,
                        unselectedLabelColor: Colors.grey,
                        labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                        tabs: const [
                          Tab(text: 'Squad'),
                          Tab(text: 'Upcoming'),
                          Tab(text: 'Results'),
                        ],
                      ),
                      theme.scaffoldBackgroundColor,
                    ),
                  ),
                ];
              },
              body: TabBarView(
                children: [
                  _buildSquadTab(context, theme, playersAsync),
                  _buildUpcomingTab(context, ref, theme, matchState.allMatches),
                  _buildResultsTab(context, ref, theme, matchState.allMatches),
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

  Widget _buildTeamHeader(ThemeData theme, Team team) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              AppConstants.getFlagUrl(team.flagCode),
              width: 96,
              height: 64,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.flag, size: 64),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  team.name,
                  style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Group ${team.group} • Coach: ${team.coach}',
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  'FIFA Ranking: #${team.fifaRanking}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSquadTab(BuildContext context, ThemeData theme, AsyncValue<List<Player>> playersAsync) {
    return playersAsync.when(
      data: (players) {
        if (players.isEmpty) {
          return const Center(child: Text('No squad players registered in database yet.'));
        }

        // Group by position
        final forwards = players.where((p) => p.position.toLowerCase() == 'forward').toList();
        final midfielders = players.where((p) => p.position.toLowerCase() == 'midfielder').toList();
        final defenders = players.where((p) => p.position.toLowerCase() == 'defender').toList();
        final keepers = players.where((p) => p.position.toLowerCase() == 'goalkeeper').toList();

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          children: [
            if (forwards.isNotEmpty) _buildPositionGroup(context, theme, 'Forwards', forwards),
            if (midfielders.isNotEmpty) _buildPositionGroup(context, theme, 'Midfielders', midfielders),
            if (defenders.isNotEmpty) _buildPositionGroup(context, theme, 'Defenders', defenders),
            if (keepers.isNotEmpty) _buildPositionGroup(context, theme, 'Goalkeepers', keepers),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error loading squad: $err')),
    );
  }

  Widget _buildPositionGroup(BuildContext context, ThemeData theme, String title, List<Player> players) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey, fontWeight: FontWeight.bold),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: players.length,
          itemBuilder: (context, index) {
            final p = players[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                leading: PlayerAvatar(player: p, radius: 20),
                title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Age: ${p.age}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  context.push('/players/player/${p.id}');
                },
              ),
            );
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildUpcomingTab(BuildContext context, WidgetRef ref, ThemeData theme, List<Match> allMatches) {
    final upcomingMatches = allMatches.where((m) {
      final isThisTeam = m.homeTeam.id.toUpperCase() == teamId.toUpperCase() ||
          m.awayTeam.id.toUpperCase() == teamId.toUpperCase();
      final isUpcoming = m.status == MatchStatus.scheduled || m.status == MatchStatus.postponed;
      return isThisTeam && isUpcoming;
    }).toList();

    if (upcomingMatches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.calendar_today_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No upcoming matches scheduled',
              style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    upcomingMatches.sort((a, b) => a.kickoffTime.compareTo(b.kickoffTime));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: upcomingMatches.length,
      itemBuilder: (context, index) {
        return _buildTeamMatchCard(context, ref, theme, upcomingMatches[index]);
      },
    );
  }

  Widget _buildResultsTab(BuildContext context, WidgetRef ref, ThemeData theme, List<Match> allMatches) {
    final resultsMatches = allMatches.where((m) {
      final isThisTeam = m.homeTeam.id.toUpperCase() == teamId.toUpperCase() ||
          m.awayTeam.id.toUpperCase() == teamId.toUpperCase();
      final isPast = m.status == MatchStatus.finished ||
          m.status == MatchStatus.live ||
          m.status == MatchStatus.halftime;
      return isThisTeam && isPast;
    }).toList();

    if (resultsMatches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.history_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No match results available yet',
              style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    resultsMatches.sort((a, b) => b.kickoffTime.compareTo(a.kickoffTime));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: resultsMatches.length,
      itemBuilder: (context, index) {
        return _buildTeamMatchCard(context, ref, theme, resultsMatches[index]);
      },
    );
  }

  Widget _buildTeamMatchCard(BuildContext context, WidgetRef ref, ThemeData theme, Match match) {
    final isFinished = match.status == MatchStatus.finished;
    final isLive = match.status == MatchStatus.live || match.status == MatchStatus.halftime;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          context.push('/match/${match.id}');
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Top line: Group or stage info and venue
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    match.group != null ? 'Group ${match.group}' : (match.stage ?? ''),
                    style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    match.venue.split(',').first,
                    style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Main row with Teams & scores/VS
              Row(
                children: [
                  // Home team
                  Expanded(
                    flex: 3,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(
                          child: Text(
                            match.homeTeam.name,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: match.homeTeam.id.toUpperCase() == teamId.toUpperCase()
                                  ? FontWeight.w800
                                  : FontWeight.normal,
                              color: match.homeTeam.id.toUpperCase() == teamId.toUpperCase()
                                  ? theme.colorScheme.primary
                                  : null,
                            ),
                            textAlign: TextAlign.end,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(
                            AppConstants.getFlagUrl(match.homeTeam.flagCode),
                            width: 32,
                            height: 22,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.flag, size: 22),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // VS / Scores
                  Expanded(
                    flex: 2,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isLive
                              ? AppTheme.liveColor.withOpacity(0.15)
                              : isFinished
                                  ? Colors.grey.withOpacity(0.1)
                                  : theme.colorScheme.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isFinished || isLive
                              ? '${match.homeScore} - ${match.awayScore}'
                              : 'VS',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isLive ? AppTheme.liveColor : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Away team
                  Expanded(
                    flex: 3,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(
                            AppConstants.getFlagUrl(match.awayTeam.flagCode),
                            width: 32,
                            height: 22,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.flag, size: 22),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            match.awayTeam.name,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: match.awayTeam.id.toUpperCase() == teamId.toUpperCase()
                                  ? FontWeight.w800
                                  : FontWeight.normal,
                              color: match.awayTeam.id.toUpperCase() == teamId.toUpperCase()
                                  ? theme.colorScheme.primary
                                  : null,
                            ),
                            textAlign: TextAlign.start,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Kickoff time or Live min
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isLive)
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppTheme.liveColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "LIVE ${match.minute}'",
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: AppTheme.liveColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      _localKickoffTimeStr(ref, match.kickoffTime),
                      style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _localKickoffTimeStr(WidgetRef ref, DateTime utcTime) {
    final tzNotifier = ref.read(timezoneProvider.notifier);
    final tzState = ref.read(timezoneProvider);
    final local = tzNotifier.convertToLocal(utcTime);
    return '${DateFormat('EEE, MMM d, yyyy \u2022 HH:mm').format(local)} ${tzState.timezoneAbbreviation}';
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color backgroundColor;

  _SliverAppBarDelegate(this.tabBar, this.backgroundColor);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: backgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
