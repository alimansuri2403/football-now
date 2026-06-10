import 'dart:math';

class Team {
  final String id;
  final String name;
  final String code;
  final String flagUrl;
  final String groupName;
  
  // Standings data
  final int played;
  final int won;
  final int drawn;
  final int lost;
  final int goalsFor;
  final int goalsAgainst;
  final int points;

  const Team({
    required this.id,
    required this.name,
    required this.code,
    required this.flagUrl,
    required this.groupName,
    this.played = 0,
    this.won = 0,
    this.drawn = 0,
    this.lost = 0,
    this.goalsFor = 0,
    this.goalsAgainst = 0,
    this.points = 0,
  });

  int get goalDifference => goalsFor - goalsAgainst;

  Team copyWith({
    int? played,
    int? won,
    int? drawn,
    int? lost,
    int? goalsFor,
    int? goalsAgainst,
    int? points,
  }) {
    return Team(
      id: id,
      name: name,
      code: code,
      flagUrl: flagUrl,
      groupName: groupName,
      played: played ?? this.played,
      won: won ?? this.won,
      drawn: drawn ?? this.drawn,
      lost: lost ?? this.lost,
      goalsFor: goalsFor ?? this.goalsFor,
      goalsAgainst: goalsAgainst ?? this.goalsAgainst,
      points: points ?? this.points,
    );
  }
}

class Player {
  final String id;
  final String name;
  final String teamId;
  final String teamName;
  final String position;
  final int goals;
  final int assists;
  final int matchesPlayed;
  final double rating;
  final String imageUrl;
  
  // Attributes (Pace, Shooting, Passing, Dribbling, Defending, Physicality)
  // Used for Radar Chart
  final Map<String, double> attributes;

  const Player({
    required this.id,
    required this.name,
    required this.teamId,
    required this.teamName,
    required this.position,
    this.goals = 0,
    this.assists = 0,
    this.matchesPlayed = 0,
    this.rating = 6.0,
    required this.imageUrl,
    required this.attributes,
  });
}

enum MatchEventType { goal, card, substitution, varDecision }

class MatchEvent {
  final String id;
  final MatchEventType type;
  final int minute;
  final String player1;
  final String? player2; // Assist or Sub-in player
  final String detail; // e.g., "Yellow Card", "Goal", "Penalty", "Sub Out"
  final bool isHomeTeam;

  const MatchEvent({
    required this.id,
    required this.type,
    required this.minute,
    required this.player1,
    this.player2,
    required this.detail,
    required this.isHomeTeam,
  });
}

enum MatchStatus { upcoming, live, finished }

class Match {
  final String id;
  final Team homeTeam;
  final Team awayTeam;
  final int homeScore;
  final int awayScore;
  final MatchStatus status;
  final int minute;
  final DateTime date;
  final String stage;
  final String stadium;
  
  // Stats
  final int possessionHome;
  final int possessionAway;
  final int shotsHome;
  final int shotsAway;
  final int shotsOnTargetHome;
  final int shotsOnTargetAway;
  final int cornersHome;
  final int cornersAway;
  final int foulsHome;
  final int foulsAway;
  final int yellowCardsHome;
  final int yellowCardsAway;
  final int redCardsHome;
  final int redCardsAway;

  final List<MatchEvent> events;
  final List<Player> homeLineup;
  final List<Player> awayLineup;

  const Match({
    required this.id,
    required this.homeTeam,
    required this.awayTeam,
    this.homeScore = 0,
    this.awayScore = 0,
    this.status = MatchStatus.upcoming,
    this.minute = 0,
    required this.date,
    required this.stage,
    required this.stadium,
    this.possessionHome = 50,
    this.possessionAway = 50,
    this.shotsHome = 0,
    this.shotsAway = 0,
    this.shotsOnTargetHome = 0,
    this.shotsOnTargetAway = 0,
    this.cornersHome = 0,
    this.cornersAway = 0,
    this.foulsHome = 0,
    this.foulsAway = 0,
    this.yellowCardsHome = 0,
    this.yellowCardsAway = 0,
    this.redCardsHome = 0,
    this.redCardsAway = 0,
    this.events = const [],
    this.homeLineup = const [],
    this.awayLineup = const [],
  });

  Match copyWith({
    int? homeScore,
    int? awayScore,
    MatchStatus? status,
    int? minute,
    int? possessionHome,
    int? possessionAway,
    int? shotsHome,
    int? shotsAway,
    int? shotsOnTargetHome,
    int? shotsOnTargetAway,
    int? cornersHome,
    int? cornersAway,
    int? foulsHome,
    int? foulsAway,
    int? yellowCardsHome,
    int? yellowCardsAway,
    int? redCardsHome,
    int? redCardsAway,
    List<MatchEvent>? events,
  }) {
    return Match(
      id: id,
      homeTeam: homeTeam,
      awayTeam: awayTeam,
      homeScore: homeScore ?? this.homeScore,
      awayScore: awayScore ?? this.awayScore,
      status: status ?? this.status,
      minute: minute ?? this.minute,
      date: date,
      stage: stage,
      stadium: stadium,
      possessionHome: possessionHome ?? this.possessionHome,
      possessionAway: possessionAway ?? this.possessionAway,
      shotsHome: shotsHome ?? this.shotsHome,
      shotsAway: shotsAway ?? this.shotsAway,
      shotsOnTargetHome: shotsOnTargetHome ?? this.shotsOnTargetHome,
      shotsOnTargetAway: shotsOnTargetAway ?? this.shotsOnTargetAway,
      cornersHome: cornersHome ?? this.cornersHome,
      cornersAway: cornersAway ?? this.cornersAway,
      foulsHome: foulsHome ?? this.foulsHome,
      foulsAway: foulsAway ?? this.foulsAway,
      yellowCardsHome: yellowCardsHome ?? this.yellowCardsHome,
      yellowCardsAway: yellowCardsAway ?? this.yellowCardsAway,
      redCardsHome: redCardsHome ?? this.redCardsHome,
      redCardsAway: redCardsAway ?? this.redCardsAway,
      events: events ?? this.events,
      homeLineup: homeLineup,
      awayLineup: awayLineup,
    );
  }
}
