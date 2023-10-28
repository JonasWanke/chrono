import 'package:chrono/chrono.dart';
import 'package:supernova/supernova.dart' hide Instant, Weekday;
import 'package:supernova/supernova_io.dart';

import 'leap_seconds.dart';
import 'rule.dart';
import 'zone.dart';
import 'zone_information_compiler.dart';

// ignore_for_file: binary-expression-operand-order

var unspecifiedtype = 0;

// Original: `YEARSPERREPEAT` → `Years.gregorianRepeat`

/// Original: `outzone`
Future<void> encodeTzif(Zone zone, Map<String, Rule> rules) async {
  var lastatmax = -1;
  var defaulttype = -1;

  // final maxFormatLength =
  //     zone.allRules.sumBy((it) => it.name.toString().length);
  // final maxAbbreviationVariableLength = rules.values
  //     .expand((it) => it.clauses)
  //     .sumBy((it) => it.abbreviationVariable.length);
  // final maxAbbreviationLength =
  //     2 + maxFormatLength + maxAbbreviationVariableLength;
  // final maxEnvVarLength = 2 * maxAbbreviationLength + 5 * 9;

  var startBuffer = ''; // TODO: `ByteData(maxAbbreviationLength + 1);`?
  var ab = ''; // TODO: `ByteData(maxAbbreviationLength + 1);`
  // final envVar = ByteData(maxEnvVarLength + 1);

  // timecnt = 0;
  attypes.clear();
  // typecnt = 0;
  utoffs.clear();
  charcnt = 0;
  final zoneCount = zone.allRules.length;
  var prodstic = zoneCount == 1;

  /// Original: `startttisstd`, `startttisut`
  var startTimeReference = TimeReference.localTime;

  /// Original: `min_year`
  var minYear = Year.unixEpoch;

  /// Original: `max_year`
  var maxYear = Year.unixEpoch;

  /// Original: `updateminmax`
  void updateMinMaxYears(Year year) {
    if (minYear > year) minYear = year;
    if (maxYear < year) maxYear = year;
  }

  if (leapseen) {
    // TODO(JonasWanke): handle leap second min and max years
    // updateMinMaxYears(leapminyear!);
    // updateMinMaxYears(leapmaxyear! + (leapmaxyear! < ZIC_MAX));
  }

  for (final (zoneRule, end) in zone.allRules) {
    if (end != null) updateMinMaxYears(end.dateTime.date.year);

    if (zoneRule.type case RuleZoneRuleType(:final ruleName)) {
      final rule = rules[ruleName]!;
      for (final clause in rule.clauses) {
        var hasExactYear = false;
        if (clause.startYear case LimitOrValue(value: final year)) {
          updateMinMaxYears(year);
          hasExactYear = true;
        }
        if (clause.endYear case LimitOrValue(value: final year)) {
          updateMinMaxYears(year);
          hasExactYear = true;
        }
        if (hasExactYear) prodstic = false;
      }
    }
  }

  // Generate lots of data if a rule can't cover all future times.
  // FIXME: Implement `stringzone`
  final stringzoneResult = stringzone(zone, rules);
  final compat = stringzoneResult?.compat;
  final envvar = stringzoneResult?.envvar;
  final version =
      compat == null || compat < 2013 ? TzifVersion.v2 : TzifVersion.v3;

  /// Original: `do_extend`
  final doExtend = compat == null;
  if (noise) {
    if (envvar == null) {
      logger.warning('No POSIX environment variable for zone ${zone.name}');
    } else if (compat != 0) {
      // Circa-COMPAT clients, and earlier clients, might not work for this zone
      // when given dates before 1970 or after 2038.
      logger.warning(
        '${zone.name}: pre-$compat clients may mishandle distant timestamps',
      );
    }
  }
  if (doExtend) {
    // Search through a couple of extra years past the obvious 400, to avoid
    // edge cases. For example, suppose a non-POSIX rule applies from 2012
    // onwards and has transitions in March and September, plus some one-off
    // transitions in November 2013. If zic looked only at the last 400 years,
    // it would set max_year=2413, with the intent that the 400 years 2014
    // through 2413 will be repeated. The last transition listed in the tzfile
    // would be in 2413-09, less than 400 years after the last one-off
    // transition in 2013-11. Two years might be overkill, but with the kind of
    // edge cases available we're not sure that one year would suffice.
    /// Original: `years_of_observations`
    final yearsOfObservations = Years.gregorianRepeat + const Years(2);

    minYear =
        (minYear - yearsOfObservations).coerceAtLeast(const Year(ZIC_MIN));
    maxYear =
        (maxYear + yearsOfObservations).coerceAtLeast(const Year(ZIC_MAX));
    // Regardless of any of the above, for a "proDSTic" zone which specifies
    // that its rules always have and always will be in effect, we only need one
    // cycle to define the zone.
    if (prodstic) {
      minYear = const Year(1900);
      maxYear = const Year(1900) + yearsOfObservations;
    }
  }

  maxYear = maxYear.coerceAtLeast(
    Year.unixEpoch +
        Years(
          redundant_time.durationSinceUnixEpoch.inSeconds ~/
                  Seconds.perNormalYear +
              1,
        ),
  );
  final maxYear0 = maxYear;
  if (bloat.wantsBloat) {
    // For the benefit of older systems, generate data from 1900 through 2038.
    if (minYear > const Year(1900)) minYear = const Year(1900);
    if (maxYear < const Year(2038)) maxYear = const Year(2038);
  }

  if (min_time < lo_time || hi_time < max_time) {
    unspecifiedtype =
        addtype(const Seconds(0), '-00', false, TimeReference.localTime);
  }

  // `lo_time = min_time`, `hi_time = max_time`

  // Corresponds to `rule.r_todo` in the original code.
  final rulesToDo = <(String, int)>{};

  RuleClause? prevrp;
  (int, DateTime)? prevktime;
  for (final (i, (zoneRule, end)) in zone.allRules.indexed) {
    /// A guess that may well be corrected later.
    var save = const Seconds(0);
    var usestart = i > 0 && zone.rulesWithEnd[i - 1].$2.dateTime > minDateTime;
    // useuntil = end != null
    final stdoff = zoneRule.standardOffset;
    var startoff = stdoff;
    if (end != null && end.dateTime <= minDateTime) continue;

    var startTime = DateTime.unixEpoch;
    switch (zoneRule.type) {
      case NoneZoneRuleType():
        save = const Seconds(0);
        assert(zoneRule.name is! FormattedWithVariableZoneRuleName);
        startBuffer = doabbr(zoneRule, '', save, isDst: false);
        final type = addtype(
          zoneRule.standardOffset.asSeconds,
          startBuffer,
          false,
          startTimeReference,
        );
        if (usestart) {
          addtt(startTime, type);
          usestart = false;
        } else {
          defaulttype = type;
        }
      case OffsetZoneRuleType(offset: final zoneSave, :final isDst):
        save = zoneSave.asSeconds;
        assert(zoneRule.name is! FormattedWithVariableZoneRuleName);
        startBuffer = doabbr(zoneRule, '', save, isDst: isDst);
        final type = addtype(
          oadd(zoneRule.standardOffset, save),
          startBuffer,
          isDst,
          startTimeReference,
        );
        if (usestart) {
          addtt(startTime, type);
          usestart = false;
        } else {
          defaulttype = type;
        }
      case RuleZoneRuleType(:final ruleName):
        final currentRule = rules[ruleName]!;
        for (var year = minYear; year <= maxYear; year += const Years(1)) {
          if (end != null && year > end.dateTime.date.year) break;

          // Mark which rules to do in the current year.
          // For those to do, calculate rpytime(rp, year).
          // The former TYPE field was also considered here.
          final temps = <int, LimitOr<DateTime>>{};
          for (final (ruleClauseIndex, ruleClause)
              in currentRule.clauses.indexed) {
            final y2038Boundary =
                DateTime.fromDurationSinceUnixEpoch(const Seconds(1 << 31));
            if (ruleClause.startYear > year || ruleClause.endYear < year) {
              continue;
            }

            final temp = rpytime(ruleClause, year);
            temps[ruleClauseIndex] = temp;
            if (temp < y2038Boundary || year <= maxYear0) {
              rulesToDo.add((ruleName, ruleClauseIndex));
            }
          }
          while (true) {
            DateTime? untilTime;
            if (end != null) {
              // Turn `untilTime` into UT assuming the current `stdoff` and `save`
              // values.
              untilTime =
                  end.dateTime - end.timeReference.getAdjustment(stdoff, save);
            }

            // Find the rule (of those to do, if any) that takes effect earliest
            // in the year.

            /// Original: `k`, `ktime`
            (int, DateTime)? ktime;
            late Seconds offset;
            for (var j = 0; j < currentRule.clauses.length; j++) {
              final r = currentRule.clauses[j];
              if (!rulesToDo.contains((ruleName, j))) continue;

              offset = r.timeReference.getAdjustment(stdoff, save);

              final DateTime jtime;
              if (temps[j]! case LimitOrValue(:final value)) {
                jtime = value - offset;
              } else {
                continue;
              }

              if (ktime == null || jtime < ktime.$2) {
                ktime = (j, jtime);
              } else if (jtime == ktime.$2) {
                logger.error('Two rules for same instant $jtime');
              }
            }
            if (ktime == null) {
              // Go on to next year.
              break;
            }

            final rp = currentRule.clauses[ktime.$1];
            rulesToDo.remove((ruleName, ktime.$1));
            if (end != null && ktime.$2 >= untilTime!) {
              if (startBuffer.isEmpty &&
                  (oadd(zoneRule.standardOffset, rp.offset) == startoff)) {
                startBuffer = doabbr(
                  zoneRule,
                  rp.abbreviationVariable,
                  rp.offset.asSeconds,
                  isDst: rp.isDst,
                );
              }
              break;
            }
            save = rp.offset.asSeconds;
            if (usestart && ktime.$2 == startTime) usestart = false;
            if (usestart) {
              if (ktime.$2 < startTime) {
                startoff = oadd(zoneRule.standardOffset, save);
                // TODO(JonasWanke): append?
                startBuffer = doabbr(
                  zoneRule,
                  rp.abbreviationVariable,
                  rp.offset.asSeconds,
                  isDst: rp.isDst,
                );
                continue;
              }
              if (startBuffer.isEmpty &&
                  startoff == oadd(zoneRule.standardOffset, save)) {
                // TODO(JonasWanke): append?
                startBuffer = doabbr(
                  zoneRule,
                  rp.abbreviationVariable,
                  rp.offset.asSeconds,
                  isDst: rp.isDst,
                );
              }
            }
            ab = doabbr(
              zoneRule,
              rp.abbreviationVariable,
              rp.offset.asSeconds,
              isDst: rp.isDst,
            );
            offset = oadd(zoneRule.standardOffset, rp.offset.asSeconds);
            if (!bloat.wantsBloat &&
                end == null &&
                !doExtend &&
                prevrp != null &&
                lo_time.dateTimeInUtc <= prevktime!.$2 &&
                redundant_time.dateTimeInUtc <= ktime.$2 &&
                rp.endYear is LimitOrMax &&
                prevrp.endYear is LimitOrMax) {
              break;
            }
            final type = addtype(offset, ab, rp.isDst, rp.timeReference);
            if (defaulttype < 0 && !rp.isDst) defaulttype = type;
            if (rp.endYear is LimitOrMax &&
                !(0 <= lastatmax && ktime.$2 < attypes[lastatmax].at)) {
              lastatmax = timecnt;
            }
            addtt(ktime.$2, type);
            prevrp = rp;
            prevktime = ktime;
          }
        }
    }
    if (usestart) {
      final isDst = startoff != zoneRule.standardOffset;
      // TODO(JonasWanke): `if (startBuffer.isEmpty && zoneRule->z_format) {`
      if (startBuffer.isEmpty) {
        if (zoneRule.name is! FormattedWithVariableZoneRuleName) {
          startBuffer = doabbr(zoneRule, '', save, isDst: isDst);
        }
      }
      if (startBuffer.isEmpty) {
        logger.error(
          "Can't determine time zone abbreviation to use just after until "
          'time.',
        );
      } else {
        final type =
            addtype(startoff.asSeconds, startBuffer, isDst, startTimeReference);
        if (defaulttype < 0 && !isDst) defaulttype = type;
        addtt(startTime, type);
      }
    }
    // Now we may get to set startTime for the next zone line.
    if (end != null) {
      startTimeReference = end.timeReference;
      startTime = end.dateTime - end.timeReference.getAdjustment(stdoff, save);
    }
  }
  if (defaulttype < 0) defaulttype = 0;
  if (lastatmax >= 0) {
    attypes[lastatmax] = (
      at: attypes[lastatmax].at,
      dontMerge: true,
      type: attypes[lastatmax].type
    );
  }
  if (doExtend) {
    // If we're extending the explicitly listed observations for 400 years
    // because we can't fill the POSIX-TZ field, check whether we actually ended
    // up explicitly listing observations through that period. If there aren't
    // any near the end of the 400-year period, add a redundant one at the end
    // of the final year, to make it clear that we are claiming to have definite
    // knowledge of the lack of transitions up to that point.
    final lastat = attypes.maxBy((it) => it.at);
    if (lastat == null ||
        lastat.at <
            calculateRuleClauseDateTime(
              Month.january,
              const DayCode.dayOfMonth(1),
              const Seconds(0),
              LimitOrValue(maxYear - const Years(1)),
            )) {
      addtt(
        calculateRuleClauseDateTime(
          Month.january,
          const DayCode.dayOfMonth(1),
          const Seconds(0),
          LimitOrValue(maxYear + const Years(1)),
        ),
        lastat?.type ?? defaulttype,
      );
      attypes[timecnt - 1] = (
        at: attypes[timecnt - 1].at,
        dontMerge: true,
        type: attypes[timecnt - 1].type
      );
    }
  }

  await _writeZone(zone.name, envvar ?? '', version, defaulttype, bloat: bloat);
}

({int compat, String envvar})? stringzone(Zone zone, Map<String, Rule> rules) {
  // register const struct zone *zp;
  // register struct rule *rp;
  // register struct rule *stdrp;
  // register struct rule *dstrp;
  // register ptrdiff_t i;
  // register int compat = 0;
  // register int c;
  // int offsetlen;
  // struct rule stdr, dstr;
  // ptrdiff_t len;
  // int dstcmp;
  // struct rule *lastrp[2] = {NULL, NULL};
  // struct zone zstr[2];
  // struct zone const *stdzp;
  // struct zone const *dstzp;

  // Internet [RFC 8536 section 5.1](https://www.rfc-editor.org/rfc/rfc8536.html#section-5.1)
  // says to use an empty TZ string if future timestamps are truncated.
  if (hi_time < max_time) return null;

  final zp = zone.lastRule;
  RuleClause? stdrp;
  RuleClause? dstrp;
  final int dstcmp;
  switch (zp.type) {
    case NoneZoneRuleType():
      // TODO(JonasWanke): Verify that this is correct
      // It corresponds to `zp->z_nrules == 0 && !zp_isdst`
      dstcmp = -1;
      break;
    case OffsetZoneRuleType(:final isDst):
      dstcmp = isDst ? 1 : -1;
      break;
    case RuleZoneRuleType(:final ruleName):
      final rule = rules[ruleName]!;
      for (final rp in rule.clauses) {
        final last = rp.isDst ? dstrp : stdrp;
        final cmp = _compareRuleClauses(last, rp);
        if (cmp < 0) {
          if (rp.isDst) {
            dstrp = rp;
          } else {
            stdrp = rp;
          }
        } else if (cmp == 0) {
          return null;
        }
      }
      dstcmp = _compareRuleClauses(dstrp, stdrp);
  }

  var stdzp = zp;
  var dstzp = zp;

  if (dstcmp < 0) {
    // Standard time all year.
    dstrp = null;
  } else if (dstcmp > 0) {
    // DST all year. Use an abbreviation like "XXX3EDT4,0/0,J365/23" for EDT
    // (-04) all year.
    /// Original: `save`
    final save = dstrp?.offset ??
        zp.type.map<Seconds>(
          rule: (_) => throw Exception('`dstrp` should not be `null` here.'),
          offset: (it) => it.offset.asSeconds,
          none: (_) => const Seconds(0),
        );
    if (save.isNonNegative) {
      // Positive DST, the typical case for all-year DST. Fake a timezone with
      // negative DST.
      stdzp = ZoneRule(
        standardOffset: zp.standardOffset.asSeconds + save * 2,
        type: const ZoneRuleType.none(),
        name: const ZoneRuleName.simple('XXX'), // Any 3 letters will do.
      );
      dstzp = ZoneRule(
        standardOffset: zp.standardOffset.asSeconds + save * 2,
        type: const ZoneRuleType.none(),
        name: zp.name,
      );
    }

    // TODO(JonasWanke): I think that `startYear` and `endYear` are not used afterwards since they aren't set in the original. Hence, I just used a default value.
    dstrp = RuleClause(
      startYear: const LimitOrMin(),
      endYear: const LimitOrMax(),
      month: Month.january,
      dayCode: const DayCode.dayOfMonth(1),
      time: const Seconds(0),
      timeReference: TimeReference.localTime,
      isDst: true,
      offset: -save.absolute,
      abbreviationVariable: dstrp?.abbreviationVariable,
    );
    stdrp = RuleClause(
      startYear: const LimitOrMin(),
      endYear: const LimitOrMax(),
      month: Month.december,
      dayCode: const DayCode.dayOfMonth(31),
      time: Seconds.normalDay + dstrp.offset,
      timeReference: TimeReference.localTime,
      isDst: false,
      offset: const Seconds(0),
      abbreviationVariable:
          save.isNegative ? stdrp?.abbreviationVariable : null,
    );
  }
  var result = doabbr(
    stdzp,
    stdrp?.abbreviationVariable,
    const Seconds(0),
    isDst: false,
    addQuotes: true,
  );
  final offsetString = stringoffset(-stdzp.standardOffset.asSeconds);
  if (offsetString == null) return null;
  result += offsetString;

  if (dstrp == null) return (compat: 0, envvar: result);

  result += doabbr(
    dstzp,
    dstrp.abbreviationVariable,
    dstrp.offset.asSeconds,
    isDst: dstrp.isDst,
    addQuotes: true,
  );

  if (dstrp.offset != Seconds.hour) {
    final offsetString =
        stringoffset(dstzp.standardOffset.asSeconds + dstrp.offset);
    if (offsetString == null) return null;
    result += offsetString;
  }

  result += ',';

  final dstRuleStringResult =
      stringrule(dstrp, dstrp.offset.asSeconds, stdzp.standardOffset.asSeconds);
  if (dstRuleStringResult == null) return null;
  var compat = dstRuleStringResult.compat;
  result += dstRuleStringResult.ruleString;

  result += ',';

  final stdRuleStringResult = stringrule(
      stdrp!, dstrp.offset.asSeconds, stdzp.standardOffset.asSeconds);
  if (stdRuleStringResult == null) return null;
  if (compat < stdRuleStringResult.compat) compat = stdRuleStringResult.compat;
  result += stdRuleStringResult.ruleString;
  return (compat: compat, envvar: result);
}

/// Original: `stringoffset`
String? stringoffset(Seconds offset) {
  final buffer = StringBuffer(offset.isNegative ? '-' : '');
  final (hours, minutes, seconds) = offset.absolute.asHoursAndMinutesAndSeconds;
  if (hours >= Hours.normalWeek) return null;

  buffer.write(hours.inHours.toString());
  if (!minutes.isZero || !seconds.isZero) {
    buffer.write(minutes.inMinutes.toString().padLeft(2, '0'));
    if (!seconds.isZero) {
      buffer.write(seconds.inSeconds.toString().padLeft(2, '0'));
    }
  }
  return buffer.toString();
}

({int compat, String ruleString})? stringrule(
  RuleClause rp,
  Seconds save,
  Seconds stdoff,
) {
  var tod = rp.time.asSeconds;
  var compat = 0;
  var result = '';

  switch (rp.dayCode) {
    case DayOfMonthDayCode(day: final day):
      if (day == 29 && rp.month == Month.february) return null;
      final total = Month.values
          .takeWhile((it) => it < rp.month)
          .map((it) => it.lengthInCommonYear)
          .fold(const Days(0), (sum, it) => sum + it);
      // Omit the "J" in Jan and Feb, as that's shorter.
      if (rp.month <= Month.february) {
        result += (total.inDays + day - 1).toString();
      } else {
        result += 'J${total.inDays + day}';
      }

    case LessThanOrEqualToDayCode(weekday: var weekday, day: final day):
      final int week;
      if (day == rp.month.lastDayInLeapYear.day) {
        week = 5;
      } else {
        final weekdayoff = Days(day) % Days.perWeek;
        if (!weekdayoff.isZero) compat = 2013;
        weekday -= weekdayoff;
        tod += weekdayoff.asNormalHours;
        week = day ~/ Days.perWeek;
      }
      // Weekdays should be 0 for Sunday, 1 for Monday, etc.
      // (See `TM_SUNDAY`, `TM_MONDAY`, etc. in the original.)
      result +=
          'M${rp.month.number}.$week.${weekday.number % Weekday.maxNumber}';
    case GreaterThanOrEqualToDayCode(weekday: var weekday, day: final day):
      final weekdayoff = Days(day - 1) % Days.perWeek;
      if (!weekdayoff.isZero) compat = 2013;
      weekday -= weekdayoff;
      tod += weekdayoff.asNormalHours;
      final week = 1 + (day - 1) ~/ Days.perWeek;
      // Weekdays should be 0 for Sunday, 1 for Monday, etc.
      // (See `TM_SUNDAY`, `TM_MONDAY`, etc. in the original.)
      result +=
          'M${rp.month.number}.$week.${weekday.number % Weekday.maxNumber}';
  }

  if (rp.timeReference.isUt) tod += stdoff;
  if (rp.timeReference.isStd && !rp.isDst) tod += save;
  if (tod != const Hours(2).asSeconds) {
    result += '/';

    final stringOffsetResult = stringoffset(tod);
    if (stringOffsetResult == null) return null;
    result += stringOffsetResult;

    if (tod.isNegative) {
      if (compat < 2013) compat = 2013;
    } else if (tod >= Seconds.normalDay) {
      if (compat < 1994) compat = 1994;
    }
  }
  return (compat: compat, ruleString: result);
}

// static void adjleap(void) {
//   register int i;
//   register zic_t last = 0;
//   register zic_t prevtrans = 0;

//   /*
//   ** propagate leap seconds forward
//   */
//   for (i = 0; i < leapcnt; ++i) {
//     if (trans[i] - prevtrans < 28 * SECSPERDAY) {
//       error(_("Leap seconds too close together"));
//       exit(EXIT_FAILURE);
//     }
//     prevtrans = trans[i];
//     trans[i] = tadd(trans[i], last);
//     last = corr[i] += last;
//   }

//   if (0 <= leapexpires) {
//     leapexpires = oadd(leapexpires, last);
//     if (!(leapcnt == 0 || (trans[leapcnt - 1] < leapexpires))) {
//       error(_("last Leap time does not precede Expires time"));
//       exit(EXIT_FAILURE);
//     }
//   }
// }

/// Original: `rule_cmp`
int _compareRuleClauses(RuleClause? a, RuleClause? b) {
  return switch ((a, b)) {
    (null, null) => 0,
    (null, _) => -1,
    (_, null) => 1,
    (RuleClause(endYear: final aEndYear), RuleClause(endYear: final bEndYear))
        when aEndYear != bEndYear =>
      switch ((aEndYear, bEndYear)) {
        (LimitOrMin(), LimitOrValue() || LimitOrMax()) => -1,
        (LimitOrValue(), LimitOrMax()) => -1,
        (
          LimitOrValue(value: final aValue),
          LimitOrValue(value: final bValue)
        ) =>
          aValue.compareTo(bValue),
        (LimitOrValue() || LimitOrMax(), LimitOrMin()) => 1,
        (LimitOrMax(), LimitOrValue()) => 1,
        _ => throw Exception('All cases are handled above'),
      },
    (RuleClause(endYear: LimitOrMax()), _) => 0,
    (RuleClause(month: final aMonth), RuleClause(month: final bMonth))
        when aMonth != bMonth =>
      aMonth.compareTo(bMonth),
    (
      RuleClause(dayCode: final aDayCode),
      RuleClause(dayCode: final bDayCode)
    ) =>
      aDayCode.day.compareTo(bDayCode.day),
  };
}

/// Original: `writezone`
Future<void> _writeZone(
  String name,
  String string,
  TzifVersion version,
  int defaultType, {
  required Bloat bloat,
}) async {
  // String? tempname;
  final outname = name;

  /* Allocate the ATS and TYPES arrays via a single malloc,
     as this is a bit faster.  Do not malloc(0) if !timecnt,
     as that might return NULL even on success.  */
  // zic_t *ats = emalloc(align_to(
  //     size_product(timecnt + !timecnt, sizeof *ats + 1), alignof(zic_t)));
  // void *typesptr = ats + timecnt;
  // unsigned char *types = typesptr;
  // struct timerange rangeall = {0}, range32, range64;

  // Sort

  if (timecnt > 1) {
    /// Original: `atcomp`
    attypes.sortBy((it) => it.at);
  }

  // Optimize

  {
    var fromIndex = 0;
    var toIndex = 0;
    for (; fromIndex < timecnt; ++fromIndex) {
      if (toIndex > 0 &&
          ((attypes[fromIndex].at + utoffs[attypes[toIndex - 1].type]) <=
              (attypes[toIndex - 1].at +
                  utoffs[toIndex == 1 ? 0 : attypes[toIndex - 2].type]))) {
        // TODO: class and `copyWith(…)`
        attypes[toIndex - 1] = (
          at: attypes[toIndex - 1].at,
          dontMerge: attypes[toIndex - 1].dontMerge,
          type: attypes[fromIndex].type,
        );
        continue;
      }
      if (toIndex == 0 ||
          attypes[fromIndex].dontMerge ||
          (utoffs[attypes[toIndex - 1].type] !=
              utoffs[attypes[fromIndex].type]) ||
          (isdsts[attypes[toIndex - 1].type] !=
              isdsts[attypes[fromIndex].type]) ||
          (desigidx[attypes[toIndex - 1].type] !=
              desigidx[attypes[fromIndex].type])) {
        attypes[toIndex++] = attypes[fromIndex];
      }
    }
    attypes = attypes.sublist(0, toIndex);
  }

  if (noise && timecnt > 1200) {
    logger.warning(
      timecnt > TZ_MAX_TIMES
          ? 'Reference clients mishandle more than $TZ_MAX_TIMES transition times'
          : 'Pre-2014 clients may mishandle more than 1200 transition times.',
    );
  }

  // Transfer

  // TODO: Is `inUtc` correct here?
  // FIXME: Do these have to be contiguous bytes?
  final ats = attypes
      .map((it) =>
          UnixEpochSeconds(it.at.inUtc.durationSinceUnixEpoch.roundToSeconds()))
      .toList();
  final types = attypes.map((it) => it.type).toList();

  // Correct for leap seconds.

  for (var i = 0; i < timecnt; ++i) {
    // TODO: use binary search
    var j = leapcnt;
    while (--j >= 0) {
      final leapSecond = leapSeconds[j];
      if (ats[i] > leapSecond.transition - leapSecond.correction) {
        ats[i] += leapSecond.correction;
        break;
      }
    }
  }

  final rangeall = _TimeRange(
    defaultType: defaultType,
    base: 0,
    count: timecnt,
    leapBase: 0,
    leapCount: leapcnt,
    leapExpiry: false,
  );
  final range64 = rangeall.limit(
    lo_time,
    [hi_time, redundant_time - Seconds(min_time < redundant_time ? 1 : 0)].max,
    ats,
    types,
  );
  final range32 = range64.limit(minTime32, maxTime32, ats, types);

  // TZif version 4 is needed if a no-op transition is appended to indicate the
  // expiration of the leap second table, or if the first leap second transition
  // is not to a +1 or -1 correction.
  for (final range in [if (bloat.wantsBloat) range32, range64]) {
    if (range.leapExpiry) {
      if (noise) {
        logger.warning(
          '$name: Pre-2021b clients may mishandle leap second expiry.',
        );
      }
      version = TzifVersion.v4;
    }
    if (range.leapCount > 0 &&
        leapSeconds[range.leapBase].correction.absolute != const Seconds(1)) {
      if (noise) {
        logger.warning(
          '$name: Pre-2021b clients may mishandle leap second table truncation.',
        );
      }
      version = TzifVersion.v4;
    }
    if (version == TzifVersion.v4) break;
  }

  final file = File(outname);
  await file.directory.create(recursive: true);
  final fp = file.openWrite();

  for (var pass = 1; pass <= 2; pass++) {
    // register ptrdiff_t thistimei, thistimecnt, thistimelim;
    // register int thisleapi, thisleapcnt, thisleaplim;
    // struct tzhead tzh;
    // int pretranstype = -1, thisdefaulttype;
    // bool locut, hicut, thisleapexpiry;
    // zic_t lo, thismin, thismax;
    // int old0;
    // char omittype[TZ_MAX_TYPES];
    // int typemap[TZ_MAX_TYPES];
    // int thistypecnt, stdcnt, utcnt;
    // char thischars[TZ_MAX_CHARS];
    // int thischarcnt;
    int thisdefaulttype;
    final int thistimei;
    int thistimecnt;
    final bool toomanytimes;
    final int thisleapi;
    int thisleapcnt;
    bool thisleapexpiry;
    final UnixEpochSeconds thismin;
    final UnixEpochSeconds thismax;
    // int indmap[TZ_MAX_CHARS];

    if (pass == 1) {
      thisdefaulttype = range32.defaultType;
      thistimei = range32.base;
      thistimecnt = range32.count;
      toomanytimes = thistimecnt >> 31 >> 1 != 0;
      thisleapi = range32.leapBase;
      thisleapcnt = range32.leapCount;
      thisleapexpiry = range32.leapExpiry;
      thismin = minTime32;
      thismax = maxTime32;
    } else {
      thisdefaulttype = range64.defaultType;
      thistimei = range64.base;
      thistimecnt = range64.count;
      toomanytimes = thistimecnt >> 31 >> 31 >> 2 != 0;
      thisleapi = range64.leapBase;
      thisleapcnt = range64.leapCount;
      thisleapexpiry = range64.leapExpiry;
      thismin = min_time;
      thismax = max_time;
    }
    if (toomanytimes) logger.error('Too many transition times');

    final locut = thismin < lo_time && lo_time <= thismax;
    var hicut = thismin <= hi_time && hi_time < thismax;
    final thistimelim = thistimei + thistimecnt;
    final omittype = List.generate(TZ_MAX_TYPES, (index) => index < typecnt);

    // Determine whether to output a transition before the first transition in
    // range. This is needed when the output is truncated at the start, and is
    // also useful when catering to buggy 32-bit clients that do not use time
    // type 0 for timestamps before the first transition.
    var pretranstype = -1;
    if ((locut || (pass == 1 && thistimei > 0)) &&
        !(thistimecnt > 0 && ats[thistimei] == lo_time)) {
      pretranstype = thisdefaulttype;
      omittype[pretranstype] = false;
    }

    // Arguably the default time type in the 32-bit data should be
    // `range32.defaultType`, which is suited for timestamps just before
    // `ZIC32_MIN`. However, zic traditionally used the time type of the
    // indefinite past instead. Internet RFC 8532 says readers should ignore
    // 32-bit data, so this discrepancy matters only to obsolete readers where
    // the traditional type might be more appropriate even if it's "wrong". So,
    // use the historical zic value, unless -r specifies a low cutoff that
    // excludes some 32-bit timestamps.
    if (pass == 1 && lo_time <= thismin) thisdefaulttype = range64.defaultType;

    if (locut) thisdefaulttype = unspecifiedtype;
    omittype[thisdefaulttype] = false;
    for (var i = thistimei; i < thistimelim; i++) {
      omittype[types[i]] = false;
    }
    if (hicut) omittype[unspecifiedtype] = false;

    // Reorder types to make `THISDEFAULTTYPE` type 0. Use `TYPEMAP` to swap
    // `OLD0` and `THISDEFAULTTYPE` so that `THISDEFAULTTYPE` appears as type 0
    // in the output instead of `OLD0`. `TYPEMAP` also omits unused types.
    final old0 = omittype.indexOf(false);

    // `LEAVE_SOME_PRE_2011_SYSTEMS_IN_THE_LURCH` is undefined

    /*
    ** For some pre-2011 systems: if the last-to-be-written
    ** standard (or daylight) type has an offset different from the
    ** most recently used offset,
    ** append an (unused) copy of the most recently used type
    ** (to help get global "altzone" and "timezone" variables
    ** set correctly).
    */
    String charsSubstring(int desigidxIndex) {
      final start = desigidx[desigidxIndex];
      final end = chars.indexOf('\x00', start);
      return chars.substring(start, end);
    }

    if (bloat.wantsBloat) {
      var hidst = -1;
      var histd = -1;
      var mrudst = -1;
      var mrustd = -1;
      var type = 0;
      if (pretranstype >= 0) {
        if (isdsts[pretranstype] != 0) {
          mrudst = pretranstype;
        } else {
          mrustd = pretranstype;
        }
      }
      for (var i = thistimei; i < thistimelim; i++) {
        if (isdsts[types[i]] != 0) {
          mrudst = types[i];
        } else {
          mrustd = types[i];
        }
      }
      for (var i = old0; i < typecnt; i++) {
        final h = (i == old0
            ? thisdefaulttype
            : i == thisdefaulttype
                ? old0
                : i);
        if (omittype[h]) continue;

        if (isdsts[h] != 0) {
          hidst = i;
        } else {
          histd = i;
        }
      }
      if (hidst >= 0 &&
          mrudst >= 0 &&
          hidst != mrudst &&
          utoffs[hidst] != utoffs[mrudst]) {
        isdsts[mrudst] = -1;
        type = addtype(
          utoffs[mrudst],
          charsSubstring(mrudst),
          true,
          TimeReference.from(isStd: ttisstds[mrudst], isUt: ttisuts[mrudst]),
        );
        isdsts[mrudst] = 1;
        omittype[type] = false;
      }
      if (histd >= 0 &&
          mrustd >= 0 &&
          histd != mrustd &&
          utoffs[histd] != utoffs[mrustd]) {
        isdsts[mrustd] = -1;
        type = addtype(
          utoffs[mrustd],
          charsSubstring(mrustd),
          false,
          TimeReference.from(isStd: ttisstds[mrustd], isUt: ttisuts[mrustd]),
        );
        isdsts[mrustd] = 0;
        omittype[type] = false;
      }
    }
    final typemap = List.filled(TZ_MAX_TYPES, 0);
    var thistypecnt = 0;
    for (var i = old0; i < typecnt; i++) {
      if (!omittype[i]) {
        typemap[i == old0
            ? thisdefaulttype
            : i == thisdefaulttype
                ? old0
                : i] = thistypecnt++;
      }
    }

    final indmap = List.filled(TZ_MAX_CHARS, -1);
    var stdcnt = 0;
    var utcnt = 0;
    var thischars = '';
    for (var i = old0; i < typecnt; i++) {
      if (omittype[i]) continue;
      if (ttisstds[i]) stdcnt = thistypecnt;
      if (ttisuts[i]) utcnt = thistypecnt;
      if (indmap[desigidx[i]] >= 0) continue;

      final thisabbr = charsSubstring(i);
      var index = thischars.indexOfOrNull(thisabbr);
      if (index == null) {
        index = thischars.length;
        thischars += thisabbr;
        thischars += '\x00';
      }
      indmap[desigidx[i]] = index;
    }
    if (pass == 1 && !bloat.wantsBloat) {
      hicut = thisleapexpiry = false;
      pretranstype = -1;
      thistimecnt = thisleapcnt = 0;
      thistypecnt = 1;
      // TODO(JonasWanke): Does this always write a null byte?
      thischars = thischars.isEmpty ? '\x00' : thischars.substring(0, 1);
    }

    final header = TzifHeader(
      version: version,
      isutcnt: utcnt,
      isstdcnt: stdcnt,
      leapcnt: thisleapcnt + (thisleapexpiry ? 1 : 0),
      timecnt: (pretranstype >= 0 ? 1 : 0) + thistimecnt + (hicut ? 1 : 0),
      typecnt: thistypecnt,
      charcnt: thischars.length,
    );
    header.writeTo(fp);
    if (pass == 1 && !bloat.wantsBloat) {
      // Output a minimal data block with just one time type.
      // utoff
      fp.addU32(0);
      // dst, index of abbreviation, empty-string abbreviation
      fp.add([0, 0, 0]);
      continue;
    }

    // Output a LO_TIME transition if needed; see `limitrange`. But do not go
    // below the minimum representable value for this pass.
    final lo = pass == 1 && lo_time < min_time ? min_time : lo_time;

    // write `timecnt` × transition time
    if (pretranstype >= 0) {
      fp.puttzcodepass(lo.durationSinceUnixEpoch.inSeconds, pass);
    }
    for (var i = thistimei; i < thistimelim; ++i) {
      fp.puttzcodepass(ats[i].durationSinceUnixEpoch.inSeconds, pass);
    }
    if (hicut) {
      fp.puttzcodepass(hi_time.durationSinceUnixEpoch.inSeconds + 1, pass);
    }

    // write `timecnt` × transition type
    if (pretranstype >= 0) fp.addU8(typemap[pretranstype]);
    for (var i = thistimei; i < thistimelim; i++) {
      fp.addU8(typemap[types[i]]);
    }
    if (hicut) fp.addU8(typemap[unspecifiedtype]);

    // write `typecnt` × local time type record
    for (var i = old0; i < typecnt; i++) {
      final h = (i == old0
          ? thisdefaulttype
          : i == thisdefaulttype
              ? old0
              : i);
      if (!omittype[h]) {
        fp.addI32(utoffs[h].inSeconds);
        // TODO(JonasWanke): convert `isdsts` to bools
        assert(isdsts[h] == 0 || isdsts[h] == 1);
        fp.addU8(isdsts[h]);
        fp.addU8(indmap[desigidx[h]]);
      }
    }

    // write time zone designations (`charcnt` characters)
    if (thischars.isNotEmpty) {
      assert(thischars.isAscii);
      fp.add(thischars.codeUnits);
    }

    // write `leapcnt` × leap-second record
    final thisleaplim = thisleapi + thisleapcnt;
    for (var i = thisleapi; i < thisleaplim; ++i) {
      final UnixEpochSeconds todo;

      if (leapSeconds[i].rolling != 0) {
        int j;
        if (timecnt == 0 || leapSeconds[i].transition < ats.first) {
          j = 0;
          while (isdsts[j] != 0) {
            if (++j >= typecnt) {
              j = 0;
              break;
            }
          }
        } else {
          j = 1;
          while (j < timecnt && leapSeconds[i].transition >= ats[j]) {
            ++j;
          }
          j = types[j - 1];
        }
        todo = leapSeconds[i].transition - utoffs[j];
      } else {
        todo = leapSeconds[i].transition;
      }
      fp.puttzcodepass(todo.durationSinceUnixEpoch.inSeconds, pass);
      fp.addI32(leapSeconds[i].correction.inSeconds);
    }
    if (thisleapexpiry) {
      // Append a no-op leap correction indicating when the leap second table
      // expires. Although this does not conform to Internet RFC 8536, most
      // clients seem to accept this and the plan is to amend the RFC to allow
      // this in version 4 TZif files.
      fp.puttzcodepass(leapexpires.durationSinceUnixEpoch.inSeconds, pass);
      fp.addI32(
        thisleaplim > 0 ? leapSeconds[thisleaplim - 1].correction.inSeconds : 0,
      );
    }

    // write `isstdcnt` × standard/wall indicator
    if (stdcnt != 0) {
      for (var i = old0; i < typecnt; i++) {
        if (!omittype[i]) fp.addBool(ttisstds[i]);
      }
    }

    // write `isutcnt` × UT/local indicators
    if (utcnt != 0) {
      for (var i = old0; i < typecnt; i++) {
        if (!omittype[i]) fp.addBool(ttisuts[i]);
      }
    }
  }

  TzifFooter(string).writeTo(fp);
  // close_file(fp, directory, name, tempname);
  // rename_dest(tempname, name);
  await fp.close();
}

/// Original: `timerange`
@immutable
final class _TimeRange {
  const _TimeRange({
    required this.defaultType,
    required this.base,
    required this.count,
    required this.leapBase,
    required this.leapCount,
    required this.leapExpiry,
  })  : assert(defaultType >= 0),
        assert(base >= 0),
        assert(count >= 0),
        assert(leapBase >= 0),
        assert(leapCount >= 0),
        assert(leapCount >= 0);

  /// Original: `defaulttype`
  final int defaultType;
  final int base;
  final int count;

  /// Original: `leapbase`
  final int leapBase;

  /// Original: `leapcount`
  final int leapCount;

  /// Original: `leapexpiry`
  final bool leapExpiry;

  /// Original: `limitrange`
  _TimeRange limit(
    UnixEpochSeconds lo,
    UnixEpochSeconds hi,
    List<UnixEpochSeconds> ats,
    List<int> types,
  ) {
    var r = this;

    // Omit ordinary transitions < LO.
    while (0 < r.count && ats[r.base] < lo) {
      r = r.copyWith(
        defaultType: types[r.base],
        count: r.count - 1,
        base: r.base + 1,
      );
    }

    // Omit as many initial leap seconds as possible, such that the first leap
    // second in the truncated list is <= LO, and is a positive leap second iff
    // it has a positive correction. This supports common TZif readers that
    // assume that the first leap second is positive iff its correction is
    // positive.
    while (1 < r.leapCount && leapSeconds[r.leapBase + 1].transition <= lo) {
      r = r.copyWith(
        leapCount: r.leapCount - 1,
        leapBase: r.leapBase + 1,
      );
    }
    while (0 < r.leapBase &&
        ((leapSeconds[r.leapBase - 1].correction <
                leapSeconds[r.leapBase].correction) !=
            leapSeconds[r.leapBase].correction.isPositive)) {
      r = r.copyWith(
        leapCount: r.leapCount + 1,
        leapBase: r.leapBase - 1,
      );
    }

    // Omit ordinary and leap second transitions greater than HI + 1.
    if (hi < max_time) {
      while (0 < r.count && hi + const Seconds(1) < ats[r.base + r.count - 1]) {
        r = r.copyWith(count: r.count - 1);
      }
      while (0 < r.leapCount &&
          hi + const Seconds(1) <
              leapSeconds[r.leapBase + r.leapCount - 1].transition) {
        r = r.copyWith(leapCount: r.leapCount - 1);
      }
    }

    // Determine whether to append an expiration to the leap second table.
    return r.copyWith(
      leapExpiry: leapexpires.durationSinceUnixEpoch.isPositive &&
          leapexpires - const Seconds(1) <= hi,
    );
  }

  _TimeRange copyWith({
    int? defaultType,
    int? base,
    int? count,
    int? leapBase,
    int? leapCount,
    bool? leapExpiry,
  }) {
    return _TimeRange(
      defaultType: defaultType ?? this.defaultType,
      base: base ?? this.base,
      count: count ?? this.count,
      leapBase: leapBase ?? this.leapBase,
      leapCount: leapCount ?? this.leapCount,
      leapExpiry: leapExpiry ?? this.leapExpiry,
    );
  }
}

LimitOr<DateTime> rpytime(RuleClause clause, Year wantedYear) {
  // TODO(JonasWanke): cleanup
  return LimitOrValue(
    calculateRuleClauseDateTime(
      clause.month,
      clause.dayCode,
      clause.time,
      LimitOrValue(wantedYear),
    ),
  );
}

/// Original: `doabbr`
String doabbr(
  ZoneRule zoneRule,
  String? abbreviationVariable,
  Seconds offset, {
  required bool isDst,
  bool addQuotes = false,
}) {
  final abbreviation = switch (zoneRule.name) {
    EitherZoneRuleName(:final standard, :final dst) => isDst ? dst : standard,
    // TODO(JonasWanke): `disable_percent_s`
    FormattedWithVariableZoneRuleName(:final start, :final end) =>
      '$start${abbreviationVariable!}$end',
    FormattedOffsetZoneRuleName() =>
      _formatOffset(zoneRule.standardOffset.asSeconds + offset),
    SimpleZoneRuleName(:final value) => value,
  };
  if (!addQuotes) return abbreviation;

  final indexOfNonLetter = abbreviation.indexOfOrNull(RegExp(r'[^A-Za-z]'));
  if (indexOfNonLetter == null) return abbreviation;

  final letters = abbreviation.substring(0, indexOfNonLetter);
  final nonLetters = abbreviation.substring(indexOfNonLetter);
  return '$letters<$nonLetters>';
}

/// Original: `abbroffset`
String _formatOffset(Seconds offset) {
  final sign = offset.isNegative ? '-' : '+';
  final (hours, minutes, seconds) = offset.absolute.asHoursAndMinutesAndSeconds;
  if (hours.inHours > 100) {
    logger.error('%z UT offset magnitude exceeds 99:59:59');
    return '%z';
  }

  final buffer = StringBuffer(sign);
  buffer.write(hours.inHours.toString().padLeft(2, '0'));
  if (!minutes.isZero || !seconds.isZero) {
    buffer.write(minutes.inMinutes.toString().padLeft(2, '0'));
    if (!seconds.isZero) {
      buffer.write(seconds.inSeconds.toString().padLeft(2, '0'));
    }
  }
  return buffer.toString();
}

var charcnt = 0;

// This must be at least 242 for Europe/London with 'zic -b fat'.
const TZ_MAX_TIMES = 2000;

// This must be at least 18 for Europe/Vilnius with 'zic -b fat'.
const TZ_MAX_TYPES = 256;
typedef attype = ({DateTime at, bool dontMerge, int type});
var attypes = <attype>[];
int get timecnt => attypes.length;
var utoffs = <Seconds>[];
var isdsts = <int>[];
var desigidx = <int>[];
var ttisstds = <bool>[];
var ttisuts = <bool>[];
// TODO(JonasWanke): Merge this and [desigidx] to `List<String>`
var chars = '';

int get typecnt => utoffs.length;

/// Original: `addtt`
void addtt(DateTime startTime, int type) {
  attypes.add((at: startTime, dontMerge: false, type: type));
}

/// Original: `addtype`
int addtype(
  Seconds utoff,
  String abbr,
  bool isdst,
  TimeReference timeReference,
) {
  if (-1 - 2147483647 > utoff.inSeconds || utoff.inSeconds > 2147483647) {
    throw ArgumentError('UT offset out of range');
  }

  final j = chars.indexOfOrNull(abbr);
  final jFallback = chars.length;
  if (j == null) {
    newabbr(abbr);
  } else {
    /* If there's already an entry, return its index.  */
    for (var i = 0; i < typecnt; i++) {
      if (utoff == utoffs[i] &&
          (isdst ? 1 : 0) == isdsts[i] &&
          j == desigidx[i] &&
          timeReference.isStd == ttisstds[i] &&
          timeReference.isUt == ttisuts[i]) {
        return i;
      }
    }
  }
  /*
  ** There isn't one; add a new one, unless there are already too
  ** many.
  */
  if (typecnt >= TZ_MAX_TYPES) {
    throw StateError('Too many local time types');
  }
  utoffs.add(utoff);
  isdsts.add(isdst ? 1 : 0);
  ttisstds.add(timeReference.isStd);
  ttisuts.add(timeReference.isUt);
  desigidx.add(j ?? jFallback);
  return typecnt - 1;
}

/// Maximum number of abbreviation characters (limited by what unsigned chars
/// can hold).
///
/// This must be at least 40 for America/Anchorage.
const TZ_MAX_CHARS = 50;

const ZIC_MAX_ABBR_LEN_WO_WARN = 6;

const noise = true;

Seconds oadd(SecondsDuration t1, SecondsDuration t2) {
  // TODO(JonasWanke): Verify
  return t1.asSeconds + t2;
}

/// Original: `newabbr`
void newabbr(String string) {
/* This string was in the Factory zone through version 2016f.  */
  const grandparented = 'Local time zone must be set--see zic manual page';
  if (string != grandparented) {
    final firstDifferingIndex = string.characters.firstIndexWhereOrNull((it) =>
        !('A' <= it && it <= 'Z' ||
            'a' <= it && it <= 'z' ||
            '0' <= it && it <= '9' ||
            it == '-' ||
            it == '+'));
    String? warning;
    if (firstDifferingIndex == null) {
      warning = 'Time zone abbreviation differs from POSIX standard';
    } else {
      if (noise && firstDifferingIndex < 3) {
        warning = 'Time zone abbreviation has fewer than 3 characters';
      }
      if (firstDifferingIndex > ZIC_MAX_ABBR_LEN_WO_WARN) {
        warning = 'Time zone abbreviation has too many characters';
      }
    }
    if (warning != null) logger.warning('$warning (“$string”)');
  }

  if (charcnt + string.length + 1 > TZ_MAX_CHARS) {
    throw ArgumentError('too many, or too long, time zone abbreviations');
  }

  chars += string;
  chars += '\x00';
}

/// https://www.rfc-editor.org/rfc/rfc8536.html#section-3.1
@immutable
final class TzifHeader {
  const TzifHeader({
    required this.version,
    required this.isutcnt,
    required this.isstdcnt,
    required this.leapcnt,
    required this.timecnt,
    required this.typecnt,
    required this.charcnt,
  })  : assert(0 <= isutcnt && isutcnt < 1 << 32),
        assert(isutcnt == 0 || isutcnt == typecnt),
        assert(0 <= isstdcnt && isstdcnt < 1 << 32),
        assert(isstdcnt == 0 || isstdcnt == typecnt),
        assert(0 <= leapcnt && leapcnt < 1 << 32),
        assert(0 <= timecnt && timecnt < 1 << 32),
        assert(0 < typecnt && typecnt < 1 << 32),
        assert(0 < charcnt && charcnt < 1 << 32);

  /// The four-octet ASCII [RFC20](https://www.rfc-editor.org/rfc/rfc20)
  /// sequence "TZif" (0x54 0x5A 0x69 0x66), which identifies the file as
  /// utilizing the Time Zone Information Format.
  static const magic = [0x54, 0x5A, 0x69, 0x66];

  /// An octet identifying the version of the file's format.
  final TzifVersion version;

  // TODO(JonasWanke): Rename these for clarity
  /// A four-octet unsigned integer specifying the number of UT/local
  /// indicators contained in the data block -- MUST either be zero or equal to
  /// `typecnt`.
  ///
  /// Original: `isutcnt`
  final int isutcnt;

  /// A four-octet unsigned integer specifying the number of standard/wall
  /// indicators contained in the data block -- MUST either be zero or equal to
  /// `typecnt`.
  ///
  /// Original: `isstdcnt`
  final int isstdcnt;

  /// A four-octet unsigned integer specifying the number of leap-second
  /// records contained in the data block.
  ///
  /// Original: `leapcnt`
  final int leapcnt;

  /// A four-octet unsigned integer specifying the number of transition times
  /// contained in the data block.
  ///
  /// Original: `timecnt`
  final int timecnt;

  /// A four-octet unsigned integer specifying the number of local time type
  /// records contained in the data block -- MUST NOT be zero. (Although local
  /// time type records convey no useful information in files that have
  /// nonempty TZ strings but no transitions, at least one such record is
  /// nevertheless required because many TZif readers reject files that have
  /// zero time types.)
  ///
  /// Original: `typecnt`
  final int typecnt;

  /// A four-octet unsigned integer specifying the total number of octets used
  /// by the set of time zone designations contained in the data block -- MUST
  /// NOT be zero. The count includes the trailing NUL (0x00) octet at the end
  /// of the last time zone designation.
  ///
  /// Original: `charcnt`
  final int charcnt;

  void writeTo(Sink<List<int>> output) {
    output.add(magic);
    output.addU8(version.value);
    output.add(List.filled(15, 0));
    output.addU32(isutcnt);
    output.addU32(isstdcnt);
    output.addU32(leapcnt);
    output.addU32(timecnt);
    output.addU32(typecnt);
    output.addU32(charcnt);
  }
}

enum TzifVersion {
  /// Version 1: The file contains only the version 1 header and data block.
  /// Version 1 files MUST NOT contain a version 2+ header, data block, or
  /// footer.
  v1(0),

  /// Version 2: The file MUST contain the version 1 header and data block, a
  /// version 2+ header and data block, and a footer. The TZ string in the
  /// footer ([TzifFooter]), if non-empty, MUST strictly adhere to the
  /// requirements for the TZ environment variable as defined in Section 8.3 of
  /// the "Base Definitions" volume of [POSIX](http://pubs.opengroup.org/onlinepubs/9699919799/)
  /// and MUST encode the POSIX portable character set as ASCII.
  v2(0x32),

  /// Version 3: The file MUST contain the version 1 header and data block, a
  /// version 2+ header and data block, and a footer. The TZ string in the
  /// footer ([TzifFooter]), if non-empty, MUST conform to POSIX requirements
  /// with ASCII encoding, except that it MAY use the TZ string extensions
  /// described below (Section 3.3.1).
  v3(0x33),

  /// Version 4: The file MUST conform to all version 3 requirements, except
  /// that the leap-second records MAY be truncated at the start, and MAY
  /// contain an expiration time.
  v4(0x34);

  const TzifVersion(this.value) : assert(0 <= value && value < 256);

  final int value;
}

/// https://www.rfc-editor.org/rfc/rfc8536.html#section-3.3
@immutable
final class TzifFooter {
  TzifFooter(this.timeZoneString) : assert(timeZoneString.isAscii);

  /// A rule for computing local time changes after the last transition time
  /// stored in the version 2+ data block. The string is either empty or uses
  /// the expanded format of the "TZ" environment variable as defined in
  /// Section 8.3 of the "Base Definitions" volume of [POSIX](http://pubs.opengroup.org/onlinepubs/9699919799/)
  /// with ASCII encoding, possibly utilizing extensions described below
  /// (Section 3.3.1) in version 3 files. If the string is empty, the
  /// corresponding information is not available. If the string is non-empty and
  /// one or more transitions appear in the version 2+ data, the string MUST be
  /// consistent with the last version 2+ transition. In other words, evaluating
  /// the TZ string at the time of the last transition should yield the same
  /// time type as was specified in the last transition. The string MUST NOT
  /// contain NUL octets or be NUL-terminated, and it SHOULD NOT begin with the
  /// ':' (colon) character.
  final String timeZoneString;

  void writeTo(Sink<List<int>> output) {
    output.addU8(0x0A);
    output.add(timeZoneString.codeUnits);
    output.addU8(0x0A);
  }
}

extension on Sink<List<int>> {
  // ignore: avoid_positional_boolean_parameters
  void addBool(bool value) => addU8(value ? 1 : 0);
  void addU8(int value) {
    assert(0 <= value && value < 1 << 8);
    add([value]);
  }

  /// Original: `puttzcode`
  void addU32(int value) {
    assert(0 <= value && value < 1 << 32);
    add(value.asU32BigEndianBytes);
  }

  /// Original: `puttzcode`
  void addI32(int value) {
    assert(-(1 << 31) <= value && value < (1 << 31) - 1);
    add(value.asI32BigEndianBytes);
  }

  // TODO(JonasWanke): Accept `UnixEpochSeconds value` instead of `int`
  void puttzcodepass(int value, int pass) {
    if (pass == 1) {
      addI32(value);
    } else {
      add(value.asI64BigEndianBytes);
    }
  }
}

extension on int {
  /// Original: `convert`
  List<int> get asU32BigEndianBytes {
    assert(0 <= this && this < 1 << 32);
    return _as32BitBigEndianBytes;
  }

  /// Original: `convert`
  List<int> get asI32BigEndianBytes {
    assert(-(1 << 31) <= this && this < (1 << 31) - 1);
    return _as32BitBigEndianBytes;
  }

  List<int> get _as32BitBigEndianBytes {
    return [
      (this >> 24) & 0xFF,
      (this >> 16) & 0xFF,
      (this >> 8) & 0xFF,
      this & 0xFF,
    ];
  }

  /// Original: `convert64`
  List<int> get asI64BigEndianBytes {
    return [
      (this >> 56) & 0xFF,
      (this >> 48) & 0xFF,
      (this >> 40) & 0xFF,
      (this >> 32) & 0xFF,
      (this >> 24) & 0xFF,
      (this >> 16) & 0xFF,
      (this >> 8) & 0xFF,
      this & 0xFF,
    ];
  }
}
