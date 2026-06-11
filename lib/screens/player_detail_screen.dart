import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/player.dart';
import '../providers/player_providers.dart';
import '../core/constants.dart';
import '../widgets/player_avatar.dart';

class PlayerDetailScreen extends ConsumerWidget {
  final String playerId;

  const PlayerDetailScreen({super.key, required this.playerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final playerAsync = ref.watch(playerDetailProvider(playerId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Player Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: playerAsync.when(
        data: (player) {
          if (player == null) {
            return const Center(child: Text('Player not found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPlayerHeader(theme, player),
                const SizedBox(height: 24),
                _buildStatsGrid(theme, player),
                const SizedBox(height: 24),
                if (player.pastRecords.isNotEmpty) ...[
                  _buildPastRecordsCard(theme, player),
                  const SizedBox(height: 24),
                ],
                _buildAttributeRadar(theme, player, isDark),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildPlayerHeader(ThemeData theme, Player player) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          PlayerAvatar(player: player, radius: 40, fontSize: 28),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.name,
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  '${player.position} • Number ${player.number}',
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  'Team: ${player.teamName} • Age: ${player.age}',
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                ),
              ],
            ),
          ),
          // Large Overall Rating Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [theme.colorScheme.primary, theme.colorScheme.primary.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${player.rating}',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: theme.brightness == Brightness.dark ? Colors.black : Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 28,
                  ),
                ),
                Text(
                  'OVR',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.brightness == Brightness.dark ? Colors.black54 : Colors.white70,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(ThemeData theme, Player player) {
    final stats = player.stats;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.3,
      children: [
        _buildStatCard(theme, 'Goals', '${stats.goals}', Icons.sports_soccer, Colors.green),
        _buildStatCard(theme, 'Assists', '${stats.assists}', Icons.star, Colors.amber),
        _buildStatCard(theme, 'Minutes', '${stats.minutesPlayed}', Icons.timer, Colors.blue),
        _buildStatCard(theme, 'Matches', '${stats.matchesPlayed}', Icons.emoji_events, Colors.orange),
        _buildStatCard(theme, 'Yellows', '${stats.yellowCards}', Icons.style, Colors.yellow[700]!),
        _buildStatCard(theme, 'Reds', '${stats.redCards}', Icons.style, Colors.red),
      ],
    );
  }

  Widget _buildStatCard(ThemeData theme, String title, String val, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            val,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildPastRecordsCard(ThemeData theme, Player player) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.military_tech, color: theme.colorScheme.primary, size: 28),
              const SizedBox(width: 12),
              Text(
                'Career Milestones & Records',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          Column(
            children: player.pastRecords.map((record) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.emoji_events, color: Colors.amber[600], size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        record,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAttributeRadar(ThemeData theme, Player player, bool isDark) {
    // Attributes based on position
    final isForward = player.position.toLowerCase() == 'forward';
    final isMid = player.position.toLowerCase() == 'midfielder';
    
    // Custom mock attributes for visualization
    final double pace = isForward ? 92 : (isMid ? 80 : 70);
    final double shooting = isForward ? 94 : (isMid ? 84 : 50);
    final double passing = isMid ? 93 : (isForward ? 82 : 68);
    final double dribbling = (isForward || isMid) ? 90 : 70;
    final double defense = isForward ? 35 : (isMid ? 65 : 88);
    final double physical = isForward ? 80 : (isMid ? 78 : 85);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance Matrix',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          AspectRatio(
            aspectRatio: 1.3,
            child: RadarChart(
              RadarChartData(
                dataSets: [
                  RadarDataSet(
                    fillColor: theme.colorScheme.primary.withOpacity(0.25),
                    borderColor: theme.colorScheme.primary,
                    entryRadius: 3,
                    dataEntries: [
                      RadarEntry(value: pace),
                      RadarEntry(value: shooting),
                      RadarEntry(value: passing),
                      RadarEntry(value: dribbling),
                      RadarEntry(value: defense),
                      RadarEntry(value: physical),
                    ],
                  ),
                ],
                radarShape: RadarShape.polygon,
                titlePositionPercentageOffset: 0.2,
                titleTextStyle: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                getTitle: (index, angle) {
                  switch (index) {
                    case 0:
                      return const RadarChartTitle(text: 'Pace');
                    case 1:
                      return const RadarChartTitle(text: 'Shooting');
                    case 2:
                      return const RadarChartTitle(text: 'Passing');
                    case 3:
                      return const RadarChartTitle(text: 'Dribbling');
                    case 4:
                      return const RadarChartTitle(text: 'Defense');
                    case 5:
                      return const RadarChartTitle(text: 'Physicality');
                    default:
                      return const RadarChartTitle(text: '');
                  }
                },
                tickCount: 4,
                ticksTextStyle: const TextStyle(color: Colors.transparent),
                gridBorderData: BorderSide(color: isDark ? Colors.white24 : Colors.black12, width: 1),
                radarBorderData: BorderSide(color: isDark ? Colors.white38 : Colors.black26, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
