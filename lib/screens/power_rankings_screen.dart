import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/player.dart';
import '../providers/player_providers.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../widgets/shimmer_loading.dart';

class PowerRankingsScreen extends ConsumerWidget {
  const PowerRankingsScreen({super.key});

  double _computePowerScore(Player player) {
    return (player.stats.goals * 3) + (player.stats.assists * 2) + (player.rating * 0.1);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final playersAsync = ref.watch(playersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Power Rankings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(playersProvider),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.refresh(playersProvider);
        },
        child: playersAsync.when(
          data: (players) {
            // Sort players by power score descending
            final sortedPlayers = List<Player>.from(players);
            sortedPlayers.sort((a, b) => _computePowerScore(b).compareTo(_computePowerScore(a)));

            if (sortedPlayers.isEmpty) {
              return const Center(child: Text('No players found'));
            }

            final top3 = sortedPlayers.take(3).toList();
            final rest = sortedPlayers.skip(3).take(17).toList();

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'POWER RANKINGS',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Top Performers',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── PODIUM DISPLAY ──
                  if (top3.isNotEmpty) _buildPodium(context, top3, theme, isDark),
                  const SizedBox(height: 32),

                  // ── LEADERBOARD LIST ──
                  Text(
                    'Tournament Leaderboard',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: rest.length,
                    itemBuilder: (context, index) {
                      final player = rest[index];
                      final rank = index + 4;
                      final score = _computePowerScore(player);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: AppTheme.glassDecoration(context: context, radius: 12),
                        child: ListTile(
                          onTap: () => context.push('/players/player/${player.id}'),
                          leading: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 24,
                                child: Text(
                                  '$rank',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(width: 12),
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                                backgroundImage: player.photoUrl.isNotEmpty ? NetworkImage(player.photoUrl) : null,
                                child: player.photoUrl.isEmpty
                                    ? Text(
                                        player.name.split(' ').map((e) => e[0]).take(2).join(),
                                        style: TextStyle(color: theme.colorScheme.primary, fontSize: 12),
                                      )
                                    : null,
                              ),
                            ],
                          ),
                          title: Text(
                            player.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${player.teamName} • ${player.position}',
                            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              score.toStringAsFixed(1),
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error loading rankings: $err')),
        ),
      ),
    );
  }

  Widget _buildPodium(BuildContext context, List<Player> top3, ThemeData theme, bool isDark) {
    // top3 order: index 0 = Gold (#1), index 1 = Silver (#2), index 2 = Bronze (#3)
    final p1 = top3[0];
    final p2 = top3.length > 1 ? top3[1] : null;
    final p3 = top3.length > 2 ? top3[2] : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // #2 Silver (Left side)
        if (p2 != null)
          Expanded(
            child: _buildPodiumCard(
              context: context,
              player: p2,
              rank: 2,
              theme: theme,
              isDark: isDark,
              height: 160,
              accentColor: const Color(0xFFC0C0C0), // Silver
              icon: Icons.looks_two,
            ),
          )
        else
          const Spacer(),

        const SizedBox(width: 8),

        // #1 Gold (Center)
        Expanded(
          child: _buildPodiumCard(
            context: context,
            player: p1,
            rank: 1,
            theme: theme,
            isDark: isDark,
            height: 190,
            accentColor: const Color(0xFFFFD700), // Gold
            icon: Icons.emoji_events,
          ),
        ),

        const SizedBox(width: 8),

        // #3 Bronze (Right side)
        if (p3 != null)
          Expanded(
            child: _buildPodiumCard(
              context: context,
              player: p3,
              rank: 3,
              theme: theme,
              isDark: isDark,
              height: 140,
              accentColor: const Color(0xFFCD7F32), // Bronze
              icon: Icons.looks_3,
            ),
          )
        else
          const Spacer(),
      ],
    );
  }

  Widget _buildPodiumCard({
    required BuildContext context,
    required Player player,
    required int rank,
    required ThemeData theme,
    required bool isDark,
    required double height,
    required Color accentColor,
    required IconData icon,
  }) {
    final score = _computePowerScore(player);
    return GestureDetector(
      onTap: () => context.push('/players/player/${player.id}'),
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.03),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: accentColor.withOpacity(0.4),
            width: rank == 1 ? 2 : 1,
          ),
          boxShadow: rank == 1
              ? [
                  BoxShadow(
                    color: accentColor.withOpacity(0.15),
                    blurRadius: 16,
                    spreadRadius: 2,
                  )
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: rank == 1 ? 32 : 24,
                  backgroundColor: accentColor.withOpacity(0.2),
                  backgroundImage: player.photoUrl.isNotEmpty ? NetworkImage(player.photoUrl) : null,
                  child: player.photoUrl.isEmpty
                      ? Text(
                          player.name.split(' ').map((e) => e[0]).take(2).join(),
                          style: TextStyle(color: accentColor, fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: Icon(icon, color: accentColor, size: rank == 1 ? 22 : 18),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              player.name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: rank == 1 ? 14 : 12,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              player.teamName,
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey, fontSize: 10),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                score.toStringAsFixed(1),
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
