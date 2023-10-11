# Chrono

**⚠️ Work in Progress ⚠️**

Chrono is a date and time package for Dart supporting all platforms.
It offers strongly-typed data classes for timezone-independent (plain/local) date, time, and different durations based on the [proleptic Gregorian calendar], including:

- arithmetic operations and conversions
- parsing and formatting for a subset of [ISO 8601], [RFC 3339], and [CC 18011:2018]
  - this is implemented for [`Instant`] and the date/time classes, but still missing for durations
  - these classes also have `toJson()`/`fromJson()` functions

The following features are _not_ implemented, but could be added in the future:

- timezone support
- customizable parsing and formatting
- internationalization

## Usage

Since Dart Core also provides classes called `DateTime` and `Duration`, you might have to add `import 'package:chrono/chrono.dart';` manually.
If you want to use classes from both sources, you can use an import prefix:

```dart
import 'dart:core' as core;
import 'package:chrono/chrono.dart';

void main() {
  final dartCoreDateTime = core.DateTime.now();
  final chronoDateTime = DateTime.nowInLocalZone();
}
```

## [`Instant`]

An [`Instant`] is a unique point on the UTC timeline with unlimited precision.

If you want to store the exact point in time when something happened, this is usually the best choice.
For example, the timestamp of a message in a chat app should be stored as an [`Instant`].

Past dates (e.g., birthdays) should rather be represented as a [`Date`].
Future timestamps, e.g., for scheduling a meeting, should rather be represented as a [`DateTime`] and the corresponding timezone.

## Date and Time

[`DateTime`] combines [`Date`] and [`Time`] without timezone information.
This is also called plain or local time [in other languages](#comparison-to-other-languages).

For example, April 23, 2023 at 18:24:20 happened at different moments in different time zones.
In Chrono's classes, it would be represented as:

![`DateTime` classes visualization](doc/DateTime%20classes%20visualization.svg)

| Class         | Encoding              |
| :------------ | :-------------------- |
| `DateTime`    | `2023-04-23T18:24:20` |
| `Date`        | `2023-04-23`          |
| `Year`        | 2023                  |
| `Month`       | 4                     |
| `YearMonth`   | `2023-04`             |
| `MonthDay`    | `--04-23`             |
| `OrdinalDate` | `2023-113`            |
| `WeekDate`    | `2023-W16-7`          |
| `YearWeek`    | `2023-W16`            |
| `Weekday`     | 7                     |
| `Time`        | `18:24:20`            |

### 📅 [`Date`]

An ISO 8601 calendar date without timezone information, e.g., April 23, 2023.

Dates can be represented by three different classes:

|           Class | Components                          | Conversion       | Encoding     |
| --------------: | :---------------------------------- | :--------------- | :----------- |
|        [`Date`] | [`Year`] + [`Month`] + day of month | `.asDate`        | `2023-04-23` |
|    [`WeekDate`] | [`YearWeek`] + [`Weekday`]          | `.asWeekDate`    | `2023-W16-7` |
| [`OrdinalDate`] | [`Year`] + day of year              | `.asOrdinalDate` | `2023-113`   |

- `Year`: year in the ISO 8601 calendar (see the class documentation for representation of BCE years)
- `Month`: enum of months
- `Weekday`: enum of weekdays
- `YearMonth`: `Year` + `Month`, e.g., for getting the length of a month honoring leap years
- `MonthDay`: `Month` + `Day`, e.g., for representing birthdays without a year (February 29 is allowed)
- `YearWeek`: `Year` + [ISO week] from Monday to Sunday

### ⌚ [`Time`]

An ISO 8601 time without timezone information, e.g., 18:24:20.123456.

Since fractional seconds are represented using the fixed-point number [`Fixed`], there's basically no limit to the precision.

TODO: document no leap second support

## Durations

Durations fall into three categories:

- time-based durations, e.g., 1 hour
- day-based durations, e.g., 2 days
- month-based durations, e.g., 3 months

One day is not always 24 hours long (due to daylight savings time changes), and one month is not always 30/31 days long (due to leap years and different month lengths).
Chrono offers different classes for each category (listed by inheritance):

- [`Duration`]: abstract base class
  - [`TimeDuration`]: time-based durations: hours, minutes, seconds, milliseconds, etc.
    - [`FractionalSeconds`]: fractional number of seconds with unlimited precision (using [`Fixed`])
    - [`Hours`], [`Minutes`], [`Seconds`], [`Milliseconds`], [`Microseconds`], [`Nanoseconds`]: a whole number of hours/etc.
  - [`DateDuration`]: day- and month-based durations
    - [`FixedDaysDuration`]: day-based durations, can be [`Days`] or [`Weeks`]
    - [`MonthsDuration`]: month-based durations, can be [`Months`] or [`Years`]
    - [`CompoundDaysDuration`]: [`Months`] + [`Days`]
  - [`CompoundDuration`]: [`Months`] + [`Days`] + [`FractionalSeconds`]

The `Duration` class from Dart Core corresponds to [`TimeDuration`]/[`FractionalSeconds`], but limited to microsecond precision.

Some duration classes also have a corresponding `…Duration` class, e.g., [`Minutes`] and [`MinutesDuration`].
[`MinutesDuration`] is an abstract base class for all time-based durations consisting of a whole number of minutes.
[`Minutes`] is a concrete class extending [`MinutesDuration`].
When constructing or returning values, you should use [Minutes] directly.
However, in parameters, you should accept any [`MinutesDuration`].
This way, callers can pass not only [`Minutes`], but also [`Hours`].
To convert this to [`Minutes`], call `asMinutes`

### Compound Durations

[`CompoundDuration`] and [`CompoundDaysDuration`] can represent values with mixed signs, e.g., -1 month and 1 day.

When performing additions and subtractions with compound durations, first the [`Months`] are evaluated, then the [`Days`], and finally the [`FractionalSeconds`].
For example, adding 1 month and -1 day to 2023-08-31 results in 2023-09-29:

1. First, 1 month is added, resulting in 2023-09-30.
   (September only has 30 days, so the day is clamped.)
2. Then, 1 day is subtracted, resulting in 2023-09-29.

(If the order of operations was reversed, the result would be 2023-09-30.)

## Comparison to other languages

| Dart: `chrono`                             | Java/Kotlin     | Rust                               |
| :----------------------------------------- | :-------------- | :--------------------------------- |
| [`Instant`]                                | `Instant`       | `std::time::{Instant, SystemTime}` |
| [`DateTime`]                               | `LocalDateTime` | `chrono::NaiveDateTime`            |
| [`Date`]                                   | `LocalDate`     | `chrono::NaiveDate`                |
| [`Year`]                                   | `Year`          | —                                  |
| [`YearMonth`]                              | `YearMonth`     | —                                  |
| [`Month`]                                  | `Month`         | `chrono::Month`                    |
| [`MonthDay`]                               | `MonthDay`      | —                                  |
| [`YearWeek`]                               | —               | `chrono::IsoWeek`                  |
| [`Weekday`]                                | `DayOfWeek`     | `chrono::Weekday`                  |
| [`Time`]                                   | `LocalTime`     | `chrono::NaiveTime`                |
| [`DateDuration`]                           | `Period`        | —                                  |
| [`MonthsDuration`], [`Months`], [`Years`]  | —               | `chrono::Months`                   |
| [`FixedDaysDuration`], [`Days`], [`Weeks`] | —               | `chrono::Days`                     |
| [`TimeDuration`]                           | `Duration`      | `std::time::Duration`              |
| [`Clock`] (from [<kbd>clock</kbd>])        | `Clock`         | —                                  |

<!-- chrono -->

[`CompoundDaysDuration`]: https://pub.dev/documentation/chrono/latest/chrono/CompoundDaysDuration-class.html
[`CompoundDuration`]: https://pub.dev/documentation/chrono/latest/chrono/CompoundDuration-class.html
[`Date`]: https://pub.dev/documentation/chrono/latest/chrono/Date-class.html
[`DateDuration`]: https://pub.dev/documentation/chrono/latest/chrono/DateDuration-class.html
[`DateTime`]: https://pub.dev/documentation/chrono/latest/chrono/DateTime-class.html
[`Days`]: https://pub.dev/documentation/chrono/latest/chrono/Days-class.html
[`Duration`]: https://pub.dev/documentation/chrono/latest/chrono/Duration-class.html
[`FixedDaysDuration`]: https://pub.dev/documentation/chrono/latest/chrono/FixedDaysDuration-class.html
[`FractionalSeconds`]: https://pub.dev/documentation/chrono/latest/chrono/FractionalSeconds-class.html
[`Hours`]: https://pub.dev/documentation/chrono/latest/chrono/Hours-class.html
[`Instant`]: https://pub.dev/documentation/chrono/latest/chrono/Instant-class.html
[`Microseconds`]: https://pub.dev/documentation/chrono/latest/chrono/Microseconds-class.html
[`Milliseconds`]: https://pub.dev/documentation/chrono/latest/chrono/Milliseconds-class.html
[`Minutes`]: https://pub.dev/documentation/chrono/latest/chrono/Minutes-class.html
[`MinutesDuration`]: https://pub.dev/documentation/chrono/latest/chrono/MinutesDuration-class.html
[`Month`]: https://pub.dev/documentation/chrono/latest/chrono/Month-class.html
[`MonthDay`]: https://pub.dev/documentation/chrono/latest/chrono/MonthDay-class.html
[`Months`]: https://pub.dev/documentation/chrono/latest/chrono/Months-class.html
[`MonthsDuration`]: https://pub.dev/documentation/chrono/latest/chrono/MonthsDuration-class.html
[`Nanoseconds`]: https://pub.dev/documentation/chrono/latest/chrono/Nanoseconds-class.html
[`OrdinalDate`]: https://pub.dev/documentation/chrono/latest/chrono/OrdinalDate-class.html
[`Seconds`]: https://pub.dev/documentation/chrono/latest/chrono/Seconds-class.html
[`Time`]: https://pub.dev/documentation/chrono/latest/chrono/Time-class.html
[`TimeDuration`]: https://pub.dev/documentation/chrono/latest/chrono/TimeDuration-class.html
[`WeekDate`]: https://pub.dev/documentation/chrono/latest/chrono/WeekDate-class.html
[`Weekday`]: https://pub.dev/documentation/chrono/latest/chrono/Weekday-class.html
[`Weeks`]: https://pub.dev/documentation/chrono/latest/chrono/Weeks-class.html
[`Year`]: https://pub.dev/documentation/chrono/latest/chrono/Year-class.html
[`YearMonth`]: https://pub.dev/documentation/chrono/latest/chrono/YearMonth-class.html
[`Years`]: https://pub.dev/documentation/chrono/latest/chrono/Years-class.html
[`YearWeek`]: https://pub.dev/documentation/chrono/latest/chrono/YearWeek-class.html

<!-- clock -->

[<kbd>clock</kbd>]: https://pub.dev/packages/clock
[`Clock`]: https://pub.dev/documentation/clock/latest/clock/Clock-class.html

<!-- fixed -->

[`Fixed`]: https://pub.dev/documentation/fixed/latest/fixed/Fixed-class.html

<!-- external -->

[CC 18011:2018]: https://standards.calconnect.org/csd/cc-18011.html
[ISO 8601]: https://en.wikipedia.org/wiki/ISO_8601
[ISO week]: https://en.wikipedia.org/wiki/ISO_week_date
[Proleptic Gregorian calendar]: https://en.wikipedia.org/wiki/Proleptic_Gregorian_calendar
[RFC 3339]: https://datatracker.ietf.org/doc/html/rfc3339
