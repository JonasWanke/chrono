import 'package:chrono/chrono.dart';
import 'package:chrono_timezone_parser/chrono_timezone_parser.dart';
import 'package:test/test.dart';

void main() {
  test('no transitions', () {
    final table = Table(
      rulesets: {},
      zonesets: {
        'Test/Zone': [
          TableZoneInfo(
            offsetSeconds: 1234,
            format: Format('TEST'),
            saving: const Saving_None(),
            endTime: null,
          ),
        ],
      },
    );

    expect(
      table.timespans('Test/Zone'),
      const FixedTimespanSet(
        FixedTimespan('TEST', utcOffsetSeconds: 1234, dstOffsetSeconds: 0),
        [],
      ),
    );
  });

  test('one transition', () {
    final table = Table(
      rulesets: {},
      zonesets: {
        'Test/Zone': [
          TableZoneInfo(
            offsetSeconds: 1234,
            format: Format('TEST'),
            saving: const Saving_None(),
            endTime: ChangeTime_UntilTime(
              // ignore: use_named_constants
              const YearSpec_Number(Year(1970)),
              Month.january,
              const DaySpec_Ordinal(2),
              const TimeSpec_HoursMinutesSeconds(
                10,
                17,
                36,
              ).withType(TimeType.utc),
            ),
          ),
          TableZoneInfo(
            offsetSeconds: 5678,
            format: Format('TSET'),
            saving: const Saving_None(),
            endTime: null,
          ),
        ],
      },
    );

    expect(
      table.timespans('Test/Zone'),
      const FixedTimespanSet(
        FixedTimespan('TEST', utcOffsetSeconds: 1234, dstOffsetSeconds: 0),
        [
          (
            TimeDelta.secondsPerNormalDay +
                10 * TimeDelta.secondsPerHour +
                17 * TimeDelta.secondsPerMinute +
                36,
            FixedTimespan('TSET', utcOffsetSeconds: 5678, dstOffsetSeconds: 0),
          ),
        ],
      ),
    );
  });

  test('two transitions', () {
    final table = Table(
      rulesets: {},
      zonesets: {
        'Test/Zone': [
          TableZoneInfo(
            offsetSeconds: 1234,
            format: Format('TEST'),
            saving: const Saving_None(),
            endTime: ChangeTime_UntilTime(
              // ignore: use_named_constants
              const YearSpec_Number(Year(1970)),
              Month.january,
              const DaySpec_Ordinal(2),
              const TimeSpec_HoursMinutesSeconds(
                10,
                17,
                36,
              ).withType(TimeType.standard),
            ),
          ),
          TableZoneInfo(
            offsetSeconds: 3456,
            format: Format('TSET'),
            saving: const Saving_None(),
            endTime: ChangeTime_UntilTime(
              // ignore: use_named_constants
              const YearSpec_Number(Year(1970)),
              Month.january,
              const DaySpec_Ordinal(3),
              const TimeSpec_HoursMinutesSeconds(
                17,
                9,
                27,
              ).withType(TimeType.standard),
            ),
          ),
          TableZoneInfo(
            offsetSeconds: 5678,
            format: Format('ESTE'),
            saving: const Saving_None(),
            endTime: null,
          ),
        ],
      },
    );

    expect(
      table.timespans('Test/Zone'),
      const FixedTimespanSet(
        FixedTimespan('TEST', utcOffsetSeconds: 1234, dstOffsetSeconds: 0),
        [
          (
            122222,
            FixedTimespan('TSET', utcOffsetSeconds: 3456, dstOffsetSeconds: 0),
          ),
          (
            231111,
            FixedTimespan('ESTE', utcOffsetSeconds: 5678, dstOffsetSeconds: 0),
          ),
        ],
      ),
    );
  });

  test('one rule', () {
    final table = Table(
      rulesets: {
        'Dwayne': [
          const TableRuleInfo(
            fromYear: YearSpec_Number(Year(1980)),
            toYear: null,
            month: Month.february,
            day: DaySpec_Ordinal(4),
            time: 0,
            timeType: TimeType.utc,
            timeToAdd: 1000,
            letters: null,
          ),
        ],
      },
      zonesets: {
        'Test/Zone': [
          TableZoneInfo(
            offsetSeconds: 0,
            format: Format('LMT'),
            saving: const Saving_None(),
            endTime: const ChangeTime_UntilYear(YearSpec_Number(Year(1980))),
          ),
          TableZoneInfo(
            offsetSeconds: 2000,
            format: Format('TEST'),
            saving: const Saving_Multiple('Dwayne'),
            endTime: null,
          ),
        ],
      },
    );

    expect(
      table.timespans('Test/Zone'),
      const FixedTimespanSet(
        FixedTimespan('LMT', utcOffsetSeconds: 0, dstOffsetSeconds: 0),
        [
          (
            318_470_400,
            FixedTimespan(
              'TEST',
              utcOffsetSeconds: 2000,
              dstOffsetSeconds: 1000,
            ),
          ),
        ],
      ),
    );
  });

  test('two rules', () {
    final table = Table(
      rulesets: {
        'Dwayne': [
          const TableRuleInfo(
            fromYear: YearSpec_Number(Year(1980)),
            toYear: null,
            month: Month.february,
            day: DaySpec_Ordinal(4),
            time: 0,
            timeType: TimeType.utc,
            timeToAdd: 1000,
            letters: null,
          ),
          const TableRuleInfo(
            fromYear: YearSpec_Number(Year(1989)),
            toYear: null,
            month: Month.january,
            day: DaySpec_Ordinal(12),
            time: 0,
            timeType: TimeType.utc,
            timeToAdd: 1500,
            letters: null,
          ),
        ],
      },
      zonesets: {
        'Test/Zone': [
          TableZoneInfo(
            offsetSeconds: 0,
            format: Format('LMT'),
            saving: const Saving_None(),
            endTime: const ChangeTime_UntilYear(YearSpec_Number(Year(1980))),
          ),
          TableZoneInfo(
            offsetSeconds: 2000,
            format: Format('TEST'),
            saving: const Saving_Multiple('Dwayne'),
            endTime: null,
          ),
        ],
      },
    );

    expect(
      table.timespans('Test/Zone'),
      const FixedTimespanSet(
        FixedTimespan('LMT', utcOffsetSeconds: 0, dstOffsetSeconds: 0),
        [
          (
            318_470_400,
            FixedTimespan(
              'TEST',
              utcOffsetSeconds: 2000,
              dstOffsetSeconds: 1000,
            ),
          ),
          (
            600_566_400,
            FixedTimespan(
              'TEST',
              utcOffsetSeconds: 2000,
              dstOffsetSeconds: 1500,
            ),
          ),
        ],
      ),
    );
  });

  test('Africa/Tripoli', () {
    final table = Table(
      rulesets: {
        'Libya': [
          const TableRuleInfo(
            fromYear: YearSpec_Number(Year(1951)),
            toYear: null,
            month: Month.october,
            day: DaySpec_Ordinal(14),
            time: 7200,
            timeType: TimeType.wall,
            timeToAdd: 3600,
            letters: 'S',
          ),
          const TableRuleInfo(
            fromYear: YearSpec_Number(Year(1952)),
            toYear: null,
            month: Month.january,
            day: DaySpec_Ordinal(1),
            time: 0,
            timeType: TimeType.wall,
            timeToAdd: 0,
            letters: null,
          ),
          const TableRuleInfo(
            fromYear: YearSpec_Number(Year(1953)),
            toYear: null,
            month: Month.october,
            day: DaySpec_Ordinal(9),
            time: 7200,
            timeType: TimeType.wall,
            timeToAdd: 3600,
            letters: 'S',
          ),
          const TableRuleInfo(
            fromYear: YearSpec_Number(Year(1954)),
            toYear: null,
            month: Month.january,
            day: DaySpec_Ordinal(1),
            time: 0,
            timeType: TimeType.wall,
            timeToAdd: 0,
            letters: null,
          ),
          const TableRuleInfo(
            fromYear: YearSpec_Number(Year(1955)),
            toYear: null,
            month: Month.september,
            day: DaySpec_Ordinal(30),
            time: 0,
            timeType: TimeType.wall,
            timeToAdd: 3600,
            letters: 'S',
          ),
          const TableRuleInfo(
            fromYear: YearSpec_Number(Year(1956)),
            toYear: null,
            month: Month.january,
            day: DaySpec_Ordinal(1),
            time: 0,
            timeType: TimeType.wall,
            timeToAdd: 0,
            letters: null,
          ),
          const TableRuleInfo(
            fromYear: YearSpec_Number(Year(1982)),
            toYear: YearSpec_Number(Year(1984)),
            month: Month.april,
            day: DaySpec_Ordinal(1),
            time: 0,
            timeType: TimeType.wall,
            timeToAdd: 3600,
            letters: 'S',
          ),
          const TableRuleInfo(
            fromYear: YearSpec_Number(Year(1982)),
            toYear: YearSpec_Number(Year(1985)),
            month: Month.october,
            day: DaySpec_Ordinal(1),
            time: 0,
            timeType: TimeType.wall,
            timeToAdd: 0,
            letters: null,
          ),
          const TableRuleInfo(
            fromYear: YearSpec_Number(Year(1985)),
            toYear: null,
            month: Month.april,
            day: DaySpec_Ordinal(6),
            time: 0,
            timeType: TimeType.wall,
            timeToAdd: 3600,
            letters: 'S',
          ),
          const TableRuleInfo(
            fromYear: YearSpec_Number(Year(1986)),
            toYear: null,
            month: Month.april,
            day: DaySpec_Ordinal(4),
            time: 0,
            timeType: TimeType.wall,
            timeToAdd: 3600,
            letters: 'S',
          ),
          const TableRuleInfo(
            fromYear: YearSpec_Number(Year(1986)),
            toYear: null,
            month: Month.october,
            day: DaySpec_Ordinal(3),
            time: 0,
            timeType: TimeType.wall,
            timeToAdd: 0,
            letters: null,
          ),
          const TableRuleInfo(
            fromYear: YearSpec_Number(Year(1987)),
            toYear: YearSpec_Number(Year(1989)),
            month: Month.april,
            day: DaySpec_Ordinal(1),
            time: 0,
            timeType: TimeType.wall,
            timeToAdd: 3600,
            letters: 'S',
          ),
          const TableRuleInfo(
            fromYear: YearSpec_Number(Year(1987)),
            toYear: YearSpec_Number(Year(1989)),
            month: Month.october,
            day: DaySpec_Ordinal(1),
            time: 0,
            timeType: TimeType.wall,
            timeToAdd: 0,
            letters: null,
          ),
          const TableRuleInfo(
            fromYear: YearSpec_Number(Year(1997)),
            toYear: null,
            month: Month.april,
            day: DaySpec_Ordinal(4),
            time: 0,
            timeType: TimeType.wall,
            timeToAdd: 3600,
            letters: 'S',
          ),
          const TableRuleInfo(
            fromYear: YearSpec_Number(Year(1997)),
            toYear: null,
            month: Month.october,
            day: DaySpec_Ordinal(4),
            time: 0,
            timeType: TimeType.wall,
            timeToAdd: 0,
            letters: null,
          ),
          const TableRuleInfo(
            fromYear: YearSpec_Number(Year(2013)),
            toYear: null,
            month: Month.march,
            day: DaySpec_Last(Weekday.friday),
            time: 3600,
            timeType: TimeType.wall,
            timeToAdd: 3600,
            letters: 'S',
          ),
          const TableRuleInfo(
            fromYear: YearSpec_Number(Year(2013)),
            toYear: null,
            month: Month.october,
            day: DaySpec_Last(Weekday.friday),
            time: 7200,
            timeType: TimeType.wall,
            timeToAdd: 0,
            letters: null,
          ),
        ],
      },
      zonesets: {
        'Test/Zone': [
          TableZoneInfo(
            offsetSeconds: 3164,
            format: Format('LMT'),
            saving: const Saving_None(),
            endTime: const ChangeTime_UntilYear(YearSpec_Number(Year(1920))),
          ),
          TableZoneInfo(
            offsetSeconds: 3600,
            format: Format('CE%sT'),
            saving: const Saving_Multiple('Libya'),
            endTime: const ChangeTime_UntilYear(YearSpec_Number(Year(1959))),
          ),
          TableZoneInfo(
            offsetSeconds: 7200,
            format: Format('EET'),
            saving: const Saving_None(),
            endTime: const ChangeTime_UntilYear(YearSpec_Number(Year(1982))),
          ),
          TableZoneInfo(
            offsetSeconds: 3600,
            format: Format('CE%sT'),
            saving: const Saving_Multiple('Libya'),
            endTime: const ChangeTime_UntilDay(
              YearSpec_Number(Year(1990)),
              Month.may,
              DaySpec_Ordinal(4),
            ),
          ),
          TableZoneInfo(
            offsetSeconds: 7200,
            format: Format('EET'),
            saving: const Saving_None(),
            endTime: const ChangeTime_UntilDay(
              YearSpec_Number(Year(1996)),
              Month.september,
              DaySpec_Ordinal(30),
            ),
          ),
          TableZoneInfo(
            offsetSeconds: 3600,
            format: Format('CE%sT'),
            saving: const Saving_Multiple('Libya'),
            endTime: const ChangeTime_UntilDay(
              YearSpec_Number(Year(1997)),
              Month.october,
              DaySpec_Ordinal(4),
            ),
          ),
          TableZoneInfo(
            offsetSeconds: 7200,
            format: Format('EET'),
            saving: const Saving_None(),
            endTime: ChangeTime_UntilTime(
              const YearSpec_Number(Year(2012)),
              Month.november,
              const DaySpec_Ordinal(10),
              const TimeSpec_HoursMinutes(2, 0).withType(TimeType.wall),
            ),
          ),
          TableZoneInfo(
            offsetSeconds: 3600,
            format: Format('CE%sT'),
            saving: const Saving_Multiple('Libya'),
            endTime: ChangeTime_UntilTime(
              const YearSpec_Number(Year(2013)),
              Month.october,
              const DaySpec_Ordinal(25),
              const TimeSpec_HoursMinutes(2, 0).withType(TimeType.wall),
            ),
          ),
          TableZoneInfo(
            offsetSeconds: 7200,
            format: Format('EET'),
            saving: const Saving_None(),
            endTime: null,
          ),
        ],
      },
    );

    expect(
      table.timespans('Test/Zone'),
      const FixedTimespanSet(
        FixedTimespan('LMT', utcOffsetSeconds: 3164, dstOffsetSeconds: 0),
        [
          (
            -1_577_926_364,
            FixedTimespan('CET', utcOffsetSeconds: 3600, dstOffsetSeconds: 0),
          ),
          (
            -574_902_000,
            FixedTimespan(
              'CEST',
              utcOffsetSeconds: 3600,
              dstOffsetSeconds: 3600,
            ),
          ),
          (
            -568_087_200,
            FixedTimespan('CET', utcOffsetSeconds: 3600, dstOffsetSeconds: 0),
          ),
          (
            -512_175_600,
            FixedTimespan(
              'CEST',
              utcOffsetSeconds: 3600,
              dstOffsetSeconds: 3600,
            ),
          ),
          (
            -504_928_800,
            FixedTimespan('CET', utcOffsetSeconds: 3600, dstOffsetSeconds: 0),
          ),
          (
            -449_888_400,
            FixedTimespan(
              'CEST',
              utcOffsetSeconds: 3600,
              dstOffsetSeconds: 3600,
            ),
          ),
          (
            -441_856_800,
            FixedTimespan('CET', utcOffsetSeconds: 3600, dstOffsetSeconds: 0),
          ),
          (
            -347_158_800,
            FixedTimespan('EET', utcOffsetSeconds: 7200, dstOffsetSeconds: 0),
          ),
          (
            378_684_000,
            FixedTimespan('CET', utcOffsetSeconds: 3600, dstOffsetSeconds: 0),
          ),
          (
            386_463_600,
            FixedTimespan(
              'CEST',
              utcOffsetSeconds: 3600,
              dstOffsetSeconds: 3600,
            ),
          ),
          (
            402_271_200,
            FixedTimespan('CET', utcOffsetSeconds: 3600, dstOffsetSeconds: 0),
          ),
          (
            417_999_600,
            FixedTimespan(
              'CEST',
              utcOffsetSeconds: 3600,
              dstOffsetSeconds: 3600,
            ),
          ),
          (
            433_807_200,
            FixedTimespan('CET', utcOffsetSeconds: 3600, dstOffsetSeconds: 0),
          ),
          (
            449_622_000,
            FixedTimespan(
              'CEST',
              utcOffsetSeconds: 3600,
              dstOffsetSeconds: 3600,
            ),
          ),
          (
            465_429_600,
            FixedTimespan('CET', utcOffsetSeconds: 3600, dstOffsetSeconds: 0),
          ),
          (
            481_590_000,
            FixedTimespan(
              'CEST',
              utcOffsetSeconds: 3600,
              dstOffsetSeconds: 3600,
            ),
          ),
          (
            496_965_600,
            FixedTimespan('CET', utcOffsetSeconds: 3600, dstOffsetSeconds: 0),
          ),
          (
            512_953_200,
            FixedTimespan(
              'CEST',
              utcOffsetSeconds: 3600,
              dstOffsetSeconds: 3600,
            ),
          ),
          (
            528_674_400,
            FixedTimespan('CET', utcOffsetSeconds: 3600, dstOffsetSeconds: 0),
          ),
          (
            544_230_000,
            FixedTimespan(
              'CEST',
              utcOffsetSeconds: 3600,
              dstOffsetSeconds: 3600,
            ),
          ),
          (
            560_037_600,
            FixedTimespan('CET', utcOffsetSeconds: 3600, dstOffsetSeconds: 0),
          ),
          (
            575_852_400,
            FixedTimespan(
              'CEST',
              utcOffsetSeconds: 3600,
              dstOffsetSeconds: 3600,
            ),
          ),
          (
            591_660_000,
            FixedTimespan('CET', utcOffsetSeconds: 3600, dstOffsetSeconds: 0),
          ),
          (
            607_388_400,
            FixedTimespan(
              'CEST',
              utcOffsetSeconds: 3600,
              dstOffsetSeconds: 3600,
            ),
          ),
          (
            623_196_000,
            FixedTimespan('CET', utcOffsetSeconds: 3600, dstOffsetSeconds: 0),
          ),
          (
            641_775_600,
            FixedTimespan('EET', utcOffsetSeconds: 7200, dstOffsetSeconds: 0),
          ),
          (
            844_034_400,
            FixedTimespan('CET', utcOffsetSeconds: 3600, dstOffsetSeconds: 0),
          ),
          (
            860_108_400,
            FixedTimespan(
              'CEST',
              utcOffsetSeconds: 3600,
              dstOffsetSeconds: 3600,
            ),
          ),
          (
            875_916_000,
            FixedTimespan('EET', utcOffsetSeconds: 7200, dstOffsetSeconds: 0),
          ),
          (
            1_352_505_600,
            FixedTimespan('CET', utcOffsetSeconds: 3600, dstOffsetSeconds: 0),
          ),
          (
            1_364_515_200,
            FixedTimespan(
              'CEST',
              utcOffsetSeconds: 3600,
              dstOffsetSeconds: 3600,
            ),
          ),
          (
            1_382_659_200,
            FixedTimespan('EET', utcOffsetSeconds: 7200, dstOffsetSeconds: 0),
          ),
        ],
      ),
    );
  });

  test('Asia/Dushanbe', () {
    const zoneInfo = '''
Zone    Asia/Dushanbe   4:35:12 -   LMT 1924 May  2
            5:00    1:00    +05/+06 1991 Sep  9  2:00s
    ''';

    final tableBuilder = TableBuilder();
    for (final line in zoneInfo.split('\n')) {
      tableBuilder.add(LineParser.parse(line).unwrap());
    }
    final table = tableBuilder.build();
    expect(table.timespans('Asia/Dushanbe'), isNotNull);
  });

  test('optimize Antarctica/Macquarie', () {
    const transitions = FixedTimespanSet(
      FixedTimespan('zzz', utcOffsetSeconds: 0, dstOffsetSeconds: 0),
      [
        (
          -2_214_259_200,
          FixedTimespan('AEST', utcOffsetSeconds: 36000, dstOffsetSeconds: 0),
        ),
        (
          -1_680_508_800,
          FixedTimespan(
            'AEDT',
            utcOffsetSeconds: 36000,
            dstOffsetSeconds: 3600,
          ),
        ),
        (
          -1_669_892_400,
          FixedTimespan(
            'AEDT',
            utcOffsetSeconds: 36000,
            dstOffsetSeconds: 3600,
          ),
        ), // gets removed
        (
          -1_665_392_400,
          FixedTimespan('AEST', utcOffsetSeconds: 36000, dstOffsetSeconds: 0),
        ),
        (
          -1_601_719_200,
          FixedTimespan('zzz', utcOffsetSeconds: 0, dstOffsetSeconds: 0),
        ),
        (
          -687_052_800,
          FixedTimespan('AEST', utcOffsetSeconds: 36000, dstOffsetSeconds: 0),
        ),
        (
          -94_730_400,
          FixedTimespan('AEST', utcOffsetSeconds: 36000, dstOffsetSeconds: 0),
        ), // also gets removed
        (
          -71_136_000,
          FixedTimespan(
            'AEDT',
            utcOffsetSeconds: 36000,
            dstOffsetSeconds: 3600,
          ),
        ),
        (
          -55_411_200,
          FixedTimespan('AEST', utcOffsetSeconds: 36000, dstOffsetSeconds: 0),
        ),
        (
          -37_267_200,
          FixedTimespan(
            'AEDT',
            utcOffsetSeconds: 36000,
            dstOffsetSeconds: 3600,
          ),
        ),
        (
          -25_776_000,
          FixedTimespan('AEST', utcOffsetSeconds: 36000, dstOffsetSeconds: 0),
        ),
        (
          -5_817_600,
          FixedTimespan(
            'AEDT',
            utcOffsetSeconds: 36000,
            dstOffsetSeconds: 3600,
          ),
        ),
      ],
    );

    final optimized = transitions.optimize();

    final result = FixedTimespanSet(
      transitions.first,
      List.of(transitions.rest),
    );
    result.rest.removeAt(6);
    result.rest.removeAt(2);

    expect(optimized, result);
  });
}
