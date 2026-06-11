import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/player.dart';
import '../providers/player_providers.dart';
import '../widgets/player_card.dart';
import '../widgets/shimmer_loading.dart';

class PlayersScreen extends ConsumerStatefulWidget {
  const PlayersScreen({super.key});

  @override
  ConsumerState<PlayersScreen> createState() => _PlayersScreenState();
}

class _PlayersScreenState extends ConsumerState<PlayersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String _selectedPosition = 'All';
  final List<String> _positions = ['All', 'GK', 'DEF', 'MID', 'FWD'];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Player> _applyFilters(List<Player> players) {
    return players.where((p) {
      final query = _searchQuery.toLowerCase();
      final matchesSearch = query.isEmpty ||
          p.name.toLowerCase().contains(query) ||
          p.teamName.toLowerCase().contains(query);

      final matchesPosition = _selectedPosition == 'All' ||
          (_selectedPosition == 'GK' && p.position.toLowerCase() == 'goalkeeper') ||
          (_selectedPosition == 'DEF' && p.position.toLowerCase() == 'defender') ||
          (_selectedPosition == 'MID' && p.position.toLowerCase() == 'midfielder') ||
          (_selectedPosition == 'FWD' && p.position.toLowerCase() == 'forward');

      return matchesSearch && matchesPosition;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final topScorersAsync = ref.watch(topScorersProvider);
    final topAssistsAsync = ref.watch(topAssistsProvider);
    final topRatingsAsync = ref.watch(topRatingsProvider);

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
                  const SizedBox(height: 16),

                  // Search bar
                  Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.black.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) =>
                          setState(() => _searchQuery = v),
                      decoration: InputDecoration(
                        hintText: 'Search players or teams...',
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Position filter chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _positions.map((pos) {
                        final isSelected = _selectedPosition == pos;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(pos),
                            selected: isSelected,
                            onSelected: (_) =>
                                setState(() => _selectedPosition = pos),
                            selectedColor:
                                theme.colorScheme.primary.withOpacity(0.2),
                            checkmarkColor: theme.colorScheme.primary,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : Colors.grey,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 13,
                            ),
                            side: BorderSide(
                              color: isSelected
                                  ? theme.colorScheme.primary.withOpacity(0.5)
                                  : Colors.grey.withOpacity(0.3),
                            ),
                            backgroundColor: Colors.transparent,
                            showCheckmark: false,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 0),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
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
              tabs: const [
                Tab(text: '⚽ Scorers'),
                Tab(text: '🎯 Assists'),
                Tab(text: '⭐ Ratings'),
              ],
            ),
            const SizedBox(height: 8),

            // Tab views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Scorers
                  _buildPlayerList(
                    asyncValue: topScorersAsync,
                    showGoals: true,
                    statLabel: 'GOALS',
                  ),
                  // Assists
                  _buildPlayerList(
                    asyncValue: topAssistsAsync,
                    showGoals: false,
                    statLabel: 'ASSISTS',
                  ),
                  // Ratings
                  _buildPlayerList(
                    asyncValue: topRatingsAsync,
                    showGoals: true,
                    statLabel: 'RATING',
                    showRating: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerList({
    required AsyncValue<List<Player>> asyncValue,
    required bool showGoals,
    required String statLabel,
    bool showRating = false,
  }) {
    return asyncValue.when(
      data: (players) {
        final filtered = _applyFilters(players);
        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.search_off,
                    size: 48, color: Colors.grey.withOpacity(0.4)),
                const SizedBox(height: 12),
                Text('No players found',
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final player = filtered[index];
            return PlayerCard(
              player: player,
              rank: index + 1,
              showGoals: showGoals,
              showRating: showRating,
            );
          },
        );
      },
      loading: () => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child:
            ShimmerLoading(child: ShimmerLoading.cardList(count: 6)),
      ),
      error: (err, _) =>
          Center(child: Text('Error loading players: $err')),
    );
  }
}
