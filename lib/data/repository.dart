import 'dart:async';
import '../models/match.dart';
import '../models/team.dart';
import '../models/player.dart';
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
  final StreamController<List<Match>> _controller =
      StreamController<List<Match>>.broadcast();

  MockDataRepository({this.getMatches});

  Team _mapTeam(WC2026Team t) {
    return Team(
      id: t.code,
      name: t.name,
      code: t.code,
      flagCode: t.flagCode,
      group: t.group,
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

    return Player(
      id: id,
      name: p.name,
      teamId: t.code,
      teamName: t.name,
      position: positionLong,
      number: p.number,
      age: p.age,
      photoUrl: 'https://images.unsplash.com/photo-1508098682722-e99c43a406b2?w=150&q=80',
      rating: rating,
      pastRecords: ['Plays for ${p.club}'],
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
    try {
      final t = WC2026Data.teams.firstWhere(
        (team) => team.code.toUpperCase() == teamCode.toUpperCase(),
      );
      return t.group;
    } catch (_) {
      return '';
    }
  }

  @override
  Future<List<Team>> getTeams() async {
    return WC2026Data.teams.map(_mapTeam).toList();
  }

  @override
  Future<Team?> getTeamById(String id) async {
    try {
      final t = WC2026Data.teams.firstWhere(
        (team) => team.code.toUpperCase() == id.toUpperCase() || team.name.toUpperCase() == id.toUpperCase(),
      );
      return _mapTeam(t);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Player>> getPlayers() async {
    final List<Player> players = [];
    for (final t in WC2026Data.teams) {
      for (final p in t.squad) {
        players.add(_mapPlayer(p, t));
      }
    }
    return players;
  }

  @override
  Future<Player?> getPlayerById(String id) async {
    try {
      final all = await getPlayers();
      return all.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Player>> getPlayersByTeam(String teamId) async {
    try {
      final t = WC2026Data.teams.firstWhere(
        (team) => team.code.toUpperCase() == teamId.toUpperCase() || team.name.toUpperCase() == teamId.toUpperCase(),
      );
      return t.squad.map((p) => _mapPlayer(p, t)).toList();
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
    // 1. Get all teams in this group from WC2026Data
    final groupTeams = WC2026Data.teams
        .where((t) => t.group.toUpperCase() == groupName.toUpperCase())
        .map(_mapTeam)
        .toList();

    // 2. Initialize map of standings
    final Map<String, GroupStanding> standingsMap = {
      for (final team in groupTeams)
        team.id: GroupStanding(
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
      final homeCode = match.homeTeam.code;
      final awayCode = match.awayTeam.code;
      final homeGroup = _getTeamGroup(homeCode);
      final awayGroup = _getTeamGroup(awayCode);
      
      final bool isThisGroup = match.group?.toUpperCase() == groupName.toUpperCase() ||
          homeGroup.toUpperCase() == groupName.toUpperCase() ||
          awayGroup.toUpperCase() == groupName.toUpperCase();

      if (isThisGroup &&
          (match.status == MatchStatus.finished ||
           match.status == MatchStatus.live ||
           match.status == MatchStatus.halftime)) {
        
        final homeId = match.homeTeam.id;
        final awayId = match.awayTeam.id;

        final homeStanding = standingsMap[homeId];
        final awayStanding = standingsMap[awayId];

        if (homeStanding != null && awayStanding != null) {
          final hs = match.homeScore;
          final as = match.awayScore;

          final bool homeWon = hs > as;
          final bool awayWon = as > hs;
          final bool draw = hs == as;

          standingsMap[homeId] = GroupStanding(
            team: homeStanding.team,
            played: homeStanding.played + 1,
            won: homeStanding.won + (homeWon ? 1 : 0),
            drawn: homeStanding.drawn + (draw ? 1 : 0),
            lost: homeStanding.lost + (awayWon ? 1 : 0),
            goalsFor: homeStanding.goalsFor + hs,
            goalsAgainst: homeStanding.goalsAgainst + as,
            points: homeStanding.points + (homeWon ? 3 : (draw ? 1 : 0)),
          );

          standingsMap[awayId] = GroupStanding(
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

