import 'dart:convert';

import 'package:glados/glados.dart';
import 'package:meta/meta.dart';

// ignore_for_file: avoid-top-level-members-in-tests

void testDataClassBasics<T extends Comparable<T>>({
  required List<Codec<T, dynamic>> codecs,
}) {
  Glados<T>().test('equality', (value) {
    expect(value == value, true);
    expect(value.compareTo(value), 0);
  });

  group('Codecs', () {
    for (final codec in codecs) {
      Glados<T>().test(codec.runtimeType.toString(), (value) {
        expect(codec.decode(codec.encode(value)), value);
      });
    }
  });
}

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

extension AnyChronoTests on Any {
  Generator<int> get intExcept0 =>
      either(intInRange(null, -1), intInRange(1, null));
}
