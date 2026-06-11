import 'dart:async';
import '../models/match.dart';
import '../models/team.dart';
import '../models/player.dart';
import '../services/espn_api.dart';
import 'wc2026_data.dart';


/// Abstract repository interface.
abstract class DataRepository {
  Future<List<Team>> getTeams();
  Future<Team?> getTeamById(String id);
  Future<List<Player>> getPlayers();
  Future<Player?> getPlayerById(String id);
  Future<List<Player>> getPlayersByTeam(String teamId);
  Future<List<Match>> getUpcomingMatches();
  Future<List<Match>> getFinishedMatches();
  Future<Match?> getMatchById(String id);
  Stream<List<Match>> getLiveMatchesStream();
  Future<List<GroupStanding>> getGroupStandings(String groupName);
  void dispose();
}

/// Clean repository — loaded with static teams/players from WC2026Data.
/// Standings are computed dynamically from matches.
class MockDataRepository implements DataRepository {
  final List<Match> Function()? getMatches;
  final EspnApiService? espnApi;
  final StreamController<List<Match>> _controller =
      StreamController<List<Match>>.broadcast();

  final Map<String, List<Player>> _rosterCache = {};

  MockDataRepository({this.getMatches, this.espnApi}) {
    _preCacheRosters();
  }

  void _preCacheRosters() async {
    // 1. Prioritized top teams for concurrent fetch on startup to resolve instantly
    final priorityTeams = ['ARG', 'POR', 'FRA', 'ENG', 'BRA', 'ESP', 'GER', 'NED', 'URU', 'BEL', 'USA', 'MEX', 'CAN'];
    
    if (espnApi != null) {
      try {
        await Future.wait(priorityTeams.map((code) async {
          final espnId = _teamCodeToEspnId[code];
          if (espnId != null) {
            try {
              await getPlayersByTeam(code);
            } catch (_) {}
          }
        }));
      } catch (_) {}
    }

    // 2. Fetch the rest of the teams sequentially with a delay in the background
    final remainingTeams = _teamCodeToEspnId.keys.where((code) => !priorityTeams.contains(code)).toList();
    for (final code in remainingTeams) {
      if (_rosterCache.containsKey(code)) continue;
      final espnId = _teamCodeToEspnId[code];
      if (espnId != null && espnApi != null) {
        try {
          await getPlayersByTeam(code);
        } catch (_) {}
      }
      await Future.delayed(const Duration(milliseconds: 300));
    }
  }

  String _simplifyName(String name) {
    return name
        .toLowerCase()
        .replaceAll(' ', '')
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ñ', 'n')
        .replaceAll('ü', 'u')
        .replaceAll('ö', 'o');
  }


  static const Map<String, String> _teamCodeToEspnId = {
    'MEX': '203', 'RSA': '467', 'KOR': '451', 'CZE': '450',
    'CAN': '206', 'BIH': '452', 'QAT': '4398', 'SUI': '475',
    'BRA': '205', 'MAR': '2869', 'HAI': '2654', 'SCO': '580',
    'USA': '660', 'PAR': '210', 'AUS': '628', 'TUR': '465',
    'GER': '481', 'CUW': '11678', 'CIV': '4789', 'ECU': '209',
    'NED': '449', 'JPN': '627', 'SWE': '466', 'TUN': '659',
    'BEL': '459', 'EGY': '2620', 'IRN': '469', 'NZL': '2666',
    'ESP': '164', 'CPV': '2597', 'SAU': '655', 'URU': '212',
    'FRA': '478', 'SEN': '654', 'IRQ': '4375', 'NOR': '464',
    'ARG': '202', 'ALG': '624', 'AUT': '474', 'JOR': '2917',
    'POR': '482', 'COD': '2850', 'UZB': '2570', 'COL': '208',
    'ENG': '448', 'CRO': '477', 'GHA': '4469', 'PAN': '2659',
  };



  static const Map<String, String> _teamGroups = {
    // Group A
    'MEX': 'A', 'RSA': 'A', 'KOR': 'A', 'CZE': 'A',
    // Group B
    'CAN': 'B', 'BIH': 'B', 'QAT': 'B', 'SUI': 'B',
    // Group C
    'BRA': 'C', 'MAR': 'C', 'HAI': 'C', 'SCO': 'C',
    // Group D
    'USA': 'D', 'PAR': 'D', 'AUS': 'D', 'TUR': 'D',
    // Group E
    'GER': 'E', 'CUW': 'E', 'CIV': 'E', 'ECU': 'E',
    // Group F
    'NED': 'F', 'JPN': 'F', 'SWE': 'F', 'TUN': 'F',
    // Group G
    'BEL': 'G', 'EGY': 'G', 'IRN': 'G', 'NZL': 'G',
    // Group H
    'ESP': 'H', 'CPV': 'H', 'SAU': 'H', 'URU': 'H',
    // Group I
    'FRA': 'I', 'SEN': 'I', 'IRQ': 'I', 'NOR': 'I',
    // Group J
    'ARG': 'J', 'ALG': 'J', 'AUT': 'J', 'JOR': 'J',
    // Group K
    'POR': 'K', 'COD': 'K', 'UZB': 'K', 'COL': 'K',
    // Group L
    'ENG': 'L', 'CRO': 'L', 'GHA': 'L', 'PAN': 'L',
  };

  Team _mapTeam(WC2026Team t) {
    final code = t.code.toUpperCase();
    final group = _teamGroups[code] ?? t.group;
    return Team(
      id: code,
      name: t.name,
      code: code,
      flagCode: t.flagCode,
      group: group,
      fifaRanking: t.fifaRanking,
      coach: t.coach,
    );
  }

  Player _mapPlayer(WC2026Player p, WC2026Team t) {
    final String id = '${t.code}_${p.number}_${p.name.replaceAll(' ', '_')}';
    
    // Map position short name to long name
    String positionLong = 'Forward';
    if (p.position == 'GK') {
      positionLong = 'Goalkeeper';
    } else if (p.position == 'DEF') {
      positionLong = 'Defender';
    } else if (p.position == 'MID') {
      positionLong = 'Midfielder';
    }

    final int seed = p.name.hashCode;
    int goals = 0;
    int assists = 0;
    if (p.position == 'FWD') {
      goals = (seed.abs() % 6); // 0 to 5 goals
      assists = ((seed.abs() >> 2) % 4); // 0 to 3 assists
    } else if (p.position == 'MID') {
      goals = (seed.abs() % 3); // 0 to 2 goals
      assists = ((seed.abs() >> 2) % 6); // 0 to 5 assists
    } else if (p.position == 'DEF') {
      goals = (seed.abs() % 2); // 0 to 1 goals
      assists = ((seed.abs() >> 2) % 3); // 0 to 2 assists
    }
    
    final int matchesPlayed = 3 + (seed.abs() % 3);
    final int minutesPlayed = matchesPlayed * 90 - (seed.abs() % 45);
    final int yellowCards = (seed.abs() % 3) == 0 ? 1 : 0;
    final int redCards = (seed.abs() % 15) == 0 ? 1 : 0;

    int rating = 70 + (seed.abs() % 20); // 70 to 89
    if (p.name == 'Lionel Messi' || p.name == 'Cristiano Ronaldo' || p.name == 'Kylian Mbappé' || p.name == 'Jude Bellingham' || p.name == 'Erling Haaland') {
      rating = 92 + (seed.abs() % 5); // 92 to 96
    }

    // Try to find matching player in ESPN roster cache to copy photoUrl & details
    String photoUrl = '';
    int jersey = p.number;
    int age = p.age;
    String position = positionLong;
    List<String> pastRecords = ['Plays for ${p.club}'];

    final cacheKey = t.code.toUpperCase();
    if (_rosterCache.containsKey(cacheKey)) {
      final cachedPlayers = _rosterCache[cacheKey]!;
      for (final cp in cachedPlayers) {
        if (_simplifyName(cp.name) == _simplifyName(p.name) || cp.number == p.number) {
          photoUrl = cp.photoUrl;
          jersey = cp.number;
          age = cp.age;
          position = cp.position;
          if (cp.pastRecords.isNotEmpty) {
            pastRecords = List<String>.from(cp.pastRecords);
          }
          break;
        }
      }
    }

    return Player(
      id: id,
      name: p.name,
      teamId: t.code,
      teamName: t.name,
      position: position,
      number: jersey,
      age: age,
      photoUrl: photoUrl,
      rating: rating,
      pastRecords: pastRecords,
      stats: PlayerStats(
        goals: goals,
        assists: assists,
        yellowCards: yellowCards,
        redCards: redCards,
        minutesPlayed: minutesPlayed,
        matchesPlayed: matchesPlayed,
      ),
    );
  }

  String _getTeamGroup(String teamCode) {
    return _teamGroups[teamCode.toUpperCase()] ?? '';
  }

  String _mapLegacyCode(String code) {
    if (code == 'SAU') return 'KSA';
    if (code == 'KSA') return 'SAU';
    return code;
  }

  List<Player> _generateDefaultPlayers(Team team) {
    final List<Player> list = [];
    final positions = ['GK', 'DEF', 'MID', 'FWD'];
    final names = ['Captain', 'Striker', 'Playmaker', 'Defender', 'Goalie'];
    
    for (int i = 0; i < 11; i++) {
      final name = '${team.name} Player ${i + 1}';
      final pos = positions[i % positions.length];
      
      list.add(Player(
        id: '${team.code}_${i + 1}',
        name: name,
        teamId: team.code,
        teamName: team.name,
        position: pos == 'GK' ? 'Goalkeeper' : (pos == 'DEF' ? 'Defender' : (pos == 'MID' ? 'Midfielder' : 'Forward')),
        number: i + 1,
        age: 22 + (i % 8),
        photoUrl: '',
        rating: 70 + (i % 15),
        pastRecords: const [],
        stats: PlayerStats(
          goals: i % 4 == 0 ? 1 : 0,
          assists: i % 3 == 0 ? 1 : 0,
          yellowCards: 0,
          redCards: 0,
          minutesPlayed: 180,
          matchesPlayed: 2,
        ),
      ));
    }
    return list;
  }

  @override
  Future<List<Team>> getTeams() async {
    final List<Team> list = [];
    
    final List<Map<String, String>> espnTeams = [
      {'code': 'MEX', 'name': 'Mexico', 'flag': 'mx', 'group': 'A'},
      {'code': 'RSA', 'name': 'South Africa', 'flag': 'za', 'group': 'A'},
      {'code': 'KOR', 'name': 'South Korea', 'flag': 'kr', 'group': 'A'},
      {'code': 'CZE', 'name': 'Czechia', 'flag': 'cz', 'group': 'A'},
      
      {'code': 'CAN', 'name': 'Canada', 'flag': 'ca', 'group': 'B'},
      {'code': 'BIH', 'name': 'Bosnia and Herzegovina', 'flag': 'ba', 'group': 'B'},
      {'code': 'QAT', 'name': 'Qatar', 'flag': 'qa', 'group': 'B'},
      {'code': 'SUI', 'name': 'Switzerland', 'flag': 'ch', 'group': 'B'},
      
      {'code': 'BRA', 'name': 'Brazil', 'flag': 'br', 'group': 'C'},
      {'code': 'MAR', 'name': 'Morocco', 'flag': 'ma', 'group': 'C'},
      {'code': 'HAI', 'name': 'Haiti', 'flag': 'ht', 'group': 'C'},
      {'code': 'SCO', 'name': 'Scotland', 'flag': 'gb-sct', 'group': 'C'},
      
      {'code': 'USA', 'name': 'USA', 'flag': 'us', 'group': 'D'},
      {'code': 'PAR', 'name': 'Paraguay', 'flag': 'py', 'group': 'D'},
      {'code': 'AUS', 'name': 'Australia', 'flag': 'au', 'group': 'D'},
      {'code': 'TUR', 'name': 'Türkiye', 'flag': 'tr', 'group': 'D'},
      
      {'code': 'GER', 'name': 'Germany', 'flag': 'de', 'group': 'E'},
      {'code': 'CUW', 'name': 'Curaçao', 'flag': 'cw', 'group': 'E'},
      {'code': 'CIV', 'name': 'Ivory Coast', 'flag': 'ci', 'group': 'E'},
      {'code': 'ECU', 'name': 'Ecuador', 'flag': 'ec', 'group': 'E'},
      
      {'code': 'NED', 'name': 'Netherlands', 'flag': 'nl', 'group': 'F'},
      {'code': 'JPN', 'name': 'Japan', 'flag': 'jp', 'group': 'F'},
      {'code': 'SWE', 'name': 'Sweden', 'flag': 'se', 'group': 'F'},
      {'code': 'TUN', 'name': 'Tunisia', 'flag': 'tn', 'group': 'F'},
      
      {'code': 'BEL', 'name': 'Belgium', 'flag': 'be', 'group': 'G'},
      {'code': 'EGY', 'name': 'Egypt', 'flag': 'eg', 'group': 'G'},
      {'code': 'IRN', 'name': 'Iran', 'flag': 'ir', 'group': 'G'},
      {'code': 'NZL', 'name': 'New Zealand', 'flag': 'nz', 'group': 'G'},
      
      {'code': 'ESP', 'name': 'Spain', 'flag': 'es', 'group': 'H'},
      {'code': 'CPV', 'name': 'Cabo Verde', 'flag': 'cv', 'group': 'H'},
      {'code': 'SAU', 'name': 'Saudi Arabia', 'flag': 'sa', 'group': 'H'},
      {'code': 'URU', 'name': 'Uruguay', 'flag': 'uy', 'group': 'H'},
      
      {'code': 'FRA', 'name': 'France', 'flag': 'fr', 'group': 'I'},
      {'code': 'SEN', 'name': 'Senegal', 'flag': 'sn', 'group': 'I'},
      {'code': 'IRQ', 'name': 'Iraq', 'flag': 'iq', 'group': 'I'},
      {'code': 'NOR', 'name': 'Norway', 'flag': 'no', 'group': 'I'},
      
      {'code': 'ARG', 'name': 'Argentina', 'flag': 'ar', 'group': 'J'},
      {'code': 'ALG', 'name': 'Algeria', 'flag': 'dz', 'group': 'J'},
      {'code': 'AUT', 'name': 'Austria', 'flag': 'at', 'group': 'J'},
      {'code': 'JOR', 'name': 'Jordan', 'flag': 'jo', 'group': 'J'},
      
      {'code': 'POR', 'name': 'Portugal', 'flag': 'pt', 'group': 'K'},
      {'code': 'COD', 'name': 'DR Congo', 'flag': 'cd', 'group': 'K'},
      {'code': 'UZB', 'name': 'Uzbekistan', 'flag': 'uz', 'group': 'K'},
      {'code': 'COL', 'name': 'Colombia', 'flag': 'co', 'group': 'K'},
      
      {'code': 'ENG', 'name': 'England', 'flag': 'gb-eng', 'group': 'L'},
      {'code': 'CRO', 'name': 'Croatia', 'flag': 'hr', 'group': 'L'},
      {'code': 'GHA', 'name': 'Ghana', 'flag': 'gh', 'group': 'L'},
      {'code': 'PAN', 'name': 'Panama', 'flag': 'pa', 'group': 'L'},
    ];

    for (final et in espnTeams) {
      final code = et['code']!;
      final name = et['name']!;
      final flag = et['flag']!;
      final group = et['group']!;
      
      WC2026Team? staticTeam;
      try {
        staticTeam = WC2026Data.teams.firstWhere(
          (t) => t.code.toUpperCase() == code || t.code.toUpperCase() == _mapLegacyCode(code)
        );
      } catch (_) {}

      list.add(Team(
        id: code,
        name: name,
        code: code,
        flagCode: flag,
        group: group,
        fifaRanking: staticTeam?.fifaRanking ?? 50,
        coach: staticTeam?.coach ?? 'Head Coach',
      ));
    }
    return list;
  }

  @override
  Future<Team?> getTeamById(String id) async {
    try {
      final teams = await getTeams();
      return teams.firstWhere(
        (t) => t.code.toUpperCase() == id.toUpperCase() || t.name.toUpperCase() == id.toUpperCase(),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Player>> getPlayers() async {
    final List<Player> players = [];
    final teams = await getTeams();
    for (final team in teams) {
      WC2026Team? staticTeam;
      try {
        staticTeam = WC2026Data.teams.firstWhere(
          (t) => t.code.toUpperCase() == team.code || t.code.toUpperCase() == _mapLegacyCode(team.code)
        );
      } catch (_) {}

      if (staticTeam != null && staticTeam.squad.isNotEmpty) {
        for (final p in staticTeam.squad) {
          players.add(_mapPlayer(p, staticTeam));
        }
      } else {
        players.addAll(_generateDefaultPlayers(team));
      }
    }
    return players;
  }

  @override
  Future<Player?> getPlayerById(String id) async {
    try {
      // Search in cached rosters first
      for (final roster in _rosterCache.values) {
        for (final p in roster) {
          if (p.id == id) return p;
        }
      }
      final all = await getPlayers();
      return all.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Player>> getPlayersByTeam(String teamId) async {
    try {
      final teams = await getTeams();
      final team = teams.firstWhere(
        (t) => t.code.toUpperCase() == teamId.toUpperCase() || t.name.toUpperCase() == teamId.toUpperCase(),
      );
      final cacheKey = team.code.toUpperCase();
      if (_rosterCache.containsKey(cacheKey)) {
        return _rosterCache[cacheKey]!;
      }

      if (espnApi != null) {
        final espnId = _teamCodeToEspnId[cacheKey];
        if (espnId != null) {
          final roster = await espnApi!.fetchTeamRoster(espnId, team.code, team.name);
          if (roster.isNotEmpty) {
            _rosterCache[cacheKey] = roster;
            return roster;
          }
        }
      }

      WC2026Team? staticTeam;
      try {
        staticTeam = WC2026Data.teams.firstWhere(
          (t) => t.code.toUpperCase() == team.code || t.code.toUpperCase() == _mapLegacyCode(team.code)
        );
      } catch (_) {}

      List<Player> fallbackList;
      if (staticTeam != null && staticTeam.squad.isNotEmpty) {
        fallbackList = staticTeam.squad.map((p) => _mapPlayer(p, staticTeam!)).toList();
      } else {
        fallbackList = _generateDefaultPlayers(team);
      }

      _rosterCache[cacheKey] = fallbackList;
      return fallbackList;
    } catch (_) {
      return [];
    }
  }


  @override
  Future<List<Match>> getUpcomingMatches() async => [];

  @override
  Future<List<Match>> getFinishedMatches() async => [];

  @override
  Future<Match?> getMatchById(String id) async => null;

  @override
  Stream<List<Match>> getLiveMatchesStream() => _controller.stream;

  @override
  Future<List<GroupStanding>> getGroupStandings(String groupName) async {
    // 1. Get all teams in this group from our clean getTeams()
    final allTeams = await getTeams();
    final groupTeams = allTeams
        .where((t) => t.group.toUpperCase() == groupName.toUpperCase())
        .toList();

    // 2. Initialize map of standings
    final Map<String, GroupStanding> standingsMap = {
      for (final team in groupTeams)
        team.code.toUpperCase(): GroupStanding(
          team: team,
          played: 0,
          won: 0,
          drawn: 0,
          lost: 0,
          goalsFor: 0,
          goalsAgainst: 0,
          points: 0,
        ),
    };

    // 3. Get matches from callback
    final matches = getMatches?.call() ?? [];

    // 4. Update stats from matches that have kicked off (live, halftime, finished)
    for (final match in matches) {
      final homeCode = match.homeTeam.code.toUpperCase();
      final awayCode = match.awayTeam.code.toUpperCase();
      
      final homeGroup = _teamGroups[homeCode] ?? '';
      final awayGroup = _teamGroups[awayCode] ?? '';
      
      final bool isThisGroup = match.group?.toUpperCase() == groupName.toUpperCase() ||
          homeGroup.toUpperCase() == groupName.toUpperCase() ||
          awayGroup.toUpperCase() == groupName.toUpperCase();

      if (isThisGroup &&
          (match.status == MatchStatus.finished ||
           match.status == MatchStatus.live ||
           match.status == MatchStatus.halftime)) {
        
        final homeStanding = standingsMap[homeCode];
        final awayStanding = standingsMap[awayCode];

        if (homeStanding != null && awayStanding != null) {
          final hs = match.homeScore;
          final as = match.awayScore;

          final bool homeWon = hs > as;
          final bool awayWon = as > hs;
          final bool draw = hs == as;

          standingsMap[homeCode] = GroupStanding(
            team: homeStanding.team,
            played: homeStanding.played + 1,
            won: homeStanding.won + (homeWon ? 1 : 0),
            drawn: homeStanding.drawn + (draw ? 1 : 0),
            lost: homeStanding.lost + (awayWon ? 1 : 0),
            goalsFor: homeStanding.goalsFor + hs,
            goalsAgainst: homeStanding.goalsAgainst + as,
            points: homeStanding.points + (homeWon ? 3 : (draw ? 1 : 0)),
          );

          standingsMap[awayCode] = GroupStanding(
            team: awayStanding.team,
            played: awayStanding.played + 1,
            won: awayStanding.won + (awayWon ? 1 : 0),
            drawn: awayStanding.drawn + (draw ? 1 : 0),
            lost: awayStanding.lost + (homeWon ? 1 : 0),
            goalsFor: awayStanding.goalsFor + as,
            goalsAgainst: awayStanding.goalsAgainst + hs,
            points: awayStanding.points + (awayWon ? 3 : (draw ? 1 : 0)),
          );
        }
      }
    }

    // 5. Convert to list and sort by points, goal difference, goals for
    final list = standingsMap.values.toList();
    list.sort((a, b) {
      if (b.points != a.points) return b.points.compareTo(a.points);
      if (b.goalDifference != a.goalDifference) return b.goalDifference.compareTo(a.goalDifference);
      return b.goalsFor.compareTo(a.goalsFor);
    });

    return list;
  }

  @override
  void dispose() {
    _controller.close();
  }
}

