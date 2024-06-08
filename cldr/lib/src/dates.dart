import 'package:collection/collection.dart';
import 'package:dartx/dartx_io.dart';
import 'package:meta/meta.dart';
import 'package:xml/xml.dart';

import 'common.dart';

@immutable
class Dates {
  const Dates({required this.calendars});

  factory Dates.fromXml(XmlElement element) {
    return Dates(
      calendars: Calendars.fromXml(element.getElement('calendars')!),
    );
  }

  final Calendars calendars;

  @override
  String toString() => 'Dates(calendars: $calendars)';
}

@immutable
class Calendars {
  const Calendars({required this.gregorian});

  factory Calendars.fromXml(XmlElement element) {
    final calendars = element
        .findElements('calendar')
        .associateBy((it) => it.getAttribute('type')!);
    return Calendars(
      gregorian: Calendar.fromXml(calendars['gregorian']!),
    );
  }

  final Calendar gregorian;

  @override
  String toString() => 'Calendars(gregorian: $gregorian)';
}

@immutable
class Calendar {
  const Calendar({
    required this.months,
    required this.days,
    required this.eras,
  });

  factory Calendar.fromXml(XmlElement element) {
    return Calendar(
      months: Context.fromXml(
        element.getElement('months')!,
        'monthContext',
        (it) => Widths.fromXml(
          it,
          'monthWidth',
          (it) => it
              .findElements('month')
              .associateBy((it) => int.parse(it.getAttribute('type')!))
              .mapValues((it) => Value.fromXml(it.value)),
        ),
      ),
      days: Context.fromXml(
        element.getElement('days')!,
        'dayContext',
        DayWidths.fromXml,
      ),
      eras: Eras.fromXml(element.getElement('eras')!),
    );
  }

  final Context<Widths<Map<int, Value>>> months;
  final Context<DayWidths> days;
  final Eras eras;

  @override
  String toString() => 'Calendar(months: $months, days: $days, eras: $eras)';
}

class DayWidths extends Widths<Days> {
  const DayWidths({
    required super.wide,
    required super.abbreviated,
    required this.short,
    required super.narrow,
  });

  factory DayWidths.fromXml(XmlElement element) {
    final days = element
        .findElements('dayWidth')
        .associateBy((it) => it.getAttribute('type')!)
        .mapValues((it) => Days.fromXml(it.value));
    return DayWidths(
      wide: days['wide']!,
      abbreviated: days['abbreviated']!,
      short: days['short']!,
      narrow: days['narrow']!,
    );
  }

  /// Ideally between the abbreviated and narrow widths, but must be no longer
  /// than abbreviated and no shorter than narrow (if short day names are not
  /// explicitly specified, abbreviated day names are used instead).
  final Days short;

  @override
  String toString() {
    return 'DayWidths(wide: $wide, abbreviated: $abbreviated, short: $short, '
        'narrow: $narrow)';
  }
}

@immutable
class Days {
  const Days({
    required this.sunday,
    required this.monday,
    required this.tuesday,
    required this.wednesday,
    required this.thursday,
    required this.friday,
    required this.saturday,
  });

  factory Days.fromXml(XmlElement element) {
    final days = element
        .findElements('day')
        .associateBy((it) => it.getAttribute('type')!)
        .mapValues((it) => Value.fromXml(it.value));
    return Days(
      sunday: days['sun']!,
      monday: days['mon']!,
      tuesday: days['tue']!,
      wednesday: days['wed']!,
      thursday: days['thu']!,
      friday: days['fri']!,
      saturday: days['sat']!,
    );
  }

  final Value sunday;
  final Value monday;
  final Value tuesday;
  final Value wednesday;
  final Value thursday;
  final Value friday;
  final Value saturday;

  @override
  String toString() {
    return 'Days(sunday: $sunday, monday: $monday, tuesday: $tuesday, '
        'wednesday: $wednesday, thursday: $thursday, friday: $friday, '
        'saturday: $saturday)';
  }
}

@immutable
class Eras {
  const Eras({required this.eras});

  factory Eras.fromXml(XmlElement element) {
    final eraNames = element.getElement('eraNames')!.findElements('era');
    final eraAbbreviations = element.getElement('eraAbbr')!.findElements('era');
    final eraNarrow = element.getElement('eraNarrow')!.findElements('era');
    final eras = eraNames
        .groupListsBy((it) => it.getAttribute('type')!)
        .map((type, nameElements) {
      return MapEntry(
        int.parse(type),
        Era(
          name: ValueWithVariant.fromXml(nameElements),
          abbreviation: ValueWithVariant.fromXml(
            eraAbbreviations
                .where((it) => it.getAttribute('type') == type)
                .toList(),
          ),
          narrow: ValueWithVariant.fromXml(
            eraNarrow.where((it) => it.getAttribute('type') == type).toList(),
          ),
        ),
      );
    });
    return Eras(eras: eras);
  }

  final Map<int, Era> eras;

  @override
  String toString() => 'Eras(eras: $eras)';
}

@immutable
class Era {
  const Era({
    required this.name,
    required this.abbreviation,
    required this.narrow,
  });

  final ValueWithVariant name;
  final ValueWithVariant abbreviation;
  final ValueWithVariant narrow;

  @override
  String toString() =>
      'Era(name: $name, abbreviation: $abbreviation, narrow: $narrow)';
}

@immutable
class Context<T extends Object> {
  const Context({required this.format, required this.standAlone});

  factory Context.fromXml(
    XmlElement element,
    String elementName,
    T Function(XmlElement) valueFromXml,
  ) {
    final formats = element
        .findElements(elementName)
        .associateBy((it) => it.getAttribute('type')!)
        .mapValues((it) => valueFromXml(it.value));
    return Context(
      format: formats['format']!,
      standAlone: formats['stand-alone']!,
    );
  }

  /// The form used within a date format string (such as "Saturday, November
  /// 12th").
  final T format;

  /// The form used independently, such as in calendar headers.
  final T standAlone;

  @override
  String toString() => 'Context(format: $format, standAlone: $standAlone)';
}

@immutable
class Widths<T extends Object> {
  const Widths({
    required this.wide,
    required this.abbreviated,
    required this.narrow,
  });

  factory Widths.fromXml(
    XmlElement element,
    String elementName,
    T Function(XmlElement) valueFromXml,
  ) {
    final values = element
        .findElements(elementName)
        .associateBy((it) => it.getAttribute('type')!)
        .mapValues((it) => valueFromXml(it.value));
    return Widths(
      wide: values['wide']!,
      abbreviated: values['abbreviated']!,
      narrow: values['narrow']!,
    );
  }

  /// The default.
  final T wide;
  final T abbreviated;
  final T narrow;

  @override
  String toString() =>
      'Widths(wide: $wide, abbreviated: $abbreviated, narrow: $narrow)';
}
