import 'package:glados/glados.dart';
import 'package:plain_date_time/plain_date_time.dart';

void main() {
  setPlainDateTimeGladosDefaults();

  Glados<PlainYear>().test('PlainYear', (year) {
    expect(year, PlainYear.fromJson(year.toJson()));
  });
  // TODO: PlainMonth
  Glados<PlainYearMonth>().test('PlainYearMonth', (year) {
    expect(year, PlainYearMonth.fromJson(year.toJson()));
  });
  Glados<PlainDate>().test('PlainDate', (year) {
    expect(year, PlainDate.fromJson(year.toJson()));
  });
  Glados<PlainTime>().test('PlainTime', (year) {
    expect(year, PlainTime.fromJson(year.toJson()));
  });
  Glados<PlainDateTime>().test('PlainDateTime', (year) {
    expect(year, PlainDateTime.fromJson(year.toJson()));
  });
  Glados<Instant>().test('Instant', (year) {
    expect(year, Instant.fromJson(year.toJson()));
  });
}
