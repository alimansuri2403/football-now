class Team {
  final String id;
  final String name;
  final String code; // e.g. USA, MEX, CAN
  final String flagCode; // 2-letter country code for FlagCDN
  final String group; // A to L
  final int fifaRanking;
  final String coach;

  const Team({
    required this.id,
    required this.name,
    required this.code,
    required this.flagCode,
    required this.group,
    required this.fifaRanking,
    required this.coach,
  });

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'] as String,
      name: json['name'] as String,
      code: json['code'] as String,
      flagCode: json['flagCode'] as String,
      group: json['group'] as String,
      fifaRanking: json['fifaRanking'] as int,
      coach: json['coach'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'code': code,
        'flagCode': flagCode,
        'group': group,
        'fifaRanking': fifaRanking,
        'coach': coach,
      };
}

class GroupStanding {
  final Team team;
  final int played;
  final int won;
  final int drawn;
  final int lost;
  final int goalsFor;
  final int goalsAgainst;
  final int points;

  const GroupStanding({
    required this.team,
    required this.played,
    required this.won,
    required this.drawn,
    required this.lost,
    required this.goalsFor,
    required this.goalsAgainst,
    required this.points,
  });

  int get goalDifference => goalsFor - goalsAgainst;
}
