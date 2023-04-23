import 'package:meta/meta.dart';
import 'package:oxidized/oxidized.dart';

import 'parser.dart';
import 'plain_date_time.dart';
import 'utils.dart';

@immutable
final class Instant
    with ComparisonOperatorsFromComparable<Instant>
    implements Comparable<Instant> {
  const Instant.fromMicrosecondsSinceUnixEpoch(this.microsecondsSinceUnixEpoch);
  Instant.fromDateTime(DateTime dateTime)
      : microsecondsSinceUnixEpoch = dateTime.microsecondsSinceEpoch;

  factory Instant.fromJson(String json) =>
      parse(json).unwrap(); // TODO: error message
  static Result<Instant, FormatException> parse(String value) =>
      Parser.parseInstant(value);

  final int microsecondsSinceUnixEpoch;

  PlainDateTime get plainDateTimeInLocalZone =>
      PlainDateTime.fromDateTime(dateTimeInLocalZone);
  PlainDateTime get plainDateTimeInUtc =>
      PlainDateTime.fromDateTime(dateTimeInUtc);

  DateTime get dateTimeInLocalZone {
    return DateTime.fromMicrosecondsSinceEpoch(
      microsecondsSinceUnixEpoch,
      isUtc: false,
    );
  }

  DateTime get dateTimeInUtc {
    return DateTime.fromMicrosecondsSinceEpoch(
      microsecondsSinceUnixEpoch,
      isUtc: true,
    );
  }

  @override
  int compareTo(Instant other) =>
      microsecondsSinceUnixEpoch.compareTo(other.microsecondsSinceUnixEpoch);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is Instant &&
            microsecondsSinceUnixEpoch == other.microsecondsSinceUnixEpoch);
  }

  @override
  int get hashCode => microsecondsSinceUnixEpoch.hashCode;

  @override
  String toString() => '${plainDateTimeInUtc}Z';

  String toJson() => toString();
}
