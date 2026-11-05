import 'package:chrono_timezone_parser/chrono_timezone_parser.dart';
import 'package:test/test.dart';

void main() {
  group('%z', () {
    String format(int utcOffsetSeconds, [int dstOffsetSeconds = 0]) =>
        Format('%z').format(utcOffsetSeconds, dstOffsetSeconds, null);

    test('whole hours omit minutes', () {
      expect(format(-3600), '-01');
      expect(format(11 * 3600), '+11');
      expect(format(2 * 3600, 3600), '+03');
    });

    test('minutes are appended without a colon', () {
      expect(format(2 * 3600 + 45 * 60), '+0245');
      expect(format(-(3 * 3600 + 30 * 60)), '-0330');
    });
  });
}
