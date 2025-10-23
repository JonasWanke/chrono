import 'package:meta/meta.dart';

import '../date_time/date_time.dart';
import 'fixed.dart';
import 'time_zone.dart';

/// The UTC (Coordinated Universal Time) time zone.
///
/// This is the most efficient time zone when you don't need the local time. It
/// is also used as an offset (which is also a dummy type).
///
/// Using the [TimeZone] methods on [utc] is the preferred way to construct
/// `ZonedDateTime<Utc>` instances.
@immutable
class Utc extends TimeZone<Utc> implements Offset<Utc> {
  const Utc();


  @override
  Utc get timeZone => this;

  @override
  MappedLocalTime<Utc> offsetFromLocalDateTime(CDateTime local) =>
      MappedLocalTime_Single(this);

  @override
  Utc offsetFromUtcDateTime(CDateTime utc) => this;

  @override
  // ignore: unused_result
  FixedOffset fix() => const FixedOffset.east(0);

  @override
  bool operator ==(Object other) => other is Utc;
  @override
  int get hashCode => 0;

  @override
  String toString() => 'UTC';
}

// TODO(JonasWanke): remove?
const utc = Utc();
