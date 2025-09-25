import 'package:chrono/chrono.dart';
import 'package:meta/meta.dart';

import '../chrono_timezone.dart';

/// An [Offset] that applies for a period of time.
///
/// For example, [Tz.US__Eastern] is composed of at least two
/// [FixedTimespan]s: `EST` and `EDT`, that are variously in effect.
@immutable
class FixedTimespan {
  const FixedTimespan(this.name, {required this.offsetSeconds});

  /// The name of this timezone, for example, the difference between `EDT`/`EST`
  final String name;

  /// The base offset from UTC; this usually doesn't change unless the
  /// government changes something.
  final int offsetSeconds;

  @override
  bool operator ==(Object other) =>
      other is FixedTimespan &&
      other.name == name &&
      other.offsetSeconds == offsetSeconds;
  @override
  int get hashCode => Object.hash(name, offsetSeconds);

  @override
  String toString() => name;
}

@immutable
class TzOffset implements Offset, OffsetName {
  const TzOffset(this.tz, this.offset);

  final Tz tz;
  final FixedTimespan offset;

  @override
  String get tzId => tz.name;
  @override
  String get abbreviation => offset.name;

  static MappedLocalTime<TzOffset> mapMappedLocalTime(
    Tz tz,
    MappedLocalTime<FixedTimespan> result,
  ) {
    return switch (result) {
      MappedLocalTime_None() => const MappedLocalTime_None(),
      MappedLocalTime_Single(:final value) => MappedLocalTime_Single(
        TzOffset(tz, value),
      ),
      MappedLocalTime_Ambiguous(:final earliest, :final latest) =>
        MappedLocalTime_Ambiguous(TzOffset(tz, earliest), TzOffset(tz, latest)),
    };
  }

  @override
  // ignore: unused_result
  FixedOffset fix() => FixedOffset.east(offset.offsetSeconds);

  @override
  bool operator ==(Object other) =>
      other is TzOffset && other.tz == tz && other.offset == offset;
  @override
  int get hashCode => Object.hash(tz, offset);

  @override
  String toString() => offset.toString();
}

/// Timezone offset name information.
///
/// This interface exposes display names that describe an offset in various
/// situations.
///
// TODO(JonasWanke): migrate to Dart
/// ```rust
/// # extern crate chrono;
/// # extern crate chrono_tz;
/// use chrono::{Duration, Offset, TimeZone};
/// use chrono_tz::Europe::London;
/// use chrono_tz::OffsetName;
///
/// # fn main() {
/// let london_time = London.ymd(2016, 2, 10).and_hms(12, 0, 0);
/// assert_eq!(london_time.offset().tz_id(), "Europe/London");
/// // London is normally on GMT
/// assert_eq!(london_time.offset().abbreviation(), "GMT");
///
/// let london_summer_time = London.ymd(2016, 5, 10).and_hms(12, 0, 0);
/// // The TZ ID remains constant year round
/// assert_eq!(london_summer_time.offset().tz_id(), "Europe/London");
/// // During the summer, this becomes British Summer Time
/// assert_eq!(london_summer_time.offset().abbreviation(), "BST");
/// # }
/// ```
abstract interface class OffsetName {
  /// The IANA TZDB identifier (e.g., "America/New_York").
  String get tzId;

  /// The abbreviation to use in a longer timestamp (e.g., "EST").
  ///
  /// This takes into account any special offsets that may be in effect. For
  /// example, at a given instant, the time zone with ID *America/New_York* may
  /// be either *EST* or *EDT*.
  String get abbreviation;
}

/// Represents the span of time that a given rule is valid for.
///
/// From Rust's chrono-tz:
///
/// > Note that I have made the assumption that all ranges are left-inclusive
/// > and right-exclusive – that is to say, if the clocks go forward by 1 hour
/// > at 1am, the time 1am does not exist in local time (the clock goes from
/// > 00:59:59 to 02:00:00). Likewise, if the clocks go back by one hour at 2am,
/// > the clock goes from 01:59:59 to 01:00:00. This is an arbitrary choice, and
/// > I could not find a source to confirm whether or not this is correct.
@immutable
class Span {
  const Span(this.begin, this.end);

  final int? begin;
  final int? end;

  bool contains(int x) {
    return switch ((begin, end)) {
      (final a?, final b?) when a <= x && x < b => true,
      (final a?, null) when a <= x => true,
      (null, final b?) when b > x => true,
      (null, null) => true,
      _ => false,
    };
  }

  // TODO(JonasWanke): implement `Comparable<int>`
  Ordering compareTo(int x) {
    return switch ((begin, end)) {
      (final a?, final b?) when a <= x && x < b => Ordering.equal,
      (final a?, final b?) when a <= x && b <= x => Ordering.less,
      (final _?, final _?) => Ordering.greater,
      (final a?, null) when a <= x => Ordering.equal,
      (final _?, null) => Ordering.greater,
      (null, final b?) when b <= x => Ordering.less,
      (null, final _?) => Ordering.equal,
      (null, null) => Ordering.equal,
    };
  }
}

enum Ordering { less, equal, greater }

@immutable
class FixedTimespanSet {
  const FixedTimespanSet(this.first, this.rest);

  final FixedTimespan first;
  final List<(int, FixedTimespan)> rest;

  int get length => 1 + rest.length;

  Span utcSpan(int index) {
    assert(index < length);
    return Span(
      index == 0 ? null : rest[index - 1].$1,
      index == rest.length ? null : rest[index].$1,
    );
  }

  Span localSpan(int index) {
    assert(index < length);
    return Span(
      index == 0
          ? null
          : () {
              final span = rest[index - 1];
              return span.$1 + span.$2.offsetSeconds;
            }(),
      index == rest.length
          ? null
          : index == 0
          ? rest[index].$1 + first.offsetSeconds
          : rest[index].$1 + rest[index - 1].$2.offsetSeconds,
    );
  }

  FixedTimespan get(int index) {
    assert(index < length);
    return index == 0 ? first : rest[index - 1].$2;
  }
}

// /// Represents the information of a gap.
// ///
// /// This returns useful information that can be used when converting a local [`NaiveDateTime`]
// /// to a timezone-aware [`DateTime`] with [`TimeZone::from_local_datetime`] and a gap
// /// ([`LocalResult::None`]) is found.
// pub struct GapInfo {
//     /// When available it contains information about the beginning of the gap.
//     ///
//     /// The time represents the first instant in which the gap starts.
//     /// This means that it is the first instant that when used with [`TimeZone::from_local_datetime`]
//     /// it will return [`LocalResult::None`].
//     ///
//     /// The offset represents the offset of the first instant before the gap.
//     pub begin: Option<(NaiveDateTime, TzOffset)>,
//     /// When available it contains the first instant after the gap.
//     pub end: Option<DateTime<Tz>>,
// }

// impl GapInfo {
//     /// Return information about a gap.
//     ///
//     /// It returns `None` if `local` is not in a gap for the current timezone.
//     ///
//     /// If `local` is at the limits of the known timestamps the fields `begin` or `end` in
//     /// [`GapInfo`] will be `None`.
//     pub fn new(local: &NaiveDateTime, tz: &Tz) -> Option<Self> {
//         let timestamp = local.and_utc().timestamp();
//         let timespans = tz.timespans();
//         let index = binary_search(0, timespans.len(), |i| {
//             timespans.local_span(i).cmp(timestamp)
//         });

//         let Err(end_idx) = index else {
//             return None;
//         };

//         let begin = match end_idx {
//             0 => None,
//             _ => {
//                 let start_idx = end_idx - 1;

//                 timespans
//                     .local_span(start_idx)
//                     .end
//                     .and_then(|start_time| DateTime::from_timestamp(start_time, 0))
//                     .map(|start_time| {
//                         (
//                             start_time.naive_local(),
//                             TzOffset::new(*tz, timespans.get(start_idx)),
//                         )
//                     })
//             }
//         };

//         let end = match end_idx {
//             _ if end_idx >= timespans.len() => None,
//             _ => {
//                 timespans
//                     .local_span(end_idx)
//                     .begin
//                     .and_then(|end_time| DateTime::from_timestamp(end_time, 0))
//                     .and_then(|date_time| {
//                         // we create the DateTime from a timestamp that exists in the timezone
//                         tz.from_local_datetime(&date_time.naive_local()).single()
//                     })
//             }
//         };

//         Some(Self { begin, end })
//     }
// }
