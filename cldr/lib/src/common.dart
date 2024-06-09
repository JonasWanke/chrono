import 'package:code_builder/code_builder.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:xml/xml.dart';

part 'common.freezed.dart';

@freezed
class ValueWithVariant<T extends Object>
    with _$ValueWithVariant<T>
    implements ToExpression {
  const factory ValueWithVariant(Value<T> value, [Value<T>? variant]) =
      _ValueWithVariant<T>;
  const ValueWithVariant._();

  static ValueWithVariant<String> fromXml(List<XmlElement> elements) {
    if (elements.isEmpty) throw const FormatException('No elements found');
    if (elements.length > 2) {
      throw FormatException('Too many elements found: $elements');
    }

    if (elements.length == 1) {
      return ValueWithVariant(Value.fromXml(elements.first));
    }

    final firstAlt = elements.first.getAttribute('alt');
    final secondAlt = elements[1].getAttribute('alt');
    final (normal, alt) = switch ((firstAlt, secondAlt)) {
      (null, null) => throw const FormatException(
          "Both elements don't have an alt attribute",
        ),
      (null, 'variant') => (
          Value.fromXml(elements.first),
          Value.fromXml(elements[1])
        ),
      ('variant', null) => (
          Value.fromXml(elements[1]),
          Value.fromXml(elements.first)
        ),
      ('variant', 'variant') =>
        throw const FormatException('Both elements have an alt attribute'),
      _ => throw FormatException(
          'Unknown combination of alt attributes: `$firstAlt`, `$secondAlt`',
        ),
    };
    return ValueWithVariant(normal, alt);
  }

  @override
  Expression toExpression() {
    return referCldr('ValueWithVariant')(
      [
        value.toExpression(),
        if (variant != null) variant!.toExpression(),
      ],
    );
  }

  @override
  String toString() =>
      [value, if (variant != null) '(Variant: $variant)'].join(' ');
}

@freezed
class Value<T extends Object> with _$Value<T> implements ToExpression {
  const factory Value(T? value) = _Value<T>;
  const Value._();

  factory Value.customFromXml(
    XmlElement element,
    T Function(String) fromString,
  ) {
    final text = element.innerText;
    return Value(text == '↑↑↑' ? null : fromString(text));
  }
  static Value<String> fromXml(XmlElement element) =>
      Value.customFromXml(element, (it) => it);

  bool get isInherited => value == null;

  @override
  Expression toExpression() =>
      referCldr('Value')([ToExpression.convert(value)]);

  @override
  String toString() => isInherited ? '<inherited>' : value!.toString();
}

abstract interface class ToExpression {
  static Expression convert(Object? value) {
    if (value == null) return literalNull;
    if (value is ToExpression) return value.toExpression();
    if (value is num) return literalNum(value);
    if (value is String) return literalString(value);
    if (value is List<dynamic>) return literalList(value.map(convert));
    if (value is Map<dynamic, dynamic>) {
      return literalMap(
        value.map((key, value) => MapEntry(convert(key), convert(value))),
      );
    }
    throw ArgumentError.value(value, 'value', 'Unsupported type');
  }

  Expression toExpression();
}

Reference referCldr(String name) => refer(name, 'package:cldr/cldr.dart');
