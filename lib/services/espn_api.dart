import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/match.dart';
import '../models/team.dart';

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
      return _injectMockFinishedResults(list);
    } catch (e) {
      debugPrint('ESPN all fixtures error: $e, using local fallback.');
      return _generateLocalMockFixtures();
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

    // Group (extract from name if available)
    final eventName = event['name']?.toString() ?? '';
    String? group;
    final groupMatch = RegExp(r'Group ([A-L])').firstMatch(eventName);
    if (groupMatch != null) group = groupMatch.group(1);

    return Match(
      id: id,
      homeTeam: Team(
        id: homeTeamData['id']?.toString() ?? homeAbbr,
        name: homeTeamName,
        code: homeAbbr,
        flagCode: homeAbbr.toLowerCase(),
        group: group ?? '',
        fifaRanking: 0,
        coach: '',
      ),
      awayTeam: Team(
        id: awayTeamData['id']?.toString() ?? awayAbbr,
        name: awayTeamName,
        code: awayAbbr,
        flagCode: awayAbbr.toLowerCase(),
        group: group ?? '',
        fifaRanking: 0,
        coach: '',
      ),
      homeScore: homeScore,
      awayScore: awayScore,
      status: status,
      kickoffTime: kickoff,
      minute: minute,
      venue: venueName,
      city: city,
      stage: stage,
      group: group,
    );
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
        fifaRanking: 0,
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

        // Make the first 2 matches of each group finished to show realistic standings
        final bool isFinished = matchInGroupIndex < 2;
        
        int homeScore = 0;
        int awayScore = 0;
        MatchStatus status = MatchStatus.scheduled;

        if (isFinished) {
          status = MatchStatus.finished;
          // Deterministic score based on match index
          final int seed = i.hashCode.abs();
          homeScore = (seed % 3) + 1; // 1 to 3
          awayScore = ((seed >> 2) % 2) + (seed % 2 == 0 ? 1 : 0); // 0 to 2
        }

        matches[i] = Match(
          id: m.id,
          homeTeam: home,
          awayTeam: away,
          homeScore: homeScore,
          awayScore: awayScore,
          status: status,
          kickoffTime: m.kickoffTime,
          venue: m.venue,
          city: m.city,
          stage: m.stage,
          minute: isFinished ? 90 : null,
          group: groupName,
          stats: m.stats,
          events: m.events,
        );
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
          name: '',
          code: '',
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
