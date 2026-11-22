import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:scatter_notes/app.dart';
import 'package:scatter_notes/core/database/database_provider.dart';

import 'helpers/test_database.dart';

void main() {
  testWidgets('renders seeded School and Personal Projects spaces', (
    WidgetTester tester,
  ) async {
    final testDb = createTestDatabase();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(testDb)],
        child: const ScatterNotesApp(),
      ),
    );

    // Wait for async Drift seeding & stream updates without pumpAndSettle(),
    // which hangs on indeterminate progress indicators and open streams.
    for (var i = 0; i < 40; i++) {
      await tester.pump();
      if (find.text('School').evaluate().isNotEmpty) {
        break;
      }
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
    }

    expect(find.text('Scatter Notes'), findsOneWidget);
    expect(find.text('School'), findsOneWidget);
    expect(find.text('Personal Projects'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
    await testDb.close();
    await tester.pump();
  });
}
