import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/player_providers.dart';
import '../widgets/player_card.dart';
import '../widgets/shimmer_loading.dart';

class PlayersScreen extends ConsumerWidget {
  const PlayersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final topScorersAsync = ref.watch(topScorersProvider);
    final topAssistsAsync = ref.watch(topAssistsProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOURNAMENT LEADERS',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Player Standings',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              TabBar(
                dividerColor: Colors.transparent,
                indicatorColor: theme.colorScheme.primary,
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor: Colors.grey,
                tabs: const [
                  Tab(text: 'Top Scorers'),
                  Tab(text: 'Top Assists'),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TabBarView(
                  children: [
                    // Top Scorers tab
                    topScorersAsync.when(
                      data: (scorers) {
                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          itemCount: scorers.length,
                          itemBuilder: (context, index) {
                            return PlayerCard(
                              player: scorers[index],
                              rank: index + 1,
                              showGoals: true,
                            );
                          },
                        );
                      },
                      loading: () => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: ShimmerLoading(child: ShimmerLoading.cardList(count: 5)),
                      ),
                      error: (err, stack) => Center(child: Text('Error loading top scorers: $err')),
                    ),

                    // Top Assists tab
                    topAssistsAsync.when(
                      data: (assists) {
                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          itemCount: assists.length,
                          itemBuilder: (context, index) {
                            return PlayerCard(
                              player: assists[index],
                              rank: index + 1,
                              showGoals: false,
                            );
                          },
                        );
                      },
                      loading: () => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: ShimmerLoading(child: ShimmerLoading.cardList(count: 5)),
                      ),
                      error: (err, stack) => Center(child: Text('Error loading top assists: $err')),
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
