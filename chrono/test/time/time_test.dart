import 'package:chrono/chrono.dart';
import 'package:glados/glados.dart';

import '../utils.dart';

void main() {
  setChronoGladosDefaults();

  // ignore: missing-test-assertion
  testDataClassBasics(preciseCodecs: const [TimeAsStringCodec()]);

  Glados<Time>().test('fromTimeSinceMidnight', (time) {
    expect(Time.fromTimeSinceMidnight(time.timeSinceMidnight), time);
  });

  Glados2<Time, TimeDelta>().test('+, -, and difference(…)', (time, timeDelta) {
    final timePlusDuration = time.addChecked(timeDelta);
    if (timePlusDuration == null) return;

    expect(timePlusDuration - timeDelta, time);
    expect(timePlusDuration.difference(time), timeDelta);
  });

  group('overflowingAddOffset(…) and overflowingSubOffset(…)', () {
    final offset = FixedOffset.east(TimeDelta(hours: 1, minutes: 30));

    test('edge cases', () {
      expect(Time(0, 30).overflowingSubOffset(offset), (
        Time(23),
        const Days(-1),
      ));
      expect(Time(23).overflowingAddOffset(offset), (
        Time(0, 30),
        const Days(1),
      ));
      expect(Time(12).overflowingAddOffset(offset), (
        Time(13, 30),
        const Days(0),
      ));
      expect(
        Time(12).overflowingAddOffset(
          FixedOffset.west(TimeDelta(hours: 12, minutes: 30)),
        ),
        (Time(23, 30), const Days(-1)),
      );
      expect(
        Time(0, 30).overflowingAddOffset(FixedOffset.west(TimeDelta(hours: 1))),
        (Time(23, 30), const Days(-1)),
      );
    });
    test('with sub-second nanos', () {
      final nanosOffset = FixedOffset.east(
        TimeDelta(hours: 1, nanos: 600000000),
      );
      expect(Time(12, 0, 0, 700).overflowingAddOffset(nanosOffset), (
        Time(13, 0, 1, 300),
        const Days(0),
      ));
      expect(Time(0, 0, 0, 100).overflowingSubOffset(nanosOffset), (
        Time(22, 59, 59, 500),
        const Days(-1),
      ));
    });
    Glados2<Time, TimeDelta>().test('add and sub are inverse', (time, delta) {
      if (delta <= FixedOffset.minOffset || delta >= FixedOffset.maxOffset) {
        return;
      }
      final offset = FixedOffset.east(delta);
      final (added, addedDays) = time.overflowingAddOffset(offset);
      final (back, backDays) = added.overflowingSubOffset(offset);
      expect(back, time);
      expect(addedDays + backDays, const Days(0));
    });
  });
}
