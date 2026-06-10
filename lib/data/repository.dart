import 'dart:async';
import 'dart:math';
import '../models/match.dart';
import '../models/team.dart';
import '../models/player.dart';
import 'mock_data.dart';

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
}

class MockDataRepository implements DataRepository {
  final List<Team> _teams = List.from(MockData.teams);
  final List<Player> _players = List.from(MockData.players);
  late List<Match> _matches;
  
  // Stream controller for live matches
  final StreamController<List<Match>> _liveMatchesController = StreamController<List<Match>>.broadcast();
  Timer? _simulationTimer;
  final Random _random = Random();

  MockDataRepository() {
    _matches = MockData.getMatches();
    _startSimulation();
  }

  void _startSimulation() {
    _simulationTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      bool changed = false;
      _matches = _matches.map((match) {
        if (match.status == MatchStatus.live) {
          changed = true;
          // Increment match minute
          int nextMin = match.currentMinute + 1;
          if (nextMin > 90) {
            // Match finished
            return match.copyWith(
              status: MatchStatus.finished,
              minute: 90,
            );
          }

          // Random goal event (1% chance per tick)
          int homeScore = match.homeScore;
          int awayScore = match.awayScore;
          List<MatchEvent> events = List.from(match.events);
          MatchStats stats = match.stats;

          if (_random.nextDouble() < 0.05) {
            final scoreHome = _random.nextBool();
            if (scoreHome) {
              homeScore++;
              events.add(MatchEvent(
                minute: nextMin,
                teamId: match.homeTeam.id,
                playerName: _getRandomPlayerName(match.homeTeam.id),
                type: MatchEventType.goal,
                detail: 'Goal!',
              ));
            } else {
              awayScore++;
              events.add(MatchEvent(
                minute: nextMin,
                teamId: match.awayTeam.id,
                playerName: _getRandomPlayerName(match.awayTeam.id),
                type: MatchEventType.goal,
                detail: 'Goal!',
              ));
            }
          }

          // Random yellow card (3% chance)
          if (_random.nextDouble() < 0.08) {
            final cardHome = _random.nextBool();
            events.add(MatchEvent(
              minute: nextMin,
              teamId: cardHome ? match.homeTeam.id : match.awayTeam.id,
              playerName: _getRandomPlayerName(cardHome ? match.homeTeam.id : match.awayTeam.id),
              type: MatchEventType.card,
              detail: 'Yellow Card',
            ));
          }

          // Adjust stats randomly
          final newHomePos = (stats.homePossession + (_random.nextInt(3) - 1)).clamp(35, 65);
          final newAwayPos = 100 - newHomePos;

          final newStats = MatchStats(
            homePossession: newHomePos,
            awayPossession: newAwayPos,
            homeShotsOnGoal: stats.homeShotsOnGoal + (_random.nextDouble() < 0.1 ? 1 : 0),
            awayShotsOnGoal: stats.awayShotsOnGoal + (_random.nextDouble() < 0.1 ? 1 : 0),
            homeTotalShots: stats.homeTotalShots + (_random.nextDouble() < 0.2 ? 1 : 0),
            awayTotalShots: stats.awayTotalShots + (_random.nextDouble() < 0.2 ? 1 : 0),
            homeCorners: stats.homeCorners + (_random.nextDouble() < 0.1 ? 1 : 0),
            awayCorners: stats.awayCorners + (_random.nextDouble() < 0.1 ? 1 : 0),
            homeFouls: stats.homeFouls + (_random.nextDouble() < 0.15 ? 1 : 0),
            awayFouls: stats.awayFouls + (_random.nextDouble() < 0.15 ? 1 : 0),
            homeYellowCards: events.where((e) => e.teamId == match.homeTeam.id && e.detail.contains('Yellow')).length,
            awayYellowCards: events.where((e) => e.teamId == match.awayTeam.id && e.detail.contains('Yellow')).length,
            homeRedCards: stats.homeRedCards,
            awayRedCards: stats.awayRedCards,
            homeOffsides: stats.homeOffsides + (_random.nextDouble() < 0.05 ? 1 : 0),
            awayOffsides: stats.awayOffsides + (_random.nextDouble() < 0.05 ? 1 : 0),
          );

          return match.copyWith(
            minute: nextMin,
            homeScore: homeScore,
            awayScore: awayScore,
            events: events,
            stats: newStats,
          );
        }
        return match;
      }).toList();

      if (changed) {
        final liveList = _matches.where((m) => m.status == MatchStatus.live).toList();
        _liveMatchesController.add(liveList);
      }
    });
  }

  String _getRandomPlayerName(String teamId) {
    final teamPlayers = _players.where((p) => p.teamId == teamId).toList();
    if (teamPlayers.isNotEmpty) {
      return teamPlayers[_random.nextInt(teamPlayers.length)].name;
    }
    return 'Player';
  }

  @override
  Future<List<Team>> getTeams() async {
    return _teams;
  }

  @override
  Future<Team?> getTeamById(String id) async {
    try {
      return _teams.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Player>> getPlayers() async {
    return _players;
  }

  @override
  Future<Player?> getPlayerById(String id) async {
    try {
      return _players.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Player>> getPlayersByTeam(String teamId) async {
    return _players.where((p) => p.teamId == teamId).toList();
  }

  @override
  Future<List<Match>> getUpcomingMatches() async {
    return _matches.where((m) => m.status == MatchStatus.scheduled).toList();
  }

  @override
  Future<List<Match>> getFinishedMatches() async {
    return _matches.where((m) => m.status == MatchStatus.finished).toList();
  }

  @override
  Future<Match?> getMatchById(String id) async {
    try {
      return _matches.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<List<Match>> getLiveMatchesStream() {
    // Return immediate value then updates
    final live = _matches.where((m) => m.status == MatchStatus.live).toList();
    
    // Create a controller to merge immediate data and future streams
    final controller = StreamController<List<Match>>();
    controller.add(live);
    
    final subscription = _liveMatchesController.stream.listen(
      (data) => controller.add(data),
      onError: (err) => controller.addError(err),
      onDone: () => controller.close(),
    );
    
    controller.onCancel = () {
      subscription.cancel();
      controller.close();
    };
    
    return controller.stream;
  }

  @override
  Future<List<GroupStanding>> getGroupStandings(String groupName) async {
    final groupTeams = _teams.where((t) => t.group == groupName).toList();
    final standings = groupTeams.map((team) {
      // Calculate stats based on finished matches
      int played = 0;
      int won = 0;
      int drawn = 0;
      int lost = 0;
      int goalsFor = 0;
      int goalsAgainst = 0;

      for (final match in _matches.where((m) => m.status == MatchStatus.finished)) {
        if (match.homeTeam.id == team.id) {
          played++;
          goalsFor += match.homeScore;
          goalsAgainst += match.awayScore;
          if (match.homeScore > match.awayScore) {
            won++;
          } else if (match.homeScore == match.awayScore) {
            drawn++;
          } else {
            lost++;
          }
        } else if (match.awayTeam.id == team.id) {
          played++;
          goalsFor += match.awayScore;
          goalsAgainst += match.homeScore;
          if (match.awayScore > match.homeScore) {
            won++;
          } else if (match.awayScore == match.homeScore) {
            drawn++;
          } else {
            lost++;
          }
        }
      }

      int points = (won * 3) + drawn;

      return GroupStanding(
        team: team,
        played: played,
        won: won,
        drawn: drawn,
        lost: lost,
        goalsFor: goalsFor,
        goalsAgainst: goalsAgainst,
        points: points,
      );
    }).toList();

    // Sort standings by points (desc), goal difference (desc), goals for (desc)
    standings.sort((a, b) {
      if (b.points != a.points) {
        return b.points.compareTo(a.points);
      }
      final gdA = a.goalsFor - a.goalsAgainst;
      final gdB = b.goalsFor - b.goalsAgainst;
      if (gdB != gdA) {
        return gdB.compareTo(gdA);
      }
      return b.goalsFor.compareTo(a.goalsFor);
    });

    return standings;
  }
  
  void dispose() {
    _simulationTimer?.cancel();
    _liveMatchesController.close();
  }
}
