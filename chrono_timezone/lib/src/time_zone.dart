import 'package:chrono/chrono.dart';
import 'package:meta/meta.dart';

import '../chrono_timezone.dart';
import 'utils.dart';

/// An [Offset] that applies for a period of time.
///
/// For example, [Tz.us_eastern] is composed of at least two [FixedTimespan]s:
/// `EST` and `EDT`, that are variously in effect.
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
class TzOffset implements Offset<Tz> {
  const TzOffset(this.timeZone, this.offset);

  @override
  final Tz timeZone;
  final FixedTimespan offset;

  /// The IANA TZDB identifier (e.g., "America/New_York").
  String get tzId => timeZone.name;

  /// The abbreviation to use in a longer timestamp (e.g., "EST").
  ///
  /// This takes into account any special offsets that may be in effect. For
  /// example, at a given instant, the time zone with ID *America/New_York* may
  /// be either *EST* or *EDT*.
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
      other is TzOffset && other.timeZone == timeZone && other.offset == offset;
  @override
  int get hashCode => Object.hash(timeZone, offset);

  @override
  String toString() => offset.toString();
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
class Span implements Comparable<int> {
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

  @override
  int compareTo(int x) {
    return switch ((begin, end)) {
      (final a?, final b?) when a <= x && x < b => 0,
      (final a?, final b?) when a <= x && b <= x => -1,
      (final _?, final _?) => 1,
      (final a?, null) when a <= x => 0,
      (final _?, null) => 1,
      (null, final b?) when b <= x => -1,
      (null, final _?) => 0,
      (null, null) => 0,
    };
  }
}

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

/// Represents the information of a gap.
///
/// This returns useful information that can be used when converting a local
/// [CDateTime] to a timezone-aware [ZonedDateTime] with
/// [TimeZone.fromLocalDateTime] and a gap ([MappedLocalTime_None]) is found.
@immutable
class GapInfo {
  const GapInfo(this.begin, this.end);

  /// Return information about a gap.
  ///
  /// It returns `null` if [local] is not in a gap for the current timezone.
  ///
  /// If [local] is at the limits of the known timestamps, the fields [begin] or
  /// [end] in [GapInfo] will be `null`.
  static GapInfo? of(CDateTime local, Tz tz) {
    final timestamp = local.andUtc().durationSinceUnixEpoch.totalSeconds;
    final timespans = tz.timespans;
    final endIndex = binarySearch(
      timespans.length,
      (it) => timespans.localSpan(it).compareTo(timestamp),
    );

    if (endIndex == null) return null;

    final begin = endIndex == 0
        ? null
        : () {
            final startIndex = endIndex - 1;
            final end = timespans.localSpan(startIndex).end;
            if (end == null) return null;

            return (
              ZonedDateTime.fromDurationSinceUnixEpoch(
                TimeDelta(seconds: end),
              ).localDateTime,
              TzOffset(tz, timespans.get(startIndex)),
            );
          }();

    final end = endIndex >= timespans.length
        ? null
        : () {
            final begin = timespans.localSpan(endIndex).begin;
            if (begin == null) return null;

            // We create the ZonedDateTime from a timestamp that exists in the
            // timezone.
            return tz
                .fromLocalDateTime(
                  ZonedDateTime.fromDurationSinceUnixEpoch(
                    TimeDelta(seconds: begin),
                  ).localDateTime,
                )
                .single;
          }();

    return GapInfo(begin, end);
  }

  /// When available, it contains information about the beginning of the gap.
  ///
  /// The time represents the first instant in which the gap starts.
  /// This means that it is the first instant that, when used with
  /// [TimeZone.fromLocalDateTime], will return [MappedLocalTime_None].
  ///
  /// The offset represents the offset of the first instant before the gap.
  final (CDateTime, TzOffset)? begin;

  /// When available, it contains the first instant after the gap.
  final ZonedDateTime<Tz>? end;

  @override
  bool operator ==(Object other) =>
      other is GapInfo && other.begin == begin && other.end == end;
  @override
  int get hashCode => Object.hash(begin, end);

  @override
  String toString() => 'GapInfo($begin, $end)';
}
