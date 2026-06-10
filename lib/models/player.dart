class Player {
  final String id;
  final String name;
  final String teamId;
  final String teamName;
  final String position; // Forward, Midfielder, Defender, Goalkeeper
  final int number;
  final int age;
  final String photoUrl;
  final int rating; // Player overall rating (e.g. 91)
  final List<String> pastRecords; // Past career achievements / records
  final PlayerStats stats;

  const Player({
    required this.id,
    required this.name,
    required this.teamId,
    required this.teamName,
    required this.position,
    required this.number,
    required this.age,
    required this.photoUrl,
    required this.rating,
    required this.pastRecords,
    required this.stats,
  });

  Player copyWith({
    PlayerStats? stats,
    int? rating,
    List<String>? pastRecords,
  }) {
    return Player(
      id: id,
      name: name,
      teamId: teamId,
      teamName: teamName,
      position: position,
      number: number,
      age: age,
      photoUrl: photoUrl,
      rating: rating ?? this.rating,
      pastRecords: pastRecords ?? this.pastRecords,
      stats: stats ?? this.stats,
    );
  }
}

class PlayerStats {
  final int goals;
  final int assists;
  final int yellowCards;
  final int redCards;
  final int minutesPlayed;
  final int matchesPlayed;

  const PlayerStats({
    required this.goals,
    required this.assists,
    required this.yellowCards,
    required this.redCards,
    required this.minutesPlayed,
    required this.matchesPlayed,
  });

  const PlayerStats.empty()
      : goals = 0,
        assists = 0,
        yellowCards = 0,
        redCards = 0,
        minutesPlayed = 0,
        matchesPlayed = 0;
}
