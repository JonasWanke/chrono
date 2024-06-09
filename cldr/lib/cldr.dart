import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:xml/xml.dart';

import 'src/dates.dart';

part 'cldr.freezed.dart';

@freezed
class CommonLocaleData with _$CommonLocaleData {
  const factory CommonLocaleData({
    required Dates dates,
    // TODO(JonasWanke): `<localeDisplayNames>`, `<contextTransforms>`,
    // `<characters>`, `<delimiters>`, `<numbers>`, `<units>`, `<listPatterns>`,
    // `<posix>`, `<characterLabels>`, `<typographicNames>`, `<personNames>`
  }) = _CommonLocaleData;
  const CommonLocaleData._();

  factory CommonLocaleData.fromXml(XmlElement element) {
    return CommonLocaleData(
      dates: Dates.fromXml(element.getElement('dates')!),
    );
  }
}

Future<void> main() async {
  final xmlString = await File('de.xml').readAsString();
  final xml = XmlDocument.parse(xmlString);
  final data = CommonLocaleData.fromXml(xml.rootElement);
  print(data);
}
