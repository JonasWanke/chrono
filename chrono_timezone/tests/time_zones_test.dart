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
      final dt1 = (dt + Days(days)).withTimezone(Tz.us_eastern);
      final dt2 = dt.withTimezone(Tz.us_eastern) + Days(days);
      expect(dt1, dt2);
    }
  });

  // test('test_addition_across_dst_boundary', () {
  //     use chrono::TimeZone;
  //     final two_hours = Duration::hours(2);
  //     final edt = Eastern.with_ymd_and_hms(2019, 11, 3, 0, 0, 0).unwrap();
  //     final est = edt + two_hours;

  //     expect(edt.to_string(), "2019-11-03 00:00:00 EDT".to_string());
  //     expect(est.to_string(), "2019-11-03 01:00:00 EST".to_string());
  //     expect(est.timestamp(), edt.timestamp() + two_hours.num_seconds());
  // });

  // test('warsaw_tz_name', () {
  //     final dt = UTC.with_ymd_and_hms(1915, 8, 4, 22, 35, 59).unwrap();
  //     expect(dt.withTimezone(&Warsaw).format("%Z").to_string(), "WMT");
  //     final dt = dt + Duration::seconds(1);
  //     expect(dt.withTimezone(&Warsaw).format("%Z").to_string(), "CET");
  // });

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

  // test('victorian_times', () {
  //     final dt = UTC
  //         .with_ymd_and_hms(1847, 12, 1, 0, 1, 14)
  //         .unwrap()
  //         .withTimezone(&London);
  //     expect(
  //         dt,
  //         Tz.europe_london.with_ymd_and_hms(1847, 11, 30, 23, 59, 59).unwrap()
  //     );
  //     final dt = dt + Duration::seconds(1);
  //     expect(dt, Tz.europe_london.with_ymd_and_hms(1847, 12, 1, 0, 1, 15).unwrap());
  // });

  test('London DST', () {
    final dt = Tz.europe_london.with_ymd_and_hms(2016, 3, 10, 5, 0, 0).unwrap();
    final later = dt + const Days(180);
    final expected = Tz.europe_london
        .with_ymd_and_hms(2016, 9, 6, 6, 0, 0)
        .unwrap();
    expect(later, expected);
  });

  // test('international_date_line_change', () {
  //     final dt = UTC
  //         .with_ymd_and_hms(2011, 12, 30, 9, 59, 59)
  //         .unwrap()
  //         .withTimezone(&Apia);
  //     expect(dt, Apia.with_ymd_and_hms(2011, 12, 29, 23, 59, 59).unwrap());
  //     final dt = dt + Duration::seconds(1);
  //     expect(dt, Apia.with_ymd_and_hms(2011, 12, 31, 0, 0, 0).unwrap());
  // });

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

  // test('monotonicity', () {
  //     final mut dt = Noumea.with_ymd_and_hms(1800, 1, 1, 12, 0, 0).unwrap();
  //     for _ in 0..24 * 356 * 400 {
  //         final new = dt + Duration::hours(1);
  //         assert!(new > dt);
  //         assert!(new.withTimezone(&UTC) > dt.withTimezone(&UTC));
  //         dt = new;
  //     }
  // }

  // test('test_inverse', <T: TimeZone>(tz: T, begin: i32, end: i32) {
  //     for y in begin..end {
  //         for d in 1..366 {
  //             final date = NaiveDate::from_yo_opt(y, d).unwrap();
  //             for h in 0..24 {
  //                 for m in 0..60 {
  //                     final dt = date.and_hms_opt(h, m, 0).unwrap().and_utc();
  //                     final with_tz = dt.withTimezone(&tz);
  //                     final utc = with_tz.withTimezone(&UTC);
  //                     expect(dt, utc);
  //                 }
  //             }
  //         }
  //     }
  // });

  // test('inverse_london', () {
  //     test_inverse(London, 1989, 1994);
  // });

  // test('inverse_dhaka', () {
  //     test_inverse(Dhaka, 1995, 2000);
  // });

  // test('inverse_apia', () {
  //     test_inverse(Apia, 2011, 2012);
  // });

  // test('inverse_tahiti', () {
  //     test_inverse(Tahiti, 1911, 1914);
  // });

  // test('string_representation', () {
  //     final dt = UTC
  //         .with_ymd_and_hms(2000, 9, 1, 12, 30, 15)
  //         .unwrap()
  //         .withTimezone(&Adelaide);
  //     expect(dt.to_string(), "2000-09-01 22:00:15 ACST");
  //     expect(format!("{dt:?}"), "2000-09-01T22:00:15ACST");
  //     expect(dt.to_rfc3339(), "2000-09-01T22:00:15+09:30");
  //     expect(format!("{dt}"), "2000-09-01 22:00:15 ACST");
  // });

  // test('tahiti', () {
  //     final dt = UTC
  //         .with_ymd_and_hms(1912, 10, 1, 9, 58, 16)
  //         .unwrap()
  //         .withTimezone(&Tahiti);
  //     final before = dt - Duration::hours(1);
  //     expect(
  //         before,
  //         Tahiti.with_ymd_and_hms(1912, 9, 30, 23, 0, 0).unwrap()
  //     );
  //     final after = dt + Duration::hours(1);
  //     expect(
  //         after,
  //         Tahiti.with_ymd_and_hms(1912, 10, 1, 0, 58, 16).unwrap()
  //     );
  // });

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
    final earliestUtc = CDateTime.fromRaw(2014, 10, 25, 1, 30);
    expect(
      ambiguous.earliest!.toFixedOffset(),
      Tz.europe_moscow.fromUtcDateTime(earliestUtc).toFixedOffset(),
    );
    final latestUtc = CDateTime.fromRaw(2014, 10, 25, 2, 30);
    expect(ambiguous.latest!, Tz.europe_moscow.fromUtcDateTime(latestUtc));
  });

  test('ambiguous_time_4', () {
    final ambiguous = Tz.europe_moscow.with_ymd_and_hms(2014, 10, 26, 1, 0, 0);
    final earliestUtc = CDateTime.fromRaw(2014, 10, 25, 1);
    expect(
      ambiguous.earliest!.toFixedOffset(),
      Tz.europe_moscow.fromUtcDateTime(earliestUtc).toFixedOffset(),
    );
    final latestUtc = CDateTime.fromRaw(2014, 10, 25, 2);
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

  // test('test_get_name', () {
  //     expect(Tz.europe_london.name(), "Europe/London");
  //     expect(Tz::Africa__Abidjan.name(), "Africa/Abidjan");
  //     expect(Tz::UTC.name(), "UTC");
  //     expect(Tz::Zulu.name(), "Zulu");
  // });

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

  // test('test_numeric_names', () {
  //     final dt = Scoresbysund.with_ymd_and_hms(2024, 5, 1, 0, 0, 0).unwrap();
  //     expect(format!("{}", dt.offset()), "-01");
  //     expect(format!("{:?}", dt.offset()), "-01");
  //     final dt = Casey.with_ymd_and_hms(2022, 11, 1, 0, 0, 0).unwrap();
  //     expect(format!("{}", dt.offset()), "+11");
  //     expect(format!("{:?}", dt.offset()), "+11");
  //     final dt = Addis_Ababa.with_ymd_and_hms(1937, 2, 1, 0, 0, 0).unwrap();
  //     expect(format!("{}", dt.offset()), "+0245");
  //     expect(format!("{:?}", dt.offset()), "+0245");
  // }

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
