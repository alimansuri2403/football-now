import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/team.dart';
import '../models/player.dart';
import '../providers/team_providers.dart';
import '../providers/player_providers.dart';
import '../core/constants.dart';

class TeamDetailScreen extends ConsumerWidget {
  final String teamId;

  const TeamDetailScreen({super.key, required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final teamAsync = ref.watch(teamDetailProvider(teamId));
    final playersAsync = ref.watch(teamPlayersProvider(teamId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Team Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: teamAsync.when(
        data: (team) {
          if (team == null) {
            return const Center(child: Text('Team not found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTeamHeader(theme, team),
                const SizedBox(height: 32),
                Text(
                  'Squad List',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                playersAsync.when(
                  data: (players) {
                    if (players.isEmpty) {
                      return const Center(child: Text('No squad players registered in database yet.'));
                    }

                    // Group by position
                    final forwards = players.where((p) => p.position.toLowerCase() == 'forward').toList();
                    final midfielders = players.where((p) => p.position.toLowerCase() == 'midfielder').toList();
                    final defenders = players.where((p) => p.position.toLowerCase() == 'defender').toList();
                    final keepers = players.where((p) => p.position.toLowerCase() == 'goalkeeper').toList();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                )
              ],
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
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                  backgroundImage: p.photoUrl.isNotEmpty ? NetworkImage(p.photoUrl) : null,
                  child: p.photoUrl.isEmpty ? Text('${p.number}') : null,
                ),
                title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Age: ${p.age}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  context.go('/player/${p.id}');
                },
              ),
            );
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
