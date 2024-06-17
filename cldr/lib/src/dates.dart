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
    required DateOrTimeFormats<DateOrTimeFormat<DateField>> dateFormats,
    required DateOrTimeFormats<DateOrTimeFormat<TimeField>> timeFormats,
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
        (path) => DateOrTimeFormat.fromXml(xml, path, DateField.parse),
      ),
      timeFormats: DateOrTimeFormats.fromXml(
        path.child('timeFormats'),
        'timeFormat',
        (path) => DateOrTimeFormat.fromXml(xml, path, TimeField.parse),
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

  Days operator [](DayFieldWidth width) {
    return switch (width) {
      DayFieldWidth.wide => wide,
      DayFieldWidth.abbreviated => abbreviated,
      DayFieldWidth.short => short,
      DayFieldWidth.narrow => narrow,
    };
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

enum DayFieldWidth implements ToExpression {
  wide,
  abbreviated,
  short,
  narrow;

  @override
  Expression toExpression() => referCldr('DayFieldWidth').property(name);
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

  T operator [](DateOrTimeFormatWidth width) {
    return switch (width) {
      DateOrTimeFormatWidth.full => full,
      DateOrTimeFormatWidth.long => long,
      DateOrTimeFormatWidth.medium => medium,
      DateOrTimeFormatWidth.short => short,
    };
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
class DateOrTimeFormat<F extends ToExpression>
    with _$DateOrTimeFormat<F>
    implements ToExpression {
  const factory DateOrTimeFormat({
    required List<DateOrTimePatternPart> pattern,
    required String? displayName,
  }) = _DateOrTimeFormat<F>;
  const DateOrTimeFormat._();

  factory DateOrTimeFormat.fromXml(
    CldrXml xml,
    CldrPath path,
    ParseDateOrTimePatternField<F> parseField,
  ) {
    return DateOrTimeFormat(
      pattern: DateOrTimePatternPart.parse(
        xml.resolveString(path.child('pattern')),
        parseField,
      ),
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
    required Map<String, Plural<List<DateOrTimePatternPart<DateTimeField>>>>
        availableFormats,
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
              (element) => DateOrTimePatternPart.parse(
                element.innerText,
                DateTimeField.parse,
              ),
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
    final raw = DateOrTimePatternPart.parse(pattern, DateTimeField.parse);
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
sealed class DateOrTimePatternPart<F extends ToExpression>
    with _$DateOrTimePatternPart<F>
    implements ToExpression {
  const factory DateOrTimePatternPart.literal(String value) =
      _DateOrTimePatternPartLiteral<F>;
  const factory DateOrTimePatternPart.field(F field) =
      _DateOrTimePatternPartField<F>;
  const DateOrTimePatternPart._();

  static List<DateOrTimePatternPart<F>> parse<F extends ToExpression>(
    String pattern,
    ParseDateOrTimePatternField<F> parseField,
  ) {
    var offset = 0;
    final parts = <DateOrTimePatternPart<F>>[];
    void addLiteral(String literal) {
      if (parts.lastOrNull is _DateOrTimePatternPartLiteral<F>) {
        final last = parts.removeLast() as _DateOrTimePatternPartLiteral<F>;
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
          }
          final field = parseField(character, length) ??
              (throw FormatException('Unknown field: `${character * length}`'));
          parts.add(DateOrTimePatternPart.field(field));
          offset += length;
        default:
          // Unquoted text
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

typedef ParseDateOrTimePatternField<F extends ToExpression> = F? Function(
  String character,
  int length,
);

@freezed
sealed class DateTimeField with _$DateTimeField implements ToExpression {
  const factory DateTimeField.dateField(DateField field) =
      _DateTimeFieldDateField;
  const factory DateTimeField.timeField(TimeField field) =
      _DateTimeFieldTimeField;
  const DateTimeField._();

  static DateTimeField? parse(String character, int length) {
    return DateField.parse(character, length)?.let(DateTimeField.dateField) ??
        TimeField.parse(character, length)?.let(DateTimeField.timeField);
  }

  @override
  Expression toExpression() {
    final create = referCldr('DateTimeField').newInstanceNamed;
    return when(
      dateField: (field) => create('dateField', [field.toExpression()]),
      timeField: (field) => create('timeField', [field.toExpression()]),
    );
  }
}

@freezed
sealed class DateField with _$DateField implements ToExpression {
  /// Era name:
  ///
  /// | Width         | Example                           | Unicode Shorthand |
  /// | :------------ | :-------------------------------- | :---------------- |
  /// | `wide`        | Anno Domini (variant: Common Era) | `GGGG`            |
  /// | `abbreviated` | AD (variant: CE)                  | `G`, `GG`, `GGG`  |
  /// | `narrow`      | A                                 | `GGGGG`           |
  const factory DateField.era(FieldWidth width) = _DateFieldEra;

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
  const factory DateField.year({required int minDigits}) = _DateFieldYear;

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
  const factory DateField.weekBasedYear({required int minDigits}) =
      _DateFieldWeekBasedYear;

  /// Extended year, e.g., “4601”.
  ///
  /// This is a single number designating the year of this calendar system,
  /// encompassing all supra-year fields. For example, for the Julian calendar
  /// system, year numbers are positive, with an era of BCE or CE. An extended
  /// year value for the Julian calendar system assigns positive values to CE
  /// years and negative values to BCE years, with 1 BCE being year 0.
  ///
  /// Unicode Shorthand: `u`, `uu`, `uuu`, etc.
  const factory DateField.extendedYear({required int minDigits}) =
      _DateFieldExtendedYear;

  /// Cyclic year name.
  ///
  /// Calendars such as the Chinese lunar calendar (and related calendars) and
  /// the Hindu calendars use 60-year cycles of year names.
  ///
  /// If the calendar does not provide cyclic year name data, or if the year
  /// value to be formatted is out of the range of years for which cyclic name
  /// data is provided, then numeric formatting is used (behaves like "y").
  ///
  /// | Width         | Example       | Unicode Shorthand |
  /// | :------------ | :------------ | :---------------- |
  /// | `wide`        | 甲子           | `UUUU`            |
  /// | `abbreviated` | 甲子 (for now) | `U`, `UU`, `UUU`  |
  /// | `narrow`      | 甲子 (for now) | `UUUUU`           |
  const factory DateField.cyclicYearName(FieldWidth width) =
      _DateFieldCyclicYearName;

  /// Related Gregorian year (numeric).
  ///
  /// For non-Gregorian calendars, this corresponds to the extended Gregorian
  /// year in which the calendar’s year begins. Related Gregorian years are
  /// often displayed, for example, when formatting dates in the Japanese
  /// calendar – e.g., “2012(平成24)年1月15日” – or in the Chinese calendar – e.g.,
  /// “2012壬辰年腊月初四”. The related Gregorian year is usually displayed using
  /// the “latn” numbering system, regardless of what numbering systems may be
  /// used for other parts of the formatted date. If the calendar’s year is
  /// linked to the solar year (perhaps using leap months), then for that
  /// calendar the ‘r’ year will always be at a fixed offset from the ‘u’ year.
  /// For the Gregorian calendar, the ‘r’ year is the same as the ‘u’ year.
  ///
  /// Unicode Shorthand: `r`, `rr`, `rrr`, etc.
  const factory DateField.relatedGregorianYear({required int minDigits}) =
      _DateFieldRelatedGregorianYear;

  const factory DateField.quarter(QuarterStyle style) = _DateFieldQuarter;

  const factory DateField.month(MonthStyle style) = _DateFieldMonth;

  /// Week of Year, e.g., “27”.
  ///
  /// Unicode Shorthand: `w` (not padded), `ww` (padded)
  const factory DateField.weekOfYear({required bool isPadded}) =
      _DateFieldWeekOfYear;

  /// Week of Month, e.g., “3”.
  ///
  /// Unicode Shorthand: `W`
  const factory DateField.weekOfMonth() = _DateFieldWeekOfMonth;

  /// Date - Day of the month, e.g., “1”.
  ///
  /// Unicode Shorthand: `d` (not padded), `dd` (padded)
  const factory DateField.dayOfMonth({required bool isPadded}) =
      _DateFieldDayOfMonth;

  /// Day of year, e.g., “345”.
  ///
  /// Unicode Shorthand: `D` (one digit), `DD` (padded to two digits),
  /// `DDD` (padded to three digits)
  const factory DateField.dayOfYear({required DayOfYearPadding padding}) =
      _DateFieldDayOfYear;

  /// Day of Week in Month, e.g., “2”.
  ///
  /// The example is for the 2nd Wed in July
  ///
  /// Unicode Shorthand: `F`
  const factory DateField.dayOfWeekInMonth() = _DateFieldDayOfWeekInMonth;

  /// Modified Julian day.
  ///
  /// This is different from the conventional Julian day number in two regards.
  /// First, it demarcates days at local zone midnight, rather than noon GMT.
  /// Second, it is a local number; that is, it depends on the local time zone.
  /// It can be thought of as a single number that encompasses all the
  /// date-related fields.
  ///
  /// Unicode Shorthand: `g`
  const factory DateField.modifiedJulianDay() = _DateFieldModifiedJulianDay;

  const factory DateField.weekday(WeekdayStyle style) = _DateFieldWeekday;

  const DateField._();

  static DateField? parse(String character, int length) {
    return switch ((character, length)) {
          ('G', >= 1 && <= 3) => const DateField.era(FieldWidth.abbreviated),
          ('G', 4) => const DateField.era(FieldWidth.wide),
          ('G', 5) => const DateField.era(FieldWidth.narrow),
          ('y', _) => DateField.year(minDigits: length),
          ('Y', _) => DateField.weekBasedYear(minDigits: length),
          ('u', _) => DateField.extendedYear(minDigits: length),
          ('U', >= 1 && <= 3) =>
            const DateField.cyclicYearName(FieldWidth.abbreviated),
          ('U', 4) => const DateField.cyclicYearName(FieldWidth.wide),
          ('U', 5) => const DateField.cyclicYearName(FieldWidth.narrow),
          ('r', _) => DateField.relatedGregorianYear(minDigits: length),
          ('w', 1) => const DateField.weekOfYear(isPadded: false),
          ('w', 2) => const DateField.weekOfYear(isPadded: true),
          ('W', 1) => const DateField.weekOfMonth(),
          ('d', 1) => const DateField.dayOfMonth(isPadded: false),
          ('d', 2) => const DateField.dayOfMonth(isPadded: true),
          ('D', 1) => const DateField.dayOfYear(padding: DayOfYearPadding.one),
          ('D', 2) => const DateField.dayOfYear(padding: DayOfYearPadding.two),
          ('D', 3) =>
            const DateField.dayOfYear(padding: DayOfYearPadding.three),
          ('F', 1) => const DateField.dayOfWeekInMonth(),
          ('g', _) => const DateField.modifiedJulianDay(),
          _ => null,
        } ??
        QuarterStyle.parse(character, length)?.let(DateField.quarter) ??
        MonthStyle.parse(character, length)?.let(DateField.month) ??
        WeekdayStyle.parse(character, length)?.let(DateField.weekday);
  }

  @override
  Expression toExpression() {
    final create = referCldr('DateField').newInstanceNamed;
    return when(
      era: (width) => create('era', [width.toExpression()]),
      year: (minDigits) =>
          create('year', [], {'minDigits': literalNum(minDigits)}),
      weekBasedYear: (minDigits) =>
          create('weekBasedYear', [], {'minDigits': literalNum(minDigits)}),
      extendedYear: (minDigits) =>
          create('extendedYear', [], {'minDigits': literalNum(minDigits)}),
      cyclicYearName: (width) =>
          create('cyclicYearName', [width.toExpression()]),
      relatedGregorianYear: (minDigits) => create(
        'relatedGregorianYear',
        [],
        {'minDigits': literalNum(minDigits)},
      ),
      quarter: (style) => create('quarter', [style.toExpression()]),
      month: (style) => create('month', [style.toExpression()]),
      weekOfYear: (isPadded) =>
          create('weekOfYear', [], {'isPadded': literalBool(isPadded)}),
      weekOfMonth: () => create('weekOfMonth', []),
      dayOfMonth: (isPadded) =>
          create('dayOfMonth', [], {'isPadded': literalBool(isPadded)}),
      dayOfYear: (padding) =>
          create('dayOfYear', [], {'padding': padding.toExpression()}),
      dayOfWeekInMonth: () => create('dayOfWeekInMonth', []),
      modifiedJulianDay: () => create('modifiedJulianDay', []),
      weekday: (style) => create('weekday', [style.toExpression()]),
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

@freezed
sealed class QuarterStyle with _$QuarterStyle implements ToExpression {
  /// The form used within a date format string (such as “2nd quarter 2024”).
  ///
  /// | Width         | Example     | Unicode Shorthand |
  /// | :------------ | :---------- | :---------------- |
  /// | `wide`        | 2nd quarter | `QQQQ`            |
  /// | `abbreviated` | Q2          | `QQQ`             |
  /// | `narrow`      | 2           | `QQQQQ`           |
  const factory QuarterStyle.format(FieldWidth width) = _QuarterStyleFormat;

  /// Numeric version of [QuarterStyle.format], e.g., “2” (not padded) or “02”
  /// (padded).
  ///
  /// Unicode Shorthand: `Q` (one digit), `QQ` (padded to two digits)
  const factory QuarterStyle.formatNumeric({required bool isPadded}) =
      _QuarterStyleFormatNumeric;

  /// The form used independently, e.g., in a calendar header.
  ///
  /// | Width         | Example     | Unicode Shorthand |
  /// | :------------ | :---------- | :---------------- |
  /// | `wide`        | 2nd quarter | `qqqq`            |
  /// | `abbreviated` | Q2          | `qqq`             |
  /// | `narrow`      | 2           | `qqqqL`           |
  const factory QuarterStyle.standalone(FieldWidth width) =
      _QuarterStyleStandalone;

  /// Numeric version of [QuarterStyle.standalone], e.g., “2” (not padded) or
  /// “02” (padded).
  ///
  /// Unicode Shorthand: `q` (one digit), `qq` (padded to two digits)
  const factory QuarterStyle.standaloneNumeric({required bool isPadded}) =
      _QuarterStyleStandaloneNumeric;

  const QuarterStyle._();

  static QuarterStyle? parse(String character, int length) {
    return switch ((character, length)) {
      ('Q', 1) => const QuarterStyle.formatNumeric(isPadded: false),
      ('Q', 2) => const QuarterStyle.formatNumeric(isPadded: true),
      ('Q', 3) => const QuarterStyle.format(FieldWidth.abbreviated),
      ('Q', 4) => const QuarterStyle.format(FieldWidth.wide),
      ('Q', 5) => const QuarterStyle.format(FieldWidth.narrow),
      ('q', 1) => const QuarterStyle.standaloneNumeric(isPadded: false),
      ('q', 2) => const QuarterStyle.standaloneNumeric(isPadded: true),
      ('q', 3) => const QuarterStyle.standalone(FieldWidth.abbreviated),
      ('q', 4) => const QuarterStyle.standalone(FieldWidth.wide),
      ('q', 5) => const QuarterStyle.standalone(FieldWidth.narrow),
      _ => null,
    };
  }

  @override
  Expression toExpression() {
    final create = referCldr('QuarterStyle').newInstanceNamed;
    return when(
      format: (width) => create('format', [width.toExpression()]),
      formatNumeric: (isPadded) =>
          create('formatNumeric', [], {'isPadded': literalBool(isPadded)}),
      standalone: (width) => create('standalone', [width.toExpression()]),
      standaloneNumeric: (isPadded) =>
          create('standaloneNumeric', [], {'isPadded': literalBool(isPadded)}),
    );
  }
}

@freezed
sealed class MonthStyle with _$MonthStyle implements ToExpression {
  /// The form used within a date format string (such as “Saturday, November
  /// 12th”).
  ///
  /// The format style name is an additional form of the month name (besides the
  /// standalone style) that can be used in contexts where it is different than
  /// the standalone form. For example, depending on the language, patterns that
  /// combine month with day-of month (e.g., “d MMMM”) may require the month to
  /// be in genitive form.
  ///
  /// If a separate form is not needed, the format and standalone forms can be
  /// the same.
  ///
  /// | Width         | Example   | Unicode Shorthand |
  /// | :------------ | :-------- | :---------------- |
  /// | `wide`        | September | `MMMM`            |
  /// | `abbreviated` | Sep       | `MMM`             |
  /// | `narrow`      | S         | `MMMMM`           |
  const factory MonthStyle.format(FieldWidth width) = _MonthStyleFormat;

  /// Numeric version of [MonthStyle.format], e.g., “9” (not padded) or “09”
  /// (padded).
  ///
  /// Unicode Shorthand: `M` (one digit), `MM` (padded to two digits)
  const factory MonthStyle.formatNumeric({required bool isPadded}) =
      _MonthStyleFormatNumeric;

  /// The form used independently, e.g., in a calendar header.
  ///
  /// | Width         | Example   | Unicode Shorthand |
  /// | :------------ | :-------- | :---------------- |
  /// | `wide`        | September | `LLLL`            |
  /// | `abbreviated` | Sep       | `LLL`             |
  /// | `narrow`      | S         | `LLLLL`           |
  const factory MonthStyle.standalone(FieldWidth width) = _MonthStyleStandalone;

  /// Numeric version of [MonthStyle.standalone], e.g., “9” (not padded) or “09”
  /// (padded).
  ///
  /// Unicode Shorthand: `L` (one digit), `LL` (padded to two digits)
  const factory MonthStyle.standaloneNumeric({required bool isPadded}) =
      _MonthStyleStandaloneNumeric;

  const MonthStyle._();

  static MonthStyle? parse(String character, int length) {
    return switch ((character, length)) {
      ('M', 1) => const MonthStyle.formatNumeric(isPadded: false),
      ('M', 2) => const MonthStyle.formatNumeric(isPadded: true),
      ('M', 3) => const MonthStyle.format(FieldWidth.abbreviated),
      ('M', 4) => const MonthStyle.format(FieldWidth.wide),
      ('M', 5) => const MonthStyle.format(FieldWidth.narrow),
      ('L', 1) => const MonthStyle.standaloneNumeric(isPadded: false),
      ('L', 2) => const MonthStyle.standaloneNumeric(isPadded: true),
      ('L', 3) => const MonthStyle.standalone(FieldWidth.abbreviated),
      ('L', 4) => const MonthStyle.standalone(FieldWidth.wide),
      ('L', 5) => const MonthStyle.standalone(FieldWidth.narrow),
      _ => null,
    };
  }

  @override
  Expression toExpression() {
    final create = referCldr('MonthStyle').newInstanceNamed;
    return when(
      format: (width) => create('format', [width.toExpression()]),
      formatNumeric: (isPadded) =>
          create('formatNumeric', [], {'isPadded': literalBool(isPadded)}),
      standalone: (width) => create('standalone', [width.toExpression()]),
      standaloneNumeric: (isPadded) =>
          create('standaloneNumeric', [], {'isPadded': literalBool(isPadded)}),
    );
  }
}

@freezed
sealed class WeekdayStyle with _$WeekdayStyle implements ToExpression {
  /// The form used within a date format string (such as “Saturday, November
  /// 12th”).
  ///
  /// | Width         | Example | Unicode Shorthand       |
  /// | :------------ | :------ | :---------------------- |
  /// | `wide`        | Tuesday | `EEEE`, `eeee`          |
  /// | `abbreviated` | Tue     | `E`, `EE`, `EEE`, `eee` |
  /// | `short`       | Tu      | `EEEEEE`, `eeeeee`      |
  /// | `narrow`      | T       | `EEEEE`, `eeeee`        |
  const factory WeekdayStyle.format(DayFieldWidth width) = _WeekdayStyleFormat;

  /// Local weekday (numeric), e.g., “2”.
  ///
  /// Unicode Shorthand: `e` (one digit), `ee` (padded to two digits)
  const factory WeekdayStyle.formatNumeric({required bool isPadded}) =
      _WeekdayStyleFormatNumeric;

  /// The form used independently, e.g., in a calendar header.
  ///
  /// | Width         | Example | Unicode Shorthand |
  /// | :------------ | :------ | :---------------- |
  /// | `wide`        | Tuesday | `cccc`            |
  /// | `abbreviated` | Tue     | `ccc`             |
  /// | `short`       | Tu      | `cccccc`          |
  /// | `narrow`      | T       | `ccccc`           |
  const factory WeekdayStyle.standalone(DayFieldWidth width) =
      _WeekdayStyleStandalone;

  /// Standalone local day of week number, e.g., “2”.
  ///
  /// Unicode Shorthand: `c`, `cc`
  const factory WeekdayStyle.standaloneNumeric() =
      _WeekdayStyleStandaloneNumeric;

  const WeekdayStyle._();

  static WeekdayStyle? parse(String character, int length) {
    return switch ((character, length)) {
      ('E', >= 1 && <= 3) ||
      ('e', 3) =>
        const WeekdayStyle.format(DayFieldWidth.abbreviated),
      ('E' || 'e', 4) => const WeekdayStyle.format(DayFieldWidth.wide),
      ('E' || 'e', 5) => const WeekdayStyle.format(DayFieldWidth.narrow),
      ('E' || 'e', 6) => const WeekdayStyle.format(DayFieldWidth.short),
      ('e', 1) => const WeekdayStyle.formatNumeric(isPadded: false),
      ('e', 2) => const WeekdayStyle.formatNumeric(isPadded: true),
      ('c', >= 1 && <= 2) => const WeekdayStyle.standaloneNumeric(),
      ('c', 3) => const WeekdayStyle.standalone(DayFieldWidth.abbreviated),
      ('c', 4) => const WeekdayStyle.standalone(DayFieldWidth.wide),
      ('c', 5) => const WeekdayStyle.standalone(DayFieldWidth.narrow),
      ('c', 6) => const WeekdayStyle.standalone(DayFieldWidth.short),
      _ => null,
    };
  }

  @override
  Expression toExpression() {
    final create = referCldr('WeekdayStyle').newInstanceNamed;
    return when(
      format: (width) => create('format', [width.toExpression()]),
      formatNumeric: (isPadded) => create(
        'formatNumeric',
        [],
        {'isPadded': literalBool(isPadded)},
      ),
      standalone: (width) => create('standalone', [width.toExpression()]),
      standaloneNumeric: () => create('standaloneNumeric', []),
    );
  }
}

@freezed
sealed class TimeField with _$TimeField implements ToExpression {
  /// Period (AM or PM), e.g., “AM”.
  ///
  /// May be uppercase or lowercase depending on the locale and other options.
  /// The wide form may be the same as the short form if the “real” long form
  /// (e.g., ante meridiem) is not customarily used. The narrow form must be
  /// unique, unlike some other fields
  ///
  /// | Width         | Example            | Unicode Shorthand |
  /// | :------------ | :----------------- | :---------------- |
  /// | `wide`        | am. (e.g., 12 am.) | `aaaa`            |
  /// | `abbreviated` | am. (e.g., 12 am.) | `a`, `aa`, `aaa`  |
  /// | `narrow`      | a (e.g., 12a)      | `aaaaa`           |
  const factory TimeField.periodAmPm(FieldWidth width) = _TimeFieldPeriodAmPm;

  /// Period (AM or PM) with optional values for noon and midnight, e.g., “AM”.
  ///
  /// May be uppercase or lowercase depending on the locale and other options.
  /// If the locale doesn't have the notion of a unique “noon” = 12:00, then the
  /// PM form may be substituted. Similarly for “midnight” = 00:00 and the AM
  /// form. The narrow form must be unique, unlike some other fields.
  ///
  /// | Width         | Example                      | Unicode Shorthand |
  /// | :------------ | :--------------------------- | :---------------- |
  /// | `wide`        | midnight (e.g., 12 midnight) | `bbbb`            |
  /// | `abbreviated` | mid. (e.g., 12 mid.)         | `b`, `bb`, `bbb`  |
  /// | `narrow`      | md (e.g., 12 md)             | `bbbbb`           |
  const factory TimeField.periodAmPmNoonMidnight(FieldWidth width) =
      _TimeFieldPeriodAmPmNoonMidnight;

  /// Flexible day period, e.g., “at night”.
  ///
  /// May be uppercase or lowercase depending on the locale and other options.
  /// Often, there is only one width that is customarily used.
  ///
  /// | Width         | Example                        | Unicode Shorthand |
  /// | :------------ | :----------------------------- | :---------------- |
  /// | `wide`        | at night (e.g., 3:00 at night) | `BBBB`            |
  /// | `abbreviated` | at night (e.g., 3:00 at night) | `B`, `BB`, `BBB`  |
  /// | `narrow`      | at night (e.g., 3:00 at night) | `BBBBB`           |
  const factory TimeField.periodFlexible(FieldWidth width) =
      _TimeFieldPeriodFlexible;

  /// Hour (1 – 12), e.g., “11”.
  ///
  /// Unicode Shorthand: `h`, `hh`
  const factory TimeField.hour12({required bool isPadded}) = _TimeFieldHour12;

  /// Hour (0 – 23), e.g., “13”.
  ///
  /// Unicode Shorthand: `H`, `HH`
  const factory TimeField.hour24({required bool isPadded}) = _TimeFieldHour24;

  /// Hour (0 – 11), e.g., “0” or “00”.
  ///
  /// Unicode Shorthand: `K`, `KK`
  const factory TimeField.hour12ZeroBased({required bool isPadded}) =
      _TimeFieldHour12ZeroBased;

  /// Hour (1 – 24), e.g., “24”.
  ///
  /// Unicode Shorthand: `k`, `kk`
  const factory TimeField.hour24OneBased({required bool isPadded}) =
      _TimeFieldHour24OneBased;

  /// Minute, e.g., “59”.
  ///
  /// Unicode Shorthand: `m`, `mm`
  const factory TimeField.minute({required bool isPadded}) = _TimeFieldMinute;

  /// Second, e.g., “12”.
  ///
  /// Unicode Shorthand: `s`, `ss`
  const factory TimeField.second({required bool isPadded}) = _TimeFieldSecond;

  /// Fractional Second, e.g., “3456”.
  ///
  /// Unicode Shorthand: `S`, `SS`, etc.
  @Assert('digits >= 1')
  const factory TimeField.fractionalSecond(int digits) =
      _TimeFieldFractionalSecond;

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
  const factory TimeField.millisecondsInDay(int digits) =
      _TimeFieldMillisecondsInDay;

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
  const factory TimeField.zoneSpecificNonLocation({
    required ZoneFieldLength length,
  }) = _TimeFieldZoneSpecificNonLocation;

  /// The localized GMT format, e.g., “GMT-8” (short) or “GMT-08:00” (long).
  ///
  /// Unicode Shorthand: `O` (short), `ZZZZ`, `OOOO` (long)
  // `TODO`(JonasWanke): check example since the spec conflicts itself
  const factory TimeField.zoneLocalizedGmt({
    required ZoneFieldLength length,
  }) = _TimeFieldZoneLocalizedGmt;

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
  const factory TimeField.zoneGenericNonLocation({
    required ZoneFieldLength length,
  }) = _TimeFieldZoneGenericNonLocation;

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
  const factory TimeField.zoneID({required ZoneFieldLength length}) =
      _TimeFieldZoneID;

  /// The exemplar city (location) for the time zone, e.g., “Los Angeles”.
  ///
  /// Where that is unavailable, the localized exemplar city name for the
  /// special zone Etc/Unknown is used as the fallback (for example, “Unknown
  /// City”).
  ///
  /// Unicode Shorthand: `VVV`
  const factory TimeField.zoneExemplarCity() = _TimeFieldZoneExemplarCity;

  /// The generic location format, e.g., “Los Angeles Time”.
  ///
  /// Where that is unavailable, falls back to the long localized GMT format
  /// (“OOOO”; Note: Fallback is only necessary with a GMT-style Time Zone ID,
  /// like Etc/GMT-830.) This is especially useful when presenting possible
  /// timezone choices for user selection, since the naming is more uniform than
  /// the `v` format.
  ///
  /// Unicode Shorthand: `VVVV`
  const factory TimeField.zoneGenericLocationFormat() =
      _TimeFieldZoneGenericLocationFormat;

  /// An ISO 8601 basic format, see [ZoneFieldIso8601Style] for details.
  ///
  /// With [useZForZeroOffset] set to `true`, the ISO 8601 UTC indicator “Z” is
  /// used when local time offset is 0.
  ///
  /// Unicode Shorthand: See [ZoneFieldIso8601Style]
  const factory TimeField.zoneIso8601({
    required ZoneFieldIso8601Style style,
    required bool useZForZeroOffset,
  }) = _TimeFieldZoneIso8601Basic;

  const TimeField._();

  static TimeField? parse(String character, int length) {
    return switch ((character, length)) {
      ('a', >= 1 && <= 3) => const TimeField.periodAmPm(FieldWidth.abbreviated),
      ('a', 4) => const TimeField.periodAmPm(FieldWidth.wide),
      ('a', 5) => const TimeField.periodAmPm(FieldWidth.narrow),
      ('b', >= 1 && <= 3) =>
        const TimeField.periodAmPmNoonMidnight(FieldWidth.abbreviated),
      ('b', 4) => const TimeField.periodAmPmNoonMidnight(FieldWidth.wide),
      ('b', 5) => const TimeField.periodAmPmNoonMidnight(FieldWidth.narrow),
      ('B', >= 1 && <= 3) =>
        const TimeField.periodFlexible(FieldWidth.abbreviated),
      ('B', 4) => const TimeField.periodFlexible(FieldWidth.wide),
      ('B', 5) => const TimeField.periodFlexible(FieldWidth.narrow),
      ('h', 1) => const TimeField.hour12(isPadded: false),
      ('h', 2) => const TimeField.hour12(isPadded: true),
      ('H', 1) => const TimeField.hour24(isPadded: false),
      ('H', 2) => const TimeField.hour24(isPadded: true),
      ('K', 1) => const TimeField.hour12ZeroBased(isPadded: false),
      ('K', 2) => const TimeField.hour12ZeroBased(isPadded: true),
      ('k', 1) => const TimeField.hour24OneBased(isPadded: false),
      ('k', 2) => const TimeField.hour24OneBased(isPadded: true),
      ('m', 1) => const TimeField.minute(isPadded: false),
      ('m', 2) => const TimeField.minute(isPadded: true),
      ('s', 1) => const TimeField.second(isPadded: false),
      ('s', 2) => const TimeField.second(isPadded: true),
      ('S', _) => TimeField.fractionalSecond(length),
      ('A', _) => TimeField.millisecondsInDay(length),
      ('z', >= 1 && <= 3) => const TimeField.zoneSpecificNonLocation(
          length: ZoneFieldLength.short,
        ),
      ('z', 4) => const TimeField.zoneSpecificNonLocation(
          length: ZoneFieldLength.long,
        ),
      ('Z' || 'O', 4) => const TimeField.zoneLocalizedGmt(
          length: ZoneFieldLength.long,
        ),
      ('O', 1) => const TimeField.zoneLocalizedGmt(
          length: ZoneFieldLength.short,
        ),
      ('v', 1) => const TimeField.zoneGenericNonLocation(
          length: ZoneFieldLength.short,
        ),
      ('v', 4) => const TimeField.zoneGenericNonLocation(
          length: ZoneFieldLength.long,
        ),
      ('V', 1) => const TimeField.zoneID(length: ZoneFieldLength.short),
      ('V', 2) => const TimeField.zoneID(length: ZoneFieldLength.long),
      ('V', 3) => const TimeField.zoneExemplarCity(),
      ('V', 4) => const TimeField.zoneGenericLocationFormat(),
      ('X', 1) => const TimeField.zoneIso8601(
          style: ZoneFieldIso8601Style.basicWithHoursOptionalMinutes,
          useZForZeroOffset: true,
        ),
      ('X', 2) => const TimeField.zoneIso8601(
          style: ZoneFieldIso8601Style.basicWithHoursMinutes,
          useZForZeroOffset: true,
        ),
      ('X', 3) => const TimeField.zoneIso8601(
          style: ZoneFieldIso8601Style.extendedWithHoursMinutes,
          useZForZeroOffset: true,
        ),
      ('X', 4) => const TimeField.zoneIso8601(
          style: ZoneFieldIso8601Style.basicWithHoursMinutesOptionalSeconds,
          useZForZeroOffset: true,
        ),
      ('X' || 'Z', 5) => const TimeField.zoneIso8601(
          style: ZoneFieldIso8601Style.extendedWithHoursMinutesOptionalSeconds,
          useZForZeroOffset: true,
        ),
      ('x', 1) => const TimeField.zoneIso8601(
          style: ZoneFieldIso8601Style.basicWithHoursOptionalMinutes,
          useZForZeroOffset: false,
        ),
      ('x', 2) => const TimeField.zoneIso8601(
          style: ZoneFieldIso8601Style.basicWithHoursMinutes,
          useZForZeroOffset: false,
        ),
      ('x', 3) => const TimeField.zoneIso8601(
          style: ZoneFieldIso8601Style.extendedWithHoursMinutes,
          useZForZeroOffset: false,
        ),
      ('x', 4) || ('Z', >= 1 && <= 3) => const TimeField.zoneIso8601(
          style: ZoneFieldIso8601Style.basicWithHoursMinutesOptionalSeconds,
          useZForZeroOffset: false,
        ),
      ('x', 5) => const TimeField.zoneIso8601(
          style: ZoneFieldIso8601Style.extendedWithHoursMinutesOptionalSeconds,
          useZForZeroOffset: false,
        ),
      _ => null,
    };
  }

  @override
  Expression toExpression() {
    final create = referCldr('TimeField').newInstanceNamed;

    return when(
      periodAmPm: (width) => create('periodAmPm', [width.toExpression()]),
      periodAmPmNoonMidnight: (width) =>
          create('periodAmPmNoonMidnight', [width.toExpression()]),
      periodFlexible: (width) =>
          create('periodFlexible', [width.toExpression()]),
      hour12: (isPadded) =>
          create('hour12', [], {'isPadded': literalBool(isPadded)}),
      hour24: (isPadded) =>
          create('hour24', [], {'isPadded': literalBool(isPadded)}),
      hour12ZeroBased: (isPadded) =>
          create('hour12ZeroBased', [], {'isPadded': literalBool(isPadded)}),
      hour24OneBased: (isPadded) =>
          create('hour24OneBased', [], {'isPadded': literalBool(isPadded)}),
      minute: (isPadded) =>
          create('minute', [], {'isPadded': literalBool(isPadded)}),
      second: (isPadded) =>
          create('second', [], {'isPadded': literalBool(isPadded)}),
      fractionalSecond: (digits) =>
          create('fractionalSecond', [], {'digits': literalNum(digits)}),
      millisecondsInDay: (digits) =>
          create('millisecondsInDay', [], {'digits': literalNum(digits)}),
      zoneSpecificNonLocation: (length) => create(
        'zoneSpecificNonLocation',
        [],
        {'length': length.toExpression()},
      ),
      zoneLocalizedGmt: (length) =>
          create('zoneLocalizedGmt', [], {'length': length.toExpression()}),
      zoneGenericNonLocation: (length) => create(
        'zoneGenericNonLocation',
        [],
        {'length': length.toExpression()},
      ),
      zoneID: (length) =>
          create('zoneID', [], {'length': length.toExpression()}),
      zoneExemplarCity: () => create('zoneExemplarCity', []),
      zoneGenericLocationFormat: () => create('zoneGenericLocationFormat', []),
      zoneIso8601: (style, useZForZeroOffset) => create('zoneIso8601', [], {
        'style': style.toExpression(),
        'useZForZeroOffset': literalBool(useZForZeroOffset),
      }),
    );
  }
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

  T operator [](FieldWidth width) {
    return switch (width) {
      FieldWidth.wide => wide,
      FieldWidth.abbreviated => abbreviated,
      FieldWidth.narrow => narrow,
    };
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

enum FieldWidth implements ToExpression {
  wide,
  abbreviated,
  narrow;

  @override
  Expression toExpression() => referCldr('FieldWidth').property(name);
}
