import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/player.dart';
import '../core/theme.dart';
import '../core/constants.dart';

class PlayerCard extends StatelessWidget {
  final Player player;
  final int rank;
  final bool showGoals; // if true, highlight goals; if false, highlight assists

  const PlayerCard({
    super.key,
    required this.player,
    required this.rank,
    this.showGoals = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          context.go('/player/${player.id}');
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: AppTheme.glassDecoration(
            context: context,
            radius: 16,
            fillOpacity: isDark ? 0.05 : 0.03,
            borderOpacity: 0.1,
          ),
          child: Row(
            children: [
              // Rank
              Container(
                width: 32,
                alignment: Alignment.center,
                child: Text(
                  '#$rank',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: rank <= 3 ? theme.colorScheme.primary : Colors.grey,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Player Photo / Initials
              CircleAvatar(
                radius: 24,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                backgroundImage: player.photoUrl.isNotEmpty ? NetworkImage(player.photoUrl) : null,
                child: player.photoUrl.isEmpty
                    ? Text(
                        player.name.split(' ').map((e) => e[0]).take(2).join(),
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              // Name, Team & Rating
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          player.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'OVR ${player.rating}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 9,
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${player.position} • ${player.teamName}',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              // Stat Display
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: showGoals
                      ? theme.colorScheme.primary.withOpacity(0.1)
                      : theme.colorScheme.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      showGoals ? '${player.stats.goals}' : '${player.stats.assists}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: showGoals ? theme.colorScheme.primary : theme.colorScheme.secondary,
                      ),
                    ),
                    Text(
                      showGoals ? 'GOALS' : 'ASSISTS',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 9,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
