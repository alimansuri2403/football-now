import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../core/constants.dart';
import '../core/theme.dart';

class BracketSimulatorScreen extends StatefulWidget {
  const BracketSimulatorScreen({super.key});

  @override
  State<BracketSimulatorScreen> createState() => _BracketSimulatorScreenState();
}

class _BracketSimulatorScreenState extends State<BracketSimulatorScreen> {
  // We represent the bracket rounds as lists of team codes.
  // Round of 32: 32 teams (16 matches)
  // Round of 16: 16 teams (8 matches)
  // Quarterfinals: 8 teams (4 matches)
  // Semifinals: 4 teams (2 matches)
  // Final: 2 teams (1 match)
  // Champion: 1 team

  final List<String> _r32Default = [
    'ARG', 'CAN', 'FRA', 'AUS', 'GER', 'JPN', 'NED', 'EGY',
    'BRA', 'ECU', 'POR', 'KOR', 'ESP', 'MAR', 'BEL', 'SEN',
    'ENG', 'USA', 'URU', 'SUI', 'ITA', 'SWE', 'CRO', 'NOR',
    'COL', 'MEX', 'DEN', 'POL', 'UKR', 'AUT', 'NGA', 'SCO',
  ];

  late List<String> _r32;
  List<String?> _r16 = List.filled(16, null);
  List<String?> _qf = List.filled(8, null);
  List<String?> _sf = List.filled(4, null);
  List<String?> _final = List.filled(2, null);
  String? _champion;

  @override
  void initState() {
    super.initState();
    _r32 = List.from(_r32Default);
    _loadBracket();
  }

  Future<void> _loadBracket() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('bracket_simulator_picks');
    if (saved != null) {
      try {
        final Map<String, dynamic> data = json.decode(saved);
        setState(() {
          if (data['r16'] != null) {
            _r16 = List<String?>.from(data['r16'].map((x) => x as String?));
          }
          if (data['qf'] != null) {
            _qf = List<String?>.from(data['qf'].map((x) => x as String?));
          }
          if (data['sf'] != null) {
            _sf = List<String?>.from(data['sf'].map((x) => x as String?));
          }
          if (data['final'] != null) {
            _final = List<String?>.from(data['final'].map((x) => x as String?));
          }
          _champion = data['champion'];
        });
      } catch (_) {}
    }
  }

  Future<void> _saveBracket() async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'r16': _r16,
      'qf': _qf,
      'sf': _sf,
      'final': _final,
      'champion': _champion,
    };
    await prefs.setString('bracket_simulator_picks', json.encode(data));
  }

  void _resetPicks() {
    setState(() {
      _r16 = List.filled(16, null);
      _qf = List.filled(8, null);
      _sf = List.filled(4, null);
      _final = List.filled(2, null);
      _champion = null;
      _saveBracket();
    });
  }

  void _advanceTeam(int currentRound, int matchIndex, String teamCode) {
    setState(() {
      if (currentRound == 32) {
        // Advances from R32 to R16.
        // Match idx (0-15) advances to slot (idx) in R16.
        _r16[matchIndex] = teamCode;
        // Invalidate dependent subsequent picks
        _clearDownstream(16, matchIndex);
      } else if (currentRound == 16) {
        // Advances from R16 (8 matches) to QF.
        // Match index i (0-7) advances to QF slot i.
        _qf[matchIndex] = teamCode;
        _clearDownstream(8, matchIndex);
      } else if (currentRound == 8) {
        // Advances from QF (4 matches) to SF.
        // Match index i (0-3) advances to SF slot i.
        _sf[matchIndex] = teamCode;
        _clearDownstream(4, matchIndex);
      } else if (currentRound == 4) {
        // Advances from SF (2 matches) to Final.
        // Match index i (0-1) advances to Final slot i.
        _final[matchIndex] = teamCode;
        _clearDownstream(2, matchIndex);
      } else if (currentRound == 2) {
        // Advances from Final to Champion.
        _champion = teamCode;
      }
      _saveBracket();
    });
  }

  void _clearDownstream(int round, int matchIdx) {
    if (round == 16) {
      // Clears QF slot corresponding to R16 matchIdx
      final qfSlot = matchIdx ~/ 2;
      _qf[qfSlot] = null;
      _clearDownstream(8, qfSlot);
    } else if (round == 8) {
      // Clears SF slot corresponding to QF matchIdx
      final sfSlot = matchIdx ~/ 2;
      _sf[sfSlot] = null;
      _clearDownstream(4, sfSlot);
    } else if (round == 4) {
      // Clears Final slot corresponding to SF matchIdx
      final finalSlot = matchIdx ~/ 2;
      _final[finalSlot] = null;
      _clearDownstream(2, finalSlot);
    } else if (round == 2) {
      _champion = null;
    }
  }

  double get _completionPercent {
    int totalPicked = 0;
    for (final x in _r16) { if (x != null) totalPicked++; }
    for (final x in _qf) { if (x != null) totalPicked++; }
    for (final x in _sf) { if (x != null) totalPicked++; }
    for (final x in _final) { if (x != null) totalPicked++; }
    if (_champion != null) totalPicked++;
    
    // total slots to fill = 16 + 8 + 4 + 2 + 1 = 31 picks
    return (totalPicked / 31.0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bracket Simulator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetPicks,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PLAYOFF PREDICTIONS',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Bracket Simulator',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '${(_completionPercent * 100).round()}% Done',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _completionPercent,
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),

            // Horizontal scrolling rounds columns
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRoundColumn('Round of 32', 32, 16, _r32),
                    _buildRoundColumn('Round of 16', 16, 8, _r16),
                    _buildRoundColumn('Quarterfinals', 8, 4, _qf),
                    _buildRoundColumn('Semifinals', 4, 2, _sf),
                    _buildRoundColumn('Final', 2, 1, _final),
                    _buildChampionColumn(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoundColumn(String roundTitle, int roundCode, int matchCount, List<String?> teamsList) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Round header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              roundTitle,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Matches
          Expanded(
            child: ListView.builder(
              physics: const ClampingScrollPhysics(),
              itemCount: matchCount,
              itemBuilder: (context, matchIdx) {
                final homeTeam = teamsList[matchIdx * 2];
                final awayTeam = teamsList[matchIdx * 2 + 1];

                // Determine if a winner was already selected to go to the next round.
                // Next round list index corresponding to this match output is matchIdx.
                String? advancedWinner;
                if (roundCode == 32) advancedWinner = _r16[matchIdx];
                else if (roundCode == 16) advancedWinner = _qf[matchIdx];
                else if (roundCode == 8) advancedWinner = _sf[matchIdx];
                else if (roundCode == 4) advancedWinner = _final[matchIdx];
                else if (roundCode == 2) advancedWinner = _champion;

                return _buildSimulatorMatchCard(
                  roundCode: roundCode,
                  matchIdx: matchIdx,
                  homeCode: homeTeam,
                  awayCode: awayTeam,
                  winnerCode: advancedWinner,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimulatorMatchCard({
    required int roundCode,
    required int matchIdx,
    required String? homeCode,
    required String? awayCode,
    required String? winnerCode,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: AppTheme.glassDecoration(context: context, radius: 16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _buildTeamSelectorRow(roundCode, matchIdx, homeCode, winnerCode, theme),
          const Divider(height: 1, color: Colors.white12),
          _buildTeamSelectorRow(roundCode, matchIdx, awayCode, winnerCode, theme),
        ],
      ),
    );
  }

  Widget _buildTeamSelectorRow(int roundCode, int matchIdx, String? teamCode, String? winnerCode, ThemeData theme) {
    final isSelected = teamCode != null && winnerCode == teamCode;
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: teamCode == null ? null : () => _advanceTeam(roundCode, matchIdx, teamCode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        color: isSelected ? theme.colorScheme.primary.withOpacity(0.15) : Colors.transparent,
        child: Row(
          children: [
            if (teamCode != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: Image.network(
                  AppConstants.getFlagUrl(_getFlagCode(teamCode)),
                  width: 22,
                  height: 15,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.flag, size: 15),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  teamCode,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? theme.colorScheme.primary : null,
                  ),
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle, color: theme.colorScheme.primary, size: 16),
            ] else ...[
              Container(
                width: 22,
                height: 15,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              const Text('TBD', style: TextStyle(color: Colors.grey, fontSize: 13)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChampionColumn() {
    final theme = Theme.of(context);
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'CHAMPION',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.amber),
            ),
          ),
          const SizedBox(height: 64),
          if (_champion != null) ...[
            const Icon(Icons.workspace_premium, color: Colors.amber, size: 64),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                AppConstants.getFlagUrl(_getFlagCode(_champion!)),
                width: 64,
                height: 44,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _champion!,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: Colors.amber,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Predicted World Cup Winner!',
              style: TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ] else ...[
            Icon(Icons.emoji_events_outlined, color: Colors.grey.withOpacity(0.4), size: 64),
            const SizedBox(height: 16),
            const Text(
              'Advance teams to determine your Champion!',
              style: TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ]
        ],
      ),
    );
  }

  String _getFlagCode(String teamCode) {
    // Basic codes fallback mapping
    final Map<String, String> map = {
      'ARG': 'ar', 'BRA': 'br', 'FRA': 'fr', 'ENG': 'gb-eng', 'GER': 'de',
      'ESP': 'es', 'POR': 'pt', 'NED': 'nl', 'BEL': 'be', 'URU': 'uy',
      'USA': 'us', 'MEX': 'mx', 'CAN': 'ca', 'JPN': 'jp', 'KOR': 'kr',
      'AUS': 'au', 'MAR': 'ma', 'SEN': 'sn', 'EGY': 'eg', 'COL': 'co',
      'ECU': 'ec', 'SUI': 'ch', 'SWE': 'se', 'CRO': 'hr', 'NOR': 'no',
      'DEN': 'dk', 'POL': 'pl', 'UKR': 'ua', 'AUT': 'at', 'NGA': 'ng',
      'SCO': 'gb-sct',
    };
    return map[teamCode] ?? teamCode.substring(0, 2).toLowerCase();
  }
}
