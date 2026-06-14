import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/match.dart';
import '../models/player.dart';
import '../providers/match_provider.dart';
import '../providers/player_providers.dart';
import '../providers/timezone_provider.dart';
import '../widgets/match_stat_bar.dart';
import '../widgets/shimmer_loading.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../services/ad_service.dart';
import '../services/espn_api.dart';

class MatchDetailScreen extends ConsumerStatefulWidget {
  final String matchId;

  const MatchDetailScreen({super.key, required this.matchId});

  @override
  ConsumerState<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends ConsumerState<MatchDetailScreen> {
  String _selectedLineupTab = 'Performance';
  @override
  void initState() {
    super.initState();
    // Track match detail open count and show interstitial ad on every 5th open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        AdService().incrementMatchDetailOpensAndShow(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final matchAsync = ref.watch(matchDetailProvider(widget.matchId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Match Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            tooltip: 'Live Fan Chat',
            onPressed: () {
              matchAsync.whenData((match) {
                if (match != null) {
                  final title = '${match.homeTeam.code} vs ${match.awayTeam.code}';
                  context.push('/chat/${match.id}/${Uri.encodeComponent(title)}');
                }
              });
            },
          ),
        ],
      ),
      body: matchAsync.when(
        data: (match) {
          if (match == null) {
            return const Center(child: Text('Match not found'));
          }
          return DefaultTabController(
            length: 5,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  _buildScoreboardHeader(theme, match),
                  const SizedBox(height: 24),
                  TabBar(
                    dividerColor: Colors.transparent,
                    indicatorColor: theme.colorScheme.primary,
                    labelColor: theme.colorScheme.primary,
                    unselectedLabelColor: Colors.grey,
                    isScrollable: true,
                    tabs: const [
                      Tab(text: 'Statistics'),
                      Tab(text: 'Timeline'),
                      Tab(text: 'Lineups'),
                      Tab(text: 'H2H'),
                      Tab(text: 'AI Summary'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 520,
                    child: TabBarView(
                      children: [
                        _buildStatsTab(match),
                        _buildTimelineTab(theme, match),
                        _buildLineupsTab(ref, match),
                        _buildH2hTab(match),
                        _buildAiSummaryTab(match),
                      ],
                    ),
                  )
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildScoreboardHeader(ThemeData theme, Match match) {
    final isLive = match.status == MatchStatus.live;
    final isFinished = match.status == MatchStatus.finished;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          // Match Venue & Group Info
          Text(
            '${match.group} • ${match.venue}',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _formatMatchDateTime(match.dateTime),
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          // Scores and Flags
          Row(
            children: [
              // Home Team
              Expanded(
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        AppConstants.getFlagUrl(match.homeTeam.flagCode),
                        width: 72,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.flag, size: 48),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      match.homeTeam.name,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              // Score Line
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          isFinished || isLive ? '${match.homeScore}' : '-',
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            fontSize: 48,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          ':',
                          style: theme.textTheme.headlineLarge?.copyWith(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          isFinished || isLive ? '${match.awayScore}' : '-',
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            fontSize: 48,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Live status / Scheduled marker
                    if (isLive)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "LIVE ${match.currentMinute}'",
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else if (isFinished)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "FULL TIME",
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "SCHEDULED",
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                  ],
                ),
              ),
              // Away Team
              Expanded(
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        AppConstants.getFlagUrl(match.awayTeam.flagCode),
                        width: 72,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.flag, size: 48),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      match.awayTeam.name,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  String _formatMatchDateTime(DateTime utcTime) {
    final tzNotifier = ref.read(timezoneProvider.notifier);
    final tzState = ref.read(timezoneProvider);
    final local = tzNotifier.convertToLocal(utcTime);
    final abbr = tzState.timezoneAbbreviation;
    return '${DateFormat('MMMM d, yyyy - HH:mm').format(local)} $abbr';
  }

  Widget _buildStatsTab(Match match) {
    if (match.status == MatchStatus.scheduled) {
      return const Center(child: Text('Statistics will be available when match starts.'));
    }

    final stats = match.stats;
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      children: [
        MatchStatBar(label: 'Ball Possession', homeVal: stats.homePossession, awayVal: stats.awayPossession, isPercentage: true),
        MatchStatBar(label: 'Shots on Target', homeVal: stats.homeShotsOnGoal, awayVal: stats.awayShotsOnGoal),
        MatchStatBar(label: 'Total Shots', homeVal: stats.homeTotalShots, awayVal: stats.awayTotalShots),
        MatchStatBar(label: 'Corners', homeVal: stats.homeCorners, awayVal: stats.awayCorners),
        MatchStatBar(label: 'Fouls Committed', homeVal: stats.homeFouls, awayVal: stats.awayFouls),
        MatchStatBar(label: 'Yellow Cards', homeVal: stats.homeYellowCards, awayVal: stats.awayYellowCards),
        MatchStatBar(label: 'Offsides', homeVal: stats.homeOffsides, awayVal: stats.awayOffsides),
      ],
    );
  }

  Widget _buildTimelineTab(ThemeData theme, Match match) {
    if (match.events.isEmpty) {
      return const Center(child: Text('No timeline events recorded yet.'));
    }

    return ListView.builder(
      itemCount: match.events.length,
      itemBuilder: (context, index) {
        final event = match.events[index];
        final isHome = event.teamId == match.homeTeam.id;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: isHome ? MainAxisAlignment.start : MainAxisAlignment.end,
            children: [
              if (isHome) ...[
                _buildTimelineIcon(event.type),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          "${event.minute}'",
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Text(event.playerName, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Text(event.detail, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                  ],
                ),
              ] else ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Text(event.playerName, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        Text(
                          "${event.minute}'",
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Text(event.detail, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                  ],
                ),
                const SizedBox(width: 12),
                _buildTimelineIcon(event.type),
              ]
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimelineIcon(MatchEventType type) {
    switch (type) {
      case MatchEventType.goal:
        return const CircleAvatar(
          radius: 14,
          backgroundColor: Colors.green,
          child: Icon(Icons.sports_soccer, size: 16, color: Colors.white),
        );
      case MatchEventType.card:
        return const CircleAvatar(
          radius: 14,
          backgroundColor: Colors.amber,
          child: Icon(Icons.style, size: 14, color: Colors.black),
        );
      case MatchEventType.substitution:
        return const CircleAvatar(
          radius: 14,
          backgroundColor: Colors.blue,
          child: Icon(Icons.swap_horiz, size: 16, color: Colors.white),
        );
    }
  }

  String getPosCategory(String position) {
    final pos = position.toUpperCase();
    if (pos.contains('GK') || pos.contains('GOAL')) return 'GK';
    if (pos.contains('DEF')) return 'DEF';
    if (pos.contains('MID')) return 'MID';
    if (pos.contains('FWD') || pos.contains('FOR') || pos.contains('STR')) return 'FWD';
    return 'MID';
  }

  List<Player> getStarting11(List<Player> squad) {
    final List<Player> starters = [];
    final List<Player> gks = [];
    final List<Player> defs = [];
    final List<Player> mids = [];
    final List<Player> fwds = [];
    
    // Sort by rating descending so top rated players start
    final sortedSquad = List<Player>.from(squad)..sort((Player a, Player b) => b.rating.compareTo(a.rating));
    
    for (final p in sortedSquad) {
      final cat = getPosCategory(p.position);
      if (cat == 'GK') gks.add(p);
      else if (cat == 'DEF') defs.add(p);
      else if (cat == 'MID') mids.add(p);
      else if (cat == 'FWD') fwds.add(p);
    }
    
    // Select 1 GK
    if (gks.isNotEmpty) {
      starters.add(gks.removeAt(0));
    }
    
    // Select 3 DEF
    int defNeeded = 3;
    while (defNeeded > 0 && defs.isNotEmpty) {
      starters.add(defs.removeAt(0));
      defNeeded--;
    }
    
    // Select 4 MID
    int midNeeded = 4;
    while (midNeeded > 0 && mids.isNotEmpty) {
      starters.add(mids.removeAt(0));
      midNeeded--;
    }
    
    // Select 3 FWD
    int fwdNeeded = 3;
    while (fwdNeeded > 0 && fwds.isNotEmpty) {
      starters.add(fwds.removeAt(0));
      fwdNeeded--;
    }
    
    // If we still need starters (e.g. some list was empty), fill up from leftovers
    final leftovers = [...gks, ...defs, ...mids, ...fwds];
    leftovers.sort((Player a, Player b) => b.rating.compareTo(a.rating));
    
    while (starters.length < 11 && leftovers.isNotEmpty) {
      starters.add(leftovers.removeAt(0));
    }
    
    return starters;
  }

  String _shortenName(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length <= 1) return fullName;
    if (parts.length == 2) {
      final first = parts[0];
      final last = parts[1];
      if (first.length > 3) {
        return '${first[0]}. $last';
      }
      return fullName;
    }
    final last = parts.last;
    final initials = parts.sublist(0, parts.length - 1).map((p) => p.isNotEmpty ? p[0] : '').join('.');
    return '$initials. $last';
  }

  String _extractClub(Player p) {
    if (p.pastRecords.isNotEmpty) {
      final first = p.pastRecords.first;
      if (first.startsWith('Plays for ')) {
        return first.replaceFirst('Plays for ', '');
      }
      return first;
    }
    return 'Free Agent';
  }

  Color _getRatingColor(int rating) {
    if (rating >= 85) return Colors.green[800]!;
    if (rating >= 78) return Colors.green[600]!;
    if (rating >= 72) return Colors.amber[700]!;
    return Colors.red[600]!;
  }

  bool _matchesName(String pName, String eName) {
    final p = pName.toLowerCase();
    final e = eName.toLowerCase();
    return p.contains(e) || e.contains(p);
  }

  static final Map<String, String> _managers = {
    'ARG': 'L. Scaloni',
    'FRA': 'D. Deschamps',
    'POR': 'R. Martínez',
    'ENG': 'G. Southgate',
    'USA': 'M. Pochettino',
    'MEX': 'J. Aguirre',
    'CAN': 'J. Marsch',
    'BRA': 'Dorival Júnior',
    'GER': 'J. Nagelsmann',
    'ESP': 'L. de la Fuente',
    'ITA': 'L. Spalletti',
    'NED': 'R. Koeman',
    'BEL': 'D. Tedesco',
    'CRO': 'Z. Dalić',
    'URU': 'M. Bielsa',
    'COL': 'N. Lorenzo',
    'SEN': 'A. Cissé',
    'MAR': 'W. Regragui',
    'KOR': 'Hong Myung-bo',
    'CZE': 'I. Hašek',
    'SUI': 'M. Yakin',
    'DEN': 'K. Hjulmand',
    'KSA': 'R. Mancini',
    'SAU': 'R. Mancini',
    'JPN': 'H. Moriyasu',
    'AUS': 'G. Arnold',
  };

  String getManager(String teamCode, String teamName) {
    final code = teamCode.toUpperCase();
    if (_managers.containsKey(code)) return _managers[code]!;
    final h = teamName.hashCode.abs();
    final lastNames = ['Silva', 'García', 'Smith', 'Müller', 'Dupont', 'Jones', 'Novák', 'Kim', 'Sato', 'Rossi', 'Larsson', 'Alves'];
    final firstInitials = ['A.', 'M.', 'J.', 'D.', 'G.', 'R.', 'L.', 'H.', 'K.', 'F.'];
    return '${firstInitials[h % firstInitials.length]} ${lastNames[(h >> 2) % lastNames.length]}';
  }

  String _getFormationString(List<Player> starters) {
    int def = 0;
    int mid = 0;
    int fwd = 0;
    for (final p in starters) {
      final cat = getPosCategory(p.position);
      if (cat == 'DEF') def++;
      else if (cat == 'MID') mid++;
      else if (cat == 'FWD') fwd++;
    }
    if (def == 0 && mid == 0 && fwd == 0) return '3-4-3';
    return '$def-$mid-$fwd';
  }

  List<double> _getXCoords(int count) {
    if (count <= 1) return [0.5];
    final double step = 0.8 / (count - 1);
    return List.generate(count, (i) => 0.1 + i * step);
  }

  Widget _buildSubTabChip(String tabName, ThemeData theme) {
    final isSelected = _selectedLineupTab == tabName;
    return ChoiceChip(
      label: Text(tabName, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      selected: isSelected,
      onSelected: (val) {
        if (val) {
          setState(() {
            _selectedLineupTab = tabName;
          });
        }
      },
      selectedColor: theme.colorScheme.primary.withOpacity(0.2),
      backgroundColor: theme.colorScheme.surface,
      checkmarkColor: theme.colorScheme.primary,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    );
  }

  Widget _buildLegendItem(Widget icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        const SizedBox(width: 4),
        Flexible(
          child: Text(label, style: const TextStyle(fontSize: 10), overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  Widget _buildPitchPlayerItem(Player p, double x, double y, BoxConstraints constraints, {required bool isHome, required Match match}) {
    final playerGoals = match.events.where((e) => e.type == MatchEventType.goal && _matchesName(p.name, e.playerName)).toList();
    final goalsCount = playerGoals.length;
    
    final playerYellow = match.events.any((e) => e.type == MatchEventType.card && _matchesName(p.name, e.playerName) && e.detail.toLowerCase().contains('yellow'));
    final playerRed = match.events.any((e) => e.type == MatchEventType.card && _matchesName(p.name, e.playerName) && e.detail.toLowerCase().contains('red'));
    
    final subOutEvent = match.events.where(
      (e) => e.type == MatchEventType.substitution && _matchesName(p.name, e.playerName)
    ).firstOrNull;
    final isSubbedOut = subOutEvent != null;

    final double left = (x * constraints.maxWidth).clamp(30.0, constraints.maxWidth - 30.0) - 30.0;
    final double top = (y * constraints.maxHeight).clamp(40.0, constraints.maxHeight - 45.0) - 35.0;

    return Positioned(
      left: left,
      top: top,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 38,
              height: 38,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 19,
                    backgroundColor: isHome ? const Color(0xFF1E3A8A) : const Color(0xFFDC2626),
                    child: CircleAvatar(
                      radius: 17,
                      backgroundImage: p.photoUrl.isNotEmpty ? NetworkImage(p.photoUrl) : null,
                      backgroundColor: Colors.white.withOpacity(0.9),
                      child: p.photoUrl.isEmpty
                          ? Text(
                              '${p.number}',
                              style: TextStyle(
                                color: isHome ? const Color(0xFF1E3A8A) : const Color(0xFFDC2626),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            )
                          : null,
                    ),
                  ),
                  if (goalsCount > 0)
                    Positioned(
                      top: -4,
                      left: -4,
                      child: Container(
                        padding: const EdgeInsets.all(1.5),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 2)]),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.sports_soccer, size: 10, color: Colors.black),
                            if (goalsCount > 1)
                              Text('x$goalsCount', style: const TextStyle(fontSize: 7, fontWeight: FontWeight.bold, color: Colors.black)),
                          ],
                        ),
                      ),
                    ),
                  if (playerRed)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        width: 8,
                        height: 11,
                        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(1.5), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 1.5)]),
                      ),
                    )
                  else if (playerYellow)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        width: 8,
                        height: 11,
                        decoration: BoxDecoration(color: Colors.yellow[700], borderRadius: BorderRadius.circular(1.5), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 1.5)]),
                      ),
                    ),
                  if (isSubbedOut)
                    Positioned(
                      bottom: -3,
                      right: -3,
                      child: Container(
                        padding: const EdgeInsets.all(1),
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 1.5)]),
                        child: const Icon(Icons.arrow_downward, size: 10, color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 3),
            Text(
              _shortenName(p.name),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(offset: Offset(1, 1), blurRadius: 2.5, color: Colors.black),
                ],
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (_selectedLineupTab == 'Performance')
              Container(
                margin: const EdgeInsets.only(top: 1),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0.5),
                decoration: BoxDecoration(
                  color: _getRatingColor(p.rating),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  (p.rating / 10).toStringAsFixed(1),
                  style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                ),
              )
            else if (_selectedLineupTab == 'Age')
              Text(
                '${p.age}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w500,
                  shadows: [Shadow(color: Colors.black87, blurRadius: 2)],
                ),
              )
            else if (_selectedLineupTab == 'Club')
              Text(
                _extractClub(p),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 8,
                  fontWeight: FontWeight.w500,
                  shadows: [Shadow(color: Colors.black87, blurRadius: 2)],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenchPlayerRowItem(Player p, bool isSubbedIn, int? subInMin, {required bool isHome, required Match match}) {
    final playerGoals = match.events.where((e) => e.type == MatchEventType.goal && _matchesName(p.name, e.playerName)).toList();
    final goalsCount = playerGoals.length;
    
    final playerYellow = match.events.any((e) => e.type == MatchEventType.card && _matchesName(p.name, e.playerName) && e.detail.toLowerCase().contains('yellow'));
    final playerRed = match.events.any((e) => e.type == MatchEventType.card && _matchesName(p.name, e.playerName) && e.detail.toLowerCase().contains('red'));

    final avatar = CircleAvatar(
      radius: 16,
      backgroundImage: p.photoUrl.isNotEmpty ? NetworkImage(p.photoUrl) : null,
      backgroundColor: Colors.grey.withOpacity(0.2),
      child: p.photoUrl.isEmpty
          ? Text('${p.number}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))
          : null,
    );

    final String subText;
    if (_selectedLineupTab == 'Age') {
      subText = '${p.age} yrs';
    } else if (_selectedLineupTab == 'Club') {
      subText = _extractClub(p);
    } else {
      subText = '${p.position} #${p.number}';
    }

    final detailCol = Column(
      crossAxisAlignment: isHome ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
        Text(subText, style: const TextStyle(color: Colors.grey, fontSize: 9), maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
    );

    final eventsWidget = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isSubbedIn) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.12),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.arrow_upward, size: 8, color: Colors.green),
                const SizedBox(width: 1),
                Text(
                  "${subInMin ?? ''}'",
                  style: const TextStyle(color: Colors.green, fontSize: 8.5, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
        ],
        if (goalsCount > 0) ...[
          const Icon(Icons.sports_soccer, size: 11, color: Colors.white70),
          if (goalsCount > 1)
            Text('x$goalsCount', style: const TextStyle(fontSize: 8, color: Colors.white70)),
          const SizedBox(width: 4),
        ],
        if (playerYellow) ...[
          Container(width: 7, height: 10, decoration: BoxDecoration(color: Colors.yellow[700], borderRadius: BorderRadius.circular(1))),
          const SizedBox(width: 4),
        ],
        if (playerRed) ...[
          Container(width: 7, height: 10, decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(1))),
          const SizedBox(width: 4),
        ],
      ],
    );

    if (isHome) {
      return Row(
        children: [
          avatar,
          const SizedBox(width: 8),
          Expanded(child: detailCol),
          const SizedBox(width: 4),
          eventsWidget,
        ],
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          eventsWidget,
          const SizedBox(width: 4),
          Expanded(child: detailCol),
          const SizedBox(width: 8),
          avatar,
        ],
      );
    }
  }

  Widget _buildLineupsTab(WidgetRef ref, Match match) {
    final homePlayersAsync = ref.watch(teamPlayersProvider(match.homeTeam.id));
    final awayPlayersAsync = ref.watch(teamPlayersProvider(match.awayTeam.id));
    final theme = Theme.of(context);

    return homePlayersAsync.when(
      data: (homePlayers) {
        return awayPlayersAsync.when(
          data: (awayPlayers) {
            if (homePlayers.isEmpty || awayPlayers.isEmpty) {
              return const Center(child: Text('Lineup information not available yet.'));
            }

            final List<Player> homeStarters = getStarting11(homePlayers);
            final List<Player> homeBench = homePlayers.where((Player p) => !homeStarters.contains(p)).toList();

            final List<Player> awayStarters = getStarting11(awayPlayers);
            final List<Player> awayBench = awayPlayers.where((Player p) => !awayStarters.contains(p)).toList();

            final homeFormStr = _getFormationString(homeStarters);
            final awayFormStr = _getFormationString(awayStarters);

            return SingleChildScrollView(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildSubTabChip('Performance', theme),
                      const SizedBox(width: 8),
                      _buildSubTabChip('Age', theme),
                      const SizedBox(width: 8),
                      _buildSubTabChip('Club', theme),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 500,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                      ),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.center,
                            child: Container(
                              height: 2,
                              width: double.infinity,
                              color: Colors.white.withOpacity(0.25),
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withOpacity(0.25), width: 2),
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.topCenter,
                            child: Container(
                              width: 170,
                              height: 75,
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: Colors.white.withOpacity(0.25), width: 2),
                                  left: BorderSide(color: Colors.white.withOpacity(0.25), width: 2),
                                  right: BorderSide(color: Colors.white.withOpacity(0.25), width: 2),
                                ),
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.topCenter,
                            child: Container(
                              width: 90,
                              height: 30,
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: Colors.white.withOpacity(0.25), width: 2),
                                  left: BorderSide(color: Colors.white.withOpacity(0.25), width: 2),
                                  right: BorderSide(color: Colors.white.withOpacity(0.25), width: 2),
                                ),
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              width: 170,
                              height: 75,
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(color: Colors.white.withOpacity(0.25), width: 2),
                                  left: BorderSide(color: Colors.white.withOpacity(0.25), width: 2),
                                  right: BorderSide(color: Colors.white.withOpacity(0.25), width: 2),
                                ),
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              width: 90,
                              height: 30,
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(color: Colors.white.withOpacity(0.25), width: 2),
                                  left: BorderSide(color: Colors.white.withOpacity(0.25), width: 2),
                                  right: BorderSide(color: Colors.white.withOpacity(0.25), width: 2),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            left: 12,
                            child: Row(
                              children: [
                                Image.network(AppConstants.getFlagUrl(match.homeTeam.flagCode), width: 18, height: 12, errorBuilder: (_, __, ___) => const Icon(Icons.flag, size: 12)),
                                const SizedBox(width: 4),
                                Text(match.homeTeam.name, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(4)),
                              child: Text(homeFormStr, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          Positioned(
                            bottom: 8,
                            left: 12,
                            child: Row(
                              children: [
                                Image.network(AppConstants.getFlagUrl(match.awayTeam.flagCode), width: 18, height: 12, errorBuilder: (_, __, ___) => const Icon(Icons.flag, size: 12)),
                                const SizedBox(width: 4),
                                Text(match.awayTeam.name, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          Positioned(
                            bottom: 8,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(4)),
                              child: Text(awayFormStr, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final List<Widget> playerWidgets = [];

                              final homeGK = homeStarters.where((Player p) => getPosCategory(p.position) == 'GK').toList();
                              final homeDEF = homeStarters.where((Player p) => getPosCategory(p.position) == 'DEF').toList();
                              final homeMID = homeStarters.where((Player p) => getPosCategory(p.position) == 'MID').toList();
                              final homeFWD = homeStarters.where((Player p) => getPosCategory(p.position) == 'FWD').toList();

                              final awayGK = awayStarters.where((Player p) => getPosCategory(p.position) == 'GK').toList();
                              final awayDEF = awayStarters.where((Player p) => getPosCategory(p.position) == 'DEF').toList();
                              final awayMID = awayStarters.where((Player p) => getPosCategory(p.position) == 'MID').toList();
                              final awayFWD = awayStarters.where((Player p) => getPosCategory(p.position) == 'FWD').toList();

                              if (homeGK.isNotEmpty) {
                                playerWidgets.add(_buildPitchPlayerItem(homeGK[0], 0.5, 0.08, constraints, isHome: true, match: match));
                              }
                              final homeDEFCoords = _getXCoords(homeDEF.length);
                              for (int i = 0; i < homeDEF.length; i++) {
                                playerWidgets.add(_buildPitchPlayerItem(homeDEF[i], homeDEFCoords[i], 0.22, constraints, isHome: true, match: match));
                              }
                              final homeMIDCoords = _getXCoords(homeMID.length);
                              for (int i = 0; i < homeMID.length; i++) {
                                playerWidgets.add(_buildPitchPlayerItem(homeMID[i], homeMIDCoords[i], 0.35, constraints, isHome: true, match: match));
                              }
                              final homeFWDCoords = _getXCoords(homeFWD.length);
                              for (int i = 0; i < homeFWD.length; i++) {
                                playerWidgets.add(_buildPitchPlayerItem(homeFWD[i], homeFWDCoords[i], 0.45, constraints, isHome: true, match: match));
                              }

                              final awayFWDCoords = _getXCoords(awayFWD.length);
                              for (int i = 0; i < awayFWD.length; i++) {
                                playerWidgets.add(_buildPitchPlayerItem(awayFWD[i], awayFWDCoords[i], 0.55, constraints, isHome: false, match: match));
                              }
                              final awayMIDCoords = _getXCoords(awayMID.length);
                              for (int i = 0; i < awayMID.length; i++) {
                                playerWidgets.add(_buildPitchPlayerItem(awayMID[i], awayMIDCoords[i], 0.65, constraints, isHome: false, match: match));
                              }
                              final awayDEFCoords = _getXCoords(awayDEF.length);
                              for (int i = 0; i < awayDEF.length; i++) {
                                playerWidgets.add(_buildPitchPlayerItem(awayDEF[i], awayDEFCoords[i], 0.78, constraints, isHome: false, match: match));
                              }
                              if (awayGK.isNotEmpty) {
                                playerWidgets.add(_buildPitchPlayerItem(awayGK[0], 0.5, 0.92, constraints, isHome: false, match: match));
                              }

                              return Stack(children: playerWidgets);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest ?? Colors.grey.withOpacity(0.1),
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Image.network(AppConstants.getFlagUrl(match.homeTeam.flagCode), width: 22, height: 14, errorBuilder: (_, __, ___) => const Icon(Icons.flag, size: 14)),
                        const Text('Bench', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Image.network(AppConstants.getFlagUrl(match.awayTeam.flagCode), width: 22, height: 14, errorBuilder: (_, __, ___) => const Icon(Icons.flag, size: 14)),
                      ],
                    ),
                  ),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final benchLength = math.max(homeBench.length, awayBench.length);

                      final homeSubs = match.events
                          .where((e) => e.type == MatchEventType.substitution && e.teamId.toUpperCase() == match.homeTeam.code.toUpperCase())
                          .toList()
                        ..sort((a, b) => a.minute.compareTo(b.minute));

                      final awaySubs = match.events
                          .where((e) => e.type == MatchEventType.substitution && e.teamId.toUpperCase() == match.awayTeam.code.toUpperCase())
                          .toList()
                        ..sort((a, b) => a.minute.compareTo(b.minute));

                      return Column(
                        children: List.generate(benchLength, (index) {
                          final homePlayer = index < homeBench.length ? homeBench[index] : null;
                          final awayPlayer = index < awayBench.length ? awayBench[index] : null;

                          final isHomeSubIn = homePlayer != null && index < homeSubs.length;
                          final homeSubMin = isHomeSubIn ? homeSubs[index].minute : null;

                          final isAwaySubIn = awayPlayer != null && index < awaySubs.length;
                          final awaySubMin = isAwaySubIn ? awaySubs[index].minute : null;

                          return Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                            decoration: BoxDecoration(
                              border: Border(bottom: BorderSide(color: theme.dividerColor, width: 0.5)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: homePlayer != null
                                      ? _buildBenchPlayerRowItem(homePlayer, isHomeSubIn, homeSubMin, isHome: true, match: match)
                                      : const SizedBox(),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: awayPlayer != null
                                      ? _buildBenchPlayerRowItem(awayPlayer, isAwaySubIn, awaySubMin, isHome: false, match: match)
                                      : const SizedBox(),
                                ),
                              ],
                            ),
                          );
                        }),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(getManager(match.homeTeam.code, match.homeTeam.name), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            Row(
                              children: [
                                Image.network(AppConstants.getFlagUrl(match.homeTeam.flagCode), width: 14, height: 9, errorBuilder: (_, __, ___) => const Icon(Icons.flag, size: 9)),
                                const SizedBox(width: 4),
                                const Text('Manager', style: TextStyle(color: Colors.grey, fontSize: 10)),
                              ],
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(getManager(match.awayTeam.code, match.awayTeam.name), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.right),
                            Row(
                              children: [
                                const Text('Manager', style: TextStyle(color: Colors.grey, fontSize: 10)),
                                const SizedBox(width: 4),
                                Image.network(AppConstants.getFlagUrl(match.awayTeam.flagCode), width: 14, height: 9, errorBuilder: (_, __, ___) => const Icon(Icons.flag, size: 9)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow ?? Colors.grey.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Legend', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        const SizedBox(height: 10),
                        GridView(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 4,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          children: [
                            _buildLegendItem(const Icon(Icons.sports_soccer, size: 13, color: Colors.white70), 'Goal'),
                            _buildLegendItem(const Icon(Icons.arrow_upward, size: 12, color: Colors.green), 'Sub in'),
                            _buildLegendItem(Container(width: 8, height: 11, decoration: BoxDecoration(color: Colors.yellow[700], borderRadius: BorderRadius.circular(1.5))), 'Yellow card'),
                            _buildLegendItem(const Icon(Icons.arrow_downward, size: 12, color: Colors.red), 'Sub out'),
                            _buildLegendItem(Container(width: 8, height: 11, decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(1.5))), 'Red card'),
                            _buildLegendItem(const Icon(Icons.assistant_navigation, size: 12, color: Colors.blue), 'Assist'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(child: Text('Error: $e')),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildH2hTab(Match match) {
    final espnApi = ref.read(espnApiProvider);
    final theme = Theme.of(context);

    return FutureBuilder<List<H2hMeeting>>(
      future: espnApi.fetchMatchSummary(match.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error loading H2H records: ${snapshot.error}'));
        }

        final meetings = snapshot.data ?? [];
        if (meetings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey.withOpacity(0.5)),
                const SizedBox(height: 16),
                Text(
                  'No historical head-to-head records found.',
                  style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: meetings.length,
          itemBuilder: (context, index) {
            final meeting = meetings[index];
            final kickoffDate = DateTime.tryParse(meeting.date);
            final formattedDate = kickoffDate != null
                ? DateFormat('MMMM d, yyyy').format(kickoffDate)
                : meeting.date;

            // Determine meeting result badge color
            Color badgeColor = Colors.grey;
            if (meeting.result.toUpperCase() == 'W') {
              badgeColor = Colors.green;
            } else if (meeting.result.toUpperCase() == 'L') {
              badgeColor = Colors.red;
            } else if (meeting.result.toUpperCase() == 'D') {
              badgeColor = Colors.amber;
            }

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          meeting.competition,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: badgeColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            meeting.result,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: badgeColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formattedDate,
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Primary Team (from scoreboard perspective)
                        Expanded(
                          child: Text(
                            meeting.isHome ? match.homeTeam.name : match.awayTeam.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        // Score
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            meeting.score,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        // Opponent Team
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Flexible(
                                child: Text(
                                  meeting.opponentName,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.end,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (meeting.opponentLogo.isNotEmpty)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Image.network(
                                    meeting.opponentLogo,
                                    width: 28,
                                    height: 20,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Icon(Icons.flag, size: 20),
                                  ),
                                )
                              else
                                const Icon(Icons.flag, size: 20),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAiSummaryTab(Match match) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Generate dynamic summary
    String summaryTitle = '';
    String summaryBody = '';
    String starPlayer = 'Not decided yet';
    String starPlayerDetail = '';

    if (match.status == MatchStatus.scheduled) {
      summaryTitle = 'Upcoming Clash Analysis';
      summaryBody = 'This is an upcoming match scheduled at ${match.venue} in ${match.city ?? 'host city'}. '
          'According to current FIFA rankings, ${match.homeTeam.name} (#${match.homeTeam.fifaRanking}) is set to face '
          '${match.awayTeam.name} (#${match.awayTeam.fifaRanking}). This looks to be a highly competitive encounter '
          'with both teams aiming to secure crucial points in the tournament.';
      starPlayer = '${match.homeTeam.name} / ${match.awayTeam.name}';
      starPlayerDetail = 'Look out for key playmakers on both sides to dominate midfield possession.';
    } else if (match.status == MatchStatus.live || match.status == MatchStatus.halftime) {
      summaryTitle = 'Live Match Summary';
      summaryBody = 'A live battle is currently unfolding! The score is ${match.homeScore} - ${match.awayScore} in the ${match.currentMinute}th minute. '
          'Both sides have shown high intensity. ${match.homeTeam.name} is working to enforce possession, while '
          '${match.awayTeam.name} is posing a severe threat on counter-attacks. Everything is still to play for.';
      starPlayer = 'Active Midfielders';
      starPlayerDetail = 'Playmakers are controlling the tempo as the tension escalates in real-time.';
    } else if (match.status == MatchStatus.finished) {
      summaryTitle = 'Post-Match AI Report';
      final homeName = match.homeTeam.name;
      final awayName = match.awayTeam.name;
      final homeScore = match.homeScore;
      final awayScore = match.awayScore;

      if (homeScore > awayScore) {
        summaryBody = 'A dominant performance by $homeName resulted in a $homeScore - $awayScore victory over $awayName at ${match.venue}. '
            'The home team asserted their dominance early on, converting key opportunities and maintaining defensive discipline. '
            'Despite late pressure from $awayName, $homeName successfully closed out the match to claim all three points.';
        starPlayer = '$homeName Attacker';
        starPlayerDetail = 'Made the difference by finding spaces in the box and clinching the decisive goal.';
      } else if (awayScore > homeScore) {
        summaryBody = 'An outstanding away display saw $awayName snatch a $homeScore - $awayScore win against $homeName. '
            'Capitalizing on tactical opportunities, the visitors broke down $homeName\'s backline to secure the goals. '
            'An intense defensive effort in the final minutes guaranteed they took home the win.';
        starPlayer = '$awayName Forward';
        starPlayerDetail = 'Posed a constant threat to the defenders, creating multiple chances and scoring.';
      } else {
        summaryBody = 'A tactical stalemate ended in a $homeScore - $awayScore draw between $homeName and $awayName. '
            'Both teams had their chances to win it, but stout defending and top-tier goalkeeping kept the score level. '
            'Both federations will take a point from this closely contested affair.';
        starPlayer = 'Starting Goalkeepers';
        starPlayerDetail = 'Pulled off several crucial saves to deny the attackers and secure the draw.';
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Explain in 30 seconds card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: AppTheme.glassDecoration(context: context, radius: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.video_camera_back_outlined, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    const Text(
                      '30-SECOND SUMMARY',
                      style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  summaryTitle,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  summaryBody,
                  style: const TextStyle(fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Star Player card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: AppTheme.glassDecoration(context: context, radius: 20),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
                  radius: 24,
                  child: Icon(Icons.star, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'MATCH STAR PLAYER',
                        style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        starPlayer,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        starPlayerDetail,
                        style: const TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Match summary highlights key moments
          if (match.events.isNotEmpty) ...[
            Text(
              'Key Moments Timeline',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: match.events.length,
              itemBuilder: (context, idx) {
                final e = match.events[idx];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${e.minute}\'',
                          style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary, fontSize: 11),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${e.playerName} - ${e.detail}',
                          style: const TextStyle(fontSize: 12.5),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
