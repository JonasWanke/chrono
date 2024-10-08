# Chrono

**⚠️ Work in Progress ⚠️**

Chrono is a date and time package for Dart supporting all platforms.
It offers strongly-typed data classes for timestamps, timezone-independent (plain/local) date and time, as well as different durations based on the [proleptic Gregorian calendar], including:

- arithmetic operations and conversions
- parsing and formatting for a subset of [ISO 8601], [RFC 3339], and [CC 18011:2018]
  - this is implemented for [`Instant`] and the date/time classes, but still missing for durations

The following features are _not_ implemented, but could be added in the future:

- timezone support (work in progress)
- customizable parsing and formatting
- internationalization
- leap second support

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

## Timestamps

A timestamp is a unique point on the UTC timeline, stored as the duration since the [Unix epoch].
Chrono provides these classes:

- [`UnixEpochTimestamp<D>`], generic over a [`TimeDuration`] type
  - [`Instant`]: a subclass with arbitrary precision
  - [`UnixEpochNanoseconds`]: a subclass with nanosecond precision
  - [`UnixEpochMicroseconds`]: a subclass with microsecond precision
  - [`UnixEpochMilliseconds`]: a subclass with millisecond precision
  - [`UnixEpochSeconds`]: a subclass with second precision

If you want to store the exact point in time when something happened, e.g., when a message in a chat app was sent, one of these classes is usually the best choice.
The specific one is up to you, based on how precise you want to be.

Past dates (e.g., birthdays) should rather be represented as a [`Date`].
Future timestamps, e.g., for scheduling a meeting, should rather be represented as a [`DateTime`] and the corresponding timezone.

## Date and Time

[`DateTime`] combines [`Date`] and [`Time`] without timezone information.
This is also called plain or local time [in other languages](#comparison-to-other-languages).

For example, April 23, 2023, at 18:24:20 happened at different moments in different time zones.
In Chrono's classes, it would be represented as:

![`DateTime` classes visualization](doc/DateTime%20classes%20visualization.svg)

| Class         | Encoding                                  |
| :------------ | :---------------------------------------- |
| [`DateTime`]  | `2023-04-23T18:24:20`                     |
| [`Date`]      | `2023-04-23`, `2023-113`, or `2023-W16-7` |
| [`Year`]      | 2023                                      |
| [`Month`]     | 4                                         |
| [`YearMonth`] | `2023-04`                                 |
| [`MonthDay`]  | `--04-23`                                 |
| [`YearWeek`]  | `2023-W16`                                |
| [`Weekday`]   | 7                                         |
| [`Time`]      | `18:24:20`                                |

### 📅 [`Date`]

An ISO 8601 calendar date without timezone information, e.g., April 23, 2023.

- [`Year`]: year in the ISO 8601 calendar (see the class documentation for representation of BCE years)
- [`Month`]: enum of months
- [`Weekday`]: enum of weekdays
- [`YearMonth`]: [`Year`] + [`Month`], e.g., for getting the length of a month honoring leap years
- [`MonthDay`]: [`Month`] + [`Day`], e.g., for representing birthdays without a year (February 29 is allowed)
- [`YearWeek`]: [`Year`] + [ISO week] from Monday to Sunday

### ⌚ [`Time`]

An ISO 8601 time without timezone information, e.g., 18:24:20.123456.

Since fractional seconds are represented using the fixed-point number [`Fixed`] class of the package [<kbd>fixed</kbd>], there's basically no limit to the precision.

Chrono does not support leap seconds:
It assumes that all minutes are 60 seconds long.

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

The [`Duration`] class from Dart Core corresponds to [`TimeDuration`]/[`FractionalSeconds`], but limited to microsecond precision.

Some duration classes also have a corresponding `…Duration` class, e.g., [`Minutes`] and [`MinutesDuration`].
[`MinutesDuration`] is an abstract base class for all time-based durations consisting of a whole number of minutes.
[`Minutes`] is a concrete class extending [`MinutesDuration`].
When constructing or returning values, you should use [`Minutes`] directly.
However, in parameters, you should accept any [`MinutesDuration`].
This way, callers can pass not only [`Minutes`], but also [`Hours`].
To convert this to [`Minutes`], call `asMinutes`.

### Compound Durations

[`CompoundDuration`] and [`CompoundDaysDuration`] can represent values with mixed signs, e.g., -1 month and 1 day.

When performing additions and subtractions with compound durations, first the [`Months`] are evaluated, then the [`Days`], and finally the [`FractionalSeconds`].
For example, adding 1 month and -1 day to 2023-08-31 results in 2023-09-29:

1. First, 1 month is added, resulting in 2023-09-30.
   (September only has 30 days, so the day is clamped.)
2. Then, 1 day is subtracted, resulting in 2023-09-29.

(If the order of operations was reversed, the result would be 2023-09-30.)

## Serialization

All timestamp, date, and time classes support JSON serialization.
(Support for durations will be added in the future.)

Because there are often multiple possibilities of how to encode a value, Chono lets you choose the format:
There are subclasses of [`JsonConverter`] for each class called `<Chrono type>As<JSON type>JsonConverter`, e.g., [`DateTimeAsIsoStringJsonConverter`].
These are all converters and how they encode February 3, 2001, at 4:05:06.007008009 UTC:

|                                   Converter class | Encoding example                   |
| ------------------------------------------------: | :--------------------------------- |
|               [`InstantAsIsoStringJsonConverter`] | `"2001-02-03T04:05:06.007008009Z"` |
|  [`UnixEpochNanosecondsAsIsoStringJsonConverter`] | `"2001-02-03T04:05:06.007008009Z"` |
|        [`UnixEpochNanosecondsAsIntJsonConverter`] | `981173106007008009`               |
| [`UnixEpochMicrosecondsAsIsoStringJsonConverter`] | `"2001-02-03T04:05:06.007008Z"`    |
|       [`UnixEpochMicrosecondsAsIntJsonConverter`] | `981173106007008`                  |
| [`UnixEpochMillisecondsAsIsoStringJsonConverter`] | `"2001-02-03T04:05:06.007Z"`       |
|       [`UnixEpochMillisecondsAsIntJsonConverter`] | `981173106007`                     |
|      [`UnixEpochSecondsAsIsoStringJsonConverter`] | `"2001-02-03T04:05:06Z"`           |
|            [`UnixEpochSecondsAsIntJsonConverter`] | `981173106`                        |
|              [`DateTimeAsIsoStringJsonConverter`] | `"2001-02-03T04:05:06.007"`        |
|                  [`DateAsIsoStringJsonConverter`] | `"2001-02-03"`                     |
|       [`DateAsOrdinalDateIsoStringJsonConverter`] | `"2001-034"`                       |
|          [`DateAsWeekDateIsoStringJsonConverter`] | `"2001-W05-6"`                     |
|                  [`YearAsIsoStringJsonConverter`] | `"2001"`                           |
|                        [`YearAsIntJsonConverter`] | `2001`                             |
|                       [`MonthAsIntJsonConverter`] | `2`                                |
|             [`YearMonthAsIsoStringJsonConverter`] | `"2001-02"`                        |
|              [`MonthDayAsIsoStringJsonConverter`] | `"--02-03"`                        |
|              [`YearWeekAsIsoStringJsonConverter`] | `"2001-W05"`                       |
|                     [`WeekdayAsIntJsonConverter`] | `6`                                |
|                  [`TimeAsIsoStringJsonConverter`] | `"04:05:06.007"`                   |

### [<kbd>json_serializable</kbd>]

If you use [<kbd>json_serializable</kbd>], you can choose between the following approaches:

1. Annotate your field with the converter you want to use:

   ```dart
   @JsonSerializable()
   class MyClass {
     const MyClass(this.value);

     factory MyClass.fromJson(Map<String, dynamic> json) =>
         _$MyClassFromJson(json);

     @DateTimeAsIsoStringJsonConverter()
     final DateTime value;

     Map<String, dynamic> toJson() => _$MyClassToJson(this);
   }
   ```

2. Specify the converter in the [`JsonSerializable`] annotation so it applies to all fields in that class:

   ```dart
   @JsonSerializable(converters: [DateTimeAsIsoStringJsonConverter()])
   class MyClass {
     // ...
   }
   ```

3. Create a customized instance of [`JsonSerializable`] that you can reuse for all your classes:

   ```dart
   const jsonSerializable = JsonSerializable(converters: [DateTimeAsIsoStringJsonConverter()]);

   @jsonSerializable
   class MyClass {
     // ...
   }
   ```

You can also combine these approaches:
For example, create a customized [`JsonSerializable`] instance with your defaults (approach 3) and overwrite the converter individual fields (approach 1).

## Testing

All functions that are based on the current time accept an optional [`Clock`] parameter.
Please have a look at the [<kbd>clock</kbd>] package for how this can be used to overwrite the time during tests.

Chrono uses [<kbd>Glados</kbd>] for property-based testing.

## Comparison to other languages

| Dart: `chrono`                             | Java/Kotlin     | Rust                               |
| :----------------------------------------- | :-------------- | :--------------------------------- |
| [`UnixEpochTimestamp<D>`]                  | —               | —                                  |
| [`Instant`]                                | —               | —                                  |
| [`UnixEpochNanoseconds`]                   | `Instant`       | `std::time::{Instant, SystemTime}` |
| [`UnixEpochMicroseconds`]                  | —               | —                                  |
| [`UnixEpochMilliseconds`]                  | —               | —                                  |
| [`UnixEpochSeconds`]                       | —               | —                                  |
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
[`DateAsIsoStringJsonConverter`]: https://pub.dev/documentation/chrono/latest/chrono/DateAsIsoStringJsonConverter-class.html
[`DateAsOrdinalDateIsoStringJsonConverter`]: https://pub.dev/documentation/chrono/latest/chrono/DateAsOrdinalDateIsoStringJsonConverter-class.html
[`DateAsWeekDateIsoStringJsonConverter`]: https://pub.dev/documentation/chrono/latest/chrono/DateAsWeekDateIsoStringJsonConverter-class.html
[`DateDuration`]: https://pub.dev/documentation/chrono/latest/chrono/DateDuration-class.html
[`DateTime`]: https://pub.dev/documentation/chrono/latest/chrono/DateTime-class.html
[`DateTimeAsIsoStringJsonConverter`]: https://pub.dev/documentation/chrono/latest/chrono/DateTimeAsIsoStringJsonConverter-class.html
[`Days`]: https://pub.dev/documentation/chrono/latest/chrono/Days-class.html
[`Duration`]: https://pub.dev/documentation/chrono/latest/chrono/Duration-class.html
[`FixedDaysDuration`]: https://pub.dev/documentation/chrono/latest/chrono/FixedDaysDuration-class.html
[`FractionalSeconds`]: https://pub.dev/documentation/chrono/latest/chrono/FractionalSeconds-class.html
[`Hours`]: https://pub.dev/documentation/chrono/latest/chrono/Hours-class.html
[`Instant`]: https://pub.dev/documentation/chrono/latest/chrono/Instant-class.html
[`InstantAsIsoStringJsonConverter`]: https://pub.dev/documentation/chrono/latest/chrono/InstantAsIsoStringJsonConverter-class.html
[`Microseconds`]: https://pub.dev/documentation/chrono/latest/chrono/Microseconds-class.html
[`Milliseconds`]: https://pub.dev/documentation/chrono/latest/chrono/Milliseconds-class.html
[`Minutes`]: https://pub.dev/documentation/chrono/latest/chrono/Minutes-class.html
[`MinutesDuration`]: https://pub.dev/documentation/chrono/latest/chrono/MinutesDuration-class.html
[`Month`]: https://pub.dev/documentation/chrono/latest/chrono/Month-class.html
[`MonthAsIntJsonConverter`]: https://pub.dev/documentation/chrono/latest/chrono/MonthAsIntJsonConverter-class.html
[`MonthDay`]: https://pub.dev/documentation/chrono/latest/chrono/MonthDay-class.html
[`MonthDayAsIsoStringJsonConverter`]: https://pub.dev/documentation/chrono/latest/chrono/MonthDayAsIsoStringJsonConverter-class.html
[`Months`]: https://pub.dev/documentation/chrono/latest/chrono/Months-class.html
[`MonthsDuration`]: https://pub.dev/documentation/chrono/latest/chrono/MonthsDuration-class.html
[`Nanoseconds`]: https://pub.dev/documentation/chrono/latest/chrono/Nanoseconds-class.html
[`Seconds`]: https://pub.dev/documentation/chrono/latest/chrono/Seconds-class.html
[`Time`]: https://pub.dev/documentation/chrono/latest/chrono/Time-class.html
[`TimeAsIsoStringJsonConverter`]: https://pub.dev/documentation/chrono/latest/chrono/TimeAsIsoStringJsonConverter-class.html
[`TimeDuration`]: https://pub.dev/documentation/chrono/latest/chrono/TimeDuration-class.html
[`UnixEpochMicroseconds`]: https://pub.dev/documentation/chrono/latest/chrono/UnixEpochMicroseconds-class.html
[`UnixEpochMicrosecondsAsIntJsonConverter`]: https://pub.dev/documentation/chrono/latest/chrono/UnixEpochMicrosecondsAsIntJsonConverter-class.html
[`UnixEpochMicrosecondsAsIsoStringJsonConverter`]: https://pub.dev/documentation/chrono/latest/chrono/UnixEpochMicrosecondsAsIsoStringJsonConverter-class.html
[`UnixEpochMilliseconds`]: https://pub.dev/documentation/chrono/latest/chrono/UnixEpochMilliseconds-class.html
[`UnixEpochMillisecondsAsIntJsonConverter`]: https://pub.dev/documentation/chrono/latest/chrono/UnixEpochMillisecondsAsIntJsonConverter-class.html
[`UnixEpochMillisecondsAsIsoStringJsonConverter`]: https://pub.dev/documentation/chrono/latest/chrono/UnixEpochMillisecondsAsIsoStringJsonConverter-class.html
[`UnixEpochNanoseconds`]: https://pub.dev/documentation/chrono/latest/chrono/UnixEpochNanoseconds-class.html
[`UnixEpochNanosecondsAsIntJsonConverter`]: https://pub.dev/documentation/chrono/latest/chrono/UnixEpochNanosecondsAsIntJsonConverter-class.html
[`UnixEpochNanosecondsAsIsoStringJsonConverter`]: https://pub.dev/documentation/chrono/latest/chrono/UnixEpochNanosecondsAsIsoStringJsonConverter-class.html
[`UnixEpochSeconds`]: https://pub.dev/documentation/chrono/latest/chrono/UnixEpochSeconds-class.html
[`UnixEpochSecondsAsIntJsonConverter`]: https://pub.dev/documentation/chrono/latest/chrono/UnixEpochSecondsAsIntJsonConverter-class.html
[`UnixEpochSecondsAsIsoStringJsonConverter`]: https://pub.dev/documentation/chrono/latest/chrono/UnixEpochSecondsAsIsoStringJsonConverter-class.html
[`UnixEpochTimestamp<D>`]: https://pub.dev/documentation/chrono/latest/chrono/UnixEpochTimestamp-class.html
[`Weekday`]: https://pub.dev/documentation/chrono/latest/chrono/Weekday-class.html
[`WeekdayAsIntJsonConverter`]: https://pub.dev/documentation/chrono/latest/chrono/WeekdayAsIntJsonConverter-class.html
[`Weeks`]: https://pub.dev/documentation/chrono/latest/chrono/Weeks-class.html
[`Year`]: https://pub.dev/documentation/chrono/latest/chrono/Year-class.html
[`YearAsIntJsonConverter`]: https://pub.dev/documentation/chrono/latest/chrono/YearAsIntJsonConverter-class.html
[`YearAsIsoStringJsonConverter`]: https://pub.dev/documentation/chrono/latest/chrono/YearAsIsoStringJsonConverter-class.html
[`YearMonth`]: https://pub.dev/documentation/chrono/latest/chrono/YearMonth-class.html
[`YearMonthAsIsoStringJsonConverter`]: https://pub.dev/documentation/chrono/latest/chrono/YearMonthAsIsoStringJsonConverter-class.html
[`Years`]: https://pub.dev/documentation/chrono/latest/chrono/Years-class.html
[`YearWeek`]: https://pub.dev/documentation/chrono/latest/chrono/YearWeek-class.html
[`YearWeekAsIsoStringJsonConverter`]: https://pub.dev/documentation/chrono/latest/chrono/YearWeekAsIsoStringJsonConverter-class.html

<!-- clock -->

[<kbd>clock</kbd>]: https://pub.dev/packages/clock
[`Clock`]: https://pub.dev/documentation/clock/latest/clock/Clock-class.html

<!-- fixed -->

[<kbd>fixed</kbd>]: https://pub.dev/packages/fixed
[`Fixed`]: https://pub.dev/documentation/fixed/latest/fixed/Fixed-class.html

<!-- glados -->

[<kbd>glados</kbd>]: https://pub.dev/packages/glados

<!-- json_annotation -->

[`JsonConverter`]: https://pub.dev/documentation/json_annotation/latest/json_annotation/JsonConverter-class.html

<!-- json_serializable -->

[<kbd>json_serializable</kbd>]: https://pub.dev/packages/json_serializable
[`JsonSerializable`]: https://pub.dev/documentation/json_annotation/4.8.1/json_annotation/JsonSerializable-class.html

<!-- external -->

[CC 18011:2018]: https://standards.calconnect.org/csd/cc-18011.html
[ISO 8601]: https://en.wikipedia.org/wiki/ISO_8601
[ISO week]: https://en.wikipedia.org/wiki/ISO_week_date
[Proleptic Gregorian calendar]: https://en.wikipedia.org/wiki/Proleptic_Gregorian_calendar
[RFC 3339]: https://datatracker.ietf.org/doc/html/rfc3339
[Unix epoch]: https://en.wikipedia.org/wiki/Unix_time
