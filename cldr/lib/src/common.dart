import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:xml/xml.dart';

part 'common.freezed.dart';

@freezed
class ValueWithVariant with _$ValueWithVariant {
  const factory ValueWithVariant(Value value, [Value? variant]) =
      _ValueWithVariant;
  const ValueWithVariant._();

  factory ValueWithVariant.fromXml(List<XmlElement> elements) {
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
  String toString() =>
      [value, if (variant != null) '(Variant: $variant)'].join(' ');
}

@freezed
class Value<T extends Object> with _$Value<T> {
  const factory Value(T? value) = _Value;
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
  String toString() => isInherited ? '<inherited>' : value!.toString();
}
