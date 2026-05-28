import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:replay/features/inventory/navigation/toy_detail_route.dart';
import 'package:replay/features/inventory/screens/toy_detail_screen.dart';

void main() {
  test('toyDetailRoute returns a PageRouteBuilder with a fade transition', () {
    final route = toyDetailRoute(42);
    expect(route, isA<PageRouteBuilder<void>>());

    final builder = route as PageRouteBuilder<void>;
    expect(builder.transitionDuration, const Duration(milliseconds: 350));
    expect(builder.reverseTransitionDuration, const Duration(milliseconds: 300));
  });

  test('toyDetailRoute pageBuilder produces ToyDetailScreen with correct toyId', () {
    final route = toyDetailRoute(99) as PageRouteBuilder<void>;
    final page = route.pageBuilder(
      _DummyBuildContext(),
      const AlwaysStoppedAnimation(0),
      const AlwaysStoppedAnimation(0),
    );

    expect(page, isA<ToyDetailScreen>());
    expect((page as ToyDetailScreen).toyId, 99);
  });
}

class _DummyBuildContext implements BuildContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
