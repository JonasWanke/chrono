import 'package:meta/meta.dart';

import '../duration.dart';
import '../weekday.dart';

@immutable
class WeekConfig {
  factory WeekConfig.from({
    required Weekday firstDay,
    required int minDaysInFirstWeek,
  }) {
    RangeError.checkValueInInterval(
      minDaysInFirstWeek,
      1,
      Days.perWeek,
      'minDaysInFirstWeek',
    );
    return WeekConfig._unchecked(
      firstDay: firstDay,
      minDaysInFirstWeek: minDaysInFirstWeek,
    );
  }

  const WeekConfig._unchecked({
    required this.firstDay,
    required this.minDaysInFirstWeek,
  });

  static const iso = WeekConfig._unchecked(
    firstDay: Weekday.monday,
    minDaysInFirstWeek: 4,
  );

  final Weekday firstDay;
  final int minDaysInFirstWeek;

  WeekConfig copyWith({Weekday? firstDay, int? minDaysInFirstWeek}) {
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
