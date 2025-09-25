# Chrono Timezone Parser

Dart package for reading the text files comprising the [tz database](https://en.wikipedia.org/wiki/Tz_database), which records time time zone changes and offsets across the world from multiple sources.

The tz database is distributed in one of two formats: a raw text format with one file per continent, and a compiled binary format with one file per time zone. This packagee only deals with the former.

The database itself is maintained by IANA. For more information, see [IANA’s page on the time zone database](https://www.iana.org/time-zones). You can also find the text files themselves in the [tz repository](https://github.com/eggert/tz).

This implementation is based on the [parse-zoneinfo Rust crate](https://github.com/chronotope/parse-zoneinfo/blob/0207cf40ee9525c029399571561f47ddbf7cbad2/parse-zoneinfo/README.md).
