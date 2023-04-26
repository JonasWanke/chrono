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
  Glados<PlainDate>().test('PlainDate', (date) {
    expect(date, PlainDate.fromJson(date.toJson()));
  });
  Glados<PlainTime>().test('PlainTime', (timet) {
    expect(timet, PlainTime.fromJson(timet.toJson()));
  });
  Glados<PlainDateTime>().test('PlainDateTime', (dateTime) {
    expect(dateTime, PlainDateTime.fromJson(dateTime.toJson()));
  });
  Glados<Instant>().test('Instant', (instant) {
    expect(instant, Instant.fromJson(instant.toJson()));
  });
}
