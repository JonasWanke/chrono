// ignore_for_file: lines_longer_than_80_chars, missing-test-assertion

import 'package:chrono/chrono.dart';
import 'package:test/test.dart';

void main() {
  group('whitespace and literal', () {
    test('empty string', () {
      _parses('', []);
      _checkError(' ', [], .tooLong);
      _checkError('a', [], .tooLong);
      _checkError('abc', [], .tooLong);
      _checkError('🤠', [], .tooLong);
    });
    test('whitespaces', () {
      _parses('', [const .space('')]);
      _parses(' ', [const .space(' ')]);
      _parses('  ', [const .space('  ')]);
      _parses('   ', [const .space('   ')]);
      _parses(' ', [const .space('')]);
      _parses('  ', [const .space(' ')]);
      _parses('   ', [const .space('  ')]);
      _parses('    ', [const .space('  ')]);
      _parses('', [const .space(' ')]);
      _parses(' ', [const .space('  ')]);
      _parses('  ', [const .space('   ')]);
      _parses('  ', [const .space('  '), const .space('  ')]);
      _parses('   ', [const .space('  '), const .space('  ')]);
      _parses('  ', [const .space(' '), const .space(' ')]);
      _parses('   ', [const .space('  '), const .space(' ')]);
      _parses('   ', [const .space(' '), const .space('  ')]);
      _parses('   ', [const .space(' '), const .space(' '), const .space(' ')]);
      _parses('\t', [const .space('')]);
      _parses(' \n\r  \n', [const .space('')]);
      _parses('\t', [const .space('\t')]);
      _parses('\t', [const .space(' ')]);
      _parses(' ', [const .space('\t')]);
      _parses('\t\r', [const .space('\t\r')]);
      _parses('\t\r ', [const .space('\t\r ')]);
      _parses('\t \r', [const .space('\t \r')]);
      _parses(' \t\r', [const .space(' \t\r')]);
      _parses(' \n\r  \n', [const .space(' \n\r  \n')]);
      _parses(' \t\n', [const .space(' \t')]);
      _parses(' \n\t', [const .space(' \t\n')]);
      _parses('\u{2002}', [const .space('\u{2002}')]);
      // most unicode whitespace characters
      _parses(
        '\u{00A0}\u{1680}\u{2000}\u{2001}\u{2002}\u{2003}\u{2004}\u{2005}\u{2006}\u{2007}\u{2008}\u{2009}\u{3000}',
        [
          const .space(
            '\u{00A0}\u{1680}\u{2000}\u{2001}\u{2002}\u{2003}\u{2004}\u{2005}\u{2006}\u{2007}\u{2008}\u{2009}\u{3000}',
          ),
        ],
      );
      // most unicode whitespace characters
      _parses(
        '\u{00A0}\u{1680}\u{2000}\u{2001}\u{2002}\u{2003}\u{2004}\u{2005}\u{2006}\u{2007}\u{2008}\u{2009}\u{3000}',
        [
          const .space(
            '\u{00A0}\u{1680}\u{2000}\u{2001}\u{2002}\u{2003}\u{2004}',
          ),
          const .space('\u{2005}\u{2006}\u{2007}\u{2008}\u{2009}\u{3000}'),
        ],
      );
      _checkError('a', [const .space('')], .tooLong);
      _checkError('a', [const .space(' ')], .tooLong);
      // a Space containing a literal does not match a literal
      _checkError('a', [const .space('a')], .tooLong);
      _checkError('abc', [const .space('')], .tooLong);
      _checkError('abc', [const .space(' ')], .tooLong);
      _checkError(' abc', [const .space('')], .tooLong);
      _checkError(' abc', [const .space(' ')], .tooLong);
    });
  });
  test('parse_whitespace_and_literal', () {
    // `\u{0363}` is combining diacritic mark "COMBINING LATIN SMALL LETTER A"

    // literal
    _parses('', [const .literal('')]);
    _checkError('', [const .literal('a')], .tooShort);
    _checkError(' ', [const .literal('a')], .invalid);
    _parses('a', [const .literal('a')]);
    _parses('+', [const .literal('+')]);
    _parses('-', [const .literal('-')]);
    _parses('−', [const .literal('−')]); // MINUS SIGN (U+2212)
    _parses(' ', [
      const .literal(' '),
    ]); // a .literal may contain whitespace and match whitespace
    _checkError('aa', [const .literal('a')], .tooLong);
    _checkError('🤠', [const .literal('a')], .invalid);
    _checkError('A', [const .literal('a')], .invalid);
    _checkError('a', [const .literal('z')], .invalid);
    _checkError('a', [const .literal('🤠')], .tooShort);
    _checkError('a', [const .literal('\u{0363}a')], .tooShort);
    _checkError('\u{0363}a', [const .literal('a')], .invalid);
    _parses('\u{0363}a', [const .literal('\u{0363}a')]);
    _checkError('a', [const .literal('ab')], .tooShort);
    _parses('xy', [const .literal('xy')]);
    _parses('xy', [const .literal('x'), const .literal('y')]);
    _parses('1', [const .literal('1')]);
    _parses('1234', [const .literal('1234')]);
    _parses('+1234', [const .literal('+1234')]);
    _parses('-1234', [const .literal('-1234')]);
    _parses('−1234', [const .literal('−1234')]); // MINUS SIGN (U+2212)
    _parses('PST', [const .literal('PST')]);
    _parses('🤠', [const .literal('🤠')]);
    _parses('🤠a', [const .literal('🤠'), const .literal('a')]);
    _parses('🤠a🤠', [const .literal('🤠'), const .literal('a🤠')]);
    _parses('a🤠b', [
      const .literal('a'),
      const .literal('🤠'),
      const .literal('b'),
    ]);
    // literals can be together
    _parses('xy', [const .literal('xy')]);
    _parses('xyz', [const .literal('xyz')]);
    // or literals can be apart
    _parses('xy', [const .literal('x'), const .literal('y')]);
    _parses('xyz', [const .literal('x'), const .literal('yz')]);
    _parses('xyz', [const .literal('xy'), const .literal('z')]);
    _parses('xyz', [
      const .literal('x'),
      const .literal('y'),
      const .literal('z'),
    ]);
    //
    _checkError('x y', [const .literal('x'), const .literal('y')], .invalid);
    _parses('xy', [const .literal('x'), const .space(''), const .literal('y')]);
    _parses('x y', [
      const .literal('x'),
      const .space(''),
      const .literal('y'),
    ]);
    _parses('x y', [
      const .literal('x'),
      const .space(' '),
      const .literal('y'),
    ]);

    // whitespaces + literals
    _parses('a\n', [const .literal('a'), const .space('\n')]);
    _parses('\tab\n', [
      const .space('\t'),
      const .literal('ab'),
      const .space('\n'),
    ]);
    _parses('ab\tcd\ne', [
      const .literal('ab'),
      const .space('\t'),
      const .literal('cd'),
      const .space('\n'),
      const .literal('e'),
    ]);
    _parses('+1ab\tcd\r\n+,.', [
      const .literal('+1ab'),
      const .space('\t'),
      const .literal('cd'),
      const .space('\r\n'),
      const .literal('+,.'),
    ]);
    // whitespace and literals can be intermixed
    _parses('a\tb', [const .literal('a\tb')]);
    _parses('a\tb', [
      const .literal('a'),
      const .space('\t'),
      const .literal('b'),
    ]);
  });

  test('parse_numeric', () {
    // numeric
    _check('1987', [const .year()], ChronoParsed()..year = const Year(1987));
    _checkError('1987 ', [const .year()], .tooLong);
    _checkError('0x12', [const .year()], .tooLong); // `0` is parsed
    _checkError('x123', [const .year()], .invalid);
    _checkError('o123', [const .year()], .invalid);
    _check('2015', [const .year()], ChronoParsed()..year = const Year(2015));
    _check('0000', [const .year()], ChronoParsed()..year = const Year(0));
    _check('9999', [const .year()], ChronoParsed()..year = const Year(9999));
    _check(' \t987', [const .year()], ChronoParsed()..year = const Year(987));
    _check(' \t987', [
      const .space(' \t'),
      const .year(),
    ], ChronoParsed()..year = const Year(987));
    _check(' \t987🤠', [
      const .space(' \t'),
      const .year(),
      const .literal('🤠'),
    ], ChronoParsed()..year = const Year(987));
    _check('987🤠', [
      const .year(),
      const .literal('🤠'),
    ], ChronoParsed()..year = const Year(987));
    _check('5', [const .year()], ChronoParsed()..year = const Year(5));
    _checkError('5\x00', [const .year()], .tooLong);
    _checkError('\x005', [const .year()], .invalid);
    _checkError('', [const .year()], .tooShort);
    _check('12345', [
      const .year(),
      const .literal('5'),
    ], ChronoParsed()..year = const Year(1234));
    _check('12345', [
      const .year(padding: .space),
      const .literal('5'),
    ], ChronoParsed()..year = const Year(1234));
    _check('12345', [
      const .year(padding: .none),
      const .literal('5'),
    ], ChronoParsed()..year = const Year(1234));
    _check('12341234', [
      const .year(),
      const .year(),
    ], ChronoParsed()..year = const Year(1234));
    _check('1234 1234', [
      const .year(),
      const .year(),
    ], ChronoParsed()..year = const Year(1234));
    _check('1234 1234', [
      const .year(),
      const .space(' '),
      const .year(),
    ], ChronoParsed()..year = const Year(1234));
    _checkError('1234 1235', [const .year(), const .year()], .impossible);
    _checkError('1234 1234', [
      const .year(),
      const .literal('x'),
      const .year(),
    ], .invalid);
    _check('1234x1234', [
      const .year(),
      const .literal('x'),
      const .year(),
    ], ChronoParsed()..year = const Year(1234));
    _checkError('1234 x 1234', [
      const .year(),
      const .literal('x'),
      const .year(),
    ], .invalid);
    _checkError('1234xx1234', [
      const .year(),
      const .literal('x'),
      const .year(),
    ], .invalid);
    _check('1234xx1234', [
      const .year(),
      const .literal('xx'),
      const .year(),
    ], ChronoParsed()..year = const Year(1234));
    _check('1234 x 1234', [
      const .year(),
      const .space(' '),
      const .literal('x'),
      const .space(' '),
      const .year(),
    ], ChronoParsed()..year = const Year(1234));
    _check('1234 x 1235', [
      const .year(),
      const .space(' '),
      const .literal('x'),
      const .space(' '),
      const .literal('1235'),
    ], ChronoParsed()..year = const Year(1234));

    // signed numeric
    _check('-42', [const .year()], ChronoParsed()..year = const Year(-42));
    _check('+42', [const .year()], ChronoParsed()..year = const Year(42));
    _check('-0042', [const .year()], ChronoParsed()..year = const Year(-42));
    _check('+0042', [const .year()], ChronoParsed()..year = const Year(42));
    _check('-42195', [
      const .year(),
    ], ChronoParsed()..year = const Year(-42195));
    _checkError('−42195', [const .year()], .invalid); // MINUS SIGN (U+2212)
    _check('+42195', [const .year()], ChronoParsed()..year = const Year(42195));
    _check('  -42195', [
      const .year(),
    ], ChronoParsed()..year = const Year(-42195));
    _check(' +42195', [
      const .year(),
    ], ChronoParsed()..year = const Year(42195));
    _check('  -42195', [
      const .year(),
    ], ChronoParsed()..year = const Year(-42195));
    _check('  +42195', [
      const .year(),
    ], ChronoParsed()..year = const Year(42195));
    _checkError('-42195 ', [const .year()], .tooLong);
    _checkError('+42195 ', [const .year()], .tooLong);
    _checkError('  -   42', [const .year()], .invalid);
    _checkError('  +   42', [const .year()], .invalid);
    _check('  -42195', [
      const .space('  '),
      const .year(),
    ], ChronoParsed()..year = const Year(-42195));
    _checkError('  −42195', [
      const .space('  '),
      const .year(),
    ], .invalid); // MINUS SIGN (U+2212)
    _check('  +42195', [
      const .space('  '),
      const .year(),
    ], ChronoParsed()..year = const Year(42195));
    _checkError('  -   42', [const .space('  '), const .year()], .invalid);
    _checkError('  +   42', [const .space('  '), const .year()], .invalid);
    _checkError('-', [const .year()], .tooShort);
    _checkError('+', [const .year()], .tooShort);

    // unsigned numeric
    _check('345', [const .ordinal()], ChronoParsed()..ordinal = 345);
    _checkError('+345', [const .ordinal()], .invalid);
    _checkError('-345', [const .ordinal()], .invalid);
    _check(' 345', [const .ordinal()], ChronoParsed()..ordinal = 345);
    _checkError('−345', [const .ordinal()], .invalid); // MINUS SIGN (U+2212)
    _checkError('345 ', [const .ordinal()], .tooLong);
    _check(' 345', [
      const .space(' '),
      const .ordinal(),
    ], ChronoParsed()..ordinal = 345);
    _check('345 ', [
      const .ordinal(),
      const .space(' '),
    ], ChronoParsed()..ordinal = 345);
    _check('345🤠 ', [
      const .ordinal(),
      const .literal('🤠'),
      const .space(' '),
    ], ChronoParsed()..ordinal = 345);
    _checkError('345🤠', [const .ordinal()], .tooLong);
    _checkError('\u{0363}345', [const .ordinal()], .invalid);
    _checkError(' +345', [const .ordinal()], .invalid);
    _checkError(' -345', [const .ordinal()], .invalid);
    _check('\t345', [
      const .space('\t'),
      const .ordinal(),
    ], ChronoParsed()..ordinal = 345);
    _checkError(' +345', [const .space(' '), const .ordinal()], .invalid);
    _checkError(' -345', [const .space(' '), const .ordinal()], .invalid);

    // various numeric fields
    _check(
      '1234 5678',
      [const .year(), const .isoYear()],
      ChronoParsed()
        ..year = const Year(1234)
        ..isoYear = const Year(5678),
    );
    _check(
      '1234 5678',
      [const .year(), const .isoYear()],
      ChronoParsed()
        ..year = const Year(1234)
        ..isoYear = const Year(5678),
    );
    _check(
      '12 34 56 78',
      [
        const .year(format: .div100),
        const .year(format: .mod100),
        const .isoYear(format: .div100),
        const .isoYear(format: .mod100),
      ],
      ChronoParsed()
        ..yearDiv100 = 12
        ..yearMod100 = 34
        ..isoYearDiv100 = 56
        ..isoYearMod100 = 78,
    );
    _check(
      '1 1 2 3 4 5',
      [
        const .quarter(),
        const .month(),
        const .day(),
        const .weekFromSun(),
        const .numDaysFromSun(),
        const .isoWeek(),
      ],
      ChronoParsed()
        ..quarter = 1
        ..month = .january
        ..day = 2
        ..weekFromSun = 3
        ..weekday = .thursday
        ..isoWeek = 5,
    );
    _check(
      '6 7 89 01',
      [
        const .weekFromMon(),
        const .weekdayFromMon(),
        const .ordinal(),
        const .hour12(),
      ],
      ChronoParsed()
        ..weekFromMon = 6
        ..weekday = .sunday
        ..ordinal = 89
        ..hourMod12 = 1,
    );
    _check(
      '23 45 6 78901234 567890123',
      [
        const .hour(),
        const .minute(),
        const .second(),
        const .nanosecond(),
        const .timestamp(),
      ],
      ChronoParsed()
        ..hourDiv12 = .pm
        ..hourMod12 = 11
        ..minute = 45
        ..second = 6
        ..nanosecond = 78_901_234
        ..timestamp = TimeDelta(seconds: 567_890_123),
    );
  });

  test('parse_fixed', () {
    // fixed: month and weekday names
    _check('apr', [const .monthName(.short)], ChronoParsed()..month = .april);
    _check('Apr', [const .monthName(.short)], ChronoParsed()..month = .april);
    _check('APR', [const .monthName(.short)], ChronoParsed()..month = .april);
    _check('ApR', [const .monthName(.short)], ChronoParsed()..month = .april);
    _checkError('\u{0363}APR', [const .monthName(.short)], .invalid);
    _checkError('April', [
      const .monthName(.short),
    ], .tooLong); // `Apr` is parsed
    _checkError('A', [const .monthName(.short)], .tooShort);
    _checkError('Sol', [const .monthName(.short)], .invalid);
    _check('Apr', [const .monthName(.full)], ChronoParsed()..month = .april);
    _checkError('Apri', [const .monthName(.full)], .tooLong); // `Apr` is parsed
    _check('April', [const .monthName(.full)], ChronoParsed()..month = .april);
    _checkError('Aprill', [const .monthName(.full)], .tooLong);
    _check('Aprill', [
      const .monthName(.full),
      const .literal('l'),
    ], ChronoParsed()..month = .april);
    _check('Aprl', [
      const .monthName(.full),
      const .literal('l'),
    ], ChronoParsed()..month = .april);
    _checkError('April', [
      const .monthName(.full),
      const .literal('il'),
    ], .tooShort); // do not backtrack
    _check('thu', [
      const .weekdayName(.short),
    ], ChronoParsed()..weekday = .thursday);
    _check('Thu', [
      const .weekdayName(.short),
    ], ChronoParsed()..weekday = .thursday);
    _check('THU', [
      const .weekdayName(.short),
    ], ChronoParsed()..weekday = .thursday);
    _check('tHu', [
      const .weekdayName(.short),
    ], ChronoParsed()..weekday = .thursday);
    _checkError('Thursday', [
      const .weekdayName(.short),
    ], .tooLong); // `Thu` is parsed
    _checkError('T', [const .weekdayName(.short)], .tooShort);
    _checkError('The', [const .weekdayName(.short)], .invalid);
    _checkError('Nop', [const .weekdayName(.short)], .invalid);
    _check('Thu', [
      const .weekdayName(.full),
    ], ChronoParsed()..weekday = .thursday);
    _checkError('Thur', [
      const .weekdayName(.full),
    ], .tooLong); // `Thu` is parsed
    _checkError('Thurs', [
      const .weekdayName(.full),
    ], .tooLong); // `Thu` is parsed
    _check('Thursday', [
      const .weekdayName(.full),
    ], ChronoParsed()..weekday = .thursday);
    _checkError('Thursdays', [const .weekdayName(.full)], .tooLong);
    _check('Thursdays', [
      const .weekdayName(.full),
      const .literal('s'),
    ], ChronoParsed()..weekday = .thursday);
    _check('Thus', [
      const .weekdayName(.full),
      const .literal('s'),
    ], ChronoParsed()..weekday = .thursday);
    _checkError('Thursday', [
      const .weekdayName(.full),
      const .literal('rsday'),
    ], .tooShort); // do not backtrack

    // fixed: am/pm
    _check('am', [const .amPm(.lower)], ChronoParsed()..hourDiv12 = .am);
    _check('pm', [const .amPm(.lower)], ChronoParsed()..hourDiv12 = .pm);
    _check('AM', [const .amPm(.lower)], ChronoParsed()..hourDiv12 = .am);
    _check('PM', [const .amPm(.lower)], ChronoParsed()..hourDiv12 = .pm);
    _check('am', [const .amPm(.upper)], ChronoParsed()..hourDiv12 = .am);
    _check('pm', [const .amPm(.upper)], ChronoParsed()..hourDiv12 = .pm);
    _check('AM', [const .amPm(.upper)], ChronoParsed()..hourDiv12 = .am);
    _check('PM', [const .amPm(.upper)], ChronoParsed()..hourDiv12 = .pm);
    _check('Am', [const .amPm(.lower)], ChronoParsed()..hourDiv12 = .am);
    _check(' Am', [
      const .space(' '),
      const .amPm(.lower),
    ], ChronoParsed()..hourDiv12 = .am);
    _check('Am🤠', [
      const .amPm(.lower),
      const .literal('🤠'),
    ], ChronoParsed()..hourDiv12 = .am);
    _check('🤠Am', [
      const .literal('🤠'),
      const .amPm(.lower),
    ], ChronoParsed()..hourDiv12 = .am);
    _checkError('\u{0363}am', [const .amPm(.lower)], .invalid);
    _checkError('\u{0360}am', [const .amPm(.lower)], .invalid);
    _checkError(' Am', [const .amPm(.lower)], .invalid);
    _checkError('Am ', [const .amPm(.lower)], .tooLong);
    _checkError('a.m.', [const .amPm(.lower)], .invalid);
    _checkError('A.M.', [const .amPm(.lower)], .invalid);
    _checkError('ame', [const .amPm(.lower)], .tooLong); // `am` is parsed
    _checkError('a', [const .amPm(.lower)], .tooShort);
    _checkError('p', [const .amPm(.lower)], .tooShort);
    _checkError('x', [const .amPm(.lower)], .tooShort);
    _checkError('xx', [const .amPm(.lower)], .invalid);
    _checkError('', [const .amPm(.lower)], .tooShort);
  });

  test('parse_fixed_nanosecond', () {
    // fixed: dot plus nanoseconds
    _check('', [
      const .subsecond(.variable),
    ], ChronoParsed()); // no field set, but not an error
    _checkError('.', [const .subsecond(.variable)], .tooShort);
    _checkError('4', [
      const .subsecond(.variable),
    ], .tooLong); // never consumes `4`
    _check('4', [
      const .subsecond(.variable),
      const .second(),
    ], ChronoParsed()..second = 4);
    _check('.0', [const .subsecond(.variable)], ChronoParsed()..nanosecond = 0);
    _check('.4', [
      const .subsecond(.variable),
    ], ChronoParsed()..nanosecond = 400_000_000);
    _check('.42', [
      const .subsecond(.variable),
    ], ChronoParsed()..nanosecond = 420_000_000);
    _check('.421', [
      const .subsecond(.variable),
    ], ChronoParsed()..nanosecond = 421_000_000);
    _check('.42195', [
      const .subsecond(.variable),
    ], ChronoParsed()..nanosecond = 421_950_000);
    _check('.421951', [
      const .subsecond(.variable),
    ], ChronoParsed()..nanosecond = 421_951_000);
    _check('.4219512', [
      const .subsecond(.variable),
    ], ChronoParsed()..nanosecond = 421_951_200);
    _check('.42195123', [
      const .subsecond(.variable),
    ], ChronoParsed()..nanosecond = 421_951_230);
    _check('.421950803', [
      const .subsecond(.variable),
    ], ChronoParsed()..nanosecond = 421_950_803);
    _check('.4219508035', [
      const .subsecond(.variable),
    ], ChronoParsed()..nanosecond = 421_950_803);
    _check('.42195080354', [
      const .subsecond(.variable),
    ], ChronoParsed()..nanosecond = 421_950_803);
    _check('.421950803547', [
      const .subsecond(.variable),
    ], ChronoParsed()..nanosecond = 421_950_803);
    _check('.000000003', [
      const .subsecond(.variable),
    ], ChronoParsed()..nanosecond = 3);
    _check('.0000000031', [
      const .subsecond(.variable),
    ], ChronoParsed()..nanosecond = 3);
    _check('.0000000035', [
      const .subsecond(.variable),
    ], ChronoParsed()..nanosecond = 3);
    _check('.000000003547', [
      const .subsecond(.variable),
    ], ChronoParsed()..nanosecond = 3);
    _check('.0000000009', [
      const .subsecond(.variable),
    ], ChronoParsed()..nanosecond = 0);
    _check('.000000000547', [
      const .subsecond(.variable),
    ], ChronoParsed()..nanosecond = 0);
    _check('.0000000009999999999999999999999999', [
      const .subsecond(.variable),
    ], ChronoParsed()..nanosecond = 0);
    _check('.4🤠', [
      const .subsecond(.variable),
      const .literal('🤠'),
    ], ChronoParsed()..nanosecond = 400_000_000);
    _checkError('.4x', [const .subsecond(.variable)], .tooLong);
    _checkError('.  4', [const .subsecond(.variable)], .invalid);
    _checkError('  .4', [
      const .subsecond(.variable),
    ], .tooLong); // no automatic trimming

    // fixed-length fractions of a second
    _check('', [
      const .subsecond(.millis),
    ], ChronoParsed()); // no field set, but not an error
    _checkError('4', [
      const .subsecond(.millis),
    ], .tooLong); // never consumes `4`
    _checkError('.12', [const .subsecond(.millis)], .tooShort);
    _check('.123', [
      const .subsecond(.millis),
    ], ChronoParsed()..nanosecond = 123_000_000);
    _checkError('.1234', [const .subsecond(.millis)], .tooLong);
    _check('.1234', [
      const .subsecond(.millis),
      const .literal('4'),
    ], ChronoParsed()..nanosecond = 123_000_000);

    _check('', [
      const .subsecond(.micros),
    ], ChronoParsed()); // no field set, but not an error
    _checkError('4', [
      const .subsecond(.micros),
    ], .tooLong); // never consumes `4`
    _checkError('.12345', [const .subsecond(.micros)], .tooShort);
    _check('.123456', [
      const .subsecond(.micros),
    ], ChronoParsed()..nanosecond = 123_456_000);
    _checkError('.1234567', [const .subsecond(.micros)], .tooLong);
    _check('.1234567', [
      const .subsecond(.micros),
      const .literal('7'),
    ], ChronoParsed()..nanosecond = 123_456_000);

    _check('', [
      const .subsecond(.nanos),
    ], ChronoParsed()); // no field set, but not an error
    _checkError('4', [
      const .subsecond(.nanos),
    ], .tooLong); // never consumes `4`
    _checkError('.12345678', [const .subsecond(.nanos)], .tooShort);
    _check('.123456789', [
      const .subsecond(.nanos),
    ], ChronoParsed()..nanosecond = 123_456_789);
    _checkError('.1234567890', [const .subsecond(.nanos)], .tooLong);
    _check('.1234567890', [
      const .subsecond(.nanos),
      const .literal('0'),
    ], ChronoParsed()..nanosecond = 123_456_789);

    // fixed: nanoseconds without the dot
    // TODO(JonasWanke): port these test cases
    // checkError("", [internal_fixed(Nanosecond3NoDot)], .tooShort);
    // checkError(".", [internal_fixed(Nanosecond3NoDot)], .tooShort);
    // checkError("0", [internal_fixed(Nanosecond3NoDot)], .tooShort);
    // checkError("4", [internal_fixed(Nanosecond3NoDot)], .tooShort);
    // checkError("42", [internal_fixed(Nanosecond3NoDot)], .tooShort);
    // check("421", [internal_fixed(Nanosecond3NoDot)], parsed!(nanosecond: 421_000_000));
    // checkError("4210", [internal_fixed(Nanosecond3NoDot)], .tooLong);
    // check(
    //     "42143",
    //     [internal_fixed(Nanosecond3NoDot), num(Second)],
    //     parsed!(nanosecond: 421_000_000, second: 43),
    // );
    // check(
    //     "421🤠",
    //     [internal_fixed(Nanosecond3NoDot), .literal("🤠")],
    //     parsed!(nanosecond: 421_000_000),
    // );
    // check(
    //     "🤠421",
    //     [.literal("🤠"), internal_fixed(Nanosecond3NoDot)],
    //     parsed!(nanosecond: 421_000_000),
    // );
    // checkError("42195", [internal_fixed(Nanosecond3NoDot)], .tooLong);
    // checkError("123456789", [internal_fixed(Nanosecond3NoDot)], .tooLong);
    // checkError("4x", [internal_fixed(Nanosecond3NoDot)], .tooShort);
    // checkError("  4", [internal_fixed(Nanosecond3NoDot)], .invalid);
    // checkError(".421", [internal_fixed(Nanosecond3NoDot)], .invalid);

    // checkError("", [internal_fixed(Nanosecond6NoDot)], .tooShort);
    // checkError(".", [internal_fixed(Nanosecond6NoDot)], .tooShort);
    // checkError("0", [internal_fixed(Nanosecond6NoDot)], .tooShort);
    // checkError("1234", [internal_fixed(Nanosecond6NoDot)], .tooShort);
    // checkError("12345", [internal_fixed(Nanosecond6NoDot)], .tooShort);
    // check("421950", [internal_fixed(Nanosecond6NoDot)], parsed!(nanosecond: 421_950_000));
    // check("000003", [internal_fixed(Nanosecond6NoDot)], parsed!(nanosecond: 3000));
    // check("000000", [internal_fixed(Nanosecond6NoDot)], parsed!(nanosecond: 0));
    // checkError("1234567", [internal_fixed(Nanosecond6NoDot)], .tooLong);
    // checkError("123456789", [internal_fixed(Nanosecond6NoDot)], .tooLong);
    // checkError("4x", [internal_fixed(Nanosecond6NoDot)], .tooShort);
    // checkError("     4", [internal_fixed(Nanosecond6NoDot)], .invalid);
    // checkError(".42100", [internal_fixed(Nanosecond6NoDot)], .invalid);

    // checkError("", [internal_fixed(Nanosecond9NoDot)], .tooShort);
    // checkError(".", [internal_fixed(Nanosecond9NoDot)], .tooShort);
    // checkError("42195", [internal_fixed(Nanosecond9NoDot)], .tooShort);
    // checkError("12345678", [internal_fixed(Nanosecond9NoDot)], .tooShort);
    // check("421950803", [internal_fixed(Nanosecond9NoDot)], parsed!(nanosecond: 421_950_803));
    // check("000000003", [internal_fixed(Nanosecond9NoDot)], parsed!(nanosecond: 3));
    // check(
    //     "42195080354",
    //     [internal_fixed(Nanosecond9NoDot), num(Second)],
    //     parsed!(nanosecond: 421_950_803, second: 54),
    // ); // don't skip digits that come after the 9
    // checkError("1234567890", [internal_fixed(Nanosecond9NoDot)], .tooLong);
    // check("000000000", [internal_fixed(Nanosecond9NoDot)], parsed!(nanosecond: 0));
    // checkError("00000000x", [internal_fixed(Nanosecond9NoDot)], .invalid);
    // checkError("        4", [internal_fixed(Nanosecond9NoDot)], .invalid);
    // checkError(".42100000", [internal_fixed(Nanosecond9NoDot)], .invalid);
  });

  group('Timezones', () {
    test(
      '.timezoneOffset(precision: .minute, allowZulu: false, printColon: false)',
      () {
        const item = ChronoFormatItem.timezoneOffset(
          allowZulu: false,
          printColon: false,
        );
        _checkError('1', [item], .invalid);
        _checkError('12', [item], .invalid);
        _checkError('123', [item], .invalid);
        _checkError('1234', [item], .invalid);
        _checkError('12345', [item], .invalid);
        _checkError('123456', [item], .invalid);
        _checkError('1234567', [item], .invalid);
        _checkError('+1', [item], .tooShort);
        _checkError('+12', [item], .tooShort);
        _checkError('+123', [item], .tooShort);
        _check('+1234', [
          item,
        ], ChronoParsed()..offset = TimeDelta(seconds: 45_240));
        _checkError('+12345', [item], .tooLong);
        _checkError('+123456', [item], .tooLong);
        _checkError('+1234567', [item], .tooLong);
        _checkError('+12345678', [item], .tooLong);
        _checkError('+12:', [item], .tooShort);
        _checkError('+12:3', [item], .tooShort);
        _check('+12:34', [
          item,
        ], ChronoParsed()..offset = TimeDelta(seconds: 45_240));
        _check('-12:34', [
          item,
        ], ChronoParsed()..offset = TimeDelta(seconds: -45_240));
        _check(
          '−12:34',
          [item],
          ChronoParsed()..offset = TimeDelta(seconds: -45_240),
        ); // MINUS SIGN (U+2212)
        _checkError('+12:34:', [item], .tooLong);
        _checkError('+12:34:5', [item], .tooLong);
        _checkError('+12:34:56', [item], .tooLong);
        _checkError('+12:34:56:', [item], .tooLong);
        _check('+12 34', [
          item,
        ], ChronoParsed()..offset = TimeDelta(seconds: 45_240));
        _check('+12  34', [
          item,
        ], ChronoParsed()..offset = TimeDelta(seconds: 45_240));
        _checkError('12:34', [item], .invalid);
        _checkError('12:34:56', [item], .invalid);
        _check('+12::34', [
          item,
        ], ChronoParsed()..offset = TimeDelta(seconds: 45_240));
        _check('+12: :34', [
          item,
        ], ChronoParsed()..offset = TimeDelta(seconds: 45_240));
        _check('+12:::34', [
          item,
        ], ChronoParsed()..offset = TimeDelta(seconds: 45_240));
        _check('+12::::34', [
          item,
        ], ChronoParsed()..offset = TimeDelta(seconds: 45_240));
        _check('+12::34', [
          item,
        ], ChronoParsed()..offset = TimeDelta(seconds: 45_240));
        _checkError('+12:34:56', [item], .tooLong);
        _checkError('+12:3456', [item], .tooLong);
        _checkError('+1234:56', [item], .tooLong);
        _checkError('+1234:567', [item], .tooLong);
        _check('+00:00', [item], ChronoParsed()..offset = TimeDelta());
        _check('-00:00', [item], ChronoParsed()..offset = TimeDelta());
        _check('−00:00', [
          item,
        ], ChronoParsed()..offset = TimeDelta()); // MINUS SIGN (U+2212)
        _check('+00:01', [
          item,
        ], ChronoParsed()..offset = TimeDelta(seconds: 60));
        _check('-00:01', [
          item,
        ], ChronoParsed()..offset = TimeDelta(seconds: -60));
        _check('+00:30', [
          item,
        ], ChronoParsed()..offset = TimeDelta(seconds: 1_800));
        _check('-00:30', [
          item,
        ], ChronoParsed()..offset = TimeDelta(seconds: -1_800));
        _check('+24:00', [
          item,
        ], ChronoParsed()..offset = TimeDelta(seconds: 86_400));
        _check('-24:00', [
          item,
        ], ChronoParsed()..offset = TimeDelta(seconds: -86_400));
        _check(
          '−24:00',
          [item],
          ChronoParsed()..offset = TimeDelta(seconds: -86_400),
        ); // MINUS SIGN (U+2212)
        _check('+99:59', [
          item,
        ], ChronoParsed()..offset = TimeDelta(seconds: 359_940));
        _check('-99:59', [
          item,
        ], ChronoParsed()..offset = TimeDelta(seconds: -359_940));
        _checkError('+00:60', [item], .outOfRange);
        _checkError('+00:99', [item], .outOfRange);
        _checkError('#12:34', [item], .invalid);
        _checkError('+12:34 ', [item], .tooLong);
        _checkError('+12 34 ', [item], .tooLong);
        _check(' +12:34', [
          item,
        ], ChronoParsed()..offset = TimeDelta(seconds: 45_240));
        _check(' -12:34', [
          item,
        ], ChronoParsed()..offset = TimeDelta(seconds: -45_240));
        _check(
          ' −12:34',
          [item],
          ChronoParsed()..offset = TimeDelta(seconds: -45_240),
        ); // MINUS SIGN (U+2212)
        _check('  +12:34', [
          item,
        ], ChronoParsed()..offset = TimeDelta(seconds: 45_240));
        _check('  -12:34', [
          item,
        ], ChronoParsed()..offset = TimeDelta(seconds: -45_240));
        _check('\t -12:34', [
          item,
        ], ChronoParsed()..offset = TimeDelta(seconds: -45_240));
        _check('-12: 34', [
          item,
        ], ChronoParsed()..offset = TimeDelta(seconds: -45_240));
        _check('-12 :34', [
          item,
        ], ChronoParsed()..offset = TimeDelta(seconds: -45_240));
        _check('-12 : 34', [
          item,
        ], ChronoParsed()..offset = TimeDelta(seconds: -45_240));
        _check('-12 :  34', [
          item,
        ], ChronoParsed()..offset = TimeDelta(seconds: -45_240));
        _check('-12  : 34', [
          item,
        ], ChronoParsed()..offset = TimeDelta(seconds: -45_240));
        _check('-12:  34', [
          item,
        ], ChronoParsed()..offset = TimeDelta(seconds: -45_240));
        _check('-12  :34', [
          item,
        ], ChronoParsed()..offset = TimeDelta(seconds: -45_240));
        _check('-12  :  34', [
          item,
        ], ChronoParsed()..offset = TimeDelta(seconds: -45_240));
        _checkError('12:34 ', [item], .invalid);
        _checkError(' 12:34', [item], .invalid);
        _checkError('', [item], .tooShort);
        _checkError('+', [item], .tooShort);
        _check(
          '+12345',
          [item, const .day()],
          ChronoParsed()
            ..offset = TimeDelta(seconds: 45_240)
            ..day = 5,
        );
        _check(
          '+12:345',
          [item, const .day()],
          ChronoParsed()
            ..offset = TimeDelta(seconds: 45_240)
            ..day = 5,
        );
        _check('+12:34:', [
          item,
          const .literal(':'),
        ], ChronoParsed()..offset = TimeDelta(seconds: 45_240));
        _checkError('Z12:34', [item], .invalid);
        _checkError('X12:34', [item], .invalid);
        _checkError('Z+12:34', [item], .invalid);
        _checkError('X+12:34', [item], .invalid);
        _checkError('X−12:34', [item], .invalid); // MINUS SIGN (U+2212)
        _checkError('🤠+12:34', [item], .invalid);
        _checkError('+12:34🤠', [item], .tooLong);
        _checkError('+12:🤠34', [item], .invalid);
        _check('+1234🤠', [
          item,
          const .literal('🤠'),
        ], ChronoParsed()..offset = TimeDelta(seconds: 45_240));
        _check('-1234🤠', [
          item,
          const .literal('🤠'),
        ], ChronoParsed()..offset = TimeDelta(seconds: -45_240));
        _check(
          '−1234🤠',
          [item, const .literal('🤠')],
          ChronoParsed()..offset = TimeDelta(seconds: -45_240),
        ); // MINUS SIGN (U+2212)
        _check('+12:34🤠', [
          item,
          const .literal('🤠'),
        ], ChronoParsed()..offset = TimeDelta(seconds: 45_240));
        _check('-12:34🤠', [
          item,
          const .literal('🤠'),
        ], ChronoParsed()..offset = TimeDelta(seconds: -45_240));
        _check(
          '−12:34🤠',
          [item, const .literal('🤠')],
          ChronoParsed()..offset = TimeDelta(seconds: -45_240),
        ); // MINUS SIGN (U+2212)
        _check('🤠+12:34', [
          const .literal('🤠'),
          item,
        ], ChronoParsed()..offset = TimeDelta(seconds: 45_240));
        _checkError('Z', [item], .invalid);
        _checkError('A', [item], .invalid);
        _checkError('PST', [item], .invalid);
        _checkError('#Z', [item], .invalid);
        _checkError(':Z', [item], .invalid);
        _checkError('+Z', [item], .tooShort);
        _checkError('+:Z', [item], .invalid);
        _checkError('+Z:', [item], .invalid);
        _checkError('z', [item], .invalid);
        _checkError(' :Z', [item], .invalid);
        _checkError(' Z', [item], .invalid);
        _checkError(' z', [item], .invalid);
      },
    );

    test(
      '.timezoneOffset(precision: .minute, allowZulu: false, printColon: true)',
      () {
        const item = ChronoFormatItem.timezoneOffset(allowZulu: false);
        _checkError('1', [item], .invalid);
        _checkError('12', [item], .invalid);
        _checkError('123', [item], .invalid);
        _checkError('1234', [item], .invalid);
        _checkError('12345', [item], .invalid);
        _checkError('123456', [item], .invalid);
        _checkError('1234567', [item], .invalid);
        _checkError('12345678', [item], .invalid);
        _checkError('+1', [item], .tooShort);
        _checkError('+12', [item], .tooShort);
        _checkError('+123', [item], .tooShort);
        _check('+1234', [
          item,
        ], ChronoParsed()..offset = TimeDelta(seconds: 45_240));
        _check('-1234', [
          item,
        ], ChronoParsed()..offset = TimeDelta(seconds: -45_240));
        _check(
          '−1234',
          [item],
          ChronoParsed()..offset = TimeDelta(seconds: -45_240),
        ); // MINUS SIGN (U+2212)
        _checkError('+12345', [item], .tooLong);
        _checkError('+123456', [item], .tooLong);
        _checkError('+1234567', [item], .tooLong);
        _checkError('+12345678', [item], .tooLong);
        _checkError('1:', [item], .invalid);
        _checkError('12:', [item], .invalid);
        _checkError('12:3', [item], .invalid);
        _checkError('12:34', [item], .invalid);
        _checkError('12:34:', [item], .invalid);
        _checkError('12:34:5', [item], .invalid);
        _checkError('12:34:56', [item], .invalid);
        _checkError('+1:', [item], .invalid);
        _checkError('+12:', [item], .tooShort);
        _checkError('+12:3', [item], .tooShort);
        _check('+12:34', [
          item,
        ], ChronoParsed()..offset = TimeDelta(seconds: 45_240));
        _check('-12:34', [
          item,
        ], ChronoParsed()..offset = TimeDelta(seconds: -45_240));
        _check(
          '−12:34',
          [item],
          ChronoParsed()..offset = TimeDelta(seconds: -45_240),
        ); // MINUS SIGN (U+2212)
        _checkError('+12:34:', [item], .tooLong);
        _checkError('+12:34:5', [item], .tooLong);
        _checkError('+12:34:56', [item], .tooLong);
        _checkError('+12:34:56:', [item], .tooLong);
        _checkError('+12:34:56:7', [item], .tooLong);
        _checkError('+12:34:56:78', [item], .tooLong);
        _checkError('+12:3456', [item], .tooLong);
        _checkError('+1234:56', [item], .tooLong);
        _check(
          '−12:34',
          [item],
          ChronoParsed()..offset = TimeDelta(seconds: -45_240),
        ); // MINUS SIGN (U+2212)
        _check(
          '−12 : 34',
          [item],
          ChronoParsed()..offset = TimeDelta(seconds: -45_240),
        ); // MINUS SIGN (U+2212)
        _check('+12 :34', [
          item,
        ], ChronoParsed()..offset = TimeDelta(seconds: 45_240));
        _check('+12: 34', [
          item,
        ], ChronoParsed()..offset = TimeDelta(seconds: 45_240));
        _check('+12 34', [
          item,
        ], ChronoParsed()..offset = TimeDelta(seconds: 45_240));
        _check('+12: 34', [
          item,
        ], ChronoParsed()..offset = TimeDelta(seconds: 45_240));
        _check('+12 :34', [
          item,
        ], ChronoParsed()..offset = TimeDelta(seconds: 45_240));
        _check('+12 : 34', [
          item,
        ], ChronoParsed()..offset = TimeDelta(seconds: 45_240));
        _check('-12 : 34', [
          item,
        ], ChronoParsed()..offset = TimeDelta(seconds: -45_240));
        _check('+12  : 34', [
          item,
        ], ChronoParsed()..offset = TimeDelta(seconds: 45_240));
        _check('+12 :  34', [
          item,
        ], ChronoParsed()..offset = TimeDelta(seconds: 45_240));
        _check('+12  :  34', [
          item,
        ], ChronoParsed()..offset = TimeDelta(seconds: 45_240));
        _check('+12::34', [
          item,
        ], ChronoParsed()..offset = TimeDelta(seconds: 45_240));
        _check('+12: :34', [
          item,
        ], ChronoParsed()..offset = TimeDelta(seconds: 45_240));
        _check('+12:::34', [
          item,
        ], ChronoParsed()..offset = TimeDelta(seconds: 45_240));
        _check('+12::::34', [
          item,
        ], ChronoParsed()..offset = TimeDelta(seconds: 45_240));
        _check('+12::34', [
          item,
        ], ChronoParsed()..offset = TimeDelta(seconds: 45_240));
        _checkError('#1234', [item], .invalid);
        _checkError('#12:34', [item], .invalid);
        _checkError('+12:34 ', [item], .tooLong);
        _check(' +12:34', [
          item,
        ], ChronoParsed()..offset = TimeDelta(seconds: 45_240));
        _check('\t+12:34', [
          item,
        ], ChronoParsed()..offset = TimeDelta(seconds: 45_240));
        _check('\t\t+12:34', [
          item,
        ], ChronoParsed()..offset = TimeDelta(seconds: 45_240));
        _checkError('12:34 ', [item], .invalid);
        _checkError(' 12:34', [item], .invalid);
        _checkError('', [item], .tooShort);
        _checkError('+', [item], .tooShort);
        _checkError(':', [item], .invalid);
        _check(
          '+12345',
          [item, const .day()],
          ChronoParsed()
            ..offset = TimeDelta(seconds: 45_240)
            ..day = 5,
        );
        _check(
          '+12:345',
          [item, const .day()],
          ChronoParsed()
            ..offset = TimeDelta(seconds: 45_240)
            ..day = 5,
        );
        _check('+12:34:', [
          item,
          const .literal(':'),
        ], ChronoParsed()..offset = TimeDelta(seconds: 45_240));
        _checkError('Z', [item], .invalid);
        _checkError('A', [item], .invalid);
        _checkError('PST', [item], .invalid);
        _checkError('#Z', [item], .invalid);
        _checkError(':Z', [item], .invalid);
        _checkError('+Z', [item], .tooShort);
        _checkError('+:Z', [item], .invalid);
        _checkError('+Z:', [item], .invalid);
        _checkError('z', [item], .invalid);
        _checkError(' :Z', [item], .invalid);
        _checkError(' Z', [item], .invalid);
        _checkError(' z', [item], .invalid);
        // testing `TimezoneOffsetColon` also tests same path as `TimezoneOffsetDoubleColon`
        // and `TimezoneOffsetTripleColon` for function `parse_internal`.
        // No need for separate tests for `TimezoneOffsetDoubleColon` and
        // `TimezoneOffsetTripleColon`.
      },
    );

    // TimezoneOffsetZ
    test(
      '.timezoneOffset(precision: .minute, allowZulu: true, printColon: false)',
      () {
        const item = ChronoFormatItem.timezoneOffset(printColon: false);

        _checkError('1', [item], .invalid);
        _checkError('12', [item], .invalid);
        _checkError('123', [item], .invalid);
        _checkError('1234', [item], .invalid);
        _checkError('12345', [item], .invalid);
        _checkError('123456', [item], .invalid);
        _checkError('1234567', [item], .invalid);
        _checkError('12345678', [item], .invalid);
        _checkError('+1', [item], .tooShort);
        _checkError('+12', [item], .tooShort);
        _checkError('+123', [item], .tooShort);
        _check('+1234', [
          item,
        ], ChronoParsed()..offset = TimeDelta(seconds: 45_240));
        _check('-1234', [
          item,
        ], ChronoParsed()..offset = TimeDelta(seconds: -45_240));
        _check(
          '−1234',
          [item],
          ChronoParsed()..offset = TimeDelta(seconds: -45_240),
        ); // MINUS SIGN (U+2212)
        _checkError('+12345', [item], .tooLong);
        _checkError('+123456', [item], .tooLong);
        _checkError('+1234567', [item], .tooLong);
        _checkError('+12345678', [item], .tooLong);
        _checkError('1:', [item], .invalid);
        _checkError('12:', [item], .invalid);
        _checkError('12:3', [item], .invalid);
        _checkError('12:34', [item], .invalid);
        _checkError('12:34:', [item], .invalid);
        _checkError('12:34:5', [item], .invalid);
        _checkError('12:34:56', [item], .invalid);
        _checkError('+1:', [item], .invalid);
        _checkError('+12:', [item], .tooShort);
        _checkError('+12:3', [item], .tooShort);
        _check('+12:34', [
          item,
        ], ChronoParsed()..offset = TimeDelta(seconds: 45_240));
        _check('-12:34', [
          item,
        ], ChronoParsed()..offset = TimeDelta(seconds: -45_240));
        _check(
          '−12:34',
          [item],
          ChronoParsed()..offset = TimeDelta(seconds: -45_240),
        ); // MINUS SIGN (U+2212)
        _checkError('+12:34:', [item], .tooLong);
        _checkError('+12:34:5', [item], .tooLong);
        _checkError('+12:34:56', [item], .tooLong);
        _checkError('+12:34:56:', [item], .tooLong);
        _checkError('+12:34:56:7', [item], .tooLong);
        _checkError('+12:34:56:78', [item], .tooLong);
        _check('+12::34', [
          item,
        ], ChronoParsed()..offset = TimeDelta(seconds: 45_240));
        _checkError('+12:3456', [item], .tooLong);
        _checkError('+1234:56', [item], .tooLong);
        _check('+12 34', [
          item,
        ], ChronoParsed()..offset = TimeDelta(seconds: 45_240));
        _check('+12  34', [
          item,
        ], ChronoParsed()..offset = TimeDelta(seconds: 45_240));
        _check('+12: 34', [
          item,
        ], ChronoParsed()..offset = TimeDelta(seconds: 45_240));
        _check('+12 :34', [
          item,
        ], ChronoParsed()..offset = TimeDelta(seconds: 45_240));
        _check('+12 : 34', [
          item,
        ], ChronoParsed()..offset = TimeDelta(seconds: 45_240));
        _check('+12  : 34', [
          item,
        ], ChronoParsed()..offset = TimeDelta(seconds: 45_240));
        _check('+12 :  34', [
          item,
        ], ChronoParsed()..offset = TimeDelta(seconds: 45_240));
        _check('+12  :  34', [
          item,
        ], ChronoParsed()..offset = TimeDelta(seconds: 45_240));
        _checkError('12:34 ', [item], .invalid);
        _checkError(' 12:34', [item], .invalid);
        _checkError('+12:34 ', [item], .tooLong);
        _checkError('+12 34 ', [item], .tooLong);
        _check(' +12:34', [
          item,
        ], ChronoParsed()..offset = TimeDelta(seconds: 45_240));
        _check(
          '+12345',
          [item, const .day()],
          ChronoParsed()
            ..offset = TimeDelta(seconds: 45_240)
            ..day = 5,
        );
        _check(
          '+12:345',
          [item, const .day()],
          ChronoParsed()
            ..offset = TimeDelta(seconds: 45_240)
            ..day = 5,
        );
        _check('+12:34:', [
          item,
          const .literal(':'),
        ], ChronoParsed()..offset = TimeDelta(seconds: 45_240));
        _checkError('Z12:34', [item], .tooLong);
        _checkError('X12:34', [item], .invalid);
        _check('Z', [item], ChronoParsed()..offset = TimeDelta());
        _check('z', [item], ChronoParsed()..offset = TimeDelta());
        _check(' Z', [item], ChronoParsed()..offset = TimeDelta());
        _check(' z', [item], ChronoParsed()..offset = TimeDelta());
        _checkError('\u{0363}Z', [item], .invalid);
        _checkError('Z ', [item], .tooLong);
        _checkError('A', [item], .invalid);
        _checkError('PST', [item], .invalid);
        _checkError('#Z', [item], .invalid);
        _checkError(':Z', [item], .invalid);
        _checkError(':z', [item], .invalid);
        _checkError('+Z', [item], .tooShort);
        _checkError('-Z', [item], .tooShort);
        _checkError('+A', [item], .tooShort);
        _checkError('+🙃', [item], .invalid);
        _checkError('+Z:', [item], .invalid);
        _checkError(' :Z', [item], .invalid);
        _checkError(' +Z', [item], .tooShort);
        _checkError(' -Z', [item], .tooShort);
        _checkError('+:Z', [item], .invalid);
        _checkError('Y', [item], .invalid);
        _check('Zulu', [
          item,
          const .literal('ulu'),
        ], ChronoParsed()..offset = TimeDelta());
        _check('zulu', [
          item,
          const .literal('ulu'),
        ], ChronoParsed()..offset = TimeDelta());
        _check('+1234ulu', [
          item,
          const .literal('ulu'),
        ], ChronoParsed()..offset = TimeDelta(seconds: 45_240));
        _check('+12:34ulu', [
          item,
          const .literal('ulu'),
        ], ChronoParsed()..offset = TimeDelta(seconds: 45_240));
        // Testing `TimezoneOffsetZ` also tests same path as `TimezoneOffsetColonZ`
        // in function `parse_internal`.
        // No need for separate tests for `TimezoneOffsetColonZ`.
      },
    );

    // TimezoneOffsetPermissive
    // checkError("1", [internal_fixed(TimezoneOffsetPermissive)], .invalid);
    // checkError("12", [internal_fixed(TimezoneOffsetPermissive)], .invalid);
    // checkError("123", [internal_fixed(TimezoneOffsetPermissive)], .invalid);
    // checkError("1234", [internal_fixed(TimezoneOffsetPermissive)], .invalid);
    // checkError("12345", [internal_fixed(TimezoneOffsetPermissive)], .invalid);
    // checkError("123456", [internal_fixed(TimezoneOffsetPermissive)], .invalid);
    // checkError("1234567", [internal_fixed(TimezoneOffsetPermissive)], .invalid);
    // checkError("12345678", [internal_fixed(TimezoneOffsetPermissive)], .invalid);
    // checkError("+1", [internal_fixed(TimezoneOffsetPermissive)], .tooShort);
    // check("+12", [internal_fixed(TimezoneOffsetPermissive)], parsed!(offset: 43_200));
    // checkError("+123", [internal_fixed(TimezoneOffsetPermissive)], .tooShort);
    // check("+1234", [internal_fixed(TimezoneOffsetPermissive)], parsed!(offset: 45_240));
    // check("-1234", [internal_fixed(TimezoneOffsetPermissive)], parsed!(offset: -45_240));
    // check("−1234", [internal_fixed(TimezoneOffsetPermissive)], parsed!(offset: -45_240)); // MINUS SIGN (U+2212)
    // checkError("+12345", [internal_fixed(TimezoneOffsetPermissive)], .tooLong);
    // checkError("+123456", [internal_fixed(TimezoneOffsetPermissive)], .tooLong);
    // checkError("+1234567", [internal_fixed(TimezoneOffsetPermissive)], .tooLong);
    // checkError("+12345678", [internal_fixed(TimezoneOffsetPermissive)], .tooLong);
    // checkError("1:", [internal_fixed(TimezoneOffsetPermissive)], .invalid);
    // checkError("12:", [internal_fixed(TimezoneOffsetPermissive)], .invalid);
    // checkError("12:3", [internal_fixed(TimezoneOffsetPermissive)], .invalid);
    // checkError("12:34", [internal_fixed(TimezoneOffsetPermissive)], .invalid);
    // checkError("12:34:", [internal_fixed(TimezoneOffsetPermissive)], .invalid);
    // checkError("12:34:5", [internal_fixed(TimezoneOffsetPermissive)], .invalid);
    // checkError("12:34:56", [internal_fixed(TimezoneOffsetPermissive)], .invalid);
    // checkError("+1:", [internal_fixed(TimezoneOffsetPermissive)], .invalid);
    // check("+12:", [internal_fixed(TimezoneOffsetPermissive)], parsed!(offset: 43_200));
    // checkError("+12:3", [internal_fixed(TimezoneOffsetPermissive)], .tooShort);
    // check("+12:34", [internal_fixed(TimezoneOffsetPermissive)], parsed!(offset: 45_240));
    // check("-12:34", [internal_fixed(TimezoneOffsetPermissive)], parsed!(offset: -45_240));
    // check("−12:34", [internal_fixed(TimezoneOffsetPermissive)], parsed!(offset: -45_240)); // MINUS SIGN (U+2212)
    // checkError("+12:34:", [internal_fixed(TimezoneOffsetPermissive)], .tooLong);
    // checkError("+12:34:5", [internal_fixed(TimezoneOffsetPermissive)], .tooLong);
    // checkError("+12:34:56", [internal_fixed(TimezoneOffsetPermissive)], .tooLong);
    // checkError("+12:34:56:", [internal_fixed(TimezoneOffsetPermissive)], .tooLong);
    // checkError("+12:34:56:7", [internal_fixed(TimezoneOffsetPermissive)], .tooLong);
    // checkError("+12:34:56:78", [internal_fixed(TimezoneOffsetPermissive)], .tooLong);
    // check("+12 34", [internal_fixed(TimezoneOffsetPermissive)], parsed!(offset: 45_240));
    // check("+12  34", [internal_fixed(TimezoneOffsetPermissive)], parsed!(offset: 45_240));
    // check("+12 :34", [internal_fixed(TimezoneOffsetPermissive)], parsed!(offset: 45_240));
    // check("+12: 34", [internal_fixed(TimezoneOffsetPermissive)], parsed!(offset: 45_240));
    // check("+12 : 34", [internal_fixed(TimezoneOffsetPermissive)], parsed!(offset: 45_240));
    // check("+12  :34", [internal_fixed(TimezoneOffsetPermissive)], parsed!(offset: 45_240));
    // check("+12:  34", [internal_fixed(TimezoneOffsetPermissive)], parsed!(offset: 45_240));
    // check("+12  :  34", [internal_fixed(TimezoneOffsetPermissive)], parsed!(offset: 45_240));
    // check("+12::34", [internal_fixed(TimezoneOffsetPermissive)], parsed!(offset: 45_240));
    // check("+12 ::34", [internal_fixed(TimezoneOffsetPermissive)], parsed!(offset: 45_240));
    // check("+12: :34", [internal_fixed(TimezoneOffsetPermissive)], parsed!(offset: 45_240));
    // check("+12:: 34", [internal_fixed(TimezoneOffsetPermissive)], parsed!(offset: 45_240));
    // check("+12  ::34", [internal_fixed(TimezoneOffsetPermissive)], parsed!(offset: 45_240));
    // check("+12:  :34", [internal_fixed(TimezoneOffsetPermissive)], parsed!(offset: 45_240));
    // check("+12::  34", [internal_fixed(TimezoneOffsetPermissive)], parsed!(offset: 45_240));
    // check("+12:::34", [internal_fixed(TimezoneOffsetPermissive)], parsed!(offset: 45_240));
    // check("+12::::34", [internal_fixed(TimezoneOffsetPermissive)], parsed!(offset: 45_240));
    // checkError("12:34 ", [internal_fixed(TimezoneOffsetPermissive)], .invalid);
    // checkError(" 12:34", [internal_fixed(TimezoneOffsetPermissive)], .invalid);
    // checkError("+12:34 ", [internal_fixed(TimezoneOffsetPermissive)], .tooLong);
    // check(" +12:34", [internal_fixed(TimezoneOffsetPermissive)], parsed!(offset: 45_240));
    // check(" -12:34", [internal_fixed(TimezoneOffsetPermissive)], parsed!(offset: -45_240));
    // check(" −12:34", [internal_fixed(TimezoneOffsetPermissive)], parsed!(offset: -45_240)); // MINUS SIGN (U+2212)
    // check(
    //     "+12345",
    //     [internal_fixed(TimezoneOffsetPermissive), num(Numeric::Day)],
    //     parsed!(offset: 45_240, day: 5),
    // );
    // check(
    //     "+12:345",
    //     [internal_fixed(TimezoneOffsetPermissive), num(Numeric::Day)],
    //     parsed!(offset: 45_240, day: 5),
    // );
    // check(
    //     "+12:34:",
    //     [internal_fixed(TimezoneOffsetPermissive), .literal(":")],
    //     parsed!(offset: 45_240),
    // );
    // checkError("🤠+12:34", [internal_fixed(TimezoneOffsetPermissive)], .invalid);
    // checkError("+12:34🤠", [internal_fixed(TimezoneOffsetPermissive)], .tooLong);
    // checkError("+12:🤠34", [internal_fixed(TimezoneOffsetPermissive)], .invalid);
    // check(
    //     "+12:34🤠",
    //     [internal_fixed(TimezoneOffsetPermissive), .literal("🤠")],
    //     parsed!(offset: 45_240),
    // );
    // check(
    //     "🤠+12:34",
    //     [.literal("🤠"), internal_fixed(TimezoneOffsetPermissive)],
    //     parsed!(offset: 45_240),
    // );
    // check("Z", [internal_fixed(TimezoneOffsetPermissive)], parsed!(offset: 0));
    // checkError("A", [internal_fixed(TimezoneOffsetPermissive)], .invalid);
    // checkError("PST", [internal_fixed(TimezoneOffsetPermissive)], .invalid);
    // check("z", [internal_fixed(TimezoneOffsetPermissive)], parsed!(offset: 0));
    // check(" Z", [internal_fixed(TimezoneOffsetPermissive)], parsed!(offset: 0));
    // check(" z", [internal_fixed(TimezoneOffsetPermissive)], parsed!(offset: 0));
    // checkError("Z ", [internal_fixed(TimezoneOffsetPermissive)], .tooLong);
    // checkError("#Z", [internal_fixed(TimezoneOffsetPermissive)], .invalid);
    // checkError(":Z", [internal_fixed(TimezoneOffsetPermissive)], .invalid);
    // checkError(":z", [internal_fixed(TimezoneOffsetPermissive)], .invalid);
    // checkError("+Z", [internal_fixed(TimezoneOffsetPermissive)], .tooShort);
    // checkError("-Z", [internal_fixed(TimezoneOffsetPermissive)], .tooShort);
    // checkError("+A", [internal_fixed(TimezoneOffsetPermissive)], .tooShort);
    // checkError("+PST", [internal_fixed(TimezoneOffsetPermissive)], .invalid);
    // checkError("+🙃", [internal_fixed(TimezoneOffsetPermissive)], .invalid);
    // checkError("+Z:", [internal_fixed(TimezoneOffsetPermissive)], .invalid);
    // checkError(" :Z", [internal_fixed(TimezoneOffsetPermissive)], .invalid);
    // checkError(" +Z", [internal_fixed(TimezoneOffsetPermissive)], .tooShort);
    // checkError(" -Z", [internal_fixed(TimezoneOffsetPermissive)], .tooShort);
    // checkError("+:Z", [internal_fixed(TimezoneOffsetPermissive)], .invalid);
    // checkError("Y", [internal_fixed(TimezoneOffsetPermissive)], .invalid);

    test('.timezoneName()', () {
      _check('CEST', [const .timezoneName()], ChronoParsed());
      _check('cest', [const .timezoneName()], ChronoParsed()); // lowercase
      _check('XXXXXXXX', [
        const .timezoneName(),
      ], ChronoParsed()); // not a real timezone name
      _check('!!!!', [
        const .timezoneName(),
      ], ChronoParsed()); // not a real timezone name!
      _check('CEST 5', [
        const .timezoneName(),
        const .literal(' '),
        const .day(),
      ], ChronoParsed()..day = 5);
      _checkError('CEST ', [const .timezoneName()], .tooLong);
      _checkError(' CEST', [const .timezoneName()], .tooLong);
      _checkError('CE ST', [const .timezoneName()], .tooLong);
    });
  });

  // test('parse_practical_examples', () {
  //     // some practical examples
  //     check(
  //         "2015-02-04T14:37:05+09:00",
  //         [
  //             .year(), .literal("-"), num(Month), .literal("-"), num(Day), .literal("T"),
  //             num(Hour), .literal(":"), num(Minute), .literal(":"), num(Second),
  //             fixed(Fixed::TimezoneOffset),
  //         ],
  //         parsed!(
  //             year: 2015, month: 2, day: 4, hour_div_12: 1, hour_mod_12: 2, minute: 37,
  //             second: 5, offset: 32400
  //         ),
  //     );
  //     check(
  //         "2015-02-04T14:37:05-09:00",
  //         [
  //             .year(), .literal("-"), num(Month), .literal("-"), num(Day), .literal("T"),
  //             num(Hour), .literal(":"), num(Minute), .literal(":"), num(Second),
  //             fixed(Fixed::TimezoneOffset),
  //         ],
  //         parsed!(
  //             year: 2015, month: 2, day: 4, hour_div_12: 1, hour_mod_12: 2, minute: 37,
  //             second: 5, offset: -32400
  //         ),
  //     );
  //     check(
  //         "2015-02-04T14:37:05−09:00", // timezone offset using MINUS SIGN (U+2212)
  //         [
  //             .year(), .literal("-"), num(Month), .literal("-"), num(Day), .literal("T"),
  //             num(Hour), .literal(":"), num(Minute), .literal(":"), num(Second),
  //             fixed(Fixed::TimezoneOffset)
  //         ],
  //         parsed!(
  //             year: 2015, month: 2, day: 4, hour_div_12: 1, hour_mod_12: 2, minute: 37,
  //             second: 5, offset: -32400
  //         ),
  //     );
  //     check(
  //         "20150204143705567",
  //         [
  //             .year(), num(Month), num(Day), num(Hour), num(Minute), num(Second),
  //             internal_fixed(Nanosecond3NoDot)
  //         ],
  //         parsed!(
  //             year: 2015, month: 2, day: 4, hour_div_12: 1, hour_mod_12: 2, minute: 37,
  //             second: 5, nanosecond: 567000000
  //         ),
  //     );
  //     check(
  //         "Mon, 10 Jun 2013 09:32:37 GMT",
  //         [
  //             fixed(Fixed::ShortWeekdayName), .literal(","), .space(" "), num(Day), .space(" "),
  //             fixed(Fixed::ShortMonthName), .space(" "), .year(), .space(" "), num(Hour),
  //             .literal(":"), num(Minute), .literal(":"), num(Second), .space(" "), .literal("GMT")
  //         ],
  //         parsed!(
  //             year: 2013, month: 6, day: 10, weekday: Weekday::Mon,
  //             hour_div_12: 0, hour_mod_12: 9, minute: 32, second: 37
  //         ),
  //     );
  //     check(
  //         "🤠Mon, 10 Jun🤠2013 09:32:37  GMT🤠",
  //         [
  //             .literal("🤠"), fixed(Fixed::ShortWeekdayName), .literal(","), .space(" "), num(Day),
  //             .space(" "), fixed(Fixed::ShortMonthName), .literal("🤠"), .year(), .space(" "),
  //             num(Hour), .literal(":"), num(Minute), .literal(":"), num(Second), .space("  "),
  //             .literal("GMT"), .literal("🤠")
  //         ],
  //         parsed!(
  //             year: 2013, month: 6, day: 10, weekday: Weekday::Mon,
  //             hour_div_12: 0, hour_mod_12: 9, minute: 32, second: 37
  //         ),
  //     );
  //     check(
  //         "Sun Aug 02 13:39:15 CEST 2020",
  //         [
  //             fixed(Fixed::ShortWeekdayName), .space(" "), fixed(Fixed::ShortMonthName),
  //             .space(" "), num(Day), .space(" "), num(Hour), .literal(":"), num(Minute),
  //             .literal(":"), num(Second), .space(" "), fixed(Fixed::TimezoneName), .space(" "),
  //             .year()
  //         ],
  //         parsed!(
  //             year: 2020, month: 8, day: 2, weekday: Weekday::Sun,
  //             hour_div_12: 1, hour_mod_12: 1, minute: 39, second: 15
  //         ),
  //     );
  //     check(
  //         "20060102150405",
  //         [.year(), num(Month), num(Day), num(Hour), num(Minute), num(Second)],
  //         parsed!(
  //             year: 2006, month: 1, day: 2, hour_div_12: 1, hour_mod_12: 3, minute: 4, second: 5
  //         ),
  //     );
  //     check(
  //         "3:14PM",
  //         [num(Hour12), .literal(":"), num(Minute), fixed(Fixed::LowerAmPm)],
  //         parsed!(hour_div_12: 1, hour_mod_12: 3, minute: 14),
  //     );
  //     check(
  //         "12345678901234.56789",
  //         [num(Timestamp), .literal("."), num(Nanosecond)],
  //         parsed!(nanosecond: 56_789, timestamp: 12_345_678_901_234),
  //     );
  //     check(
  //         "12345678901234.56789",
  //         [num(Timestamp), fixed(Fixed::Nanosecond)],
  //         parsed!(nanosecond: 567_890_000, timestamp: 12_345_678_901_234),
  //     );

  //     // docstring examples from `impl str::FromStr`
  //     check(
  //         "2000-01-02T03:04:05Z",
  //         [
  //             .year(), .literal("-"), num(Month), .literal("-"), num(Day), .literal("T"),
  //             num(Hour), .literal(":"), num(Minute), .literal(":"), num(Second),
  //             internal_fixed(TimezoneOffsetPermissive)
  //         ],
  //         parsed!(
  //             year: 2000, month: 1, day: 2, hour_div_12: 0, hour_mod_12: 3, minute: 4, second: 5,
  //             offset: 0
  //         ),
  //     );
  //     check(
  //         "2000-01-02 03:04:05Z",
  //         [
  //             .year(), .literal("-"), num(Month), .literal("-"), num(Day), .space(" "),
  //             num(Hour), .literal(":"), num(Minute), .literal(":"), num(Second),
  //             internal_fixed(TimezoneOffsetPermissive)
  //         ],
  //         parsed!(
  //             year: 2000, month: 1, day: 2, hour_div_12: 0, hour_mod_12: 3, minute: 4, second: 5,
  //             offset: 0
  //         ),
  //     );
  // }

  // #[track_caller]
  // fn parses(s: &str, items: [Item]) {
  //     let mut parsed = Parsed::new();
  //     assert!(parse(&mut parsed, s, items.iter()).is_ok());
  // }

  // #[track_caller]
  // fn check(s: &str, items: [Item], expected: ParseResult<Parsed>) {
  //     let mut parsed = Parsed::new();
  //     let result = parse(&mut parsed, s, items.iter());
  //     let parsed = result.map(|_| parsed);
  //     assert_eq!(parsed, expected);
  // }

  // test('rfc2822', () {
  //     let ymd_hmsn = |y, m, d, h, n, s, nano, off| {
  //         FixedOffset::east_opt(off * 60 * 60)
  //             .unwrap()
  //             .with_ymd_and_hms(y, m, d, h, n, s)
  //             .unwrap()
  //             .with_nanosecond(nano)
  //             .unwrap()
  //     };

  //     // Test data - (input, Ok(expected result) or Err(error code))
  //     let testdates = [
  //         ("Tue, 20 Jan 2015 17:35:20 -0800", Ok(ymd_hmsn(2015, 1, 20, 17, 35, 20, 0, -8))), // normal case
  //         ("Fri,  2 Jan 2015 17:35:20 -0800", Ok(ymd_hmsn(2015, 1, 2, 17, 35, 20, 0, -8))), // folding whitespace
  //         ("Fri, 02 Jan 2015 17:35:20 -0800", Ok(ymd_hmsn(2015, 1, 2, 17, 35, 20, 0, -8))), // leading zero
  //         ("Tue, 20 Jan 2015 17:35:20 -0800 (UTC)", Ok(ymd_hmsn(2015, 1, 20, 17, 35, 20, 0, -8))), // trailing comment
  //         (
  //             r"Tue, 20 Jan 2015 17:35:20 -0800 ( (UTC ) (\( (a)\(( \t ) ) \\( \) ))",
  //             Ok(ymd_hmsn(2015, 1, 20, 17, 35, 20, 0, -8)),
  //         ), // complex trailing comment
  //         (r"Tue, 20 Jan 2015 17:35:20 -0800 (UTC\)", .tooLong), // incorrect comment, not enough closing parentheses
  //         (
  //             "Tue, 20 Jan 2015 17:35:20 -0800 (UTC)\t \r\n(Anothercomment)",
  //             Ok(ymd_hmsn(2015, 1, 20, 17, 35, 20, 0, -8)),
  //         ), // multiple comments
  //         ("Tue, 20 Jan 2015 17:35:20 -0800 (UTC) ", .tooLong), // trailing whitespace after comment
  //         ("20 Jan 2015 17:35:20 -0800", Ok(ymd_hmsn(2015, 1, 20, 17, 35, 20, 0, -8))), // no day of week
  //         ("20 JAN 2015 17:35:20 -0800", Ok(ymd_hmsn(2015, 1, 20, 17, 35, 20, 0, -8))), // upper case month
  //         ("Tue, 20 Jan 2015 17:35 -0800", Ok(ymd_hmsn(2015, 1, 20, 17, 35, 0, 0, -8))), // no second
  //         ("11 Sep 2001 09:45:00 +0000", Ok(ymd_hmsn(2001, 9, 11, 9, 45, 0, 0, 0))),
  //         ("11 Sep 2001 09:45:00 EST", Ok(ymd_hmsn(2001, 9, 11, 9, 45, 0, 0, -5))),
  //         ("11 Sep 2001 09:45:00 GMT", Ok(ymd_hmsn(2001, 9, 11, 9, 45, 0, 0, 0))),
  //         ("30 Feb 2015 17:35:20 -0800", .outOfRange), // bad day of month
  //         ("Tue, 20 Jan 2015", .tooShort),              // omitted fields
  //         ("Tue, 20 Avr 2015 17:35:20 -0800", .invalid), // bad month name
  //         ("Tue, 20 Jan 2015 25:35:20 -0800", .outOfRange), // bad hour
  //         ("Tue, 20 Jan 2015 7:35:20 -0800", .invalid),  // bad # of digits in hour
  //         ("Tue, 20 Jan 2015 17:65:20 -0800", .outOfRange), // bad minute
  //         ("Tue, 20 Jan 2015 17:35:90 -0800", .outOfRange), // bad second
  //         ("Tue, 20 Jan 2015 17:35:20 -0890", .outOfRange), // bad offset
  //         ("6 Jun 1944 04:00:00Z", .invalid),            // bad offset (zulu not allowed)
  //         // named timezones that have specific timezone offsets
  //         // see https://www.rfc-editor.org/rfc/rfc2822#section-4.3
  //         ("Tue, 20 Jan 2015 17:35:20 GMT", Ok(ymd_hmsn(2015, 1, 20, 17, 35, 20, 0, 0))),
  //         ("Tue, 20 Jan 2015 17:35:20 UT", Ok(ymd_hmsn(2015, 1, 20, 17, 35, 20, 0, 0))),
  //         ("Tue, 20 Jan 2015 17:35:20 ut", Ok(ymd_hmsn(2015, 1, 20, 17, 35, 20, 0, 0))),
  //         ("Tue, 20 Jan 2015 17:35:20 EDT", Ok(ymd_hmsn(2015, 1, 20, 17, 35, 20, 0, -4))),
  //         ("Tue, 20 Jan 2015 17:35:20 EST", Ok(ymd_hmsn(2015, 1, 20, 17, 35, 20, 0, -5))),
  //         ("Tue, 20 Jan 2015 17:35:20 CDT", Ok(ymd_hmsn(2015, 1, 20, 17, 35, 20, 0, -5))),
  //         ("Tue, 20 Jan 2015 17:35:20 CST", Ok(ymd_hmsn(2015, 1, 20, 17, 35, 20, 0, -6))),
  //         ("Tue, 20 Jan 2015 17:35:20 MDT", Ok(ymd_hmsn(2015, 1, 20, 17, 35, 20, 0, -6))),
  //         ("Tue, 20 Jan 2015 17:35:20 MST", Ok(ymd_hmsn(2015, 1, 20, 17, 35, 20, 0, -7))),
  //         ("Tue, 20 Jan 2015 17:35:20 PDT", Ok(ymd_hmsn(2015, 1, 20, 17, 35, 20, 0, -7))),
  //         ("Tue, 20 Jan 2015 17:35:20 PST", Ok(ymd_hmsn(2015, 1, 20, 17, 35, 20, 0, -8))),
  //         ("Tue, 20 Jan 2015 17:35:20 pst", Ok(ymd_hmsn(2015, 1, 20, 17, 35, 20, 0, -8))),
  //         // named single-letter military timezones must fallback to +0000
  //         ("Tue, 20 Jan 2015 17:35:20 Z", Ok(ymd_hmsn(2015, 1, 20, 17, 35, 20, 0, 0))),
  //         ("Tue, 20 Jan 2015 17:35:20 A", Ok(ymd_hmsn(2015, 1, 20, 17, 35, 20, 0, 0))),
  //         ("Tue, 20 Jan 2015 17:35:20 a", Ok(ymd_hmsn(2015, 1, 20, 17, 35, 20, 0, 0))),
  //         ("Tue, 20 Jan 2015 17:35:20 K", Ok(ymd_hmsn(2015, 1, 20, 17, 35, 20, 0, 0))),
  //         ("Tue, 20 Jan 2015 17:35:20 k", Ok(ymd_hmsn(2015, 1, 20, 17, 35, 20, 0, 0))),
  //         // named single-letter timezone "J" is specifically not valid
  //         ("Tue, 20 Jan 2015 17:35:20 J", .invalid),
  //         ("Tue, 20 Jan 2015 17:35:20 -0890", .outOfRange), // bad offset minutes
  //         ("Tue, 20 Jan 2015 17:35:20Z", .invalid),           // bad offset: zulu not allowed
  //         ("Tue, 20 Jan 2015 17:35:20 Zulu", .invalid),       // bad offset: zulu not allowed
  //         ("Tue, 20 Jan 2015 17:35:20 ZULU", .invalid),       // bad offset: zulu not allowed
  //         ("Tue, 20 Jan 2015 17:35:20 −0800", .invalid), // bad offset: timezone offset using MINUS SIGN (U+2212), not specified for RFC 2822
  //         ("Tue, 20 Jan 2015 17:35:20 0800", .invalid),  // missing offset sign
  //         ("Tue, 20 Jan 2015 17:35:20 HAS", .invalid),   // bad named timezone
  //         ("Tue, 20 Jan 2015😈17:35:20 -0800", .invalid), // bad character!
  //     ];

  //     fn rfc2822_to_datetime(date: &str) -> ParseResult<DateTime<FixedOffset>> {
  //         let mut parsed = Parsed::new();
  //         parse(&mut parsed, date, [Item::Fixed(Fixed::RFC2822)].iter())?;
  //         parsed.to_datetime()
  //     }

  //     // Test against test data above
  //     for &(date, checkdate) in testdates.iter() {
  //         #[cfg(feature = "std")]
  //         eprintln!("Test input: {date:?}\n    Expect: {checkdate:?}");
  //         let dt = rfc2822_to_datetime(date); // parse a date
  //         if dt != checkdate {
  //             // check for expected result
  //             panic!(
  //                 "Date conversion failed for {date}\nReceived: {dt:?}\nExpected: {checkdate:?}"
  //             );
  //         }
  //     }
  // });

  // test('_rfc850', () {
  //     static RFC850_FMT: &str = "%A, %d-%b-%y %T GMT";

  //     let dt = Utc.with_ymd_and_hms(1994, 11, 6, 8, 49, 37).unwrap();

  //     // Check that the format is what we expect
  //     #[cfg(feature = "alloc")]
  //     assert_eq!(dt.format(RFC850_FMT).to_string(), "Sunday, 06-Nov-94 08:49:37 GMT");

  //     // Check that it parses correctly
  //     assert_eq!(
  //         NaiveDateTime::parse_from_str("Sunday, 06-Nov-94 08:49:37 GMT", RFC850_FMT),
  //         Ok(dt.naive_utc())
  //     );

  //     // Check that the rest of the weekdays parse correctly (this test originally failed because
  //     // Sunday parsed incorrectly).
  //     let testdates = [
  //         (
  //             Utc.with_ymd_and_hms(1994, 11, 7, 8, 49, 37).unwrap(),
  //             "Monday, 07-Nov-94 08:49:37 GMT",
  //         ),
  //         (
  //             Utc.with_ymd_and_hms(1994, 11, 8, 8, 49, 37).unwrap(),
  //             "Tuesday, 08-Nov-94 08:49:37 GMT",
  //         ),
  //         (
  //             Utc.with_ymd_and_hms(1994, 11, 9, 8, 49, 37).unwrap(),
  //             "Wednesday, 09-Nov-94 08:49:37 GMT",
  //         ),
  //         (
  //             Utc.with_ymd_and_hms(1994, 11, 10, 8, 49, 37).unwrap(),
  //             "Thursday, 10-Nov-94 08:49:37 GMT",
  //         ),
  //         (
  //             Utc.with_ymd_and_hms(1994, 11, 11, 8, 49, 37).unwrap(),
  //             "Friday, 11-Nov-94 08:49:37 GMT",
  //         ),
  //         (
  //             Utc.with_ymd_and_hms(1994, 11, 12, 8, 49, 37).unwrap(),
  //             "Saturday, 12-Nov-94 08:49:37 GMT",
  //         ),
  //     ];

  //     for val in &testdates {
  //         assert_eq!(NaiveDateTime::parse_from_str(val.1, RFC850_FMT), Ok(val.0.naive_utc()));
  //     }

  //     let test_dates_fail = [
  //         "Saturday, 12-Nov-94 08:49:37",
  //         "Saturday, 12-Nov-94 08:49:37 Z",
  //         "Saturday, 12-Nov-94 08:49:37 GMTTTT",
  //         "Saturday, 12-Nov-94 08:49:37 gmt",
  //         "Saturday, 12-Nov-94 08:49:37 +08:00",
  //         "Caturday, 12-Nov-94 08:49:37 GMT",
  //         "Saturday, 99-Nov-94 08:49:37 GMT",
  //         "Saturday, 12-Nov-2000 08:49:37 GMT",
  //         "Saturday, 12-Mop-94 08:49:37 GMT",
  //         "Saturday, 12-Nov-94 28:49:37 GMT",
  //         "Saturday, 12-Nov-94 08:99:37 GMT",
  //         "Saturday, 12-Nov-94 08:49:99 GMT",
  //     ];

  //     for val in &test_dates_fail {
  //         assert!(NaiveDateTime::parse_from_str(val, RFC850_FMT).is_err());
  //     }
  // });

  // test('rfc3339', () {
  //     let ymd_hmsn = |y, m, d, h, n, s, nano, off| {
  //         FixedOffset::east_opt(off * 60 * 60)
  //             .unwrap()
  //             .with_ymd_and_hms(y, m, d, h, n, s)
  //             .unwrap()
  //             .with_nanosecond(nano)
  //             .unwrap()
  //     };

  //     // Test data - (input, Ok(expected result) or Err(error code))
  //     let testdates = [
  //         ("2015-01-20T17:35:20-08:00", Ok(ymd_hmsn(2015, 1, 20, 17, 35, 20, 0, -8))), // normal case
  //         ("2015-01-20T17:35:20−08:00", Ok(ymd_hmsn(2015, 1, 20, 17, 35, 20, 0, -8))), // normal case with MINUS SIGN (U+2212)
  //         ("1944-06-06T04:04:00Z", Ok(ymd_hmsn(1944, 6, 6, 4, 4, 0, 0, 0))),           // D-day
  //         ("2001-09-11T09:45:00-08:00", Ok(ymd_hmsn(2001, 9, 11, 9, 45, 0, 0, -8))),
  //         ("2015-01-20T17:35:20.001-08:00", Ok(ymd_hmsn(2015, 1, 20, 17, 35, 20, 1_000_000, -8))),
  //         ("2015-01-20T17:35:20.001−08:00", Ok(ymd_hmsn(2015, 1, 20, 17, 35, 20, 1_000_000, -8))), // with MINUS SIGN (U+2212)
  //         ("2015-01-20T17:35:20.000031-08:00", Ok(ymd_hmsn(2015, 1, 20, 17, 35, 20, 31_000, -8))),
  //         ("2015-01-20T17:35:20.000000004-08:00", Ok(ymd_hmsn(2015, 1, 20, 17, 35, 20, 4, -8))),
  //         ("2015-01-20T17:35:20.000000004−08:00", Ok(ymd_hmsn(2015, 1, 20, 17, 35, 20, 4, -8))), // with MINUS SIGN (U+2212)
  //         (
  //             "2015-01-20T17:35:20.000000000452-08:00",
  //             Ok(ymd_hmsn(2015, 1, 20, 17, 35, 20, 0, -8)),
  //         ), // too small
  //         (
  //             "2015-01-20T17:35:20.000000000452−08:00",
  //             Ok(ymd_hmsn(2015, 1, 20, 17, 35, 20, 0, -8)),
  //         ), // too small with MINUS SIGN (U+2212)
  //         ("2023-11-05T01:30:00-04:00", Ok(ymd_hmsn(2023, 11, 5, 1, 30, 0, 0, -4))), // ambiguous timestamp
  //         ("2015-01-20 17:35:20-08:00", Ok(ymd_hmsn(2015, 1, 20, 17, 35, 20, 0, -8))), // without 'T'
  //         ("2015-01-20_17:35:20-08:00", .invalid), // wrong date time separator
  //         ("2015/01/20T17:35:20.001-08:00", .invalid), // wrong separator char YM
  //         ("2015-01/20T17:35:20.001-08:00", .invalid), // wrong separator char MD
  //         ("2015-01-20T17-35-20.001-08:00", .invalid), // wrong separator char HM
  //         ("2015-01-20T17-35:20.001-08:00", .invalid), // wrong separator char MS
  //         ("-01-20T17:35:20-08:00", .invalid),     // missing year
  //         ("99-01-20T17:35:20-08:00", .invalid),   // bad year format
  //         ("99999-01-20T17:35:20-08:00", .invalid), // bad year value
  //         ("-2000-01-20T17:35:20-08:00", .invalid), // bad year value
  //         ("2015-00-30T17:35:20-08:00", .outOfRange), // bad month value
  //         ("2015-02-30T17:35:20-08:00", .outOfRange), // bad day of month value
  //         ("2015-01-20T25:35:20-08:00", .outOfRange), // bad hour value
  //         ("2015-01-20T17:65:20-08:00", .outOfRange), // bad minute value
  //         ("2015-01-20T17:35:90-08:00", .outOfRange), // bad second value
  //         ("2015-01-20T17:35:20-24:00", .outOfRange), // bad offset value
  //         ("15-01-20T17:35:20-08:00", .invalid),   // bad year format
  //         ("15-01-20T17:35:20-08:00:00", .invalid), // bad year format, bad offset format
  //         ("2015-01-20T17:35:2008:00", .invalid),  // missing offset sign
  //         ("2015-01-20T17:35:20 08:00", .invalid), // missing offset sign
  //         ("2015-01-20T17:35:20Zulu", .tooLong),  // bad offset format
  //         ("2015-01-20T17:35:20 Zulu", .invalid),  // bad offset format
  //         ("2015-01-20T17:35:20GMT", .invalid),    // bad offset format
  //         ("2015-01-20T17:35:20 GMT", .invalid),   // bad offset format
  //         ("2015-01-20T17:35:20+GMT", .invalid),   // bad offset format
  //         ("2015-01-20T17:35:20++08:00", .invalid), // bad offset format
  //         ("2015-01-20T17:35:20--08:00", .invalid), // bad offset format
  //         ("2015-01-20T17:35:20−−08:00", .invalid), // bad offset format with MINUS SIGN (U+2212)
  //         ("2015-01-20T17:35:20±08:00", .invalid),  // bad offset sign
  //         ("2015-01-20T17:35:20-08-00", .invalid),  // bad offset separator
  //         ("2015-01-20T17:35:20-08;00", .invalid),  // bad offset separator
  //         ("2015-01-20T17:35:20-0800", .invalid),   // bad offset separator
  //         ("2015-01-20T17:35:20-08:0", .tooShort), // bad offset minutes
  //         ("2015-01-20T17:35:20-08:AA", .invalid),  // bad offset minutes
  //         ("2015-01-20T17:35:20-08:ZZ", .invalid),  // bad offset minutes
  //         ("2015-01-20T17:35:20.001-08 : 00", .invalid), // bad offset separator
  //         ("2015-01-20T17:35:20-08:00:00", .tooLong), // bad offset format
  //         ("2015-01-20T17:35:20+08:", .tooShort),  // bad offset format
  //         ("2015-01-20T17:35:20-08:", .tooShort),  // bad offset format
  //         ("2015-01-20T17:35:20−08:", .tooShort), // bad offset format with MINUS SIGN (U+2212)
  //         ("2015-01-20T17:35:20-08", .tooShort),  // bad offset format
  //         ("2015-01-20T", .tooShort),             // missing HMS
  //         ("2015-01-20T00:00:1", .tooShort),      // missing complete S
  //         ("2015-01-20T00:00:1-08:00", .invalid),  // missing complete S
  //     ];

  //     // Test against test data above
  //     for &(date, checkdate) in testdates.iter() {
  //         let dt = DateTime::<FixedOffset>::parse_from_rfc3339(date);
  //         if dt != checkdate {
  //             // check for expected result
  //             panic!(
  //                 "Date conversion failed for {date}\nReceived: {dt:?}\nExpected: {checkdate:?}"
  //             );
  //         }
  //     }
  // });

  // test('issue_1010', () {
  //     let dt = crate::NaiveDateTime::parse_from_str(
  //         "\u{c}SUN\u{e}\u{3000}\0m@J\u{3000}\0\u{3000}\0m\u{c}!\u{c}\u{b}\u{c}\u{c}\u{c}\u{c}%A\u{c}\u{b}\0SU\u{c}\u{c}",
  //         "\u{c}\u{c}%A\u{c}\u{b}\0SUN\u{c}\u{c}\u{c}SUNN\u{c}\u{c}\u{c}SUN\u{c}\u{c}!\u{c}\u{b}\u{c}\u{c}\u{c}\u{c}%A\u{c}\u{b}%a",
  //     );
  //     assert_eq!(dt, .parseerrorParseErrorKind::Invalid)));
  // });
}

void _parses(String string, List<ChronoFormatItem> items) {
  ChronoParser.parse(string, items);
}

void _check(
  String string,
  List<ChronoFormatItem> items,
  ChronoParsed expected,
) {
  final actual = ChronoParser.parse(string, items);
  expect(actual, equals(expected));
}

void _checkError(
  String string,
  List<ChronoFormatItem> items,
  ChronoParseExceptionKind kind,
) {
  try {
    ChronoParser.parse(string, items);
    fail('Expected ChronoParseException');
  } on ChronoParseException catch (e) {
    expect(e.kind, equals(kind));
  }
}
