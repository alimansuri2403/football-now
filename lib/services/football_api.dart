import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/match.dart';
import '../models/team.dart';

/// Legacy API-Football service — only used if apiKey is configured.
/// The app now uses EspnApiService for all real-time data by default.
class FootballApiService {
  final String _baseUrl = 'https://v3.football.api-sports.io';
  final String apiKey = ''; // Leave empty — app uses ESPN free API instead

  final http.Client client;

  FootballApiService({http.Client? httpClient})
      : client = httpClient ?? http.Client();

  Map<String, String> _headers() => {
        'x-apisports-key': apiKey,
        'Content-Type': 'application/json',
      };

  bool get isConfigured =>
      apiKey.isNotEmpty && apiKey != 'YOUR_API_KEY';

  Future<List<Match>> fetchFixtures() async {
    if (!isConfigured) return [];
    final url = Uri.parse('$_baseUrl/fixtures?league=1&season=2026');
    try {
      final response =
          await client.get(url, headers: _headers()).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final list = (body['response'] as List<dynamic>?) ?? [];
        return list.map((item) => _parseFixture(item as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<List<Match>> fetchLiveMatches() async {
    if (!isConfigured) return [];
    final url = Uri.parse('$_baseUrl/fixtures?league=1&season=2026&live=all');
    try {
      final response =
          await client.get(url, headers: _headers()).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final list = (body['response'] as List<dynamic>?) ?? [];
        return list.map((item) => _parseFixture(item as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<Match?> fetchMatchDetails(String fixtureId) async {
    if (!isConfigured) return null;
    final url = Uri.parse('$_baseUrl/fixtures?id=$fixtureId');
    try {
      final response =
          await client.get(url, headers: _headers()).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final list = (body['response'] as List<dynamic>?) ?? [];
        if (list.isNotEmpty) {
          return _parseFixture(list.first as Map<String, dynamic>);
        }
      }
    } catch (_) {}
    return null;
  }

  Match _parseFixture(Map<String, dynamic> item) {
    final fixture = item['fixture'] as Map<String, dynamic>? ?? {};
    final teams = item['teams'] as Map<String, dynamic>? ?? {};
    final goals = item['goals'] as Map<String, dynamic>? ?? {};

    final homeTeamData = teams['home'] as Map<String, dynamic>? ?? {};
    final awayTeamData = teams['away'] as Map<String, dynamic>? ?? {};

    final homeTeam = Team(
      id: homeTeamData['id']?.toString() ?? '0',
      name: homeTeamData['name']?.toString() ?? 'Home Team',
      code: (homeTeamData['name']?.toString() ?? 'HOM')
          .substring(0, 3)
          .toUpperCase(),
      flagCode: 'us',
      group: 'A',
      fifaRanking: 50,
      coach: '',
    );

    final awayTeam = Team(
      id: awayTeamData['id']?.toString() ?? '1',
      name: awayTeamData['name']?.toString() ?? 'Away Team',
      code: (awayTeamData['name']?.toString() ?? 'AWY')
          .substring(0, 3)
          .toUpperCase(),
      flagCode: 'mx',
      group: 'A',
      fifaRanking: 50,
      coach: '',
    );

    final state = fixture['status']?['short']?.toString() ?? 'NS';
    MatchStatus status = MatchStatus.scheduled;
    if (state == 'FT' || state == 'AET' || state == 'PEN') {
      status = MatchStatus.finished;
    } else if (state != 'NS' && state != 'TBD') {
      status = MatchStatus.live;
    }

    return Match(
      id: fixture['id']?.toString() ?? '0',
      homeTeam: homeTeam,
      awayTeam: awayTeam,
      homeScore: (goals['home'] as num?)?.toInt() ?? 0,
      awayScore: (goals['away'] as num?)?.toInt() ?? 0,
      status: status,
      kickoffTime: DateTime.tryParse(fixture['date']?.toString() ?? '') ?? DateTime.now(),
      venue: fixture['venue']?['name']?.toString() ?? '',
      group: 'Group Stage',
      minute: (fixture['status']?['elapsed'] as num?)?.toInt(),
    );
  }
}
