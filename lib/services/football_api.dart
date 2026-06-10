import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/match.dart';
import '../models/team.dart';
import '../models/player.dart';
import '../data/mock_data.dart';
import '../data/repository.dart';

class FootballApiService {
  // RapidAPI or API-Sports direct host.
  // By default, we use the API-Sports direct endpoint:
  final String _baseUrl = 'https://v3.football.api-sports.io';
  
  // USER INPUT: The user can input their API-Football / API-Sports key here.
  // If empty, the app will gracefully run using the real-time Mock Simulator data
  // so the application can be explored immediately without auth setup.
  final String apiKey = ''; 

  final http.Client client;

  FootballApiService({http.Client? httpClient}) : client = httpClient ?? http.Client();

  Map<String, String> _headers() {
    return {
      'x-apisports-key': apiKey,
      'Content-Type': 'application/json',
    };
  }

  bool get isConfigured => apiKey.isNotEmpty && apiKey != 'YOUR_API_KEY';

  // Fetch all matches/fixtures for World Cup 2026 (League ID = 1)
  Future<List<Match>> fetchFixtures() async {
    if (!isConfigured) {
      // Graceful fallback to simulator matches
      return MockData.getMatches();
    }

    final url = Uri.parse('$_baseUrl/fixtures?league=1&season=2026');
    try {
      final response = await client.get(url, headers: _headers());
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        final List<dynamic> list = body['response'] ?? [];
        return list.map((item) => _parseFixture(item)).toList();
      }
    } catch (_) {}
    return MockData.getMatches();
  }

  // Fetch only live matches for World Cup 2026
  Future<List<Match>> fetchLiveMatches() async {
    if (!isConfigured) {
      // Graceful fallback: return simulator live matches
      return MockData.getMatches().where((m) => m.status == MatchStatus.live).toList();
    }

    final url = Uri.parse('$_baseUrl/fixtures?league=1&season=2026&live=all');
    try {
      final response = await client.get(url, headers: _headers());
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        final List<dynamic> list = body['response'] ?? [];
        return list.map((item) => _parseFixture(item)).toList();
      }
    } catch (_) {}
    return MockData.getMatches().where((m) => m.status == MatchStatus.live).toList();
  }

  // Fetch match details including stats, lineups and timeline events
  Future<Match?> fetchMatchDetails(String fixtureId) async {
    if (!isConfigured) {
      // Fallback
      try {
        return MockData.getMatches().firstWhere((m) => m.id == fixtureId);
      } catch (_) {
        return null;
      }
    }

    final url = Uri.parse('$_baseUrl/fixtures?id=$fixtureId');
    try {
      final response = await client.get(url, headers: _headers());
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        final List<dynamic> list = body['response'] ?? [];
        if (list.isNotEmpty) {
          final item = list.first;
          
          // Fetch events, stats & lineups separately if needed,
          // or let API-Football return them in the expanded includes
          final stats = await _fetchMatchStats(fixtureId);
          final events = await _fetchMatchEvents(fixtureId);
          final parsed = _parseFixture(item);
          
          return parsed.copyWith(
            stats: stats,
            events: events,
          );
        }
      }
    } catch (_) {}
    return null;
  }

  // Fetch Standings
  Future<List<GroupStanding>> fetchStandings(String groupLetter) async {
    if (!isConfigured) {
      // Fallback: calculate standings from mock data matches
      return _calculateMockStandings(groupLetter);
    }

    final url = Uri.parse('$_baseUrl/standings?league=1&season=2026');
    try {
      final response = await client.get(url, headers: _headers());
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        final List<dynamic> leagues = body['response'] ?? [];
        if (leagues.isNotEmpty) {
          final List<dynamic> standings = leagues.first['league']?['standings'] ?? [];
          for (final groupList in standings) {
            if (groupList.isNotEmpty) {
              final groupName = groupList.first['group']?.toString() ?? '';
              // Group format typically "Group A", "Group B"
              if (groupName.toLowerCase().endsWith(groupLetter.toLowerCase())) {
                final List<dynamic> items = groupList;
                return items.map((item) {
                  final teamData = item['team'];
                  final statsData = item['all'];
                  final team = Team(
                    id: teamData['id'].toString(),
                    name: teamData['name'] ?? 'Unknown Team',
                    code: teamData['name'].toString().substring(0, 3).toUpperCase(),
                    flagCode: 'us', // Placeholder flag, flagcdn is used in UI
                    group: groupLetter,
                    fifaRanking: 50,
                    coach: 'Unknown Coach',
                  );

                  return GroupStanding(
                    team: team,
                    played: statsData['played'] ?? 0,
                    won: statsData['win'] ?? 0,
                    drawn: statsData['draw'] ?? 0,
                    lost: statsData['lose'] ?? 0,
                    goalsFor: statsData['goals']?['for'] ?? 0,
                    goalsAgainst: statsData['goals']?['against'] ?? 0,
                    points: item['points'] ?? 0,
                  );
                }).toList();
              }
            }
          }
        }
      }
    } catch (_) {}
    return _calculateMockStandings(groupLetter);
  }

  Future<List<MatchEvent>> _fetchMatchEvents(String fixtureId) async {
    final url = Uri.parse('$_baseUrl/fixtures/events?fixture=$fixtureId');
    try {
      final response = await client.get(url, headers: _headers());
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        final List<dynamic> list = body['response'] ?? [];
        return list.map((item) {
          MatchEventType type = MatchEventType.substitution;
          if (item['type'] == 'Goal') {
            type = MatchEventType.goal;
          } else if (item['type'] == 'Card') {
            type = MatchEventType.card;
          }
          return MatchEvent(
            minute: item['time']?['elapsed'] ?? 0,
            teamId: item['team']?['id']?.toString() ?? '',
            playerName: item['player']?['name'] ?? 'Player',
            type: type,
            detail: item['detail'] ?? '',
          );
        }).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<MatchStats> _fetchMatchStats(String fixtureId) async {
    final url = Uri.parse('$_baseUrl/fixtures/statistics?fixture=$fixtureId');
    try {
      final response = await client.get(url, headers: _headers());
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        final List<dynamic> list = body['response'] ?? [];
        
        if (list.length >= 2) {
          final homeStats = list[0]['statistics'] as List<dynamic>;
          final awayStats = list[1]['statistics'] as List<dynamic>;

          int getVal(List<dynamic> stats, String type) {
            final stat = stats.firstWhere((s) => s['type'] == type, orElse: () => {});
            final val = stat['value'];
            if (val == null) return 0;
            if (val is String) {
              return int.tryParse(val.replaceAll('%', '')) ?? 0;
            }
            return val as int;
          }

          return MatchStats(
            homePossession: getVal(homeStats, 'Ball Possession'),
            awayPossession: getVal(awayStats, 'Ball Possession'),
            homeShotsOnGoal: getVal(homeStats, 'Shots on Goal'),
            awayShotsOnGoal: getVal(awayStats, 'Shots on Goal'),
            homeTotalShots: getVal(homeStats, 'Total Shots'),
            awayTotalShots: getVal(awayStats, 'Total Shots'),
            homeCorners: getVal(homeStats, 'Corner Kicks'),
            awayCorners: getVal(awayStats, 'Corner Kicks'),
            homeFouls: getVal(homeStats, 'Fouls'),
            awayFouls: getVal(awayStats, 'Fouls'),
            homeYellowCards: getVal(homeStats, 'Yellow Cards'),
            awayYellowCards: getVal(awayStats, 'Yellow Cards'),
            homeRedCards: getVal(homeStats, 'Red Cards'),
            awayRedCards: getVal(awayStats, 'Red Cards'),
            homeOffsides: getVal(homeStats, 'Offsides'),
            awayOffsides: getVal(awayStats, 'Offsides'),
          );
        }
      }
    } catch (_) {}
    return const MatchStats.empty();
  }

  Match _parseFixture(Map<String, dynamic> item) {
    final fixture = item['fixture'];
    final teams = item['teams'];
    final goals = item['goals'];

    final homeTeam = Team(
      id: teams['home']['id'].toString(),
      name: teams['home']['name'] ?? 'Home Team',
      code: teams['home']['name'].toString().substring(0, 3).toUpperCase(),
      flagCode: 'us',
      group: 'A',
      fifaRanking: 50,
      coach: 'Unknown Coach',
    );

    final awayTeam = Team(
      id: teams['away']['id'].toString(),
      name: teams['away']['name'] ?? 'Away Team',
      code: teams['away']['name'].toString().substring(0, 3).toUpperCase(),
      flagCode: 'mx',
      group: 'A',
      fifaRanking: 50,
      coach: 'Unknown Coach',
    );

    final state = fixture['status']?['short'] ?? 'NS';
    MatchStatus status = MatchStatus.scheduled;
    if (state == 'FT' || state == 'AET' || state == 'PEN') {
      status = MatchStatus.finished;
    } else if (state != 'NS' && state != 'TBD') {
      status = MatchStatus.live;
    }

    return Match(
      id: fixture['id'].toString(),
      homeTeam: homeTeam,
      awayTeam: awayTeam,
      homeScore: goals['home'] ?? 0,
      awayScore: goals['away'] ?? 0,
      status: status,
      kickoffTime: DateTime.tryParse(fixture['date'] ?? '') ?? DateTime.now(),
      venue: fixture['venue']?['name'] ?? 'Unknown Stadium',
      group: 'Group Stage',
      minute: fixture['status']?['elapsed'],
    );
  }

  Future<List<GroupStanding>> _calculateMockStandings(String groupLetter) async {
    final repo = MockDataRepository();
    final standings = await repo.getGroupStandings(groupLetter);
    repo.dispose();
    return standings;
  }
}
