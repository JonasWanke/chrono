import 'package:chrono/chrono.dart';
import 'package:glados/glados.dart';

import '../utils.dart';

void main() {
  setChronoGladosDefaults();

  testDataClassBasics(OrdinalDate.fromJson);

  Glados<OrdinalDate>().test('asDate', (ordinalDate) {
    expect(ordinalDate.asDate.asOrdinalDate, ordinalDate);
  });
  Glados<OrdinalDate>().test('asWeekDate', (ordinalDate) {
    expect(ordinalDate.asWeekDate.asOrdinalDate, ordinalDate);
  });

  Glados2<OrdinalDate, DaysDuration>().test('+ and -', (ordinalDate, duration) {
    expect(ordinalDate + duration - duration, ordinalDate);
  });
  Glados<OrdinalDate>().test('next and previous', (ordinalDate) {
    expect(ordinalDate.next.previous, ordinalDate);
  });
}
