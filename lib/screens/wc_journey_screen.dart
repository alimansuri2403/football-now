import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../models/match.dart';
import '../models/team.dart';
import '../providers/match_provider.dart';
import '../providers/team_providers.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../widgets/shimmer_loading.dart';

class WcJourneyScreen extends ConsumerStatefulWidget {
  const WcJourneyScreen({super.key});

  @override
  ConsumerState<WcJourneyScreen> createState() => _WcJourneyScreenState();
}

class _WcJourneyScreenState extends ConsumerState<WcJourneyScreen> {
  String? _selectedTeamCode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final teamsAsync = ref.watch(teamsProvider);
    final matchState = ref.watch(matchProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('World Cup Journey'),
      ),
      body: SafeArea(
        child: teamsAsync.when(
          data: (teams) {
            if (teams.isEmpty) {
              return const Center(child: Text('No teams found.'));
            }

            // Set default selected team if not set
            _selectedTeamCode ??= teams.first.code;

            final selectedTeam = teams.firstWhere((t) => t.code == _selectedTeamCode);

            // Filter matches for the selected team
            final teamMatches = matchState.allMatches.where((m) {
              return m.homeTeam.code == _selectedTeamCode || m.awayTeam.code == _selectedTeamCode;
            }).toList()
              ..sort((a, b) => a.kickoffTime.compareTo(b.kickoffTime));

            // Separate into group and knockout matches
            final groupMatches = teamMatches.where((m) => m.group != null).toList();
            final knockoutMatches = teamMatches.where((m) => m.group == null).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Label
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'WORLD CUP JOURNEY',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Road to the Trophy',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Team Selector (Horizontal scroll flags)
                SizedBox(
                  height: 64,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    scrollDirection: Axis.horizontal,
                    itemCount: teams.length,
                    itemBuilder: (context, index) {
                      final team = teams[index];
                      final isSelected = team.code == _selectedTeamCode;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedTeamCode = team.code;
                          });
                        },
                        child: AnimatedContainer(
                          duration: AppConstants.shortAnimation,
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.colorScheme.primary.withOpacity(0.15)
                                : (isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03)),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: Image.network(
                                  AppConstants.getFlagUrl(team.flagCode),
                                  width: 24,
                                  height: 16,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.flag, size: 16),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                team.code,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? theme.colorScheme.primary : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // Vertical Journey Timeline
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        // Stage 1: Qualification
                        _buildTimelineItem(
                          stageName: 'Stage 1: Qualification',
                          title: 'Qualified for FIFA World Cup 2026',
                          subtitle: 'Passed regional federation stages to secure a spot in the final 48 teams.',
                          icon: Icons.check_circle,
                          color: AppTheme.success,
                          theme: theme,
                          isFirst: true,
                        ),

                        // Stage 2: Group Stage
                        _buildTimelineItem(
                          stageName: 'Stage 2: Group Stage',
                          title: 'Group ${selectedTeam.group} Campaign',
                          child: _buildGroupMatchesTimeline(groupMatches, theme),
                          icon: Icons.grid_view,
                          color: Colors.amber,
                          theme: theme,
                        ),

                        // Stage 3: Knockouts
                        _buildTimelineItem(
                          stageName: 'Stage 3: Knockout Route',
                          title: 'Knockout Stage Progression',
                          child: knockoutMatches.isEmpty
                              ? const Text(
                                  'Knockout matches have not been scheduled yet or team did not qualify.',
                                  style: TextStyle(color: Colors.grey, fontSize: 12),
                                )
                              : _buildKnockoutMatchesTimeline(knockoutMatches, theme),
                          icon: Icons.emoji_events,
                          color: theme.colorScheme.primary,
                          theme: theme,
                          isLast: true,
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error loading team journeys: $err')),
        ),
      ),
    );
  }

  Widget _buildTimelineItem({
    required String stageName,
    required String title,
    String? subtitle,
    Widget? child,
    required IconData icon,
    required Color color,
    required ThemeData theme,
    bool isFirst = false,
    bool isLast = false,
  }) {
    final isDark = theme.brightness == Brightness.dark;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Indicator column
          Column(
            children: [
              // Line top
              Container(
                width: 2,
                height: 16,
                color: isFirst ? Colors.transparent : Colors.grey.withOpacity(0.3),
              ),
              // Circle icon
              Icon(icon, color: color, size: 24),
              // Line bottom
              Expanded(
                child: Container(
                  width: 2,
                  color: isLast ? Colors.transparent : Colors.grey.withOpacity(0.3),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),

          // Content card column
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: AppTheme.glassDecoration(context: context, radius: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stageName.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                    if (child != null) ...[
                      const SizedBox(height: 12),
                      child,
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupMatchesTimeline(List<Match> matches, ThemeData theme) {
    if (matches.isEmpty) {
      return const Text(
        'Group stage matches have not been generated.',
        style: TextStyle(color: Colors.grey, fontSize: 12),
      );
    }

    return Column(
      children: matches.map((m) => _buildTimelineMatchTile(m, theme)).toList(),
    );
  }

  Widget _buildKnockoutMatchesTimeline(List<Match> matches, ThemeData theme) {
    return Column(
      children: matches.map((m) => _buildTimelineMatchTile(m, theme)).toList(),
    );
  }

  Widget _buildTimelineMatchTile(Match m, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final isFinished = m.status == MatchStatus.finished;
    final isLive = m.status == MatchStatus.live || m.status == MatchStatus.halftime;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: Image.network(
                    AppConstants.getFlagUrl(m.homeTeam.flagCode),
                    width: 20,
                    height: 14,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 6),
                Text(m.homeTeam.code, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            if (isFinished || isLive)
              Text(
                '${m.homeScore} - ${m.awayScore}',
                style: TextStyle(fontWeight: FontWeight.w900, color: theme.colorScheme.primary),
              )
            else
              const Text('VS', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            Row(
              children: [
                Text(m.awayTeam.code, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: Image.network(
                    AppConstants.getFlagUrl(m.awayTeam.flagCode),
                    width: 20,
                    height: 14,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('MMM d, y').format(m.kickoffTime),
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
              if (isLive)
                const Text(
                  'LIVE NOW',
                  style: TextStyle(fontSize: 9, color: AppTheme.liveColor, fontWeight: FontWeight.bold),
                )
              else if (isFinished)
                const Text(
                  'FINAL',
                  style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold),
                )
              else
                Text(
                  'UPCOMING',
                  style: TextStyle(fontSize: 9, color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                ),
            ],
          ),
        ),
        onTap: () {
          // Navigate to match details screen
          // Since the routing structure pushes on rootNavigator, we can use context.push
          // context.push('/match/${m.id}');
        },
      ),
    );
  }
}
