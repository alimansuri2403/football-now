import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/player.dart';
import '../providers/player_providers.dart';
import '../core/constants.dart';
import '../core/theme.dart';

class PlayerComparisonScreen extends ConsumerStatefulWidget {
  const PlayerComparisonScreen({super.key});

  @override
  ConsumerState<PlayerComparisonScreen> createState() => _PlayerComparisonScreenState();
}

class _PlayerComparisonScreenState extends ConsumerState<PlayerComparisonScreen> {
  Player? _playerA;
  Player? _playerB;
  String _searchQueryA = '';
  String _searchQueryB = '';
  
  final TextEditingController _controllerA = TextEditingController();
  final TextEditingController _controllerB = TextEditingController();

  Widget _buildSearchBox({
    required BuildContext context,
    required String label,
    required Player? selectedPlayer,
    required String query,
    required List<Player> players,
    required TextEditingController controller,
    required ValueChanged<String> onQueryChanged,
    required ValueChanged<Player?> onPlayerSelected,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final filtered = players.where((p) {
      if (query.isEmpty) return false;
      final matchQuery = p.name.toLowerCase().contains(query.toLowerCase()) || 
                         p.teamName.toLowerCase().contains(query.toLowerCase());
      final isAlreadySelected = (selectedPlayer?.id == p.id) || 
                                (_playerA?.id == p.id && label == 'Player B') ||
                                (_playerB?.id == p.id && label == 'Player A');
      return matchQuery && !isAlreadySelected;
    }).take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (selectedPlayer != null) ...[
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundImage: selectedPlayer.photoUrl.isNotEmpty ? NetworkImage(selectedPlayer.photoUrl) : null,
                  child: selectedPlayer.photoUrl.isEmpty ? const Icon(Icons.person) : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedPlayer.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        selectedPlayer.teamName,
                        style: const TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                  onPressed: () {
                    onPlayerSelected(null);
                    controller.clear();
                    onQueryChanged('');
                  },
                ),
              ],
            ),
          ),
        ] else ...[
          TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: label,
              prefixIcon: const Icon(Icons.search, size: 18),
              contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.black12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: theme.colorScheme.primary),
              ),
            ),
            style: const TextStyle(fontSize: 13),
            onChanged: onQueryChanged,
          ),
          if (filtered.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                children: filtered.map((p) {
                  return ListTile(
                    dense: true,
                    title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(p.teamName),
                    onTap: () {
                      onPlayerSelected(p);
                      controller.clear();
                      onQueryChanged('');
                    },
                  );
                }).toList(),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildStatRow(String label, dynamic valA, dynamic valB, bool higherIsBetter, ThemeData theme) {
    bool winA = false;
    bool winB = false;

    if (valA is num && valB is num) {
      if (valA != valB) {
        if (higherIsBetter) {
          winA = valA > valB;
          winB = valB > valA;
        } else {
          winA = valA < valB;
          winB = valB < valA;
        }
      }
    }

    final winColor = theme.colorScheme.primary.withOpacity(0.15);
    final winTextColor = theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          // Player A value
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              decoration: BoxDecoration(
                color: winA ? winColor : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$valA',
                style: TextStyle(
                  fontWeight: winA ? FontWeight.bold : FontWeight.normal,
                  color: winA ? winTextColor : null,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          // Label
          Container(
            width: 100,
            alignment: Alignment.center,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          // Player B value
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              decoration: BoxDecoration(
                color: winB ? winColor : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$valB',
                style: TextStyle(
                  fontWeight: winB ? FontWeight.bold : FontWeight.normal,
                  color: winB ? winTextColor : null,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final playersAsync = ref.watch(playersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Player Comparison'),
      ),
      body: playersAsync.when(
        data: (players) {
          return SafeArea(
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
                        'PLAYER COMPARISON',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Head to Head',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Search Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildSearchBox(
                          context: context,
                          label: 'Search Player A',
                          selectedPlayer: _playerA,
                          query: _searchQueryA,
                          players: players,
                          controller: _controllerA,
                          onQueryChanged: (q) => setState(() => _searchQueryA = q),
                          onPlayerSelected: (p) => setState(() => _playerA = p),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSearchBox(
                          context: context,
                          label: 'Search Player B',
                          selectedPlayer: _playerB,
                          query: _searchQueryB,
                          players: players,
                          controller: _controllerB,
                          onQueryChanged: (q) => setState(() => _searchQueryB = q),
                          onPlayerSelected: (p) => setState(() => _playerB = p),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Comparison Content
                Expanded(
                  child: _playerA == null || _playerB == null
                      ? _buildEmptyState(theme, isDark)
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              // Top headshots card
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: AppTheme.glassDecoration(context: context, radius: 24),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    Column(
                                      children: [
                                        CircleAvatar(
                                          radius: 36,
                                          backgroundImage: _playerA!.photoUrl.isNotEmpty ? NetworkImage(_playerA!.photoUrl) : null,
                                          child: _playerA!.photoUrl.isEmpty ? const Icon(Icons.person, size: 36) : null,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(_playerA!.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                        Text(_playerA!.teamName, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                      ],
                                    ),
                                    const Text('VS', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey, fontSize: 20)),
                                    Column(
                                      children: [
                                        CircleAvatar(
                                          radius: 36,
                                          backgroundImage: _playerB!.photoUrl.isNotEmpty ? NetworkImage(_playerB!.photoUrl) : null,
                                          child: _playerB!.photoUrl.isEmpty ? const Icon(Icons.person, size: 36) : null,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(_playerB!.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                        Text(_playerB!.teamName, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Stats details
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: AppTheme.glassDecoration(context: context, radius: 24),
                                child: Column(
                                  children: [
                                    _buildStatRow('OVR RATING', _playerA!.rating, _playerB!.rating, true, theme),
                                    const Divider(),
                                    _buildStatRow('GOALS', _playerA!.stats.goals, _playerB!.stats.goals, true, theme),
                                    const Divider(),
                                    _buildStatRow('ASSISTS', _playerA!.stats.assists, _playerB!.stats.assists, true, theme),
                                    const Divider(),
                                    _buildStatRow('MATCHES', _playerA!.stats.matchesPlayed, _playerB!.stats.matchesPlayed, true, theme),
                                    const Divider(),
                                    _buildStatRow('MINUTES', _playerA!.stats.minutesPlayed, _playerB!.stats.minutesPlayed, true, theme),
                                    const Divider(),
                                    _buildStatRow('YELLOWS', _playerA!.stats.yellowCards, _playerB!.stats.yellowCards, false, theme),
                                    const Divider(),
                                    _buildStatRow('REDS', _playerA!.stats.redCards, _playerB!.stats.redCards, false, theme),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Banner Winner
                              _buildWinnerBanner(theme),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading players: $err')),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_outline, size: 64, color: Colors.grey.withOpacity(0.4)),
              const SizedBox(width: 16),
              Icon(Icons.compare_arrows, size: 32, color: theme.colorScheme.primary.withOpacity(0.5)),
              const SizedBox(width: 16),
              Icon(Icons.person_outline, size: 64, color: Colors.grey.withOpacity(0.4)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _playerA == null && _playerB == null
                ? 'Select players to compare'
                : 'Search for the second player',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          const Text(
            'Compare statistics, goals, assists and ratings side-by-side.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildWinnerBanner(ThemeData theme) {
    int pointsA = 0;
    int pointsB = 0;

    void compare(num a, num b, bool higherIsBetter) {
      if (a != b) {
        if (higherIsBetter) {
          if (a > b) pointsA++; else pointsB++;
        } else {
          if (a < b) pointsA++; else pointsB++;
        }
      }
    }

    compare(_playerA!.rating, _playerB!.rating, true);
    compare(_playerA!.stats.goals, _playerB!.stats.goals, true);
    compare(_playerA!.stats.assists, _playerB!.stats.assists, true);
    compare(_playerA!.stats.matchesPlayed, _playerB!.stats.matchesPlayed, true);
    compare(_playerA!.stats.minutesPlayed, _playerB!.stats.minutesPlayed, true);
    compare(_playerA!.stats.yellowCards, _playerB!.stats.yellowCards, false);
    compare(_playerA!.stats.redCards, _playerB!.stats.redCards, false);

    String winnerName;
    if (pointsA > pointsB) {
      winnerName = _playerA!.name;
    } else if (pointsB > pointsA) {
      winnerName = _playerB!.name;
    } else {
      winnerName = "Tie";
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: winnerName == "Tie" ? Colors.grey.withOpacity(0.1) : theme.colorScheme.primary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: winnerName == "Tie" ? Colors.grey.withOpacity(0.3) : theme.colorScheme.primary.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          const Icon(Icons.auto_awesome, color: Colors.amber),
          const SizedBox(height: 8),
          Text(
            winnerName == "Tie" ? 'Stats Comparison is a Tie!' : '$winnerName wins the Comparison!',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: winnerName == "Tie" ? null : theme.colorScheme.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Score: $pointsA - $pointsB of 7 categories compared',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
