import 'package:clock_app/voice/parsed_alarm.dart';

/// Deterministic, offline parser for common spoken alarm commands.
///
/// Speech transcription is handled by the device's speech recognizer. This
/// class performs no network requests and uses no machine-learning service.
class LocalAlarmParser {
  static const String _numberWordPattern =
      r'(?:zero|one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve|thirteen|fourteen|fifteen|sixteen|seventeen|eighteen|nineteen|twenty(?:\s+(?:one|two|three|four|five|six|seven|eight|nine))?|thirty(?:\s+(?:one|two|three|four|five|six|seven|eight|nine))?|forty(?:\s+(?:one|two|three|four|five|six|seven|eight|nine))?|fifty(?:\s+(?:one|two|three|four|five|six|seven|eight|nine))?)';
  static const String _minuteWordPattern =
      '(?:oh\\s+(?:one|two|three|four|five|six|seven|eight|nine)|$_numberWordPattern)';
  static const String _durationNumberPattern =
      '(?:an?|couple|$_numberWordPattern|sixty(?:\\s+(?:one|two|three|four|five|six|seven|eight|nine))?|seventy(?:\\s+(?:one|two|three|four|five|six|seven|eight|nine))?|eighty(?:\\s+(?:one|two|three|four|five|six|seven|eight|nine))?|ninety(?:\\s+(?:one|two|three|four|five|six|seven|eight|nine))?|\\d+)';

  static String? _failureMessage;

  static String? get failureMessage => _failureMessage;

  const LocalAlarmParser._();

  static ParsedAlarm? parse(String transcript, {DateTime? now}) {
    _failureMessage = null;
    final text = _normalize(transcript);
    if (text.isEmpty) {
      _failureMessage = 'No speech was detected. Please try again.';
      return null;
    }

    final reference = now ?? DateTime.now();
    final recurrence = _parseRecurrence(text, reference);
    if (recurrence.error != null) {
      _failureMessage = recurrence.error;
      return null;
    }
    final relativeDateTime = _parseRelativeDateTime(text, reference);
    final explicitDate =
        relativeDateTime == null ? _parseExplicitDate(text, reference) : null;
    final time = relativeDateTime == null
        ? _parseClockTime(
            text,
            reference,
            explicitDate,
            recurrence.value != 'once',
          )
        : _ClockTime(relativeDateTime.hour, relativeDateTime.minute);
    DateTime? date = recurrence.value == 'once'
        ? relativeDateTime ?? explicitDate
        : recurrence.value == 'interval'
            ? explicitDate ?? _intervalStartDate(text, reference)
            : null;

    if (recurrence.value == 'interval' && time != null) {
      date = _resolveIntervalStart(
        text,
        reference,
        date,
        time,
        recurrence,
      );
    }

    if (time != null && date != null) {
      var scheduled = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      if (!scheduled.isAfter(reference) &&
          recurrence.value == 'once' &&
          _hasPlainOneTimeWeekday(text)) {
        date = date.add(const Duration(days: 7));
        scheduled = scheduled.add(const Duration(days: 7));
      }
      if (!scheduled.isAfter(reference)) {
        _failureMessage =
            'That time has already passed. Please choose a future time.';
        return null;
      }
    }

    return ParsedAlarm(
      hour: time?.hour,
      minute: time?.minute,
      recurrence: recurrence.value,
      days: recurrence.days,
      label: _extractLabel(text),
      date: date == null ? null : DateTime(date.year, date.month, date.day),
      intervalValue: recurrence.intervalValue,
      intervalUnit: recurrence.intervalUnit,
      monthDay: recurrence.monthDay,
      weekOfMonth: recurrence.weekOfMonth,
    );
  }

  static String _normalize(String input) {
    var value = input
        .toLowerCase()
        .replaceAll(RegExp(r'[\u2010\u2011\u2012\u2013\u2014]'), '-')
        .replaceAll(RegExp(r'a\s*\.\s*m\s*\.?'), 'am')
        .replaceAll(RegExp(r'p\s*\.\s*m\s*\.?'), 'pm')
        .replaceAll(RegExp(r'\ba\s+m\b'), 'am')
        .replaceAll(RegExp(r'\bp\s+m\b'), 'pm')
        .replaceAll(RegExp(r'\b(?:the\s+)?following\b'), 'coming')
        .replaceAll(RegExp(r'\bupcoming\b'), 'coming')
        .replaceAll(RegExp(r'\beveryday\b'), 'every day')
        .replaceAll(RegExp(r'\bweek\s+days?\b'), 'weekdays')
        .replaceAll(RegExp(r'\bweek\s+ends?\b'), 'weekends')
        .replaceAll(RegExp(r'\bwork\s+days?\b'), 'workdays')
        .replaceAllMapped(
          RegExp(r'(\d)\.(\d)'),
          (match) => '${match.group(1)}:${match.group(2)}',
        );
    value = value.replaceAllMapped(
      RegExp(
        r'\b(mon(?:day)?|tue(?:sday)?|wed(?:nesday)?|thu(?:rsday)?|fri(?:day)?|sat(?:urday)?|sun(?:day)?)\s*-\s*(mon(?:day)?|tue(?:sday)?|wed(?:nesday)?|thu(?:rsday)?|fri(?:day)?|sat(?:urday)?|sun(?:day)?)\b',
      ),
      (match) => '${match.group(1)} to ${match.group(2)}',
    );
    return value
        .replaceAllMapped(
          RegExp(r'\b([a-z]+)-([a-z]+)\b'),
          (match) => '${match.group(1)} ${match.group(2)}',
        )
        .replaceAll(RegExp(r"[^a-z0-9:/\s']"), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static _Recurrence _parseRecurrence(String text, DateTime reference) {
    final days = _extractDays(text);
    final interval = _parseIntervalRecurrence(text, days, reference);
    if (interval != null) return interval;

    final hasOneTimeDay = RegExp(
      r'\b(?:next|this|coming)\s+(?:mon(?:day)?|tue(?:sday)?|wed(?:nesday)?|thu(?:rsday)?|fri(?:day)?|sat(?:urday)?|sun(?:day)?|weekend)\b',
    ).hasMatch(text);
    if (hasOneTimeDay) return const _Recurrence('once', []);

    final excludedDays = _extractExcludedDays(text);
    final activeDays = List<String>.from(days)
      ..removeWhere(excludedDays.contains);

    if (RegExp(
      r'\b(?:except(?:\s+for)?|excluding|but not|not on)\s+(?:public\s+|bank\s+|national\s+)?holidays?\b',
    ).hasMatch(text)) {
      return const _Recurrence.unsupported(
        'Holiday calendars vary by location. Please choose the exact days instead.',
      );
    }

    if (RegExp(
      r'\b(daily|every day|each day|each and every day|every single day|once a day|once daily|day after day|all days|all week|seven days a week|7 days a week|nightly|every morning|every afternoon|every evening|every night|each morning|each afternoon|each evening|each night)\b',
    ).hasMatch(text)) {
      if (RegExp(
        r'\b(?:except(?:\s+for)?|excluding|but not)\s+(?:the\s+)?weekends?\b',
      ).hasMatch(text)) {
        return const _Recurrence('weekdays', []);
      }
      if (RegExp(
        r'\b(?:except(?:\s+for)?|excluding|but not)\s+(?:the\s+)?weekdays?\b',
      ).hasMatch(text)) {
        return const _Recurrence('weekends', []);
      }
      if (excludedDays.isNotEmpty) {
        final selected = List<String>.from(_weekdayOrder)
          ..removeWhere(excludedDays.contains);
        return _Recurrence('weekly', selected);
      }
      return const _Recurrence('daily', []);
    }
    if (RegExp(
      r'\b(weekdays?|workdays?|working days?|business days?|school days?|office days?|weekdays only|during the week|monday\s+(?:to|through|thru|until|till)\s+friday|mon\s+(?:to|through|thru)\s+fri)\b',
    ).hasMatch(text)) {
      if (excludedDays.isNotEmpty) {
        final selected = List<String>.from(_weekdayOrder.take(5))
          ..removeWhere(excludedDays.contains);
        return _Recurrence('weekly', selected);
      }
      return const _Recurrence('weekdays', []);
    }
    if (RegExp(
      r'\b(weekends?|weekends only|on the weekend|every saturday and sunday|saturday\s+(?:and|to|through|thru)\s+sunday|sat\s+(?:and|to|through|thru)\s+sun)\b',
    ).hasMatch(text)) {
      if (excludedDays.isNotEmpty) {
        final selected = <String>['saturday', 'sunday']
          ..removeWhere(excludedDays.contains);
        return _Recurrence('weekly', selected);
      }
      return const _Recurrence('weekends', []);
    }

    if (RegExp(
      r'\b(weekly|every week|each week|once a week|week after week)\b',
    ).hasMatch(text)) {
      return _Recurrence(
        'weekly',
        activeDays.isEmpty ? [_weekdayName(reference.weekday)] : activeDays,
      );
    }
    if (activeDays.length > 1 ||
        (activeDays.isNotEmpty && _hasRecurringDayCue(text))) {
      return _Recurrence('weekly', activeDays);
    }
    return const _Recurrence('once', []);
  }

  static _Recurrence? _parseIntervalRecurrence(
    String text,
    List<String> days,
    DateTime reference,
  ) {
    if (RegExp(r'\beach and every day\b').hasMatch(text)) return null;
    if (RegExp(
      r'\b(hourly|every hour|each hour|every minute|each minute|twice daily|twice a day|three times a day|multiple times a day)\b',
    ).hasMatch(text)) {
      return const _Recurrence.unsupported(
        'Repeats shorter than one day are not supported by Alarm yet.',
      );
    }
    if (RegExp(r'\b(?:alternate|alternating)\s+weekends?\b').hasMatch(text)) {
      return _Recurrence.interval(
        2,
        'weeks',
        const ['saturday', 'sunday'],
      );
    }
    if (RegExp(
      r'\b(?:alternate|alternating)\s+(?:weekdays?|workdays?|business\s+days?)\b',
    ).hasMatch(text)) {
      return _Recurrence.interval(2, 'weekdays', const []);
    }
    final repeatedWeekend = RegExp(
      r'\b(?:every|each)\s+(other|alternate|alternating|[a-z0-9\s]+?)\s+weekends?\b',
    ).firstMatch(text);
    if (repeatedWeekend != null) {
      final rawAmount = repeatedWeekend.group(1)!;
      final amount =
          const {'other', 'alternate', 'alternating'}.contains(rawAmount)
              ? 2
              : _numberValue(rawAmount);
      if (amount != null && amount > 0) {
        return amount == 1
            ? const _Recurrence('weekends', [])
            : _Recurrence.interval(
                amount,
                'weeks',
                const ['saturday', 'sunday'],
              );
      }
    }
    final repeatedWeekday = RegExp(
      r'\b(?:every|each)\s+(other|alternate|alternating|[a-z0-9\s]+?)\s+(weekdays?|workdays?|business\s+days?)\b',
    ).firstMatch(text);
    if (repeatedWeekday != null) {
      final rawAmount = repeatedWeekday.group(1)!;
      final amount =
          const {'other', 'alternate', 'alternating'}.contains(rawAmount)
              ? 2
              : _numberValue(rawAmount);
      if (amount != null && amount > 0) {
        return amount == 1
            ? const _Recurrence('weekdays', [])
            : _Recurrence.interval(amount, 'weekdays', const []);
      }
    }
    final alternateDay = RegExp(
      r'\b(?:every other|alternate|alternating)\s+(mon(?:day)?|tue(?:sday)?|wed(?:nesday)?|thu(?:rsday)?|fri(?:day)?|sat(?:urday)?|sun(?:day)?)s?\b',
    ).firstMatch(text);
    if (alternateDay != null) {
      final day = _canonicalWeekday(alternateDay.group(1)!);
      if (day != null) return _Recurrence.interval(2, 'weeks', [day]);
    }
    final numberedWeekday = RegExp(
      r'\bevery\s+(second|third|fourth|2nd|3rd|4th)\s+(mon(?:day)?|tue(?:sday)?|wed(?:nesday)?|thu(?:rsday)?|fri(?:day)?|sat(?:urday)?|sun(?:day)?)s?\b',
    ).firstMatch(text);
    if (numberedWeekday != null &&
        !RegExp(r'\bof\s+(?:each|every)\s+month\b').hasMatch(text)) {
      final amount = _numberValue(numberedWeekday.group(1)!);
      final day = _canonicalWeekday(numberedWeekday.group(2)!);
      if (amount != null && day != null) {
        return _Recurrence.interval(amount, 'weeks', [day]);
      }
    }
    if (RegExp(r'\b(fortnightly|every fortnight|once a fortnight|biweekly)\b')
        .hasMatch(text)) {
      return _Recurrence.interval(2, 'weeks', days);
    }
    if (RegExp(r'\b(quarterly|every quarter|once a quarter)\b')
        .hasMatch(text)) {
      return _Recurrence.interval(3, 'months', days);
    }
    final monthlyWeekday = _parseMonthlyWeekday(text);
    if (monthlyWeekday != null) return monthlyWeekday;
    if (RegExp(r'\b(monthly|every month|each month|once a month)\b')
        .hasMatch(text)) {
      return _Recurrence.interval(
        1,
        'months',
        days,
        monthDay: _extractMonthDay(text),
      );
    }
    if (RegExp(r'\b(yearly|annually|annual|every year|each year|once a year)\b')
        .hasMatch(text)) {
      return _Recurrence.interval(1, 'years', days);
    }

    final alternate = RegExp(
      r'\b(?:every other|alternate|alternating)\s+(day|week|month|year)s?\b',
    ).firstMatch(text);
    if (alternate != null) {
      return _Recurrence.interval(2, '${alternate.group(1)}s', days);
    }

    final match = RegExp(
      '\\b(?:(?:once\\s+)?every|each)\\s+'
      '((?:a\\s+)?couple(?:\\s+of)?|single|few|several|'
      '\\d+(?:st|nd|rd|th)?|$_durationNumberPattern)\\s+'
      '(minutes?|hours?|days?|weeks?|months?|years?)\\b',
    ).firstMatch(text);
    if (match == null) return null;
    final rawAmount = match.group(1)!.trim();
    final amount = rawAmount == 'single' ? 1 : _numberValue(rawAmount);
    if (amount == null || amount < 1) {
      return const _Recurrence.unsupported(
        'Please say an exact repeat interval, such as every 3 days.',
      );
    }
    final rawUnit = match.group(2)!;
    final unit = rawUnit.startsWith('minute')
        ? 'minutes'
        : rawUnit.startsWith('hour')
            ? 'hours'
            : rawUnit.startsWith('day')
                ? 'days'
                : rawUnit.startsWith('week')
                    ? 'weeks'
                    : rawUnit.startsWith('month')
                        ? 'months'
                        : 'years';

    if (unit == 'minutes') {
      if (amount % 1440 == 0) {
        final dayCount = amount ~/ 1440;
        return dayCount == 1
            ? const _Recurrence('daily', [])
            : _Recurrence.interval(dayCount, 'days', days);
      }
      return const _Recurrence.unsupported(
        'Repeats shorter than one day are not supported by Alarm yet.',
      );
    }
    if (unit == 'hours') {
      if (amount % 24 != 0) {
        return const _Recurrence.unsupported(
          'Repeats shorter than one day are not supported by Alarm yet.',
        );
      }
      final dayCount = amount ~/ 24;
      return dayCount == 1
          ? const _Recurrence('daily', [])
          : _Recurrence.interval(dayCount, 'days', days);
    }
    if (unit == 'days' && amount == 1) {
      return const _Recurrence('daily', []);
    }
    if (unit == 'weeks' && amount == 1) {
      return _Recurrence(
        'weekly',
        days.isEmpty ? [_weekdayName(reference.weekday)] : days,
      );
    }
    return _Recurrence.interval(amount, unit, days);
  }

  static _Recurrence? _parseMonthlyWeekday(String text) {
    const ordinal =
        r'(first|second|third|fourth|fifth|last|1st|2nd|3rd|4th|5th)';
    const weekday =
        r'(mon(?:day)?|tue(?:sday)?|wed(?:nesday)?|thu(?:rsday)?|fri(?:day)?|sat(?:urday)?|sun(?:day)?)';
    final match = RegExp(
      '\\b$ordinal\\s+$weekday\\s+(?:of\\s+)?(?:each|every)\\s+month\\b|'
      '\\b(?:each|every)\\s+month\\s+(?:on\\s+)?(?:the\\s+)?$ordinal\\s+$weekday\\b',
    ).firstMatch(text);
    if (match == null) return null;
    final rawOrdinal = match.group(1) ?? match.group(3)!;
    final rawDay = match.group(2) ?? match.group(4)!;
    final day = _canonicalWeekday(rawDay);
    if (day == null) return null;
    final week = rawOrdinal == 'last' ? -1 : _numberValue(rawOrdinal);
    if (week == null) return null;
    return _Recurrence.interval(
      1,
      'months',
      [day],
      weekOfMonth: week,
    );
  }

  static int? _extractMonthDay(String text) {
    if (RegExp(
      r'\b(?:last day\s+(?:of\s+)?(?:each|every)\s+month|(?:each|every)\s+month\s+(?:on\s+)?(?:the\s+)?last day)\b',
    ).hasMatch(text)) {
      return -1;
    }
    final match = RegExp(
      r'\b(?:on\s+)?(?:day\s+|the\s+)?(\d{1,2}(?:st|nd|rd|th)?|first|second|third|fourth|fifth|sixth|seventh|eighth|ninth|tenth|eleventh|twelfth)\s+(?:day\s+)?(?:of\s+)?(?:each|every)\s+month\b|\b(?:each|every)\s+month\s+(?:on\s+)?(?:day\s+|the\s+)?(\d{1,2}(?:st|nd|rd|th)?|first|second|third|fourth|fifth|sixth|seventh|eighth|ninth|tenth|eleventh|twelfth)\b',
    ).firstMatch(text);
    final value = match?.group(1) ?? match?.group(2);
    if (value == null) return null;
    final day = _numberValue(value);
    return day != null && day >= 1 && day <= 31 ? day : null;
  }

  static List<String> _extractDays(String text) {
    final result = _extractDayNames(text);
    final dayToken = _weekdayAliases.values.expand((value) => value).join('|');
    for (final match in RegExp(
      '\\b($dayToken)\\s+(?:to|through|thru|until|till)\\s+($dayToken)\\b',
    ).allMatches(text)) {
      final start = _canonicalWeekday(match.group(1)!);
      final end = _canonicalWeekday(match.group(2)!);
      if (start == null || end == null) continue;
      var index = _weekdayOrder.indexOf(start);
      final endIndex = _weekdayOrder.indexOf(end);
      while (true) {
        if (!result.contains(_weekdayOrder[index])) {
          result.add(_weekdayOrder[index]);
        }
        if (index == endIndex) break;
        index = (index + 1) % _weekdayOrder.length;
      }
    }
    result.sort(
      (a, b) => _weekdayOrder.indexOf(a).compareTo(_weekdayOrder.indexOf(b)),
    );
    return result;
  }

  static bool _hasRecurringDayCue(String text) {
    final dayToken = _weekdayAliases.values.expand((value) => value).join('|');
    return RegExp(
      '\\b(?:every|each|all)\\s+(?:other\\s+)?(?:$dayToken)\\b|'
      '\\b(?:mondays|tuesdays|wednesdays|thursdays|fridays|saturdays|sundays)\\b|'
      '\\b(?:on\\s+)?(?:$dayToken)(?:\\s*(?:,|and|or)\\s*(?:$dayToken))+\\b',
    ).hasMatch(text);
  }

  static List<String> _extractDayNames(String text) {
    final result = <String>[];
    for (final entry in _weekdayAliases.entries) {
      if (entry.value.any(
        (alias) => RegExp('\\b$alias\\b').hasMatch(text),
      )) {
        result.add(entry.key);
      }
    }
    return result;
  }

  static List<String> _extractExcludedDays(String text) {
    final match = RegExp(
      r'\b(?:except(?:\s+for)?|excluding|but not|not on|other than)\s+(.+)$',
    ).firstMatch(text);
    if (match == null) return const [];
    return _extractDayNames(match.group(1)!);
  }

  static String? _canonicalWeekday(String value) {
    for (final entry in _weekdayAliases.entries) {
      if (entry.value.contains(value)) return entry.key;
    }
    return null;
  }

  static String _weekdayName(int weekday) => _weekdayOrder[weekday - 1];

  static const List<String> _weekdayOrder = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];

  static const Map<String, List<String>> _weekdayAliases = {
    'monday': ['monday', 'mondays', 'mon'],
    'tuesday': ['tuesday', 'tuesdays', 'tue', 'tues'],
    'wednesday': ['wednesday', 'wednesdays', 'wed', 'weds'],
    'thursday': ['thursday', 'thursdays', 'thu', 'thur', 'thurs'],
    'friday': ['friday', 'fridays', 'fri'],
    'saturday': ['saturday', 'saturdays', 'sat'],
    'sunday': ['sunday', 'sundays', 'sun'],
  };

  static DateTime? _parseRelativeDateTime(String text, DateTime now) {
    var minutes = 0;
    final compound = RegExp(
      '\\b(?:in|after)\\s+($_durationNumberPattern)\\s+hours?\\s+(?:and\\s+)?($_durationNumberPattern)\\s+minutes?\\b',
    ).firstMatch(text);
    if (compound != null) {
      final hours = _numberValue(compound.group(1)!);
      final extraMinutes = _numberValue(compound.group(2)!);
      if (hours != null && extraMinutes != null) {
        minutes = hours * 60 + extraMinutes;
      }
    } else if (RegExp(
      r'\b(?:in|after)\s+(?:an?|one)\s+and\s+a\s+half\s+hours?\b',
    ).hasMatch(text)) {
      minutes = 90;
    } else if (RegExp(r'\b(?:in|after)\s+(?:half|half an|half a)\s+hour\b')
        .hasMatch(text)) {
      minutes = 30;
    } else if (RegExp(
      r'\b(?:in|after)\s+(?:a quarter|quarter)(?: of an)?\s+hour\b',
    ).hasMatch(text)) {
      minutes = 15;
    } else {
      final match = RegExp(
        '\\b(?:in|after)\\s+($_durationNumberPattern)\\s+(minutes?|hours?)\\b|\\b($_durationNumberPattern)\\s+(minutes?|hours?)\\s+(?:from now|later)\\b',
      ).firstMatch(text);
      if (match == null) return null;
      final amount = _numberValue(match.group(1) ?? match.group(3)!);
      if (amount == null || amount <= 0) return null;
      final unit = match.group(2) ?? match.group(4)!;
      minutes = unit.startsWith('hour') ? amount * 60 : amount;
    }

    if (minutes <= 0) return null;

    final target = now.add(Duration(minutes: minutes));
    final rounded = DateTime(
      target.year,
      target.month,
      target.day,
      target.hour,
      target.minute,
    );
    return target.second == 0 && target.millisecond == 0
        ? rounded
        : rounded.add(const Duration(minutes: 1));
  }

  static DateTime? _parseExplicitDate(String text, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    if (text.contains('day after tomorrow')) {
      return today.add(const Duration(days: 2));
    }
    if (RegExp(r'\btomorrow\b').hasMatch(text)) {
      return today.add(const Duration(days: 1));
    }
    if (RegExp(r'\b(today|tonight|this morning|this afternoon|this evening)\b')
        .hasMatch(text)) {
      return today;
    }
    if (RegExp(r'\b(?:next|coming)\s+weekend\b').hasMatch(text)) {
      var daysUntilSaturday = (DateTime.saturday - today.weekday + 7) % 7;
      if (daysUntilSaturday == 0) daysUntilSaturday = 7;
      return today.add(Duration(days: daysUntilSaturday));
    }
    if (RegExp(r'\bthis\s+weekend\b').hasMatch(text)) {
      final daysUntilSaturday = (DateTime.saturday - today.weekday + 7) % 7;
      return today.add(Duration(days: daysUntilSaturday));
    }

    final relativeDay = RegExp(
      '\\b(?:in|after)\\s+($_durationNumberPattern)\\s+(days?|weeks?)\\b|\\b($_durationNumberPattern)\\s+(days?|weeks?)\\s+(?:from now|from today|later)\\b',
    ).firstMatch(text);
    if (relativeDay != null) {
      final amount = _numberValue(
        relativeDay.group(1) ?? relativeDay.group(3)!,
      );
      if (amount != null && amount > 0) {
        final unit = relativeDay.group(2) ?? relativeDay.group(4)!;
        final days = unit.startsWith('week') ? amount * 7 : amount;
        return today.add(Duration(days: days));
      }
    }
    if (RegExp(r'\bnext week\b').hasMatch(text)) {
      return today.add(const Duration(days: 7));
    }
    if (RegExp(r'\bnext month\b').hasMatch(text)) {
      return _addMonthsClamped(today, 1);
    }
    if (RegExp(r'\bnext year\b').hasMatch(text)) {
      return _addYearsClamped(today, 1);
    }

    final weekdayDate = _parseRelativeWeekday(text, today);
    if (weekdayDate != null) return weekdayDate;

    final plainWeekday = _parsePlainWeekday(text, today);
    if (plainWeekday != null) return plainWeekday;

    final namedDate = _parseNamedDate(text, today);
    if (namedDate != null) return namedDate;

    final ordinal = RegExp(
      r'\b(?:on\s+)?(?:the\s+)?(\d{1,2})(?:st|nd|rd|th)\b',
    ).firstMatch(text);
    if (ordinal != null) {
      final day = int.parse(ordinal.group(1)!);
      for (var offset = 0; offset < 24; offset++) {
        final month = _addMonthsClamped(
          DateTime(today.year, today.month, 1),
          offset,
        );
        final candidate = _validDate(month.year, month.month, day);
        if (candidate != null && !candidate.isBefore(today)) {
          return candidate;
        }
      }
    }

    final numeric = RegExp(
      r'\bon\s+(\d{1,2})[/-](\d{1,2})(?:[/-](\d{2,4}))?\b',
    ).firstMatch(text);
    if (numeric != null) {
      final day = int.parse(numeric.group(1)!);
      final month = int.parse(numeric.group(2)!);
      var year =
          numeric.group(3) == null ? today.year : int.parse(numeric.group(3)!);
      if (year < 100) year += 2000;
      var candidate = _validDate(year, month, day);
      if (candidate != null &&
          numeric.group(3) == null &&
          candidate.isBefore(today)) {
        candidate = _validDate(year + 1, month, day);
      }
      return candidate;
    }
    return null;
  }

  static DateTime? _parseRelativeWeekday(String text, DateTime today) {
    const weekdays = <String, int>{
      'monday': DateTime.monday,
      'tuesday': DateTime.tuesday,
      'wednesday': DateTime.wednesday,
      'thursday': DateTime.thursday,
      'friday': DateTime.friday,
      'saturday': DateTime.saturday,
      'sunday': DateTime.sunday,
    };
    for (final entry in weekdays.entries) {
      final match =
          RegExp('\\b(next|this|coming)\\s+${entry.key}\\b').firstMatch(text);
      if (match == null) continue;
      var difference = (entry.value - today.weekday + 7) % 7;
      if ((match.group(1) == 'next' || match.group(1) == 'coming') &&
          difference == 0) {
        difference = 7;
      }
      return today.add(Duration(days: difference));
    }
    return null;
  }

  static DateTime? _parsePlainWeekday(String text, DateTime today) {
    const weekdays = <String, int>{
      'monday': DateTime.monday,
      'mon': DateTime.monday,
      'tuesday': DateTime.tuesday,
      'tue': DateTime.tuesday,
      'tues': DateTime.tuesday,
      'wednesday': DateTime.wednesday,
      'wed': DateTime.wednesday,
      'thursday': DateTime.thursday,
      'thu': DateTime.thursday,
      'thur': DateTime.thursday,
      'thurs': DateTime.thursday,
      'friday': DateTime.friday,
      'fri': DateTime.friday,
      'saturday': DateTime.saturday,
      'sat': DateTime.saturday,
      'sunday': DateTime.sunday,
      'sun': DateTime.sunday,
    };
    for (final entry in weekdays.entries) {
      if (!RegExp(
        '(?:^|\\b(?:on|for)\\s+)${entry.key}\\b|\\b${entry.key}\\s+(?:at|around|by)\\b',
      ).hasMatch(text)) {
        continue;
      }
      final difference = (entry.value - today.weekday + 7) % 7;
      return today.add(Duration(days: difference));
    }
    return null;
  }

  static bool _hasPlainOneTimeWeekday(String text) {
    const token =
        r'(?:monday|mon|tuesday|tue|tues|wednesday|wed|thursday|thu|thur|thurs|friday|fri|saturday|sat|sunday|sun)';
    return RegExp(
      '(?:^|\\b(?:on|for)\\s+)$token\\b|\\b$token\\s+(?:at|around|by)\\b',
    ).hasMatch(text);
  }

  static DateTime? _parseNamedDate(String text, DateTime today) {
    const months = <String, int>{
      'january': 1,
      'jan': 1,
      'february': 2,
      'feb': 2,
      'march': 3,
      'mar': 3,
      'april': 4,
      'apr': 4,
      'may': 5,
      'june': 6,
      'jun': 6,
      'july': 7,
      'jul': 7,
      'august': 8,
      'aug': 8,
      'september': 9,
      'sep': 9,
      'sept': 9,
      'october': 10,
      'oct': 10,
      'november': 11,
      'nov': 11,
      'december': 12,
      'dec': 12,
    };
    final monthPattern = months.keys.join('|');
    final dayFirst = RegExp(
      '\\b(?:on\\s+)?(\\d{1,2})(?:st|nd|rd|th)?(?:\\s+of)?\\s+($monthPattern)(?:\\s+(\\d{4}))?\\b',
    ).firstMatch(text);
    final monthFirst = RegExp(
      '\\b(?:on\\s+)?($monthPattern)\\s+(\\d{1,2})(?:st|nd|rd|th)?(?:\\s+(\\d{4}))?\\b',
    ).firstMatch(text);

    int? day;
    int? month;
    int? year;
    if (dayFirst != null) {
      day = int.parse(dayFirst.group(1)!);
      month = months[dayFirst.group(2)!];
      year = dayFirst.group(3) == null
          ? today.year
          : int.parse(dayFirst.group(3)!);
    } else if (monthFirst != null) {
      month = months[monthFirst.group(1)!];
      day = int.parse(monthFirst.group(2)!);
      year = monthFirst.group(3) == null
          ? today.year
          : int.parse(monthFirst.group(3)!);
    }
    if (day == null || month == null || year == null) return null;

    final hasExplicitYear =
        dayFirst?.group(3) != null || monthFirst?.group(3) != null;
    if (hasExplicitYear) return _validDate(year, month, day);
    for (var yearOffset = 0; yearOffset < 12; yearOffset++) {
      final candidate = _validDate(year + yearOffset, month, day);
      if (candidate != null && !candidate.isBefore(today)) return candidate;
    }
    return null;
  }

  static DateTime? _validDate(int year, int month, int day) {
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    final value = DateTime(year, month, day);
    return value.year == year && value.month == month && value.day == day
        ? value
        : null;
  }

  static DateTime _intervalStartDate(String text, DateTime now) {
    return DateTime(now.year, now.month, now.day);
  }

  static DateTime _resolveIntervalStart(
    String text,
    DateTime now,
    DateTime? proposedDate,
    _ClockTime time,
    _Recurrence recurrence,
  ) {
    var start = proposedDate ?? DateTime(now.year, now.month, now.day);
    if (recurrence.intervalUnit == 'months') {
      final ordinal = RegExp(
        r'\b(?:on\s+)?(?:the\s+)?(\d{1,2})(?:st|nd|rd|th)\b',
      ).firstMatch(text);
      if (ordinal != null) {
        final day = int.parse(ordinal.group(1)!);
        for (var offset = 0; offset < 24; offset++) {
          final month = _addMonthsClamped(
            DateTime(start.year, start.month, 1),
            offset,
          );
          final candidate = _validDate(month.year, month.month, day);
          if (candidate != null) {
            start = candidate;
            break;
          }
        }
      }
      if (recurrence.monthDay != null || recurrence.weekOfMonth != null) {
        return _resolveMonthlyRuleStart(start, now, time, recurrence);
      }
    }

    if (recurrence.intervalUnit == 'weeks' && recurrence.days.isNotEmpty) {
      for (var offset = 0; offset < 14; offset++) {
        final candidate = start.add(Duration(days: offset));
        final name = _weekdayName(candidate.weekday);
        final scheduled = DateTime(
          candidate.year,
          candidate.month,
          candidate.day,
          time.hour,
          time.minute,
        );
        if (recurrence.days.contains(name) && scheduled.isAfter(now)) {
          return candidate;
        }
      }
    }

    if (recurrence.intervalUnit == 'weekdays' &&
        start.weekday > DateTime.friday) {
      start = start.add(Duration(days: 8 - start.weekday));
    }

    var scheduled = DateTime(
      start.year,
      start.month,
      start.day,
      time.hour,
      time.minute,
    );
    if (scheduled.isAfter(now)) return start;

    final amount = recurrence.intervalValue ?? 1;
    switch (recurrence.intervalUnit) {
      case 'days':
        start = start.add(Duration(days: amount));
        break;
      case 'weeks':
        start = start.add(Duration(days: amount * 7));
        break;
      case 'weekdays':
        start = _addWeekdays(start, amount);
        break;
      case 'months':
        start = _addMonthsClamped(start, amount);
        break;
      case 'years':
        start = _addYearsClamped(start, amount);
        break;
    }
    return start;
  }

  static DateTime _resolveMonthlyRuleStart(
    DateTime start,
    DateTime now,
    _ClockTime time,
    _Recurrence recurrence,
  ) {
    final weekdays = recurrence.days
        .map((day) => _weekdayOrder.indexOf(day) + 1)
        .where((weekday) => weekday >= DateTime.monday)
        .toList();
    for (var offset = 0; offset < 240; offset++) {
      final month = _addMonthsClamped(
        DateTime(start.year, start.month, 1),
        offset,
      );
      final candidates = <DateTime>[];
      if (recurrence.weekOfMonth != null) {
        for (final weekday in weekdays) {
          final candidate = _weekdayOfMonth(
            month.year,
            month.month,
            weekday,
            recurrence.weekOfMonth!,
          );
          if (candidate != null) candidates.add(candidate);
        }
      } else {
        final lastDay = _daysInMonth(month.year, month.month);
        final requested = recurrence.monthDay == -1
            ? lastDay
            : recurrence.monthDay ?? start.day;
        candidates.add(
          DateTime(
            month.year,
            month.month,
            requested.clamp(1, lastDay) as int,
          ),
        );
      }
      candidates.sort();
      for (final candidate in candidates) {
        final scheduled = DateTime(
          candidate.year,
          candidate.month,
          candidate.day,
          time.hour,
          time.minute,
        );
        if (scheduled.isAfter(now)) return candidate;
      }
    }
    return start;
  }

  static DateTime? _weekdayOfMonth(
    int year,
    int month,
    int weekday,
    int occurrence,
  ) {
    if (occurrence == -1) {
      final last = DateTime(year, month + 1, 0);
      final offset = (last.weekday - weekday + 7) % 7;
      return last.subtract(Duration(days: offset));
    }
    final first = DateTime(year, month, 1);
    final offset = (weekday - first.weekday + 7) % 7;
    final result = DateTime(
      year,
      month,
      1 + offset + (occurrence - 1) * 7,
    );
    return result.month == month ? result : null;
  }

  static DateTime _addMonthsClamped(DateTime date, int months) {
    final monthIndex = date.month - 1 + months;
    final year = date.year + monthIndex ~/ 12;
    final month = monthIndex % 12 + 1;
    final day = date.day.clamp(1, _daysInMonth(year, month)) as int;
    return DateTime(year, month, day);
  }

  static DateTime _addYearsClamped(DateTime date, int years) {
    final year = date.year + years;
    final day = date.day.clamp(1, _daysInMonth(year, date.month)) as int;
    return DateTime(year, date.month, day);
  }

  static DateTime _addWeekdays(DateTime date, int amount) {
    var result = date;
    var remaining = amount;
    while (remaining > 0) {
      result = result.add(const Duration(days: 1));
      if (result.weekday <= DateTime.friday) remaining--;
    }
    return result;
  }

  static int _daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  static _ClockTime? _parseClockTime(
    String text,
    DateTime now,
    DateTime? date,
    bool repeating,
  ) {
    if (RegExp(r'\bnoon\b').hasMatch(text)) {
      return const _ClockTime(12, 0);
    }
    if (RegExp(r'\bmidnight\b').hasMatch(text)) {
      return const _ClockTime(0, 0);
    }

    final halfHour = RegExp(
      '\\bhalf\\s+($_numberWordPattern|\\d{1,2})(?:\\s*(am|pm))?\\b',
    ).firstMatch(text);
    if (halfHour != null) {
      final hour = _numberValue(halfHour.group(1)!);
      if (hour != null) {
        return _buildClockTime(
          hour,
          30,
          halfHour.group(2) ?? _periodFromText(text),
          now,
          date,
          repeating,
        );
      }
    }

    final relativeClock = RegExp(
      '\\b(?:a\\s+)?(quarter|half)\\s+(past|after|to|before|of)\\s+($_numberWordPattern|\\d{1,2})(?:\\s*(am|pm))?\\b',
    ).firstMatch(text);
    if (relativeClock != null) {
      final amount = relativeClock.group(1)!;
      final direction = relativeClock.group(2)!;
      final spokenHour = _numberValue(relativeClock.group(3)!);
      if (spokenHour == null || spokenHour < 1 || spokenHour > 12) {
        return null;
      }
      final period = relativeClock.group(4) ?? _periodFromText(text);
      final resolvedHour = _resolveHour(
        spokenHour,
        0,
        period,
        now,
        date,
        repeating,
      );
      if (direction == 'to' || direction == 'before' || direction == 'of') {
        final totalMinutes = (resolvedHour * 60 - 15) % (24 * 60);
        return _ClockTime(totalMinutes ~/ 60, totalMinutes % 60);
      }
      return _ClockTime(resolvedHour, amount == 'half' ? 30 : 15);
    }

    final minutesRelative = RegExp(
      '\\b($_minuteWordPattern|\\d{1,2})(?:\\s+minutes?)?\\s+(past|after|to|before)\\s+($_numberWordPattern|\\d{1,2})(?:\\s*(am|pm))?\\b',
    ).firstMatch(text);
    if (minutesRelative != null) {
      final minuteAmount = _numberValue(minutesRelative.group(1)!);
      final spokenHour = _numberValue(minutesRelative.group(3)!);
      if (minuteAmount != null &&
          minuteAmount > 0 &&
          minuteAmount < 60 &&
          spokenHour != null &&
          spokenHour >= 1 &&
          spokenHour <= 12) {
        final resolvedHour = _resolveHour(
          spokenHour,
          0,
          minutesRelative.group(4) ?? _periodFromText(text),
          now,
          date,
          repeating,
        );
        if (minutesRelative.group(2) == 'to' ||
            minutesRelative.group(2) == 'before') {
          final total = (resolvedHour * 60 - minuteAmount) % (24 * 60);
          return _ClockTime(total ~/ 60, total % 60);
        }
        final total = resolvedHour * 60 + minuteAmount;
        return _ClockTime((total ~/ 60) % 24, total % 60);
      }
    }

    final colonTime = RegExp(
      r'\b(\d{1,2}):(\d{1,2})\s*(am|pm)?\b',
    ).firstMatch(text);
    if (colonTime != null) {
      return _buildClockTime(
        int.parse(colonTime.group(1)!),
        int.parse(colonTime.group(2)!),
        colonTime.group(3) ?? _periodFromText(text),
        now,
        date,
        repeating,
      );
    }

    final military = RegExp(r'\b(\d{3,4})\s*hours?\b').firstMatch(text);
    if (military != null) {
      final value = int.parse(military.group(1)!);
      return _buildClockTime(
        value ~/ 100,
        value % 100,
        null,
        now,
        date,
        repeating,
      );
    }

    final compactTime = RegExp(
      r'\b(?:at|for|around|by)\s+([01]\d{3}|2[0-3]\d{2})\b',
    ).firstMatch(text);
    if (compactTime != null) {
      final value = int.parse(compactTime.group(1)!);
      return _buildClockTime(
        value ~/ 100,
        value % 100,
        null,
        now,
        date,
        repeating,
      );
    }

    final numericWithPeriod = RegExp(
      r'\b(\d{1,2})\s*(am|pm)\b',
    ).firstMatch(text);
    if (numericWithPeriod != null) {
      return _buildClockTime(
        int.parse(numericWithPeriod.group(1)!),
        0,
        numericWithPeriod.group(2),
        now,
        date,
        repeating,
      );
    }

    final spokenWithPeriod = RegExp(
      "\\b($_numberWordPattern)(?:\\s+($_minuteWordPattern))?\\s+(am|pm)\\b",
    ).firstMatch(text);
    if (spokenWithPeriod != null) {
      final hour = _numberValue(spokenWithPeriod.group(1)!);
      final minute = spokenWithPeriod.group(2) == null
          ? 0
          : _numberValue(spokenWithPeriod.group(2)!);
      if (hour != null && minute != null) {
        return _buildClockTime(
          hour,
          minute,
          spokenWithPeriod.group(3),
          now,
          date,
          repeating,
        );
      }
    }

    final numericAfterCue = RegExp(
      r"\b(?:at|for|around|by)\s+(\d{1,2})(?:\s+(\d{1,2}))?\s*(am|pm|hours?|o'?clock)?\b",
    ).firstMatch(text);
    if (numericAfterCue != null) {
      return _buildClockTime(
        int.parse(numericAfterCue.group(1)!),
        numericAfterCue.group(2) == null
            ? 0
            : int.parse(numericAfterCue.group(2)!),
        _normalizePeriod(numericAfterCue.group(3)) ?? _periodFromText(text),
        now,
        date,
        repeating,
      );
    }

    final spokenTime = RegExp(
      "\\b(?:at|for|around|by)\\s+($_numberWordPattern)(?:\\s+($_minuteWordPattern))?\\s*(am|pm|o'?clock)?\\b",
    ).firstMatch(text);
    if (spokenTime != null) {
      final hour = _numberValue(spokenTime.group(1)!);
      final minute =
          spokenTime.group(2) == null ? 0 : _numberValue(spokenTime.group(2)!);
      if (hour == null || minute == null) return null;
      return _buildClockTime(
        hour,
        minute,
        _normalizePeriod(spokenTime.group(3)) ?? _periodFromText(text),
        now,
        date,
        repeating,
      );
    }
    return null;
  }

  static _ClockTime? _buildClockTime(
    int hour,
    int minute,
    String? period,
    DateTime now,
    DateTime? date,
    bool repeating,
  ) {
    if (minute < 0 || minute > 59) return null;
    if (period != null && period != 'hours' && period != 'hour') {
      if (hour < 1 || hour > 12) return null;
    } else if (hour < 0 || hour > 23) {
      return null;
    }
    return _ClockTime(
      _resolveHour(hour, minute, period, now, date, repeating),
      minute,
    );
  }

  static int _resolveHour(
    int hour,
    int minute,
    String? period,
    DateTime now,
    DateTime? date,
    bool repeating,
  ) {
    if (period == 'am') return hour == 12 ? 0 : hour;
    if (period == 'pm') return hour == 12 ? 12 : hour + 12;
    if (period == 'night') return hour == 12 ? 0 : hour + 12;
    if (hour == 0 || hour > 12 || repeating || date != null) return hour;

    final morning = DateTime(now.year, now.month, now.day, hour, minute);
    if (morning.isAfter(now)) return hour;
    final evening = DateTime(now.year, now.month, now.day, hour + 12, minute);
    return evening.isAfter(now) ? hour + 12 : hour;
  }

  static String? _normalizePeriod(String? value) {
    if (value == null) return null;
    if (value == 'am' || value == 'pm') return value;
    if (value.startsWith('hour')) return 'hours';
    return null;
  }

  static String? _periodFromText(String text) {
    if (RegExp(r'\b(morning|before noon|before midday)\b').hasMatch(text)) {
      return 'am';
    }
    if (RegExp(r'\b(afternoon|evening|tonight)\b').hasMatch(text)) {
      return 'pm';
    }
    if (RegExp(r'\b(?:at|in the) night\b').hasMatch(text)) return 'night';
    return null;
  }

  static int? _numberValue(String phrase) {
    final cleaned = phrase
        .trim()
        .replaceAllMapped(
          RegExp(r'\b(\d+)(?:st|nd|rd|th)\b'),
          (match) => match.group(1)!,
        )
        .replaceAll('-', ' ')
        .replaceAll(RegExp(r'\b(and|of)\b'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final numeric = int.tryParse(cleaned);
    if (numeric != null) return numeric;
    if (cleaned == 'a' || cleaned == 'an') return 1;
    if (cleaned == 'couple' || cleaned == 'a couple') return 2;

    const values = <String, int>{
      'zero': 0,
      'oh': 0,
      'one': 1,
      'two': 2,
      'three': 3,
      'four': 4,
      'five': 5,
      'six': 6,
      'seven': 7,
      'eight': 8,
      'nine': 9,
      'ten': 10,
      'eleven': 11,
      'twelve': 12,
      'thirteen': 13,
      'fourteen': 14,
      'fifteen': 15,
      'sixteen': 16,
      'seventeen': 17,
      'eighteen': 18,
      'nineteen': 19,
      'first': 1,
      'second': 2,
      'third': 3,
      'fourth': 4,
      'fifth': 5,
      'sixth': 6,
      'seventh': 7,
      'eighth': 8,
      'ninth': 9,
      'tenth': 10,
      'eleventh': 11,
      'twelfth': 12,
      'twenty': 20,
      'thirty': 30,
      'forty': 40,
      'fifty': 50,
      'sixty': 60,
      'seventy': 70,
      'eighty': 80,
      'ninety': 90,
    };
    var total = 0;
    for (final word in cleaned.split(' ')) {
      if (word == 'hundred') {
        total = (total == 0 ? 1 : total) * 100;
        continue;
      }
      final value = values[word];
      if (value == null) return null;
      total += value;
    }
    return total;
  }

  static String _extractLabel(String text) {
    final explicit = RegExp(
      r'\b(?:called|named|labelled|labeled)\s+(.+)$',
    ).firstMatch(text);
    if (explicit != null) return _cleanLabel(explicit.group(1)!);

    final toMatches = RegExp(r'\bto\s+(.+)$').allMatches(text).toList();
    for (final match in toMatches.reversed) {
      final prefix = text.substring(0, match.start).trimRight();
      if (prefix.endsWith('quarter')) continue;
      return _cleanLabel(match.group(1)!);
    }

    for (final match in RegExp(r'\bfor\s+(.+)$').allMatches(text)) {
      final candidate = match.group(1)!.trim();
      if (!_startsWithTimingPhrase(candidate)) {
        return _cleanLabel(candidate);
      }
    }

    if (RegExp(r'\bwake(?: me)?(?: up)?\b').hasMatch(text)) {
      return 'Wake Up';
    }
    return 'Voice Alarm';
  }

  static bool _startsWithTimingPhrase(String value) {
    return RegExp(
      '^${_numberWordPattern}|^\\d|^(?:at|after|in|today|tomorrow|next|this|coming|every|each|all|weekdays?|weekends?|workdays?|daily|weekly|monthly|yearly|annually|fortnightly|noon|midnight|monday|mon|tuesday|tue|wednesday|wed|thursday|thu|friday|fri|saturday|sat|sunday|sun|january|jan|february|feb|march|mar|april|apr|may|june|jun|july|jul|august|aug|september|sep|october|oct|november|nov|december|dec)\\b',
    ).hasMatch(value);
  }

  static String _cleanLabel(String value) {
    var label = value
        .replaceFirst(
          RegExp(
            r'\s+\b(?:at|on|every|each|daily|weekly|monthly|yearly|annually|fortnightly|weekdays?|weekends?|workdays?|tomorrow|today|next|this|coming|starting|beginning)\b.*$',
          ),
          '',
        )
        .replaceFirst(RegExp(r'^(?:please\s+)?(?:remind\s+me\s+)?'), '')
        .trim();
    if (label.isEmpty) return 'Voice Alarm';
    label = label
        .split(RegExp(r'\s+'))
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
    return label;
  }
}

class _Recurrence {
  const _Recurrence(this.value, this.days)
      : intervalValue = null,
        intervalUnit = null,
        monthDay = null,
        weekOfMonth = null,
        error = null;

  const _Recurrence.interval(
    this.intervalValue,
    this.intervalUnit,
    this.days, {
    this.monthDay,
    this.weekOfMonth,
  })  : value = 'interval',
        error = null;

  const _Recurrence.unsupported(this.error)
      : value = 'once',
        days = const [],
        intervalValue = null,
        intervalUnit = null,
        monthDay = null,
        weekOfMonth = null;

  final String value;
  final List<String> days;
  final int? intervalValue;
  final String? intervalUnit;
  final int? monthDay;
  final int? weekOfMonth;
  final String? error;
}

class _ClockTime {
  const _ClockTime(this.hour, this.minute);

  final int hour;
  final int minute;
}
