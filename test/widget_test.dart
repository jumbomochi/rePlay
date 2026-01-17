import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:replay/app.dart';

void main() {
  testWidgets('RePlayApp smoke test - renders main UI elements',
      (WidgetTester tester) async {
    // Build our app wrapped in ProviderScope and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: RePlayApp(),
      ),
    );

    // Allow async operations to complete
    await tester.pumpAndSettle();

    // Verify the app title is displayed
    expect(find.text('rePlay'), findsOneWidget);

    // Verify the search icon is present in the app bar
    expect(find.byIcon(Icons.search), findsOneWidget);

    // Verify the FAB for adding toys is present
    expect(find.byIcon(Icons.camera_alt), findsOneWidget);
    expect(find.text('Add Toy'), findsOneWidget);
  });

  testWidgets('Search toggle works', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: RePlayApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Initially, search field should not be visible
    expect(find.byType(TextField), findsNothing);

    // Tap the search icon
    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();

    // Now search field should be visible and close icon should appear
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);

    // Tap close to dismiss search
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    // Search field should be hidden again
    expect(find.byType(TextField), findsNothing);
    expect(find.byIcon(Icons.search), findsOneWidget);
  });
}
