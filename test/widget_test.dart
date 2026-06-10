import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fifa2026_app/app.dart';
import 'package:fifa2026_app/providers/match_provider.dart';
import 'package:fifa2026_app/services/espn_api.dart';
import 'package:fifa2026_app/models/match.dart';
import 'package:fifa2026_app/data/wc2026_data.dart';

import 'package:fifa2026_app/data/repository.dart';

class MockEspnApiService extends EspnApiService {
  @override
  Future<List<Match>> fetchScoreboard() async => [];

  @override
  Future<List<Match>> fetchAllFixtures() async => [];
}

void main() {
  testWidgets('App initialization test', (WidgetTester tester) async {
    // Build our app wrapped in ProviderScope as required by Riverpod
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          espnApiProvider.overrideWithValue(MockEspnApiService()),
        ],
        child: const App(),
      ),
    );

    // Verify it compiles and starts rendering the loading shell
    expect(find.byType(ProviderScope), findsOneWidget);
  });

  test('Group distributions and team counts', () async {
    final repo = MockDataRepository();
    final teams = await repo.getTeams();
    
    expect(teams.length, 48);

    final Map<String, int> groupCounts = {};
    for (final t in teams) {
      groupCounts[t.group] = (groupCounts[t.group] ?? 0) + 1;
    }
    
    print("Cleaned Group distributions: $groupCounts");
    print("Total teams: ${teams.length}");
    
    for (final group in ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L']) {
      expect(groupCounts[group], 4);
    }
  });
}

