import 'dart:async';
import '../models/match.dart';
import '../models/team.dart';
import '../models/player.dart';

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

/// Clean repository — no mock data, no simulation.
/// Teams/players come from ESPN API via match_provider.
/// Matches are loaded from EspnApiService, not stored here.
class MockDataRepository implements DataRepository {
  final StreamController<List<Match>> _controller =
      StreamController<List<Match>>.broadcast();

  MockDataRepository();

  @override
  Future<List<Team>> getTeams() async => [];

  @override
  Future<Team?> getTeamById(String id) async => null;

  @override
  Future<List<Player>> getPlayers() async => [];

  @override
  Future<Player?> getPlayerById(String id) async => null;

  @override
  Future<List<Player>> getPlayersByTeam(String teamId) async => [];

  @override
  Future<List<Match>> getUpcomingMatches() async => [];

  @override
  Future<List<Match>> getFinishedMatches() async => [];

  @override
  Future<Match?> getMatchById(String id) async => null;

  @override
  Stream<List<Match>> getLiveMatchesStream() => _controller.stream;

  @override
  Future<List<GroupStanding>> getGroupStandings(String groupName) async => [];

  @override
  void dispose() {
    _controller.close();
  }
}
