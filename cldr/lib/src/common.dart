import 'package:code_builder/code_builder.dart';
import 'package:dartx/dartx.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:xml/xml.dart';
import 'package:xml/xpath.dart';

part 'common.freezed.dart';

@freezed
class Plural<T> with _$Plural<T> implements ToExpression {
  const factory Plural({
    T? zero,
    T? one,
    T? two,
    T? few,
    T? many,
    T? other,
  }) = _Plural<T>;
  const Plural._();

  static Plural<String> stringsFromXml(CldrXml xml, CldrPath path) =>
      Plural.fromXml(xml, path, (it) => it.innerText);
  // ignore: sort_constructors_first
  factory Plural.fromXml(
    CldrXml xml,
    CldrPath path,
    T Function(XmlElement) valueFromElement,
  ) {
    T? resolve(String count) {
      return xml
          .resolveOptionalElement(path.withAttribute('count', count))
          ?.let(valueFromElement);
    }

    final zero = resolve('zero');
    final one = resolve('one');
    final two = resolve('two');
    final few = resolve('few');
    final many = resolve('many');
    var other = resolve('other');
    if ([zero, one, two, few, many, other].every((it) => it == null)) {
      other = valueFromElement(xml.resolveElement(path));
    }

    return Plural(
      zero: zero,
      one: one,
      two: two,
      few: few,
      many: many,
      other: other,
    );
  }

  @override
  Expression toExpression() {
    return referCldr('Plural')(
      [],
      {
        if (zero != null) 'zero': ToExpression.convert(zero),
        if (one != null) 'one': ToExpression.convert(one),
        if (two != null) 'two': ToExpression.convert(two),
        if (few != null) 'few': ToExpression.convert(few),
        if (many != null) 'many': ToExpression.convert(many),
        if (other != null) 'other': ToExpression.convert(other),
      },
    );
  }
}

@freezed
class ValueWithVariant<T extends Object>
    with _$ValueWithVariant<T>
    implements ToExpression {
  const factory ValueWithVariant(T value, [T? variant]) = _ValueWithVariant<T>;
  const ValueWithVariant._();

  static ValueWithVariant<String> fromXml(CldrXml xml, CldrPath path) {
    return ValueWithVariant(
      xml.resolveString(path),
      xml.resolveOptionalString(path.withAttribute('alt', 'variant')),
    );
  }

  static ValueWithVariant<String> fromXmlElements(List<XmlElement> elements) {
    if (elements.isEmpty) throw const FormatException('No elements found');
    if (elements.length > 2) {
      throw FormatException('Too many elements found: $elements');
    }
    if (elements.length == 1) {
      return ValueWithVariant(elements.first.innerText);
    }
    final firstAlt = elements.first.getAttribute('alt');
    final secondAlt = elements[1].getAttribute('alt');
    final (normal, alt) = switch ((firstAlt, secondAlt)) {
      (null, null) => throw const FormatException(
          "Both elements don't have an alt attribute",
        ),
      (null, 'variant') => (elements.first, elements[1]),
      ('variant', null) => (elements[1], elements.first),
      ('variant', 'variant') =>
        throw const FormatException('Both elements have an alt attribute'),
      _ => throw FormatException(
          'Unknown combination of alt attributes: `$firstAlt`, `$secondAlt`',
        ),
    };
    return ValueWithVariant(normal.innerText, alt.innerText);
  }

  T get variantOrValue => variant ?? value;

  @override
  Expression toExpression() {
    return referCldr('ValueWithVariant')(
      [
        ToExpression.convert(value),
        if (variant != null) ToExpression.convert(variant!),
      ],
    );
  }

  @override
  String toString() =>
      [value, if (variant != null) '(Variant: $variant)'].join(' ');
}

class CldrXml {
  CldrXml(this.documents)
      : assert(
          documents.length >= 2,
          'At least the language and root documents are required.',
        );

  final List<XmlDocument> documents;
  XmlDocument get root => documents.last;

  String resolveString(CldrPath path) => resolveElement(path).innerText;
  String? resolveOptionalString(CldrPath path) =>
      resolveOptionalElement(path)?.innerText;
  XmlElement resolveElement(CldrPath path) {
    return resolveOptionalElement(path) ??
        (throw ArgumentError('No element found at path: `$path`'));
  }

  /// Based on https://cldr.unicode.org/development/development-process/design-proposals/resolution-of-cldr-files#h.tleayzd1wetm.
  XmlElement? resolveOptionalElement(CldrPath path) {
    while (true) {
      // TODO(JonasWanke): prevent infinite loop

      // Look up path in document and fallbacks
      for (final document in documents) {
        XmlElement? lookup(CldrPath path) {
          return document
              .xpath(path.toExplicitString())
              .whereType<XmlElement>()
              .firstOrNull;
        }

        final element = lookup(path);
        if (element == null) continue;

        final text = element.innerText;
        if (text == '↑↑↑') {
          final lateralFallback = path.lateralFallbacks
              .mapNotNull(lookup)
              .where((it) => it.innerText != '↑↑↑')
              .firstOrNull;
          if (lateralFallback != null) return lateralFallback;
          continue;
        }

        return element;
      }

      // Resolve alias
      var parentNavigations = 1;
      while (true) {
        if (parentNavigations > path.segments.length) return null;

        final parentPath = path.nthParent(parentNavigations)!;
        final alias = root
            .xpath(parentPath.child('alias').toExplicitString())
            .firstOrNull;
        if (alias == null) {
          parentNavigations++;
          continue;
        }

        assert(alias.getAttribute('source') == 'locale');
        path = parentPath
            ._resolveRelativePath(alias.getAttribute('path')!)
            .nestedChild(
              path.segments.skip(path.segments.length - parentNavigations),
            );
        break;
      }
    }
  }

  late final _allPaths = _findAllPaths();

  /// Based on https://cldr.unicode.org/development/development-process/design-proposals/resolution-of-cldr-files#h.qwnlqdi5j0t4
  Set<CldrPath> _findAllPaths() {
    // Note: Sorting doesn't seem to be necessary.

    // 1. Find the set of all non-aliased paths in the file and each of its
    // parents, and sort it by path.
    var allPaths = documents
        .expand((it) => it.descendantElements)
        .where((it) => it.localName != 'alias')
        .map(CldrPath.fromElement)
        .toSet();

    // 2. Collect all the aliases in root and obtain a reverse mapping of
    // aliases, i.e., destinationPath to sourcePath. Sort it by destinationPath.
    final aliases = documents.last
        .findAllElements('alias')
        .where((it) => it.getAttribute('source') == 'locale')
        .map((it) {
      final path = CldrPath.fromElement(it.parentElement!);
      return (
        sourcePath: path,
        destinationPath: path._resolveRelativePath(it.getAttribute('path')!),
      );
    }).sortedBy((it) => it.destinationPath);

    var lastPathCount = 0;
    while (allPaths.length > lastPathCount) {
      lastPathCount = allPaths.length;

      // 3. Working backwards, use each reverse alias on the path set to get a
      // set of new paths that would use the alias to map to one of the paths in
      // the original set.
      allPaths = allPaths
          .expand(
            (path) => aliases
                .where(
                  (alias) =>
                      alias.sourcePath == path ||
                      alias.sourcePath.isChildOf(path),
                )
                .map(
                  (alias) => alias.destinationPath.nestedChild(
                    path.segments.skip(alias.sourcePath.segments.length),
                  ),
                )
                .followedBy([path]),
          )
          .toSet();
    }
    return allPaths;
  }

  Iterable<XmlElement> listChildElements(CldrPath path) =>
      listChildPaths(path).map(resolveElement);

  Iterable<CldrPath> listChildPaths(CldrPath path) =>
      _allPaths.filter((it) => it.isChildOf(path));
}

@freezed
class CldrPath with _$CldrPath implements Comparable<CldrPath> {
  const factory CldrPath(List<CldrPathSegment> segments) = _CldrPath;
  const CldrPath._();

  /// Only parses a very limited subset of the path syntax.
  factory CldrPath.parse(String path) =>
      CldrPath(path.split('/').map(CldrPathSegment.parse).toList());

  factory CldrPath.fromElement(XmlElement element) {
    return CldrPath(
      element.ancestorElements.reversed
          .followedBy([element])
          .map(CldrPathSegment.fromElement)
          .toList(),
    );
  }

  bool get isRoot => segments.isEmpty;

  CldrPath? get parent {
    if (isRoot) return null;
    return CldrPath(segments.sublist(0, segments.length - 1));
  }

  CldrPath? nthParent(int parentNavigations) {
    if (parentNavigations > segments.length) return null;
    return CldrPath(segments.sublist(0, segments.length - parentNavigations));
  }

  CldrPath withAttribute(String attribute, String value) {
    assert(segments.isNotEmpty);
    final lastSegment = segments.last;
    return CldrPath(
      [
        ...segments.sublist(0, segments.length - 1),
        CldrPathSegment(
          lastSegment.elementName,
          attributes: {...lastSegment.attributes, attribute: value},
        ),
      ],
    );
  }

  CldrPath child(
    String elementName, {
    Map<String, String> attributes = const {},
  }) =>
      childSegment(CldrPathSegment(elementName, attributes: attributes));
  CldrPath childSegment(CldrPathSegment segment) =>
      CldrPath([...segments, segment]);

  CldrPath nestedChild(Iterable<CldrPathSegment> segments) =>
      CldrPath([...this.segments, ...segments]);
  bool isChildOf(CldrPath other) {
    if (segments.length <= other.segments.length) return false;
    return const DeepCollectionEquality().equals(
      segments.sublist(0, other.segments.length),
      other.segments,
    );
  }

  CldrPath _resolveRelativePath(String relativePath) {
    var relativeParentNavigations = 0;
    while (relativePath.startsWith('../')) {
      relativePath = relativePath.substring(3);
      relativeParentNavigations++;
    }

    return CldrPath([
      ...segments.take(segments.length - relativeParentNavigations),
      ...CldrPath.parse(relativePath).segments,
    ]);
  }

  CldrPath? sibling(CldrPathSegment segment) {
    if (isRoot) return null;
    return CldrPath([...segments.take(segments.length - 1), segment]);
  }

  Iterable<CldrPath> get lateralFallbacks {
    if (isRoot) return [];
    return [parent!].followedBy(parent!.lateralFallbacks).expand(
          (parent) => segments.last.lateralFallbacks.map(parent.childSegment),
        );
  }

  @override
  int compareTo(CldrPath other) => toString().compareTo(other.toString());

  String toExplicitString() =>
      segments.map((it) => it.toExplicitString()).join();
  @override
  String toString() => segments.join();
}

@freezed
class CldrPathSegment with _$CldrPathSegment {
  const factory CldrPathSegment(
    String elementName, {
    @Default(<String, String>{}) Map<String, String> attributes,
  }) = _CldrPathSegment;
  const CldrPathSegment._();

  /// Only parses a very limited subset of the path syntax.
  factory CldrPathSegment.parse(String segment) {
    final attributeRegExp = RegExp(r"\[\@(?<type>[^=]+)='(?<value>[^']+)'\]");

    final attributeMatches = attributeRegExp.allMatches(segment);
    final attributes = attributeMatches.associate(
      (it) => MapEntry(it.namedGroup('type')!, it.namedGroup('value')!),
    );
    if (attributes['type'] == 'standard') attributes.remove('type');

    return CldrPathSegment(
      attributeMatches.isEmpty
          ? segment
          : segment.substring(0, attributeMatches.first.start),
      attributes: attributes,
    );
  }

  factory CldrPathSegment.fromElement(XmlElement element) {
    return CldrPathSegment(
      element.localName,
      attributes: {
        for (final attribute in _distinguishingAttributes)
          if (element.getAttribute(attribute) case final value?)
            attribute: value,
      },
    );
  }

  static const _distinguishingAttributes = {'alt', 'count', 'id', 'type'};

  static const _attributesWithLateralFallbacks = {'alt', 'count'};
  Iterable<CldrPathSegment> get lateralFallbacks {
    // TODO(JonasWanke): Support remining attributes with fallbacks
    // Attribute 	Fallback 	Exception Elements
    // case 	"nominative" → ∅ 	caseMinimalPairs
    // gender 	default_gender(locale) → ∅ 	genderMinimalPairs
    // ordinal 	plural_rules(locale, x) → "other" → ∅ 	ordinalMinimalPairs

    final altVariants = switch (attributes['alt']) {
      null => [null],
      final alt => [alt, null],
    };

    final count = attributes['count'];
    // TODO(JonasWanke): Support count being a number
    // plural_rules(locale, x) → "other" → ∅
    final countVariants =
        ['minDays', 'pluralMinimalPairs'].contains(elementName)
            ? [count]
            : switch (attributes['count']) {
                null => [null],
                'other' => ['other', null],
                final count => [count, 'other', null],
              };

    final remainingAttributes = Map.fromEntries(
      attributes.entries
          .where((it) => !_attributesWithLateralFallbacks.contains(it.key)),
    );
    return countVariants
        .expand((count) => altVariants.map((alt) => (alt: alt, count: count)))
        .map(
          (it) => CldrPathSegment(
            elementName,
            attributes: {
              ...remainingAttributes,
              if (it.alt != null) 'alt': it.alt!,
              if (it.count != null) 'count': it.count!,
            },
          ),
        )
        .skip(1);
  }

  String toExplicitString() {
    final buffer = StringBuffer(toString());
    for (final attribute in _distinguishingAttributes) {
      if (!attributes.containsKey(attribute)) {
        buffer.write('[not(@$attribute)]');
      }
    }
    return buffer.toString();
  }

  @override
  String toString() {
    return [
      '/',
      elementName,
      for (final entry in attributes.entries)
        "[@${entry.key}='${entry.value}']",
    ].join();
  }
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

extension ListToExpression<T extends ToExpression> on List<T> {
  Expression toExpression() => literalList(map((it) => it.toExpression()));
}

Reference referCldr(String name) => refer(name, 'package:cldr/cldr.dart');

/// https://github.com/JonasWanke/supernova/blob/c568672838f2982d0b04562f33b42f6bafa85f70/supernova/lib/src/scope_functions.dart
extension LetExtension<T extends Object> on T {
  R let<R>(R Function(T) block) => block(this);
}
