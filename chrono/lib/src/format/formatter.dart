import 'package:meta/meta.dart';

import '../../chrono.dart';

// Based on Rust Chrono's formatter: https://github.com/chronotope/chrono/blob/3ffcd1b107fd3085bc184a1f5f7445b97a0d655f/src/format/formatting.rs
class ChronoFormatter {
  ChronoFormatter._(
    this._items, {
    Date? date,
    Time? time,
    ({String name, FixedOffset offset})? offset,
  }) : _date = date,
       _time = time,
       _offset = offset;

  final List<ChronoFormatItem> _items;
  final Date? _date;
  final Time? _time;
  final ({String name, FixedOffset offset})? _offset;
  // TODO(JonasWanke):
  //     /// Locale used for text.
  //     /// ZST if the `unstable-locales` feature is not enabled.
  //     locale: Locale,

  /// Writes the date, time, and offset to a string.
  ///
  // TODO(JonasWanke): improve comment
  /// Same as `%Y-%m-%dT%H:%M:%S%.f%:z`.
  @internal
  String formatRfc3339(
    CDateTime dateTime,
    FixedOffset offset,
    ChronoSecondsFormat secondsFormat, {
    bool allowZulu = true,
  }) {
    final formatter = ChronoFormatter._(const []);
    formatter._writeYear(dateTime.date.year, .zero);
    formatter._buffer.write('-');
    formatter._writeTwo(dateTime.date.month.number, .zero);
    formatter._buffer.write('-');
    formatter._writeTwo(dateTime.date.day, .zero);

    formatter._buffer.write('T');

    formatter._writeTwo(dateTime.time.hour, .zero);
    formatter._buffer.write(':');
    formatter._writeTwo(dateTime.time.minute, .zero);
    formatter._buffer.write(':');
    var second = dateTime.time.second;
    var nanos = dateTime.time.subSecondNanos;
    if (nanos >= TimeDelta.nanosPerSecond) {
      second++;
      nanos -= TimeDelta.nanosPerSecond;
    }
    formatter._writeTwo(second, .zero);

    switch (secondsFormat) {
      case .seconds:
        break;
      case .millis:
        formatter._writeSubsecond(
          const ChronoFormatSubsecond(.millis),
          dateTime.time,
        );
      case .micros:
        formatter._writeSubsecond(
          const ChronoFormatSubsecond(.micros),
          dateTime.time,
        );
      case .nanos:
        formatter._writeSubsecond(
          const ChronoFormatSubsecond(.nanos),
          dateTime.time,
        );
      case .variable:
        formatter._writeSubsecond(
          const ChronoFormatSubsecond(.variable),
          dateTime.time,
        );
    }

    formatter._writeOffset(
      ChronoFormatTimezoneOffset(allowZulu: allowZulu),
      offset,
    );
    return formatter._buffer.toString();
  }

  // TODO(JonasWanke): convert
  // #[cfg(feature = "alloc")]
  // /// write datetimes like `Tue, 1 Jul 2003 10:52:37 +0200`, same as `%a, %d %b %Y %H:%M:%S %z`
  // pub(crate) fn write_rfc2822(
  //     w: &mut (impl Write + ?Sized),
  //     dt: NaiveDateTime,
  //     off: FixedOffset,
  // ) -> fmt::Result {
  //     let year = dt.year();
  //     // RFC2822 is only defined on years 0 through 9999
  //     if !(0..=9999).contains(&year) {
  //         return Err(fmt::Error);
  //     }

  //     let english = default_locale();

  //     w.write_str(short_weekdays(english)[dt.weekday().num_days_from_sunday() as usize])?;
  //     w.write_str(", ")?;
  //     let day = dt.day();
  //     if day < 10 {
  //         w.write_char((b'0' + day as u8) as char)?;
  //     } else {
  //         write_hundreds(w, day as u8)?;
  //     }
  //     w.write_char(' ')?;
  //     w.write_str(short_months(english)[dt.month0() as usize])?;
  //     w.write_char(' ')?;
  //     write_hundreds(w, (year / 100) as u8)?;
  //     write_hundreds(w, (year % 100) as u8)?;
  //     w.write_char(' ')?;

  //     let (hour, min, sec) = dt.time().hms();
  //     write_hundreds(w, hour as u8)?;
  //     w.write_char(':')?;
  //     write_hundreds(w, min as u8)?;
  //     w.write_char(':')?;
  //     let sec = sec + dt.nanosecond() / 1_000_000_000;
  //     write_hundreds(w, sec as u8)?;
  //     w.write_char(' ')?;
  //     OffsetFormat {
  //         precision: OffsetPrecision::Minutes,
  //         colons: Colons::None,
  //         allow_zulu: false,
  //         padding: Pad::Zero,
  //     }
  //     .format(w, off)
  // }

  final _buffer = StringBuffer();
  var _isFormatted = false;

  @override
  String toString() {
    if (!_isFormatted) {
      for (final item in _items) {
        switch (item) {
          case ChronoFormatItemLiteral(:final text) ||
              ChronoFormatItemSpace(:final text):
            _buffer.write(text);
          case final ChronoFormatItemNumeric item:
            _writeNumeric(item);
          case final ChronoFormatItemFixed item:
            _writeFixed(item);
          case ChronoFormatItemError():
            throw const FormatException('Error formatting date/time');
        }
      }
      _isFormatted = true;
    }
    return _buffer.toString();
  }

  void _writeNumeric(ChronoFormatItemNumeric item) {
    switch ((item, _date, _time)) {
      case (ChronoFormatYear(format: .full), final date?, _):
        _writeYear(date.year, item.padding);
      case (ChronoFormatYear(format: .div100), final date?, _):
        _writeTwo(date.year.number ~/ 100, item.padding);
      case (ChronoFormatYear(format: .mod100), final date?, _):
        _writeTwo(date.year.number % 100, item.padding);
      case (ChronoFormatIsoYear(format: .full), final date?, _):
        _writeYear(date.isoYearWeek.weekBasedYear, item.padding);
      case (ChronoFormatIsoYear(format: .div100), final date?, _):
        _writeTwo(date.isoYearWeek.weekBasedYear.number ~/ 100, item.padding);
      case (ChronoFormatIsoYear(format: .mod100), final date?, _):
        _writeTwo(date.isoYearWeek.weekBasedYear.number % 100, item.padding);
      case (ChronoFormatQuarter(), final date?, _):
        _writeOne(date.month.index ~/ 3 + 1);
      case (ChronoFormatMonth(), final date?, _):
        _writeTwo(date.month.number, item.padding);
      case (ChronoFormatDay(), final date?, _):
        _writeTwo(date.day, item.padding);
      case (ChronoFormatWeekFromSun(), final date?, _):
        // TODO(JonasWanke): support ChronoFormatWeekFromSun
        // (WeekFromSun, Some(d), _) => write_two(w, d.weeks_from(Weekday::Sun) as u8, pad),
        throw UnimplementedError();
      case (ChronoFormatWeekFromMon(), final date?, _):
        // TODO(JonasWanke): support ChronoFormatWeekFromMon
        // (WeekFromMon, Some(d), _) => write_two(w, d.weeks_from(Weekday::Mon) as u8, pad),
        throw UnimplementedError();
      case (ChronoFormatIsoWeek(), final date?, _):
        _writeTwo(date.isoYearWeek.week, item.padding);
      case (ChronoFormatNumDaysFromSun(), final date?, _):
        _writeOne(date.weekday.indexFrom(.sunday));
      case (ChronoFormatWeekdayFromMon(), final date?, _):
        _writeOne(date.weekday.isoNumber);
      case (ChronoFormatOrdinal(), final date?, _):
        _writeN(3, date.dayOfYear, item.padding);
      case (ChronoFormatHour(), _, final time?):
        _writeTwo(time.hour, item.padding);
      case (ChronoFormatHour12(), _, final time?):
        _writeTwo(time.hour12, item.padding);
      case (ChronoFormatMinute(), _, final time?):
        _writeTwo(time.minute, item.padding);
      case (ChronoFormatSecond(), _, final time?):
        _writeTwo(
          time.second + time.subSecondNanos ~/ TimeDelta.nanosPerSecond,
          item.padding,
        );
      case (ChronoFormatNanosecond(), _, final time?):
        _writeN(
          9,
          time.subSecondNanos % TimeDelta.nanosPerSecond,
          item.padding,
        );
      case (ChronoFormatTimestamp(), final date?, final time?):
        final offset = _offset?.offset.localMinusUtc ?? TimeDelta();
        final timestamp = date.at(time).inUtc.durationSinceUnixEpoch - offset;
        _writeN(9, timestamp.roundToSeconds(), item.padding);
      default:
        throw FormatException('Insufficient arguments for given format $item');
    }
  }

  void _writeFixed(ChronoFormatItemFixed item) {
    switch ((item, _date, _time, _offset)) {
      // case (ChronoFormatMonthName(length: .short), final date?, _, _):
      // case (ChronoFormatAmPm(casing: .lower), _, final time?, _):
      case (final ChronoFormatSubsecond item, _, final time?, _):
        _writeSubsecond(item, time);
      case (ChronoFormatTimezoneName(), _, _, (:final name, offset: _)?):
        _buffer.write(name);
      case (
        final ChronoFormatTimezoneOffset item,
        _,
        _,
        (name: _, :final offset)?,
      ):
        _writeOffset(item, offset);
      default:
        throw FormatException('Insufficient arguments for given format $item');
    }
    //     match (spec, self.date, self.time, self.off.as_ref()) {
    //         (ShortMonthName, Some(d), _, _) => {
    //             w.write_str(short_months(self.locale)[d.month0() as usize])
    //         }
    //         (LongMonthName, Some(d), _, _) => {
    //             w.write_str(long_months(self.locale)[d.month0() as usize])
    //         }
    //         (ShortWeekdayName, Some(d), _, _) => w.write_str(
    //             short_weekdays(self.locale)[d.weekday().num_days_from_sunday() as usize],
    //         ),
    //         (LongWeekdayName, Some(d), _, _) => {
    //             w.write_str(long_weekdays(self.locale)[d.weekday().num_days_from_sunday() as usize])
    //         }
    //         (LowerAmPm, _, Some(t), _) => {
    //             let ampm = if t.hour12().0 { am_pm(self.locale)[1] } else { am_pm(self.locale)[0] };
    //             for c in ampm.chars().flat_map(|c| c.to_lowercase()) {
    //                 w.write_char(c)?
    //             }
    //             Ok(())
    //         }
    //         (UpperAmPm, _, Some(t), _) => {
    //             let ampm = if t.hour12().0 { am_pm(self.locale)[1] } else { am_pm(self.locale)[0] };
    //             w.write_str(ampm)
    //         }
    //         (Internal(InternalFixed { val: Nanosecond3NoDot }), _, Some(t), _) => {
    //             write!(w, "{:03}", t.nanosecond() / 1_000_000 % 1_000)
    //         }
    //         (Internal(InternalFixed { val: Nanosecond6NoDot }), _, Some(t), _) => {
    //             write!(w, "{:06}", t.nanosecond() / 1_000 % 1_000_000)
    //         }
    //         (Internal(InternalFixed { val: Nanosecond9NoDot }), _, Some(t), _) => {
    //             write!(w, "{:09}", t.nanosecond() % 1_000_000_000)
    //         }
    //         (RFC2822, Some(d), Some(t), Some((_, off))) => {
    //             write_rfc2822(w, crate::NaiveDateTime::new(d, t), *off)
    //         }
    //         (RFC3339, Some(d), Some(t), Some((_, off))) => write_rfc3339(
    //             w,
    //             crate::NaiveDateTime::new(d, t),
    //             *off,
    //             SecondsFormat::AutoSi,
    //             false,
    //         ),
    //     }
    // }
  }

  void _writeOffset(ChronoFormatTimezoneOffset item, FixedOffset offsetRaw) {
    var offset = offsetRaw.localMinusUtc;
    if (item.allowZulu && offset.isZero) {
      _buffer.write('Z');
      return;
    }

    if (offset.isNegative) {
      _buffer.write('-');
      offset = -offset;
    } else {
      _buffer.write('+');
    }

    final int hours;
    var minutes = 0;
    var seconds = 0;
    var precision = item.precision;
    switch (precision) {
      case .hours:
        // Minutes and seconds are simply truncated.
        hours = offset.roundToHours(rounding: .down);
        precision = .hours;
      case .minutes || .optionalMinutes:
        final (h, m) = offset.splitHoursMinutes(rounding: .down);
        hours = h;
        minutes = m;
        if (precision == .optionalMinutes && minutes == 0) {
          precision = .hours;
        }
      case .seconds || .optionalSeconds || .optionalMinutesAndSeconds:
        final (h, m, s) = offset.splitHoursMinutesSeconds(rounding: .down);
        hours = h;
        minutes = m;
        seconds = s;
        if (precision != .seconds && seconds == 0) {
          precision = precision == .optionalMinutesAndSeconds && minutes == 0
              ? .hours
              : .minutes;
        }
    }

    _writeTwo(hours, .zero);
    if (precision case .minutes || .seconds) {
      if (item.printColon) _buffer.write(':');
      _writeTwo(minutes, .zero);
    }
    if (precision == .seconds) {
      if (item.printColon) _buffer.write(':');
      _writeTwo(seconds, .zero);
    }
  }

  void _writeSubsecond(ChronoFormatSubsecond item, Time time) {
    switch (item.accuracy) {
      case .variable:
        final nanos = time.subSecondNanos % TimeDelta.nanosPerSecond;
        if (nanos == 0) break;

        // TODO(JonasWanke): localization
        _buffer.write('.');
        if (nanos % TimeDelta.nanosPerMilli == 0) {
          _buffer.write(
            (nanos ~/ TimeDelta.nanosPerMilli).toString().padLeft(3, '0'),
          );
        } else if (nanos % TimeDelta.nanosPerMicro == 0) {
          _buffer.write(
            (nanos ~/ TimeDelta.nanosPerMicro).toString().padLeft(6, '0'),
          );
        } else {
          _buffer.write(nanos.toString().padLeft(9, '0'));
        }
      case .millis:
        // TODO(JonasWanke): localization
        _buffer.write('.');
        _buffer.write(
          (time.subSecondNanos ~/
                  TimeDelta.nanosPerMilli %
                  TimeDelta.millisPerSecond)
              .toString()
              .padLeft(3, '0'),
        );
      case .micros:
        // TODO(JonasWanke): localization
        _buffer.write('.');
        _buffer.write(
          (time.subSecondNanos ~/
                  TimeDelta.nanosPerMicro %
                  TimeDelta.microsPerSecond)
              .toString()
              .padLeft(6, '0'),
        );
      case .nanos:
        // TODO(JonasWanke): localization
        _buffer.write('.');
        _buffer.write(
          (time.subSecondNanos ~/ TimeDelta.nanosPerSecond).toString().padLeft(
            9,
            '0',
          ),
        );
    }
  }

  void _writeOne(int value) => _buffer.writeCharCode(0x30 + value);
  void _writeTwo(int value, ChronoPadding padding) {
    switch ((value ~/ 10, padding)) {
      case (0, .none):
        break;
      case (0, .space):
        _buffer.write(' ');
      case (final tens, _):
        _writeOne(tens);
    }
    _writeOne(value % 10);
  }

  void _writeN(
    int width,
    int value,
    ChronoPadding padding, {
    bool alwaysSign = false,
  }) {
    if (value < 0) {
      _buffer.write('-');
      width -= 1;
      value = -value;
    } else if (alwaysSign) {
      _buffer.write('+');
      width -= 1;
    }
    switch (padding) {
      case .none:
        _buffer.write(value);
      case .zero:
        _buffer.write(value.toString().padLeft(width, '0'));
      case .space:
        _buffer.write(value.toString().padLeft(width));
    }
  }

  void _writeYear(Year year, ChronoPadding padding) {
    final number = year.number;
    if (1000 <= number || number <= 9999) {
      _writeTwo(number ~/ 100, padding);
      _writeTwo(number % 100, padding);
    } else {
      _writeN(4, number, padding, alwaysSign: number < 0 || number >= 10_000);
    }
  }
}
