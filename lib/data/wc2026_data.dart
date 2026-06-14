/// Comprehensive static data for FIFA World Cup 2026
/// Hosted by USA (11 venues), Canada (2 venues), Mexico (3 venues)
/// 48 teams · 12 groups · 104 matches · June 11 – July 19, 2026

class WC2026Stadium {
  final String id;
  final String name;
  final String city;
  final String country;
  final String countryCode; // 2-letter ISO
  final int capacity;
  final String surface;
  final String? host; // special role e.g. "FINAL"
  final String imageUrl;

  const WC2026Stadium({
    required this.id,
    required this.name,
    required this.city,
    required this.country,
    required this.countryCode,
    required this.capacity,
    this.surface = 'Natural Grass',
    this.host,
    required this.imageUrl,
  });
}

class WC2026Team {
  final String code;      // FIFA 3-letter code e.g. USA
  final String name;
  final String flagCode;  // 2-letter ISO e.g. us
  final String group;     // A-L
  final String coach;
  final int fifaRanking;
  final List<WC2026Player> squad;

  const WC2026Team({
    required this.code,
    required this.name,
    required this.flagCode,
    required this.group,
    required this.coach,
    required this.fifaRanking,
    this.squad = const [],
  });
}

class WC2026Player {
  final String name;
  final String position; // GK, DEF, MID, FWD
  final String club;
  final int number;
  final int age;

  const WC2026Player({
    required this.name,
    required this.position,
    required this.club,
    required this.number,
    required this.age,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// STADIUMS  (16 official venues)
// ─────────────────────────────────────────────────────────────────────────────
class WC2026Data {
  static const List<WC2026Stadium> stadiums = [
    // ── USA ──────────────────────────────────────────────────────────────────
    WC2026Stadium(
      id: 'metlife',
      name: 'MetLife Stadium',
      city: 'East Rutherford, NJ',
      country: 'United States',
      countryCode: 'us',
      capacity: 82500,
      host: 'FINAL',
      imageUrl: 'https://images.unsplash.com/photo-1508098682722-e99c43a406b2?w=800&auto=format&fit=crop',
    ),
    WC2026Stadium(
      id: 'att',
      name: 'AT&T Stadium',
      city: 'Arlington, TX',
      country: 'United States',
      countryCode: 'us',
      capacity: 80000,
      surface: 'Artificial Turf',
      imageUrl: 'https://images.unsplash.com/photo-1485324290208-fb19f8a9816d?w=800&auto=format&fit=crop',
    ),
    WC2026Stadium(
      id: 'sofi',
      name: 'SoFi Stadium',
      city: 'Inglewood, CA',
      country: 'United States',
      countryCode: 'us',
      capacity: 70240,
      imageUrl: 'https://images.unsplash.com/photo-1522778119026-d647f0596c20?w=800&auto=format&fit=crop',
    ),
    WC2026Stadium(
      id: 'levis',
      name: "Levi's Stadium",
      city: 'Santa Clara, CA',
      country: 'United States',
      countryCode: 'us',
      capacity: 68500,
      imageUrl: 'https://images.unsplash.com/photo-1577223625856-7fde4979e8c0?w=800&auto=format&fit=crop',
    ),
    WC2026Stadium(
      id: 'lincoln',
      name: 'Lincoln Financial Field',
      city: 'Philadelphia, PA',
      country: 'United States',
      countryCode: 'us',
      capacity: 69328,
      imageUrl: 'https://images.unsplash.com/photo-1563185367-170068426390?w=800&auto=format&fit=crop',
    ),
    WC2026Stadium(
      id: 'arrowhead',
      name: 'Arrowhead Stadium',
      city: 'Kansas City, MO',
      country: 'United States',
      countryCode: 'us',
      capacity: 76416,
      imageUrl: 'https://images.unsplash.com/photo-1595155731960-b1ee143dec79?w=800&auto=format&fit=crop',
    ),
    WC2026Stadium(
      id: 'gillette',
      name: 'Gillette Stadium',
      city: 'Foxborough, MA',
      country: 'United States',
      countryCode: 'us',
      capacity: 65878,
      imageUrl: 'https://images.unsplash.com/photo-1510250297584-113bf550402e?w=800&auto=format&fit=crop',
    ),
    WC2026Stadium(
      id: 'lumen',
      name: 'Lumen Field',
      city: 'Seattle, WA',
      country: 'United States',
      countryCode: 'us',
      capacity: 68740,
      imageUrl: 'https://images.unsplash.com/photo-1477862096227-3a1bb3b08330?w=800&auto=format&fit=crop',
    ),
    WC2026Stadium(
      id: 'allegiant',
      name: 'Allegiant Stadium',
      city: 'Las Vegas, NV',
      country: 'United States',
      countryCode: 'us',
      capacity: 65000,
      imageUrl: 'https://images.unsplash.com/photo-1599045118108-bf9954418b76?w=800&auto=format&fit=crop',
    ),
    WC2026Stadium(
      id: 'hardrock',
      name: 'Hard Rock Stadium',
      city: 'Miami Gardens, FL',
      country: 'United States',
      countryCode: 'us',
      capacity: 64767,
      imageUrl: 'https://images.unsplash.com/photo-1517649763962-0c623066013b?w=800&auto=format&fit=crop',
    ),
    WC2026Stadium(
      id: 'nrg',
      name: 'NRG Stadium',
      city: 'Houston, TX',
      country: 'United States',
      countryCode: 'us',
      capacity: 72220,
      surface: 'Retractable Roof',
      imageUrl: 'https://images.unsplash.com/photo-1518005020951-eccb494ad742?w=800&auto=format&fit=crop',
    ),
    // ── CANADA ───────────────────────────────────────────────────────────────
    WC2026Stadium(
      id: 'bcplace',
      name: 'BC Place',
      city: 'Vancouver, BC',
      country: 'Canada',
      countryCode: 'ca',
      capacity: 54500,
      surface: 'Artificial Turf',
      imageUrl: 'https://images.unsplash.com/photo-1533174072545-7a4b6ad7a6c3?w=800&auto=format&fit=crop',
    ),
    WC2026Stadium(
      id: 'bmofield',
      name: 'BMO Field',
      city: 'Toronto, ON',
      country: 'Canada',
      countryCode: 'ca',
      capacity: 45736,
      imageUrl: 'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=800&auto=format&fit=crop',
    ),
    // ── MEXICO ───────────────────────────────────────────────────────────────
    WC2026Stadium(
      id: 'azteca',
      name: 'Estadio Azteca',
      city: 'Mexico City',
      country: 'Mexico',
      countryCode: 'mx',
      capacity: 87523,
      host: 'OPENING MATCH',
      imageUrl: 'https://images.unsplash.com/photo-1504701954957-2390f80649b6?w=800&auto=format&fit=crop',
    ),
    WC2026Stadium(
      id: 'bbva',
      name: 'Estadio BBVA',
      city: 'Monterrey',
      country: 'Mexico',
      countryCode: 'mx',
      capacity: 53500,
      imageUrl: 'https://images.unsplash.com/photo-1524143986875-3b098d78b363?w=800&auto=format&fit=crop',
    ),
    WC2026Stadium(
      id: 'akron',
      name: 'Estadio Akron',
      city: 'Guadalajara',
      country: 'Mexico',
      countryCode: 'mx',
      capacity: 46232,
      imageUrl: 'https://images.unsplash.com/photo-1519766304817-4f37bda74a27?w=800&auto=format&fit=crop',
    ),
  ];

  // ─────────────────────────────────────────────────────────────────────────
  // TEAMS  (48 qualified nations with squads)
  // ─────────────────────────────────────────────────────────────────────────
  static const List<WC2026Team> teams = [
    // ── GROUP A ─────────────────────────────────────────────────────────────
    WC2026Team(
      code: 'USA', name: 'United States', flagCode: 'us', group: 'A',
      coach: 'Mauricio Pochettino', fifaRanking: 11,
      squad: [
        WC2026Player(name: 'Matt Turner', position: 'GK', club: 'Crystal Palace', number: 1, age: 30),
        WC2026Player(name: 'Christian Pulisic', position: 'FWD', club: 'AC Milan', number: 10, age: 27),
        WC2026Player(name: 'Gio Reyna', position: 'MID', club: 'Borussia Dortmund', number: 7, age: 23),
        WC2026Player(name: 'Weston McKennie', position: 'MID', club: 'Juventus', number: 8, age: 27),
        WC2026Player(name: 'Yunus Musah', position: 'MID', club: 'AC Milan', number: 6, age: 22),
        WC2026Player(name: 'Tyler Adams', position: 'MID', club: 'Bournemouth', number: 4, age: 26),
        WC2026Player(name: 'Tim Weah', position: 'FWD', club: 'Juventus', number: 11, age: 25),
        WC2026Player(name: 'Folarin Balogun', position: 'FWD', club: 'Monaco', number: 9, age: 24),
        WC2026Player(name: 'Sergiño Dest', position: 'DEF', club: 'PSV', number: 2, age: 24),
        WC2026Player(name: 'Chris Richards', position: 'DEF', club: 'Crystal Palace', number: 5, age: 24),
        WC2026Player(name: 'Joe Scally', position: 'DEF', club: 'Borussia M\'gladbach', number: 3, age: 22),
      ],
    ),
    WC2026Team(
      code: 'MEX', name: 'Mexico', flagCode: 'mx', group: 'B',
      coach: 'Javier Aguirre', fifaRanking: 16,
      squad: [
        WC2026Player(name: 'Guillermo Ochoa', position: 'GK', club: 'América', number: 1, age: 39),
        WC2026Player(name: 'Hirving Lozano', position: 'FWD', club: 'SD Dynamo', number: 22, age: 29),
        WC2026Player(name: 'Edson Álvarez', position: 'MID', club: 'West Ham', number: 6, age: 27),
        WC2026Player(name: 'Santiago Giménez', position: 'FWD', club: 'Feyenoord', number: 9, age: 23),
        WC2026Player(name: 'Alexis Vega', position: 'FWD', club: 'Chivas', number: 11, age: 27),
        WC2026Player(name: 'Carlos Rodríguez', position: 'MID', club: 'Cruz Azul', number: 8, age: 27),
        WC2026Player(name: 'César Montes', position: 'DEF', club: 'Espanyol', number: 3, age: 27),
        WC2026Player(name: 'Orbelin Pineda', position: 'MID', club: 'AEK Athens', number: 10, age: 28),
        WC2026Player(name: 'Héctor Herrera', position: 'MID', club: 'Houston Dynamo', number: 16, age: 35),
        WC2026Player(name: 'Henry Martín', position: 'FWD', club: 'América', number: 14, age: 32),
        WC2026Player(name: 'Johan Vásquez', position: 'DEF', club: 'Genoa', number: 4, age: 24),
      ],
    ),
    WC2026Team(
      code: 'CAN', name: 'Canada', flagCode: 'ca', group: 'C',
      coach: 'Jesse Marsch', fifaRanking: 39,
      squad: [
        WC2026Player(name: 'Milan Borjan', position: 'GK', club: 'Red Star Belgrade', number: 1, age: 36),
        WC2026Player(name: 'Alphonso Davies', position: 'DEF', club: 'Bayern Munich', number: 19, age: 24),
        WC2026Player(name: 'Jonathan David', position: 'FWD', club: 'Lille', number: 9, age: 24),
        WC2026Player(name: 'Tajon Buchanan', position: 'FWD', club: 'Inter Milan', number: 11, age: 25),
        WC2026Player(name: 'Stephen Eustáquio', position: 'MID', club: 'Porto', number: 7, age: 27),
        WC2026Player(name: 'Cyle Larin', position: 'FWD', club: 'Club Brugge', number: 10, age: 29),
        WC2026Player(name: 'Richie Laryea', position: 'DEF', club: 'Nottm Forest', number: 22, age: 29),
        WC2026Player(name: 'Atiba Hutchinson', position: 'MID', club: 'Beşiktaş', number: 13, age: 40),
        WC2026Player(name: 'Alistair Johnston', position: 'DEF', club: 'Celtic', number: 2, age: 25),
        WC2026Player(name: 'Kamal Miller', position: 'DEF', club: 'LAFC', number: 5, age: 27),
        WC2026Player(name: 'Ismaël Koné', position: 'MID', club: 'Marseille', number: 8, age: 22),
      ],
    ),
    // ── TOP CONTENDERS ───────────────────────────────────────────────────────
    WC2026Team(
      code: 'ARG', name: 'Argentina', flagCode: 'ar', group: 'D',
      coach: 'Lionel Scaloni', fifaRanking: 1,
      squad: [
        WC2026Player(name: 'Emiliano Martínez', position: 'GK', club: 'Aston Villa', number: 23, age: 32),
        WC2026Player(name: 'Lionel Messi', position: 'FWD', club: 'Inter Miami', number: 10, age: 38),
        WC2026Player(name: 'Lautaro Martínez', position: 'FWD', club: 'Inter Milan', number: 22, age: 27),
        WC2026Player(name: 'Julián Álvarez', position: 'FWD', club: 'Atlético Madrid', number: 9, age: 24),
        WC2026Player(name: 'Enzo Fernández', position: 'MID', club: 'Chelsea', number: 24, age: 24),
        WC2026Player(name: 'Alexis Mac Allister', position: 'MID', club: 'Liverpool', number: 20, age: 25),
        WC2026Player(name: 'Rodrigo De Paul', position: 'MID', club: 'Atlético Madrid', number: 7, age: 30),
        WC2026Player(name: 'Lisandro Martínez', position: 'DEF', club: 'Man United', number: 25, age: 26),
        WC2026Player(name: 'Cristian Romero', position: 'DEF', club: 'Tottenham', number: 13, age: 26),
        WC2026Player(name: 'Nahuel Molina', position: 'DEF', club: 'Atlético Madrid', number: 26, age: 26),
        WC2026Player(name: 'Nicolás Tagliafico', position: 'DEF', club: 'Lyon', number: 3, age: 32),
      ],
    ),
    WC2026Team(
      code: 'FRA', name: 'France', flagCode: 'fr', group: 'E',
      coach: 'Didier Deschamps', fifaRanking: 2,
      squad: [
        WC2026Player(name: 'Mike Maignan', position: 'GK', club: 'AC Milan', number: 16, age: 29),
        WC2026Player(name: 'Kylian Mbappé', position: 'FWD', club: 'Real Madrid', number: 10, age: 27),
        WC2026Player(name: 'Ousmane Dembélé', position: 'FWD', club: 'PSG', number: 11, age: 27),
        WC2026Player(name: 'Antoine Griezmann', position: 'FWD', club: 'Atlético Madrid', number: 7, age: 35),
        WC2026Player(name: 'Aurélien Tchouaméni', position: 'MID', club: 'Real Madrid', number: 8, age: 24),
        WC2026Player(name: 'Eduardo Camavinga', position: 'MID', club: 'Real Madrid', number: 6, age: 22),
        WC2026Player(name: 'Adrien Rabiot', position: 'MID', club: 'Marseille', number: 14, age: 30),
        WC2026Player(name: 'Théo Hernandez', position: 'DEF', club: 'AC Milan', number: 22, age: 27),
        WC2026Player(name: 'Jules Koundé', position: 'DEF', club: 'Barcelona', number: 5, age: 26),
        WC2026Player(name: 'Dayot Upamecano', position: 'DEF', club: 'Bayern Munich', number: 4, age: 26),
        WC2026Player(name: 'William Saliba', position: 'DEF', club: 'Arsenal', number: 17, age: 23),
      ],
    ),
    WC2026Team(
      code: 'BRA', name: 'Brazil', flagCode: 'br', group: 'F',
      coach: 'Dorival Júnior', fifaRanking: 5,
      squad: [
        WC2026Player(name: 'Alisson', position: 'GK', club: 'Liverpool', number: 1, age: 32),
        WC2026Player(name: 'Vinícius Jr.', position: 'FWD', club: 'Real Madrid', number: 7, age: 24),
        WC2026Player(name: 'Rodrygo', position: 'FWD', club: 'Real Madrid', number: 11, age: 24),
        WC2026Player(name: 'Endrick', position: 'FWD', club: 'Real Madrid', number: 9, age: 18),
        WC2026Player(name: 'Lucas Paquetá', position: 'MID', club: 'West Ham', number: 10, age: 27),
        WC2026Player(name: 'Bruno Guimarães', position: 'MID', club: 'Newcastle', number: 5, age: 27),
        WC2026Player(name: 'Gerson', position: 'MID', club: 'Flamengo', number: 8, age: 27),
        WC2026Player(name: 'Éder Militão', position: 'DEF', club: 'Real Madrid', number: 3, age: 27),
        WC2026Player(name: 'Marquinhos', position: 'DEF', club: 'PSG', number: 4, age: 31),
        WC2026Player(name: 'Danilo', position: 'DEF', club: 'Juventus', number: 2, age: 33),
        WC2026Player(name: 'Renan Lodi', position: 'DEF', club: 'Nottm Forest', number: 6, age: 26),
      ],
    ),
    WC2026Team(
      code: 'ENG', name: 'England', flagCode: 'gb-eng', group: 'G',
      coach: 'Lee Carsley', fifaRanking: 4,
      squad: [
        WC2026Player(name: 'Jordan Pickford', position: 'GK', club: 'Everton', number: 1, age: 32),
        WC2026Player(name: 'Jude Bellingham', position: 'MID', club: 'Real Madrid', number: 10, age: 22),
        WC2026Player(name: 'Bukayo Saka', position: 'FWD', club: 'Arsenal', number: 7, age: 24),
        WC2026Player(name: 'Phil Foden', position: 'MID', club: 'Man City', number: 11, age: 26),
        WC2026Player(name: 'Harry Kane', position: 'FWD', club: 'Bayern Munich', number: 9, age: 32),
        WC2026Player(name: 'Trent Alexander-Arnold', position: 'MID', club: 'Real Madrid', number: 66, age: 27),
        WC2026Player(name: 'Declan Rice', position: 'MID', club: 'Arsenal', number: 4, age: 27),
        WC2026Player(name: 'Marcus Rashford', position: 'FWD', club: 'Barcelona', number: 11, age: 28),
        WC2026Player(name: 'John Stones', position: 'DEF', club: 'Man City', number: 5, age: 31),
        WC2026Player(name: 'Kyle Walker', position: 'DEF', club: 'Bayern Munich', number: 2, age: 36),
        WC2026Player(name: 'Marc Guehi', position: 'DEF', club: 'Crystal Palace', number: 6, age: 24),
      ],
    ),
    WC2026Team(
      code: 'ESP', name: 'Spain', flagCode: 'es', group: 'H',
      coach: 'Luis de la Fuente', fifaRanking: 3,
      squad: [
        WC2026Player(name: 'Unai Simón', position: 'GK', club: 'Athletic Club', number: 1, age: 27),
        WC2026Player(name: 'Lamine Yamal', position: 'FWD', club: 'Barcelona', number: 19, age: 18),
        WC2026Player(name: 'Pedri', position: 'MID', club: 'Barcelona', number: 8, age: 23),
        WC2026Player(name: 'Gavi', position: 'MID', club: 'Barcelona', number: 6, age: 25),
        WC2026Player(name: 'Álvaro Morata', position: 'FWD', club: 'AC Milan', number: 7, age: 33),
        WC2026Player(name: 'Rodri', position: 'MID', club: 'Man City', number: 16, age: 29),
        WC2026Player(name: 'Fabián Ruiz', position: 'MID', club: 'PSG', number: 14, age: 28),
        WC2026Player(name: 'Nico Williams', position: 'FWD', club: 'Athletic Club', number: 11, age: 22),
        WC2026Player(name: 'Daniel Carvajal', position: 'DEF', club: 'Real Madrid', number: 2, age: 32),
        WC2026Player(name: 'Alejandro Grimaldo', position: 'DEF', club: 'Bayer Leverkusen', number: 3, age: 29),
        WC2026Player(name: 'Aymeric Laporte', position: 'DEF', club: 'Al-Nassr', number: 14, age: 30),
      ],
    ),
    WC2026Team(
      code: 'GER', name: 'Germany', flagCode: 'de', group: 'I',
      coach: 'Julian Nagelsmann', fifaRanking: 12,
      squad: [
        WC2026Player(name: 'Manuel Neuer', position: 'GK', club: 'Bayern Munich', number: 1, age: 40),
        WC2026Player(name: 'Jamal Musiala', position: 'MID', club: 'Bayern Munich', number: 10, age: 21),
        WC2026Player(name: 'Florian Wirtz', position: 'MID', club: 'Bayer Leverkusen', number: 17, age: 21),
        WC2026Player(name: 'Kai Havertz', position: 'FWD', club: 'Arsenal', number: 7, age: 26),
        WC2026Player(name: 'Leroy Sané', position: 'FWD', club: 'Bayern Munich', number: 19, age: 30),
        WC2026Player(name: 'Joshua Kimmich', position: 'MID', club: 'Bayern Munich', number: 6, age: 29),
        WC2026Player(name: 'Toni Kroos', position: 'MID', club: 'Real Madrid', number: 8, age: 36),
        WC2026Player(name: 'Robert Andrich', position: 'MID', club: 'Bayer Leverkusen', number: 23, age: 30),
        WC2026Player(name: 'Antonio Rüdiger', position: 'DEF', club: 'Real Madrid', number: 2, age: 33),
        WC2026Player(name: 'Jonathan Tah', position: 'DEF', club: 'Bayer Leverkusen', number: 4, age: 28),
        WC2026Player(name: 'Theo Müller', position: 'FWD', club: 'Bayern Munich', number: 25, age: 36),
      ],
    ),
    WC2026Team(
      code: 'POR', name: 'Portugal', flagCode: 'pt', group: 'J',
      coach: 'Roberto Martínez', fifaRanking: 6,
      squad: [
        WC2026Player(name: 'Diogo Costa', position: 'GK', club: 'Porto', number: 1, age: 25),
        WC2026Player(name: 'Cristiano Ronaldo', position: 'FWD', club: 'Al-Nassr', number: 7, age: 41),
        WC2026Player(name: 'Bernardo Silva', position: 'MID', club: 'Man City', number: 10, age: 31),
        WC2026Player(name: 'Bruno Fernandes', position: 'MID', club: 'Man United', number: 8, age: 31),
        WC2026Player(name: 'Rafael Leão', position: 'FWD', club: 'AC Milan', number: 17, age: 26),
        WC2026Player(name: 'Vitinha', position: 'MID', club: 'PSG', number: 16, age: 24),
        WC2026Player(name: 'João Félix', position: 'FWD', club: 'Atlético Madrid', number: 11, age: 26),
        WC2026Player(name: 'Rúben Dias', position: 'DEF', club: 'Man City', number: 3, age: 27),
        WC2026Player(name: 'João Cancelo', position: 'DEF', club: 'Barcelona', number: 20, age: 31),
        WC2026Player(name: 'Nuno Mendes', position: 'DEF', club: 'PSG', number: 22, age: 22),
        WC2026Player(name: 'Pepe', position: 'DEF', club: 'Retired', number: 3, age: 43),
      ],
    ),
    WC2026Team(
      code: 'NED', name: 'Netherlands', flagCode: 'nl', group: 'K',
      coach: 'Ronald Koeman', fifaRanking: 7,
      squad: [
        WC2026Player(name: 'Bart Verbruggen', position: 'GK', club: 'Brighton', number: 1, age: 22),
        WC2026Player(name: 'Virgil van Dijk', position: 'DEF', club: 'Liverpool', number: 4, age: 34),
        WC2026Player(name: 'Frenkie de Jong', position: 'MID', club: 'Barcelona', number: 21, age: 27),
        WC2026Player(name: 'Cody Gakpo', position: 'FWD', club: 'Liverpool', number: 11, age: 25),
        WC2026Player(name: 'Memphis Depay', position: 'FWD', club: 'Corinthians', number: 10, age: 30),
        WC2026Player(name: 'Tijjani Reijnders', position: 'MID', club: 'AC Milan', number: 14, age: 26),
        WC2026Player(name: 'Teun Koopmeiners', position: 'MID', club: 'Juventus', number: 8, age: 26),
        WC2026Player(name: 'Denzel Dumfries', position: 'DEF', club: 'Inter Milan', number: 22, age: 28),
        WC2026Player(name: 'Nathan Aké', position: 'DEF', club: 'Man City', number: 5, age: 30),
        WC2026Player(name: 'Jeremie Frimpong', position: 'DEF', club: 'Bayer Leverkusen', number: 3, age: 24),
        WC2026Player(name: 'Xavi Simons', position: 'MID', club: 'PSG', number: 7, age: 22),
      ],
    ),
    WC2026Team(
      code: 'URU', name: 'Uruguay', flagCode: 'uy', group: 'L',
      coach: 'Marcelo Bielsa', fifaRanking: 14,
      squad: [
        WC2026Player(name: 'Sergio Rochet', position: 'GK', club: 'Nacional', number: 1, age: 30),
        WC2026Player(name: 'Darwin Núñez', position: 'FWD', club: 'Liverpool', number: 9, age: 25),
        WC2026Player(name: 'Federico Valverde', position: 'MID', club: 'Real Madrid', number: 8, age: 26),
        WC2026Player(name: 'Rodrigo Bentancur', position: 'MID', club: 'Tottenham', number: 30, age: 27),
        WC2026Player(name: 'Ronald Araújo', position: 'DEF', club: 'Barcelona', number: 4, age: 25),
        WC2026Player(name: 'José María Giménez', position: 'DEF', club: 'Atlético Madrid', number: 2, age: 29),
        WC2026Player(name: 'Matías Vecino', position: 'MID', club: 'Lazio', number: 17, age: 33),
        WC2026Player(name: 'Facundo Pellistri', position: 'FWD', club: 'Man United', number: 11, age: 23),
        WC2026Player(name: 'Maximiliano Araújo', position: 'FWD', club: 'St. Louis City', number: 7, age: 24),
        WC2026Player(name: 'Mathías Olivera', position: 'DEF', club: 'Napoli', number: 3, age: 27),
        WC2026Player(name: 'Sebastián Cáceres', position: 'DEF', club: 'América', number: 5, age: 26),
      ],
    ),
    // ── OTHER QUALIFIED NATIONS ──────────────────────────────────────────────
    WC2026Team(code: 'COL', name: 'Colombia', flagCode: 'co', group: 'A', coach: 'Néstor Lorenzo', fifaRanking: 9,
      squad: [
        WC2026Player(name: 'David Ospina', position: 'GK', club: 'Al-Qadsiah', number: 1, age: 36),
        WC2026Player(name: 'James Rodríguez', position: 'MID', club: 'Rayo Vallecano', number: 10, age: 34),
        WC2026Player(name: 'Luis Díaz', position: 'FWD', club: 'Liverpool', number: 7, age: 27),
        WC2026Player(name: 'Falcao García', position: 'FWD', club: 'Rayo Vallecano', number: 9, age: 40),
        WC2026Player(name: 'Jhon Arias', position: 'MID', club: 'Fluminense', number: 11, age: 27),
        WC2026Player(name: 'Richard Ríos', position: 'MID', club: 'Palmeiras', number: 8, age: 25),
      ]),
    WC2026Team(code: 'ECU', name: 'Ecuador', flagCode: 'ec', group: 'B', coach: 'Sebastián Beccacece', fifaRanking: 34,
      squad: [
        WC2026Player(name: 'Hernán Galíndez', position: 'GK', club: 'Aucas', number: 1, age: 36),
        WC2026Player(name: 'Enner Valencia', position: 'FWD', club: 'Internacional', number: 13, age: 34),
        WC2026Player(name: 'Moisés Caicedo', position: 'MID', club: 'Chelsea', number: 25, age: 22),
        WC2026Player(name: 'Gonzalo Plata', position: 'FWD', club: 'Al-Qadsiah', number: 11, age: 23),
        WC2026Player(name: 'Jeremy Sarmiento', position: 'FWD', club: 'Brighton', number: 10, age: 22),
      ]),
    WC2026Team(code: 'SEN', name: 'Senegal', flagCode: 'sn', group: 'C', coach: 'Aliou Cissé', fifaRanking: 20,
      squad: [
        WC2026Player(name: 'Édouard Mendy', position: 'GK', club: 'Al-Ahli', number: 1, age: 32),
        WC2026Player(name: 'Sadio Mané', position: 'FWD', club: 'Al-Nassr', number: 10, age: 34),
        WC2026Player(name: 'Kalidou Koulibaly', position: 'DEF', club: 'Al-Hilal', number: 3, age: 33),
        WC2026Player(name: 'Idrissa Gueye', position: 'MID', club: 'Everton', number: 6, age: 34),
        WC2026Player(name: 'Ismaila Sarr', position: 'FWD', club: 'Marseille', number: 23, age: 26),
      ]),
    WC2026Team(code: 'MAR', name: 'Morocco', flagCode: 'ma', group: 'D', coach: 'Walid Regragui', fifaRanking: 13,
      squad: [
        WC2026Player(name: 'Yassine Bounou', position: 'GK', club: 'Al-Hilal', number: 1, age: 33),
        WC2026Player(name: 'Achraf Hakimi', position: 'DEF', club: 'PSG', number: 2, age: 26),
        WC2026Player(name: 'Hakim Ziyech', position: 'MID', club: 'Galatasaray', number: 7, age: 32),
        WC2026Player(name: 'Sofyan Amrabat', position: 'MID', club: 'Man United', number: 4, age: 28),
        WC2026Player(name: 'Youssef En-Nesyri', position: 'FWD', club: 'Fenerbahçe', number: 19, age: 27),
      ]),
    WC2026Team(code: 'JPN', name: 'Japan', flagCode: 'jp', group: 'E', coach: 'Hajime Moriyasu', fifaRanking: 18,
      squad: [
        WC2026Player(name: 'Shuichi Gonda', position: 'GK', club: 'Shimizu S-Pulse', number: 1, age: 35),
        WC2026Player(name: 'Takefusa Kubo', position: 'FWD', club: 'Real Sociedad', number: 11, age: 23),
        WC2026Player(name: 'Wataru Endo', position: 'MID', club: 'Liverpool', number: 3, age: 31),
        WC2026Player(name: 'Ritsu Doan', position: 'MID', club: 'Freiburg', number: 8, age: 26),
        WC2026Player(name: 'Daichi Kamada', position: 'MID', club: 'Crystal Palace', number: 10, age: 28),
        WC2026Player(name: 'Kaoru Mitoma', position: 'FWD', club: 'Brighton', number: 7, age: 27),
      ]),
    WC2026Team(code: 'KOR', name: 'South Korea', flagCode: 'kr', group: 'F', coach: 'Hong Myung-bo', fifaRanking: 22,
      squad: [
        WC2026Player(name: 'Kim Seung-gyu', position: 'GK', club: 'Vissel Kobe', number: 1, age: 35),
        WC2026Player(name: 'Son Heung-min', position: 'FWD', club: 'Tottenham', number: 7, age: 34),
        WC2026Player(name: 'Lee Kang-in', position: 'MID', club: 'PSG', number: 19, age: 23),
        WC2026Player(name: 'Kim Min-jae', position: 'DEF', club: 'Bayern Munich', number: 3, age: 28),
        WC2026Player(name: 'Hwang Hee-chan', position: 'FWD', club: 'Wolves', number: 11, age: 28),
      ]),
    WC2026Team(code: 'PAN', name: 'Panama', flagCode: 'pa', group: 'A', coach: 'Thomas Christiansen', fifaRanking: 49, squad: [
      WC2026Player(name: 'Luis Mejía', position: 'GK', club: 'Olimpia', number: 1, age: 29),
      WC2026Player(name: 'Rolando Blackburn', position: 'FWD', club: 'Philadelphia Union', number: 9, age: 32),
      WC2026Player(name: 'Adalberto Carrasquilla', position: 'MID', club: 'Hartford Athletic', number: 8, age: 25),
    ]),
    WC2026Team(code: 'HND', name: 'Honduras', flagCode: 'hn', group: 'B', coach: 'Reinaldo Rueda', fifaRanking: 78, squad: [
      WC2026Player(name: 'Luis López', position: 'GK', club: 'Montreal', number: 1, age: 32),
      WC2026Player(name: 'Romell Quioto', position: 'FWD', club: 'CF Montréal', number: 11, age: 30),
    ]),
    WC2026Team(code: 'JAM', name: 'Jamaica', flagCode: 'jm', group: 'C', coach: 'Heimir Hallgrímsson', fifaRanking: 43, squad: [
      WC2026Player(name: 'Andre Blake', position: 'GK', club: 'Philadelphia Union', number: 1, age: 33),
      WC2026Player(name: 'Bobby Reid', position: 'FWD', club: 'Fulham', number: 11, age: 31),
    ]),
    WC2026Team(code: 'VEN', name: 'Venezuela', flagCode: 've', group: 'D', coach: 'Fernando Batista', fifaRanking: 36, squad: [
      WC2026Player(name: 'Wuilker Faríñez', position: 'GK', club: 'Lens', number: 1, age: 27),
      WC2026Player(name: 'Salomón Rondón', position: 'FWD', club: 'Everton', number: 9, age: 34),
      WC2026Player(name: 'Yangel Herrera', position: 'MID', club: 'Girona', number: 10, age: 26),
    ]),
    WC2026Team(code: 'BEL', name: 'Belgium', flagCode: 'be', group: 'E', coach: 'Domenico Tedesco', fifaRanking: 3, squad: [
      WC2026Player(name: 'Thibaut Courtois', position: 'GK', club: 'Real Madrid', number: 1, age: 32),
      WC2026Player(name: 'Kevin De Bruyne', position: 'MID', club: 'Man City', number: 7, age: 35),
      WC2026Player(name: 'Romelu Lukaku', position: 'FWD', club: 'Napoli', number: 9, age: 33),
      WC2026Player(name: 'Lois Openda', position: 'FWD', club: 'RB Leipzig', number: 11, age: 24),
      WC2026Player(name: 'Arthur Vermeeren', position: 'MID', club: 'Atlético Madrid', number: 8, age: 19),
    ]),
    WC2026Team(code: 'CRO', name: 'Croatia', flagCode: 'hr', group: 'F', coach: 'Zlatko Dalić', fifaRanking: 10, squad: [
      WC2026Player(name: 'Dominik Livaković', position: 'GK', club: 'Fenerbahçe', number: 1, age: 29),
      WC2026Player(name: 'Luka Modrić', position: 'MID', club: 'Real Madrid', number: 10, age: 40),
      WC2026Player(name: 'Ivan Perišić', position: 'MID', club: 'Hajduk Split', number: 4, age: 35),
      WC2026Player(name: 'Mateo Kovačić', position: 'MID', club: 'Man City', number: 8, age: 31),
      WC2026Player(name: 'Ante Budimir', position: 'FWD', club: 'Osasuna', number: 9, age: 33),
    ]),
    WC2026Team(code: 'AUS', name: 'Australia', flagCode: 'au', group: 'G', coach: 'Tony Popovic', fifaRanking: 25, squad: [
      WC2026Player(name: 'Mat Ryan', position: 'GK', club: 'Real Sociedad', number: 1, age: 33),
      WC2026Player(name: 'Harry Souttar', position: 'DEF', club: 'Leicester City', number: 3, age: 25),
      WC2026Player(name: 'Mathew Leckie', position: 'FWD', club: 'Melbourne City', number: 7, age: 34),
      WC2026Player(name: 'Mitchell Duke', position: 'FWD', club: 'Fagiano Okayama', number: 9, age: 33),
    ]),
    WC2026Team(code: 'SUI', name: 'Switzerland', flagCode: 'ch', group: 'H', coach: 'Murat Yakin', fifaRanking: 19, squad: [
      WC2026Player(name: 'Yann Sommer', position: 'GK', club: 'Inter Milan', number: 1, age: 35),
      WC2026Player(name: 'Granit Xhaka', position: 'MID', club: 'Bayer Leverkusen', number: 10, age: 32),
      WC2026Player(name: 'Xherdan Shaqiri', position: 'FWD', club: 'Chicago Fire', number: 23, age: 32),
      WC2026Player(name: 'Breel Embolo', position: 'FWD', club: 'Monaco', number: 7, age: 27),
    ]),
    WC2026Team(code: 'POL', name: 'Poland', flagCode: 'pl', group: 'I', coach: 'Michał Probierz', fifaRanking: 29, squad: [
      WC2026Player(name: 'Wojciech Szczęsny', position: 'GK', club: 'Barcelona', number: 1, age: 35),
      WC2026Player(name: 'Robert Lewandowski', position: 'FWD', club: 'Barcelona', number: 9, age: 37),
      WC2026Player(name: 'Piotr Zieliński', position: 'MID', club: 'Inter Milan', number: 10, age: 30),
      WC2026Player(name: 'Nicola Zalewski', position: 'MID', club: 'Galatasaray', number: 17, age: 22),
    ]),
    WC2026Team(code: 'DEN', name: 'Denmark', flagCode: 'dk', group: 'J', coach: 'Lars Knudsen', fifaRanking: 21, squad: [
      WC2026Player(name: 'Kasper Schmeichel', position: 'GK', club: 'Anderlecht', number: 1, age: 38),
      WC2026Player(name: 'Christian Eriksen', position: 'MID', club: 'Man United', number: 10, age: 34),
      WC2026Player(name: 'Andreas Christensen', position: 'DEF', club: 'Barcelona', number: 6, age: 29),
      WC2026Player(name: 'Rasmus Højlund', position: 'FWD', club: 'Man United', number: 11, age: 22),
    ]),
    WC2026Team(code: 'AUT', name: 'Austria', flagCode: 'at', group: 'K', coach: 'Ralf Rangnick', fifaRanking: 24, squad: [
      WC2026Player(name: 'Patrick Pentz', position: 'GK', club: 'Girondins Bordeaux', number: 1, age: 27),
      WC2026Player(name: 'Marcel Sabitzer', position: 'MID', club: 'Man United', number: 7, age: 30),
      WC2026Player(name: 'David Alaba', position: 'DEF', club: 'Real Madrid', number: 4, age: 33),
      WC2026Player(name: 'Christoph Baumgartner', position: 'MID', club: 'RB Leipzig', number: 10, age: 25),
    ]),
    WC2026Team(code: 'TUR', name: 'Türkiye', flagCode: 'tr', group: 'L', coach: 'Vincenzo Montella', fifaRanking: 33, squad: [
      WC2026Player(name: 'Mert Günok', position: 'GK', club: 'Beşiktaş', number: 1, age: 35),
      WC2026Player(name: 'Hakan Çalhanoğlu', position: 'MID', club: 'Inter Milan', number: 10, age: 30),
      WC2026Player(name: 'Arda Güler', position: 'MID', club: 'Real Madrid', number: 11, age: 20),
      WC2026Player(name: 'Kerem Aktürkoğlu', position: 'FWD', club: 'Galatasaray', number: 7, age: 26),
    ]),
    WC2026Team(code: 'SAU', name: 'Saudi Arabia', flagCode: 'sa', group: 'A', coach: 'Hervé Renard', fifaRanking: 56, squad: [
      WC2026Player(name: 'Mohammed Al-Owais', position: 'GK', club: 'Al-Hilal', number: 1, age: 32),
      WC2026Player(name: 'Salem Al-Dawsari', position: 'FWD', club: 'Al-Hilal', number: 10, age: 32),
      WC2026Player(name: 'Saleh Al-Shehri', position: 'FWD', club: 'Al-Hilal', number: 9, age: 31),
    ]),
    WC2026Team(code: 'IRN', name: 'Iran', flagCode: 'ir', group: 'B', coach: 'Amir Ghalenoei', fifaRanking: 22, squad: [
      WC2026Player(name: 'Alireza Beiranvand', position: 'GK', club: 'Persepolis', number: 1, age: 32),
      WC2026Player(name: 'Mehdi Taremi', position: 'FWD', club: 'Inter Milan', number: 9, age: 32),
      WC2026Player(name: 'Sardar Azmoun', position: 'FWD', club: 'Bayer Leverkusen', number: 7, age: 29),
    ]),
    WC2026Team(code: 'NGA', name: 'Nigeria', flagCode: 'ng', group: 'C', coach: 'Finidi George', fifaRanking: 37, squad: [
      WC2026Player(name: 'Francis Uzoho', position: 'GK', club: 'Omonia', number: 1, age: 26),
      WC2026Player(name: 'Victor Osimhen', position: 'FWD', club: 'Napoli', number: 9, age: 25),
      WC2026Player(name: 'Wilfried Ndidi', position: 'MID', club: 'Leicester City', number: 4, age: 27),
      WC2026Player(name: 'Alex Iwobi', position: 'MID', club: 'Fulham', number: 17, age: 28),
    ]),
    WC2026Team(code: 'CMR', name: 'Cameroon', flagCode: 'cm', group: 'D', coach: 'Marc Brys', fifaRanking: 52, squad: [
      WC2026Player(name: 'André Onana', position: 'GK', club: 'Man United', number: 1, age: 28),
      WC2026Player(name: 'Vincent Aboubakar', position: 'FWD', club: 'Al-Qadsiah', number: 10, age: 32),
      WC2026Player(name: 'Eric Maxim Choupo-Moting', position: 'FWD', club: 'Bayern Munich', number: 13, age: 35),
    ]),
    WC2026Team(code: 'ITA', name: 'Italy', flagCode: 'it', group: 'E', coach: 'Luciano Spalletti', fifaRanking: 9, squad: [
      WC2026Player(name: 'Gianluigi Donnarumma', position: 'GK', club: 'PSG', number: 1, age: 26),
      WC2026Player(name: 'Federico Chiesa', position: 'FWD', club: 'Liverpool', number: 7, age: 26),
      WC2026Player(name: 'Sandro Tonali', position: 'MID', club: 'Newcastle', number: 8, age: 24),
      WC2026Player(name: 'Nicolo Barella', position: 'MID', club: 'Inter Milan', number: 18, age: 27),
      WC2026Player(name: 'Gianluca Scamacca', position: 'FWD', club: 'Atalanta', number: 9, age: 25),
    ]),
    WC2026Team(code: 'SRB', name: 'Serbia', flagCode: 'rs', group: 'F', coach: 'Dragan Stojković', fifaRanking: 33, squad: [
      WC2026Player(name: 'Predrag Rajković', position: 'GK', club: 'Mallorca', number: 1, age: 29),
      WC2026Player(name: 'Dušan Vlahović', position: 'FWD', club: 'Juventus', number: 9, age: 24),
      WC2026Player(name: 'Sergej Milinković-Savić', position: 'MID', club: 'Al-Hilal', number: 11, age: 29),
      WC2026Player(name: 'Aleksandar Mitrović', position: 'FWD', club: 'Al-Hilal', number: 10, age: 30),
    ]),
    WC2026Team(code: 'MEX', name: 'Mexico', flagCode: 'mx', group: 'B', coach: 'Javier Aguirre', fifaRanking: 16, squad: []),
    WC2026Team(code: 'GHA', name: 'Ghana', flagCode: 'gh', group: 'G', coach: 'Otto Addo', fifaRanking: 60, squad: [
      WC2026Player(name: 'Lawrence Ati-Zigi', position: 'GK', club: 'St. Gallen', number: 1, age: 27),
      WC2026Player(name: 'Jordan Ayew', position: 'FWD', club: 'Leicester City', number: 11, age: 32),
      WC2026Player(name: 'Mohammed Kudus', position: 'MID', club: 'West Ham', number: 10, age: 23),
    ]),
    WC2026Team(code: 'CRC', name: 'Costa Rica', flagCode: 'cr', group: 'H', coach: 'Gustavo Alfaro', fifaRanking: 55, squad: [
      WC2026Player(name: 'Keylor Navas', position: 'GK', club: 'PSG', number: 1, age: 37),
      WC2026Player(name: 'Bryan Ruiz', position: 'MID', club: 'Saprissa', number: 10, age: 38),
      WC2026Player(name: 'Joel Campbell', position: 'FWD', club: 'León', number: 7, age: 32),
    ]),
    WC2026Team(code: 'UKR', name: 'Ukraine', flagCode: 'ua', group: 'I', coach: 'Serhiy Rebrov', fifaRanking: 24, squad: [
      WC2026Player(name: 'Andriy Lunin', position: 'GK', club: 'Real Madrid', number: 1, age: 25),
      WC2026Player(name: 'Mykhailo Mudryk', position: 'FWD', club: 'Chelsea', number: 10, age: 23),
      WC2026Player(name: 'Victor Tsygankov', position: 'MID', club: 'Girona', number: 11, age: 26),
      WC2026Player(name: 'Oleksandr Zinchenko', position: 'DEF', club: 'Arsenal', number: 35, age: 27),
    ]),
    WC2026Team(code: 'EGY', name: 'Egypt', flagCode: 'eg', group: 'J', coach: 'Hossam El-Badry', fifaRanking: 35, squad: [
      WC2026Player(name: 'Mohamed El-Shennawy', position: 'GK', club: 'Al-Ahly', number: 1, age: 36),
      WC2026Player(name: 'Mohamed Salah', position: 'FWD', club: 'Liverpool', number: 11, age: 33),
      WC2026Player(name: 'Omar Marmoush', position: 'FWD', club: 'Man City', number: 7, age: 25),
    ]),
    WC2026Team(code: 'MLI', name: 'Mali', flagCode: 'ml', group: 'K', coach: 'Eric Sékou Chelle', fifaRanking: 57, squad: [
      WC2026Player(name: 'Ibrahim Mounkoro', position: 'GK', club: 'Genoa', number: 1, age: 24),
      WC2026Player(name: 'Amadou Haidara', position: 'MID', club: 'RB Leipzig', number: 8, age: 26),
      WC2026Player(name: 'Moussa Diaby', position: 'FWD', club: 'Aston Villa', number: 10, age: 25),
    ]),
    WC2026Team(code: 'IDN', name: 'Indonesia', flagCode: 'id', group: 'L', coach: 'Patrick Kluivert', fifaRanking: 130, squad: [
      WC2026Player(name: 'Ernando Ari', position: 'GK', club: 'Persebaya', number: 1, age: 23),
      WC2026Player(name: 'Marselino Ferdinan', position: 'MID', club: 'FK Brann', number: 10, age: 20),
      WC2026Player(name: 'Jay Idzes', position: 'DEF', club: 'Venezia', number: 4, age: 24),
    ]),
    WC2026Team(code: 'BOL', name: 'Bolivia', flagCode: 'bo', group: 'A', coach: 'Óscar Villegas', fifaRanking: 85, squad: [
      WC2026Player(name: 'Carlos Lampe', position: 'GK', club: 'Always Ready', number: 1, age: 36),
      WC2026Player(name: 'Marcelo Martins', position: 'FWD', club: 'Coritiba', number: 9, age: 35),
    ]),
    WC2026Team(code: 'PAR', name: 'Paraguay', flagCode: 'py', group: 'B', coach: 'Daniel Garnero', fifaRanking: 66, squad: [
      WC2026Player(name: 'Antony Silva', position: 'GK', club: 'San Lorenzo', number: 1, age: 39),
      WC2026Player(name: 'Miguel Almirón', position: 'MID', club: 'MLS', number: 10, age: 30),
    ]),
    WC2026Team(code: 'NZL', name: 'New Zealand', flagCode: 'nz', group: 'C', coach: 'Darren Bazeley', fifaRanking: 91, squad: [
      WC2026Player(name: 'Max Crocombe', position: 'GK', club: 'Hibernian', number: 1, age: 31),
      WC2026Player(name: 'Chris Wood', position: 'FWD', club: 'Nottm Forest', number: 9, age: 32),
      WC2026Player(name: 'Clayton Lewis', position: 'MID', club: 'Yokohama F.M.', number: 10, age: 27),
    ]),
    WC2026Team(code: 'ALG', name: 'Algeria', flagCode: 'dz', group: 'D', coach: 'Djamel Belmadi', fifaRanking: 32, squad: [
      WC2026Player(name: 'Raïs M\'Bolhi', position: 'GK', club: 'Al-Ettifaq', number: 1, age: 37),
      WC2026Player(name: 'Riyad Mahrez', position: 'FWD', club: 'Al-Ahli', number: 7, age: 35),
      WC2026Player(name: 'Islam Slimani', position: 'FWD', club: 'Al-Shabab', number: 9, age: 36),
    ]),
    WC2026Team(code: 'SVK', name: 'Slovakia', flagCode: 'sk', group: 'E', coach: 'Francesco Calzona', fifaRanking: 44, squad: [
      WC2026Player(name: 'Martin Dúbravka', position: 'GK', club: 'Newcastle', number: 1, age: 35),
      WC2026Player(name: 'Milan Škriniar', position: 'DEF', club: 'PSG', number: 5, age: 29),
      WC2026Player(name: 'Ondrej Duda', position: 'MID', club: 'Norwich', number: 10, age: 29),
    ]),
    WC2026Team(code: 'QAT', name: 'Qatar', flagCode: 'qa', group: 'F', coach: 'Marquez Lopez', fifaRanking: 37, squad: [
      WC2026Player(name: 'Meshaal Barsham', position: 'GK', club: 'Al-Sadd', number: 1, age: 25),
      WC2026Player(name: 'Akram Afif', position: 'FWD', club: 'Al-Sadd', number: 11, age: 27),
      WC2026Player(name: 'Almoez Ali', position: 'FWD', club: 'Al-Duhail', number: 9, age: 27),
    ]),
    WC2026Team(code: 'GRE', name: 'Greece', flagCode: 'gr', group: 'G', coach: 'Iván Jovanović', fifaRanking: 46, squad: [
      WC2026Player(name: 'Odysseas Vlachodimos', position: 'GK', club: 'Newcastle', number: 1, age: 30),
      WC2026Player(name: 'Anastasios Bakasetas', position: 'MID', club: 'Trabzonspor', number: 10, age: 30),
    ]),
    WC2026Team(code: 'TUN', name: 'Tunisia', flagCode: 'tn', group: 'H', coach: 'Jalel Kadri', fifaRanking: 30, squad: [
      WC2026Player(name: 'Aymen Dahmen', position: 'GK', club: 'Montpellier', number: 1, age: 28),
      WC2026Player(name: 'Anis Ben Slimane', position: 'MID', club: 'Brøndby', number: 10, age: 23),
      WC2026Player(name: 'Wahbi Khazri', position: 'FWD', club: 'Al-Qadsiah', number: 10, age: 33),
    ]),
    WC2026Team(code: 'HUN', name: 'Hungary', flagCode: 'hu', group: 'I', coach: 'Marco Rossi', fifaRanking: 28, squad: [
      WC2026Player(name: 'Péter Gulácsi', position: 'GK', club: 'RB Leipzig', number: 1, age: 34),
      WC2026Player(name: 'Dominik Szoboszlai', position: 'MID', club: 'Liverpool', number: 10, age: 23),
      WC2026Player(name: 'Roland Sallai', position: 'MID', club: 'Freiburg', number: 11, age: 27),
    ]),
    WC2026Team(code: 'CIV', name: "Côte d'Ivoire", flagCode: 'ci', group: 'J', coach: 'Emerse Faé', fifaRanking: 23, squad: [
      WC2026Player(name: 'Yahia Fofana', position: 'GK', club: 'Monaco', number: 1, age: 31),
      WC2026Player(name: 'Franck Kessie', position: 'MID', club: 'Al-Ahli', number: 5, age: 27),
      WC2026Player(name: 'Sébastien Haller', position: 'FWD', club: 'Borussia Dortmund', number: 9, age: 30),
      WC2026Player(name: 'Simon Adingra', position: 'FWD', club: 'Brighton', number: 11, age: 22),
    ]),
    WC2026Team(code: 'IRQ', name: 'Iraq', flagCode: 'iq', group: 'K', coach: 'Jesús Casas', fifaRanking: 63, squad: [
      WC2026Player(name: 'Jalal Hassan', position: 'GK', club: 'Al-Zawraa', number: 1, age: 29),
      WC2026Player(name: 'Amjad Attwan', position: 'MID', club: 'Al-Shorta', number: 10, age: 26),
    ]),
    WC2026Team(code: 'FJI', name: 'Fiji', flagCode: 'fj', group: 'L', coach: 'Rob Sherman', fifaRanking: 163, squad: [
      WC2026Player(name: 'Simione Tamanisau', position: 'GK', club: 'BA FC', number: 1, age: 28),
      WC2026Player(name: 'Roy Krishna', position: 'FWD', club: 'Auckland City', number: 10, age: 36),
    ]),
  ];

  // ─────────────────────────────────────────────────────────────────────────
  // TOURNAMENT INFO
  // ─────────────────────────────────────────────────────────────────────────
  static const Map<String, dynamic> tournamentInfo = {
    'name': 'FIFA World Cup 2026™',
    'startDate': '2026-06-11',
    'endDate': '2026-07-19',
    'totalTeams': 48,
    'totalMatches': 104,
    'totalGroups': 12,
    'teamsPerGroup': 4,
    'hostNations': ['United States', 'Canada', 'Mexico'],
    'format': '12 groups of 4 → top 2 + 8 best 3rd → R32 → R16 → QF → SF → Final',
    'defending': 'Argentina',
    'topScorer2022': 'Kylian Mbappé (8 goals)',
    'prizePool': '\$1 Billion USD',
  };
}
