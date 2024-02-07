# Chrono

**⚠️ Work in Progress ⚠️**

Chrono is a date and time package for Dart supporting all platforms.
It offers strongly-typed data classes for timezone-independent (plain/local) date, time, and different durations based on the proleptic Gregorian calendar, including:

- arithmetic operations and conversions
- parsing and formatting for a subset of [ISO 8601], [RFC 3339], and [CC 18011:2018]
  - this is implemented for `Instant` and the date/time classes, but still missing for durations

The following features are _not_ implemented, but could be added in the future:

- timezone support (work in progress)
- customizable parsing and formatting
- internationalization

Chrono is split into multiple packages:

- [`chrono`](./chrono/): The core package, providing date, time, and duration classes.
- [`chrono_timezone_compiler`](./chrono_timezone_compiler/) (WIP): A Dart program reading the [IANA Time Zone Database] and generating timezone data for Chrono.
