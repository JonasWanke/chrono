import 'package:meta/meta.dart';
import 'package:test/test.dart';

// ignore_for_file: avoid-top-level-members-in-tests

@isTestGroup
void testAll<T>(String description, List<T> values, void Function(T) body) {
  group(description, () {
    for (final value in values) {
      test('$value', () => body(value));
    }
  });
}

@isTestGroup
void testAllPairs<T>(
  String description,
  List<T> values,
  void Function(T, T) body,
) {
  group(description, () {
    for (final first in values) {
      for (final second in values) {
        test('$first and $second', () => body(first, second));
      }
    }
  });
}

void expectInRange<T extends Comparable<T>>(
  T actual,
  T lowerBound,
  T upperBound,
) {
  expect(actual, greaterThanOrEqualTo(lowerBound));
  expect(actual, lessThanOrEqualTo(upperBound));
}
