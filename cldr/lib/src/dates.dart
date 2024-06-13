import 'package:code_builder/code_builder.dart';
import 'package:collection/collection.dart';
import 'package:dartx/dartx.dart' hide IterableFirstOrNull, IterableLastOrNull;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:xml/xml.dart';

import 'common.dart';

part 'dates.freezed.dart';

@freezed
class Dates with _$Dates implements ToExpression {
  const factory Dates({
    required Calendars calendars,
    required Fields fields,
    // TODO(JonasWanke): `<timeZoneNames>`
  }) = _Dates;
  const Dates._();

  factory Dates.fromXml(CldrXml xml, CldrPath path) {
    return Dates(
      calendars: Calendars.fromXml(xml, path.child('calendars')),
      fields: Fields.fromXml(xml, path.child('fields')),
    );
  }

  @override
  Expression toExpression() {
    return referCldr('Dates')(
      [],
      {
        'calendars': calendars.toExpression(),
        'fields': fields.toExpression(),
      },
    );
  }
}

@freezed
class Calendars with _$Calendars implements ToExpression {
  const factory Calendars({required Calendar gregorian}) = _Calendars;
  const Calendars._();

  factory Calendars.fromXml(CldrXml xml, CldrPath path) {
    Calendar resolve(String type) {
      return Calendar.fromXml(
        xml,
        path.child('calendar', attributes: {'type': type}),
      );
    }

    return Calendars(gregorian: resolve('gregorian'));
  }

  @override
  Expression toExpression() =>
      referCldr('Calendars')([], {'gregorian': gregorian.toExpression()});
}

@freezed
class Calendar with _$Calendar implements ToExpression {
  const factory Calendar({
    required Context<Widths<Map<int, String>>> months,
    required Context<DayWidths> days,
    // TODO(JonasWanke): `<quarters>`, `<dayPeriods>`
    required Eras eras,
    required DateOrTimeFormats<DateOrTimeFormat> dateFormats,
    required DateOrTimeFormats<DateOrTimeFormat> timeFormats,
    required DateTimeFormats dateTimeFormats,
  }) = _Calendar;
  const Calendar._();

  factory Calendar.fromXml(CldrXml xml, CldrPath path) {
    return Calendar(
      months: Context.fromXml(
        path.child('months').child('monthContext'),
        (path) => Widths.fromXml(
          path.child('monthWidth'),
          (path) => 1.rangeTo(12).associateWith(
                (number) => xml.resolveString(
                  path.child('month', attributes: {'type': number.toString()}),
                ),
              ),
        ),
      ),
      days: Context.fromXml(
        path.child('days').child('dayContext'),
        (path) => DayWidths.fromXml(xml, path),
      ),
      eras: Eras.fromXml(xml, path.child('eras')),
      dateFormats: DateOrTimeFormats.fromXml(
        path.child('dateFormats'),
        'dateFormat',
        (path) => DateOrTimeFormat.fromXml(xml, path),
      ),
      timeFormats: DateOrTimeFormats.fromXml(
        path.child('timeFormats'),
        'timeFormat',
        (path) => DateOrTimeFormat.fromXml(xml, path),
      ),
      dateTimeFormats:
          DateTimeFormats.fromXml(xml, path.child('dateTimeFormats')),
    );
  }

  @override
  Expression toExpression() {
    return referCldr('Calendar')(
      [],
      {
        'months': months.toExpression(),
        'days': days.toExpression(),
        'eras': eras.toExpression(),
        'dateFormats': dateFormats.toExpression(),
        'timeFormats': timeFormats.toExpression(),
        'dateTimeFormats': dateTimeFormats.toExpression(),
      },
    );
  }
}

@freezed
class DayWidths with _$DayWidths implements ToExpression {
  const factory DayWidths({
    required Days wide,
    required Days abbreviated,

    /// Ideally between the abbreviated and narrow widths, but must be no longer
    /// than abbreviated and no shorter than narrow (if short day names are not
    /// explicitly specified, abbreviated day names are used instead).
    required Days short,
    required Days narrow,
  }) = _DayWidths;
  const DayWidths._();

  factory DayWidths.fromXml(CldrXml xml, CldrPath path) {
    Days resolve(String type) =>
        Days.fromXml(xml, path.child('dayWidth', attributes: {'type': type}));
    return DayWidths(
      wide: resolve('wide'),
      abbreviated: resolve('abbreviated'),
      short: resolve('short'),
      narrow: resolve('narrow'),
    );
  }

  @override
  Expression toExpression() {
    return referCldr('DayWidths')(
      [],
      {
        'wide': wide.toExpression(),
        'abbreviated': abbreviated.toExpression(),
        'short': short.toExpression(),
        'narrow': narrow.toExpression(),
      },
    );
  }
}

@freezed
class Days with _$Days implements ToExpression {
  const factory Days({
    required String sunday,
    required String monday,
    required String tuesday,
    required String wednesday,
    required String thursday,
    required String friday,
    required String saturday,
  }) = _Days;
  const Days._();

  factory Days.fromXml(CldrXml xml, CldrPath path) {
    String resolve(String type) =>
        xml.resolveString(path.child('day', attributes: {'type': type}));
    return Days(
      sunday: resolve('sun'),
      monday: resolve('mon'),
      tuesday: resolve('tue'),
      wednesday: resolve('wed'),
      thursday: resolve('thu'),
      friday: resolve('fri'),
      saturday: resolve('sat'),
    );
  }

  @override
  Expression toExpression() {
    return referCldr('Days')(
      [],
      {
        'sunday': literalString(sunday),
        'monday': literalString(monday),
        'tuesday': literalString(tuesday),
        'wednesday': literalString(wednesday),
        'thursday': literalString(thursday),
        'friday': literalString(friday),
        'saturday': literalString(saturday),
      },
    );
  }
}

@freezed
class Eras with _$Eras implements ToExpression {
  const factory Eras({required Map<int, Era> eras}) = _Eras;
  const Eras._();

  factory Eras.fromXml(CldrXml xml, CldrPath path) {
    Map<int, List<XmlElement>> find(String elementName) {
      return xml
          .listChildElements(path.child(elementName))
          .groupListsBy((it) => int.parse(it.getAttribute('type')!));
    }

    final eraNames = find('eraNames');
    final eraAbbreviations = find('eraAbbr');
    final eraNarrow = find('eraNarrow');

    final eras = eraNames.keys.associateWith((type) {
      return Era(
        name: ValueWithVariant.fromXmlElements(eraNames[type]!),
        abbreviation: ValueWithVariant.fromXmlElements(eraAbbreviations[type]!),
        narrow: ValueWithVariant.fromXmlElements(eraNarrow[type]!),
      );
    });
    return Eras(eras: eras);
  }

  @override
  Expression toExpression() {
    return referCldr('Eras')(
      [],
      {
        'eras': literalMap(
          eras.map(
            (key, value) => MapEntry(literalNum(key), value.toExpression()),
          ),
        ),
      },
    );
  }
}

@freezed
class Era with _$Era implements ToExpression {
  const factory Era({
    required ValueWithVariant<String> name,
    required ValueWithVariant<String> abbreviation,
    required ValueWithVariant<String> narrow,
  }) = _Era;
  const Era._();

  @override
  Expression toExpression() {
    return referCldr('Era')(
      [],
      {
        'name': name.toExpression(),
        'abbreviation': abbreviation.toExpression(),
        'narrow': narrow.toExpression(),
      },
    );
  }
}

@freezed
class DateOrTimeFormats<T extends ToExpression>
    with _$DateOrTimeFormats<T>
    implements ToExpression {
  const factory DateOrTimeFormats({
    required T full,
    required T long,
    required T medium,
    required T short,
  }) = _DateOrTimeFormats<T>;
  const DateOrTimeFormats._();

  factory DateOrTimeFormats.fromXml(
    CldrPath path,
    String elementName,
    T Function(CldrPath path) valueFromXml,
  ) {
    T resolve(String length) {
      return valueFromXml(
        path.child(
          '${elementName}Length',
          attributes: {'type': length},
        ).child(elementName),
      );
    }

    return DateOrTimeFormats(
      full: resolve('full'),
      long: resolve('long'),
      medium: resolve('medium'),
      short: resolve('short'),
    );
  }

  @override
  Expression toExpression() {
    return referCldr('DateOrTimeFormats')(
      [],
      {
        'full': full.toExpression(),
        'long': long.toExpression(),
        'medium': medium.toExpression(),
        'short': short.toExpression(),
      },
    );
  }
}

@freezed
class DateOrTimeFormat with _$DateOrTimeFormat implements ToExpression {
  const factory DateOrTimeFormat({
    required List<DateOrTimePatternPart> pattern,
    required String? displayName,
  }) = _DateOrTimeFormat;
  const DateOrTimeFormat._();

  factory DateOrTimeFormat.fromXml(CldrXml xml, CldrPath path) {
    return DateOrTimeFormat(
      pattern:
          DateOrTimePatternPart.parse(xml.resolveString(path.child('pattern'))),
      displayName: xml.resolveOptionalString(path.child('displayName')),
    );
  }

  @override
  Expression toExpression() {
    return referCldr('DateOrTimeFormat')(
      [],
      {
        'pattern': pattern.toExpression(),
        'displayName':
            displayName == null ? literalNull : literalString(displayName!),
      },
    );
  }
}

@freezed
class DateTimeFormats with _$DateTimeFormats implements ToExpression {
  const factory DateTimeFormats({
    required DateOrTimeFormats<DateTimeFormat> formats,
    // `TODO`(JonasWanke): Parse skeletons
    required Map<String, Plural<List<DateOrTimePatternPart>>> availableFormats,
    // `TODO`(JonasWanke): `<appendItems>`, `<intervalFormats>`
  }) = _DateTimeFormats;
  const DateTimeFormats._();

  factory DateTimeFormats.fromXml(CldrXml xml, CldrPath path) {
    return DateTimeFormats(
      formats: DateOrTimeFormats.fromXml(
        path,
        'dateTimeFormat',
        (path) => DateTimeFormat.fromXml(xml, path),
      ),
      availableFormats: xml
          .listChildElements(path.child('availableFormats'))
          .where((it) => it.localName == 'dateFormatItem')
          .map((it) => it.getAttribute('id')!)
          .toSet()
          .associateWith(
            (id) => Plural.fromXml(
              xml,
              path
                  .child('availableFormats')
                  .child('dateFormatItem', attributes: {'id': id}),
              (element) => DateOrTimePatternPart.parse(element.innerText),
            ),
          ),
    );
  }

  @override
  Expression toExpression() {
    return referCldr('DateTimeFormats')(
      [],
      {
        'formats': formats.toExpression(),
        'availableFormats': literalMap(
          availableFormats.map(
            (key, value) => MapEntry(literalString(key), value.toExpression()),
          ),
        ),
      },
    );
  }
}

@freezed
class DateTimeFormat with _$DateTimeFormat implements ToExpression {
  const factory DateTimeFormat({
    required List<DateTimePatternPart> pattern,
    required String? displayName,
  }) = _DateTimeFormat;
  const DateTimeFormat._();

  factory DateTimeFormat.fromXml(CldrXml xml, CldrPath path) {
    return DateTimeFormat(
      pattern:
          DateTimePatternPart.parse(xml.resolveString(path.child('pattern'))),
      displayName: xml.resolveOptionalString(path.child('displayName')),
    );
  }

  @override
  Expression toExpression() {
    return referCldr('DateTimeFormat')(
      [],
      {
        'pattern': pattern.toExpression(),
        'displayName':
            displayName == null ? literalNull : literalString(displayName!),
      },
    );
  }
}

@freezed
class DateTimePatternPart with _$DateTimePatternPart implements ToExpression {
  const factory DateTimePatternPart.literal(String value) =
      _DateTimePatternPartLiteral;
  const factory DateTimePatternPart.time() = _DateTimePatternPartTime;
  const factory DateTimePatternPart.date() = _DateTimePatternPartDate;
  const factory DateTimePatternPart.field(DateTimeField field) =
      _DateTimePatternPartField;
  const DateTimePatternPart._();

  static List<DateTimePatternPart> parse(String pattern) {
    final raw = DateOrTimePatternPart.parse(pattern);
    return raw.expand((it) {
      return it.when(
        literal: (value) {
          var lastOffset = 0;
          var offset = 0;
          final parts = <DateTimePatternPart>[];
          void addCurrent() {
            if (offset > lastOffset) {
              parts.add(
                DateTimePatternPart.literal(
                  value.substring(lastOffset, offset),
                ),
              );
            }
            lastOffset = offset;
          }

          while (offset < value.length) {
            final index = value.indexOf('{', offset);
            if (index < 0 ||
                index + 2 > value.length ||
                value[index + 2] != '}') {
              break;
            }

            offset = index;
            switch (value[index + 1]) {
              case '0':
                addCurrent();
                parts.add(const DateTimePatternPart.time());
                offset = lastOffset = index + 3;
              case '1':
                addCurrent();
                parts.add(const DateTimePatternPart.date());
                offset = lastOffset = index + 3;
              default:
                offset++;
            }
          }
          addCurrent();
          return parts;
        },
        field: (field) => [DateTimePatternPart.field(field)],
      );
    }).toList();
  }

  @override
  Expression toExpression() {
    Expression create(String name, [List<Expression> args = const []]) =>
        referCldr('DateTimePatternPart').newInstanceNamed(name, args);

    return when(
      literal: (value) => create('literal', [literalString(value)]),
      time: () => create('time', []),
      date: () => create('date', []),
      field: (field) => create('field', [field.toExpression()]),
    );
  }

  @override
  String toString() {
    return when(
      literal: (value) => "'${value.replaceAll("'", "''")}'",
      time: () => 'time',
      date: () => 'date',
      field: (field) => field.toString(),
    );
  }
}

@freezed
sealed class DateOrTimePatternPart
    with _$DateOrTimePatternPart
    implements ToExpression {
  const factory DateOrTimePatternPart.literal(String value) =
      _DateOrTimePatternPartLiteral;
  const factory DateOrTimePatternPart.field(DateTimeField field) =
      _DateOrTimePatternPartField;
  const DateOrTimePatternPart._();

  static List<DateOrTimePatternPart> parse(String pattern) {
    var offset = 0;
    final parts = <DateOrTimePatternPart>[];
    void addLiteral(String literal) {
      if (parts.lastOrNull is _DateOrTimePatternPartLiteral) {
        final last = parts.removeLast() as _DateOrTimePatternPartLiteral;
        parts.add(_DateOrTimePatternPartLiteral(last.value + literal));
      } else {
        parts.add(_DateOrTimePatternPartLiteral(literal));
      }
    }

    while (offset < pattern.length) {
      final character = pattern[offset];
      switch (character) {
        case "'" when offset + 1 < pattern.length && pattern[offset + 1] == "'":
          // Escaped quote
          addLiteral("'");
          offset += 2;
        case "'":
          // Quoted text
          while (true) {
            final end = pattern.indexOf("'", offset + 1);
            if (end < 0) {
              throw ArgumentError('Unclosed quote in pattern: `$pattern`');
            }

            addLiteral(pattern.substring(offset + 1, end));
            offset = end + 1;
            if (offset == pattern.length) break;

            if (pattern[offset] == "'") {
              addLiteral("'");
              offset++;
            } else {
              break;
            }
          }

        case _
            when 'a' <= character && character <= 'z' ||
                'A' <= character && character <= 'Z':
          // Field
          var length = 0;
          while (offset + length < pattern.length &&
              pattern[offset + length] == character) {
            length++;
          } // TODO(JonasWanke): Update to newer UTS version
          final field = switch ((character, length)) {
            ('G', >= 1 && <= 3) => const DateTimeField.eraAbbreviated(),
            ('G', 4) => const DateTimeField.eraLong(),
            ('G', 5) => const DateTimeField.eraNarrow(),
            ('y', _) => DateTimeField.year(minDigits: length),
            ('Y', _) => DateTimeField.weekBasedYear(minDigits: length),
            ('u', _) => const DateTimeField.extendedYear(),
            ('U', >= 1 && <= 3) =>
              const DateTimeField.cyclicYearNameAbbreviated(),
            ('U', 4) => const DateTimeField.cyclicYearNameFull(),
            ('U', 5) => const DateTimeField.cyclicYearNameNarrow(),
            ('Q', 1) => const DateTimeField.quarterNumerical(isPadded: false),
            ('Q', 2) => const DateTimeField.quarterNumerical(isPadded: true),
            ('Q', 3) => const DateTimeField.quarterAbbreviated(),
            ('Q', 4) => const DateTimeField.quarterFull(),
            ('q', >= 1 && <= 2) =>
              const DateTimeField.standaloneQuarterNumerical(),
            ('q', 3) => const DateTimeField.standaloneQuarterAbbreviated(),
            ('q', 4) => const DateTimeField.standaloneQuarterFull(),
            ('M', 1) => const DateTimeField.monthNumerical(isPadded: false),
            ('M', 2) => const DateTimeField.monthNumerical(isPadded: true),
            ('M', 3) => const DateTimeField.monthAbbreviated(),
            ('M', 4) => const DateTimeField.monthFull(),
            ('M', 5) => const DateTimeField.monthNarrow(),
            ('L', 1) =>
              const DateTimeField.standaloneMonthNumerical(isPadded: false),
            ('L', 2) =>
              const DateTimeField.standaloneMonthNumerical(isPadded: true),
            ('L', 3) => const DateTimeField.standaloneMonthAbbreviated(),
            ('L', 4) => const DateTimeField.standaloneMonthFull(),
            ('L', 5) => const DateTimeField.standaloneMonthNarrow(),
            ('w', 1) => const DateTimeField.weekOfYear(isPadded: false),
            ('w', 2) => const DateTimeField.weekOfYear(isPadded: true),
            ('W', 1) => const DateTimeField.weekOfMonth(),
            ('d', 1) => const DateTimeField.dayOfMonth(isPadded: false),
            ('d', 2) => const DateTimeField.dayOfMonth(isPadded: true),
            ('D', 1) =>
              const DateTimeField.dayOfYear(padding: DayOfYearPadding.one),
            ('D', 2) =>
              const DateTimeField.dayOfYear(padding: DayOfYearPadding.two),
            ('D', 3) =>
              const DateTimeField.dayOfYear(padding: DayOfYearPadding.three),
            ('F', 1) => const DateTimeField.dayOfWeekInMonth(),
            ('g', _) => const DateTimeField.modifiedJulianDay(),
            ('E', >= 1 && <= 3) ||
            ('e', 3) =>
              const DateTimeField.dayOfWeekShortDay(),
            ('E' || 'e', 4) => const DateTimeField.dayOfWeekFull(),
            ('E' || 'e', 5) => const DateTimeField.dayOfWeekNarrow(),
            ('E' || 'e', 6) => const DateTimeField.dayOfWeekShort(),
            ('e', >= 1 && <= 3) ||
            ('c', 1) =>
              const DateTimeField.localDayOfWeekNumeric(),
            ('c', 3) => const DateTimeField.standaloneLocalDayOfWeekShortDay(),
            ('c', 4) => const DateTimeField.standaloneLocalDayOfWeekFull(),
            ('c', 5) => const DateTimeField.standaloneLocalDayOfWeekNarrow(),
            ('c', 6) => const DateTimeField.standaloneLocalDayOfWeekShort(),
            ('a', 1) => const DateTimeField.period(),
            ('h', 1) => const DateTimeField.hour12(isPadded: false),
            ('h', 2) => const DateTimeField.hour12(isPadded: true),
            ('H', 1) => const DateTimeField.hour24(isPadded: false),
            ('H', 2) => const DateTimeField.hour24(isPadded: true),
            ('K', 1) => const DateTimeField.hour12ZeroBased(isPadded: false),
            ('K', 2) => const DateTimeField.hour12ZeroBased(isPadded: true),
            ('k', 1) => const DateTimeField.hour24OneBased(isPadded: false),
            ('k', 2) => const DateTimeField.hour24OneBased(isPadded: true),
            ('m', 1) => const DateTimeField.minute(isPadded: false),
            ('m', 2) => const DateTimeField.minute(isPadded: true),
            ('s', 1) => const DateTimeField.second(isPadded: false),
            ('s', 2) => const DateTimeField.second(isPadded: true),
            ('S', _) => DateTimeField.fractionalSecond(length),
            ('A', _) => DateTimeField.millisecondsInDay(length),
            ('z', >= 1 && <= 3) => const DateTimeField.zoneSpecificNonLocation(
                length: ZoneFieldLength.short,
              ),
            ('z', 4) => const DateTimeField.zoneSpecificNonLocation(
                length: ZoneFieldLength.long,
              ),
            ('Z' || 'O', 4) => const DateTimeField.zoneLocalizedGmt(
                length: ZoneFieldLength.long,
              ),
            ('O', 1) => const DateTimeField.zoneLocalizedGmt(
                length: ZoneFieldLength.short,
              ),
            ('v', 1) => const DateTimeField.zoneGenericNonLocation(
                length: ZoneFieldLength.short,
              ),
            ('v', 4) => const DateTimeField.zoneGenericNonLocation(
                length: ZoneFieldLength.long,
              ),
            ('V', 1) =>
              const DateTimeField.zoneID(length: ZoneFieldLength.short),
            ('V', 2) =>
              const DateTimeField.zoneID(length: ZoneFieldLength.long),
            ('V', 3) => const DateTimeField.zoneExemplarCity(),
            ('V', 4) => const DateTimeField.zoneGenericLocationFormat(),
            ('X', 1) => const DateTimeField.zoneIso8601(
                style: ZoneFieldIso8601Style.basicWithHoursOptionalMinutes,
                useZForZeroOffset: true,
              ),
            ('X', 2) => const DateTimeField.zoneIso8601(
                style: ZoneFieldIso8601Style.basicWithHoursMinutes,
                useZForZeroOffset: true,
              ),
            ('X', 3) => const DateTimeField.zoneIso8601(
                style: ZoneFieldIso8601Style.extendedWithHoursMinutes,
                useZForZeroOffset: true,
              ),
            ('X', 4) => const DateTimeField.zoneIso8601(
                style:
                    ZoneFieldIso8601Style.basicWithHoursMinutesOptionalSeconds,
                useZForZeroOffset: true,
              ),
            ('X' || 'Z', 5) => const DateTimeField.zoneIso8601(
                style: ZoneFieldIso8601Style
                    .extendedWithHoursMinutesOptionalSeconds,
                useZForZeroOffset: true,
              ),
            ('x', 1) => const DateTimeField.zoneIso8601(
                style: ZoneFieldIso8601Style.basicWithHoursOptionalMinutes,
                useZForZeroOffset: false,
              ),
            ('x', 2) => const DateTimeField.zoneIso8601(
                style: ZoneFieldIso8601Style.basicWithHoursMinutes,
                useZForZeroOffset: false,
              ),
            ('x', 3) => const DateTimeField.zoneIso8601(
                style: ZoneFieldIso8601Style.extendedWithHoursMinutes,
                useZForZeroOffset: false,
              ),
            ('x', 4) || ('Z', >= 1 && <= 3) => const DateTimeField.zoneIso8601(
                style:
                    ZoneFieldIso8601Style.basicWithHoursMinutesOptionalSeconds,
                useZForZeroOffset: false,
              ),
            ('x', 5) => const DateTimeField.zoneIso8601(
                style: ZoneFieldIso8601Style
                    .extendedWithHoursMinutesOptionalSeconds,
                useZForZeroOffset: false,
              ),
            _ => DateTimeField.unknown(character: character, length: length),
          };
          parts.add(DateOrTimePatternPart.field(field));
          offset += length;
        default:
          addLiteral(character);
          offset++;
      }
    }

    return parts;
  }

  @override
  Expression toExpression() {
    Expression create(String name, [List<Expression> args = const []]) =>
        referCldr('DateOrTimePatternPart').newInstanceNamed(name, args);

    return when(
      literal: (value) => create('literal', [literalString(value)]),
      field: (field) => create('field', [field.toExpression()]),
    );
  }

  @override
  String toString() {
    return when(
      literal: (value) => "'${value.replaceAll("'", "''")}'",
      field: (field) => field.toString(),
    );
  }
}

@freezed
sealed class DateTimeField with _$DateTimeField implements ToExpression {
  /// Era (abbreviated form), e.g., “AD”.
  ///
  /// Unicode Shorthand: `G`, `GG`, `GGG`
  const factory DateTimeField.eraAbbreviated() = _DateTimeFieldEraAbbreviated;

  /// Era (long form), e.g., “Anno Domini”.
  ///
  /// Unicode Shorthand: `GGGG`
  const factory DateTimeField.eraLong() = _DateTimeFieldEraLong;

  /// Era (narrow form), e.g., “A”.
  ///
  /// Unicode Shorthand: `GGGGG`
  const factory DateTimeField.eraNarrow() = _DateTimeFieldEraNarrow;

  /// Year, e.g., “1996”.
  ///
  /// Normally, the length specifies the padding, but for 2 it also specifies
  /// the maximum length. Example:
  ///
  /// | Year     |     1 |  2 |     3 |     4 |     5 |
  /// | :------- | ----: | -: |   --: | ----: | ----: |
  /// | AD 1     |     1 | 01 |   001 |  0001 | 00001 |
  /// | AD 12    |    12 | 12 |   012 |  0012 | 00012 |
  /// | AD 123   |   123 | 23 |   123 |  0123 | 00123 |
  /// | AD 1234  |  1234 | 34 |  1234 |  1234 | 01234 |
  /// | AD 12345 | 12345 | 45 | 12345 | 12345 | 12345 |
  ///
  /// Unicode Shorthand: `y`, `yy`, `yyy`, `yyyy`, `yyyyy`, etc.
  @Assert('minDigits >= 1')
  const factory DateTimeField.year({required int minDigits}) =
      _DateTimeFieldYear;

  /// Year (in "Week of Year" based calendars), e.g., “1997”.
  ///
  /// Normally, the length specifies the padding, but for 2 it also specifies
  /// the maximum length. This year designation is used in ISO year-week
  /// calendar as defined by ISO 8601, but can be used in non-Gregorian based
  /// calendar systems where week date processing is desired. May not always be
  /// the same value as calendar year.
  ///
  /// Unicode Shorthand: `Y`, `YY`, `YYY`, `YYYY`, `YYYYY`, etc.
  @Assert('minDigits >= 1')
  const factory DateTimeField.weekBasedYear({required int minDigits}) =
      _DateTimeFieldWeekBasedYear;

  /// Extended year, e.g., “4601”.
  ///
  /// This is a single number designating the year of this calendar system,
  /// encompassing all supra-year fields. For example, for the Julian calendar
  /// system, year numbers are positive, with an era of BCE or CE. An extended
  /// year value for the Julian calendar system assigns positive values to CE
  /// years and negative values to BCE years, with 1 BCE being year 0.
  ///
  /// Unicode Shorthand: `u`
  const factory DateTimeField.extendedYear() = _DateTimeFieldExtendedYear;

  /// Cyclic year name (abbreviated), e.g., “甲子”.
  ///
  /// Calendars such as the Chinese lunar calendar (and related calendars) and
  /// the Hindu calendars use 60-year cycles of year names.
  ///
  /// If the calendar does not provide cyclic year name data, or if the year
  /// value to be formatted is out of the range of years for which cyclic name
  /// data is provided, then numeric formatting is used (behaves like "y").
  ///
  /// Unicode Shorthand: `U`, `UU`, `UUU`
  const factory DateTimeField.cyclicYearNameAbbreviated() =
      _DateTimeFieldCyclicYearNameAbbreviated;

  /// Cyclic year name (full name), e.g., “甲子”.
  ///
  /// Calendars such as the Chinese lunar calendar (and related calendars) and
  /// the Hindu calendars use 60-year cycles of year names.
  ///
  /// If the calendar does not provide cyclic year name data, or if the year
  /// value to be formatted is out of the range of years for which cyclic name
  /// data is provided, then numeric formatting is used (behaves like "y").
  ///
  /// Note: Currently the data only provides abbreviated names, which will be
  /// used for all requested name widths.
  ///
  /// Unicode Shorthand: `UUUU`
  const factory DateTimeField.cyclicYearNameFull() =
      _DateTimeFieldCyclicYearNameFull;

  /// Cyclic year name (narrow name), e.g., “甲子”.
  ///
  /// Calendars such as the Chinese lunar calendar (and related calendars) and
  /// the Hindu calendars use 60-year cycles of year names.
  ///
  /// If the calendar does not provide cyclic year name data, or if the year
  /// value to be formatted is out of the range of years for which cyclic name
  /// data is provided, then numeric formatting is used (behaves like "y").
  ///
  /// Note: Currently the data only provides abbreviated names, which will be
  /// used for all requested name widths.
  ///
  /// Unicode Shorthand: `UUUUU`
  const factory DateTimeField.cyclicYearNameNarrow() =
      _DateTimeFieldCyclicYearNameNarrow;

  /// Quarter (numerical), e.g., “2” (not padded) or “02” (padded).
  ///
  /// Unicode Shorthand: `Q` (not padded), `QQ` (padded)
  const factory DateTimeField.quarterNumerical({required bool isPadded}) =
      _DateTimeFieldQuarterNumerical;

  /// Quarter (abbreviated), e.g., “Q2”.
  ///
  /// Unicode Shorthand: `QQQ`
  const factory DateTimeField.quarterAbbreviated() =
      _DateTimeFieldQuarterAbbreviated;

  /// Quarter (full name), e.g., “2nd quarter”.
  ///
  /// Unicode Shorthand: `QQQQ`
  const factory DateTimeField.quarterFull() = _DateTimeFieldQuarterFull;

  /// Stand-Alone Quarter (numerical), e.g., “02”.
  ///
  /// Unicode Shorthand: `q`, `qq`
  const factory DateTimeField.standaloneQuarterNumerical() =
      _DateTimeFieldStandaloneQuarterNumerical;

  /// Stand-Alone Quarter (abbreviated), e.g., “Q2”.
  ///
  /// Unicode Shorthand: `qqq`
  const factory DateTimeField.standaloneQuarterAbbreviated() =
      _DateTimeFieldStandaloneQuarterAbbreviated;

  /// Stand-Alone Quarter (full name), e.g., “2nd quarter”.
  ///
  /// Unicode Shorthand: `qqqq`
  const factory DateTimeField.standaloneQuarterFull() =
      _DateTimeFieldStandaloneQuarterFull;

  /// Month (numerical), e.g., “0” (not padded) or “09” (padded).
  ///
  /// Unicode Shorthand: `M` (not padded), `MM` (padded)
  const factory DateTimeField.monthNumerical({required bool isPadded}) =
      _DateTimeFieldMonthNumerical;

  /// Month (abbreviation), e.g., “Sept”.
  ///
  /// Unicode Shorthand: `MMM`
  const factory DateTimeField.monthAbbreviated() =
      _DateTimeFieldMonthAbbreviated;

  /// Month (full name), e.g., “September”.
  ///
  /// Unicode Shorthand: `MMMM`
  const factory DateTimeField.monthFull() = _DateTimeFieldMonthFull;

  /// Month (narrow), e.g., “S”.
  ///
  /// Unicode Shorthand: `MMMMM`
  const factory DateTimeField.monthNarrow() = _DateTimeFieldMonthNarrow;

  /// Stand-Alone Month (numerical), e.g., “9” (not padded) or “09” (padded).
  ///
  /// Unicode Shorthand: `L` (not padded), `LL` (padded)
  const factory DateTimeField.standaloneMonthNumerical({
    required bool isPadded,
  }) = _DateTimeFieldStandaloneMonthNumerical;

  /// Stand-Alone Month (abbreviated), e.g., “Sept”.
  ///
  /// Unicode Shorthand: `LLL`
  const factory DateTimeField.standaloneMonthAbbreviated() =
      _DateTimeFieldStandaloneMonthAbbreviated;

  /// Stand-Alone Month (full), e.g., September”.
  ///
  /// Unicode Shorthand: `LLLL`
  const factory DateTimeField.standaloneMonthFull() =
      _DateTimeFieldStandaloneMonthFull;

  /// Stand-Alone Month (narrow), e.g., “S”.
  ///
  /// Unicode Shorthand: `LLLLL`
  const factory DateTimeField.standaloneMonthNarrow() =
      _DateTimeFieldStandaloneMonthNarrow;

  /// Week of Year, e.g., “27”.
  ///
  /// Unicode Shorthand: `w` (not padded), `ww` (padded)
  const factory DateTimeField.weekOfYear({required bool isPadded}) =
      _DateTimeFieldWeekOfYear;

  /// Week of Month, e.g., “3”.
  ///
  /// Unicode Shorthand: `W`
  const factory DateTimeField.weekOfMonth() = _DateTimeFieldWeekOfMonth;

  /// Date - Day of the month, e.g., “1”.
  ///
  /// Unicode Shorthand: `d` (not padded), `dd` (padded)
  const factory DateTimeField.dayOfMonth({required bool isPadded}) =
      _DateTimeFieldDayOfMonth;

  /// Day of year, e.g., “345”.
  ///
  /// Unicode Shorthand: `D` (padded to one digit), `DD` (padded to two digits),
  /// `DDD` (padded to three digits)
  const factory DateTimeField.dayOfYear({required DayOfYearPadding padding}) =
      _DateTimeFieldDayOfYear;

  /// Day of Week in Month, e.g., “2”.
  ///
  /// The example is for the 2nd Wed in July
  ///
  /// Unicode Shorthand: `F`
  const factory DateTimeField.dayOfWeekInMonth() =
      _DateTimeFieldDayOfWeekInMonth;

  /// Modified Julian day.
  ///
  /// This is different from the conventional Julian day number in two regards.
  /// First, it demarcates days at local zone midnight, rather than noon GMT.
  /// Second, it is a local number; that is, it depends on the local time zone.
  /// It can be thought of as a single number that encompasses all the
  /// date-related fields.
  ///
  /// Unicode Shorthand: `g`
  const factory DateTimeField.modifiedJulianDay() =
      _DateTimeFieldModifiedJulianDay;

  /// Day of Week (short day), e.g., “Tues”.
  ///
  /// Unicode Shorthand: `E`, `EE`, `EEE`, `eee`
  const factory DateTimeField.dayOfWeekShortDay() =
      _DateTimeFieldDayOfWeekShortDay;

  /// Day of Week (full name), e.g., “Tuesday”.
  ///
  /// Unicode Shorthand: `EEEE`, `eeee`
  const factory DateTimeField.dayOfWeekFull() = _DateTimeFieldDayOfWeekFull;

  /// Day of Week (narrow name), e.g., “T”.
  ///
  /// Unicode Shorthand: `EEEEE`, `eeeee`
  const factory DateTimeField.dayOfWeekNarrow() = _DateTimeFieldDayOfWeekNarrow;

  /// Day of Week (short name), e.g., “Tu”.
  ///
  /// Unicode Shorthand: `EEEEEE`, `eeeeee`
  const factory DateTimeField.dayOfWeekShort() = _DateTimeFieldDayOfWeekShort;

  /// Local Day of Week (numeric), e.g., “2”.
  ///
  /// Unicode Shorthand: `e`, `ee`, `c`
  const factory DateTimeField.localDayOfWeekNumeric() =
      _DateTimeFieldLocalDayOfWeekNumeric;

  /// Stand-Alone Local Day of Week (short day), e.g., “Tues”.
  ///
  /// Unicode Shorthand: `ccc`
  const factory DateTimeField.standaloneLocalDayOfWeekShortDay() =
      _DateTimeFieldStandaloneLocalDayOfWeekShortDay;

  /// Stand-Alone Local Day of Week (full name), e.g., “Tuesday”.
  ///
  /// Unicode Shorthand: `cccc`
  const factory DateTimeField.standaloneLocalDayOfWeekFull() =
      _DateTimeFieldStandaloneLocalDayOfWeekFull;

  /// Stand-Alone Local Day of Week (narrow name), e.g., “T”.
  ///
  /// Unicode Shorthand: `ccccc`
  const factory DateTimeField.standaloneLocalDayOfWeekNarrow() =
      _DateTimeFieldStandaloneLocalDayOfWeekNarrow;

  /// Stand-Alone Local Day of Week (short name), e.g., “Tu”.
  ///
  /// Unicode Shorthand: `cccccc`
  const factory DateTimeField.standaloneLocalDayOfWeekShort() =
      _DateTimeFieldStandaloneLocalDayOfWeekShort;

  /// Period (AM or PM), e.g., “AM”.
  ///
  /// Unicode Shorthand: `a`
  const factory DateTimeField.period() = _DateTimeFieldPeriod;

  /// Hour (1 – 12), e.g., “11”.
  ///
  /// Unicode Shorthand: `h`, `hh`
  const factory DateTimeField.hour12({required bool isPadded}) =
      _DateTimeFieldHour12;

  /// Hour (0 – 23), e.g., “13”.
  ///
  /// Unicode Shorthand: `H`, `HH`
  const factory DateTimeField.hour24({required bool isPadded}) =
      _DateTimeFieldHour24;

  /// Hour (0 – 11), e.g., “0” or “00”.
  ///
  /// Unicode Shorthand: `K`, `KK`
  const factory DateTimeField.hour12ZeroBased({required bool isPadded}) =
      _DateTimeFieldHour12ZeroBased;

  /// Hour (1 – 24), e.g., “24”.
  ///
  /// Unicode Shorthand: `k`, `kk`
  const factory DateTimeField.hour24OneBased({required bool isPadded}) =
      _DateTimeFieldHour24OneBased;

  /// Minute, e.g., “59”.
  ///
  /// Unicode Shorthand: `m`, `mm`
  const factory DateTimeField.minute({required bool isPadded}) =
      _DateTimeFieldMinute;

  /// Second, e.g., “12”.
  ///
  /// Unicode Shorthand: `s`, `ss`
  const factory DateTimeField.second({required bool isPadded}) =
      _DateTimeFieldSecond;

  /// Fractional Second, e.g., “3456”.
  ///
  /// Unicode Shorthand: `S`, `SS`, etc.
  @Assert('digits >= 1')
  const factory DateTimeField.fractionalSecond(int digits) =
      _DateTimeFieldFractionalSecond;

  /// Milliseconds in day, e.g., “69540000”.
  ///
  /// This field behaves exactly like a composite of all time-related fields,
  /// not including the zone fields. As such, it also reflects discontinuities
  /// of those fields on DST transition days. On a day of DST onset, it will
  /// jump forward. On a day of DST cessation, it will jump backward. This
  /// reflects the fact that is must be combined with the offset field to obtain
  /// a unique local time value.
  ///
  /// Unicode Shorthand: `A`, `AA`, etc.
  @Assert('digits >= 1')
  const factory DateTimeField.millisecondsInDay(int digits) =
      _DateTimeFieldMillisecondsInDay;

  /// The specific non-location format, e.g., “PDT” (short) or “Pacific Daylight
  /// Time” (long).
  ///
  /// Short: Where that is unavailable, falls back to the short localized GMT
  /// format (“O”).
  ///
  /// Long: Where that is unavailable, falls back to the long localized GMT
  /// format (“OOOO”).
  ///
  /// Unicode Shorthand: `z`, `zz`, `zzz` (short), `zzzz` (long)
  const factory DateTimeField.zoneSpecificNonLocation({
    required ZoneFieldLength length,
  }) = _DateTimeFieldZoneSpecificNonLocation;

  /// The localized GMT format, e.g., “GMT-8” (short) or “GMT-08:00” (long).
  ///
  /// Unicode Shorthand: `O` (short), `ZZZZ`, `OOOO` (long)
  // `TODO`(JonasWanke): check example since the spec conflicts itself
  const factory DateTimeField.zoneLocalizedGmt({
    required ZoneFieldLength length,
  }) = _DateTimeFieldZoneLocalizedGmt;

  /// The generic non-location format, e.g., “PT” (short) or “Pacific Time”
  /// (long).
  ///
  /// Short: Where that is unavailable, falls back to the generic location
  /// format (“VVVV”), then the short localized GMT format as the final
  /// fallback.
  ///
  /// Long: Where that is unavailable, falls back to generic location format
  /// (“VVVV”).
  ///
  /// Unicode Shorthand: `v` (short), `vvvv` (long)
  const factory DateTimeField.zoneGenericNonLocation({
    required ZoneFieldLength length,
  }) = _DateTimeFieldZoneGenericNonLocation;

  /// The time zone ID, e.g., “uslax” (short) or “America/Los_Angeles” (long).
  ///
  /// Short: Where that is unavailable, the special short time zone ID `unk`
  /// (Unknown Zone) is used.
  ///
  /// Short: Note: This specifier was originally used for a variant of the short
  /// specific non-location format, but it was deprecated in the later version
  /// of this specification. In CLDR 23, the definition of the specifier was
  /// changed to designate a short time zone ID.
  ///
  /// Unicode Shorthand: `V` (short), `VV` (long)
  const factory DateTimeField.zoneID({required ZoneFieldLength length}) =
      _DateTimeFieldZoneID;

  /// The exemplar city (location) for the time zone, e.g., “Los Angeles”.
  ///
  /// Where that is unavailable, the localized exemplar city name for the
  /// special zone Etc/Unknown is used as the fallback (for example, “Unknown
  /// City”).
  ///
  /// Unicode Shorthand: `VVV`
  const factory DateTimeField.zoneExemplarCity() =
      _DateTimeFieldZoneExemplarCity;

  /// The generic location format, e.g., “Los Angeles Time”.
  ///
  /// Where that is unavailable, falls back to the long localized GMT format
  /// (“OOOO”; Note: Fallback is only necessary with a GMT-style Time Zone ID,
  /// like Etc/GMT-830.) This is especially useful when presenting possible
  /// timezone choices for user selection, since the naming is more uniform than
  /// the `v` format.
  ///
  /// Unicode Shorthand: `VVVV`
  const factory DateTimeField.zoneGenericLocationFormat() =
      _DateTimeFieldZoneGenericLocationFormat;

  /// An ISO 8601 basic format, see [ZoneFieldIso8601Style] for details.
  ///
  /// With [useZForZeroOffset] set to `true`, the ISO 8601 UTC indicator “Z” is
  /// used when local time offset is 0.
  ///
  /// Unicode Shorthand: See [ZoneFieldIso8601Style]
  const factory DateTimeField.zoneIso8601({
    required ZoneFieldIso8601Style style,
    required bool useZForZeroOffset,
  }) = _DateTimeFieldZoneIso8601Basic;

  const factory DateTimeField.unknown({
    required String character,
    required int length,
  }) = _DateTimeFieldUnknown;

  const DateTimeField._();

  @override
  Expression toExpression() {
    Expression create(
      String name, [
      Map<String, Expression> args = const {},
    ]) =>
        referCldr('DateTimeField').newInstanceNamed(name, [], args);

    return when(
      eraAbbreviated: () => create('eraAbbreviated'),
      eraLong: () => create('eraLong'),
      eraNarrow: () => create('eraNarrow'),
      year: (minDigits) => create('year', {'minDigits': literalNum(minDigits)}),
      weekBasedYear: (minDigits) =>
          create('weekBasedYear', {'minDigits': literalNum(minDigits)}),
      extendedYear: () => create('extendedYear'),
      cyclicYearNameAbbreviated: () => create('cyclicYearNameAbbreviated'),
      cyclicYearNameFull: () => create('cyclicYearNameFull'),
      cyclicYearNameNarrow: () => create('cyclicYearNameNarrow'),
      quarterNumerical: (isPadded) =>
          create('quarterNumerical', {'isPadded': literalBool(isPadded)}),
      quarterAbbreviated: () => create('quarterAbbreviated'),
      quarterFull: () => create('quarterFull'),
      standaloneQuarterNumerical: () => create('standaloneQuarterNumerical'),
      standaloneQuarterAbbreviated: () =>
          create('standaloneQuarterAbbreviated'),
      standaloneQuarterFull: () => create('standaloneQuarterFull'),
      monthNumerical: (isPadded) =>
          create('monthNumerical', {'isPadded': literalBool(isPadded)}),
      monthAbbreviated: () => create('monthAbbreviated'),
      monthFull: () => create('monthFull'),
      monthNarrow: () => create('monthNarrow'),
      standaloneMonthNumerical: (isPadded) => create(
        'standaloneMonthNumerical',
        {'isPadded': literalBool(isPadded)},
      ),
      standaloneMonthAbbreviated: () => create('standaloneMonthAbbreviated'),
      standaloneMonthFull: () => create('standaloneMonthFull'),
      standaloneMonthNarrow: () => create('standaloneMonthNarrow'),
      weekOfYear: (isPadded) =>
          create('weekOfYear', {'isPadded': literalBool(isPadded)}),
      weekOfMonth: () => create('weekOfMonth'),
      dayOfMonth: (isPadded) =>
          create('dayOfMonth', {'isPadded': literalBool(isPadded)}),
      dayOfYear: (padding) =>
          create('dayOfYear', {'padding': padding.toExpression()}),
      dayOfWeekInMonth: () => create('dayOfWeekInMonth'),
      modifiedJulianDay: () => create('modifiedJulianDay'),
      dayOfWeekShortDay: () => create('dayOfWeekShortDay'),
      dayOfWeekFull: () => create('dayOfWeekFull'),
      dayOfWeekNarrow: () => create('dayOfWeekNarrow'),
      dayOfWeekShort: () => create('dayOfWeekShort'),
      localDayOfWeekNumeric: () => create('localDayOfWeekNumeric'),
      standaloneLocalDayOfWeekShortDay: () =>
          create('standaloneLocalDayOfWeekShortDay'),
      standaloneLocalDayOfWeekFull: () =>
          create('standaloneLocalDayOfWeekFull'),
      standaloneLocalDayOfWeekNarrow: () =>
          create('standaloneLocalDayOfWeekNarrow'),
      standaloneLocalDayOfWeekShort: () =>
          create('standaloneLocalDayOfWeekShort'),
      period: () => create('period'),
      hour12: (isPadded) =>
          create('hour12', {'isPadded': literalBool(isPadded)}),
      hour24: (isPadded) =>
          create('hour24', {'isPadded': literalBool(isPadded)}),
      hour12ZeroBased: (isPadded) =>
          create('hour12ZeroBased', {'isPadded': literalBool(isPadded)}),
      hour24OneBased: (isPadded) =>
          create('hour24OneBased', {'isPadded': literalBool(isPadded)}),
      minute: (isPadded) =>
          create('minute', {'isPadded': literalBool(isPadded)}),
      second: (isPadded) =>
          create('second', {'isPadded': literalBool(isPadded)}),
      fractionalSecond: (digits) =>
          create('fractionalSecond', {'digits': literalNum(digits)}),
      millisecondsInDay: (digits) =>
          create('millisecondsInDay', {'digits': literalNum(digits)}),
      zoneSpecificNonLocation: (length) =>
          create('zoneSpecificNonLocation', {'length': length.toExpression()}),
      zoneLocalizedGmt: (length) =>
          create('zoneLocalizedGmt', {'length': length.toExpression()}),
      zoneGenericNonLocation: (length) =>
          create('zoneGenericNonLocation', {'length': length.toExpression()}),
      zoneID: (length) => create('zoneID', {'length': length.toExpression()}),
      zoneExemplarCity: () => create('zoneExemplarCity'),
      zoneGenericLocationFormat: () => create('zoneGenericLocationFormat'),
      zoneIso8601: (style, useZForZeroOffset) => create(
        'zoneIso8601',
        {
          'style': style.toExpression(),
          'useZForZeroOffset': literalBool(useZForZeroOffset),
        },
      ),
      unknown: (character, length) => create('unknown', {
        'character': literalString(character),
        'length': literalNum(length),
      }),
    );
  }
}

enum DayOfYearPadding implements ToExpression {
  one,
  two,
  three;

  @override
  Expression toExpression() => referCldr('DayOfYearPadding').property(name);
}

enum ZoneFieldLength implements ToExpression {
  short,
  long;

  @override
  Expression toExpression() => referCldr('ZoneFieldLength').property(name);
}

enum ZoneFieldIso8601Style implements ToExpression {
  /// The ISO 8601 basic format with hours field and optional minutes field,
  /// e.g., “-08” or “+0530”.
  ///
  /// Unicode Shorthand: `X` (with “Z” for zero offset), `x` (without “Z” for
  /// zero offset)
  basicWithHoursOptionalMinutes,

  /// The ISO 8601 basic format with hours and minutes fields, e.g., “-0800”.
  ///
  /// The format (without “Z” for zero offset) is equivalent to RFC 822 zone
  /// format.
  ///
  /// Unicode Shorthand: `XX` (with “Z” for zero offset), `xx`, `Z`, `ZZ`, `ZZZ`
  /// (without “Z” for zero offset)
  basicWithHoursMinutes,

  /// The ISO 8601 extended format with hours and minutes fields, e.g.,
  ///
  /// Unicode Shorthand: `XXX` (with “Z” for zero offset), `xxx` (without “Z”
  /// for zero offset)
  /// “-08:00”.
  extendedWithHoursMinutes,

  /// The ISO 8601 basic format with hours, minutes and optional seconds fields,
  /// e.g., “-0800” or “-075258”.
  ///
  /// Note: The seconds field is not supported by the ISO 8601 specification.
  ///
  /// Unicode Shorthand: `XXXX` (with “Z” for zero offset), `xxxx` (without “Z”
  /// for zero offset)
  basicWithHoursMinutesOptionalSeconds,

  /// The ISO 8601 extended format with hours, minutes and optional seconds
  /// fields, e.g., “-08:00” or “-07:52:58”.
  ///
  /// Note: The seconds field is not supported by the ISO 8601 specification.
  ///
  /// Unicode Shorthand: `XXXXX`, `ZZZZZ` (with “Z” for zero offset), `xxxxx`
  /// (without “Z” for zero offset)
  extendedWithHoursMinutesOptionalSeconds;

  @override
  Expression toExpression() =>
      referCldr('ZoneFieldIso8601Style').property(name);
}

@freezed
class Fields with _$Fields implements ToExpression {
  const factory Fields({
    required FieldWidths era,
    required FieldWidths year,
    required FieldWidths quarter,
    required FieldWidths month,
    required FieldWidths week,
    required FieldWidths weekOfMonth,
    required FieldWidths day,
    required FieldWidths dayOfYear,
    required FieldWidths weekday,
    required FieldWidths weekdayOfMonth,
    required FieldWidths sun,
    required FieldWidths mon,
    required FieldWidths tue,
    required FieldWidths wed,
    required FieldWidths thu,
    required FieldWidths fri,
    required FieldWidths sat,
    required FieldWidths dayperiod,
    required FieldWidths hour,
    required FieldWidths minute,
    required FieldWidths second,
    required FieldWidths zone,
  }) = _Fields;
  const Fields._();

  factory Fields.fromXml(CldrXml xml, CldrPath path) {
    FieldWidths fieldFromXml(String type) {
      return FieldWidths(
        full:
            Field.fromXml(xml, path.child('field', attributes: {'type': type})),
        short: Field.fromXml(
          xml,
          path.child('field', attributes: {'type': '$type-short'}),
        ),
        narrow: Field.fromXml(
          xml,
          path.child('field', attributes: {'type': '$type-narrow'}),
        ),
      );
    }

    return Fields(
      era: fieldFromXml('era'),
      year: fieldFromXml('year'),
      quarter: fieldFromXml('quarter'),
      month: fieldFromXml('month'),
      week: fieldFromXml('week'),
      weekOfMonth: fieldFromXml('weekOfMonth'),
      day: fieldFromXml('day'),
      dayOfYear: fieldFromXml('dayOfYear'),
      weekday: fieldFromXml('weekday'),
      weekdayOfMonth: fieldFromXml('weekdayOfMonth'),
      sun: fieldFromXml('sun'),
      mon: fieldFromXml('mon'),
      tue: fieldFromXml('tue'),
      wed: fieldFromXml('wed'),
      thu: fieldFromXml('thu'),
      fri: fieldFromXml('fri'),
      sat: fieldFromXml('sat'),
      dayperiod: fieldFromXml('dayperiod'),
      hour: fieldFromXml('hour'),
      minute: fieldFromXml('minute'),
      second: fieldFromXml('second'),
      zone: fieldFromXml('zone'),
    );
  }

  @override
  Expression toExpression() {
    return referCldr('Fields')(
      [],
      {
        'era': era.toExpression(),
        'year': year.toExpression(),
        'quarter': quarter.toExpression(),
        'month': month.toExpression(),
        'week': week.toExpression(),
        'weekOfMonth': weekOfMonth.toExpression(),
        'day': day.toExpression(),
        'dayOfYear': dayOfYear.toExpression(),
        'weekday': weekday.toExpression(),
        'weekdayOfMonth': weekdayOfMonth.toExpression(),
        'sun': sun.toExpression(),
        'mon': mon.toExpression(),
        'tue': tue.toExpression(),
        'wed': wed.toExpression(),
        'thu': thu.toExpression(),
        'fri': fri.toExpression(),
        'sat': sat.toExpression(),
        'dayperiod': dayperiod.toExpression(),
        'hour': hour.toExpression(),
        'minute': minute.toExpression(),
        'second': second.toExpression(),
        'zone': zone.toExpression(),
      },
    );
  }
}

@freezed
class FieldWidths with _$FieldWidths implements ToExpression {
  const factory FieldWidths({
    required Field full,
    required Field short,
    required Field narrow,
  }) = _FieldWidths;
  const FieldWidths._();

  @override
  Expression toExpression() {
    return referCldr('FieldWidths')(
      [],
      {
        'full': full.toExpression(),
        'short': short.toExpression(),
        'narrow': narrow.toExpression(),
      },
    );
  }
}

@freezed
class Field with _$Field implements ToExpression {
  const factory Field({
    required String? displayName,
    required Map<int, String> relative,
    // `TODO`(JonasWanke): parse placeholder position
    required Plural<String>? relativeTimePast,
    required Plural<String>? relativeTimeFuture,
  }) = _Field;
  const Field._();

  factory Field.fromXml(CldrXml xml, CldrPath path) {
    return Field(
      displayName: xml.resolveOptionalString(path.child('displayName')),
      relative: xml.listChildElements(path.child('relative')).associate(
            (it) => MapEntry(int.parse(it.getAttribute('type')!), it.innerText),
          ),
      relativeTimePast: xml
          .listChildElements(path.child('relativeTime'))
          .where((it) => it.getAttribute('type') == 'past')
          .map(
            (it) =>
                Plural.stringsFromXml(xml, path.child('relativeTimePattern')),
          )
          .firstOrNull,
      relativeTimeFuture: xml
          .listChildElements(path.child('relativeTime'))
          .where((it) => it.getAttribute('type') == 'future')
          .map(
            (it) =>
                Plural.stringsFromXml(xml, path.child('relativeTimePattern')),
          )
          .firstOrNull,
    );
  }

  @override
  Expression toExpression() {
    return referCldr('Field')(
      [],
      {
        'displayName':
            displayName == null ? literalNull : literalString(displayName!),
        'relative': literalMap(
          relative.map(
            (key, value) => MapEntry(literalNum(key), literalString(value)),
          ),
        ),
        'relativeTimePast': relativeTimePast == null
            ? literalNull
            : relativeTimePast!.toExpression(),
        'relativeTimeFuture': relativeTimeFuture == null
            ? literalNull
            : relativeTimeFuture!.toExpression(),
      },
    );
  }
}

// Common

@freezed
class Context<T extends ToExpression>
    with _$Context<T>
    implements ToExpression {
  const factory Context({
    /// The form used within a date format string (such as "Saturday, November
    /// 12th").
    required T format,

    /// The form used independently, such as in calendar headers.
    required T standalone,
  }) = _Context<T>;
  const Context._();

  factory Context.fromXml(
    CldrPath path,
    T Function(CldrPath path) valueFromXml,
  ) {
    return Context(
      format: valueFromXml(path.withAttribute('type', 'format')),
      standalone: valueFromXml(path.withAttribute('type', 'stand-alone')),
    );
  }

  @override
  Expression toExpression() {
    return referCldr('Context')(
      [],
      {
        'format': format.toExpression(),
        'standalone': standalone.toExpression(),
      },
    );
  }
}

@freezed
class Widths<T extends Object> with _$Widths<T> implements ToExpression {
  const factory Widths({
    /// The default.
    required T wide,
    required T abbreviated,
    required T narrow,
  }) = _Widths<T>;
  const Widths._();

  factory Widths.fromXml(
    CldrPath path,
    T Function(CldrPath path) valueFromXml,
  ) {
    return Widths(
      wide: valueFromXml(path.withAttribute('type', 'wide')),
      abbreviated: valueFromXml(path.withAttribute('type', 'abbreviated')),
      narrow: valueFromXml(path.withAttribute('type', 'narrow')),
    );
  }

  @override
  Expression toExpression() {
    return referCldr('Widths')(
      [],
      {
        'wide': ToExpression.convert(wide),
        'abbreviated': ToExpression.convert(abbreviated),
        'narrow': ToExpression.convert(narrow),
      },
    );
  }
}
