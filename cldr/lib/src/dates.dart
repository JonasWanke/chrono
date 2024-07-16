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
    return referCldr('Dates').newInstance(
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
  Expression toExpression() => referCldr('Calendars')
      .newInstance([], {'gregorian': gregorian.toExpression()});
}

@freezed
class Calendar with _$Calendar implements ToExpression {
  const factory Calendar({
    required Context<Widths<Map<int, String>>> months,
    required Context<DayWidths> days,
    // TODO(JonasWanke): `<quarters>`
    required Context<Widths<DayPeriods>> dayPeriods,
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
      dayPeriods: Context.fromXml(
        path.child('dayPeriods').child('dayPeriodContext'),
        (path) => Widths.fromXml(
          path.child('dayPeriodWidth'),
          (path) => DayPeriods.fromXml(xml, path),
        ),
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
    return referCldr('Calendar').newInstance(
      [],
      {
        'months': months.toExpression(),
        'days': days.toExpression(),
        'dayPeriods': dayPeriods.toExpression(),
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
    return referCldr('DayWidths').constInstance(
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
    return referCldr('Days').constInstance(
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
class DayPeriods with _$DayPeriods implements ToExpression {
  const factory DayPeriods({
    required String am,
    required String pm,
    required String? midnight,
    required String? morning1,
    required String? morning2,
    required String? noon,
    required String? afternoon1,
    required String? afternoon2,
    required String? evening1,
    required String? evening2,
    required String? night1,
    required String? night2,
  }) = _DayPeriods;
  const DayPeriods._();

  factory DayPeriods.fromXml(CldrXml xml, CldrPath path) {
    CldrPath getPath(String type) =>
        path.child('dayPeriod', attributes: {'type': type});
    return DayPeriods(
      am: xml.resolveString(getPath('am')),
      pm: xml.resolveString(getPath('pm')),
      midnight: xml.resolveOptionalString(getPath('midnight')),
      morning1: xml.resolveOptionalString(getPath('morning1')),
      morning2: xml.resolveOptionalString(getPath('morning2')),
      noon: xml.resolveOptionalString(getPath('noon')),
      afternoon1: xml.resolveOptionalString(getPath('afternoon1')),
      afternoon2: xml.resolveOptionalString(getPath('afternoon2')),
      evening1: xml.resolveOptionalString(getPath('evening1')),
      evening2: xml.resolveOptionalString(getPath('evening2')),
      night1: xml.resolveOptionalString(getPath('night1')),
      night2: xml.resolveOptionalString(getPath('night2')),
    );
  }

  @override
  Expression toExpression() {
    return referCldr('DayPeriods').constInstance(
      [],
      {
        'am': literalString(am),
        'pm': literalString(pm),
        'midnight': midnight == null ? literalNull : literalString(midnight!),
        'morning1': morning1 == null ? literalNull : literalString(morning1!),
        'morning2': morning2 == null ? literalNull : literalString(morning2!),
        'noon': noon == null ? literalNull : literalString(noon!),
        'afternoon1':
            afternoon1 == null ? literalNull : literalString(afternoon1!),
        'afternoon2':
            afternoon2 == null ? literalNull : literalString(afternoon2!),
        'evening1': evening1 == null ? literalNull : literalString(evening1!),
        'evening2': evening2 == null ? literalNull : literalString(evening2!),
        'night1': night1 == null ? literalNull : literalString(night1!),
        'night2': night2 == null ? literalNull : literalString(night2!),
      },
    );
  }
}

@freezed
class Eras with _$Eras implements ToExpression {
  const factory Eras({
    required Map<int, Widths<ValueWithVariant<String>>> eras,
  }) = _Eras;
  const Eras._();

  factory Eras.fromXml(CldrXml xml, CldrPath path) {
    // In the root document, `<eraNames>` and `<eraNarrow>` are aliases to
    // `<eraAbbr>`, so we use that as the source of truth.
    final eraTypes = xml
        .listChildElements(path.child('eraAbbr'))
        .map((it) => int.parse(it.getAttribute('type')!))
        .toSet();

    final eras = eraTypes.associateWith((type) {
      final lastSegment =
          CldrPathSegment('era', attributes: {'type': type.toString()});
      return Widths(
        wide: ValueWithVariant.fromXml(
          xml,
          path.child('eraNames').childSegment(lastSegment),
        ),
        abbreviated: ValueWithVariant.fromXml(
          xml,
          path.child('eraAbbr').childSegment(lastSegment),
        ),
        narrow: ValueWithVariant.fromXml(
          xml,
          path.child('eraNarrow').childSegment(lastSegment),
        ),
      );
    });
    return Eras(eras: eras);
  }

  @override
  Expression toExpression() {
    return referCldr('Eras').constInstance(
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

  T operator [](DateOrTimeFormatLength width) {
    return switch (width) {
      DateOrTimeFormatLength.full => full,
      DateOrTimeFormatLength.long => long,
      DateOrTimeFormatLength.medium => medium,
      DateOrTimeFormatLength.short => short,
    };
  }

  @override
  Expression toExpression() {
    return referCldr('DateOrTimeFormats').constInstance(
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

enum DateOrTimeFormatLength { full, long, medium, short }

@freezed
class DateOrTimeFormat<F extends ToExpression>
    with _$DateOrTimeFormat<F>
    implements ToExpression {
  const factory DateOrTimeFormat({
    required List<DateOrTimePatternPart<F>> pattern,
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
    return referCldr('DateOrTimeFormat').constInstance(
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
    required DateOrTimeFormats<DateTimeVariants> formats,
    required Map<DateTimeSkeleton,
            Plural<List<DateOrTimePatternPart<DateTimeField>>>>
        availableFormats,
    // `TODO`(JonasWanke): `<appendItems>`, `<intervalFormats>`
  }) = _DateTimeFormats;
  const DateTimeFormats._();

  factory DateTimeFormats.fromXml(CldrXml xml, CldrPath path) {
    return DateTimeFormats(
      formats: DateOrTimeFormats.fromXml(
        path,
        'dateTimeFormat',
        (path) => DateTimeVariants.fromXml(xml, path),
      ),
      availableFormats: xml
          .listChildElements(path.child('availableFormats'))
          .where((it) => it.localName == 'dateFormatItem')
          .map((it) => it.getAttribute('id')!)
          .toSet()
          .associate(
            (id) => MapEntry(
              DateTimeSkeleton.parse(id),
              Plural.fromXml(
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
          ),
    );
  }

  // TODO(JonasWanke): skeleton matching
  // https://www.unicode.org/reports/tr35/tr35-dates.html#Matching_Skeletons
  // https://docs.rs/icu_datetime/1.5.1/src/icu_datetime/skeleton/helpers.rs.html#369

  @override
  Expression toExpression() {
    return referCldr('DateTimeFormats').newInstance(
      [],
      {
        'formats': formats.toExpression(),
        'availableFormats': literalMap(
          availableFormats.map(
            (key, value) => MapEntry(key.toExpression(), value.toExpression()),
          ),
        ),
      },
    );
  }
}

@freezed
class DateTimeVariants with _$DateTimeVariants implements ToExpression {
  const factory DateTimeVariants(
    DateTimeFormat standard, {
    required DateTimeFormat? atTime,
  }) = _DateTimeVariants;
  const DateTimeVariants._();

  factory DateTimeVariants.fromXml(CldrXml xml, CldrPath path) {
    final atTimePath = path.withAttribute('type', 'atTime');
    return DateTimeVariants(
      DateTimeFormat.fromXml(xml, path),
      atTime: xml.resolveOptionalElement(atTimePath) == null
          ? null
          : DateTimeFormat.fromXml(xml, atTimePath),
    );
  }

  @override
  Expression toExpression() {
    return referCldr('DateTimeVariants').constInstance(
      [standard.toExpression()],
      {'atTime': atTime == null ? literalNull : atTime!.toExpression()},
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
    return referCldr('DateTimeFormat').constInstance(
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
  const factory DateTimePatternPart.date() = _DateTimePatternPartDate;
  const factory DateTimePatternPart.time() = _DateTimePatternPartTime;
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
        referCldr('DateTimePatternPart').constInstanceNamed(name, args);

    return when(
      literal: (value) => create('literal', [literalString(value)]),
      date: () => create('date', []),
      time: () => create('time', []),
      field: (field) => create('field', [field.toExpression()]),
    );
  }

  @override
  String toString() {
    return when(
      literal: (value) => "'${value.replaceAll("'", "''")}'",
      date: () => 'date',
      time: () => 'time',
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
          offset++;
          while (true) {
            final nextQuoteIndex = pattern.indexOf("'", offset);
            if (nextQuoteIndex < 0) {
              throw ArgumentError('Unclosed quote in pattern: `$pattern`');
            }

            addLiteral(pattern.substring(offset, nextQuoteIndex));
            offset = nextQuoteIndex + 1;
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
        referCldr('DateOrTimePatternPart').constInstanceNamed(name, args);

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
sealed class DateTimeSkeleton with _$DateTimeSkeleton implements ToExpression {
  const factory DateTimeSkeleton({
    EraStyle? era,
    YearStyle? year,
    QuarterStyle? quarter,
    MonthStyle? month,
    WeekStyle? week,
    DayStyle? day,
    WeekdayStyle? weekday,
    PeriodStyle? period,
    HourStyle? hour,
    MinuteStyle? minute,
    SecondStyle? second,
    ZoneStyle? zone,
  }) = _DateTimeSkeleton;
  const DateTimeSkeleton._();

  factory DateTimeSkeleton.parse(String skeleton) {
    final fields = DateOrTimePatternPart.parse(skeleton, DateTimeField.parse)
        .map((it) => (it as _DateOrTimePatternPartField<DateTimeField>).field)
        .toList();
    F? getField<DT extends DateTimeField, F extends Object>() {
      return fields
          .whereType<DT>()
          .map((it) => it.field)
          .whereType<F>()
          .firstOrNull;
    }

    F? getDateField<F extends DateField>() =>
        getField<_DateTimeFieldDateField, F>();
    F? getTimeField<F extends TimeField>() =>
        getField<_DateTimeFieldTimeField, F>();

    final era = getDateField<_DateFieldEra>()?.style;
    final year = getDateField<_DateFieldYear>()?.style;
    final quarter = getDateField<_DateFieldQuarter>()?.style;
    final month = getDateField<_DateFieldMonth>()?.style;
    final week = getDateField<_DateFieldWeek>()?.style;
    final day = getDateField<_DateFieldDay>()?.style;
    final weekday = getDateField<_DateFieldWeekday>()?.style;
    var period = getTimeField<_TimeFieldPeriod>()?.style;
    final hour = getTimeField<_TimeFieldHour>()?.style;
    final minute = getTimeField<_TimeFieldMinute>()?.style;
    final second = getTimeField<_TimeFieldSecond>()?.style;
    final zone = getTimeField<_TimeFieldZone>()?.style;

    if (hour != null && hour.uses12HourCycle) {
      period ??= const PeriodStyle.amPm(FieldWidth.abbreviated);
    }

    return DateTimeSkeleton(
      era: era,
      year: year,
      quarter: quarter,
      month: month,
      week: week,
      day: day,
      weekday: weekday,
      period: period,
      hour: hour,
      minute: minute,
      second: second,
      zone: zone,
    );
  }

  @override
  Expression toExpression() {
    return referCldr('DateTimeSkeleton').constInstance([], {
      'era': era == null ? literalNull : era!.toExpression(),
      'year': year == null ? literalNull : year!.toExpression(),
      'quarter': quarter == null ? literalNull : quarter!.toExpression(),
      'month': month == null ? literalNull : month!.toExpression(),
      'week': week == null ? literalNull : week!.toExpression(),
      'day': day == null ? literalNull : day!.toExpression(),
      'weekday': weekday == null ? literalNull : weekday!.toExpression(),
      'period': period == null ? literalNull : period!.toExpression(),
      'hour': hour == null ? literalNull : hour!.toExpression(),
      'minute': minute == null ? literalNull : minute!.toExpression(),
      'second': second == null ? literalNull : second!.toExpression(),
      'zone': zone == null ? literalNull : zone!.toExpression(),
    });
  }
}

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
    final create = referCldr('DateTimeField').constInstanceNamed;
    return when(
      dateField: (field) => create('dateField', [field.toExpression()]),
      timeField: (field) => create('timeField', [field.toExpression()]),
    );
  }
}

@freezed
sealed class DateField with _$DateField implements ToExpression {
  const factory DateField.era(EraStyle style) = _DateFieldEra;
  const factory DateField.year(YearStyle style) = _DateFieldYear;
  const factory DateField.quarter(QuarterStyle style) = _DateFieldQuarter;
  const factory DateField.month(MonthStyle style) = _DateFieldMonth;
  const factory DateField.week(WeekStyle style) = _DateFieldWeek;
  const factory DateField.day(DayStyle style) = _DateFieldDay;
  const factory DateField.weekday(WeekdayStyle style) = _DateFieldWeekday;

  const DateField._();

  static DateField? parse(String character, int length) {
    return EraStyle.parse(character, length)?.let(DateField.era) ??
        YearStyle.parse(character, length)?.let(DateField.year) ??
        QuarterStyle.parse(character, length)?.let(DateField.quarter) ??
        MonthStyle.parse(character, length)?.let(DateField.month) ??
        WeekStyle.parse(character, length)?.let(DateField.week) ??
        DayStyle.parse(character, length)?.let(DateField.day) ??
        WeekdayStyle.parse(character, length)?.let(DateField.weekday);
  }

  @override
  Expression toExpression() {
    final create = referCldr('DateField').constInstanceNamed;
    return when(
      era: (style) => create('era', [style.toExpression()]),
      year: (style) => create('year', [style.toExpression()]),
      quarter: (style) => create('quarter', [style.toExpression()]),
      month: (style) => create('month', [style.toExpression()]),
      week: (style) => create('week', [style.toExpression()]),
      day: (style) => create('day', [style.toExpression()]),
      weekday: (style) => create('weekday', [style.toExpression()]),
    );
  }
}

enum DayOfYearPadding implements ToExpression {
  one,
  two,
  three;

  int get asInt => index + 1;

  @override
  Expression toExpression() => referCldr('DayOfYearPadding').property(name);
}

@freezed
sealed class EraStyle with _$EraStyle implements ToExpression {
  /// Era name:
  ///
  /// | Width         | Example                           | Unicode Shorthand |
  /// | :------------ | :-------------------------------- | :---------------- |
  /// | `wide`        | Anno Domini (variant: Common Era) | `GGGG`            |
  /// | `abbreviated` | AD (variant: CE)                  | `G`, `GG`, `GGG`  |
  /// | `narrow`      | A                                 | `GGGGG`           |
  const factory EraStyle(
    FieldWidth width, {
    @Default(false) bool useVariant,
  }) = _EraStyle;

  const EraStyle._();

  static EraStyle? parse(String character, int length) {
    return switch ((character, length)) {
      ('G', >= 1 && <= 3) => const EraStyle(FieldWidth.abbreviated),
      ('G', 4) => const EraStyle(FieldWidth.wide),
      ('G', 5) => const EraStyle(FieldWidth.narrow),
      _ => null,
    };
  }

  @override
  Expression toExpression() {
    return referCldr('EraStyle').newInstance(
      [width.toExpression()],
      {'useVariant': literalBool(useVariant)},
    );
  }
}

@freezed
sealed class YearStyle with _$YearStyle implements ToExpression {
  /// Calendar year number, e.g., “1996”.
  ///
  /// | Year     |     1 |     2 |     3 |     4 |     5 |
  /// | :------- | ----: | ----: |   --: | ----: | ----: |
  /// | AD 1     |     1 |    01 |   001 |  0001 | 00001 |
  /// | AD 12    |    12 |    12 |   012 |  0012 | 00012 |
  /// | AD 123   |   123 |   123 |   123 |  0123 | 00123 |
  /// | AD 1234  |  1234 |  1234 |  1234 |  1234 | 01234 |
  /// | AD 12345 | 12345 | 12345 | 12345 | 12345 | 12345 |
  ///
  /// Unicode Shorthand: `y`, `yyy`, `yyyy`, `yyyyy`, etc.
  @Assert('minDigits >= 1')
  const factory YearStyle.calendarYear({required int minDigits}) =
      _YearStyleCalendarYear;

  /// Two-digit year number, e.g., “96”.
  ///
  /// Unicode Shorthand: `yy`
  const factory YearStyle.calendarYearTwoDigits() =
      _YearStyleCalendarYearTwoDigits;

  /// Year number (in "Week of Year"-based calendars), e.g., “1996”.
  ///
  /// | Year     |     1 |     2 |     3 |     4 |     5 |
  /// | :------- | ----: | ----: |   --: | ----: | ----: |
  /// | AD 1     |     1 |    01 |   001 |  0001 | 00001 |
  /// | AD 12    |    12 |    12 |   012 |  0012 | 00012 |
  /// | AD 123   |   123 |   123 |   123 |  0123 | 00123 |
  /// | AD 1234  |  1234 |  1234 |  1234 |  1234 | 01234 |
  /// | AD 12345 | 12345 | 12345 | 12345 | 12345 | 12345 |
  ///
  /// Unicode Shorthand: `Y`, `YYY`, `YYYY`, `YYYYY`, etc.
  @Assert('minDigits >= 1')
  const factory YearStyle.weekBasedYear({required int minDigits}) =
      _YearStyleWeekBasedYear;

  /// Two-digit year number (in "Week of Year"-based calendars), e.g., “96”.
  ///
  /// Unicode Shorthand: `YY`
  const factory YearStyle.weekBasedYearTwoDigits() =
      _YearStyleWeekBasedYearTwoDigits;

  /// Extended year, e.g., “4601”.
  ///
  /// This is a single number designating the year of this calendar system,
  /// encompassing all supra-year fields. For example, for the Julian calendar
  /// system, year numbers are positive, with an era of BCE or CE. An extended
  /// year value for the Julian calendar system assigns positive values to CE
  /// years and negative values to BCE years, with 1 BCE being year 0.
  ///
  /// Unicode Shorthand: `u`, `uu`, `uuu`, etc.
  const factory YearStyle.extendedYear({required int minDigits}) =
      _YearStyleExtendedYear;

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
  const factory YearStyle.cyclicYearName(FieldWidth width) =
      _YearStyleCyclicYearName;

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
  const factory YearStyle.relatedGregorianYear({required int minDigits}) =
      _YearStyleRelatedGregorianYear;

  const YearStyle._();

  static YearStyle? parse(String character, int length) {
    return switch ((character, length)) {
      ('y', 2) => const YearStyle.calendarYearTwoDigits(),
      ('y', _) => YearStyle.calendarYear(minDigits: length),
      ('Y', 2) => const YearStyle.weekBasedYearTwoDigits(),
      ('Y', _) => YearStyle.weekBasedYear(minDigits: length),
      ('u', _) => YearStyle.extendedYear(minDigits: length),
      ('U', >= 1 && <= 3) =>
        const YearStyle.cyclicYearName(FieldWidth.abbreviated),
      ('U', 4) => const YearStyle.cyclicYearName(FieldWidth.wide),
      ('U', 5) => const YearStyle.cyclicYearName(FieldWidth.narrow),
      ('r', _) => YearStyle.relatedGregorianYear(minDigits: length),
      _ => null,
    };
  }

  @override
  Expression toExpression() {
    final create = referCldr('YearStyle').constInstanceNamed;
    return when(
      calendarYear: (minDigits) =>
          create('calendarYear', [], {'minDigits': literalNum(minDigits)}),
      calendarYearTwoDigits: () => create('calendarYearTwoDigits', []),
      weekBasedYear: (minDigits) =>
          create('weekBasedYear', [], {'minDigits': literalNum(minDigits)}),
      weekBasedYearTwoDigits: () => create('weekBasedYearTwoDigits', []),
      extendedYear: (minDigits) =>
          create('extendedYear', [], {'minDigits': literalNum(minDigits)}),
      cyclicYearName: (width) =>
          create('cyclicYearName', [width.toExpression()]),
      relatedGregorianYear: (minDigits) => create(
        'relatedGregorianYear',
        [],
        {'minDigits': literalNum(minDigits)},
      ),
    );
  }
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
    final create = referCldr('QuarterStyle').constInstanceNamed;
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
    final create = referCldr('MonthStyle').constInstanceNamed;
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
sealed class WeekStyle with _$WeekStyle implements ToExpression {
  /// Week of Year, e.g., “27”.
  ///
  /// Unicode Shorthand: `w` (not padded), `ww` (padded)
  const factory WeekStyle.weekOfYear({required bool isPadded}) =
      _WeekStyleWeekOfYear;

  /// Week of Month, e.g., “3”.
  ///
  /// Unicode Shorthand: `W`
  const factory WeekStyle.weekOfMonth() = _WeekStyleWeekOfMonth;

  const WeekStyle._();

  static WeekStyle? parse(String character, int length) {
    return switch ((character, length)) {
      ('w', 1) => const WeekStyle.weekOfYear(isPadded: false),
      ('w', 2) => const WeekStyle.weekOfYear(isPadded: true),
      ('W', 1) => const WeekStyle.weekOfMonth(),
      _ => null,
    };
  }

  @override
  Expression toExpression() {
    final create = referCldr('WeekStyle').constInstanceNamed;
    return when(
      weekOfYear: (isPadded) =>
          create('weekOfYear', [], {'isPadded': literalBool(isPadded)}),
      weekOfMonth: () => create('weekOfMonth', []),
    );
  }
}

@freezed
sealed class DayStyle with _$DayStyle implements ToExpression {
  /// Date - Day of the month, e.g., “1”.
  ///
  /// Unicode Shorthand: `d` (not padded), `dd` (padded)
  const factory DayStyle.dayOfMonth({required bool isPadded}) =
      _DayStyleDayOfMonth;

  /// Day of year, e.g., “345”.
  ///
  /// Unicode Shorthand: `D` (one digit), `DD` (padded to two digits),
  /// `DDD` (padded to three digits)
  const factory DayStyle.dayOfYear({required DayOfYearPadding padding}) =
      _DayStyleDayOfYear;

  /// Day of Week in Month, e.g., “2”.
  ///
  /// The example is for the 2nd Wed in July
  ///
  /// Unicode Shorthand: `F`
  const factory DayStyle.dayOfWeekInMonth() = _DayStyleDayOfWeekInMonth;

  /// Modified Julian day.
  ///
  /// This is different from the conventional Julian day number in two regards.
  /// First, it demarcates days at local zone midnight, rather than noon GMT.
  /// Second, it is a local number; that is, it depends on the local time zone.
  /// It can be thought of as a single number that encompasses all the
  /// date-related fields.
  ///
  /// Unicode Shorthand: `g`
  const factory DayStyle.modifiedJulianDay() = _DayStyleModifiedJulianDay;

  const DayStyle._();

  static DayStyle? parse(String character, int length) {
    return switch ((character, length)) {
      ('d', 1) => const DayStyle.dayOfMonth(isPadded: false),
      ('d', 2) => const DayStyle.dayOfMonth(isPadded: true),
      ('D', 1) => const DayStyle.dayOfYear(padding: DayOfYearPadding.one),
      ('D', 2) => const DayStyle.dayOfYear(padding: DayOfYearPadding.two),
      ('D', 3) => const DayStyle.dayOfYear(padding: DayOfYearPadding.three),
      ('F', 1) => const DayStyle.dayOfWeekInMonth(),
      ('g', _) => const DayStyle.modifiedJulianDay(),
      _ => null,
    };
  }

  @override
  Expression toExpression() {
    final create = referCldr('DayStyle').constInstanceNamed;
    return when(
      dayOfMonth: (isPadded) =>
          create('dayOfMonth', [], {'isPadded': literalBool(isPadded)}),
      dayOfYear: (padding) =>
          create('dayOfYear', [], {'padding': padding.toExpression()}),
      dayOfWeekInMonth: () => create('dayOfWeekInMonth', []),
      modifiedJulianDay: () => create('modifiedJulianDay', []),
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
    final create = referCldr('WeekdayStyle').constInstanceNamed;
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
  const factory TimeField.period(PeriodStyle style) = _TimeFieldPeriod;
  const factory TimeField.hour(HourStyle style) = _TimeFieldHour;
  const factory TimeField.minute(MinuteStyle style) = _TimeFieldMinute;
  const factory TimeField.second(SecondStyle style) = _TimeFieldSecond;
  const factory TimeField.zone(ZoneStyle style) = _TimeFieldZone;
  const TimeField._();

  static TimeField? parse(String character, int length) {
    return PeriodStyle.parse(character, length)?.let(TimeField.period) ??
        HourStyle.parse(character, length)?.let(TimeField.hour) ??
        MinuteStyle.parse(character, length)?.let(TimeField.minute) ??
        SecondStyle.parse(character, length)?.let(TimeField.second) ??
        ZoneStyle.parse(character, length)?.let(TimeField.zone);
  }

  @override
  Expression toExpression() {
    final create = referCldr('TimeField').constInstanceNamed;
    return when(
      period: (style) => create('period', [style.toExpression()]),
      hour: (style) => create('hour', [style.toExpression()]),
      minute: (style) => create('minute', [style.toExpression()]),
      second: (style) => create('second', [style.toExpression()]),
      zone: (style) => create('zone', [style.toExpression()]),
    );
  }
}

@freezed
sealed class PeriodStyle with _$PeriodStyle implements ToExpression {
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
  const factory PeriodStyle.amPm(FieldWidth width) = _PeriodStyleAmPm;

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
  const factory PeriodStyle.amPmNoonMidnight(FieldWidth width) =
      _PeriodStyleAmPmNoonMidnight;

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
  const factory PeriodStyle.flexible(FieldWidth width) = _PeriodStyleFlexible;

  const PeriodStyle._();

  static PeriodStyle? parse(String character, int length) {
    return switch ((character, length)) {
      ('a', >= 1 && <= 3) => const PeriodStyle.amPm(FieldWidth.abbreviated),
      ('a', 4) => const PeriodStyle.amPm(FieldWidth.wide),
      ('a', 5) => const PeriodStyle.amPm(FieldWidth.narrow),
      ('b', >= 1 && <= 3) =>
        const PeriodStyle.amPmNoonMidnight(FieldWidth.abbreviated),
      ('b', 4) => const PeriodStyle.amPmNoonMidnight(FieldWidth.wide),
      ('b', 5) => const PeriodStyle.amPmNoonMidnight(FieldWidth.narrow),
      ('B', >= 1 && <= 3) => const PeriodStyle.flexible(FieldWidth.abbreviated),
      ('B', 4) => const PeriodStyle.flexible(FieldWidth.wide),
      ('B', 5) => const PeriodStyle.flexible(FieldWidth.narrow),
      _ => null,
    };
  }

  @override
  Expression toExpression() {
    final create = referCldr('PeriodStyle').constInstanceNamed;

    return when(
      amPm: (width) => create('amPm', [width.toExpression()]),
      amPmNoonMidnight: (width) =>
          create('amPmNoonMidnight', [width.toExpression()]),
      flexible: (width) => create('flexible', [width.toExpression()]),
    );
  }
}

@freezed
sealed class HourStyle with _$HourStyle implements ToExpression {
  /// Hour (0 – 23), e.g., “13”.
  ///
  /// Unicode Shorthand: `H`, `HH`
  const factory HourStyle.from0To23({required bool isPadded}) =
      _HourStyleFrom0To23;

  /// Hour (1 – 24), e.g., “24”.
  ///
  /// Unicode Shorthand: `k`, `kk`
  const factory HourStyle.from1To24({required bool isPadded}) =
      _HourStyleFrom1To24;

  /// Hour (0 – 11), e.g., “0” or “00”.
  ///
  /// Unicode Shorthand: `K`, `KK`
  const factory HourStyle.from0To11({required bool isPadded}) =
      _HourStyleFrom0To11;

  /// Hour (1 – 12), e.g., “11”.
  ///
  /// Unicode Shorthand: `h`, `hh`
  const factory HourStyle.from1To12({required bool isPadded}) =
      _HourStyleFrom1To12;

  const HourStyle._();

  static HourStyle? parse(String character, int length) {
    return switch ((character, length)) {
      ('h', 1) => const HourStyle.from1To12(isPadded: false),
      ('h', 2) => const HourStyle.from1To12(isPadded: true),
      ('H', 1) => const HourStyle.from0To23(isPadded: false),
      ('H', 2) => const HourStyle.from0To23(isPadded: true),
      ('K', 1) => const HourStyle.from0To11(isPadded: false),
      ('K', 2) => const HourStyle.from0To11(isPadded: true),
      ('k', 1) => const HourStyle.from1To24(isPadded: false),
      ('k', 2) => const HourStyle.from1To24(isPadded: true),
      _ => null,
    };
  }

  bool get uses24HourCycle {
    return map(
      from0To23: (_) => true,
      from1To24: (_) => true,
      from0To11: (_) => false,
      from1To12: (_) => false,
    );
  }

  bool get uses12HourCycle => !uses24HourCycle;

  @override
  Expression toExpression() {
    final create = referCldr('HourStyle').constInstanceNamed;

    return when(
      from0To23: (style) =>
          create('from0To23', [], {'isPadded': literalBool(isPadded)}),
      from1To24: (style) =>
          create('from1To24', [], {'isPadded': literalBool(isPadded)}),
      from0To11: (style) =>
          create('from0To11', [], {'isPadded': literalBool(isPadded)}),
      from1To12: (style) =>
          create('from1To12', [], {'isPadded': literalBool(isPadded)}),
    );
  }
}

@freezed
sealed class MinuteStyle with _$MinuteStyle implements ToExpression {
  /// Minute, e.g., “59”.
  ///
  /// Unicode Shorthand: `m`, `mm`
  const factory MinuteStyle({required bool isPadded}) = _MinuteStyle;
  const MinuteStyle._();

  static MinuteStyle? parse(String character, int length) {
    return switch ((character, length)) {
      ('m', 1) => const MinuteStyle(isPadded: false),
      ('m', 2) => const MinuteStyle(isPadded: true),
      _ => null,
    };
  }

  @override
  Expression toExpression() {
    return referCldr('MinuteStyle')
        .newInstance([], {'isPadded': literalBool(isPadded)});
  }
}

@freezed
sealed class SecondStyle with _$SecondStyle implements ToExpression {
  /// Second in minute, e.g., “12”.
  ///
  /// Unicode Shorthand: `s`, `ss`
  const factory SecondStyle.second({required bool isPadded}) =
      _SecondStyleSecond;

  /// Fractional Second, e.g., “3456”.
  ///
  /// The example shows display using pattern `SSSS` for seconds value 12.34567.
  ///
  /// Unicode Shorthand: `S`, `SS`, etc.
  @Assert('digits >= 1')
  const factory SecondStyle.fractionalSecond({required int digits}) =
      _SecondStyleFractionalSecond;

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
  @Assert('minDigits >= 1')
  const factory SecondStyle.millisecondsInDay({required int minDigits}) =
      _SecondStyleMillisecondsInDay;

  const SecondStyle._();

  static SecondStyle? parse(String character, int length) {
    return switch ((character, length)) {
      ('s', 1) => const SecondStyle.second(isPadded: false),
      ('s', 2) => const SecondStyle.second(isPadded: true),
      ('S', _) => SecondStyle.fractionalSecond(digits: length),
      ('A', _) => SecondStyle.millisecondsInDay(minDigits: length),
      _ => null,
    };
  }

  @override
  Expression toExpression() {
    final create = referCldr('SecondStyle').constInstanceNamed;

    return when(
      second: (isPadded) =>
          create('second', [], {'isPadded': literalBool(isPadded)}),
      fractionalSecond: (digits) =>
          create('fractionalSecond', [], {'digits': literalNum(digits)}),
      millisecondsInDay: (digits) =>
          create('millisecondsInDay', [], {'minDigits': literalNum(digits)}),
    );
  }
}

@freezed
sealed class ZoneStyle with _$ZoneStyle implements ToExpression {
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
  const factory ZoneStyle.specificNonLocation({
    required ZoneLength length,
  }) = _ZoneStyleSpecificNonLocation;

  /// The localized GMT format, e.g., “GMT-8” (short) or “GMT-08:00” (long).
  ///
  /// Unicode Shorthand: `O` (short), `ZZZZ`, `OOOO` (long)
  // `TODO`(JonasWanke): check example since the spec conflicts itself
  const factory ZoneStyle.localizedGmt({
    required ZoneLength length,
  }) = _ZoneStyleLocalizedGmt;

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
  const factory ZoneStyle.genericNonLocation({
    required ZoneLength length,
  }) = _ZoneStyleGenericNonLocation;

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
  const factory ZoneStyle.id({required ZoneLength length}) = _ZoneStyleID;

  /// The exemplar city (location) for the time zone, e.g., “Los Angeles”.
  ///
  /// Where that is unavailable, the localized exemplar city name for the
  /// special zone Etc/Unknown is used as the fallback (for example, “Unknown
  /// City”).
  ///
  /// Unicode Shorthand: `VVV`
  const factory ZoneStyle.exemplarCity() = _ZoneStyleExemplarCity;

  /// The generic location format, e.g., “Los Angeles Time”.
  ///
  /// Where that is unavailable, falls back to the long localized GMT format
  /// (“OOOO”; Note: Fallback is only necessary with a GMT-style Time Zone ID,
  /// like Etc/GMT-830.) This is especially useful when presenting possible
  /// timezone choices for user selection, since the naming is more uniform than
  /// the `v` format.
  ///
  /// Unicode Shorthand: `VVVV`
  const factory ZoneStyle.genericLocationFormat() =
      _ZoneStyleGenericLocationFormat;

  /// An ISO 8601 basic format, see [ZoneIso8601Style] for details.
  ///
  /// With [useZForZeroOffset] set to `true`, the ISO 8601 UTC indicator “Z” is
  /// used when local time offset is 0.
  ///
  /// Unicode Shorthand: See [ZoneIso8601Style]
  const factory ZoneStyle.iso8601({
    required ZoneIso8601Style style,
    required bool useZForZeroOffset,
  }) = _ZoneStyleIso8601Basic;

  const ZoneStyle._();

  static ZoneStyle? parse(String character, int length) {
    return switch ((character, length)) {
      ('z', >= 1 && <= 3) =>
        const ZoneStyle.specificNonLocation(length: ZoneLength.short),
      ('z', 4) => const ZoneStyle.specificNonLocation(length: ZoneLength.long),
      ('Z' || 'O', 4) => const ZoneStyle.localizedGmt(length: ZoneLength.long),
      ('O', 1) => const ZoneStyle.localizedGmt(length: ZoneLength.short),
      ('v', 1) => const ZoneStyle.genericNonLocation(length: ZoneLength.short),
      ('v', 4) => const ZoneStyle.genericNonLocation(length: ZoneLength.long),
      ('V', 1) => const ZoneStyle.id(length: ZoneLength.short),
      ('V', 2) => const ZoneStyle.id(length: ZoneLength.long),
      ('V', 3) => const ZoneStyle.exemplarCity(),
      ('V', 4) => const ZoneStyle.genericLocationFormat(),
      ('X', 1) => const ZoneStyle.iso8601(
          style: ZoneIso8601Style.basicWithHoursOptionalMinutes,
          useZForZeroOffset: true,
        ),
      ('X', 2) => const ZoneStyle.iso8601(
          style: ZoneIso8601Style.basicWithHoursMinutes,
          useZForZeroOffset: true,
        ),
      ('X', 3) => const ZoneStyle.iso8601(
          style: ZoneIso8601Style.extendedWithHoursMinutes,
          useZForZeroOffset: true,
        ),
      ('X', 4) => const ZoneStyle.iso8601(
          style: ZoneIso8601Style.basicWithHoursMinutesOptionalSeconds,
          useZForZeroOffset: true,
        ),
      ('X' || 'Z', 5) => const ZoneStyle.iso8601(
          style: ZoneIso8601Style.extendedWithHoursMinutesOptionalSeconds,
          useZForZeroOffset: true,
        ),
      ('x', 1) => const ZoneStyle.iso8601(
          style: ZoneIso8601Style.basicWithHoursOptionalMinutes,
          useZForZeroOffset: false,
        ),
      ('x', 2) => const ZoneStyle.iso8601(
          style: ZoneIso8601Style.basicWithHoursMinutes,
          useZForZeroOffset: false,
        ),
      ('x', 3) => const ZoneStyle.iso8601(
          style: ZoneIso8601Style.extendedWithHoursMinutes,
          useZForZeroOffset: false,
        ),
      ('x', 4) || ('Z', >= 1 && <= 3) => const ZoneStyle.iso8601(
          style: ZoneIso8601Style.basicWithHoursMinutesOptionalSeconds,
          useZForZeroOffset: false,
        ),
      ('x', 5) => const ZoneStyle.iso8601(
          style: ZoneIso8601Style.extendedWithHoursMinutesOptionalSeconds,
          useZForZeroOffset: false,
        ),
      _ => null,
    };
  }

  @override
  Expression toExpression() {
    final create = referCldr('ZoneStyle').constInstanceNamed;

    return when(
      specificNonLocation: (length) => create(
        'specificNonLocation',
        [],
        {'length': length.toExpression()},
      ),
      localizedGmt: (length) =>
          create('localizedGmt', [], {'length': length.toExpression()}),
      genericNonLocation: (length) => create(
        'genericNonLocation',
        [],
        {'length': length.toExpression()},
      ),
      id: (length) => create('id', [], {'length': length.toExpression()}),
      exemplarCity: () => create('exemplarCity', []),
      genericLocationFormat: () => create('genericLocationFormat', []),
      iso8601: (style, useZForZeroOffset) => create('iso8601', [], {
        'style': style.toExpression(),
        'useZForZeroOffset': literalBool(useZForZeroOffset),
      }),
    );
  }
}

enum ZoneLength implements ToExpression {
  short,
  long;

  @override
  Expression toExpression() => referCldr('ZoneLength').property(name);
}

enum ZoneIso8601Style implements ToExpression {
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
  Expression toExpression() => referCldr('ZoneIso8601Style').property(name);
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
    return referCldr('Fields').constInstance(
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
    return referCldr('FieldWidths').constInstance(
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
    return referCldr('Field').constInstance(
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
    return referCldr('Context').constInstance(
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
    return referCldr('Widths').constInstance(
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
