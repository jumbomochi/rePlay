import 'package:flutter_test/flutter_test.dart';
import 'package:replay/core/widgets/hero_tags.dart';

void main() {
  test('toyImageHeroTag returns stable tag for a given id', () {
    expect(toyImageHeroTag(1), 'toy-image-1');
    expect(toyImageHeroTag(42), 'toy-image-42');
  });

  test('toyImageHeroTag is unique per id', () {
    expect(toyImageHeroTag(1), isNot(equals(toyImageHeroTag(2))));
  });
}
