import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/player.dart';
import '../providers/player_providers.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../widgets/shimmer_loading.dart';

class FantasyScreen extends ConsumerStatefulWidget {
  const FantasyScreen({super.key});

  @override
  ConsumerState<FantasyScreen> createState() => _FantasyScreenState();
}

class _FantasyScreenState extends ConsumerState<FantasyScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<Player> _squad = [];
  final int _maxSquadSize = 11;
  final int _totalBudget = 100;

  // Max slots per position
  final Map<String, int> _positionLimits = {
    'Goalkeeper': 1,
    'Defender': 4,
    'Midfielder': 4,
    'Forward': 2,
  };

  String _selectedPositionFilter = 'GK';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  // Loaded from playersProvider when available to resolve mock player IDs to actual players
  bool _squadLoaded = false;
  Future<void> _loadSquad(List<Player> allPlayers) async {
    if (_squadLoaded) return;
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('fantasy_squad_ids');
    if (data != null) {
      try {
        final List<dynamic> ids = json.decode(data);
        setState(() {
          _squad.clear();
          for (final id in ids) {
            final player = allPlayers.firstWhere((p) => p.id == id);
            _squad.add(player);
          }
          _squadLoaded = true;
        });
      } catch (_) {
        _squadLoaded = true;
      }
    } else {
      _squadLoaded = true;
    }
  }

  Future<void> _saveSquad() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = _squad.map((p) => p.id).toList();
    await prefs.setString('fantasy_squad_ids', json.encode(ids));
  }

  int _getPlayerCost(Player p) {
    // rating - 60, min 1
    final cost = p.rating - 60;
    return cost < 1 ? 1 : cost;
  }

  int get _usedBudget {
    return _squad.fold(0, (sum, p) => sum + _getPlayerCost(p));
  }

  int get _remainingBudget => _totalBudget - _usedBudget;

  double _getFantasyPoints(Player p) {
    // goals*6 + assists*4 + (rating-70)*0.5
    final ratingPart = (p.rating - 70) * 0.5;
    return (p.stats.goals * 6) + (p.stats.assists * 4) + (ratingPart < 0 ? 0 : ratingPart);
  }

  double get _totalFantasyPoints {
    return _squad.fold(0.0, (sum, p) => sum + _getFantasyPoints(p));
  }

  int _countPosition(String pos) {
    return _squad.where((p) => p.position == pos).length;
  }

  void _addPlayer(Player p) {
    final pos = p.position;
    final limit = _positionLimits[pos] ?? 0;
    final currentCount = _countPosition(pos);
    final cost = _getPlayerCost(p);

    if (_squad.any((item) => item.id == p.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Player already in squad!')),
      );
      return;
    }

    if (_squad.length >= _maxSquadSize) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Squad is already full (11 players max)!')),
      );
      return;
    }

    if (currentCount >= limit) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You can only have $limit players in $pos position!')),
      );
      return;
    }

    if (_remainingBudget < cost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not enough budget credits remaining!')),
      );
      return;
    }

    setState(() {
      _squad.add(p);
      _saveSquad();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${p.name} added to your squad!')),
    );
  }

  void _removePlayer(Player p) {
    setState(() {
      _squad.removeWhere((item) => item.id == p.id);
      _saveSquad();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${p.name} removed from your squad.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final playersAsync = ref.watch(playersProvider);

    playersAsync.whenData((allPlayers) => _loadSquad(allPlayers));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fantasy World Cup'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.primary,
          tabs: const [
            Tab(text: 'My Squad', icon: Icon(Icons.sports_soccer)),
            Tab(text: 'Pick Players', icon: Icon(Icons.add_circle_outline)),
          ],
        ),
      ),
      body: playersAsync.when(
        data: (allPlayers) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildMySquadTab(theme),
              _buildPickPlayersTab(theme, allPlayers),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildMySquadTab(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Stats
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AppTheme.glassDecoration(context: context, radius: 16),
                  child: Column(
                    children: [
                      Text('TOTAL POINTS', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text(
                        _totalFantasyPoints.toStringAsFixed(1),
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AppTheme.glassDecoration(context: context, radius: 16),
                  child: Column(
                    children: [
                      Text('BUDGET REMAINING', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text(
                        '$_remainingBudget / $_totalBudget CR',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: _remainingBudget < 10 ? AppTheme.liveColor : AppTheme.success,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Budget Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _usedBudget / _totalBudget,
              minHeight: 8,
              backgroundColor: Colors.grey.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation<Color>(
                _remainingBudget < 10 ? AppTheme.liveColor : theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Pitch Layout
          Container(
            height: 380,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1B5E20), Color(0xFF33691E)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white24, width: 2),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Stack(
              children: [
                // Pitch markings
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    height: 1,
                    color: Colors.white12,
                    width: double.infinity,
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    height: 90,
                    width: 90,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white12, width: 2),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                
                // Position Slots
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Forwards (Row 1)
                    _buildPositionRow('Forward', 2),
                    // Midfielders (Row 2)
                    _buildPositionRow('Midfielder', 4),
                    // Defenders (Row 3)
                    _buildPositionRow('Defender', 4),
                    // Goalkeeper (Row 4)
                    _buildPositionRow('Goalkeeper', 1),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPositionRow(String position, int count) {
    final list = _squad.where((p) => p.position == position).toList();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(count, (index) {
        if (index < list.length) {
          final p = list[index];
          return _buildPitchPlayerSlot(p);
        } else {
          return _buildPitchEmptySlot(position);
        }
      }),
    );
  }

  Widget _buildPitchPlayerSlot(Player p) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => _showPlayerOptions(p),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.white.withOpacity(0.25),
            backgroundImage: p.photoUrl.isNotEmpty ? NetworkImage(p.photoUrl) : null,
            child: p.photoUrl.isEmpty
                ? Text(p.name.split(' ').map((e) => e[0]).take(2).join(), style: const TextStyle(fontSize: 10, color: Colors.white))
                : null,
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              p.name.split(' ').last,
              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${_getPlayerCost(p)} CR',
            style: const TextStyle(color: Colors.white70, fontSize: 9),
          ),
        ],
      ),
    );
  }

  Widget _buildPitchEmptySlot(String position) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () {
        // Switch to Pick Players tab and select position filter
        _tabController.animateTo(1);
        setState(() {
          if (position == 'Goalkeeper') _selectedPositionFilter = 'GK';
          if (position == 'Defender') _selectedPositionFilter = 'DEF';
          if (position == 'Midfielder') _selectedPositionFilter = 'MID';
          if (position == 'Forward') _selectedPositionFilter = 'FWD';
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.black26,
            child: Icon(Icons.add, color: Colors.white.withOpacity(0.6), size: 16),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _getShortPosition(position),
              style: const TextStyle(color: Colors.white70, fontSize: 9),
            ),
          ),
        ],
      ),
    );
  }

  String _getShortPosition(String position) {
    if (position == 'Goalkeeper') return 'GK';
    if (position == 'Defender') return 'DEF';
    if (position == 'Midfielder') return 'MID';
    return 'FWD';
  }

  void _showPlayerOptions(Player p) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(p.name),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Team: ${p.teamName}'),
              Text('Rating: ${p.rating} OVR'),
              Text('Cost: ${_getPlayerCost(p)} credits'),
              Text('Fantasy Points: ${_getFantasyPoints(p).toStringAsFixed(1)} pts'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.liveColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _removePlayer(p);
              },
              child: const Text('Remove from Squad'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPickPlayersTab(ThemeData theme, List<Player> allPlayers) {
    final isDark = theme.brightness == Brightness.dark;

    final GKList = allPlayers.where((p) => p.position == 'Goalkeeper').toList();
    final DEFList = allPlayers.where((p) => p.position == 'Defender').toList();
    final MIDList = allPlayers.where((p) => p.position == 'Midfielder').toList();
    final FWDList = allPlayers.where((p) => p.position == 'Forward').toList();

    List<Player> currentList;
    if (_selectedPositionFilter == 'GK') currentList = GKList;
    else if (_selectedPositionFilter == 'DEF') currentList = DEFList;
    else if (_selectedPositionFilter == 'MID') currentList = MIDList;
    else currentList = FWDList;

    return Column(
      children: [
        // Position Filter Tabs
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['GK', 'DEF', 'MID', 'FWD'].map((pos) {
              final isSelected = _selectedPositionFilter == pos;
              return ChoiceChip(
                label: Text(pos),
                selected: isSelected,
                selectedColor: theme.colorScheme.primary,
                labelStyle: TextStyle(
                  color: isSelected ? (isDark ? Colors.black : Colors.white) : null,
                  fontWeight: FontWeight.bold,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (val) {
                  if (val) setState(() => _selectedPositionFilter = pos);
                },
              );
            }).toList(),
          ),
        ),

        // Available Players
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: currentList.length,
            itemBuilder: (context, index) {
              final p = currentList[index];
              final cost = _getPlayerCost(p);
              final isAdded = _squad.any((item) => item.id == p.id);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: AppTheme.glassDecoration(context: context, radius: 16),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: p.photoUrl.isNotEmpty ? NetworkImage(p.photoUrl) : null,
                    child: p.photoUrl.isEmpty ? const Icon(Icons.person) : null,
                  ),
                  title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    '${p.teamName} • ⭐ ${p.rating} OVR • 🪙 $cost CR',
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                  trailing: isAdded
                      ? ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => _removePlayer(p),
                          child: const Text('REMOVE'),
                        )
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: isDark ? Colors.black : Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => _addPlayer(p),
                          child: const Text('ADD'),
                        ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
