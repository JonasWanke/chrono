import 'dart:core';
import 'dart:core' as core;

import 'package:clock/clock.dart';
import 'package:meta/meta.dart';
import 'package:oxidized/oxidized.dart';

import '../parser.dart';
import '../time/duration.dart';
import '../utils.dart';
import 'date_time.dart';

@immutable
final class Instant
    with ComparisonOperatorsFromComparable<Instant>
    implements Comparable<Instant> {
  const Instant.fromSecondsSinceUnixEpoch(this.secondsSinceUnixEpoch);

  Instant.fromCore(core.DateTime dateTime)
      : secondsSinceUnixEpoch =
            FractionalSeconds.microsecond * dateTime.microsecondsSinceEpoch;
  Instant.now({Clock? clockOverride})
      : this.fromCore((clockOverride ?? clock).now());

  factory Instant.fromJson(String json) => unwrapParserResult(parse(json));
  static Result<Instant, FormatException> parse(String value) =>
      Parser.parseInstant(value);

  final FractionalSeconds secondsSinceUnixEpoch;

  DateTime get dateTimeInLocalZone =>
      DateTime.fromCore(asCoreDateTimeInLocalZone);
  DateTime get dateTimeInUtc => DateTime.fromCore(asCoreDateTimeInUtc);

  core.DateTime get asCoreDateTimeInLocalZone => _getDateTime(isUtc: false);
  core.DateTime get asCoreDateTimeInUtc => _getDateTime(isUtc: true);
  core.DateTime _getDateTime({required bool isUtc}) {
    return core.DateTime.fromMicrosecondsSinceEpoch(
      secondsSinceUnixEpoch.asMicrosecondsRounded,
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
  String toString() => '${dateTimeInUtc}Z';

  String toJson() => toString();
}
