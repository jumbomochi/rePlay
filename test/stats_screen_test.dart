import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:replay/core/database/database.dart';
import 'package:replay/core/services/image_storage_service.dart';
import 'package:replay/features/inventory/providers/inventory_provider.dart';
import 'package:replay/features/stats/screens/stats_screen.dart';
import 'package:replay/features/stats/widgets/hero_count_card.dart';
import 'package:replay/features/stats/widgets/needs_attention_card.dart';
import 'package:replay/features/stats/widgets/recently_added_card.dart';
import 'package:replay/features/stats/widgets/status_breakdown_card.dart';

void main() {
  testWidgets('HeroCountCard shows total toy count', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: HeroCountCard(totalCount: 24)),
      ),
    );

    expect(find.text('24'), findsOneWidget);
    expect(find.text('total toys'), findsOneWidget);
  });

  testWidgets('HeroCountCard shows zero count', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: HeroCountCard(totalCount: 0)),
      ),
    );

    expect(find.text('0'), findsOneWidget);
  });

  testWidgets('StatusBreakdownCard shows counts per status', (WidgetTester tester) async {
    final statusCounts = {
      'active': 15,
      'inStorage': 5,
      'toDonate': 3,
      'toSell': 1,
    };

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: StatusBreakdownCard(statusCounts: statusCounts)),
      ),
    );

    expect(find.text('By Status'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('15'), findsOneWidget);
    expect(find.text('In Storage'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
  });

  testWidgets('RecentlyAddedCard shows toys in reverse chronological order', (WidgetTester tester) async {
    final now = DateTime.now();
    final toys = [
      Toy(id: 1, name: 'Oldest', description: null, imagePath: '', thumbnailPath: null, category: 'Other', aiLabels: '[]', createdAt: now.subtract(const Duration(days: 10)), updatedAt: now, condition: 'good', location: null, status: 'active'),
      Toy(id: 2, name: 'Newest', description: null, imagePath: '', thumbnailPath: null, category: 'Other', aiLabels: '[]', createdAt: now.subtract(const Duration(hours: 2)), updatedAt: now, condition: 'good', location: null, status: 'active'),
      Toy(id: 3, name: 'Middle', description: null, imagePath: '', thumbnailPath: null, category: 'Other', aiLabels: '[]', createdAt: now.subtract(const Duration(days: 3)), updatedAt: now, condition: 'good', location: null, status: 'active'),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: RecentlyAddedCard(toys: toys, onToyTap: (_) {})),
      ),
    );

    expect(find.text('Recently Added'), findsOneWidget);
    expect(find.text('Newest'), findsOneWidget);
    expect(find.text('Middle'), findsOneWidget);
    expect(find.text('Oldest'), findsOneWidget);

    final newestOffset = tester.getTopLeft(find.text('Newest'));
    final oldestOffset = tester.getTopLeft(find.text('Oldest'));
    expect(newestOffset.dy, lessThan(oldestOffset.dy));
  });

  testWidgets('NeedsAttentionCard hidden when no poor/broken toys', (WidgetTester tester) async {
    final toys = [
      Toy(id: 1, name: 'GoodToy', description: null, imagePath: '', thumbnailPath: null, category: 'Other', aiLabels: '[]', createdAt: DateTime.now(), updatedAt: DateTime.now(), condition: 'good', location: null, status: 'active'),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: NeedsAttentionCard(toys: toys, onToyTap: (_) {})),
      ),
    );

    expect(find.text('Needs Attention'), findsNothing);
  });

  testWidgets('NeedsAttentionCard shows poor and broken toys', (WidgetTester tester) async {
    final toys = [
      Toy(id: 1, name: 'GoodToy', description: null, imagePath: '', thumbnailPath: null, category: 'Other', aiLabels: '[]', createdAt: DateTime.now(), updatedAt: DateTime.now(), condition: 'good', location: null, status: 'active'),
      Toy(id: 2, name: 'PoorToy', description: null, imagePath: '', thumbnailPath: null, category: 'Other', aiLabels: '[]', createdAt: DateTime.now(), updatedAt: DateTime.now(), condition: 'poor', location: null, status: 'active'),
      Toy(id: 3, name: 'BrokenToy', description: null, imagePath: '', thumbnailPath: null, category: 'Other', aiLabels: '[]', createdAt: DateTime.now(), updatedAt: DateTime.now(), condition: 'broken', location: null, status: 'active'),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: NeedsAttentionCard(toys: toys, onToyTap: (_) {})),
      ),
    );

    expect(find.text('Needs Attention'), findsOneWidget);
    expect(find.text('PoorToy'), findsOneWidget);
    expect(find.text('BrokenToy'), findsOneWidget);
    expect(find.text('GoodToy'), findsNothing);
  });

  testWidgets('StatsScreen shows all stat sections with toy data', (WidgetTester tester) async {
    final notifier = _MockInventoryNotifier();
    final now = DateTime.now();
    notifier.state = InventoryState(
      toys: [
        Toy(id: 1, name: 'ActiveToy', description: null, imagePath: '', thumbnailPath: null, category: 'Other', aiLabels: '[]', createdAt: now.subtract(const Duration(days: 1)), updatedAt: now, condition: 'good', location: null, status: 'active'),
        Toy(id: 2, name: 'BrokenToy', description: null, imagePath: '', thumbnailPath: null, category: 'Dolls', aiLabels: '[]', createdAt: now.subtract(const Duration(days: 5)), updatedAt: now, condition: 'broken', location: null, status: 'active'),
        Toy(id: 3, name: 'StoredToy', description: null, imagePath: '', thumbnailPath: null, category: 'Other', aiLabels: '[]', createdAt: now.subtract(const Duration(days: 3)), updatedAt: now, condition: 'good', location: null, status: 'inStorage'),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inventoryProvider.overrideWith((ref) => notifier),
        ],
        child: const MaterialApp(home: StatsScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('3'), findsOneWidget);
    expect(find.text('total toys'), findsOneWidget);
    expect(find.text('By Status'), findsOneWidget);
    expect(find.text('Recently Added'), findsOneWidget);
    expect(find.text('ActiveToy'), findsOneWidget);
    expect(find.text('Needs Attention'), findsOneWidget);
    expect(find.text('BrokenToy'), findsWidgets);
  });
}

class _MockInventoryNotifier extends InventoryNotifier {
  _MockInventoryNotifier() : super(_MockDatabase(), _MockImageStorage());
}

class _MockDatabase implements AppDatabase {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _MockImageStorage implements ImageStorageService {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
