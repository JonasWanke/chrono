import 'package:meta/meta.dart';
import 'package:oxidized/oxidized.dart';

import '../duration.dart';
import '../weekday.dart';

@immutable
class WeekConfig {
  static Result<WeekConfig, String> from({
    required Weekday firstDay,
    required int minDaysInFirstWeek,
  }) {
    if (minDaysInFirstWeek < 1 || minDaysInFirstWeek > Days.perWeek) {
      return Err('Invalid `minDaysInFirstWeek`: $minDaysInFirstWeek');
    }
    return Ok(
      WeekConfig._(firstDay: firstDay, minDaysInFirstWeek: minDaysInFirstWeek),
    );
  }

  const WeekConfig._({
    required this.firstDay,
    required this.minDaysInFirstWeek,
  });

  static const iso = WeekConfig._(
    firstDay: Weekday.monday,
    minDaysInFirstWeek: 4,
  );

  final Weekday firstDay;
  final int minDaysInFirstWeek;

  Result<WeekConfig, String> copyWith({
    Weekday? firstDay,
    int? minDaysInFirstWeek,
  }) {
    return WeekConfig.from(
      firstDay: firstDay ?? this.firstDay,
      minDaysInFirstWeek: minDaysInFirstWeek ?? this.minDaysInFirstWeek,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is WeekConfig &&
            firstDay == other.firstDay &&
            minDaysInFirstWeek == other.minDaysInFirstWeek);
  }

  @override
  int get hashCode =>
      Object.hash(firstDay.hashCode, minDaysInFirstWeek.hashCode);

  @override
  String toString() {
    return 'WeekConfig(firstDay: $firstDay, '
        'minDaysInFirstWeek: $minDaysInFirstWeek)';
  }
}
