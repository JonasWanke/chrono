import 'package:chrono/chrono.dart';
import 'package:chrono_timezone/chrono_timezone.dart';
import 'package:deranged/deranged.dart';
import 'package:meta/meta.dart';
import 'package:test/test.dart';

void main() {
  test('London to Berlin', () {
    final dt = Tz.europe_london
        .with_ymd_and_hms(2016, 10, 8, 17, 0, 0)
        .unwrap();
    final converted = dt.withTimezone(Tz.europe_berlin);
    final expected = Tz.europe_berlin
        .with_ymd_and_hms(2016, 10, 8, 18, 0, 0)
        .unwrap();
    expect(converted, expected);
  });

  test('us_eastern_dst_commutativity', () {
    final dt = Tz.utc.with_ymd_and_hms(2002, 4, 7, 7, 0, 0).unwrap();
    for (final days in const IntRange(-420, 719)) {
      final dt1 = (dt + TimeDelta(normalDays: days)).withTimezone(
        Tz.us_eastern,
      );
      final dt2 = dt.withTimezone(Tz.us_eastern) + TimeDelta(normalDays: days);
      expect(dt1, dt2);
    }
  });

  test('addition across DST boundary', () {
    final twoHours = TimeDelta(hours: 2);
    final edt = Tz.us_eastern.with_ymd_and_hms(2019, 11, 3, 0, 0, 0).unwrap();
    final est = edt + twoHours;

    expect(edt.toString(), '2019-11-03T00:00:00 EDT');
    expect(est.toString(), '2019-11-03T01:00:00 EST');
    expect(est.durationSinceUnixEpoch, edt.durationSinceUnixEpoch + twoHours);
  });

  test('Warsaw time zone name', () {
    final dt = Tz.utc.with_ymd_and_hms(1915, 8, 4, 22, 35, 59).unwrap();
    expect(abbreviationOf(dt.withTimezone(Tz.europe_warsaw)), 'WMT');
    final later = dt + TimeDelta(seconds: 1);
    expect(abbreviationOf(later.withTimezone(Tz.europe_warsaw)), 'CET');
  });

  test('Vilnius UTC offset', () {
    final dt0 = Tz.utc
        .with_ymd_and_hms(1916, 12, 31, 22, 35, 59)
        .unwrap()
        .withTimezone(Tz.europe_vilnius);
    expect(
      dt0,
      Tz.europe_vilnius.with_ymd_and_hms(1916, 12, 31, 23, 59, 59).unwrap(),
    );
    final dt1 = dt0 + TimeDelta(seconds: 1);
    expect(
      dt1,
      Tz.europe_vilnius.with_ymd_and_hms(1917, 1, 1, 0, 11, 36).unwrap(),
    );
  });

  test('Victorian times', () {
    final dt = Tz.utc
        .with_ymd_and_hms(1847, 12, 1, 0, 1, 14)
        .unwrap()
        .withTimezone(Tz.europe_london);
    expect(
      dt,
      Tz.europe_london.with_ymd_and_hms(1847, 11, 30, 23, 59, 59).unwrap(),
    );
    expect(
      dt + TimeDelta(seconds: 1),
      Tz.europe_london.with_ymd_and_hms(1847, 12, 1, 0, 1, 15).unwrap(),
    );
  });

  group('adding Days', () {
    test('keeps wall-clock time across DST', () {
      final dt = Tz.europe_berlin.with_ymd_and_hms(2024, 3, 30, 12, 0, 0);
      expect(
        dt.unwrap() + const Days(1),
        Tz.europe_berlin.with_ymd_and_hms(2024, 3, 31, 12, 0, 0).unwrap(),
      );
      expect(
        dt.unwrap() + TimeDelta(hours: 24),
        Tz.europe_berlin.with_ymd_and_hms(2024, 3, 31, 13, 0, 0).unwrap(),
      );
    });

    test('into a gap shifts forward', () {
      final dt = Tz.europe_london.with_ymd_and_hms(2024, 3, 30, 1, 30, 0);
      expect(
        dt.unwrap() + const Days(1),
        Tz.europe_london.with_ymd_and_hms(2024, 3, 31, 2, 30, 0).unwrap(),
      );
    });

    test('checkedAdd reports gaps and folds', () {
      final beforeGap = Tz.europe_london
          .with_ymd_and_hms(2024, 3, 30, 1, 30, 0)
          .unwrap();
      expect(beforeGap.checkedAdd(const Days(1)), isA<MappedLocalTime_None>());

      final beforeFold = Tz.europe_london
          .with_ymd_and_hms(2024, 10, 26, 1, 30, 0)
          .unwrap();
      expect(
        beforeFold.checkedAdd(const Days(1)),
        Tz.europe_london.with_ymd_and_hms(2024, 10, 27, 1, 30, 0),
      );

      final ordinary = Tz.europe_berlin
          .with_ymd_and_hms(2024, 3, 30, 12, 0, 0)
          .unwrap();
      final delta = DateTimeDelta(
        days: const Days(1),
        time: TimeDelta(hours: 1),
      );
      expect(ordinary.checkedAdd(delta).single, ordinary + delta);
    });

    test('checkedSubtract reports gaps and folds', () {
      final afterGap = Tz.europe_london
          .with_ymd_and_hms(2024, 4, 1, 1, 30, 0)
          .unwrap();
      expect(
        afterGap.checkedSubtract(const Days(1)),
        Tz.europe_london.with_ymd_and_hms(2024, 3, 31, 1, 30, 0),
      );
      expect(
        afterGap.checkedSubtract(const Days(1)),
        isA<MappedLocalTime_None>(),
      );

      final afterFold = Tz.europe_london
          .with_ymd_and_hms(2024, 10, 28, 1, 30, 0)
          .unwrap();
      expect(
        afterFold.checkedSubtract(const Days(1)),
        isA<MappedLocalTime_Ambiguous>(),
      );
    });

    test('into a fold keeps offset, else earliest', () {
      final earliest = Tz.europe_london
          .with_ymd_and_hms(2024, 10, 26, 1, 30, 0)
          .unwrap();
      final result = earliest + const Days(1);
      expect(result.localDateTime, CDateTime.fromRaw(2024, 10, 27, 1, 30));
      expect(
        result,
        Tz.europe_london.with_ymd_and_hms(2024, 10, 27, 1, 30, 0).earliest,
      );

      final latest = Tz.europe_london
          .with_ymd_and_hms(2024, 10, 27, 1, 30, 0)
          .latest!;
      expect(
        (latest + Days.week).localDateTime.date,
        Date.fromRaw(2024, 11, 3),
      );
      expect(
        (latest - Days.week).offset.fix(),
        FixedOffset.east(TimeDelta(hours: 1)),
      );
    });
  });

  test('London DST', () {
    final dt = Tz.europe_london.with_ymd_and_hms(2016, 3, 10, 5, 0, 0).unwrap();
    final later = dt + TimeDelta(normalDays: 180);
    final expected = Tz.europe_london
        .with_ymd_and_hms(2016, 9, 6, 6, 0, 0)
        .unwrap();
    expect(later, expected);
  });

  test('international date line change', () {
    final dt = Tz.utc
        .with_ymd_and_hms(2011, 12, 30, 9, 59, 59)
        .unwrap()
        .withTimezone(Tz.pacific_apia);
    expect(
      dt,
      Tz.pacific_apia.with_ymd_and_hms(2011, 12, 29, 23, 59, 59).unwrap(),
    );
    expect(
      dt + TimeDelta(seconds: 1),
      Tz.pacific_apia.with_ymd_and_hms(2011, 12, 31, 0, 0, 0).unwrap(),
    );
  });

  test('negative offset with minutes and seconds', () {
    final dt = Tz.utc
        .with_ymd_and_hms(1900, 1, 1, 12, 0, 0)
        .unwrap()
        .withTimezone(Tz.america_danmarkshavn);
    expect(
      dt,
      Tz.america_danmarkshavn.with_ymd_and_hms(1900, 1, 1, 10, 45, 20).unwrap(),
    );
  });

  test('monotonicity', () {
    var dt = Tz.pacific_noumea.with_ymd_and_hms(1800, 1, 1, 12, 0, 0).unwrap();
    for (var i = 0; i < 24 * 356 * 400; i++) {
      final next = dt + TimeDelta(hours: 1);
      expect(next.utcDateTime > dt.utcDateTime, isTrue, reason: '$dt');
      dt = next;
    }
  });

  group('inverse', () {
    @isTest
    void testInverse(String description, Tz tz, int begin, int end) {
      test(description, () {
        for (var year = begin; year < end; year++) {
          for (var dayOfYear = 1; dayOfYear < 366; dayOfYear++) {
            final date = Date.fromYearAndOrdinal(Year(year), dayOfYear);
            for (var hour = 0; hour < 24; hour++) {
              for (var minute = 0; minute < 60; minute++) {
                final dt = date.at(Time.from(hour, minute)).andUtc();
                final back = dt.withTimezone(tz).withTimezone(Tz.utc);
                expect(back.utcDateTime, dt.utcDateTime, reason: '$tz $dt');
              }
            }
          }
        }
      });
    }

    testInverse('London', Tz.europe_london, 1989, 1994);
    testInverse('Dhaka', Tz.asia_dhaka, 1995, 2000);
    testInverse('Apia', Tz.pacific_apia, 2011, 2012);
    testInverse('Tahiti', Tz.pacific_tahiti, 1911, 1914);
  });

  test('string representation', () {
    final dt = Tz.utc
        .with_ymd_and_hms(2000, 9, 1, 12, 30, 15)
        .unwrap()
        .withTimezone(Tz.australia_adelaide);
    expect(dt.toString(), '2000-09-01T22:00:15 ACST');
    expect(
      dt.toString(ZonedDateTime.rfc3339Format()),
      '2000-09-01T22:00:15+09:30',
    );
  });

  test('Tahiti', () {
    final dt = Tz.utc
        .with_ymd_and_hms(1912, 10, 1, 9, 58, 16)
        .unwrap()
        .withTimezone(Tz.pacific_tahiti);
    expect(
      dt - TimeDelta(hours: 1),
      Tz.pacific_tahiti.with_ymd_and_hms(1912, 9, 30, 23, 0, 0).unwrap(),
    );
    expect(
      dt + TimeDelta(hours: 1),
      Tz.pacific_tahiti.with_ymd_and_hms(1912, 10, 1, 0, 58, 16).unwrap(),
    );
  });

  test('Non-existent time', () {
    expect(
      Tz.europe_london.with_ymd_and_hms(2016, 3, 27, 1, 30, 0).single,
      null,
    );
  });

  test('Non-existent time_2', () {
    expect(
      Tz.europe_london.with_ymd_and_hms(2016, 3, 27, 1, 0, 0).single,
      null,
    );
  });

  test('time_exists', () {
    expect(
      Tz.europe_london.with_ymd_and_hms(2016, 3, 27, 2, 0, 0).single,
      isNotNull,
    );
  });

  test('ambiguous_time', () {
    final ambiguous = Tz.europe_london.with_ymd_and_hms(2016, 10, 30, 1, 0, 0);
    final earliestUtc = CDateTime.fromRaw(2016, 10, 30);
    expect(ambiguous.earliest!, Tz.europe_london.fromUtcDateTime(earliestUtc));
    final latestUtc = CDateTime.fromRaw(2016, 10, 30, 1);
    expect(ambiguous.latest!, Tz.europe_london.fromUtcDateTime(latestUtc));
  });

  test('ambiguous_time_2', () {
    final ambiguous = Tz.europe_london.with_ymd_and_hms(2016, 10, 30, 1, 30, 0);
    final earliestUtc = CDateTime.fromRaw(2016, 10, 30, 0, 30);
    expect(ambiguous.earliest!, Tz.europe_london.fromUtcDateTime(earliestUtc));
    final latestUtc = CDateTime.fromRaw(2016, 10, 30, 1, 30);
    expect(ambiguous.latest!, Tz.europe_london.fromUtcDateTime(latestUtc));
  });

  test('ambiguous_time_3', () {
    final ambiguous = Tz.europe_moscow.with_ymd_and_hms(2014, 10, 26, 1, 30, 0);
    final earliestUtc = CDateTime.fromRaw(2014, 10, 25, 21, 30);
    expect(
      ambiguous.earliest!.toFixedOffset(),
      Tz.europe_moscow.fromUtcDateTime(earliestUtc).toFixedOffset(),
    );
    final latestUtc = CDateTime.fromRaw(2014, 10, 25, 22, 30);
    expect(ambiguous.latest!, Tz.europe_moscow.fromUtcDateTime(latestUtc));
  });

  test('ambiguous_time_4', () {
    final ambiguous = Tz.europe_moscow.with_ymd_and_hms(2014, 10, 26, 1, 0, 0);
    final earliestUtc = CDateTime.fromRaw(2014, 10, 25, 21);
    expect(
      ambiguous.earliest!.toFixedOffset(),
      Tz.europe_moscow.fromUtcDateTime(earliestUtc).toFixedOffset(),
    );
    final latestUtc = CDateTime.fromRaw(2014, 10, 25, 22);
    expect(ambiguous.latest!, Tz.europe_moscow.fromUtcDateTime(latestUtc));
  });

  test('unambiguous_time', () {
    expect(
      Tz.europe_london.with_ymd_and_hms(2016, 10, 30, 2, 0, 0).single,
      isNotNull,
    );
  });

  test('unambiguous_time_2', () {
    expect(
      Tz.europe_moscow.with_ymd_and_hms(2014, 10, 26, 2, 0, 0).single,
      isNotNull,
    );
  });

  test('tzId', () {
    expect(Tz.europe_london.tzId, 'Europe/London');
    expect(Tz.africa_abidjan.tzId, 'Africa/Abidjan');
    expect(Tz.utc.tzId, 'UTC');
    expect(Tz.zulu.tzId, 'Zulu');
  });

  test('toString()', () {
    expect(Tz.europe_london.toString(), 'Europe/London');
    expect(Tz.africa_abidjan.toString(), 'Africa/Abidjan');
    expect(Tz.utc.toString(), 'UTC');
    expect(Tz.zulu.toString(), 'Zulu');
  });

  test('test_iana_tzdb_version', () {
    // Format should be something like 2023c.
    expect(ianaTzdbVersion.length, 5);
    final numbers = RegExp(r'\d').allMatches(ianaTzdbVersion);
    expect(numbers, hasLength(4));
    expect(
      ianaTzdbVersion.substring(ianaTzdbVersion.length - 1),
      matches('[a-z]'),
    );
  });

  group('numeric names', () {
    test('Scoresbysund', () {
      final dt = Tz.america_scoresbysund
          .with_ymd_and_hms(2024, 5, 1, 0, 0, 0)
          .unwrap();
      expect(dt.offset.toString(), '-01');
    });
    test('Casey', () {
      final dt = Tz.antarctica_casey
          .with_ymd_and_hms(2022, 11, 1, 0, 0, 0)
          .unwrap();
      expect(dt.offset.toString(), '+11');
    });
    test('Addis Ababa', () {
      final dt = Tz.africa_addisAbaba
          .with_ymd_and_hms(1937, 2, 1, 0, 0, 0)
          .unwrap();
      expect(dt.offset.toString(), '+0245');
    });
  });

  group('Gap info', () {
    @isTest
    void testGapInfo(
      String description,
      Tz tz,
      CDateTime gapBegin,
      CDateTime gapEnd,
    ) {
      test(description, () {
        final before = gapBegin - TimeDelta(seconds: 1);
        final beforeOffset = tz.offsetFromLocalDateTime(before).single!;

        final gapEndZdt = tz.fromLocalDateTime(gapEnd).single!;

        final inGap = gapBegin + TimeDelta(seconds: 1);
        final gapInfo = GapInfo.of(inGap, tz)!;
        expect(gapInfo, GapInfo((gapBegin, beforeOffset), gapEndZdt));
      });
    }

    testGapInfo(
      'Europe/London',
      Tz.europe_london,
      CDateTime.fromRaw(2024, 3, 31, 1),
      CDateTime.fromRaw(2024, 3, 31, 2),
    );
    testGapInfo(
      'Europe/Dublin',
      Tz.europe_dublin,
      CDateTime.fromRaw(2024, 3, 31, 1),
      CDateTime.fromRaw(2024, 3, 31, 2),
    );
    testGapInfo(
      'Australia/Adelaide',
      Tz.australia_adelaide,
      CDateTime.fromRaw(2024, 10, 6, 2),
      CDateTime.fromRaw(2024, 10, 6, 3),
    );
    testGapInfo(
      'Samoa skips a day',
      Tz.pacific_apia,
      CDateTime.fromRaw(2011, 12, 30),
      CDateTime.fromRaw(2011, 12, 31),
    );
    testGapInfo(
      'Libya 2013',
      Tz.libya,
      CDateTime.fromRaw(2013, 3, 29, 1),
      CDateTime.fromRaw(2013, 3, 29, 2),
    );
  });

  test('Casey UTC change time', () {
    expect(
      CDateTime.fromRaw(
        2012,
        2,
        21,
        16,
        59,
        59,
      ).andUtc().withTimezone(Tz.antarctica_casey).offset.toString(),
      '+11',
    );

    expect(
      CDateTime.fromRaw(
        2012,
        2,
        21,
        17,
      ).andUtc().withTimezone(Tz.antarctica_casey).offset.toString(),
      '+08',
    );
  });
}

String abbreviationOf(ZonedDateTime<Tz> dateTime) =>
    (dateTime.offset as TzOffset).abbreviation;
