import 'dart:io';

import 'package:meta/meta.dart';
import 'package:xml/xml.dart';

import 'src/dates.dart';

@immutable
class CommonLocaleData {
  const CommonLocaleData({required this.dates});

  factory CommonLocaleData.fromXml(XmlElement element) {
    return CommonLocaleData(
      dates: Dates.fromXml(element.getElement('dates')!),
    );
  }

  final Dates dates;

  @override
  String toString() => 'CommonLocaleData(dates: $dates)';
}

Future<void> main() async {
  final xmlString = await File('de.xml').readAsString();
  final xml = XmlDocument.parse(xmlString);
  final data = CommonLocaleData.fromXml(xml.rootElement);
  print(data);
}
