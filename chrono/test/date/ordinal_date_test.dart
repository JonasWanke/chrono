import 'package:chrono/chrono.dart';
import 'package:glados/glados.dart';

import '../utils.dart';

void main() {
  setChronoGladosDefaults();

  testDataClassBasics(const OrdinalDateAsIsoStringJsonConverter());

  Glados<OrdinalDate>().test('asDate', (ordinalDate) {
    expect(ordinalDate.asDate.asOrdinalDate, ordinalDate);
  });
  Glados<OrdinalDate>().test('asWeekDate', (ordinalDate) {
    expect(ordinalDate.asWeekDate.asOrdinalDate, ordinalDate);
  });

  // Arithmetic with `MonthsDuration` isn't always round-trippable.
  Glados2<OrdinalDate, FixedDaysDuration>().test('+ and -', (date, duration) {
    expect(date + duration - duration, date);
  });
  Glados<OrdinalDate>().test('next and previous', (ordinalDate) {
    expect(ordinalDate.next.previous, ordinalDate);
  });
}
