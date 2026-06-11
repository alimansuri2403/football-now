import 'package:fifa2026_app/services/espn_api.dart';
import 'package:fifa2026_app/data/repository.dart';
import 'package:fifa2026_app/models/match.dart';

void main() async {
  final api = EspnApiService();
  final fixtures = await api.fetchAllFixtures();
  print('Total fixtures: ${fixtures.length}');

  // Find a finished fixture
  final finishedFixtures = fixtures.where((m) => m.status == MatchStatus.finished).toList();
  print('Finished fixtures count: ${finishedFixtures.length}');

  if (finishedFixtures.isNotEmpty) {
    final first = finishedFixtures.first;
    print('\nFirst finished match details:');
    print('  ID: ${first.id}');
    print('  Home: ${first.homeTeam.name} (Code: ${first.homeTeam.code}, ID: ${first.homeTeam.id})');
    print('  Away: ${first.awayTeam.name} (Code: ${first.awayTeam.code}, ID: ${first.awayTeam.id})');
    print('  Score: ${first.homeScore} - ${first.awayScore}');
    print('  Group: ${first.group}');
    print('  Status: ${first.status}');
  }

  // Let's run a check on team mapping in MockDataRepository
  final repo = MockDataRepository(getMatches: () => fixtures);
  final teams = await repo.getTeams();
  print('\nRepository teams list (first 5):');
  for (var i = 0; i < 5 && i < teams.length; i++) {
    print('  ${teams[i].name} | Code: ${teams[i].code} | Group: ${teams[i].group}');
  }
}
