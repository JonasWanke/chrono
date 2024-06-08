import 'package:collection/collection.dart';
import 'package:dartx/dartx_io.dart';
import 'package:xml/xml.dart';

import 'common.dart';

final class Dates {
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

final class Calendars {
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

final class Calendar {
  const Calendar({required this.eras});

  factory Calendar.fromXml(XmlElement element) {
    return Calendar(
      eras: Eras.fromXml(element.getElement('eras')!),
    );
  }

  final Eras eras;

  @override
  String toString() => 'Calendar(eras: $eras)';
}

final class Eras {
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

final class Era {
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
