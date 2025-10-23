import 'package:meta/meta.dart';

import '../../chrono.dart';

/// The result of mapping a local time to a concrete instant in a given time
/// zone.
///
/// The calculation to go from a local time (wall clock time) to an instant in
/// UTC can end up in three cases:
///
/// * A single, simple result.
/// * An ambiguous result when the clock is turned backwards during a transition
///   due to, for example, daylight-saving time (DST).
/// * No result when the clock is turned forwards during a transition due to,
///   for example, DST.
///
/// When the clock is turned backwards, it creates a _fold_ in local time,
/// during which the local time is _ambiguous_. When the clock is turned
/// forwards it creates a _gap_ in local time, during which the local time is
/// _missing_, or does not exist.
///
/// Chrono does not return a default choice or invalid data during time zone
/// transitions, but has the `MappedLocalTime` type to help deal with the result
/// correctly.
///
/// [T] is usually a [ZonedDateTime] but may also be only an [Offset].
@immutable
sealed class MappedLocalTime<T> {
  const MappedLocalTime();

  /// If the time zone mapping has a single result, this result is returned.
  ///
  /// If the local time falls in a _fold_ or _gap_, or if there was an error,
  /// `null` is returned.
  @useResult
  T? get single {
    return switch (this) {
      MappedLocalTime_Single(:final value) => value,
      _ => null,
    };
  }

  /// Returns the earliest possible result of the time zone mapping.
  ///
  /// Returns `null` if local time falls in a _gap_, or if there was an error.
  @useResult
  T? get earliest {
    return switch (this) {
      MappedLocalTime_Single(:final value) ||
      MappedLocalTime_Ambiguous(earliest: final value) => value,
      _ => null,
    };
  }

  /// Returns the latest possible result of the time zone mapping.
  ///
  /// Returns `null` if local time falls in a _gap_, or if there was an error.
  @useResult
  T? get latest {
    return switch (this) {
      MappedLocalTime_Single(:final value) ||
      MappedLocalTime_Ambiguous(latest: final value) => value,
      _ => null,
    };
  }

  /// Maps a `MappedLocalTime<T>` into `MappedLocalTime<U>` with the given
  /// [mapper].
  @useResult
  MappedLocalTime<U> map<U>(U Function(T) mapper) {
    return switch (this) {
      MappedLocalTime_None() => const MappedLocalTime_None(),
      MappedLocalTime_Single(:final value) => MappedLocalTime_Single(
        mapper(value),
      ),
      MappedLocalTime_Ambiguous(:final earliest, :final latest) =>
        MappedLocalTime_Ambiguous(mapper(earliest), mapper(latest)),
    };
  }

  /// Maps a `MappedLocalTime<T>` into `MappedLocalTime<U>` with the given
  /// [mapper].
  ///
  /// Returns [MappedLocalTime_None] if the function returns `null`.
  @useResult
  MappedLocalTime<U> andThen<U>(U? Function(T) mapper) {
    return switch (this) {
      MappedLocalTime_None() => const MappedLocalTime_None(),
      MappedLocalTime_Single(:final value) => switch (mapper(value)) {
        final value? => MappedLocalTime_Single(value),
        null => const MappedLocalTime_None(),
      },
      MappedLocalTime_Ambiguous(:final earliest, :final latest) => switch ((
        mapper(earliest),
        mapper(latest),
      )) {
        (final earliest?, final latest?) => MappedLocalTime_Ambiguous(
          earliest,
          latest,
        ),
        _ => const MappedLocalTime_None(),
      },
    };
  }

  /// Returns a single unique conversion result or throws a [StateError].
  ///
  /// `unwrap()` is best combined with time zone types where the mapping can
  /// never fail, like [Utc] and [FixedOffset]. Note that for [FixedOffset]
  /// there is a rare case where a resulting [ZonedDateTime] can be out of range.
  ///
  /// Throws an exception if the local time falls within a _fold_ or a _gap_ in
  /// the local time, and on any error that may have been returned by the type
  /// implementing [TimeZone].
  @useResult
  T unwrap() {
    return switch (this) {
      MappedLocalTime_None() => throw StateError('No such local time'),
      MappedLocalTime_Single(:final value) => value,
      MappedLocalTime_Ambiguous(:final earliest, :final latest) =>
        throw StateError(
          'Ambiguous local time, ranging from $earliest to $latest',
        ),
    };
  }
}

/// The local time maps to a single unique result.
// ignore: camel_case_types
class MappedLocalTime_Single<T> extends MappedLocalTime<T> {
  const MappedLocalTime_Single(this.value);

  final T value;

  @override
  bool operator ==(Object other) =>
      other is MappedLocalTime_Single && other.value == value;
  @override
  int get hashCode => value.hashCode;
}

/// The local time is _ambiguous_ because there is a _fold_ in the local time.
///
/// This variant contains the two possible results.
// ignore: camel_case_types
class MappedLocalTime_Ambiguous<T> extends MappedLocalTime<T> {
  const MappedLocalTime_Ambiguous(this.earliest, this.latest);

  @override
  final T earliest;
  @override
  final T latest;

  @override
  bool operator ==(Object other) =>
      other is MappedLocalTime_Ambiguous &&
      other.earliest == earliest &&
      other.latest == latest;
  @override
  int get hashCode => Object.hash(earliest, latest);
}

/// The local time does not exist because there is a _gap_ in the local time.
///
/// This variant may also be returned if there was an error while resolving the local time,
/// caused by for example missing time zone data files, an error in an OS API, or overflow.
// ignore: camel_case_types
class MappedLocalTime_None<T> extends MappedLocalTime<T> {
  const MappedLocalTime_None();

  @override
  bool operator ==(Object other) => other is MappedLocalTime_None;
  @override
  int get hashCode => 0;
}

/// The offset from the local time to UTC.
@immutable
abstract interface class Offset<Tz extends TimeZone<Tz>> {
  /// Returns the fixed offset from UTC to the local time stored.
  FixedOffset fix();

  Tz get timeZone;
}

/// The time zone.
///
/// The methods here are the primary constructors for the [ZonedDateTime] type.
@immutable
abstract class TimeZone<Tz extends TimeZone<Tz>> {
  const TimeZone();

  /// Make a new `DateTime` from year, month, day, time components and current time zone.
  ///
  /// This assumes the proleptic Gregorian calendar, with the year 0 being 1 BCE.
  ///
  /// Returns `MappedLocalTime::None` on invalid input data.
  MappedLocalTime<ZonedDateTime<Tz>> with_ymd_and_hms(
    int year,
    int month,
    int day,
    int hour,
    int minute,
    int second,
  ) {
    return fromLocalDateTime(
      Date.fromRaw(year, month, day).at(Time.from(hour, minute, second)),
    );
  }

  /// Makes a new [ZonedDateTime] from the duration passed since January 1, 1970
  /// 0:00:00 UTC (aka "UNIX timestamp").
  // TODO(JonasWanke): add `withDurationSinceUnixEpochRaw(…)` with leap second support
  ZonedDateTime<Tz> withDurationSinceUnixEpoch(TimeDelta duration) {
    return fromUtcDateTime(
      ZonedDateTime.fromDurationSinceUnixEpoch(duration).utcDateTime,
    );
  }

  // TODO(JonasWanke): add
  // /// Reconstructs the time zone from the offset.
  // TimeZone fromOffset(offset: &Self::Offset) -> Self;

  /// Creates the offset(s) for given local [CDateTime], if possible.
  MappedLocalTime<Offset<Tz>> offsetFromLocalDateTime(CDateTime local);

  /// Converts the local [CDateTime] to the timezone-aware [ZonedDateTime], if
  /// possible.
  MappedLocalTime<ZonedDateTime<Tz>> fromLocalDateTime(CDateTime local) {
    return offsetFromLocalDateTime(local).andThen(
      (offset) => ZonedDateTime.fromUtcDateTimeAndOffset(
        local.subOffset(offset.fix()),
        offset,
      ),
    );
  }

  /// Creates the offset for given UTC [CDateTime].
  Offset<Tz> offsetFromUtcDateTime(CDateTime utc);

  /// Converts the UTC [CDateTime] to the local time.
  ///
  /// The UTC is continuous and thus this cannot fail (but can give the
  /// duplicate local time).
  ZonedDateTime<Tz> fromUtcDateTime(CDateTime utc) {
    return ZonedDateTime.fromUtcDateTimeAndOffset(
      utc,
      offsetFromUtcDateTime(utc),
    );
  }
}
