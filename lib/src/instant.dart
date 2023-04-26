import 'package:clock/clock.dart';
import 'package:fixed/fixed.dart';
import 'package:meta/meta.dart';
import 'package:oxidized/oxidized.dart';

import 'parser.dart';
import 'plain_date_time.dart';
import 'utils.dart';

@immutable
final class Instant
    with ComparisonOperatorsFromComparable<Instant>
    implements Comparable<Instant> {
  const Instant.fromSecondsSinceUnixEpoch(this.secondsSinceUnixEpoch);

  Instant.fromDateTime(DateTime dateTime)
      : secondsSinceUnixEpoch =
            Fixed.fromInt(dateTime.microsecondsSinceEpoch, scale: 6);
  Instant.now({Clock? clockOverride})
      : this.fromDateTime((clockOverride ?? clock).now());

  factory Instant.fromJson(String json) => unwrapParserResult(parse(json));
  static Result<Instant, FormatException> parse(String value) =>
      Parser.parseInstant(value);

  final Fixed secondsSinceUnixEpoch;

  PlainDateTime get plainDateTimeInLocalZone =>
      PlainDateTime.fromDateTime(dateTimeInLocalZone);
  PlainDateTime get plainDateTimeInUtc =>
      PlainDateTime.fromDateTime(dateTimeInUtc);

  DateTime get dateTimeInLocalZone => _getDateTime(isUtc: false);
  DateTime get dateTimeInUtc => _getDateTime(isUtc: true);
  DateTime _getDateTime({required bool isUtc}) {
    return DateTime.fromMicrosecondsSinceEpoch(
      secondsSinceUnixEpoch.secondsAsMicroseconds,
      isUtc: isUtc,
    );
  }

  @override
  int compareTo(Instant other) =>
      secondsSinceUnixEpoch.compareTo(other.secondsSinceUnixEpoch);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is Instant &&
            secondsSinceUnixEpoch == other.secondsSinceUnixEpoch);
  }

  @override
  int get hashCode => secondsSinceUnixEpoch.hashCode;

  @override
  String toString() => '${plainDateTimeInUtc}Z';

  String toJson() => toString();
}
