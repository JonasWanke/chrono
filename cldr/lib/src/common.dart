import 'package:meta/meta.dart';
import 'package:xml/xml.dart';

@immutable
class ValueWithVariant {
  const ValueWithVariant(this.value, [this.variant]);

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

  final Value value;
  final Value? variant;

  @override
  String toString() =>
      [value, if (variant != null) '(Variant: $variant)'].join(' ');
}

@immutable
class Value<T extends Object> {
  const Value(this.value);

  factory Value.customFromXml(
    XmlElement element,
    T Function(String) fromString,
  ) {
    final text = element.innerText;
    return Value(text == '↑↑↑' ? null : fromString(text));
  }
  static Value<String> fromXml(XmlElement element) =>
      Value.customFromXml(element, (it) => it);

  final T? value;
  bool get isInherited => value == null;

  @override
  String toString() => isInherited ? '<inherited>' : value!.toString();
}
