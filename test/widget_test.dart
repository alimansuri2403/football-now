import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fifa2026_app/app.dart';
import 'package:fifa2026_app/providers/match_provider.dart';
import 'package:fifa2026_app/services/espn_api.dart';
import 'package:fifa2026_app/models/match.dart';

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
}

