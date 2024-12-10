import 'package:chrono/chrono.dart';
import 'package:glados/glados.dart';

import '../../utils.dart';

void main() {
  setChronoGladosDefaults();

  testDataClassBasics(codecs: const [IsoYearWeekAsIsoStringCodec()]);

  Glados2<IsoYearWeek, Weeks>().test('+ and -', (yearWeek, duration) {
    expect(yearWeek + duration - duration, yearWeek);
  });
  Glados<IsoYearWeek>().test('next and previous', (yearWeek) {
    expect(yearWeek.next.previous, yearWeek);
  });
}
