import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fifa2026_app/app.dart';

void main() {
  testWidgets('App initialization test', (WidgetTester tester) async {
    // Build our app wrapped in ProviderScope as required by Riverpod
    await tester.pumpWidget(
      const ProviderScope(
        child: App(),
      ),
    );

    // Verify it compiles and starts rendering the loading shell
    expect(find.byType(ProviderScope), findsOneWidget);
  });
}
