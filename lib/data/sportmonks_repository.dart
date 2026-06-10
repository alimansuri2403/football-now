import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import '../models/match.dart';
import '../models/team.dart';
import '../models/player.dart';
import 'repository.dart';

class SportmonksRepository implements DataRepository {
  final String apiToken;
  final String baseUrl = 'https://api.sportmonks.com/v3/football';
  final http.Client client;

  SportmonksRepository({
    required this.apiToken,
    http.Client? httpClient,
  }) : client = httpClient ?? http.Client();

  // Helper to append auth query parameter
  Uri _buildUri(String path, {Map<String, String>? queryParameters}) {
    final params = Map<String, String>.from(queryParameters ?? {});
    params['api_token'] = apiToken;
    return Uri.parse('$baseUrl$path').replace(queryParameters: params);
  }

  @override
  Future<List<Team>> getTeams() async {
    // World Cup 2026 Season ID is placeholder here. Typically you'd query by season/league.
    final uri = _buildUri('/teams', queryParameters: {
      'include': 'country',
    });

    try {
      final response = await client.get(uri);
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        final List<dynamic> data = body['data'] ?? [];
        return data.map((item) {
          final countryCode = item['country']?['extra']?['iso2'] ?? 'US';
          return Team(
            id: item['id'].toString(),
            name: item['name'] ?? 'Unknown Team',
            code: item['short_code'] ?? item['name'].toString().substring(0, 3).toUpperCase(),
            flagCode: countryCode.toString().toLowerCase(),
            group: 'Group Stage', // Groups can be parsed from standings endpoints
            fifaRanking: 50, // Fallback rank
            coach: 'Unknown Coach',
          );
        }).toList();
      }
    } catch (_) {
      // Fallback or retry logic
    }
    return [];
  }

  @override
  Future<Team?> getTeamById(String id) async {
    final uri = _buildUri('/teams/$id', queryParameters: {
      'include': 'country',
    });

    try {
      final response = await client.get(uri);
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        final item = body['data'];
        if (item != null) {
          final countryCode = item['country']?['extra']?['iso2'] ?? 'US';
          return Team(
            id: item['id'].toString(),
            name: item['name'] ?? 'Unknown Team',
            code: item['short_code'] ?? item['name'].toString().substring(0, 3).toUpperCase(),
            flagCode: countryCode.toString().toLowerCase(),
            group: 'Group Stage',
            fifaRanking: 50,
            coach: 'Unknown Coach',
          );
        }
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<List<Player>> getPlayers() async {
    final uri = _buildUri('/players');
    try {
      final response = await client.get(uri);
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        final List<dynamic> data = body['data'] ?? [];
        return data.map((item) => _parsePlayer(item)).toList();
      }
    } catch (_) {}
    return [];
  }

  @override
  Future<Player?> getPlayerById(String id) async {
    final uri = _buildUri('/players/$id', queryParameters: {
      'include': 'teams,statistics',
    });
    try {
      final response = await client.get(uri);
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        final item = body['data'];
        if (item != null) {
          return _parsePlayer(item);
        }
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<List<Player>> getPlayersByTeam(String teamId) async {
    final uri = _buildUri('/teams/$teamId', queryParameters: {
      'include': 'squad.player',
    });
    try {
      final response = await client.get(uri);
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        final List<dynamic> squad = body['data']?['squad'] ?? [];
        return squad
            .where((s) => s['player'] != null)
            .map((s) => _parsePlayer(s['player']))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  Player _parsePlayer(Map<String, dynamic> item) {
    return Player(
      id: item['id'].toString(),
      name: item['display_name'] ?? item['common_name'] ?? 'Unknown Player',
      teamId: '',
      teamName: 'National Team',
      position: item['position']?['name'] ?? 'Forward',
      number: 10,
      age: item['date_of_birth'] != null
          ? DateTime.now().year - DateTime.parse(item['date_of_birth']).year
          : 25,
      photoUrl: item['image_path'] ?? '',
      rating: 80, // Default rating fallback for API parsed players
      pastRecords: const [], // Default empty records fallback
      stats: const PlayerStats.empty(),
    );
  }

  @override
  Future<List<Match>> getUpcomingMatches() async {
    final uri = _buildUri('/fixtures', queryParameters: {
      'include': 'participants',
      'filters': 'upcoming',
    });
    return _fetchFixtures(uri);
  }

  @override
  Future<List<Match>> getFinishedMatches() async {
    final uri = _buildUri('/fixtures', queryParameters: {
      'include': 'participants',
      'filters': 'past',
    });
    return _fetchFixtures(uri);
  }

  @override
  Future<Match?> getMatchById(String id) async {
    final uri = _buildUri('/fixtures/$id', queryParameters: {
      'include': 'participants,scores,events,statistics',
    });
    try {
      final response = await client.get(uri);
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        final item = body['data'];
        if (item != null) {
          return _parseFixture(item);
        }
      }
    } catch (_) {}
    return null;
  }

  @override
  Stream<List<Match>> getLiveMatchesStream() {
    // Sportmonks live scores can be fetched periodically (polling)
    // to update the Stream.
    final controller = StreamController<List<Match>>();
    
    Future<void> tick() async {
      final uri = _buildUri('/livescores', queryParameters: {
        'include': 'participants,scores',
      });
      try {
        final matches = await _fetchFixtures(uri);
        if (!controller.isClosed) {
          controller.add(matches);
        }
      } catch (e) {
        if (!controller.isClosed) {
          controller.addError(e);
        }
      }
    }

    // Immediate fetch
    tick();

    // Stream polling every 30 seconds
    final timer = Timer.periodic(const Duration(seconds: 30), (_) => tick());
    
    controller.onCancel = () {
      timer.cancel();
      controller.close();
    };

    return controller.stream;
  }

  @override
  Future<List<GroupStanding>> getGroupStandings(String groupName) async {
    // Group standings calculations
    return [];
  }

  Future<List<Match>> _fetchFixtures(Uri uri) async {
    try {
      final response = await client.get(uri);
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        final List<dynamic> data = body['data'] ?? [];
        return data.map((item) => _parseFixture(item)).toList();
      }
    } catch (_) {}
    return [];
  }

  Match _parseFixture(Map<String, dynamic> item) {
    final List<dynamic> participants = item['participants'] ?? [];
    
    // Parse Home/Away teams
    final homeData = participants.firstWhere((p) => p['meta']?['location'] == 'home', orElse: () => {});
    final awayData = participants.firstWhere((p) => p['meta']?['location'] == 'away', orElse: () => {});

    final homeTeam = Team(
      id: homeData['id']?.toString() ?? 'home',
      name: homeData['name'] ?? 'Home Team',
      code: homeData['short_code'] ?? 'HOM',
      flagCode: 'us',
      group: 'A',
      fifaRanking: 50,
      coach: 'Coach',
    );

    final awayTeam = Team(
      id: awayData['id']?.toString() ?? 'away',
      name: awayData['name'] ?? 'Away Team',
      code: awayData['short_code'] ?? 'AWY',
      flagCode: 'mx',
      group: 'A',
      fifaRanking: 50,
      coach: 'Coach',
    );

    final scores = item['scores'] ?? [];
    final homeScore = scores.firstWhere((s) => s['description'] == 'CURRENT' && s['score']?['participant_id'] == homeData['id'], orElse: () => {})['score']?['goals'] ?? 0;
    final awayScore = scores.firstWhere((s) => s['description'] == 'CURRENT' && s['score']?['participant_id'] == awayData['id'], orElse: () => {})['score']?['goals'] ?? 0;

    final state = item['state']?['state'] ?? 'NS'; // NS = Not Started, LIVE = Live, FT = Finished
    MatchStatus status = MatchStatus.scheduled;
    if (state == 'LIVE') {
      status = MatchStatus.live;
    } else if (state == 'FT') {
      status = MatchStatus.finished;
    }

    return Match(
      id: item['id'].toString(),
      homeTeam: homeTeam,
      awayTeam: awayTeam,
      homeScore: homeScore,
      awayScore: awayScore,
      status: status,
      kickoffTime: DateTime.tryParse(item['starting_at'] ?? '') ?? DateTime.now(),
      venue: item['venue']?['name'] ?? 'Unknown Stadium',
      group: 'Group Stage',
      minute: item['minute'] ?? 0,
      stats: const MatchStats.empty(),
      events: const [],
    );
  }
}
