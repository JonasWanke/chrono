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

## Timestamps

A timestamp is a unique point on the UTC timeline, stored as the duration since the [Unix epoch].
Chrono provides these classes:

- [`UnixEpochTimestamp<D>`], generic over a [`TimeDuration`] type
  - [`Instant`]: a subclass with nanosecond precision
  - [`UnixEpochMicroseconds`]: a subclass with microsecond precision
  - [`UnixEpochMilliseconds`]: a subclass with millisecond precision
  - [`UnixEpochSeconds`]: a subclass with second precision

If you want to store the exact point in time when something happened, e.g., when a message in a chat app was sent, one of these classes is usually the best choice.
The specific one is up to you, based on how precise you want to be.

Past dates (e.g., birthdays) should rather be represented as a [`Date`].
Future timestamps, e.g., for scheduling a meeting, should rather be represented as a [`CDateTime`] and the corresponding timezone.

## Date and Time

[`CDateTime`] combines [`Date`] and [`Time`] without timezone information.
This is also called plain or local time [in other languages](#comparison-to-other-languages).

For example, April 23, 2023, at 18:24:20 happened at different moments in different time zones.
In Chrono's classes, it would be represented as:

![date and time classes visualization](doc/DateTime%20classes%20visualization.svg)

| Class         | Encoding                                  |
| :------------ | :---------------------------------------- |
| [`CDateTime`] | `2023-04-23T18:24:20`                     |
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

The maximum precision is nanoseconds.

Chrono does not support leap seconds:
It assumes that all minutes are 60 seconds long.

## Durations

Durations fall into three categories:

- time-based durations, e.g., 1 hour
- day-based durations, e.g., 2 days
- month-based durations, e.g., 3 months

One day is not always 24 hours long (due to daylight savings time changes), and one month is not always 30/31 days long (due to leap years and different month lengths).
Chrono offers different classes for each category (listed by inheritance):

- [`CDuration`]: abstract base class
  - [`TimeDuration`]: time-based durations: hours, minutes, seconds, milliseconds, etc.
    - [`Hours`], [`Minutes`], [`Seconds`], [`Milliseconds`], [`Microseconds`], [`Nanoseconds`]: a whole number of hours/etc.
  - [`CalendarDuration`]: day- and month-based durations
    - [`DaysDuration`]: day-based durations, can be [`Days`] or [`Weeks`]
    - [`MonthsDuration`]: month-based durations, can be [`Months`] or [`Years`]
    - [`CompoundCalendarDuration`]: [`Months`] + [`Days`]
  - [`CompoundDuration`]: [`Months`] + [`Days`] + [`Nanoseconds`]

The [`CDuration`] class from Dart Core corresponds to [`TimeDuration`], but limited to microsecond precision.

Some duration classes also have a corresponding `…Duration` class, e.g., [`Minutes`] and [`MinutesDuration`].
[`MinutesDuration`] is an abstract base class for all time-based durations consisting of a whole number of minutes.
[`Minutes`] is a concrete class extending [`MinutesDuration`].
When constructing or returning values, you should use [`Minutes`] directly.
However, in parameters, you should accept any [`MinutesDuration`].
This way, callers can pass not only [`Minutes`], but also [`Hours`].
To convert this to [`Minutes`], call `asMinutes`.

### Compound Durations

[`CompoundDuration`] and [`CompoundCalendarDuration`] can represent values with mixed signs, e.g., -1 month and 1 day.

When performing additions and subtractions with compound durations, first the [`Months`] are evaluated, then the [`Days`], and finally the [`Nanoseconds`].
For example, adding 1 month and -1 day to 2023-08-31 results in 2023-09-29:

1. First, 1 month is added, resulting in 2023-09-30.
   (September only has 30 days, so the day is clamped.)
2. Then, 1 day is subtracted, resulting in 2023-09-29.

(If the order of operations was reversed, the result would be 2023-09-30.)

## Serialization

All timestamp, date, and time classes support JSON serialization.
(Support for durations will be added in the future.)

Because there are often multiple possibilities of how to encode a value, Chrono lets you choose the format:
There are subclasses of [`JsonConverter`] for each class called `<Chrono type>As<JSON type>Codec`, e.g., [`CDateTimeAsIsoStringCodec`].
These are all converters and how they encode February 3, 2001, at 4:05:06.007008009 UTC:

|                           Converter class | Encoding example                   |
| ----------------------------------------: | :--------------------------------- |
|               [`InstantAsIsoStringCodec`] | `"2001-02-03T04:05:06.007008009Z"` |
|                     [`InstantAsIntCodec`] | `981173106007008009`               |
| [`UnixEpochMicrosecondsAsIsoStringCodec`] | `"2001-02-03T04:05:06.007008Z"`    |
|       [`UnixEpochMicrosecondsAsIntCodec`] | `981173106007008`                  |
| [`UnixEpochMillisecondsAsIsoStringCodec`] | `"2001-02-03T04:05:06.007Z"`       |
|       [`UnixEpochMillisecondsAsIntCodec`] | `981173106007`                     |
|      [`UnixEpochSecondsAsIsoStringCodec`] | `"2001-02-03T04:05:06Z"`           |
|            [`UnixEpochSecondsAsIntCodec`] | `981173106`                        |
|             [`CDateTimeAsIsoStringCodec`] | `"2001-02-03T04:05:06.007"`        |
|                  [`DateAsIsoStringCodec`] | `"2001-02-03"`                     |
|       [`DateAsOrdinalDateIsoStringCodec`] | `"2001-034"`                       |
|          [`DateAsWeekDateIsoStringCodec`] | `"2001-W05-6"`                     |
|                  [`YearAsIsoStringCodec`] | `"2001"`                           |
|                        [`YearAsIntCodec`] | `2001`                             |
|                       [`MonthAsIntCodec`] | `2`                                |
|             [`YearMonthAsIsoStringCodec`] | `"2001-02"`                        |
|              [`MonthDayAsIsoStringCodec`] | `"--02-03"`                        |
|              [`YearWeekAsIsoStringCodec`] | `"2001-W05"`                       |
|                     [`WeekdayAsIntCodec`] | `6`                                |
|                  [`TimeAsIsoStringCodec`] | `"04:05:06.007"`                   |

### [<kbd>json_serializable</kbd>]

If you use [<kbd>json_serializable</kbd>], you can choose between the following approaches:

1. Annotate your field with the converter you want to use:

   ```dart
   @JsonSerializable()
   class MyClass {
     const MyClass(this.value);

     factory MyClass.fromJson(Map<String, dynamic> json) =>
         _$MyClassFromJson(json);

     @CDateTimeAsIsoStringCodec()
     final CDateTime value;

     Map<String, dynamic> toJson() => _$MyClassToJson(this);
   }
   ```

2. Specify the converter in the [`JsonSerializable`] annotation, so it applies to all fields in that class:

   ```dart
   @JsonSerializable(converters: [CDateTimeAsIsoStringCodec()])
   class MyClass {
     // ...
   }
   ```

3. Create a customized instance of [`JsonSerializable`] that you can reuse for all your classes:

   ```dart
   const jsonSerializable = JsonSerializable(converters: [CDateTimeAsIsoStringCodec()]);

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

| Dart: `chrono`                            | Java/Kotlin     | Rust                               |
| :---------------------------------------- | :-------------- | :--------------------------------- |
| [`UnixEpochTimestamp<D>`]                 | —               | —                                  |
| [`Instant`]                               | —               | —                                  |
| [`UnixEpochNanoseconds`]                  | `Instant`       | `std::time::{Instant, SystemTime}` |
| [`UnixEpochMicroseconds`]                 | —               | —                                  |
| [`UnixEpochMilliseconds`]                 | —               | —                                  |
| [`UnixEpochSeconds`]                      | —               | —                                  |
| [`CDateTime`]                             | `LocalDateTime` | `chrono::NaiveDateTime`            |
| [`Date`]                                  | `LocalDate`     | `chrono::NaiveDate`                |
| [`Year`]                                  | `Year`          | —                                  |
| [`YearMonth`]                             | `YearMonth`     | —                                  |
| [`Month`]                                 | `Month`         | `chrono::Month`                    |
| [`MonthDay`]                              | `MonthDay`      | —                                  |
| [`YearWeek`]                              | —               | `chrono::IsoWeek`                  |
| [`Weekday`]                               | `DayOfWeek`     | `chrono::Weekday`                  |
| [`Time`]                                  | `LocalTime`     | `chrono::NaiveTime`                |
| [`CalendarDuration`]                      | `Period`        | —                                  |
| [`MonthsDuration`], [`Months`], [`Years`] | —               | `chrono::Months`                   |
| [`DaysDuration`], [`Days`], [`Weeks`]     | —               | `chrono::Days`                     |
| [`TimeDuration`]                          | `Duration`      | `std::time::Duration`              |
| [`Clock`] (from [<kbd>clock</kbd>])       | `Clock`         | —                                  |

<!-- chrono -->

[`CalendarDuration`]: https://pub.dev/documentation/chrono/latest/chrono/CalendarDuration-class.html
[`CDateTime`]: https://pub.dev/documentation/chrono/latest/chrono/CDateTime-class.html
[`CDateTimeAsIsoStringCodec`]: https://pub.dev/documentation/chrono/latest/chrono/CDateTimeAsIsoStringCodec-class.html
[`CDuration`]: https://pub.dev/documentation/chrono/latest/chrono/CDuration-class.html
[`CompoundCalendarDuration`]: https://pub.dev/documentation/chrono/latest/chrono/CompoundCalendarDuration-class.html
[`CompoundDuration`]: https://pub.dev/documentation/chrono/latest/chrono/CompoundDuration-class.html
[`Date`]: https://pub.dev/documentation/chrono/latest/chrono/Date-class.html
[`DateAsIsoStringCodec`]: https://pub.dev/documentation/chrono/latest/chrono/DateAsIsoStringCodec-class.html
[`DateAsOrdinalDateIsoStringCodec`]: https://pub.dev/documentation/chrono/latest/chrono/DateAsOrdinalDateIsoStringCodec-class.html
[`DateAsWeekDateIsoStringCodec`]: https://pub.dev/documentation/chrono/latest/chrono/DateAsWeekDateIsoStringCodec-class.html
[`Days`]: https://pub.dev/documentation/chrono/latest/chrono/Days-class.html
[`DaysDuration`]: https://pub.dev/documentation/chrono/latest/chrono/DaysDuration-class.html
[`Hours`]: https://pub.dev/documentation/chrono/latest/chrono/Hours-class.html
[`Instant`]: https://pub.dev/documentation/chrono/latest/chrono/Instant-class.html
[`InstantAsIntCodec`]: https://pub.dev/documentation/chrono/latest/chrono/InstantAsIntCodec-class.html
[`InstantAsIsoStringCodec`]: https://pub.dev/documentation/chrono/latest/chrono/InstantAsIsoStringCodec-class.html
[`Microseconds`]: https://pub.dev/documentation/chrono/latest/chrono/Microseconds-class.html
[`Milliseconds`]: https://pub.dev/documentation/chrono/latest/chrono/Milliseconds-class.html
[`Minutes`]: https://pub.dev/documentation/chrono/latest/chrono/Minutes-class.html
[`MinutesDuration`]: https://pub.dev/documentation/chrono/latest/chrono/MinutesDuration-class.html
[`Month`]: https://pub.dev/documentation/chrono/latest/chrono/Month-class.html
[`MonthAsIntCodec`]: https://pub.dev/documentation/chrono/latest/chrono/MonthAsIntCodec-class.html
[`MonthDay`]: https://pub.dev/documentation/chrono/latest/chrono/MonthDay-class.html
[`MonthDayAsIsoStringCodec`]: https://pub.dev/documentation/chrono/latest/chrono/MonthDayAsIsoStringCodec-class.html
[`Months`]: https://pub.dev/documentation/chrono/latest/chrono/Months-class.html
[`MonthsDuration`]: https://pub.dev/documentation/chrono/latest/chrono/MonthsDuration-class.html
[`Nanoseconds`]: https://pub.dev/documentation/chrono/latest/chrono/Nanoseconds-class.html
[`Seconds`]: https://pub.dev/documentation/chrono/latest/chrono/Seconds-class.html
[`Time`]: https://pub.dev/documentation/chrono/latest/chrono/Time-class.html
[`TimeAsIsoStringCodec`]: https://pub.dev/documentation/chrono/latest/chrono/TimeAsIsoStringCodec-class.html
[`TimeDuration`]: https://pub.dev/documentation/chrono/latest/chrono/TimeDuration-class.html
[`UnixEpochMicroseconds`]: https://pub.dev/documentation/chrono/latest/chrono/UnixEpochMicroseconds-class.html
[`UnixEpochMicrosecondsAsIntCodec`]: https://pub.dev/documentation/chrono/latest/chrono/UnixEpochMicrosecondsAsIntCodec-class.html
[`UnixEpochMicrosecondsAsIsoStringCodec`]: https://pub.dev/documentation/chrono/latest/chrono/UnixEpochMicrosecondsAsIsoStringCodec-class.html
[`UnixEpochMilliseconds`]: https://pub.dev/documentation/chrono/latest/chrono/UnixEpochMilliseconds-class.html
[`UnixEpochMillisecondsAsIntCodec`]: https://pub.dev/documentation/chrono/latest/chrono/UnixEpochMillisecondsAsIntCodec-class.html
[`UnixEpochMillisecondsAsIsoStringCodec`]: https://pub.dev/documentation/chrono/latest/chrono/UnixEpochMillisecondsAsIsoStringCodec-class.html
[`UnixEpochSeconds`]: https://pub.dev/documentation/chrono/latest/chrono/UnixEpochSeconds-class.html
[`UnixEpochSecondsAsIntCodec`]: https://pub.dev/documentation/chrono/latest/chrono/UnixEpochSecondsAsIntCodec-class.html
[`UnixEpochSecondsAsIsoStringCodec`]: https://pub.dev/documentation/chrono/latest/chrono/UnixEpochSecondsAsIsoStringCodec-class.html
[`UnixEpochTimestamp<D>`]: https://pub.dev/documentation/chrono/latest/chrono/UnixEpochTimestamp-class.html
[`Weekday`]: https://pub.dev/documentation/chrono/latest/chrono/Weekday-class.html
[`WeekdayAsIntCodec`]: https://pub.dev/documentation/chrono/latest/chrono/WeekdayAsIntCodec-class.html
[`Weeks`]: https://pub.dev/documentation/chrono/latest/chrono/Weeks-class.html
[`Year`]: https://pub.dev/documentation/chrono/latest/chrono/Year-class.html
[`YearAsIntCodec`]: https://pub.dev/documentation/chrono/latest/chrono/YearAsIntCodec-class.html
[`YearAsIsoStringCodec`]: https://pub.dev/documentation/chrono/latest/chrono/YearAsIsoStringCodec-class.html
[`YearMonth`]: https://pub.dev/documentation/chrono/latest/chrono/YearMonth-class.html
[`YearMonthAsIsoStringCodec`]: https://pub.dev/documentation/chrono/latest/chrono/YearMonthAsIsoStringCodec-class.html
[`Years`]: https://pub.dev/documentation/chrono/latest/chrono/Years-class.html
[`YearWeek`]: https://pub.dev/documentation/chrono/latest/chrono/YearWeek-class.html
[`YearWeekAsIsoStringCodec`]: https://pub.dev/documentation/chrono/latest/chrono/YearWeekAsIsoStringCodec-class.html

<!-- clock -->

[<kbd>clock</kbd>]: https://pub.dev/packages/clock
[`Clock`]: https://pub.dev/documentation/clock/latest/clock/Clock-class.html

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
