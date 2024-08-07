import 'dart:io';

import 'package:code_builder/code_builder.dart' as code_builder;
import 'package:code_builder/code_builder.dart' hide Field;
import 'package:dart_style/dart_style.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:xml/xml.dart';

import 'src/common.dart';
import 'src/dates.dart';

export 'src/common.dart' hide CldrXml, LetExtension, referCldr;
export 'src/dates.dart';

part 'cldr.freezed.dart';

@freezed
class CommonLocaleData with _$CommonLocaleData implements ToExpression {
  const factory CommonLocaleData({
    required Dates dates,
    // TODO(JonasWanke): `<localeDisplayNames>`, `<contextTransforms>`,
    // `<characters>`, `<delimiters>`, `<numbers>`, `<units>`, `<listPatterns>`,
    // `<posix>`, `<characterLabels>`, `<typographicNames>`, `<personNames>`
  }) = _CommonLocaleData;
  const CommonLocaleData._();

  factory CommonLocaleData.fromXml(List<XmlDocument> documents) {
    final xml = CldrXml(documents);
    const path = CldrPath([CldrPathSegment('ldml')]);
    return CommonLocaleData(
      dates: Dates.fromXml(xml, path.child('dates')),
    );
  }

  @override
  Expression toExpression() =>
      referCldr('CommonLocaleData')([], {'dates': dates.toExpression()});
  Library toLibrary(String localeName) {
    return Library(
      (b) => b
        ..ignoreForFile.addAll([
          'require_trailing_commas',
          'avoid_redundant_argument_values',
          'prefer-trailing-comma',
        ])
        ..body.add(
          code_builder.Field(
            (b) => b
              ..modifier = FieldModifier.final$
              ..name = localeName
              ..assignment = toExpression().code,
          ),
        ),
    );
  }
}

Future<void> main() async {
  final deXmlString = await File('de.xml').readAsString();
  final deXml = XmlDocument.parse(deXmlString);
  final rootXmlString = await File('root.xml').readAsString();
  final rootXml = XmlDocument.parse(rootXmlString);

  final startedAt = DateTime.now();
  final data = CommonLocaleData.fromXml([deXml, rootXml]);
  print('Parsing took ${DateTime.now().difference(startedAt)}');

  final code = data.toLibrary('de');
  final codeString =
      DartFormatter().format(code.accept(DartEmitter.scoped()).toString());
  await File('../chrono/lib/cldr_de.dart').writeAsString(codeString);
}
