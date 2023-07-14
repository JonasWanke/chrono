# Chrono

**⚠️ Work in Progress ⚠️**

Chrono is a date and time package for Dart supporting all platforms.
It offers strongly-typed data classes for timezone-independent date, time, and different durations based on the [proleptic Gregorian calendar], including:

- arithmetic operations and conversions
- parsing and formatting for a subset of [ISO 8601], [RFC 3339], and [CC 18011:2018]

The following features are _not_ implemented, but could be added in the future:

- timezone support
- customizable parsing and formatting
- internationalization

## Comparison to `dart:core`

Dart Core:

- `DateTime`: unique point on the UTC timeline or a point in local time with microsecond precision (millisecond precision on the web)
- `Duration`: amount of time with microsecond precision

Chrono:

- `Instant`: unique point on the UTC timeline with unlimited precision
- `DateTime`: date plus wall clock time with unlimited precision
  - `Time`: wall clock time
  - `Date`: date consisting of `Year`, `Month`, and day of month
    - `WeekDate`: date consisting of `YearWeek` and `Weekday`
    - `OrdinalDate`: date consisting of `Year` and day of year
  - `Year`, `Month`, `Weekday`: self-explanatory TODO
  - `YearMonth`: `Year` and `Month`, e.g., for getting the length of a month
  - `YearWeek`: `Year` and [ISO week] from Monday to Sunday
- `Duration`: amount of time based on months, days, and seconds
  - `DateDuration`: amount of time based on months and days, since the length of a month and even a day can vary (e.g., daylight savings time changes)
    - `MonthsDuration`: whole number of months, can be `Months` or `Years`
    - `FixedDaysDuration`: whole number of days, can be `Days` or `Weeks`
    - `CompoundDaysDuration`: a combination of months and days
  - `TimeDuration`: amount of time based on seconds
    - `FractionalSeconds`: fractional number of seconds with unlimited precision
    - `Hours`, `Minutes`, `Seconds`, `Milliseconds`, `Microseconds`, `Nanoseconds`: a whole number of hours/etc.
  - `CompoundDuration`: a combination of `DateDuration` and `FractionalSeconds`

For example, April 23, 2023 at 18:24:20 happened at different moments in different time zones.
In Chrono's classes, it would be represented as:

| Class         | Encoding              |
| :------------ | :-------------------- |
| `DateTime`    | `2023-04-23T18:24:20` |
| `Date`        | `2023-04-23`          |
| `YearMonth`   | `2023-04`             |
| `Year`        | 2023                  |
| `Month`       | 4                     |
| `OrdinalDate` | `2023-113`            |
| `WeekDate`    | `2023-W16-7`          |
| `YearWeek`    | `2023-W16`            |
| `Weekday`     | 7                     |
| `Time`        | `18:24:20`            |

[CC 18011:2018]: https://standards.calconnect.org/csd/cc-18011.html
[ISO 8601]: https://en.wikipedia.org/wiki/ISO_8601
[ISO week]: https://en.wikipedia.org/wiki/ISO_week_date
[Proleptic Gregorian calendar]: https://en.wikipedia.org/wiki/Proleptic_Gregorian_calendar
[RFC 3339]: https://datatracker.ietf.org/doc/html/rfc3339
