import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:replay/features/stats/widgets/hero_count_card.dart';

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
}
