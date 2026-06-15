import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/match.dart';
import '../models/team.dart';
import '../models/player.dart';
import '../data/wc2026_data.dart';

/// Represents a historical head-to-head meeting between two teams.
class H2hMeeting {
  final String date;
  final String competition;
  final String score;
  final String result; // W, D, L
  final String opponentName;
  final String opponentLogo;
  final bool isHome;

  H2hMeeting({
    required this.date,
    required this.competition,
    required this.score,
    required this.result,
    required this.opponentName,
    required this.opponentLogo,
    required this.isHome,
  });
}

/// ESPN public scoreboard — no API key, no signup.
/// Source: https://site.api.espn.com/apis/site/v2/sports/soccer/fifa.world/scoreboard
/// Same endpoint used by the open-source "claudinho" project.
class EspnApiService {
  static const String _baseUrl =
      'https://site.api.espn.com/apis/site/v2/sports/soccer/fifa.world';

  static const Map<String, String> _headers = {
    'User-Agent': 'fifa2026_app/1.0 (Flutter; Educational)',
    'Accept': 'application/json',
  };

  // ── Scoreboard ─────────────────────────────────────────────────────────────

  /// Fetch today's matches + live scores.
  Future<List<Match>> fetchScoreboard() async {
    try {
      final uri = Uri.parse('$_baseUrl/scoreboard');
      final response = await http.get(uri, headers: _headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return _parseEvents(data);
      } else {
        debugPrint('ESPN scoreboard error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('ESPN fetch error: $e');
      return [];
    }
  }

  /// Fetch all fixtures (full tournament schedule).
  Future<List<Match>> fetchAllFixtures() async {
    try {
      final List<Match> allMatches = [];
      // ESPN paginates by dates; fetch a broad range for the tournament
      final dates = _tournamentDateRanges();
      for (final dateParam in dates) {
        final uri = Uri.parse('$_baseUrl/scoreboard?dates=$dateParam&limit=100');
        final response = await http.get(uri, headers: _headers)
            .timeout(const Duration(seconds: 15));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          allMatches.addAll(_parseEvents(data));
        }
        // Small delay to be respectful of rate limits
        await Future.delayed(const Duration(milliseconds: 300));
      }
      // Deduplicate by id
      final seen = <String>{};
      final list = allMatches.where((m) => seen.add(m.id)).toList();
      if (list.isEmpty) {
        debugPrint('ESPN all fixtures returned empty, using local fallback.');
        return _generateLocalMockFixtures();
      }
      return list;
    } catch (e) {
      debugPrint('ESPN all fixtures error: $e, using local fallback.');
      return _generateLocalMockFixtures();
    }
  }

  /// Fetch the real team roster from ESPN.
  Future<List<Player>> fetchTeamRoster(String espnTeamId, String teamCode, String teamName) async {
    try {
      final uri = Uri.parse('$_baseUrl/teams/$espnTeamId/roster');
      final response = await http.get(uri, headers: _headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final athletes = (data['athletes'] as List<dynamic>?) ?? [];
        final List<Player> players = [];

        for (final athleteData in athletes) {
          final athlete = athleteData as Map<String, dynamic>;
          final id = athlete['id']?.toString() ?? '';
          if (id.isEmpty) continue;

          final name = athlete['fullName']?.toString() ?? athlete['displayName']?.toString() ?? 'Player';
          final jerseyStr = athlete['jersey']?.toString() ?? '0';
          final jersey = int.tryParse(jerseyStr) ?? 0;
          final age = athlete['age'] is num ? (athlete['age'] as num).toInt() : 25;
          final photoUrl = 'https://a.espncdn.com/i/headshots/soccer/players/full/$id.png';

          // Position parsing
          final posData = athlete['position'] as Map<String, dynamic>? ?? {};
          final posName = (posData['displayName']?.toString() ?? posData['name']?.toString() ?? '').toLowerCase();
          final posAbbr = (posData['abbreviation']?.toString() ?? '').toUpperCase();
          
          String position = 'Midfielder';
          if (posName.contains('goalkeeper') || posAbbr == 'G' || posAbbr == 'GK') {
            position = 'Goalkeeper';
          } else if (posName.contains('defender') || posAbbr == 'D' || posAbbr == 'DF') {
            position = 'Defender';
          } else if (posName.contains('midfielder') || posAbbr == 'M' || posAbbr == 'MF') {
            position = 'Midfielder';
          } else if (posName.contains('forward') || posName.contains('striker') || posAbbr == 'F' || posAbbr == 'FW') {
            position = 'Forward';
          }

          // Past records / bio details
          final pastRecords = <String>[];
          final citizenship = athlete['citizenship']?.toString() ?? '';
          if (citizenship.isNotEmpty) {
            pastRecords.add('Citizenship: $citizenship');
          }
          final displayHeight = athlete['displayHeight']?.toString() ?? '';
          if (displayHeight.isNotEmpty) {
            pastRecords.add('Height: $displayHeight');
          }
          final displayWeight = athlete['displayWeight']?.toString() ?? '';
          if (displayWeight.isNotEmpty) {
            pastRecords.add('Weight: $displayWeight');
          }
          final birthPlace = athlete['birthPlace'] as Map<String, dynamic>?;
          if (birthPlace != null) {
            final city = birthPlace['city']?.toString() ?? '';
            final state = birthPlace['state']?.toString() ?? '';
            final country = birthPlace['country']?.toString() ?? '';
            final List<String> parts = [];
            if (city.isNotEmpty) parts.add(city);
            if (state.isNotEmpty) parts.add(state);
            if (country.isNotEmpty) parts.add(country);
            if (parts.isNotEmpty) {
              pastRecords.add('Birthplace: ${parts.join(", ")}');
            }
          }

          // Determinstic stats & rating using athlete ID/Name as seed
          final int seed = name.hashCode;
          final int rating = 72 + (seed.abs() % 18); // 72 to 90
          final int goals = position == 'Forward' ? (seed.abs() % 5) : (position == 'Midfielder' ? (seed.abs() % 3) : 0);
          final int assists = position == 'Midfielder' ? (seed.abs() % 4) : (position == 'Forward' ? (seed.abs() % 3) : (seed.abs() % 2));
          final int matchesPlayed = 3 + (seed.abs() % 3);
          final int minutesPlayed = matchesPlayed * 90 - (seed.abs() % 30);
          final int yellowCards = (seed.abs() % 4) == 0 ? 1 : 0;
          final int redCards = (seed.abs() % 25) == 0 ? 1 : 0;

          players.add(Player(
            id: '${teamCode}_${id}',
            name: name,
            teamId: teamCode,
            teamName: teamName,
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
          ));
        }

        return players;
      } else {
        debugPrint('ESPN roster error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('ESPN fetch roster error: $e');
      return [];
    }
  }

  /// Fetch historical meetings (H2H) summary for a given event ID.
  Future<List<H2hMeeting>> fetchMatchSummary(String eventId) async {
    try {
      final uri = Uri.parse('$_baseUrl/summary?event=$eventId');
      final response = await http.get(uri, headers: _headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final headToHeadGames = data['headToHeadGames'] as List<dynamic>? ?? [];
        if (headToHeadGames.isEmpty) return [];

        final firstGroup = headToHeadGames.first as Map<String, dynamic>;
        final events = (firstGroup['events'] as List<dynamic>?) ?? [];
        final List<H2hMeeting> meetings = [];

        for (final ev in events) {
          final eventMap = ev as Map<String, dynamic>;
          final dateStr = eventMap['gameDate']?.toString() ?? '';
          final competition = eventMap['competitionName']?.toString() ?? eventMap['leagueName']?.toString() ?? 'International Match';
          final score = eventMap['score']?.toString() ?? '';
          final result = eventMap['gameResult']?.toString() ?? 'D';
          
          final opponent = eventMap['opponent'] as Map<String, dynamic>? ?? {};
          final opponentName = opponent['displayName']?.toString() ?? 'Opponent';
          final opponentLogo = eventMap['opponentLogo']?.toString() ?? opponent['logo']?.toString() ?? '';
          
          // Determine if home
          final isHome = eventMap['atVs'] == 'vs';

          meetings.add(H2hMeeting(
            date: dateStr,
            competition: competition,
            score: score,
            result: result,
            opponentName: opponentName,
            opponentLogo: opponentLogo,
            isHome: isHome,
          ));
        }
        return meetings;
      } else {
        debugPrint('ESPN summary error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('ESPN fetch summary error: $e');
      return [];
    }
  }

  // ── Parsing ─────────────────────────────────────────────────────────────────


  List<Match> _parseEvents(Map<String, dynamic> data) {
    final events = (data['events'] as List<dynamic>?) ?? [];
    final matches = <Match>[];
    for (final event in events) {
      try {
        final match = _parseEvent(event as Map<String, dynamic>);
        if (match != null) matches.add(match);
      } catch (e) {
        debugPrint('Failed to parse event: $e');
      }
    }
    return matches;
  }

  Match? _parseEvent(Map<String, dynamic> event) {
    final id = event['id']?.toString() ?? '';
    final competitions = (event['competitions'] as List<dynamic>?) ?? [];
    if (competitions.isEmpty) return null;

    final comp = competitions.first as Map<String, dynamic>;
    final competitors = (comp['competitors'] as List<dynamic>?) ?? [];
    if (competitors.length < 2) return null;

    // Find home and away
    Map<String, dynamic>? homeComp;
    Map<String, dynamic>? awayComp;
    for (final c in competitors) {
      final cm = c as Map<String, dynamic>;
      if (cm['homeAway'] == 'home') {
        homeComp = cm;
      } else {
        awayComp = cm;
      }
    }
    homeComp ??= competitors[0] as Map<String, dynamic>;
    awayComp ??= competitors[1] as Map<String, dynamic>;

    final homeTeamData = homeComp['team'] as Map<String, dynamic>? ?? {};
    final awayTeamData = awayComp['team'] as Map<String, dynamic>? ?? {};

    final homeTeamName = homeTeamData['displayName']?.toString() ??
        homeTeamData['shortDisplayName']?.toString() ?? 'TBD';
    final awayTeamName = awayTeamData['displayName']?.toString() ??
        awayTeamData['shortDisplayName']?.toString() ?? 'TBD';

    final homeAbbrRaw = homeTeamData['abbreviation']?.toString() ?? 'HOM';
    final awayAbbrRaw = awayTeamData['abbreviation']?.toString() ?? 'AWY';
    final homeAbbr = _normalizeAbbr(homeAbbrRaw);
    final awayAbbr = _normalizeAbbr(awayAbbrRaw);

    final homeScore = int.tryParse(homeComp['score']?.toString() ?? '') ?? 0;
    final awayScore = int.tryParse(awayComp['score']?.toString() ?? '') ?? 0;

    // Status
    final statusData = comp['status'] as Map<String, dynamic>? ??
        event['status'] as Map<String, dynamic>? ?? {};
    final statusType = statusData['type'] as Map<String, dynamic>? ?? {};
    final state = statusType['state']?.toString() ?? 'pre';
    final statusName = (statusType['name']?.toString() ?? '').toUpperCase();

    MatchStatus status;
    if (statusName.contains('HALFTIME')) {
      status = MatchStatus.halftime;
    } else if (statusName.contains('POSTPONED')) {
      status = MatchStatus.postponed;
    } else if (state == 'in') {
      status = MatchStatus.live;
    } else if (state == 'post') {
      status = MatchStatus.finished;
    } else {
      status = MatchStatus.scheduled;
    }

    // Match minute
    int? minute;
    if (state == 'in') {
      final displayClock = statusData['displayClock']?.toString() ?? '';
      final clockMatch = RegExp(r'(\d+)').firstMatch(displayClock);
      if (clockMatch != null) {
        minute = int.tryParse(clockMatch.group(1)!);
      } else {
        final clock = statusData['clock'];
        if (clock is num && clock > 0) {
          minute = (clock / 60).floor();
        }
      }
    }

    // Kickoff time
    final dateStr = comp['date']?.toString() ?? event['date']?.toString() ?? '';
    DateTime kickoff = DateTime.now();
    if (dateStr.isNotEmpty) {
      kickoff = DateTime.tryParse(dateStr) ?? DateTime.now();
    }

    // Venue
    final venue = comp['venue'] as Map<String, dynamic>? ?? {};
    final venueName = venue['fullName']?.toString() ?? '';
    final address = venue['address'] as Map<String, dynamic>? ?? {};
    final city = address['city']?.toString() ?? '';

    // Stage
    final season = event['season'] as Map<String, dynamic>? ?? {};
    final slug = season['slug']?.toString() ?? '';
    final stage = _stageFromSlug(slug);

    final groupName = _countryToGroup[homeAbbr] ?? _countryToGroup[awayAbbr];

    final rawMatch = Match(
      id: id,
      homeTeam: _buildTeam(homeAbbr, homeTeamName, homeTeamData['id']?.toString() ?? ''),
      awayTeam: _buildTeam(awayAbbr, awayTeamName, awayTeamData['id']?.toString() ?? ''),
      homeScore: homeScore,
      awayScore: awayScore,
      status: status,
      kickoffTime: kickoff,
      minute: minute,
      venue: venueName,
      city: city,
      stage: stage,
      group: groupName,
    );
    return _populateStatsAndEvents(rawMatch);
  }

  Team _buildTeam(String abbr, String displayName, String id) {
    try {
      final staticTeam = WC2026Data.teams.firstWhere(
        (t) => t.code.toUpperCase() == abbr.toUpperCase()
      );
      return Team(
        id: id.isNotEmpty ? id : abbr,
        name: staticTeam.name,
        code: abbr,
        flagCode: staticTeam.flagCode,
        group: _countryToGroup[abbr.toUpperCase()] ?? '',
        fifaRanking: staticTeam.fifaRanking,
        coach: staticTeam.coach,
      );
    } catch (_) {
      return Team(
        id: id.isNotEmpty ? id : abbr,
        name: displayName,
        code: abbr,
        flagCode: abbr.toLowerCase(),
        group: _countryToGroup[abbr.toUpperCase()] ?? '',
        fifaRanking: _fifaRank(abbr),
        coach: '',
      );
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  String _stageFromSlug(String slug) {
    const map = {
      'group-stage': 'Group Stage',
      'round-of-32': 'Round of 32',
      'round-of-16': 'Round of 16',
      'quarterfinals': 'Quarter-Final',
      'semifinals': 'Semi-Final',
      '3rd-place-match': 'Third Place',
      'final': 'Final',
    };
    return map[slug] ?? 'Group Stage';
  }

  /// Generates YYYYMMDD date params covering the 2026 World Cup
  /// (June 11 – July 19, 2026).
  List<String> _tournamentDateRanges() {
    final ranges = <String>[];
    // ESPN accepts YYYYMMDD-YYYYMMDD range
    ranges.add('20260611-20260630');
    ranges.add('20260701-20260719');
    return ranges;
  }

  /// Map FIFA/ESPN country abbreviation to emoji flag.
  String _countryToFlag(String abbr) {
    const flags = {
      'USA': '🇺🇸', 'MEX': '🇲🇽', 'CAN': '🇨🇦',
      'BRA': '🇧🇷', 'ARG': '🇦🇷', 'FRA': '🇫🇷',
      'ENG': '🏴󠁧󠁢󠁥󠁮󠁧󠁿', 'GER': '🇩🇪', 'ESP': '🇪🇸',
      'POR': '🇵🇹', 'ITA': '🇮🇹', 'NED': '🇳🇱',
      'BEL': '🇧🇪', 'CRO': '🇭🇷', 'URU': '🇺🇾',
      'COL': '🇨🇴', 'ECU': '🇪🇨', 'SEN': '🇸🇳',
      'MAR': '🇲🇦', 'NGA': '🇳🇬', 'CMR': '🇨🇲',
      'GHA': '🇬🇭', 'TUN': '🇹🇳', 'EGY': '🇪🇬',
      'RSA': '🇿🇦', 'KOR': '🇰🇷', 'JPN': '🇯🇵',
      'AUS': '🇦🇺', 'IRN': '🇮🇷', 'SAU': '🇸🇦',
      'QAT': '🇶🇦', 'UAE': '🇦🇪', 'IRQ': '🇮🇶',
      'SUI': '🇨🇭', 'POL': '🇵🇱', 'DEN': '🇩🇰',
      'SWE': '🇸🇪', 'NOR': '🇳🇴', 'AUT': '🇦🇹',
      'SCO': '🏴󠁧󠁢󠁳󠁣󠁴󠁿', 'WAL': '🏴󠁧󠁢󠁷󠁬󠁳󠁿', 'SVK': '🇸🇰',
      'CZE': '🇨🇿', 'HUN': '🇭🇺', 'ROU': '🇷🇴',
      'SRB': '🇷🇸', 'ALB': '🇦🇱', 'UKR': '🇺🇦',
      'TUR': '🇹🇷', 'GRE': '🇬🇷', 'VEN': '🇻🇪',
      'CHI': '🇨🇱', 'PAR': '🇵🇾', 'BOL': '🇧🇴',
      'PAN': '🇵🇦', 'CRC': '🇨🇷', 'HON': '🇭🇳',
      'JAM': '🇯🇲', 'PER': '🇵🇪', 'NZL': '🇳🇿',
      'IDN': '🇮🇩', 'IND': '🇮🇳', 'THA': '🇹🇭',
      'CHN': '🇨🇳', 'MLI': '🇲🇱', 'CIV': '🇨🇮',
      'GAB': '🇬🇦', 'CPV': '🇨🇻', 'GNB': '🇬🇼',
    };
    return flags[abbr] ?? '🏳️';
  }

  static const Map<String, String> _countryToGroup = {
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

  String _normalizeAbbr(String abbr) {
    final map = {
      'KSA': 'SAU',
      'HON': 'HND',
    };
    return map[abbr.toUpperCase()] ?? abbr.toUpperCase();
  }

  /// Returns the real FIFA ranking for a team code, or 50 as default.
  int _fifaRank(String code) {
    try {
      return WC2026Data.teams
          .firstWhere((t) => t.code.toUpperCase() == code.toUpperCase())
          .fifaRanking;
    } catch (_) {
      return 50;
    }
  }

  // ── Stats & Events Generation ───────────────────────────────────────────

  /// Populates a match with realistic stats and events if missing.
  Match _populateStatsAndEvents(Match match) {
    if (match.status == MatchStatus.scheduled) return match;
    // If already has non-trivial stats, keep them
    if (match.stats.homeTotalShots > 0 || match.events.isNotEmpty) return match;
    final sd = _generateStatsAndEvents(
      match.id, match.homeTeam, match.awayTeam,
      match.homeScore, match.awayScore, match.status, match.minute,
    );
    return match.copyWith(stats: sd.$1, events: sd.$2);
  }

  /// Generates deterministic, realistic MatchStats and MatchEvent list.
  (MatchStats, List<MatchEvent>) _generateStatsAndEvents(
    String matchId, Team homeTeam, Team awayTeam,
    int homeScore, int awayScore, MatchStatus status, int? currentMinute,
  ) {
    // Use matchId hashcode as deterministic seed
    int seed = matchId.hashCode.abs();
    int s(int mod) { seed = (seed * 1664525 + 1013904223) & 0x7fffffff; return seed % mod; }

    // Possession: biased by score difference
    int homePoss = 45 + s(11); // 45–55
    if (homeScore > awayScore) homePoss = 50 + s(10); // 50–59
    if (awayScore > homeScore) homePoss = 40 + s(11); // 40–50
    if (homePoss > 65) homePoss = 65;
    if (homePoss < 35) homePoss = 35;
    final awayPoss = 100 - homePoss;

    // Shots — must be >= goals scored
    final homeShotsOnTarget = (homeScore + 1 + s(5)).clamp(1, 12);
    final awayShotsOnTarget = (awayScore + 1 + s(5)).clamp(1, 12);
    final homeTotalShots = (homeShotsOnTarget + 1 + s(7)).clamp(homeShotsOnTarget, 22);
    final awayTotalShots = (awayShotsOnTarget + 1 + s(7)).clamp(awayShotsOnTarget, 22);

    final homeCorners = 2 + s(8);
    final awayCorners = 2 + s(8);
    final homeFouls = 7 + s(9);
    final awayFouls = 7 + s(9);
    final homeYellow = s(3);
    final awayYellow = s(3);
    final homeRed = (homeYellow >= 2 && s(10) == 0) ? 1 : 0;
    final awayRed = (awayYellow >= 2 && s(10) == 0) ? 1 : 0;
    final homeOffsides = s(5);
    final awayOffsides = s(5);

    final stats = MatchStats(
      homePossession: homePoss,
      awayPossession: awayPoss,
      homeShotsOnGoal: homeShotsOnTarget,
      awayShotsOnGoal: awayShotsOnTarget,
      homeTotalShots: homeTotalShots,
      awayTotalShots: awayTotalShots,
      homeCorners: homeCorners,
      awayCorners: awayCorners,
      homeFouls: homeFouls,
      awayFouls: awayFouls,
      homeYellowCards: homeYellow,
      awayYellowCards: awayYellow,
      homeRedCards: homeRed,
      awayRedCards: awayRed,
      homeOffsides: homeOffsides,
      awayOffsides: awayOffsides,
    );

    // ── Events ─────────────────────────────────────────────────────────────
    final List<MatchEvent> events = [];

    // Get player names from static data
    List<String> squadNames(String code) {
      try {
        final team = WC2026Data.teams.firstWhere(
          (t) => t.code.toUpperCase() == code.toUpperCase(),
        );
        final players = team.squad
            .where((p) => p.position != 'GK')
            .map((p) => p.name)
            .toList();
        return players.isNotEmpty ? players : ['${team.name} Player'];
      } catch (_) {
        return ['$code Player'];
      }
    }

    final homePlayers = squadNames(homeTeam.code);
    final awayPlayers = squadNames(awayTeam.code);

    // Generate used minutes to avoid duplicates
    final usedMinutes = <int>{};
    int uniqueMin(int base, int range) {
      int m = base + s(range);
      int tries = 0;
      while (usedMinutes.contains(m) && tries < 20) { m = (m + 1) % 90 + 1; tries++; }
      usedMinutes.add(m);
      return m;
    }

    // Goal events for home team
    for (int i = 0; i < homeScore; i++) {
      final minute = uniqueMin(5 + i * 15, 20).clamp(1, 90);
      final scorer = homePlayers[s(homePlayers.length)];
      final assisterIdx = s(homePlayers.length);
      final assister = homePlayers[assisterIdx];
      events.add(MatchEvent(
        minute: minute,
        teamId: homeTeam.code,
        playerName: scorer,
        type: MatchEventType.goal,
        detail: scorer == assister ? 'Goal' : 'Assist: $assister',
      ));
    }

    // Goal events for away team
    for (int i = 0; i < awayScore; i++) {
      final minute = uniqueMin(10 + i * 15, 20).clamp(1, 90);
      final scorer = awayPlayers[s(awayPlayers.length)];
      final assisterIdx = s(awayPlayers.length);
      final assister = awayPlayers[assisterIdx];
      events.add(MatchEvent(
        minute: minute,
        teamId: awayTeam.code,
        playerName: scorer,
        type: MatchEventType.goal,
        detail: scorer == assister ? 'Goal' : 'Assist: $assister',
      ));
    }

    // Card events
    for (int i = 0; i < homeYellow; i++) {
      final minute = uniqueMin(20 + i * 12, 15).clamp(1, 90);
      final player = homePlayers[s(homePlayers.length)];
      events.add(MatchEvent(
        minute: minute,
        teamId: homeTeam.code,
        playerName: player,
        type: MatchEventType.card,
        detail: 'Yellow Card',
      ));
    }
    for (int i = 0; i < awayYellow; i++) {
      final minute = uniqueMin(25 + i * 12, 15).clamp(1, 90);
      final player = awayPlayers[s(awayPlayers.length)];
      events.add(MatchEvent(
        minute: minute,
        teamId: awayTeam.code,
        playerName: player,
        type: MatchEventType.card,
        detail: 'Yellow Card',
      ));
    }

    // Substitutions (only in second half for finished, or after 55' for live)
    final isLate = status == MatchStatus.finished ||
        (status == MatchStatus.live && (currentMinute ?? 0) > 55);
    if (isLate) {
      for (int i = 0; i < 2; i++) {
        final minute = uniqueMin(55 + i * 10, 15).clamp(56, 90);
        final playerOff = homePlayers[s(homePlayers.length)];
        events.add(MatchEvent(
          minute: minute,
          teamId: homeTeam.code,
          playerName: playerOff,
          type: MatchEventType.substitution,
          detail: 'Substitution',
        ));
      }
      for (int i = 0; i < 2; i++) {
        final minute = uniqueMin(58 + i * 10, 15).clamp(56, 90);
        final playerOff = awayPlayers[s(awayPlayers.length)];
        events.add(MatchEvent(
          minute: minute,
          teamId: awayTeam.code,
          playerName: playerOff,
          type: MatchEventType.substitution,
          detail: 'Substitution',
        ));
      }
    }

    events.sort((a, b) => a.minute.compareTo(b.minute));
    return (stats, events);
  }

  List<Match> _injectMockFinishedResults(List<Match> matches) {
    // Sort matches by kickoff time so we modify the earliest ones
    matches.sort((a, b) => a.kickoffTime.compareTo(b.kickoffTime));

    final groups = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L'];
    
    // Helper to create Team objects
    Team createTeam(String code, String name, String flagCode, String group) {
      return Team(
        id: code,
        name: name,
        code: code,
        flagCode: flagCode,
        group: group,
        fifaRanking: _fifaRank(code),
        coach: '',
      );
    }

    final Map<String, List<Team>> groupTeams = {
      'A': [
        createTeam('MEX', 'Mexico', 'mx', 'A'),
        createTeam('RSA', 'South Africa', 'za', 'A'),
        createTeam('KOR', 'South Korea', 'kr', 'A'),
        createTeam('CZE', 'Czechia', 'cz', 'A'),
      ],
      'B': [
        createTeam('CAN', 'Canada', 'ca', 'B'),
        createTeam('BIH', 'Bosnia and Herzegovina', 'ba', 'B'),
        createTeam('QAT', 'Qatar', 'qa', 'B'),
        createTeam('SUI', 'Switzerland', 'ch', 'B'),
      ],
      'C': [
        createTeam('BRA', 'Brazil', 'br', 'C'),
        createTeam('MAR', 'Morocco', 'ma', 'C'),
        createTeam('HAI', 'Haiti', 'ht', 'C'),
        createTeam('SCO', 'Scotland', 'gb-sct', 'C'),
      ],
      'D': [
        createTeam('USA', 'USA', 'us', 'D'),
        createTeam('PAR', 'Paraguay', 'py', 'D'),
        createTeam('AUS', 'Australia', 'au', 'D'),
        createTeam('TUR', 'Türkiye', 'tr', 'D'),
      ],
      'E': [
        createTeam('GER', 'Germany', 'de', 'E'),
        createTeam('CUW', 'Curaçao', 'cw', 'E'),
        createTeam('CIV', 'Ivory Coast', 'ci', 'E'),
        createTeam('ECU', 'Ecuador', 'ec', 'E'),
      ],
      'F': [
        createTeam('NED', 'Netherlands', 'nl', 'F'),
        createTeam('JPN', 'Japan', 'jp', 'F'),
        createTeam('SWE', 'Sweden', 'se', 'F'),
        createTeam('TUN', 'Tunisia', 'tn', 'F'),
      ],
      'G': [
        createTeam('BEL', 'Belgium', 'be', 'G'),
        createTeam('EGY', 'Egypt', 'eg', 'G'),
        createTeam('IRN', 'Iran', 'ir', 'G'),
        createTeam('NZL', 'New Zealand', 'nz', 'G'),
      ],
      'H': [
        createTeam('ESP', 'Spain', 'es', 'H'),
        createTeam('CPV', 'Cabo Verde', 'cv', 'H'),
        createTeam('SAU', 'Saudi Arabia', 'sa', 'H'),
        createTeam('URU', 'Uruguay', 'uy', 'H'),
      ],
      'I': [
        createTeam('FRA', 'France', 'fr', 'I'),
        createTeam('SEN', 'Senegal', 'sn', 'I'),
        createTeam('IRQ', 'Iraq', 'iq', 'I'),
        createTeam('NOR', 'Norway', 'no', 'I'),
      ],
      'J': [
        createTeam('ARG', 'Argentina', 'ar', 'J'),
        createTeam('ALG', 'Algeria', 'dz', 'J'),
        createTeam('AUT', 'Austria', 'at', 'J'),
        createTeam('JOR', 'Jordan', 'jo', 'J'),
      ],
      'K': [
        createTeam('POR', 'Portugal', 'pt', 'K'),
        createTeam('COD', 'DR Congo', 'cd', 'K'),
        createTeam('UZB', 'Uzbekistan', 'uz', 'K'),
        createTeam('COL', 'Colombia', 'co', 'K'),
      ],
      'L': [
        createTeam('ENG', 'England', 'gb-eng', 'L'),
        createTeam('CRO', 'Croatia', 'hr', 'L'),
        createTeam('GHA', 'Ghana', 'gh', 'L'),
        createTeam('PAN', 'Panama', 'pa', 'L'),
      ],
    };

    for (int i = 0; i < matches.length; i++) {
      final m = matches[i];
      if (i < 72) {
        final groupIndex = i ~/ 6;
        final matchInGroupIndex = i % 6;
        final groupName = groups[groupIndex];
        final teams = groupTeams[groupName]!;

        Team home;
        Team away;

        switch (matchInGroupIndex) {
          case 0:
            home = teams[0];
            away = teams[1];
            break;
          case 1:
            home = teams[2];
            away = teams[3];
            break;
          case 2:
            home = teams[0];
            away = teams[2];
            break;
          case 3:
            home = teams[1];
            away = teams[3];
            break;
          case 4:
            home = teams[3];
            away = teams[0];
            break;
          case 5:
          default:
            home = teams[1];
            away = teams[2];
            break;
        }

        final MatchStatus status = m.status;

        int hs = m.homeScore;
        int as = m.awayScore;
        int? minute = m.minute;

        final rebuilt = Match(
          id: m.id,
          homeTeam: home,
          awayTeam: away,
          homeScore: hs,
          awayScore: as,
          status: status,
          kickoffTime: m.kickoffTime,
          venue: m.venue,
          city: m.city,
          stage: m.stage,
          minute: minute,
          group: groupName,
          stats: m.stats,
          events: m.events,
        );
        matches[i] = _populateStatsAndEvents(rebuilt);
      } else {
        // Knockout matches: just clear group so they don't count towards standings
        matches[i] = Match(
          id: m.id,
          homeTeam: m.homeTeam,
          awayTeam: m.awayTeam,
          homeScore: m.homeScore,
          awayScore: m.awayScore,
          status: m.status,
          kickoffTime: m.kickoffTime,
          venue: m.venue,
          city: m.city,
          stage: m.stage,
          minute: m.minute,
          group: null,
          stats: m.stats,
          events: m.events,
        );
      }
    }
    return matches;
  }

  List<Match> _generateLocalMockFixtures() {
    final List<Match> list = [];
    final startDate = DateTime(2026, 6, 11, 18, 0);
    
    // Helper to create simple empty Team
    Team dummyTeam() => const Team(
          id: '',
          name: 'TBD',
          code: 'TBD',
          flagCode: '',
          group: '',
          fifaRanking: 0,
          coach: '',
        );

    // 72 group stage matches
    for (int i = 0; i < 72; i++) {
      list.add(Match(
        id: 'mock_group_$i',
        homeTeam: dummyTeam(),
        awayTeam: dummyTeam(),
        homeScore: 0,
        awayScore: 0,
        status: MatchStatus.scheduled,
        kickoffTime: startDate.add(Duration(hours: i * 4)),
        venue: 'Stadium $i',
        city: 'City $i',
        stage: 'Group Stage',
      ));
    }

    // 32 knockout matches (Round of 32, 16, Quarter-Final, Semi-Final, Third Place, Final)
    // Round of 32: 16 matches
    for (int i = 0; i < 16; i++) {
      list.add(Match(
        id: 'mock_r32_$i',
        homeTeam: dummyTeam(),
        awayTeam: dummyTeam(),
        homeScore: 0,
        awayScore: 0,
        status: MatchStatus.scheduled,
        kickoffTime: startDate.add(Duration(days: 16, hours: i * 6)),
        venue: 'Stadium R32_$i',
        city: 'City R32_$i',
        stage: 'Round of 32',
      ));
    }
    // Round of 16: 8 matches
    for (int i = 0; i < 8; i++) {
      list.add(Match(
        id: 'mock_r16_$i',
        homeTeam: dummyTeam(),
        awayTeam: dummyTeam(),
        homeScore: 0,
        awayScore: 0,
        status: MatchStatus.scheduled,
        kickoffTime: startDate.add(Duration(days: 20, hours: i * 8)),
        venue: 'Stadium R16_$i',
        city: 'City R16_$i',
        stage: 'Round of 16',
      ));
    }
    // Quarter-Finals: 4 matches
    for (int i = 0; i < 4; i++) {
      list.add(Match(
        id: 'mock_qf_$i',
        homeTeam: dummyTeam(),
        awayTeam: dummyTeam(),
        homeScore: 0,
        awayScore: 0,
        status: MatchStatus.scheduled,
        kickoffTime: startDate.add(Duration(days: 24, hours: i * 12)),
        venue: 'Stadium QF_$i',
        city: 'City QF_$i',
        stage: 'Quarter-Final',
      ));
    }
    // Semi-Finals: 2 matches
    for (int i = 0; i < 2; i++) {
      list.add(Match(
        id: 'mock_sf_$i',
        homeTeam: dummyTeam(),
        awayTeam: dummyTeam(),
        homeScore: 0,
        awayScore: 0,
        status: MatchStatus.scheduled,
        kickoffTime: startDate.add(Duration(days: 28, hours: i * 24)),
        venue: 'Stadium SF_$i',
        city: 'City SF_$i',
        stage: 'Semi-Final',
      ));
    }
    // Third Place: 1 match
    list.add(Match(
      id: 'mock_3rd',
      homeTeam: dummyTeam(),
      awayTeam: dummyTeam(),
      homeScore: 0,
      awayScore: 0,
      status: MatchStatus.scheduled,
      kickoffTime: startDate.add(const Duration(days: 31, hours: 18)),
      venue: 'Stadium 3rd',
      city: 'City 3rd',
      stage: 'Third Place',
    ));
    // Final: 1 match
    list.add(Match(
      id: 'mock_final',
      homeTeam: dummyTeam(),
      awayTeam: dummyTeam(),
      homeScore: 0,
      awayScore: 0,
      status: MatchStatus.scheduled,
      kickoffTime: startDate.add(const Duration(days: 32, hours: 18)),
      venue: 'MetLife Stadium',
      city: 'East Rutherford',
      stage: 'Final',
    ));

    return _injectMockFinishedResults(list);
  }
}
