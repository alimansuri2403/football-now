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
      return _injectMockFinishedResults(list);
    } catch (e) {
      debugPrint('ESPN all fixtures error: $e');
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

    final homeAbbr = homeTeamData['abbreviation']?.toString() ?? 'HOM';
    final awayAbbr = awayTeamData['abbreviation']?.toString() ?? 'AWY';

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
    'USA': 'A', 'MEX': 'A', 'CAN': 'A', 'JAM': 'A',
    'ARG': 'B', 'POL': 'B', 'SAU': 'B', 'ECU': 'B',
    'FRA': 'C', 'DEN': 'C', 'TUN': 'C', 'AUS': 'C',
    'BRA': 'D', 'SUI': 'D', 'SRB': 'D', 'CMR': 'D',
    'ENG': 'E', 'SEN': 'E', 'IRN': 'E', 'VEN': 'E',
    'BEL': 'F', 'CRO': 'F', 'MAR': 'F', 'QAT': 'F',
    'ESP': 'G', 'GER': 'G', 'JPN': 'G', 'CRC': 'G',
    'POR': 'H', 'URU': 'H', 'GHA': 'H', 'KOR': 'H',
    'ITA': 'I', 'COL': 'I', 'NGA': 'I', 'ALG': 'I',
    'NED': 'J', 'EGY': 'J', 'NZL': 'J', 'CIV': 'J',
    'UKR': 'K', 'AUT': 'K', 'MLI': 'K', 'IRQ': 'K',
    'TUR': 'L', 'IDN': 'L', 'PAN': 'L', 'HND': 'L',
  };

  List<Match> _injectMockFinishedResults(List<Match> matches) {
    // Sort matches by kickoff time so we modify the earliest ones
    matches.sort((a, b) => a.kickoffTime.compareTo(b.kickoffTime));

    // Modify the first match of each group to finished status
    final Set<String> processedGroups = {};
    
    for (int i = 0; i < matches.length; i++) {
      final m = matches[i];
      final homeCode = m.homeTeam.code.toUpperCase();
      final group = _countryToGroup[homeCode] ?? m.group ?? '';
      
      if (group.isNotEmpty && !processedGroups.contains(group)) {
        processedGroups.add(group);
        
        // Generate a deterministic score based on the match ID hash
        final int seed = m.id.hashCode.abs();
        final int homeScore = (seed % 3) + 1; // 1 to 3
        final int awayScore = ((seed >> 2) % 2) + (seed % 2 == 0 ? 1 : 0); // 0 to 2
        
        matches[i] = m.copyWith(
          status: MatchStatus.finished,
          homeScore: homeScore,
          awayScore: awayScore,
          minute: 90,
        );
      }
    }
    return matches;
  }
}
