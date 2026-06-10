import '../models/team.dart';
import '../models/player.dart';
import '../models/match.dart';

class MockData {
  static final List<Team> teams = [
    // Group A
    const Team(id: 't1', name: 'United States', code: 'USA', flagCode: 'us', group: 'A', fifaRanking: 11, coach: 'Mauricio Pochettino'),
    const Team(id: 't2', name: 'Colombia', code: 'COL', flagCode: 'co', group: 'A', fifaRanking: 9, coach: 'Néstor Lorenzo'),
    const Team(id: 't3', name: 'Morocco', code: 'MAR', flagCode: 'ma', group: 'A', fifaRanking: 13, coach: 'Walid Regragui'),
    const Team(id: 't4', name: 'Australia', code: 'AUS', flagCode: 'au', group: 'A', fifaRanking: 24, coach: 'Tony Popovic'),

    // Group B
    const Team(id: 't5', name: 'Mexico', code: 'MEX', flagCode: 'mx', group: 'B', fifaRanking: 16, coach: 'Javier Aguirre'),
    const Team(id: 't6', name: 'Ecuador', code: 'ECU', flagCode: 'ec', group: 'B', fifaRanking: 27, coach: 'Sebastián Beccacece'),
    const Team(id: 't7', name: 'Ukraine', code: 'UKR', flagCode: 'ua', group: 'B', fifaRanking: 22, coach: 'Serhiy Rebrov'),
    const Team(id: 't8', name: 'Cameroon', code: 'CMR', flagCode: 'cm', group: 'B', fifaRanking: 49, coach: 'Marc Brys'),

    // Group C
    const Team(id: 't9', name: 'Canada', code: 'CAN', flagCode: 'ca', group: 'C', fifaRanking: 35, coach: 'Jesse Marsch'),
    const Team(id: 't10', name: 'Uruguay', code: 'URU', flagCode: 'uy', group: 'C', fifaRanking: 14, coach: 'Marcelo Bielsa'),
    const Team(id: 't11', name: 'Croatia', code: 'CRO', flagCode: 'hr', group: 'C', fifaRanking: 10, coach: 'Zlatko Dalić'),
    const Team(id: 't12', name: 'Nigeria', code: 'NGA', flagCode: 'ng', group: 'C', fifaRanking: 39, coach: 'Finidi George'),

    // Group D
    const Team(id: 't13', name: 'Argentina', code: 'ARG', flagCode: 'ar', group: 'D', fifaRanking: 1, coach: 'Lionel Scaloni'),
    const Team(id: 't14', name: 'Denmark', code: 'DEN', flagCode: 'dk', group: 'D', fifaRanking: 20, coach: 'Lars Knudsen'),
    const Team(id: 't15', name: 'Saudi Arabia', code: 'KSA', flagCode: 'sa', group: 'D', fifaRanking: 56, coach: 'Roberto Mancini'),
    const Team(id: 't16', name: 'Poland', code: 'POL', flagCode: 'pl', group: 'D', fifaRanking: 30, coach: 'Michał Probierz'),

    // Group E
    const Team(id: 't17', name: 'France', code: 'FRA', flagCode: 'fr', group: 'E', fifaRanking: 2, coach: 'Didier Deschamps'),
    const Team(id: 't18', name: 'Switzerland', code: 'SUI', flagCode: 'ch', group: 'E', fifaRanking: 15, coach: 'Murat Yakin'),
    const Team(id: 't19', name: 'Egypt', code: 'EGY', flagCode: 'eg', group: 'E', fifaRanking: 31, coach: 'Hossam Hassan'),
    const Team(id: 't20', name: 'Peru', code: 'PER', flagCode: 'pe', group: 'E', fifaRanking: 43, coach: 'Jorge Fossati'),

    // Group F
    const Team(id: 't21', name: 'Spain', code: 'ESP', flagCode: 'es', group: 'F', fifaRanking: 3, coach: 'Luis de la Fuente'),
    const Team(id: 't22', name: 'Sweden', code: 'SWE', flagCode: 'se', group: 'F', fifaRanking: 28, coach: 'Jon Dahl Tomasson'),
    const Team(id: 't23', name: 'Japan', code: 'JPN', flagCode: 'jp', group: 'F', fifaRanking: 15, coach: 'Hajime Moriyasu'),
    const Team(id: 't24', name: 'Senegal', code: 'SEN', flagCode: 'sn', group: 'F', fifaRanking: 21, coach: 'Aliou Cissé'),

    // Group G
    const Team(id: 't25', name: 'England', code: 'ENG', flagCode: 'gb-eng', group: 'G', fifaRanking: 4, coach: 'Thomas Tuchel'),
    const Team(id: 't26', name: 'Austria', code: 'AUT', flagCode: 'at', group: 'G', fifaRanking: 23, coach: 'Ralf Rangnick'),
    const Team(id: 't27', name: 'South Korea', code: 'KOR', flagCode: 'kr', group: 'G', fifaRanking: 22, coach: 'Hong Myung-bo'),
    const Team(id: 't28', name: 'Ghana', code: 'GHA', flagCode: 'gh', group: 'G', fifaRanking: 64, coach: 'Otto Addo'),

    // Group H
    const Team(id: 't29', name: 'Brazil', code: 'BRA', flagCode: 'br', group: 'H', fifaRanking: 5, coach: 'Dorival Júnior'),
    const Team(id: 't30', name: 'Turkey', code: 'TUR', flagCode: 'tr', group: 'H', fifaRanking: 26, coach: 'Vincenzo Montella'),
    const Team(id: 't31', name: 'Algeria', code: 'ALG', flagCode: 'dz', group: 'H', fifaRanking: 41, coach: 'Vladimir Petković'),
    const Team(id: 't32', name: 'New Zealand', code: 'NZL', flagCode: 'nz', group: 'H', fifaRanking: 94, coach: 'Darren Bazeley'),

    // Group I
    const Team(id: 't33', name: 'Belgium', code: 'BEL', flagCode: 'be', group: 'I', fifaRanking: 6, coach: 'Domenico Tedesco'),
    const Team(id: 't34', name: 'Portugal', code: 'POR', flagCode: 'pt', group: 'I', fifaRanking: 8, coach: 'Roberto Martínez'),
    const Team(id: 't35', name: 'Iran', code: 'IRN', flagCode: 'ir', group: 'I', fifaRanking: 19, coach: 'Amir Ghalenoei'),
    const Team(id: 't36', name: 'Panama', code: 'PAN', flagCode: 'pa', group: 'I', fifaRanking: 37, coach: 'Thomas Christiansen'),

    // Group J
    const Team(id: 't37', name: 'Netherlands', code: 'NED', flagCode: 'nl', group: 'J', fifaRanking: 7, coach: 'Ronald Koeman'),
    const Team(id: 't38', name: 'Norway', code: 'NOR', flagCode: 'no', group: 'J', fifaRanking: 47, coach: 'Ståle Solbakken'),
    const Team(id: 't39', name: 'Tunisia', code: 'TUN', flagCode: 'tn', group: 'J', fifaRanking: 36, coach: 'Faouzi Benzarti'),
    const Team(id: 't40', name: 'Costa Rica', code: 'CRC', flagCode: 'cr', group: 'J', fifaRanking: 52, coach: 'Claudio Vivas'),

    // Group K
    const Team(id: 't41', name: 'Italy', code: 'ITA', flagCode: 'it', group: 'K', fifaRanking: 10, coach: 'Luciano Spalletti'),
    const Team(id: 't42', name: 'Hungary', code: 'HUN', flagCode: 'hu', group: 'K', fifaRanking: 32, coach: 'Marco Rossi'),
    const Team(id: 't43', name: 'Chile', code: 'CHI', flagCode: 'cl', group: 'K', fifaRanking: 40, coach: 'Ricardo Gareca'),
    const Team(id: 't44', name: 'South Africa', code: 'RSA', flagCode: 'za', group: 'K', fifaRanking: 59, coach: 'Hugo Broos'),

    // Group L
    const Team(id: 't45', name: 'Germany', code: 'GER', flagCode: 'de', group: 'L', fifaRanking: 12, coach: 'Julian Nagelsmann'),
    const Team(id: 't46', name: 'Ukraine', code: 'UKR', flagCode: 'ua', group: 'L', fifaRanking: 22, coach: 'Serhiy Rebrov'),
    const Team(id: 't47', name: 'Paraguay', code: 'PAR', flagCode: 'py', group: 'L', fifaRanking: 62, coach: 'Gustavo Alfaro'),
    const Team(id: 't48', name: 'Canada', code: 'CAN', flagCode: 'ca', group: 'L', fifaRanking: 35, coach: 'Jesse Marsch'),
  ];

  static final List<Player> players = [
    // Argentina
    const Player(
      id: 'p1',
      name: 'Lionel Messi',
      teamId: 't13',
      teamName: 'Argentina',
      position: 'Forward',
      number: 10,
      age: 38,
      photoUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
      rating: 91,
      pastRecords: [
        'FIFA World Cup Winner (2022)',
        '8x Ballon d\'Or Winner',
        '2x Copa América Champion (2021, 2024)',
        'World Cup Golden Ball Winner (2014, 2022)'
      ],
      stats: PlayerStats(goals: 4, assists: 3, yellowCards: 0, redCards: 0, minutesPlayed: 270, matchesPlayed: 3),
    ),
    const Player(
      id: 'p2',
      name: 'Lautaro Martínez',
      teamId: 't13',
      teamName: 'Argentina',
      position: 'Forward',
      number: 22,
      age: 28,
      photoUrl: 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=150',
      rating: 89,
      pastRecords: [
        'Copa América Golden Boot (2024)',
        'Serie A MVP (2023/2024)',
        'FIFA World Cup Winner (2022)',
        'Serie A Top Scorer (24 goals, 2023/24)'
      ],
      stats: PlayerStats(goals: 3, assists: 1, yellowCards: 1, redCards: 0, minutesPlayed: 210, matchesPlayed: 3),
    ),

    // France
    const Player(
      id: 'p3',
      name: 'Kylian Mbappé',
      teamId: 't17',
      teamName: 'France',
      position: 'Forward',
      number: 10,
      age: 27,
      photoUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
      rating: 92,
      pastRecords: [
        'FIFA World Cup Winner (2018)',
        'FIFA World Cup Golden Boot (2022)',
        'PSG All-Time Top Scorer (256 goals)',
        '7x Ligue 1 Champion'
      ],
      stats: PlayerStats(goals: 5, assists: 2, yellowCards: 0, redCards: 0, minutesPlayed: 270, matchesPlayed: 3),
    ),
    const Player(
      id: 'p4',
      name: 'Antoine Griezmann',
      teamId: 't17',
      teamName: 'France',
      position: 'Midfielder',
      number: 7,
      age: 35,
      photoUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
      rating: 88,
      pastRecords: [
        'FIFA World Cup Winner (2018)',
        'UEFA Europa League Winner (2018)',
        'La Liga Best Player (2016)',
        'UEFA Euro Golden Boot & Player of the Tournament (2016)'
      ],
      stats: PlayerStats(goals: 1, assists: 4, yellowCards: 1, redCards: 0, minutesPlayed: 250, matchesPlayed: 3),
    ),

    // Norway
    const Player(
      id: 'p5',
      name: 'Erling Haaland',
      teamId: 't38',
      teamName: 'Norway',
      position: 'Forward',
      number: 9,
      age: 25,
      photoUrl: 'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?w=150',
      rating: 91,
      pastRecords: [
        '2x Premier League Golden Boot (2023, 2024)',
        'UEFA Champions League Winner (2023)',
        'European Golden Shoe (2023)',
        'Single-season Premier League goal record (36 goals)'
      ],
      stats: PlayerStats(goals: 6, assists: 1, yellowCards: 0, redCards: 0, minutesPlayed: 270, matchesPlayed: 3),
    ),

    // Portugal
    const Player(
      id: 'p6',
      name: 'Cristiano Ronaldo',
      teamId: 't34',
      teamName: 'Portugal',
      position: 'Forward',
      number: 7,
      age: 41,
      photoUrl: 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=150',
      rating: 88,
      pastRecords: [
        '5x Ballon d\'Or Winner',
        'UEFA European Champion (2016)',
        'All-Time Leading International Goalscorer (130+ goals)',
        '5x UEFA Champions League Winner'
      ],
      stats: PlayerStats(goals: 2, assists: 1, yellowCards: 1, redCards: 0, minutesPlayed: 180, matchesPlayed: 3),
    ),
    const Player(
      id: 'p7',
      name: 'Bruno Fernandes',
      teamId: 't34',
      teamName: 'Portugal',
      position: 'Midfielder',
      number: 8,
      age: 31,
      photoUrl: 'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?w=150',
      rating: 88,
      pastRecords: [
        'UEFA Nations League Winner (2019)',
        '3x Sir Matt Busby Player of the Year',
        'UEFA Europa League Squad of the Season'
      ],
      stats: PlayerStats(goals: 1, assists: 3, yellowCards: 0, redCards: 0, minutesPlayed: 260, matchesPlayed: 3),
    ),

    // England
    const Player(
      id: 'p8',
      name: 'Harry Kane',
      teamId: 't25',
      teamName: 'England',
      position: 'Forward',
      number: 9,
      age: 32,
      photoUrl: 'https://images.unsplash.com/photo-1489980508314-941910ded1f4?w=150',
      rating: 90,
      pastRecords: [
        'FIFA World Cup Golden Boot (2018)',
        'European Golden Shoe (2024)',
        '3x Premier League Golden Boot Winner',
        'Bayern Munich Single-Season Debut Goal Record (36 goals)'
      ],
      stats: PlayerStats(goals: 3, assists: 2, yellowCards: 0, redCards: 0, minutesPlayed: 255, matchesPlayed: 3),
    ),
    const Player(
      id: 'p9',
      name: 'Jude Bellingham',
      teamId: 't25',
      teamName: 'England',
      position: 'Midfielder',
      number: 10,
      age: 22,
      photoUrl: 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=150',
      rating: 90,
      pastRecords: [
        'La Liga Player of the Season (2023/24)',
        'UEFA Champions League Winner (2024)',
        'Golden Boy Award Winner (2023)',
        'Kopa Trophy Winner (2023)'
      ],
      stats: PlayerStats(goals: 2, assists: 2, yellowCards: 1, redCards: 0, minutesPlayed: 270, matchesPlayed: 3),
    ),

    // Brazil
    const Player(
      id: 'p10',
      name: 'Vinícius Júnior',
      teamId: 't29',
      teamName: 'Brazil',
      position: 'Forward',
      number: 7,
      age: 25,
      photoUrl: 'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?w=150',
      rating: 91,
      pastRecords: [
        '2x UEFA Champions League Winner (2022, 2024)',
        'UEFA Champions League Player of the Season (2023/24)',
        'FIFA Club World Cup Golden Ball (2022)',
        '3x La Liga Champion'
      ],
      stats: PlayerStats(goals: 3, assists: 3, yellowCards: 1, redCards: 0, minutesPlayed: 260, matchesPlayed: 3),
    ),

    // Spain
    const Player(
      id: 'p11',
      name: 'Lamine Yamal',
      teamId: 't21',
      teamName: 'Spain',
      position: 'Forward',
      number: 19,
      age: 18,
      photoUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
      rating: 86,
      pastRecords: [
        'UEFA Euro Winner & Young Player of the Tournament (2024)',
        'Kopa Trophy Winner (2024)',
        'Youngest Goalscorer in UEFA Euro History',
        'Youngest Debutant & Scorer in La Liga History'
      ],
      stats: PlayerStats(goals: 2, assists: 5, yellowCards: 0, redCards: 0, minutesPlayed: 240, matchesPlayed: 3),
    ),

    // Egypt
    const Player(
      id: 'p12',
      name: 'Mohamed Salah',
      teamId: 't19',
      teamName: 'Egypt',
      position: 'Forward',
      number: 10,
      age: 33,
      photoUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
      rating: 89,
      pastRecords: [
        '3x Premier League Golden Boot Winner',
        'UEFA Champions League Winner (2019)',
        '2x CAF African Footballer of the Year (2017, 2018)',
        'Premier League Player of the Season (2017/18)'
      ],
      stats: PlayerStats(goals: 4, assists: 1, yellowCards: 0, redCards: 0, minutesPlayed: 270, matchesPlayed: 3),
    ),

    // USA
    const Player(
      id: 'p13',
      name: 'Christian Pulisic',
      teamId: 't1',
      teamName: 'United States',
      position: 'Forward',
      number: 11,
      age: 27,
      photoUrl: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=150',
      rating: 85,
      pastRecords: [
        '3x CONCACAF Nations League Winner (2021, 2023, 2024)',
        'UEFA Champions League Winner (2021)',
        'CONCACAF Nations League MVP (2023)',
        'US Soccer Male Athlete of the Year (2017, 2019, 2021, 2023)'
      ],
      stats: PlayerStats(goals: 2, assists: 2, yellowCards: 0, redCards: 0, minutesPlayed: 270, matchesPlayed: 3),
    ),
  ];

  static List<Match> getMatches() {
    final tUSA = teams.firstWhere((t) => t.id == 't1');
    final tCOL = teams.firstWhere((t) => t.id == 't2');
    final tMAR = teams.firstWhere((t) => t.id == 't3');
    final tAUS = teams.firstWhere((t) => t.id == 't4');
    final tARG = teams.firstWhere((t) => t.id == 't13');
    final tFRA = teams.firstWhere((t) => t.id == 't17');
    final tESP = teams.firstWhere((t) => t.id == 't21');
    final tBRA = teams.firstWhere((t) => t.id == 't29');
    final tENG = teams.firstWhere((t) => t.id == 't25');
    final tPOR = teams.firstWhere((t) => t.id == 't34');
    final tGER = teams.firstWhere((t) => t.id == 't45');
    final tNED = teams.firstWhere((t) => t.id == 't37');

    return [
      // LIVE MATCHES
      Match(
        id: 'm1',
        homeTeam: tUSA,
        awayTeam: tCOL,
        homeScore: 2,
        awayScore: 1,
        status: MatchStatus.live,
        currentMinute: 72,
        dateTime: DateTime.now().subtract(const Duration(minutes: 72)),
        venue: 'MetLife Stadium, East Rutherford',
        group: 'Group A',
        stats: const MatchStats(
          homePossession: 48,
          awayPossession: 52,
          homeShotsOnGoal: 5,
          awayShotsOnGoal: 6,
          homeTotalShots: 11,
          awayTotalShots: 14,
          homeCorners: 4,
          awayCorners: 6,
          homeFouls: 12,
          awayFouls: 10,
          homeYellowCards: 2,
          awayYellowCards: 1,
          homeRedCards: 0,
          awayRedCards: 0,
          homeOffsides: 2,
          awayOffsides: 1,
        ),
        events: [
          const MatchEvent(minute: 14, teamId: 't1', playerName: 'Christian Pulisic', type: MatchEventType.goal, detail: 'Assist: Weston McKennie'),
          const MatchEvent(minute: 38, teamId: 't2', playerName: 'Luis Díaz', type: MatchEventType.goal, detail: 'Penalty'),
          const MatchEvent(minute: 55, teamId: 't1', playerName: 'Folarin Balogun', type: MatchEventType.goal, detail: 'Assist: Timothy Weah'),
          const MatchEvent(minute: 61, teamId: 't2', playerName: 'Jefferson Lerma', type: MatchEventType.card, detail: 'Yellow Card'),
        ],
      ),
      Match(
        id: 'm2',
        homeTeam: tARG,
        awayTeam: tFRA,
        homeScore: 3,
        awayScore: 3,
        status: MatchStatus.live,
        currentMinute: 88,
        dateTime: DateTime.now().subtract(const Duration(minutes: 88)),
        venue: 'SoFi Stadium, Los Angeles',
        group: 'Group D/E Crossover',
        stats: const MatchStats(
          homePossession: 55,
          awayPossession: 45,
          homeShotsOnGoal: 9,
          awayShotsOnGoal: 8,
          homeTotalShots: 18,
          awayTotalShots: 15,
          homeCorners: 8,
          awayCorners: 4,
          homeFouls: 8,
          awayFouls: 14,
          homeYellowCards: 1,
          awayYellowCards: 3,
          homeRedCards: 0,
          awayRedCards: 0,
          homeOffsides: 3,
          awayOffsides: 4,
        ),
        events: [
          const MatchEvent(minute: 23, teamId: 't13', playerName: 'Lionel Messi', type: MatchEventType.goal, detail: 'Penalty'),
          const MatchEvent(minute: 36, teamId: 't13', playerName: 'Lautaro Martínez', type: MatchEventType.goal, detail: 'Assist: Rodrigo De Paul'),
          const MatchEvent(minute: 68, teamId: 't17', playerName: 'Kylian Mbappé', type: MatchEventType.goal, detail: 'Assist: Antoine Griezmann'),
          const MatchEvent(minute: 71, teamId: 't17', playerName: 'Kylian Mbappé', type: MatchEventType.goal, detail: 'Volley'),
          const MatchEvent(minute: 80, teamId: 't13', playerName: 'Lionel Messi', type: MatchEventType.goal, detail: 'Rebound'),
          const MatchEvent(minute: 84, teamId: 't17', playerName: 'Kylian Mbappé', type: MatchEventType.goal, detail: 'Penalty'),
        ],
      ),

      // FINISHED MATCHES
      Match(
        id: 'm3',
        homeTeam: tESP,
        awayTeam: tGER,
        homeScore: 2,
        awayScore: 1,
        status: MatchStatus.finished,
        dateTime: DateTime.now().subtract(const Duration(days: 1)),
        venue: 'Mercedes-Benz Stadium, Atlanta',
        group: 'Group F/L',
        stats: const MatchStats(
          homePossession: 54,
          awayPossession: 46,
          homeShotsOnGoal: 6,
          awayShotsOnGoal: 4,
          homeTotalShots: 13,
          awayTotalShots: 10,
          homeCorners: 5,
          awayCorners: 3,
          homeFouls: 9,
          awayFouls: 11,
          homeYellowCards: 1,
          awayYellowCards: 2,
          homeRedCards: 0,
          awayRedCards: 0,
          homeOffsides: 1,
          awayOffsides: 2,
        ),
        events: [
          const MatchEvent(minute: 33, teamId: 't21', playerName: 'Dani Olmo', type: MatchEventType.goal, detail: 'Assist: Lamine Yamal'),
          const MatchEvent(minute: 62, teamId: 't45', playerName: 'Kai Havertz', type: MatchEventType.goal, detail: 'Assist: Florian Wirtz'),
          const MatchEvent(minute: 119, teamId: 't21', playerName: 'Mikel Merino', type: MatchEventType.goal, detail: 'Assist: Dani Olmo'),
        ],
      ),
      Match(
        id: 'm4',
        homeTeam: tBRA,
        awayTeam: tPOR,
        homeScore: 2,
        awayScore: 0,
        status: MatchStatus.finished,
        dateTime: DateTime.now().subtract(const Duration(days: 2)),
        venue: 'Hard Rock Stadium, Miami',
        group: 'Group H/I',
        stats: const MatchStats(
          homePossession: 51,
          awayPossession: 49,
          homeShotsOnGoal: 7,
          awayShotsOnGoal: 3,
          homeTotalShots: 15,
          awayTotalShots: 9,
          homeCorners: 6,
          awayCorners: 4,
          homeFouls: 14,
          awayFouls: 16,
          homeYellowCards: 3,
          awayYellowCards: 4,
          homeRedCards: 0,
          awayRedCards: 0,
          homeOffsides: 2,
          awayOffsides: 1,
        ),
        events: [
          const MatchEvent(minute: 41, teamId: 't29', playerName: 'Vinícius Júnior', type: MatchEventType.goal, detail: 'Assist: Rodrygo'),
          const MatchEvent(minute: 85, teamId: 't29', playerName: 'Gabriel Martinelli', type: MatchEventType.goal, detail: 'Assist: Bruno Guimarães'),
        ],
      ),

      // UPCOMING MATCHES
      Match(
        id: 'm5',
        homeTeam: tENG,
        awayTeam: tNED,
        homeScore: 0,
        awayScore: 0,
        status: MatchStatus.upcoming,
        dateTime: DateTime.now().add(const Duration(hours: 4)),
        venue: 'AT&T Stadium, Dallas',
        group: 'Group G/J',
        stats: const MatchStats.empty(),
        events: [],
      ),
      Match(
        id: 'm6',
        homeTeam: tMAR,
        awayTeam: tAUS,
        homeScore: 0,
        awayScore: 0,
        status: MatchStatus.upcoming,
        dateTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
        venue: 'BC Place, Vancouver',
        group: 'Group A',
        stats: const MatchStats.empty(),
        events: [],
      ),
      Match(
        id: 'm7',
        homeTeam: tBRA,
        awayTeam: tGER,
        homeScore: 0,
        awayScore: 0,
        status: MatchStatus.upcoming,
        dateTime: DateTime.now().add(const Duration(days: 2)),
        venue: 'NRG Stadium, Houston',
        group: 'Group H/L',
        stats: const MatchStats.empty(),
        events: [],
      ),
    ];
  }
}
