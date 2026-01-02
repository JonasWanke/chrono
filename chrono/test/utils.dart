import 'dart:convert';

import 'package:glados/glados.dart';
import 'package:meta/meta.dart';

// ignore_for_file: avoid-top-level-members-in-tests

void testDataClassBasics<T extends Comparable<T>>({
  required List<Codec<T, dynamic>> preciseCodecs,
}) {
  Glados<T>().test('equality', (value) {
    expect(value == value, true);
    expect(value.compareTo(value), 0);
  });

  Glados2<T, T>().test('compareTo(…)', (first, second) {
    switch (first.compareTo(second)) {
      case < 0:
        expect(second.compareTo(first) > 0, true);
        expect(first != second, true);
      case 0:
        expect(second.compareTo(first), 0);
        expect(first == second, true);
      case > 0:
        expect(second.compareTo(first) < 0, true);
        expect(first != second, true);
    }
  });

  group('Codecs', () => preciseCodecs.forEach(testCodec));
}

@isTestGroup
void testAll<T>(String description, List<T> values, void Function(T) body) {
  group(description, () {
    for (final value in values) {
      // ignore: missing-test-assertion
      test('$value', () => body(value));
    }
  });
}

void testCodec<T, E>(Codec<T, E> codec) {
  Glados<T>().test(codec.runtimeType.toString(), (value) {
    expect(codec.decode(codec.encode(value)), value);
  });
}

void testCodecStartingFromEncoded<T, E>(Codec<T, E> codec) {
  Glados<E>().test(codec.runtimeType.toString(), (encoded) {
    expect(codec.encode(codec.decode(encoded)), encoded);
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
        // ignore: missing-test-assertion
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
