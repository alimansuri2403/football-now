import 'package:fifa2026_app/services/espn_api.dart';
import 'package:fifa2026_app/data/repository.dart';

void main() async {
  final api = EspnApiService();
  print('Fetching fixtures from ESPN...');
  final fixtures = await api.fetchAllFixtures();
  print('Fetched ${fixtures.length} fixtures.');

  final repo = MockDataRepository(getMatches: () => fixtures);
  final teams = await repo.getTeams();
  print('Loaded ${teams.length} teams from repository.');

  for (final group in ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L']) {
    final standings = await repo.getGroupStandings(group);
    print('\n--- Group $group Standings ---');
    for (final s in standings) {
      print('  ${s.team.name.padRight(20)} (${s.team.code}) | P:${s.played} W:${s.won} D:${s.drawn} L:${s.lost} GD:${s.goalDifference.toString().padLeft(2)} PTS:${s.points}');
    }
  }
}
