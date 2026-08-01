import 'package:clock_app/voice/parsed_alarm.dart';

/// Deterministic, offline parser for common spoken alarm commands.
///
/// Speech transcription is handled by the device's speech recognizer. This
/// class performs no network requests and uses no machine-learning service.
class LocalAlarmParser {
  static const String _numberWordPattern =
      r'(?:zero|one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve|thirteen|fourteen|fifteen|sixteen|seventeen|eighteen|nineteen|twenty(?:\s+(?:one|two|three|four|five|six|seven|eight|nine))?|thirty(?:\s+(?:one|two|three|four|five|six|seven|eight|nine))?|forty(?:\s+(?:one|two|three|four|five|six|seven|eight|nine))?|fifty(?:\s+(?:one|two|three|four|five|six|seven|eight|nine))?)';

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
    final recurrence = _parseRecurrence(text);
    final relativeDateTime = _parseRelativeDateTime(text, reference);
    final explicitDate = relativeDateTime == null
        ? _parseExplicitDate(text, reference)
        : null;
    final time = relativeDateTime == null
        ? _parseClockTime(
            text,
            reference,
            explicitDate,
            recurrence.value != 'once',
          )
        : _ClockTime(relativeDateTime.hour, relativeDateTime.minute);
    final date = recurrence.value == 'once'
        ? relativeDateTime ?? explicitDate
        : null;

    if (time != null && date != null) {
      final scheduled = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
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
      date: date == null
          ? null
          : DateTime(date.year, date.month, date.day),
    );
  }

  static String _normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'a\s*\.\s*m\s*\.?'), 'am')
        .replaceAll(RegExp(r'p\s*\.\s*m\s*\.?'), 'pm')
        .replaceAllMapped(
          RegExp(r'(\d)\.(\d)'),
          (match) => '${match.group(1)}:${match.group(2)}',
        )
        .replaceAll('-', ' ')
        .replaceAll(RegExp(r"[^a-z0-9:/\s']"), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static _Recurrence _parseRecurrence(String text) {
    final days = _extractDays(text);

    if (RegExp(
      r'\b(daily|every day|each day|every morning|every evening|every night|all days)\b',
    ).hasMatch(text)) {
      return const _Recurrence('daily', []);
    }
    if (RegExp(
      r'\b(weekdays?|workdays?|monday\s+(?:to|through)\s+friday)\b',
    ).hasMatch(text)) {
      return const _Recurrence('weekdays', []);
    }
    if (RegExp(
      r'\b(weekends?|saturday\s+(?:and|to|through)\s+sunday)\b',
    ).hasMatch(text)) {
      return const _Recurrence('weekends', []);
    }

    final hasOneTimeDay = RegExp(
      r'\b(?:next|this)\s+(?:mon(?:day)?|tue(?:sday)?|wed(?:nesday)?|thu(?:rsday)?|fri(?:day)?|sat(?:urday)?|sun(?:day)?)\b',
    ).hasMatch(text);
    if (days.isNotEmpty && !hasOneTimeDay) {
      return _Recurrence('weekly', days);
    }
    return const _Recurrence('once', []);
  }

  static List<String> _extractDays(String text) {
    const aliases = <String, List<String>>{
      'monday': ['monday', 'mondays', 'mon'],
      'tuesday': ['tuesday', 'tuesdays', 'tue', 'tues'],
      'wednesday': ['wednesday', 'wednesdays', 'wed'],
      'thursday': ['thursday', 'thursdays', 'thu', 'thur', 'thurs'],
      'friday': ['friday', 'fridays', 'fri'],
      'saturday': ['saturday', 'saturdays', 'sat'],
      'sunday': ['sunday', 'sundays', 'sun'],
    };
    final result = <String>[];
    for (final entry in aliases.entries) {
      if (entry.value.any(
        (alias) => RegExp('\\b$alias\\b').hasMatch(text),
      )) {
        result.add(entry.key);
      }
    }
    return result;
  }

  static DateTime? _parseRelativeDateTime(String text, DateTime now) {
    var minutes = 0;
    if (RegExp(r'\bin\s+(?:half|half an|half a)\s+hour\b')
        .hasMatch(text)) {
      minutes = 30;
    } else if (RegExp(r'\bin\s+(?:a quarter|quarter)(?: of an)?\s+hour\b')
        .hasMatch(text)) {
      minutes = 15;
    } else {
      final match = RegExp(
        r'\bin\s+([a-z0-9\s]+?)\s+(minutes?|hours?)\b',
      ).firstMatch(text);
      if (match == null) return null;
      final amount = _numberValue(match.group(1)!);
      if (amount == null || amount <= 0) return null;
      minutes = match.group(2)!.startsWith('hour') ? amount * 60 : amount;
    }

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

    final weekdayDate = _parseRelativeWeekday(text, today);
    if (weekdayDate != null) return weekdayDate;

    final namedDate = _parseNamedDate(text, today);
    if (namedDate != null) return namedDate;

    final numeric = RegExp(
      r'\bon\s+(\d{1,2})[/-](\d{1,2})(?:[/-](\d{2,4}))?\b',
    ).firstMatch(text);
    if (numeric != null) {
      final day = int.parse(numeric.group(1)!);
      final month = int.parse(numeric.group(2)!);
      var year = numeric.group(3) == null
          ? today.year
          : int.parse(numeric.group(3)!);
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
      final match = RegExp('\\b(next|this)\\s+${entry.key}\\b')
          .firstMatch(text);
      if (match == null) continue;
      var difference = (entry.value - today.weekday + 7) % 7;
      if (match.group(1) == 'next' && difference == 0) difference = 7;
      return today.add(Duration(days: difference));
    }
    return null;
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

    var candidate = _validDate(year, month, day);
    if (candidate != null &&
        !text.contains(year.toString()) &&
        candidate.isBefore(today)) {
      candidate = _validDate(year + 1, month, day);
    }
    return candidate;
  }

  static DateTime? _validDate(int year, int month, int day) {
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    final value = DateTime(year, month, day);
    return value.year == year && value.month == month && value.day == day
        ? value
        : null;
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

    final relativeClock = RegExp(
      '\\b(quarter|half)\\s+(past|after|to)\\s+($_numberWordPattern|\\d{1,2})(?:\\s*(am|pm))?\\b',
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
      if (direction == 'to') {
        final totalMinutes = (resolvedHour * 60 - 15) % (24 * 60);
        return _ClockTime(totalMinutes ~/ 60, totalMinutes % 60);
      }
      return _ClockTime(resolvedHour, amount == 'half' ? 30 : 15);
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
      "\\b(?:at|for|around|by)\\s+($_numberWordPattern)(?:\\s+($_numberWordPattern))?\\s*(am|pm|o'?clock)?\\b",
    ).firstMatch(text);
    if (spokenTime != null) {
      final hour = _numberValue(spokenTime.group(1)!);
      final minute = spokenTime.group(2) == null
          ? 0
          : _numberValue(spokenTime.group(2)!);
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
    if (RegExp(r'\b(morning|before noon)\b').hasMatch(text)) return 'am';
    if (RegExp(r'\b(afternoon|evening|tonight)\b').hasMatch(text)) {
      return 'pm';
    }
    if (RegExp(r'\bat night\b').hasMatch(text)) return 'night';
    return null;
  }

  static int? _numberValue(String phrase) {
    final cleaned = phrase
        .trim()
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
      '^${_numberWordPattern}|^\\d|^(?:today|tomorrow|next|this|every|each|weekdays?|weekends?|daily|noon|midnight)\\b',
    ).hasMatch(value);
  }

  static String _cleanLabel(String value) {
    var label = value
        .replaceFirst(
          RegExp(
            r'\s+\b(?:at|on|every|each|daily|tomorrow|today|next|this)\b.*$',
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
  const _Recurrence(this.value, this.days);

  final String value;
  final List<String> days;
}

class _ClockTime {
  const _ClockTime(this.hour, this.minute);

  final int hour;
  final int minute;
}
