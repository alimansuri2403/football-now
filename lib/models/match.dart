import 'team.dart';

enum MatchStatus { scheduled, live, halftime, finished, postponed }

class Match {
  final String id;
  final Team homeTeam;
  final Team awayTeam;
  final int homeScore;
  final int awayScore;
  final MatchStatus status;
  final DateTime kickoffTime;
  final String venue;
  final String? group;
  final String? city;
  final String? stage;
  final int? minute;
  final MatchStats stats;
  final List<MatchEvent> events;

  /// Legacy alias for kickoffTime
  DateTime get dateTime => kickoffTime;
  /// Legacy alias for minute
  int get currentMinute => minute ?? 0;

  const Match({
    required this.id,
    required this.homeTeam,
    required this.awayTeam,
    required this.homeScore,
    required this.awayScore,
    required this.status,
    required this.kickoffTime,
    required this.venue,
    this.group,
    this.city,
    this.stage,
    this.minute,
    MatchStats? stats,
    List<MatchEvent>? events,
  })  : stats = stats ?? const MatchStats.empty(),
        events = events ?? const [];

  Match copyWith({
    int? homeScore,
    int? awayScore,
    MatchStatus? status,
    int? minute,
    MatchStats? stats,
    List<MatchEvent>? events,
  }) {
    return Match(
      id: id,
      homeTeam: homeTeam,
      awayTeam: awayTeam,
      homeScore: homeScore ?? this.homeScore,
      awayScore: awayScore ?? this.awayScore,
      status: status ?? this.status,
      kickoffTime: kickoffTime,
      venue: venue,
      group: group,
      city: city,
      stage: stage,
      minute: minute ?? this.minute,
      stats: stats ?? this.stats,
      events: events ?? this.events,
    );
  }
}

class MatchStats {
  final int homePossession; // percentage e.g. 52
  final int awayPossession;
  final int homeShotsOnGoal;
  final int awayShotsOnGoal;
  final int homeTotalShots;
  final int awayTotalShots;
  final int homeCorners;
  final int awayCorners;
  final int homeFouls;
  final int awayFouls;
  final int homeYellowCards;
  final int awayYellowCards;
  final int homeRedCards;
  final int awayRedCards;
  final int homeOffsides;
  final int awayOffsides;

  const MatchStats({
    required this.homePossession,
    required this.awayPossession,
    required this.homeShotsOnGoal,
    required this.awayShotsOnGoal,
    required this.homeTotalShots,
    required this.awayTotalShots,
    required this.homeCorners,
    required this.awayCorners,
    required this.homeFouls,
    required this.awayFouls,
    required this.homeYellowCards,
    required this.awayYellowCards,
    required this.homeRedCards,
    required this.awayRedCards,
    required this.homeOffsides,
    required this.awayOffsides,
  });

  const MatchStats.empty()
      : homePossession = 50,
        awayPossession = 50,
        homeShotsOnGoal = 0,
        awayShotsOnGoal = 0,
        homeTotalShots = 0,
        awayTotalShots = 0,
        homeCorners = 0,
        awayCorners = 0,
        homeFouls = 0,
        awayFouls = 0,
        homeYellowCards = 0,
        awayYellowCards = 0,
        homeRedCards = 0,
        awayRedCards = 0,
        homeOffsides = 0,
        awayOffsides = 0;
}

enum MatchEventType { goal, card, substitution }

class MatchEvent {
  final int minute;
  final String teamId;
  final String playerName;
  final MatchEventType type;
  final String detail; // e.g. "Assist: Mbappe", "Yellow Card", "Substitution: In/Out"

  const MatchEvent({
    required this.minute,
    required this.teamId,
    required this.playerName,
    required this.type,
    required this.detail,
  });
}
