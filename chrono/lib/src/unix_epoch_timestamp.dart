import 'dart:core' as core;
import 'dart:core';

import 'package:clock/clock.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:oxidized/oxidized.dart';

import 'date_time/date_time.dart';
import 'json.dart';
import 'parser.dart';
import 'rounding.dart';
import 'time/duration.dart';
import 'utils.dart';

/// A point in time, represented as the duration that passed since the Unix
/// epoch.
///
/// The Unix epoch is 1970-01-01 at 00:00:00 in UTC
/// (https://en.wikipedia.org/wiki/Unix_time).
///
/// See also the following subclasses:
///
/// - [Instant], which stores the passed time as [FractionalSeconds].
/// - [UnixEpochNanoseconds], which stores the passed time as [Nanoseconds].
/// - [UnixEpochMicroseconds], which stores the passed time as [Microseconds].
/// - [UnixEpochMilliseconds], which stores the passed time as [Milliseconds].
/// - [UnixEpochSeconds], which stores the passed time as [Seconds].
@immutable
class UnixEpochTimestamp<D extends TimeDuration>
    with ComparisonOperatorsFromComparable<UnixEpochTimestamp<TimeDuration>>
    implements Comparable<UnixEpochTimestamp<TimeDuration>> {
  const UnixEpochTimestamp(this.durationSinceUnixEpoch);

  final D durationSinceUnixEpoch;

  DateTime get dateTimeInLocalZone =>
      DateTime.fromCore(asCoreDateTimeInLocalZone);
  DateTime get dateTimeInUtc =>
      DateTime.fromDurationSinceUnixEpoch(durationSinceUnixEpoch);

  core.DateTime get asCoreDateTimeInLocalZone => _getDateTime(isUtc: false);
  core.DateTime get asCoreDateTimeInUtc => _getDateTime(isUtc: true);
  core.DateTime _getDateTime({required bool isUtc}) {
    return core.DateTime.fromMicrosecondsSinceEpoch(
      durationSinceUnixEpoch.roundToMicroseconds().inMicroseconds,
      isUtc: isUtc,
    );
  }

  UnixEpochNanoseconds roundToNanoseconds({
    Rounding rounding = Rounding.nearestAwayFromZero,
  }) {
    return UnixEpochNanoseconds(
      durationSinceUnixEpoch.roundToNanoseconds(rounding: rounding),
    );
  }

  UnixEpochMicroseconds roundToMicroseconds({
    Rounding rounding = Rounding.nearestAwayFromZero,
  }) {
    return UnixEpochMicroseconds(
      durationSinceUnixEpoch.roundToMicroseconds(rounding: rounding),
    );
  }

  UnixEpochMilliseconds roundToMilliseconds({
    Rounding rounding = Rounding.nearestAwayFromZero,
  }) {
    return UnixEpochMilliseconds(
      durationSinceUnixEpoch.roundToMilliseconds(rounding: rounding),
    );
  }

  UnixEpochSeconds roundToSeconds({
    Rounding rounding = Rounding.nearestAwayFromZero,
  }) {
    return UnixEpochSeconds(
      durationSinceUnixEpoch.roundToSeconds(rounding: rounding),
    );
  }

  @override
  int compareTo(UnixEpochTimestamp<TimeDuration> other) =>
      durationSinceUnixEpoch.compareTo(other.durationSinceUnixEpoch);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is UnixEpochTimestamp<D> &&
            durationSinceUnixEpoch == other.durationSinceUnixEpoch);
  }

  @override
  int get hashCode => durationSinceUnixEpoch.hashCode;

  @override
  String toString() => '${dateTimeInUtc}Z';
}

// Fractional Seconds

/// A point in time, represented as the [FractionalSeconds] that passed since
/// the Unix epoch.
///
/// See also:
///
/// - [UnixEpochTimestamp], which is the superclass supporting arbitrary time
///   duration types.
/// - [UnixEpochNanoseconds], which stores the passed time as [Nanoseconds].
/// - [UnixEpochMicroseconds], which stores the passed time as [Microseconds].
/// - [UnixEpochMilliseconds], which stores the passed time as [Milliseconds].
/// - [UnixEpochSeconds], which stores the passed time as [Seconds].
final class Instant extends UnixEpochTimestamp<FractionalSeconds> {
  Instant.fromDurationSinceUnixEpoch(TimeDuration duration)
      : super(duration.asFractionalSeconds);

  Instant.fromCore(core.DateTime dateTime)
      : super(FractionalSeconds.microsecond * dateTime.microsecondsSinceEpoch);
  Instant.now({Clock? clockOverride})
      : this.fromCore((clockOverride ?? clock).now());

  /// The UNIX epoch: 1970-01-01 at 00:00:00 in UTC.
  ///
  /// https://en.wikipedia.org/wiki/Unix_time
  static final unixEpoch =
      Instant.fromDurationSinceUnixEpoch(FractionalSeconds.zero);

  Instant operator +(TimeDuration duration) =>
      Instant.fromDurationSinceUnixEpoch(durationSinceUnixEpoch + duration);
  Instant operator -(TimeDuration duration) =>
      Instant.fromDurationSinceUnixEpoch(durationSinceUnixEpoch - duration);

  /// Returns `this - other`.
  FractionalSeconds difference(Instant other) =>
      durationSinceUnixEpoch - other.durationSinceUnixEpoch;
}

/// Encodes an [Instant] as an ISO 8601 string, e.g., “2023-04-23T18:24:20.12”.
class InstantAsIsoStringJsonConverter
    extends JsonConverterWithParserResult<Instant, String> {
  const InstantAsIsoStringJsonConverter();

  @override
  Result<Instant, FormatException> resultFromJson(String json) =>
      Parser.parseInstant(json);
  @override
  String toJson(Instant object) => object.toString();
}

// Nanoseconds

/// A point in time, represented as the [Nanoseconds] that passed since the
/// Unix epoch.
///
/// See also:
///
/// - [UnixEpochTime], which is the superclass supporting arbitrary time
///   duration types.
/// - [Instant], which stores the passed time as [FractionalSeconds].
/// - [UnixEpochMicroseconds], which stores the passed time as [Microseconds].
/// - [UnixEpochMilliseconds], which stores the passed time as [Milliseconds].
/// - [UnixEpochSeconds], which stores the passed time as [Seconds].
final class UnixEpochNanoseconds extends UnixEpochTimestamp<Nanoseconds> {
  UnixEpochNanoseconds(NanosecondsDuration duration)
      : super(duration.asNanoseconds);

  UnixEpochNanoseconds.fromCore(core.DateTime dateTime)
      : super(Microseconds(dateTime.microsecondsSinceEpoch).asNanoseconds);
  UnixEpochNanoseconds.now({Clock? clockOverride})
      : this.fromCore((clockOverride ?? clock).now());

  /// The UNIX epoch: 1970-01-01 at 00:00:00 in UTC.
  ///
  /// https://en.wikipedia.org/wiki/Unix_time
  static final unixEpoch = UnixEpochNanoseconds(const Nanoseconds(0));

  UnixEpochNanoseconds operator +(NanosecondsDuration duration) =>
      UnixEpochNanoseconds(durationSinceUnixEpoch + duration);
  UnixEpochNanoseconds operator -(NanosecondsDuration duration) =>
      UnixEpochNanoseconds(durationSinceUnixEpoch - duration);

  /// Returns `this - other`.
  Nanoseconds difference(UnixEpochNanoseconds other) =>
      durationSinceUnixEpoch - other.durationSinceUnixEpoch;
}

/// Encodes [UnixEpochNanoseconds] as an ISO 8601 string, e.g.,
/// “2023-04-23T18:24:20.123456789”.
///
/// See also:
///
/// - [UnixEpochNanosecondsAsIntJsonConverter], which encodes the nanoseconds as
///   an integer.
class UnixEpochNanosecondsAsIsoStringJsonConverter
    extends JsonConverterWithParserResult<UnixEpochNanoseconds, String> {
  const UnixEpochNanosecondsAsIsoStringJsonConverter();

  @override
  Result<UnixEpochNanoseconds, FormatException> resultFromJson(String json) =>
      Parser.parseUnixEpochNanoseconds(json);
  @override
  String toJson(UnixEpochNanoseconds object) => object.toString();
}

/// Encodes [UnixEpochNanoseconds] as an integer number of milliseconds that
/// passed since the Unix epoch.
///
/// See also:
///
/// - [UnixEpochNanoseconds.unixEpoch], which is the Unix epoch.
/// - [UnixEpochNanosecondsAsIsoStringJsonConverter], which encodes Unix epoch
///   seconds as a human-readable string.
@immutable
class UnixEpochNanosecondsAsIntJsonConverter
    extends JsonConverter<UnixEpochNanoseconds, int> {
  const UnixEpochNanosecondsAsIntJsonConverter();

  @override
  UnixEpochNanoseconds fromJson(int json) =>
      UnixEpochNanoseconds(Nanoseconds(json));
  @override
  int toJson(UnixEpochNanoseconds object) =>
      object.durationSinceUnixEpoch.inNanoseconds;
}

// Microseconds

/// A point in time, represented as the [Microseconds] that passed since the
/// Unix epoch.
///
/// See also:
///
/// - [UnixEpochTimestamp], which is the superclass supporting arbitrary time
///   duration types.
/// - [Instant], which stores the passed time as [FractionalSeconds].
/// - [UnixEpochNanoseconds], which stores the passed time as [Nanoseconds].
/// - [UnixEpochMilliseconds], which stores the passed time as [Milliseconds].
/// - [UnixEpochSeconds], which stores the passed time as [Seconds].
final class UnixEpochMicroseconds extends UnixEpochTimestamp<Microseconds> {
  UnixEpochMicroseconds(MicrosecondsDuration duration)
      : super(duration.asMicroseconds);

  UnixEpochMicroseconds.fromCore(core.DateTime dateTime)
      : super(Microseconds(dateTime.microsecondsSinceEpoch));
  UnixEpochMicroseconds.now({Clock? clockOverride})
      : this.fromCore((clockOverride ?? clock).now());

  /// The UNIX epoch: 1970-01-01 at 00:00:00 in UTC.
  ///
  /// https://en.wikipedia.org/wiki/Unix_time
  static final unixEpoch = UnixEpochMicroseconds(const Microseconds(0));

  UnixEpochMicroseconds operator +(MicrosecondsDuration duration) =>
      UnixEpochMicroseconds(durationSinceUnixEpoch + duration);
  UnixEpochMicroseconds operator -(MicrosecondsDuration duration) =>
      UnixEpochMicroseconds(durationSinceUnixEpoch - duration);

  /// Returns `this - other`.
  Microseconds difference(UnixEpochMicroseconds other) =>
      durationSinceUnixEpoch - other.durationSinceUnixEpoch;
}

/// Encodes [UnixEpochMicroseconds] as an ISO 8601 string, e.g.,
/// “2023-04-23T18:24:20.123456”.
///
/// See also:
///
/// - [UnixEpochMicrosecondsAsIntJsonConverter], which encodes the nanoseconds as
///   an integer.
class UnixEpochMicrosecondsAsIsoStringJsonConverter
    extends JsonConverterWithParserResult<UnixEpochMicroseconds, String> {
  const UnixEpochMicrosecondsAsIsoStringJsonConverter();

  @override
  Result<UnixEpochMicroseconds, FormatException> resultFromJson(String json) =>
      Parser.parseUnixEpochMicroseconds(json);
  @override
  String toJson(UnixEpochMicroseconds object) => object.toString();
}

/// Encodes [UnixEpochMicroseconds] as an integer number of milliseconds that
/// passed since the Unix epoch.
///
/// See also:
///
/// - [UnixEpochMicroseconds.unixEpoch], which is the Unix epoch.
/// - [UnixEpochMicrosecondsAsIsoStringJsonConverter], which encodes Unix epoch
///   seconds as a human-readable string.
@immutable
class UnixEpochMicrosecondsAsIntJsonConverter
    extends JsonConverter<UnixEpochMicroseconds, int> {
  const UnixEpochMicrosecondsAsIntJsonConverter();

  @override
  UnixEpochMicroseconds fromJson(int json) =>
      UnixEpochMicroseconds(Microseconds(json));
  @override
  int toJson(UnixEpochMicroseconds object) =>
      object.durationSinceUnixEpoch.inMicroseconds;
}

// Milliseconds

/// A point in time, represented as the [Milliseconds] that passed since the
/// Unix epoch.
///
/// See also:
///
/// - [UnixEpochTimestamp], which is the superclass supporting arbitrary time
///   duration types.
/// - [Instant], which stores the passed time as [FractionalSeconds].
/// - [UnixEpochNanoseconds], which stores the passed time as [Nanoseconds].
/// - [UnixEpochMicroseconds], which stores the passed time as [Microseconds].
/// - [UnixEpochSeconds], which stores the passed time as [Seconds].
final class UnixEpochMilliseconds extends UnixEpochTimestamp<Milliseconds> {
  UnixEpochMilliseconds(MillisecondsDuration duration)
      : super(duration.asMilliseconds);

  UnixEpochMilliseconds.fromCore(
    core.DateTime dateTime, {
    Rounding rounding = Rounding.nearestAwayFromZero,
  }) : super(
          Microseconds(dateTime.microsecondsSinceEpoch)
              .roundToMilliseconds(rounding: rounding),
        );
  UnixEpochMilliseconds.now({Clock? clockOverride})
      : this.fromCore((clockOverride ?? clock).now());

  /// The UNIX epoch: 1970-01-01 at 00:00:00 in UTC.
  ///
  /// https://en.wikipedia.org/wiki/Unix_time
  static final unixEpoch = UnixEpochMilliseconds(const Milliseconds(0));

  UnixEpochMilliseconds operator +(MillisecondsDuration duration) =>
      UnixEpochMilliseconds(durationSinceUnixEpoch + duration);
  UnixEpochMilliseconds operator -(MillisecondsDuration duration) =>
      UnixEpochMilliseconds(durationSinceUnixEpoch - duration);

  /// Returns `this - other`.
  Milliseconds difference(UnixEpochMilliseconds other) =>
      durationSinceUnixEpoch - other.durationSinceUnixEpoch;
}

/// Encodes [UnixEpochMilliseconds] as an ISO 8601 string, e.g.,
/// “2023-04-23T18:24:20.123”.
///
/// See also:
///
/// - [UnixEpochMillisecondsAsIntJsonConverter], which encodes the nanoseconds as
///   an integer.
class UnixEpochMillisecondsAsIsoStringJsonConverter
    extends JsonConverterWithParserResult<UnixEpochMilliseconds, String> {
  const UnixEpochMillisecondsAsIsoStringJsonConverter();

  @override
  Result<UnixEpochMilliseconds, FormatException> resultFromJson(String json) =>
      Parser.parseUnixEpochMilliseconds(json);
  @override
  String toJson(UnixEpochMilliseconds object) => object.toString();
}

/// Encodes [UnixEpochMilliseconds] as an integer number of milliseconds that
/// passed since the Unix epoch.
///
/// See also:
///
/// - [UnixEpochMilliseconds.unixEpoch], which is the Unix epoch.
/// - [UnixEpochMillisecondsAsIsoStringJsonConverter], which encodes Unix epoch
///   seconds as a human-readable string.
@immutable
class UnixEpochMillisecondsAsIntJsonConverter
    extends JsonConverter<UnixEpochMilliseconds, int> {
  const UnixEpochMillisecondsAsIntJsonConverter();

  @override
  UnixEpochMilliseconds fromJson(int json) =>
      UnixEpochMilliseconds(Milliseconds(json));
  @override
  int toJson(UnixEpochMilliseconds object) =>
      object.durationSinceUnixEpoch.inMilliseconds;
}

// Seconds

/// A point in time, represented as the [Seconds] that passed since the Unix
/// epoch.
///
/// See also:
///
/// - [UnixEpochTimestamp], which is the superclass supporting arbitrary time
///   duration types.
/// - [Instant], which stores the passed time as [FractionalSeconds].
/// - [UnixEpochNanoseconds], which stores the passed time as [Nanoseconds].
/// - [UnixEpochMicroseconds], which stores the passed time as [Microseconds].
/// - [UnixEpochMilliseconds], which stores the passed time as [Milliseconds].
final class UnixEpochSeconds extends UnixEpochTimestamp<Seconds> {
  UnixEpochSeconds(SecondsDuration duration) : super(duration.asSeconds);

  UnixEpochSeconds.fromCore(
    core.DateTime dateTime, {
    Rounding rounding = Rounding.nearestAwayFromZero,
  }) : super(
          Microseconds(dateTime.microsecondsSinceEpoch)
              .roundToSeconds(rounding: rounding),
        );
  UnixEpochSeconds.now({Clock? clockOverride})
      : this.fromCore((clockOverride ?? clock).now());

  /// The UNIX epoch: 1970-01-01 at 00:00:00 in UTC.
  ///
  /// https://en.wikipedia.org/wiki/Unix_time
  static final unixEpoch = UnixEpochSeconds(const Seconds(0));

  UnixEpochSeconds operator +(SecondsDuration duration) =>
      UnixEpochSeconds(durationSinceUnixEpoch + duration);
  UnixEpochSeconds operator -(SecondsDuration duration) =>
      UnixEpochSeconds(durationSinceUnixEpoch - duration);

  /// Returns `this - other`.
  Seconds difference(UnixEpochSeconds other) =>
      durationSinceUnixEpoch - other.durationSinceUnixEpoch;
}

/// Encodes [UnixEpochSeconds] as an ISO 8601 string, e.g.,
/// “2023-04-23T18:24:20”.
///
/// See also:
///
/// - [UnixEpochSecondsAsIntJsonConverter], which encodes the nanoseconds as
///   an integer.
class UnixEpochSecondsAsIsoStringJsonConverter
    extends JsonConverterWithParserResult<UnixEpochSeconds, String> {
  const UnixEpochSecondsAsIsoStringJsonConverter();

  @override
  Result<UnixEpochSeconds, FormatException> resultFromJson(String json) =>
      Parser.parseUnixEpochSeconds(json);
  @override
  String toJson(UnixEpochSeconds object) => object.toString();
}

/// Encodes [UnixEpochSeconds] as an integer number of seconds that passed since
/// the Unix epoch.
///
/// See also:
///
/// - [UnixEpochSeconds.unixEpoch], which is the Unix epoch.
/// - [UnixEpochSecondsAsIsoStringJsonConverter], which encodes Unix epoch
///   seconds as a human-readable string.
@immutable
class UnixEpochSecondsAsIntJsonConverter
    extends JsonConverter<UnixEpochSeconds, int> {
  const UnixEpochSecondsAsIntJsonConverter();

  @override
  UnixEpochSeconds fromJson(int json) => UnixEpochSeconds(Seconds(json));
  @override
  int toJson(UnixEpochSeconds object) =>
      object.durationSinceUnixEpoch.inSeconds;
}
