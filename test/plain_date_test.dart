import 'package:glados/glados.dart';
import 'package:plain_date_time/plain_date_time.dart';

void main() {
  setPlainDateTimeGladosDefaults();

  Glados<PlainYear>().test('PlainYear', (year) {
    expect(year, PlainYear.fromJson(year.toJson()));
  });
  Glados<PlainMonth>().test('PlainMonth', (month) {
    expect(month, PlainMonth.fromJson(month.toJson()));
  });
  Glados<PlainYearMonth>().test('PlainYearMonth', (yearMonth) {
    expect(yearMonth, PlainYearMonth.fromJson(yearMonth.toJson()));
  });
  Glados<PlainYearWeek>().test('PlainYearWeek', (yearWeek) {
    expect(yearWeek, PlainYearWeek.fromJson(yearWeek.toJson()));
  });
  Glados<PlainDate>().test('PlainDate', (date) {
    expect(date, PlainDate.fromJson(date.toJson()));
    expect(date, PlainDate.fromDaysSinceUnixEpoch(date.daysSinceUnixEpoch));
  });
  Glados<PlainTime>().test('PlainTime', (timet) {
    expect(timet, PlainTime.fromJson(timet.toJson()));
  });
  Glados<PlainDateTime>().test('PlainDateTime', (dateTime) {
    expect(dateTime, PlainDateTime.fromJson(dateTime.toJson()));
  });
  Glados<Instant>().test('Instant', (instant) {
    expect(instant, Instant.fromJson(instant.toJson()));
    expect(instant, instant.plainDateTimeInLocalZone.inLocalZone);
    expect(instant, instant.plainDateTimeInUtc.inUtc);
  });
  Glados<Weekday>().test('Weekday', (weekday) {
    expect(weekday, Weekday.fromJson(weekday.toJson()));
  });
  Glados<PlainOrdinalDate>().test('PlainOrdinalDate', (weekDate) {
    expect(weekDate, PlainOrdinalDate.fromJson(weekDate.toJson()));
  });
  Glados<PlainWeekDate>().test('PlainWeekDate', (weekDate) {
    expect(weekDate, PlainWeekDate.fromJson(weekDate.toJson()));
  });
  Glados<DateTime>().test('DateTime compatibility', (dateTimeInLocalZone) {
    expect(
      dateTimeInLocalZone,
      Instant.fromDateTime(dateTimeInLocalZone).dateTimeInLocalZone,
    );
    expect(
      dateTimeInLocalZone,
      PlainDateTime.fromDateTime(dateTimeInLocalZone).dateTimeInLocalZone,
    );

    final dateTimeInUtc = dateTimeInLocalZone.toUtc();
    expect(dateTimeInUtc, Instant.fromDateTime(dateTimeInUtc).dateTimeInUtc);
    expect(
      dateTimeInUtc,
      PlainDateTime.fromDateTime(dateTimeInUtc).dateTimeInUtc,
    );
  });
}
