import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:replay/core/database/database.dart';
import 'package:replay/core/services/image_storage_service.dart';
import 'package:replay/features/categories/providers/categories_provider.dart';
import 'package:replay/features/inventory/providers/inventory_provider.dart';
import 'package:replay/features/inventory/screens/inventory_screen.dart';

void main() {
  testWidgets('InventoryScreen smoke test - renders main UI elements',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inventoryProvider.overrideWith(
            (ref) => MockInventoryNotifier(),
          ),
          categoryNamesProvider.overrideWith(
            (ref) => ['Action Figures', 'Dolls', 'Building Blocks'],
          ),
        ],
        child: const MaterialApp(
          home: InventoryScreen(),
        ),
      ),
    );

    // Allow widget to build
    await tester.pump();

    // Verify the app title is displayed
    expect(find.text('rePlay'), findsOneWidget);

    // Verify the search field is always visible with search icon
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byIcon(Icons.search), findsOneWidget);

    // Verify the FAB for adding toys is present
    expect(find.byIcon(Icons.camera_alt), findsOneWidget);
    expect(find.text('Add Toy'), findsOneWidget);

    // Verify category filter chips are present
    expect(find.text('All'), findsWidgets); // May appear in both status and category filters
    expect(find.text('Action Figures'), findsOneWidget);
  });

  testWidgets('Search bar is always visible with clear button', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inventoryProvider.overrideWith(
            (ref) => MockInventoryNotifier(),
          ),
          categoryNamesProvider.overrideWith(
            (ref) => ['Action Figures', 'Dolls'],
          ),
        ],
        child: const MaterialApp(
          home: InventoryScreen(),
        ),
      ),
    );

    await tester.pump();

    // Search field should always be visible
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Search toys...'), findsOneWidget);

    // Clear button should not be visible when search is empty
    expect(find.byIcon(Icons.clear), findsNothing);

    // Enter search text
    await tester.enterText(find.byType(TextField), 'test');
    await tester.pump();

    // Clear button should now be visible
    expect(find.byIcon(Icons.clear), findsOneWidget);

    // Tap clear to clear search
    await tester.tap(find.byIcon(Icons.clear));
    await tester.pump();

    // Clear button should be hidden again
    expect(find.byIcon(Icons.clear), findsNothing);
  });

  testWidgets('Empty state shows correct message', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inventoryProvider.overrideWith(
            (ref) => MockInventoryNotifier(),
          ),
          categoryNamesProvider.overrideWith(
            (ref) => [],
          ),
        ],
        child: const MaterialApp(
          home: InventoryScreen(),
        ),
      ),
    );

    await tester.pump();

    // Verify empty state message is shown
    expect(find.text('No toys yet'), findsOneWidget);
    expect(find.text('Tap the camera button to add your first toy!'),
        findsOneWidget);
  });

  testWidgets('Status filter tabs are displayed', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inventoryProvider.overrideWith(
            (ref) => MockInventoryNotifier(),
          ),
          categoryNamesProvider.overrideWith(
            (ref) => ['Action Figures'],
          ),
        ],
        child: const MaterialApp(
          home: InventoryScreen(),
        ),
      ),
    );

    await tester.pump();

    // Verify status filter tabs are present
    expect(find.text('All'), findsWidgets); // May appear in both status and category
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('In Storage'), findsOneWidget);
    expect(find.text('To Donate'), findsOneWidget);
  });
}

/// Mock inventory notifier that doesn't use real database
class MockInventoryNotifier extends InventoryNotifier {
  MockInventoryNotifier() : super(_MockDatabase(), _MockImageStorage());
}

/// Minimal mock database - only used for type satisfaction
class _MockDatabase implements AppDatabase {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// Minimal mock image storage - only used for type satisfaction
class _MockImageStorage implements ImageStorageService {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
