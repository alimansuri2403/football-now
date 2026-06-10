import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fifa2026_app/models/models.dart';

class TournamentState {
  final List<Match> matches;
  final List<Team> teams;
  final List<Player> players;

  const TournamentState({
    required this.matches,
    required this.teams,
    required this.players,
  });

  TournamentState copyWith({
    List<Match>? matches,
    List<Team>? teams,
    List<Player>? players,
  }) {
    return TournamentState(
      matches: matches ?? this.matches,
      teams: teams ?? this.teams,
      players: players ?? this.players,
    );
  }
}

class TournamentNotifier extends StateNotifier<TournamentState> {
  Timer? _timer;
  final Random _random = Random();

  TournamentNotifier() : super(_initialState()) {
    _startSimulation();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startSimulation() {
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      _tick();
    });
  }

  void _tick() {
    bool stateChanged = false;
    List<Match> updatedMatches = List.from(state.matches);
    List<Player> updatedPlayers = List.from(state.players);
    List<Team> updatedTeams = List.from(state.teams);

    for (int i = 0; i < updatedMatches.length; i++) {
      final match = updatedMatches[i];
      if (match.status == MatchStatus.live) {
        stateChanged = true;
        int nextMinute = match.minute + 3;
        MatchStatus nextStatus = match.status;
        int homeScore = match.homeScore;
        int awayScore = match.awayScore;
        List<MatchEvent> events = List.from(match.events);

        // Stats updates
        int possessionHome = match.possessionHome;
        int possessionAway = match.possessionAway;
        int shotsHome = match.shotsHome;
        int shotsAway = match.shotsAway;
        int shotsOnTargetHome = match.shotsOnTargetHome;
        int shotsOnTargetAway = match.shotsOnTargetAway;
        int cornersHome = match.cornersHome;
        int cornersAway = match.cornersAway;
        int foulsHome = match.foulsHome;
        int foulsAway = match.foulsAway;
        int yellowCardsHome = match.yellowCardsHome;
        int yellowCardsAway = match.yellowCardsAway;
        int redCardsHome = match.redCardsHome;
        int redCardsAway = match.redCardsAway;

        // Fluctuating possession slightly
        int possessionDelta = _random.nextInt(5) - 2; // -2 to +2
        possessionHome = (possessionHome + possessionDelta).clamp(30, 70);
        possessionAway = 100 - possessionHome;

        // Occasional actions
        bool isHomeAction = _random.nextBool();
        int actionChance = _random.nextInt(100);

        if (actionChance < 15) {
          // Shot attempt
          if (isHomeAction) {
            shotsHome++;
            if (_random.nextBool()) shotsOnTargetHome++;
          } else {
            shotsAway++;
            if (_random.nextBool()) shotsOnTargetAway++;
          }
        }

        if (actionChance < 8) {
          // Foul
          if (isHomeAction) {
            foulsHome++;
          } else {
            foulsAway++;
          }
        }

        if (actionChance < 4) {
          // Corner
          if (isHomeAction) {
            cornersHome++;
          } else {
            cornersAway++;
          }
        }

        // Random Goal (8% chance per tick if shot is on target or general chance)
        if (actionChance < 4) {
          final isHomeScorer = _random.nextBool();
          final scoringTeam = isHomeScorer ? match.homeTeam : match.awayTeam;
          final concedingTeam = isHomeScorer ? match.awayTeam : match.homeTeam;
          final squad = isHomeScorer ? match.homeLineup : match.awayLineup;

          if (squad.isNotEmpty) {
            // Pick a scorer, biased towards Forwards and Midfielders
            final scorerIndex = _random.nextInt(squad.length);
            final scorer = squad[scorerIndex];

            // Pick an assist (different player from squad)
            Player? assister;
            if (squad.length > 1 && _random.nextBool()) {
              int assisterIndex = _random.nextInt(squad.length);
              while (assisterIndex == scorerIndex) {
                assisterIndex = _random.nextInt(squad.length);
              }
              assister = squad[assisterIndex];
            }

            if (isHomeScorer) {
              homeScore++;
            } else {
              awayScore++;
            }

            // Create Event
            final eventId = 'ev_${match.id}_$nextMinute';
            events.add(MatchEvent(
              id: eventId,
              type: MatchEventType.goal,
              minute: nextMinute,
              player1: scorer.name,
              player2: assister?.name,
              detail: _random.nextInt(10) == 0 ? 'Penalty Goal' : 'Goal',
              isHomeTeam: isHomeScorer,
            ));

            // Update player goals/assists in current list
            for (int p = 0; p < updatedPlayers.length; p++) {
              if (updatedPlayers[p].id == scorer.id) {
                updatedPlayers[p] = Player(
                  id: updatedPlayers[p].id,
                  name: updatedPlayers[p].name,
                  teamId: updatedPlayers[p].teamId,
                  teamName: updatedPlayers[p].teamName,
                  position: updatedPlayers[p].position,
                  goals: updatedPlayers[p].goals + 1,
                  assists: updatedPlayers[p].assists,
                  matchesPlayed: updatedPlayers[p].matchesPlayed,
                  rating: (updatedPlayers[p].rating + 0.4).clamp(5.0, 10.0),
                  imageUrl: updatedPlayers[p].imageUrl,
                  attributes: updatedPlayers[p].attributes,
                );
              }
              if (assister != null && updatedPlayers[p].id == assister.id) {
                updatedPlayers[p] = Player(
                  id: updatedPlayers[p].id,
                  name: updatedPlayers[p].name,
                  teamId: updatedPlayers[p].teamId,
                  teamName: updatedPlayers[p].teamName,
                  position: updatedPlayers[p].position,
                  goals: updatedPlayers[p].goals,
                  assists: updatedPlayers[p].assists + 1,
                  matchesPlayed: updatedPlayers[p].matchesPlayed,
                  rating: (updatedPlayers[p].rating + 0.2).clamp(5.0, 10.0),
                  imageUrl: updatedPlayers[p].imageUrl,
                  attributes: updatedPlayers[p].attributes,
                );
              }
            }
          }
        } else if (actionChance < 6) {
          // Yellow Card
          final isHomeCard = _random.nextBool();
          final squad = isHomeCard ? match.homeLineup : match.awayLineup;
          if (squad.isNotEmpty) {
            final player = squad[_random.nextInt(squad.length)];
            if (isHomeCard) {
              yellowCardsHome++;
            } else {
              yellowCardsAway++;
            }

            events.add(MatchEvent(
              id: 'ev_yc_${match.id}_$nextMinute',
              type: MatchEventType.card,
              minute: nextMinute,
              player1: player.name,
              detail: 'Yellow Card',
              isHomeTeam: isHomeCard,
            ));
          }
        } else if (actionChance < 7) {
          // Substitution
          final isHomeSub = _random.nextBool();
          final squad = isHomeSub ? match.homeLineup : match.awayLineup;
          if (squad.isNotEmpty) {
            final pOut = squad[_random.nextInt(squad.length)];
            final pInName = _random.nextBool() ? 'Martínez' : 'Smith';
            events.add(MatchEvent(
              id: 'ev_sub_${match.id}_$nextMinute',
              type: MatchEventType.substitution,
              minute: nextMinute,
              player1: pOut.name,
              player2: pInName,
              detail: 'Substitution',
              isHomeTeam: isHomeSub,
            ));
          }
        }

        // Check if Match finished
        if (nextMinute >= 90) {
          nextMinute = 90;
          nextStatus = MatchStatus.finished;

          // Update standings in the Group
          _updateStandings(
            teams: updatedTeams,
            homeId: match.homeTeam.id,
            awayId: match.awayTeam.id,
            homeScore: homeScore,
            awayScore: awayScore,
          );

          // Activate another match!
          _activateNextMatch(updatedMatches);
        }

        updatedMatches[i] = match.copyWith(
          homeScore: homeScore,
          awayScore: awayScore,
          status: nextStatus,
          minute: nextMinute,
          possessionHome: possessionHome,
          possessionAway: possessionAway,
          shotsHome: shotsHome,
          shotsAway: shotsAway,
          shotsOnTargetHome: shotsOnTargetHome,
          shotsOnTargetAway: shotsOnTargetAway,
          cornersHome: cornersHome,
          cornersAway: cornersAway,
          foulsHome: foulsHome,
          foulsAway: foulsAway,
          yellowCardsHome: yellowCardsHome,
          yellowCardsAway: yellowCardsAway,
          redCardsHome: redCardsHome,
          redCardsAway: redCardsAway,
          events: events,
        );
      }
    }

    if (stateChanged) {
      state = state.copyWith(
        matches: updatedMatches,
        players: updatedPlayers,
        teams: updatedTeams,
      );
    }
  }

  void _updateStandings({
    required List<Team> teams,
    required String homeId,
    required String awayId,
    required int homeScore,
    required int awayScore,
  }) {
    for (int i = 0; i < teams.length; i++) {
      final t = teams[i];
      if (t.id == homeId) {
        int won = t.won + (homeScore > awayScore ? 1 : 0);
        int drawn = t.drawn + (homeScore == awayScore ? 1 : 0);
        int lost = t.lost + (homeScore < awayScore ? 1 : 0);
        int points = t.points + (homeScore > awayScore ? 3 : (homeScore == awayScore ? 1 : 0));
        teams[i] = t.copyWith(
          played: t.played + 1,
          won: won,
          drawn: drawn,
          lost: lost,
          goalsFor: t.goalsFor + homeScore,
          goalsAgainst: t.goalsAgainst + awayScore,
          points: points,
        );
      } else if (t.id == awayId) {
        int won = t.won + (awayScore > homeScore ? 1 : 0);
        int drawn = t.drawn + (awayScore == homeScore ? 1 : 0);
        int lost = t.lost + (awayScore < homeScore ? 1 : 0);
        int points = t.points + (awayScore > homeScore ? 3 : (awayScore == homeScore ? 1 : 0));
        teams[i] = t.copyWith(
          played: t.played + 1,
          won: won,
          drawn: drawn,
          lost: lost,
          goalsFor: t.goalsFor + awayScore,
          goalsAgainst: t.goalsAgainst + homeScore,
          points: points,
        );
      }
    }
  }

  void _activateNextMatch(List<Match> matches) {
    for (int i = 0; i < matches.length; i++) {
      if (matches[i].status == MatchStatus.upcoming) {
        matches[i] = matches[i].copyWith(
          status: MatchStatus.live,
          minute: 0,
          homeScore: 0,
          awayScore: 0,
          events: [],
        );
        break;
      }
    }
  }

  static TournamentState _initialState() {
    // 48 teams, 12 groups A to L
    final List<Team> initialTeams = [];
    final List<String> groupNames = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L'];
    
    final Map<String, List<Map<String, String>>> groupTeamsData = {
      'A': [
        {'id': 't_usa', 'name': 'United States', 'code': 'US'},
        {'id': 't_mex', 'name': 'Mexico', 'code': 'MX'},
        {'id': 't_can', 'name': 'Canada', 'code': 'CA'},
        {'id': 't_jam', 'name': 'Jamaica', 'code': 'JM'},
      ],
      'B': [
        {'id': 't_arg', 'name': 'Argentina', 'code': 'AR'},
        {'id': 't_pol', 'name': 'Poland', 'code': 'PL'},
        {'id': 't_ksa', 'name': 'Saudi Arabia', 'code': 'SA'},
        {'id': 't_rsa', 'name': 'South Africa', 'code': 'ZA'},
      ],
      'C': [
        {'id': 't_fra', 'name': 'France', 'code': 'FR'},
        {'id': 't_den', 'name': 'Denmark', 'code': 'DK'},
        {'id': 't_tun', 'name': 'Tunisia', 'code': 'TN'},
        {'id': 't_aus', 'name': 'Australia', 'code': 'AU'},
      ],
      'D': [
        {'id': 't_bra', 'name': 'Brazil', 'code': 'BR'},
        {'id': 't_sui', 'name': 'Switzerland', 'code': 'CH'},
        {'id': 't_srb', 'name': 'Serbia', 'code': 'RS'},
        {'id': 't_cmr', 'name': 'Cameroon', 'code': 'CM'},
      ],
      'E': [
        {'id': 't_eng', 'name': 'England', 'code': 'GB-ENG'},
        {'id': 't_sen', 'name': 'Senegal', 'code': 'SN'},
        {'id': 't_irn', 'name': 'Iran', 'code': 'IR'},
        {'id': 't_ecu', 'name': 'Ecuador', 'code': 'EC'},
      ],
      'F': [
        {'id': 't_bel', 'name': 'Belgium', 'code': 'BE'},
        {'id': 't_cro', 'name': 'Croatia', 'code': 'HR'},
        {'id': 't_mar', 'name': 'Morocco', 'code': 'MA'},
        {'id': 't_irq', 'name': 'Iraq', 'code': 'IQ'},
      ],
      'G': [
        {'id': 't_esp', 'name': 'Spain', 'code': 'ES'},
        {'id': 't_ger', 'name': 'Germany', 'code': 'DE'},
        {'id': 't_jpn', 'name': 'Japan', 'code': 'JP'},
        {'id': 't_crc', 'name': 'Costa Rica', 'code': 'CR'},
      ],
      'H': [
        {'id': 't_por', 'name': 'Portugal', 'code': 'PT'},
        {'id': 't_uru', 'name': 'Uruguay', 'code': 'UY'},
        {'id': 't_gha', 'name': 'Ghana', 'code': 'GH'},
        {'id': 't_kor', 'name': 'South Korea', 'code': 'KR'},
      ],
      'I': [
        {'id': 't_ita', 'name': 'Italy', 'code': 'IT'},
        {'id': 't_col', 'name': 'Colombia', 'code': 'CO'},
        {'id': 't_swe', 'name': 'Sweden', 'code': 'SE'},
        {'id': 't_nga', 'name': 'Nigeria', 'code': 'NG'},
      ],
      'J': [
        {'id': 't_ned', 'name': 'Netherlands', 'code': 'NL'},
        {'id': 't_chi', 'name': 'Chile', 'code': 'CL'},
        {'id': 't_alg', 'name': 'Algeria', 'code': 'DZ'},
        {'id': 't_nzl', 'name': 'New Zealand', 'code': 'NZ'},
      ],
      'K': [
        {'id': 't_ukr', 'name': 'Ukraine', 'code': 'UA'},
        {'id': 't_per', 'name': 'Peru', 'code': 'PE'},
        {'id': 't_civ', 'name': 'Ivory Coast', 'code': 'CI'},
        {'id': 't_uae', 'name': 'United Arab Emirates', 'code': 'AE'},
      ],
      'L': [
        {'id': 't_wal', 'name': 'Wales', 'code': 'GB-WLS'},
        {'id': 't_nor', 'name': 'Norway', 'code': 'NO'},
        {'id': 't_egy', 'name': 'Egypt', 'code': 'EG'},
        {'id': 't_pan', 'name': 'Panama', 'code': 'PA'},
      ],
    };

    // Initialize Teams with flags and some semi-random initial standings
    // so table is not empty at start
    final Random random = Random();
    groupTeamsData.forEach((groupLetter, teams) {
      for (var teamData in teams) {
        final played = 2;
        final won = random.nextInt(2);
        final drawn = random.nextInt(played - won + 1);
        final lost = played - won - drawn;
        final goalsFor = won * 2 + drawn + random.nextInt(3);
        final goalsAgainst = lost * 2 + drawn + random.nextInt(2);
        final points = won * 3 + drawn;

        initialTeams.add(Team(
          id: teamData['id']!,
          name: teamData['name']!,
          code: teamData['code']!,
          flagUrl: 'https://flagcdn.com/w160/${teamData['code']!.toLowerCase()}.png',
          groupName: 'Group $groupLetter',
          played: played,
          won: won,
          drawn: drawn,
          lost: lost,
          goalsFor: goalsFor,
          goalsAgainst: goalsAgainst,
          points: points,
        ));
      }
    });

    // Seed top players with attributes
    final List<Player> initialPlayers = [
      Player(
        id: 'p_messi',
        name: 'Lionel Messi',
        teamId: 't_arg',
        teamName: 'Argentina',
        position: 'Forward',
        goals: 5,
        assists: 3,
        matchesPlayed: 4,
        rating: 9.2,
        imageUrl: 'https://images.unsplash.com/photo-1544642899-7069eb16a4e9?w=150&q=80',
        attributes: {'PAC': 80, 'SHO': 91, 'PAS': 94, 'DRI': 95, 'DEF': 35, 'PHY': 65},
      ),
      Player(
        id: 'p_mbappe',
        name: 'Kylian Mbappé',
        teamId: 't_fra',
        teamName: 'France',
        position: 'Forward',
        goals: 6,
        assists: 2,
        matchesPlayed: 4,
        rating: 9.4,
        imageUrl: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=150&q=80',
        attributes: {'PAC': 97, 'SHO': 90, 'PAS': 80, 'DRI': 92, 'DEF': 36, 'PHY': 78},
      ),
      Player(
        id: 'p_haaland',
        name: 'Erling Haaland',
        teamId: 't_nor',
        teamName: 'Norway',
        position: 'Forward',
        goals: 4,
        assists: 1,
        matchesPlayed: 3,
        rating: 9.1,
        imageUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150&q=80',
        attributes: {'PAC': 89, 'SHO': 93, 'PAS': 65, 'DRI': 80, 'DEF': 40, 'PHY': 88},
      ),
      Player(
        id: 'p_bellingham',
        name: 'Jude Bellingham',
        teamId: 't_eng',
        teamName: 'England',
        position: 'Midfielder',
        goals: 3,
        assists: 3,
        matchesPlayed: 4,
        rating: 9.0,
        imageUrl: 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=150&q=80',
        attributes: {'PAC': 79, 'SHO': 82, 'PAS': 88, 'DRI': 89, 'DEF': 78, 'PHY': 82},
      ),
      Player(
        id: 'p_vinicius',
        name: 'Vinícius Júnior',
        teamId: 't_bra',
        teamName: 'Brazil',
        position: 'Forward',
        goals: 3,
        assists: 4,
        matchesPlayed: 4,
        rating: 8.9,
        imageUrl: 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=150&q=80',
        attributes: {'PAC': 95, 'SHO': 84, 'PAS': 80, 'DRI': 92, 'DEF': 30, 'PHY': 68},
      ),
      Player(
        id: 'p_debruyne',
        name: 'Kevin De Bruyne',
        teamId: 't_bel',
        teamName: 'Belgium',
        position: 'Midfielder',
        goals: 1,
        assists: 5,
        matchesPlayed: 3,
        rating: 8.8,
        imageUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&q=80',
        attributes: {'PAC': 72, 'SHO': 88, 'PAS': 95, 'DRI': 87, 'DEF': 65, 'PHY': 74},
      ),
      Player(
        id: 'p_ronaldo',
        name: 'Cristiano Ronaldo',
        teamId: 't_por',
        teamName: 'Portugal',
        position: 'Forward',
        goals: 3,
        assists: 1,
        matchesPlayed: 4,
        rating: 8.5,
        imageUrl: 'https://images.unsplash.com/photo-1628157582853-a796fa650a6a?w=150&q=80',
        attributes: {'PAC': 78, 'SHO': 89, 'PAS': 78, 'DRI': 80, 'DEF': 30, 'PHY': 75},
      ),
      Player(
        id: 'p_saka',
        name: 'Bukayo Saka',
        teamId: 't_eng',
        teamName: 'England',
        position: 'Forward',
        goals: 2,
        assists: 4,
        matchesPlayed: 4,
        rating: 8.7,
        imageUrl: 'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?w=150&q=80',
        attributes: {'PAC': 88, 'SHO': 83, 'PAS': 82, 'DRI': 89, 'DEF': 55, 'PHY': 68},
      ),
      Player(
        id: 'p_salah',
        name: 'Mohamed Salah',
        teamId: 't_egy',
        teamName: 'Egypt',
        position: 'Forward',
        goals: 4,
        assists: 2,
        matchesPlayed: 3,
        rating: 8.8,
        imageUrl: 'https://images.unsplash.com/photo-1560250097-0b93528c311a?w=150&q=80',
        attributes: {'PAC': 89, 'SHO': 87, 'PAS': 83, 'DRI': 88, 'DEF': 45, 'PHY': 72},
      ),
      Player(
        id: 'p_musiala',
        name: 'Jamal Musiala',
        teamId: 't_ger',
        teamName: 'Germany',
        position: 'Midfielder',
        goals: 2,
        assists: 3,
        matchesPlayed: 4,
        rating: 8.9,
        imageUrl: 'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?w=150&q=80',
        attributes: {'PAC': 84, 'SHO': 81, 'PAS': 86, 'DRI': 93, 'DEF': 60, 'PHY': 68},
      ),
    ];

    // Seed squads with generic player representations so lineup comparisons work
    final Map<String, List<Player>> teamSquads = {};
    for (var team in initialTeams) {
      // Find seeded players first
      final List<Player> squad = initialPlayers.where((p) => p.teamId == team.id).toList();
      
      // Pad squad to 11 players
      final positions = ['Goalkeeper', 'Defender', 'Defender', 'Defender', 'Defender', 'Midfielder', 'Midfielder', 'Midfielder', 'Forward', 'Forward', 'Forward'];
      int idGen = 1;
      while (squad.length < 11) {
        final pos = positions[squad.length % positions.length];
        squad.add(Player(
          id: 'p_${team.id}_$idGen',
          name: '${team.name.split(' ').first} Player $idGen',
          teamId: team.id,
          teamName: team.name,
          position: pos,
          goals: 0,
          assists: 0,
          matchesPlayed: 2,
          rating: 6.0 + random.nextDouble() * 3,
          imageUrl: 'https://images.unsplash.com/photo-1508098682722-e99c43a406b2?w=150&q=80',
          attributes: {
            'PAC': 60 + random.nextDouble() * 35,
            'SHO': 50 + random.nextDouble() * 45,
            'PAS': 55 + random.nextDouble() * 40,
            'DRI': 55 + random.nextDouble() * 40,
            'DEF': 40 + random.nextDouble() * 50,
            'PHY': 60 + random.nextDouble() * 35,
          },
        ));
        idGen++;
      }
      teamSquads[team.id] = squad;
    }

    // Add all dummy players to main player list so we have full team lists
    for (var squad in teamSquads.values) {
      for (var player in squad) {
        if (!initialPlayers.any((p) => p.id == player.id)) {
          initialPlayers.add(player);
        }
      }
    }

    // Helper to find team
    Team findT(String id) => initialTeams.firstWhere((t) => t.id == id);

    // Initial Matches
    final DateTime now = DateTime.now();
    final List<Match> initialMatches = [
      // Live Match 1
      Match(
        id: 'm_1',
        homeTeam: findT('t_usa'),
        awayTeam: findT('t_mex'),
        homeScore: 1,
        awayScore: 1,
        status: MatchStatus.live,
        minute: 48,
        date: now.subtract(const Duration(minutes: 48)),
        stage: 'Group Stage - Group A',
        stadium: 'MetLife Stadium, New York',
        possessionHome: 52,
        possessionAway: 48,
        shotsHome: 6,
        shotsAway: 5,
        shotsOnTargetHome: 3,
        shotsOnTargetAway: 2,
        cornersHome: 4,
        cornersAway: 3,
        foulsHome: 8,
        foulsAway: 10,
        yellowCardsHome: 1,
        yellowCardsAway: 2,
        events: [
          MatchEvent(
            id: 'ev_m1_1',
            type: MatchEventType.goal,
            minute: 12,
            player1: teamSquads['t_usa']![8].name,
            detail: 'Goal',
            isHomeTeam: true,
          ),
          MatchEvent(
            id: 'ev_m1_2',
            type: MatchEventType.goal,
            minute: 34,
            player1: teamSquads['t_mex']![9].name,
            detail: 'Goal',
            isHomeTeam: false,
          ),
        ],
        homeLineup: teamSquads['t_usa']!,
        awayLineup: teamSquads['t_mex']!,
      ),
      // Live Match 2
      Match(
        id: 'm_2',
        homeTeam: findT('t_arg'),
        awayTeam: findT('t_pol'),
        homeScore: 2,
        awayScore: 0,
        status: MatchStatus.live,
        minute: 72,
        date: now.subtract(const Duration(minutes: 72)),
        stage: 'Group Stage - Group B',
        stadium: 'SoFi Stadium, Los Angeles',
        possessionHome: 64,
        possessionAway: 36,
        shotsHome: 12,
        shotsAway: 3,
        shotsOnTargetHome: 7,
        shotsOnTargetAway: 1,
        cornersHome: 8,
        cornersAway: 2,
        foulsHome: 5,
        foulsAway: 12,
        yellowCardsHome: 0,
        yellowCardsAway: 1,
        events: [
          MatchEvent(
            id: 'ev_m2_1',
            type: MatchEventType.goal,
            minute: 22,
            player1: 'Lionel Messi',
            detail: 'Penalty Goal',
            isHomeTeam: true,
          ),
          MatchEvent(
            id: 'ev_m2_2',
            type: MatchEventType.goal,
            minute: 55,
            player1: 'Lionel Messi',
            player2: teamSquads['t_arg']![5].name, // Assist
            detail: 'Goal',
            isHomeTeam: true,
          ),
        ],
        homeLineup: teamSquads['t_arg']!,
        awayLineup: teamSquads['t_pol']!,
      ),
      // Live Match 3
      Match(
        id: 'm_3',
        homeTeam: findT('t_fra'),
        awayTeam: findT('t_den'),
        homeScore: 0,
        awayScore: 1,
        status: MatchStatus.live,
        minute: 28,
        date: now.subtract(const Duration(minutes: 28)),
        stage: 'Group Stage - Group C',
        stadium: 'Mercedes-Benz Stadium, Atlanta',
        possessionHome: 48,
        possessionAway: 52,
        shotsHome: 4,
        shotsAway: 6,
        shotsOnTargetHome: 1,
        shotsOnTargetAway: 4,
        cornersHome: 2,
        cornersAway: 5,
        foulsHome: 7,
        foulsAway: 6,
        yellowCardsHome: 1,
        yellowCardsAway: 0,
        events: [
          MatchEvent(
            id: 'ev_m3_1',
            type: MatchEventType.goal,
            minute: 18,
            player1: teamSquads['t_den']![8].name,
            detail: 'Goal',
            isHomeTeam: false,
          ),
        ],
        homeLineup: teamSquads['t_fra']!,
        awayLineup: teamSquads['t_den']!,
      ),

      // Upcoming Matches
      Match(
        id: 'm_4',
        homeTeam: findT('t_bra'),
        awayTeam: findT('t_sui'),
        date: now.add(const Duration(hours: 4)),
        stage: 'Group Stage - Group D',
        stadium: 'AT&T Stadium, Dallas',
        homeLineup: teamSquads['t_bra']!,
        awayLineup: teamSquads['t_sui']!,
      ),
      Match(
        id: 'm_5',
        homeTeam: findT('t_eng'),
        awayTeam: findT('t_sen'),
        date: now.add(const Duration(hours: 8)),
        stage: 'Group Stage - Group E',
        stadium: 'Hard Rock Stadium, Miami',
        homeLineup: teamSquads['t_eng']!,
        awayLineup: teamSquads['t_sen']!,
      ),
      Match(
        id: 'm_6',
        homeTeam: findT('t_esp'),
        awayTeam: findT('t_ger'),
        date: now.add(const Duration(hours: 12)),
        stage: 'Group Stage - Group G',
        stadium: 'NRG Stadium, Houston',
        homeLineup: teamSquads['t_esp']!,
        awayLineup: teamSquads['t_ger']!,
      ),
      Match(
        id: 'm_7',
        homeTeam: findT('t_por'),
        awayTeam: findT('t_uru'),
        date: now.add(const Duration(days: 1, hours: 2)),
        stage: 'Group Stage - Group H',
        stadium: 'Gillette Stadium, Boston',
        homeLineup: teamSquads['t_por']!,
        awayLineup: teamSquads['t_uru']!,
      ),
      Match(
        id: 'm_8',
        homeTeam: findT('t_ita'),
        awayTeam: findT('t_col'),
        date: now.add(const Duration(days: 1, hours: 6)),
        stage: 'Group Stage - Group I',
        stadium: 'Lumen Field, Seattle',
        homeLineup: teamSquads['t_ita']!,
        awayLineup: teamSquads['t_col']!,
      ),
      Match(
        id: 'm_9',
        homeTeam: findT('t_ned'),
        awayTeam: findT('t_chi'),
        date: now.add(const Duration(days: 1, hours: 10)),
        stage: 'Group Stage - Group J',
        stadium: 'Levi Stadium, San Francisco',
        homeLineup: teamSquads['t_ned']!,
        awayLineup: teamSquads['t_chi']!,
      ),

      // Finished Matches
      Match(
        id: 'm_10',
        homeTeam: findT('t_can'),
        awayTeam: findT('t_jam'),
        homeScore: 2,
        awayScore: 1,
        status: MatchStatus.finished,
        minute: 90,
        date: now.subtract(const Duration(hours: 6)),
        stage: 'Group Stage - Group A',
        stadium: 'BC Place, Vancouver',
        possessionHome: 58,
        possessionAway: 42,
        shotsHome: 14,
        shotsAway: 8,
        shotsOnTargetHome: 6,
        shotsOnTargetAway: 3,
        cornersHome: 5,
        cornersAway: 3,
        foulsHome: 11,
        foulsAway: 15,
        yellowCardsHome: 2,
        yellowCardsAway: 3,
        events: [
          MatchEvent(
            id: 'ev_m10_1',
            type: MatchEventType.goal,
            minute: 20,
            player1: teamSquads['t_can']![8].name,
            detail: 'Goal',
            isHomeTeam: true,
          ),
          MatchEvent(
            id: 'ev_m10_2',
            type: MatchEventType.goal,
            minute: 45,
            player1: teamSquads['t_jam']![8].name,
            detail: 'Goal',
            isHomeTeam: false,
          ),
          MatchEvent(
            id: 'ev_m10_3',
            type: MatchEventType.goal,
            minute: 78,
            player1: teamSquads['t_can']![9].name,
            detail: 'Goal',
            isHomeTeam: true,
          ),
        ],
        homeLineup: teamSquads['t_can']!,
        awayLineup: teamSquads['t_jam']!,
      ),
      Match(
        id: 'm_11',
        homeTeam: findT('t_ksa'),
        awayTeam: findT('t_rsa'),
        homeScore: 0,
        awayScore: 0,
        status: MatchStatus.finished,
        minute: 90,
        date: now.subtract(const Duration(hours: 10)),
        stage: 'Group Stage - Group B',
        stadium: 'Estadio Azteca, Mexico City',
        possessionHome: 49,
        possessionAway: 51,
        shotsHome: 9,
        shotsAway: 10,
        cornersHome: 4,
        cornersAway: 4,
        events: [],
        homeLineup: teamSquads['t_ksa']!,
        awayLineup: teamSquads['t_rsa']!,
      ),
    ];

    return TournamentState(
      matches: initialMatches,
      teams: initialTeams,
      players: initialPlayers,
    );
  }
}

// StateNotifierProvider
final tournamentProvider = StateNotifierProvider<TournamentNotifier, TournamentState>((ref) {
  return TournamentNotifier();
});

// Computed Providers
final liveMatchesProvider = Provider<List<Match>>((ref) {
  final state = ref.watch(tournamentProvider);
  return state.matches.where((m) => m.status == MatchStatus.live).toList();
});

final upcomingMatchesProvider = Provider<List<Match>>((ref) {
  final state = ref.watch(tournamentProvider);
  return state.matches.where((m) => m.status == MatchStatus.upcoming).toList();
});

final finishedMatchesProvider = Provider<List<Match>>((ref) {
  final state = ref.watch(tournamentProvider);
  return state.matches.where((m) => m.status == MatchStatus.finished).toList();
});

final matchDetailProvider = Provider.family<Match?, String>((ref, matchId) {
  final state = ref.watch(tournamentProvider);
  final list = state.matches.where((m) => m.id == matchId);
  return list.isNotEmpty ? list.first : null;
});

final teamsProvider = Provider<List<Team>>((ref) {
  final state = ref.watch(tournamentProvider);
  return state.teams;
});

final teamDetailProvider = Provider.family<Team?, String>((ref, teamId) {
  final state = ref.watch(tournamentProvider);
  final list = state.teams.where((t) => t.id == teamId);
  return list.isNotEmpty ? list.first : null;
});

final teamSquadProvider = Provider.family<List<Player>, String>((ref, teamId) {
  final state = ref.watch(tournamentProvider);
  return state.players.where((p) => p.teamId == teamId).toList();
});

final teamScheduleProvider = Provider.family<List<Match>, String>((ref, teamId) {
  final state = ref.watch(tournamentProvider);
  return state.matches.where((m) => m.homeTeam.id == teamId || m.awayTeam.id == teamId).toList();
});

final playersProvider = Provider<List<Player>>((ref) {
  final state = ref.watch(tournamentProvider);
  return state.players;
});

final playerDetailProvider = Provider.family<Player?, String>((ref, playerId) {
  final state = ref.watch(tournamentProvider);
  final list = state.players.where((p) => p.id == playerId);
  return list.isNotEmpty ? list.first : null;
});
