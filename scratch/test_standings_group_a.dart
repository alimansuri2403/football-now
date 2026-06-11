import 'package:fifa2026_app/services/espn_api.dart';
import 'package:fifa2026_app/data/repository.dart';

void main() async {
  final api = EspnApiService();
  final fixtures = await api.fetchAllFixtures();
  final repo = MockDataRepository(getMatches: () => fixtures);

  final standings = await repo.getGroupStandings('A');
  print('Group A Standings:');
  for (final s in standings) {
    print('  ${s.team.name} (${s.team.code})');
  }
}
