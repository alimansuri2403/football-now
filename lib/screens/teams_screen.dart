import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/team_providers.dart';
import '../providers/favourites_provider.dart';
import '../models/team.dart';
import '../widgets/group_table.dart';
import '../widgets/shimmer_loading.dart';
import '../core/constants.dart';

class TeamsScreen extends ConsumerStatefulWidget {
  const TeamsScreen({super.key});

  @override
  ConsumerState<TeamsScreen> createState() => _TeamsScreenState();
}

class _TeamsScreenState extends ConsumerState<TeamsScreen>
    with SingleTickerProviderStateMixin {
  final List<String> _groups = [
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L'
  ];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final favourites = ref.watch(favouritesProvider);
    final teamsAsync = ref.watch(teamsProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'GROUPS & STANDINGS',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tournament Stages',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),

            // Tab bar
            TabBar(
              controller: _tabController,
              dividerColor: Colors.transparent,
              indicatorColor: theme.colorScheme.primary,
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor: Colors.grey,
              tabs: [
                const Tab(text: 'All Teams'),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, size: 16),
                      const SizedBox(width: 4),
                      const Text('Favourites'),
                      if (favourites.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${favourites.length}',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            // Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: All teams grouped by standings
                  CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.all(24),
                        sliver: SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 450,
                            mainAxisSpacing: 24,
                            crossAxisSpacing: 24,
                            mainAxisExtent: 290,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final groupName = _groups[index];
                              final standingsAsync =
                                  ref.watch(groupStandingsProvider(groupName));
                              return standingsAsync.when(
                                data: (standings) => GroupTable(
                                    groupName: groupName,
                                    standings: standings),
                                loading: () => ShimmerLoading(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    height: 290,
                                  ),
                                ),
                                error: (err, _) => Center(
                                    child: Text('Error: $err')),
                              );
                            },
                            childCount: _groups.length,
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 32)),
                    ],
                  ),

                  // Tab 2: Favourites
                  teamsAsync.when(
                    data: (teams) {
                      final favTeams = teams
                          .where((t) => favourites
                              .contains(t.code.toUpperCase()))
                          .toList();
                      if (favTeams.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star_border,
                                size: 64,
                                color: Colors.grey.withOpacity(0.4),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No favourite teams yet',
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(color: Colors.grey),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap ⭐ on any team to pin it here',
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: Colors.grey),
                              ),
                            ],
                          ),
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.all(24),
                        itemCount: favTeams.length,
                        itemBuilder: (context, index) =>
                            _FavTeamCard(team: favTeams[index]),
                      );
                    },
                    loading: () => const Center(
                        child: CircularProgressIndicator()),
                    error: (err, _) =>
                        Center(child: Text('Error: $err')),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavTeamCard extends ConsumerWidget {
  final Team team;
  const _FavTeamCard({required this.team});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isFav = ref.watch(favouritesProvider).contains(team.code.toUpperCase());

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Image.network(
            AppConstants.getFlagUrl(team.flagCode),
            width: 40,
            height: 28,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.flag, size: 28),
          ),
        ),
        title: Text(
          team.name,
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Group ${team.group} • Ranked #${team.fifaRanking}',
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                isFav ? Icons.star : Icons.star_border,
                color: isFav ? Colors.amber : Colors.grey,
              ),
              onPressed: () => ref
                  .read(favouritesProvider.notifier)
                  .toggleFavourite(team.code),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => context.go('/teams/team/${team.id}'),
            ),
          ],
        ),
        onTap: () => context.go('/teams/team/${team.id}'),
      ),
    );
  }
}
