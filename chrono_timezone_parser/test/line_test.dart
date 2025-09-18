import 'package:chrono/chrono.dart';
import 'package:chrono_timezone_parser/chrono_timezone_parser.dart';
import 'package:meta/meta.dart';
import 'package:oxidized/oxidized.dart';
import 'package:test/test.dart';

@isTest
void _test<L extends Line>(
  String description,
  String input,
  Result<L, LineParserException> expected,
) {
  test(description, () => expect(LineParser.parse(input), expected));
}

void main() {
  group('Space', () {
    _test<Line>('empty', '', const Ok(Space()));
    _test<Line>('spaces', '        ', const Ok(Space()));
    _test<Line>('comment', '# this is a comment', const Ok(Space()));
    _test<Line>('another comment', '     # so is this', const Ok(Space()));
    _test<Line>('multiple hash', '     # so is this ## ', const Ok(Space()));
  });

  group('Rule', () {
    _test<Rule>(
      'rule 1',
      'Rule  US    1967  1973  ‐     Apr  lastSun  2:00  1:00  D',
      Ok(
        Rule(
          'US',
          fromYear: const YearSpec_Number(Year(1967)),
          toYear: const YearSpec_Number(Year(1973)),
          month: Month.april,
          day: const DaySpec_Last(Weekday.sunday),
          time: const TimeSpec_HoursMinutes(2, 0).withType(TimeType.wall),
          timeToAdd: const TimeSpec_HoursMinutes(1, 0),
          letters: 'D',
        ),
      ),
    );

    _test<Rule>(
      'rule 2',
      'Rule	Greece	1976	only	-	Oct	10	2:00s	0	-',
      Ok(
        Rule(
          'Greece',
          fromYear: const YearSpec_Number(Year(1976)),
          toYear: null,
          month: Month.october,
          day: const DaySpec_Ordinal(10),
          time: const TimeSpec_HoursMinutes(2, 0).withType(TimeType.standard),
          timeToAdd: const TimeSpec_Hours(0),
        ),
      ),
    );

    _test<Rule>(
      'rule 3',
      'Rule	EU	1977	1980	-	Apr	Sun>=1	 1:00u	1:00	S',
      Ok(
        Rule(
          'EU',
          fromYear: const YearSpec_Number(Year(1977)),
          toYear: const YearSpec_Number(Year(1980)),
          month: Month.april,
          day: const DaySpec_FirstOnOrAfter(Weekday.sunday, 1),
          time: const TimeSpec_HoursMinutes(1, 0).withType(TimeType.utc),
          timeToAdd: const TimeSpec_HoursMinutes(1, 0),
          letters: 'S',
        ),
      ),
    );

    _test<Rule>(
      'no hyphen',
      'Rule	EU	1977	1980	HEY	Apr	Sun>=1	 1:00u	1:00	S',
      const Err(LineParserException.typeColumnContainedNonHyphen('HEY')),
    );
    _test<Rule>(
      'bad month',
      'Rule	EU	1977	1980	-	Febtober	Sun>=1	 1:00u	1:00	S',
      const Err(LineParserException.failedMonthParse('Febtober')),
    );
  });

  group('Zone', () {
    _test(
      'zone',
      'Zone  Australia/Adelaide  9:30    Aus         AC%sT   1971 Oct 31  2:00:00',
      Ok(
        Zone(
          'Australia/Adelaide',
          ZoneInfo(
            utcOffset: const TimeSpec_HoursMinutes(9, 30),
            saving: const Saving_Multiple('Aus'),
            format: 'AC%sT',
            time: ChangeTime_UntilTime(
              const YearSpec_Number(Year(1971)),
              Month.october,
              const DaySpec_Ordinal(31),
              const TimeSpec_HoursMinutesSeconds(
                2,
                0,
                0,
              ).withType(TimeType.wall),
            ),
          ),
        ),
      ),
    );

    _test<Line>(
      'continuation 1',
      // ignore: lines_longer_than_80_chars
      '                          9:30    Aus         AC%sT   1971 Oct 31  2:00:00',
      Ok(
        ZoneContinuation(
          ZoneInfo(
            utcOffset: const TimeSpec_HoursMinutes(9, 30),
            saving: const Saving_Multiple('Aus'),
            format: 'AC%sT',
            time: ChangeTime_UntilTime(
              const YearSpec_Number(Year(1971)),
              Month.october,
              const DaySpec_Ordinal(31),
              const TimeSpec_HoursMinutesSeconds(
                2,
                0,
                0,
              ).withType(TimeType.wall),
            ),
          ),
        ),
      ),
    );

    _test<Line>(
      'continuation 2',
      '			1:00	C-Eur	CE%sT	1943 Oct 25',
      const Ok(
        ZoneContinuation(
          ZoneInfo(
            utcOffset: TimeSpec_HoursMinutes(1, 00),
            saving: Saving_Multiple('C-Eur'),
            format: 'CE%sT',
            time: ChangeTime_UntilDay(
              YearSpec_Number(Year(1943)),
              Month.october,
              DaySpec_Ordinal(25),
            ),
          ),
        ),
      ),
    );

    _test<Zone>(
      'hyphen',
      'Zone Asia/Ust-Nera\t 9:32:54 -\tLMT\t1919',
      const Ok(
        Zone(
          'Asia/Ust-Nera',
          ZoneInfo(
            utcOffset: TimeSpec_HoursMinutesSeconds(9, 32, 54),
            saving: Saving_None(),
            format: 'LMT',
            time: ChangeTime_UntilYear(YearSpec_Number(Year(1919))),
          ),
        ),
      ),
    );

    test('negative_offsets', () {
      expect(
        LineParser.parseZone(
          'Zone    Europe/London   -0:01:15 -  LMT 1847 Dec  1  0:00s',
        )!.unwrap().info.utcOffset,
        const TimeSpec_HoursMinutesSeconds(0, -1, -15),
      );
    });

    test('negative_offsets_2', () {
      expect(
        LineParser.parseZone(
          'Zone        Europe/Madrid   -0:14:44 -      LMT     1901 Jan  1  0:00s',
        )!.unwrap().info.utcOffset,
        const TimeSpec_HoursMinutesSeconds(0, -14, -44),
      );
    });

    test('negative_offsets_3', () {
      expect(
        LineParser.parseZone(
          'Zone America/Danmarkshavn -1:14:40 -    LMT 1916 Jul 28',
        )!.unwrap().info.utcOffset,
        const TimeSpec_HoursMinutesSeconds(-1, -14, -40),
      );
    });
  });

  _test(
    'Link',
    'Link  Europe/Istanbul  Asia/Istanbul',
    const Ok(Link(existingName: 'Europe/Istanbul', newName: 'Asia/Istanbul')),
  );

  group('invalid', () {
    _test<Line>(
      'golb',
      'GOLB',
      const Err(LineParserException.invalidLineType('GOLB')),
    );

    _test<Line>(
      'non-comment',
      ' this is not a # comment',
      const Err(LineParserException.invalidTimeSpecAndType('this')),
    );
  });

  group('comment', () {
    _test(
      'comment after',
      'Link  Europe/Istanbul  Asia/Istanbul #with a comment after',
      const Ok(Link(existingName: 'Europe/Istanbul', newName: 'Asia/Istanbul')),
    );

    _test(
      'two comments after',
      'Link  Europe/Istanbul  Asia/Istanbul   # comment ## comment',
      const Ok(Link(existingName: 'Europe/Istanbul', newName: 'Asia/Istanbul')),
    );
  });
}
