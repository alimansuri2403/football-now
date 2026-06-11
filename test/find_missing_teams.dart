import 'package:fifa2026_app/services/espn_api.dart';
import 'package:fifa2026_app/data/repository.dart';
import 'package:fifa2026_app/models/match.dart';

void main() async {
  final api = EspnApiService();
  final fixtures = await api.fetchAllFixtures();
  
  final repo = MockDataRepository(getMatches: () => fixtures);
  final repoTeams = await repo.getTeams();
  final repoCodes = repoTeams.map((t) => t.code.toUpperCase()).toSet();

  final Set<String> espnCodes = {};
  final Map<String, String> teamNames = {};

  for (final m in fixtures) {
    espnCodes.add(m.homeTeam.code.toUpperCase());
    espnCodes.add(m.awayTeam.code.toUpperCase());
    teamNames[m.homeTeam.code.toUpperCase()] = m.homeTeam.name;
    teamNames[m.awayTeam.code.toUpperCase()] = m.awayTeam.name;
  }

  print('Total distinct team codes in ESPN fixtures: ${espnCodes.length}');
  print('Total distinct team codes in local Repository: ${repoCodes.length}');

  final missingInRepo = espnCodes.difference(repoCodes);
  final extraInRepo = repoCodes.difference(espnCodes);

  print('\nTeam codes returned by ESPN but MISSING in local repository:');
  for (final code in missingInRepo) {
    print('  $code: ${teamNames[code]}');
  }

  print('\nTeam codes in local repository but NOT returned by ESPN fixtures:');
  for (final code in extraInRepo) {
    final t = repoTeams.firstWhere((x) => x.code == code);
    print('  $code: ${t.name} (Group ${t.group})');
  }
}
