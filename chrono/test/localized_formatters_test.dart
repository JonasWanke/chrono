import 'dart:convert';

import 'package:chrono/chrono.dart';
import 'package:chrono/cldr.dart';
import 'package:cldr/cldr.dart';
import 'package:glados/glados.dart';
import 'package:supernova/supernova.dart' hide Instant;
import 'package:supernova/supernova_io.dart';

final _testFile = File(
  '/home/user/GitHub/unicode-org/conformance/TEMP_DATA/testData/icu75/datetime_fmt_test.json',
);
final _verifyFile = File(
  '/home/user/GitHub/unicode-org/conformance/TEMP_DATA/testData/icu75/datetime_fmt_verify.json',
);
Future<void> main() async {
  final testFileContent =
      jsonDecode(await _testFile.readAsString()) as Map<String, dynamic>;
  final verifyFileContent =
      jsonDecode(await _verifyFile.readAsString()) as Map<String, dynamic>;

  print('CLDR version: ${testFileContent['cldrVersion']}');
  print('ICU version: ${testFileContent['icuVersion']}');

  final verifications = (verifyFileContent['verifications'] as List<dynamic>)
      .cast<Map<String, dynamic>>()
      .associate(
        (it) => MapEntry(it['label'] as String, it['verify'] as String),
      );
  final testCases =
      (testFileContent['tests'] as List<dynamic>).cast<Map<String, dynamic>>();

  for (final testCase in testCases) {
    final label = testCase['label'] as String;
    final inputString = testCase['input_string'] as String;
    final locale = testCase['locale'] as String;
    final options = testCase['options'] as Map<String, dynamic>;
    final verification = verifications[label]!;

    final dateLength = (options['dateStyle'] as String?)
        ?.let(DateOrTimeFormatLength.values.byName);
    final timeLength = (options['timeStyle'] as String?)
        ?.let(DateOrTimeFormatLength.values.byName);
    final calendar = options['calendar'] as String;
    final numberingSystem = options['numberingSystem'] as String;
    final hour = options['hour'] as String?;
    final minute = options['minute'] as String?;
    final second = options['second'] as String?;
    final fractionalSecondDigits = options['fractionalSecondDigits'] as int?;

    final localeData = switch (locale) {
      'ar' => ar,
      'bn' => bn,
      'de' => de,
      'en-GB' => en_GB,
      'en-US' => en_US,
      'mt-MT' => mt_MT,
      'vi' => vi,
      // 'zh-TW' => zh_TW,
      'zu' => zu,
      _ => null,
    };

    final String? skipReason;
    if (calendar != 'gregory') {
      skipReason = 'Unsupported calendar: $calendar';
    } else if (numberingSystem != 'latn') {
      skipReason = 'Unsupported numbering system: $numberingSystem';
    } else if (dateLength == null || timeLength == null) {
      skipReason = 'Only dateStyle and timeStyle are supported';
    } else if (timeLength == DateOrTimeFormatLength.long ||
        timeLength == DateOrTimeFormatLength.full) {
      skipReason = 'Time zones are not yet supported';
    } else if (localeData == null) {
      skipReason = 'Unsupported locale: $locale';
    } else if (options.containsKey('timeZoneName')) {
      skipReason = 'Unsupported option: timeZoneName';
    } else {
      skipReason = null;
    }

    test(
      '$label: $inputString in `$locale`',
      () {
        final dateTime = const InstantAsIsoStringJsonConverter()
            .fromJson(inputString)
            .dateTimeInUtc;
        final formatter = LocalizedDateTimeFormatter(
          localeData!,
          DateTimeStyle.lengths(
            dateLength: dateLength!,
            timeLength: timeLength!,
            useAtTimeVariant: true,
          ),
        );
        final actual = formatter.format(dateTime);
        expect(actual, verification);
      },
      skip: skipReason,
    );
  }
}
