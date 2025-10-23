import 'package:clock/clock.dart';
import 'package:meta/meta.dart';

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
@immutable
final class Instant
    with ComparisonOperatorsFromComparable<Instant>
    implements Comparable<Instant> {
  Instant.fromDurationSinceUnixEpoch(this.durationSinceUnixEpoch);

  Instant.fromCore(DateTime dateTime)
    : durationSinceUnixEpoch = TimeDelta(
        micros: dateTime.microsecondsSinceEpoch,
      );
  Instant.now({Clock? clockOverride})
    : this.fromCore((clockOverride ?? clock).now());

  /// The UNIX epoch: 1970-01-01 at 00:00:00 in UTC.
  ///
  /// https://en.wikipedia.org/wiki/Unix_time
  static final unixEpoch = Instant.fromDurationSinceUnixEpoch(
    const TimeDelta.raw(0, 0),
  );

  final TimeDelta durationSinceUnixEpoch;

  CDateTime get dateTimeInLocalZone =>
      CDateTime.fromCore(asCoreDateTimeInLocalZone);
  CDateTime get dateTimeInUtc =>
      CDateTime.fromDurationSinceUnixEpoch(durationSinceUnixEpoch);

  DateTime get asCoreDateTimeInLocalZone => _getDateTime(isUtc: false);
  DateTime get asCoreDateTimeInUtc => _getDateTime(isUtc: true);
  DateTime _getDateTime({required bool isUtc}) {
    return DateTime.fromMicrosecondsSinceEpoch(
      durationSinceUnixEpoch.roundToMicroseconds(),
      isUtc: isUtc,
    );
  }

  Instant asInstant() =>
      Instant.fromDurationSinceUnixEpoch(durationSinceUnixEpoch);

  Instant operator +(TimeDelta duration) =>
      Instant.fromDurationSinceUnixEpoch(durationSinceUnixEpoch + duration);
  Instant operator -(TimeDelta duration) =>
      Instant.fromDurationSinceUnixEpoch(durationSinceUnixEpoch - duration);

  /// Returns `this - other`.
  TimeDelta difference(Instant other) =>
      durationSinceUnixEpoch - other.durationSinceUnixEpoch;

  @override
  int compareTo(Instant other) =>
      durationSinceUnixEpoch.compareTo(other.durationSinceUnixEpoch);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is Instant &&
            durationSinceUnixEpoch == other.durationSinceUnixEpoch);
  }

  @override
  int get hashCode => durationSinceUnixEpoch.hashCode;

  @override
  String toString() => '${dateTimeInUtc}Z';
}

/// Encodes an [Instant] as an ISO 8601 string, e.g.,
/// “2023-04-23T18:24:20.123456789Z”.
///
/// See also:
///
/// - [InstantAsNanosIntCodec], which encodes the exact number of nanoseconds
///   since the Unix epoch.
/// - [InstantAsMicrosIntCodec], which encodes the rounded number of
///   microseconds since the Unix epoch.
/// - [InstantAsMillisIntCodec], which encodes the rounded number of
///   milliseconds since the Unix epoch.
/// - [InstantAsSecondsIntCodec], which encodes the rounded number of
///   seconds since the Unix epoch.
class InstantAsIsoStringCodec extends CodecAndJsonConverter<Instant, String> {
  const InstantAsIsoStringCodec();

  @override
  String encode(Instant input) => input.toString();
  @override
  Instant decode(String encoded) => Parser.parseInstant(encoded);
}

/// Encodes [Instant] as an integer number of nanoseconds that passed since the
/// Unix epoch.
///
/// See also:
///
/// - [Instant.unixEpoch], which is the Unix epoch.
/// - [InstantAsIsoStringCodec], which encodes an [Instant] as a human-readable
///   string.
/// - [InstantAsMicrosIntCodec], which encodes the rounded number of
///   microseconds since the Unix epoch.
/// - [InstantAsMillisIntCodec], which encodes the rounded number of
///   milliseconds since the Unix epoch.
/// - [InstantAsSecondsIntCodec], which encodes the rounded number of
///   seconds since the Unix epoch.
@immutable
class InstantAsNanosIntCodec extends CodecAndJsonConverter<Instant, int> {
  const InstantAsNanosIntCodec();

  @override
  int encode(Instant input) => input.durationSinceUnixEpoch.totalNanos;
  @override
  Instant decode(int encoded) =>
      Instant.fromDurationSinceUnixEpoch(TimeDelta(nanos: encoded));
}

/// Encodes [Instant] as a (rounded) integer number of microseconds that passed
/// since the Unix epoch.
///
/// See also:
///
/// - [Instant.unixEpoch], which is the Unix epoch.
/// - [InstantAsIsoStringCodec], which encodes an [Instant] as a human-readable
///   string.
/// - [InstantAsNanosIntCodec], which encodes the exact number of nanoseconds
///   since the Unix epoch.
/// - [InstantAsMillisIntCodec], which encodes the rounded number of
///   milliseconds since the Unix epoch.
/// - [InstantAsSecondsIntCodec], which encodes the rounded number of
///   seconds since the Unix epoch.
@immutable
class InstantAsMicrosIntCodec extends CodecAndJsonConverter<Instant, int> {
  const InstantAsMicrosIntCodec({this.rounding = Rounding.nearestAwayFromZero});

  final Rounding rounding;

  @override
  int encode(Instant input) =>
      input.durationSinceUnixEpoch.roundToMicroseconds(rounding: rounding);
  @override
  Instant decode(int encoded) =>
      Instant.fromDurationSinceUnixEpoch(TimeDelta(micros: encoded));
}

/// Encodes [Instant] as a (rounded) integer number of milliseconds that passed
/// since the Unix epoch.
///
/// See also:
///
/// - [Instant.unixEpoch], which is the Unix epoch.
/// - [InstantAsIsoStringCodec], which encodes an [Instant] as a human-readable
///   string.
/// - [InstantAsNanosIntCodec], which encodes the exact number of nanoseconds
///   since the Unix epoch.
/// - [InstantAsMicrosIntCodec], which encodes the rounded number of
///   microseconds since the Unix epoch.
/// - [InstantAsSecondsIntCodec], which encodes the rounded number of
///   seconds since the Unix epoch.
@immutable
class InstantAsMillisIntCodec extends CodecAndJsonConverter<Instant, int> {
  const InstantAsMillisIntCodec({this.rounding = Rounding.nearestAwayFromZero});

  final Rounding rounding;

  @override
  int encode(Instant input) =>
      input.durationSinceUnixEpoch.roundToMilliseconds(rounding: rounding);
  @override
  Instant decode(int encoded) =>
      Instant.fromDurationSinceUnixEpoch(TimeDelta(millis: encoded));
}

/// Encodes [Instant] as a (rounded) integer number of seconds that passed since
/// the Unix epoch.
///
/// See also:
///
/// - [Instant.unixEpoch], which is the Unix epoch.
/// - [InstantAsIsoStringCodec], which encodes an [Instant] as a human-readable
///   string.
/// - [InstantAsNanosIntCodec], which encodes the exact number of nanoseconds
///   since the Unix epoch.
/// - [InstantAsMicrosIntCodec], which encodes the rounded number of
///   microseconds since the Unix epoch.
/// - [InstantAsMillisIntCodec], which encodes the rounded number of
///   milliseconds since the Unix epoch.
@immutable
class InstantAsSecondsIntCodec extends CodecAndJsonConverter<Instant, int> {
  const InstantAsSecondsIntCodec({
    this.rounding = Rounding.nearestAwayFromZero,
  });

  final Rounding rounding;

  @override
  int encode(Instant input) =>
      input.durationSinceUnixEpoch.roundToSeconds(rounding: rounding);
  @override
  Instant decode(int encoded) =>
      Instant.fromDurationSinceUnixEpoch(TimeDelta(seconds: encoded));
}
