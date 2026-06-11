import 'package:fifa2026_app/services/espn_api.dart';

void main() async {
  final api = EspnApiService();
  final fixtures = await api.fetchAllFixtures();
  print('Total matches fetched: ${fixtures.length}');

  for (var i = 0; i < fixtures.length; i++) {
    final m = fixtures[i];
    print('Match $i: [${m.id}] ${m.homeTeam.name} (${m.homeTeam.code}) vs ${m.awayTeam.name} (${m.awayTeam.code}) on ${m.kickoffTime} (Status: ${m.status})');
  }
}
