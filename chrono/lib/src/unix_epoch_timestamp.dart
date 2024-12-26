import 'dart:core' as core;
import 'dart:core';

import 'package:clock/clock.dart';
import 'package:meta/meta.dart';
import 'package:oxidized/oxidized.dart';

import 'codec.dart';
import 'date_time/date_time.dart';
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
/// - [Instant], which stores the passed time as [Nanoseconds].
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

  Instant asInstant() =>
      Instant.fromDurationSinceUnixEpoch(durationSinceUnixEpoch);
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
}

// Fractional Seconds

/// A point in time, represented as the [Nanoseconds] that passed since
/// the Unix epoch.
///
/// See also:
///
/// - [UnixEpochTimestamp], which is the superclass supporting arbitrary time
///   duration types.
/// - [UnixEpochMicroseconds], which stores the passed time as [Microseconds].
/// - [UnixEpochMilliseconds], which stores the passed time as [Milliseconds].
/// - [UnixEpochSeconds], which stores the passed time as [Seconds].
final class Instant extends UnixEpochTimestamp<Nanoseconds> {
  Instant.fromDurationSinceUnixEpoch(TimeDuration duration)
      : super(duration.asNanoseconds);

  Instant.fromCore(core.DateTime dateTime)
      : super(Nanoseconds.microsecond * dateTime.microsecondsSinceEpoch);
  Instant.now({Clock? clockOverride})
      : this.fromCore((clockOverride ?? clock).now());

  /// The UNIX epoch: 1970-01-01 at 00:00:00 in UTC.
  ///
  /// https://en.wikipedia.org/wiki/Unix_time
  static final unixEpoch = Instant.fromDurationSinceUnixEpoch(Nanoseconds(0));

  Instant operator +(TimeDuration duration) =>
      Instant.fromDurationSinceUnixEpoch(durationSinceUnixEpoch + duration);
  Instant operator -(TimeDuration duration) =>
      Instant.fromDurationSinceUnixEpoch(durationSinceUnixEpoch - duration);

  /// Returns `this - other`.
  Nanoseconds difference(Instant other) =>
      durationSinceUnixEpoch - other.durationSinceUnixEpoch;
  @override
  String toString() => '${dateTimeInUtc}Z';
}

/// Encodes an [Instant] as an ISO 8601 string, e.g.,
/// “2023-04-23T18:24:20.123456789Z”.
class InstantAsIsoStringCodec extends CodecWithParserResult<Instant, String> {
  const InstantAsIsoStringCodec();

  @override
  String encode(Instant input) => input.toString();
  @override
  Result<Instant, FormatException> decodeAsResult(String encoded) =>
      Parser.parseInstant(encoded);
}

/// Encodes [Instant] as an integer number of nanoseconds that passed since the
/// Unix epoch.
///
/// See also:
///
/// - [Instant.unixEpoch], which is the Unix epoch.
/// - [InstantAsIsoStringCodec], which encodes Unix epoch nanoseconds as
///   a human-readable string.
@immutable
class InstantAsIntCodec extends CodecAndJsonConverter<Instant, int> {
  const InstantAsIntCodec();

  @override
  int encode(Instant input) =>
      input.durationSinceUnixEpoch.inNanoseconds.toInt();
  @override
  Instant decode(int encoded) =>
      Instant.fromDurationSinceUnixEpoch(Nanoseconds(encoded));
}

// Microseconds

/// A point in time, represented as the [Microseconds] that passed since the
/// Unix epoch.
///
/// See also:
///
/// - [UnixEpochTimestamp], which is the superclass supporting arbitrary time
///   duration types.
/// - [Instant], which stores the passed time as [Nanoseconds].
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
  @override
  String toString() {
    final dateTime = dateTimeInUtc;
    final hour = dateTime.time.hour.toString().padLeft(2, '0');
    final minute = dateTime.time.minute.toString().padLeft(2, '0');
    final second = dateTime.time.second.toString().padLeft(2, '0');
    final microseconds = dateTime.time.nanoseconds
        .roundToMicroseconds()
        .inMicroseconds
        .toString()
        .padLeft(6, '0');
    return '${dateTime.date}T$hour:$minute:$second.${microseconds}Z';
  }
}

/// Encodes [UnixEpochMicroseconds] as an ISO 8601 string, e.g.,
/// “2023-04-23T18:24:20.123456Z”.
///
/// See also:
///
/// - [UnixEpochMicrosecondsAsIntCodec], which encodes the nanoseconds
///   as an integer.
class UnixEpochMicrosecondsAsIsoStringCodec
    extends CodecWithParserResult<UnixEpochMicroseconds, String> {
  const UnixEpochMicrosecondsAsIsoStringCodec();

  @override
  Result<UnixEpochMicroseconds, FormatException> decodeAsResult(
    String encoded,
  ) =>
      Parser.parseUnixEpochMicroseconds(encoded);
  @override
  String encode(UnixEpochMicroseconds input) => input.toString();
}

/// Encodes [UnixEpochMicroseconds] as an integer number of milliseconds that
/// passed since the Unix epoch.
///
/// See also:
///
/// - [UnixEpochMicroseconds.unixEpoch], which is the Unix epoch.
/// - [UnixEpochMicrosecondsAsIsoStringCodec], which encodes Unix epoch
///   microseconds as a human-readable string.
@immutable
class UnixEpochMicrosecondsAsIntCodec
    extends CodecAndJsonConverter<UnixEpochMicroseconds, int> {
  const UnixEpochMicrosecondsAsIntCodec();

  @override
  int encode(UnixEpochMicroseconds input) =>
      input.durationSinceUnixEpoch.inMicroseconds;
  @override
  UnixEpochMicroseconds decode(int encoded) =>
      UnixEpochMicroseconds(Microseconds(encoded));
}

// Milliseconds

/// A point in time, represented as the [Milliseconds] that passed since the
/// Unix epoch.
///
/// See also:
///
/// - [UnixEpochTimestamp], which is the superclass supporting arbitrary time
///   duration types.
/// - [Instant], which stores the passed time as [Nanoseconds].
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

  @override
  String toString() {
    final dateTime = dateTimeInUtc;
    final hour = dateTime.time.hour.toString().padLeft(2, '0');
    final minute = dateTime.time.minute.toString().padLeft(2, '0');
    final second = dateTime.time.second.toString().padLeft(2, '0');
    final milliseconds = dateTime.time.nanoseconds
        .roundToMilliseconds()
        .inMilliseconds
        .toString()
        .padLeft(3, '0');
    return '${dateTime.date}T$hour:$minute:$second.${milliseconds}Z';
  }
}

/// Encodes [UnixEpochMilliseconds] as an ISO 8601 string, e.g.,
/// “2023-04-23T18:24:20.123Z”.
///
/// See also:
///
/// - [UnixEpochMillisecondsAsIntCodec], which encodes the nanoseconds
///   as an integer.
class UnixEpochMillisecondsAsIsoStringCodec
    extends CodecWithParserResult<UnixEpochMilliseconds, String> {
  const UnixEpochMillisecondsAsIsoStringCodec();

  @override
  Result<UnixEpochMilliseconds, FormatException> decodeAsResult(
    String encoded,
  ) =>
      Parser.parseUnixEpochMilliseconds(encoded);
  @override
  String encode(UnixEpochMilliseconds input) => input.toString();
}

/// Encodes [UnixEpochMilliseconds] as an integer number of milliseconds that
/// passed since the Unix epoch.
///
/// See also:
///
/// - [UnixEpochMilliseconds.unixEpoch], which is the Unix epoch.
/// - [UnixEpochMillisecondsAsIsoStringCodec], which encodes Unix epoch
///   milliseconds as a human-readable string.
@immutable
class UnixEpochMillisecondsAsIntCodec
    extends CodecAndJsonConverter<UnixEpochMilliseconds, int> {
  const UnixEpochMillisecondsAsIntCodec();

  @override
  int encode(UnixEpochMilliseconds input) =>
      input.durationSinceUnixEpoch.inMilliseconds;
  @override
  UnixEpochMilliseconds decode(int encoded) =>
      UnixEpochMilliseconds(Milliseconds(encoded));
}

// Seconds

/// A point in time, represented as the [Seconds] that passed since the Unix
/// epoch.
///
/// See also:
///
/// - [UnixEpochTimestamp], which is the superclass supporting arbitrary time
///   duration types.
/// - [Instant], which stores the passed time as [Nanoseconds].
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

  @override
  String toString() {
    final dateTime = dateTimeInUtc;
    final hour = dateTime.time.hour.toString().padLeft(2, '0');
    final minute = dateTime.time.minute.toString().padLeft(2, '0');
    final second = dateTime.time.second.toString().padLeft(2, '0');
    return '${dateTime.date}T$hour:$minute:${second}Z';
  }
}

/// Encodes [UnixEpochSeconds] as an ISO 8601 string, e.g.,
/// “2023-04-23T18:24:20Z”.
///
/// See also:
///
/// - [UnixEpochSecondsAsIntCodec], which encodes the nanoseconds as
///   an integer.
class UnixEpochSecondsAsIsoStringCodec
    extends CodecWithParserResult<UnixEpochSeconds, String> {
  const UnixEpochSecondsAsIsoStringCodec();

  @override
  Result<UnixEpochSeconds, FormatException> decodeAsResult(String encoded) =>
      Parser.parseUnixEpochSeconds(encoded);
  @override
  String encode(UnixEpochSeconds input) => input.toString();
}

/// Encodes [UnixEpochSeconds] as an integer number of seconds that passed since
/// the Unix epoch.
///
/// See also:
///
/// - [UnixEpochSeconds.unixEpoch], which is the Unix epoch.
/// - [UnixEpochSecondsAsIsoStringCodec], which encodes Unix epoch
///   seconds as a human-readable string.
@immutable
class UnixEpochSecondsAsIntCodec
    extends CodecAndJsonConverter<UnixEpochSeconds, int> {
  const UnixEpochSecondsAsIntCodec();

  @override
  int encode(UnixEpochSeconds input) => input.durationSinceUnixEpoch.inSeconds;
  @override
  UnixEpochSeconds decode(int encoded) => UnixEpochSeconds(Seconds(encoded));
}
