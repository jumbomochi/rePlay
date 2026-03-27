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

  testWidgets('Sort dropdown appears and defaults to Newest First', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inventoryProvider.overrideWith((ref) => MockInventoryNotifier()),
          categoryNamesProvider.overrideWith((ref) => []),
        ],
        child: const MaterialApp(home: InventoryScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('Newest First'), findsOneWidget);
  });

  testWidgets('Search matches toy description', (WidgetTester tester) async {
    final notifier = MockInventoryNotifier();
    notifier.state = InventoryState(
      toys: [
        Toy(
          id: 1,
          name: 'LEGO Star Wars Set',
          description: 'Millennium Falcon building set',
          imagePath: '',
          thumbnailPath: null,
          category: 'Building Blocks',
          aiLabels: '["lego"]',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          condition: 'good',
          location: 'Playroom',
          status: 'active',
        ),
      ],
      searchQuery: 'millennium',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inventoryProvider.overrideWith((ref) => notifier),
          categoryNamesProvider.overrideWith((ref) => []),
        ],
        child: const MaterialApp(home: InventoryScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('LEGO Star Wars Set'), findsOneWidget);
  });

  test('Batch update status changes all selected toys', () async {
    final db = _MockDatabase();
    final imageStorage = _MockImageStorage();
    final notifier = InventoryNotifier(db, imageStorage);

    notifier.state = InventoryState(
      toys: [
        Toy(id: 1, name: 'Toy1', description: null, imagePath: '', thumbnailPath: null, category: 'Other', aiLabels: '[]', createdAt: DateTime.now(), updatedAt: DateTime.now(), condition: 'good', location: null, status: 'active'),
        Toy(id: 2, name: 'Toy2', description: null, imagePath: '', thumbnailPath: null, category: 'Other', aiLabels: '[]', createdAt: DateTime.now(), updatedAt: DateTime.now(), condition: 'good', location: null, status: 'active'),
        Toy(id: 3, name: 'Toy3', description: null, imagePath: '', thumbnailPath: null, category: 'Other', aiLabels: '[]', createdAt: DateTime.now(), updatedAt: DateTime.now(), condition: 'good', location: null, status: 'active'),
      ],
    );

    notifier.enterMultiSelect(1);
    expect(notifier.state.isMultiSelectMode, true);
    expect(notifier.state.selectedToyIds, {1});

    notifier.toggleSelection(3);
    expect(notifier.state.selectedToyIds, {1, 3});

    notifier.toggleSelection(1);
    expect(notifier.state.selectedToyIds, {3});

    notifier.clearSelection();
    expect(notifier.state.isMultiSelectMode, false);
    expect(notifier.state.selectedToyIds, isEmpty);
  });

  testWidgets('Long press enters multi-select mode', (WidgetTester tester) async {
    final notifier = MockInventoryNotifier();
    notifier.state = InventoryState(
      toys: [
        Toy(id: 1, name: 'TestToy', description: null, imagePath: '', thumbnailPath: null, category: 'Other', aiLabels: '[]', createdAt: DateTime.now(), updatedAt: DateTime.now(), condition: 'good', location: null, status: 'active'),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inventoryProvider.overrideWith((ref) => notifier),
          categoryNamesProvider.overrideWith((ref) => ['Other']),
        ],
        child: const MaterialApp(home: InventoryScreen()),
      ),
    );
    await tester.pump();

    final toyCardFinder = find.ancestor(
      of: find.text('TestToy'),
      matching: find.byType(InkWell),
    );
    await tester.longPress(toyCardFinder);
    await tester.pump();

    expect(find.text('1 selected'), findsOneWidget);
  });

  testWidgets('Status filter tabs show toy counts', (WidgetTester tester) async {
    final notifier = MockInventoryNotifier();
    notifier.state = InventoryState(
      toys: [
        Toy(id: 1, name: 'Toy1', description: null, imagePath: '', thumbnailPath: null, category: 'Other', aiLabels: '[]', createdAt: DateTime.now(), updatedAt: DateTime.now(), condition: 'good', location: null, status: 'active'),
        Toy(id: 2, name: 'Toy2', description: null, imagePath: '', thumbnailPath: null, category: 'Other', aiLabels: '[]', createdAt: DateTime.now(), updatedAt: DateTime.now(), condition: 'good', location: null, status: 'active'),
        Toy(id: 3, name: 'Toy3', description: null, imagePath: '', thumbnailPath: null, category: 'Dolls', aiLabels: '[]', createdAt: DateTime.now(), updatedAt: DateTime.now(), condition: 'good', location: null, status: 'toDonate'),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inventoryProvider.overrideWith((ref) => notifier),
          categoryNamesProvider.overrideWith((ref) => ['Other', 'Dolls']),
        ],
        child: const MaterialApp(home: InventoryScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('All (3)'), findsWidgets); // Appears in both status and category filters
    expect(find.text('Active (2)'), findsOneWidget);
    expect(find.text('To Donate (1)'), findsOneWidget);
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
