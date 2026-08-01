import 'package:clock_app/voice/parsed_alarm.dart';

/// Expands an interval command into dates understood by the alarm date schedule.
///
/// The alarm engine schedules the first future date and advances through this
/// list after each alarm fires. Keeping this logic pure also makes every
/// supported interval deterministic and independently testable.
List<DateTime> materializeIntervalDates(
  ParsedAlarm alarm, {
  DateTime? now,
}) {
  final amount = alarm.intervalValue;
  final unit = alarm.intervalUnit;
  if (!alarm.isComplete ||
      amount == null ||
      amount < 1 ||
      unit == null) {
    return const [];
  }

  final reference = now ?? DateTime.now();
  var start = alarm.date ??
      DateTime(reference.year, reference.month, reference.day);
  final dates = <DateTime>[];

  bool isFuture(DateTime date) => DateTime(
        date.year,
        date.month,
        date.day,
        alarm.hour!,
        alarm.minute!,
      ).isAfter(reference);

  if (unit == 'weekdays') {
    if (start.weekday > DateTime.friday) {
      start = start.add(Duration(days: 8 - start.weekday));
    }
    var candidate = start;
    for (var index = 0; index < 2000; index++) {
      if (isFuture(candidate)) dates.add(candidate);
      candidate = _addWeekdays(candidate, amount);
    }
    return dates;
  }

  if (unit == 'weeks' && alarm.days.isNotEmpty) {
    final selectedDays = alarm.days
        .map((day) => _weekdayNumbers[day])
        .whereType<int>()
        .toList()
      ..sort();
    final anchorWeek = start.subtract(Duration(days: start.weekday - 1));
    for (var cycle = 0; cycle < 520 && dates.length < 2000; cycle++) {
      final week = anchorWeek.add(Duration(days: cycle * amount * 7));
      for (final weekday in selectedDays) {
        final candidate = week.add(Duration(days: weekday - 1));
        if (!candidate.isBefore(start) && isFuture(candidate)) {
          dates.add(candidate);
        }
      }
    }
    return dates;
  }

  if (unit == 'months' &&
      alarm.weekOfMonth != null &&
      alarm.days.isNotEmpty) {
    final selectedDays = alarm.days
        .map((day) => _weekdayNumbers[day])
        .whereType<int>()
        .toList()
      ..sort();
    for (var cycle = 0; cycle < 240 && dates.length < 2000; cycle++) {
      final month = _addMonthsClamped(
        DateTime(start.year, start.month, 1),
        cycle * amount,
      );
      for (final weekday in selectedDays) {
        final candidate = _weekdayOfMonth(
          month.year,
          month.month,
          weekday,
          alarm.weekOfMonth!,
        );
        if (candidate != null &&
            !candidate.isBefore(start) &&
            isFuture(candidate)) {
          dates.add(candidate);
        }
      }
    }
    dates.sort();
    return dates;
  }

  if (unit == 'months' && alarm.monthDay != null) {
    for (var cycle = 0; cycle < 240 && dates.length < 2000; cycle++) {
      final month = _addMonthsClamped(
        DateTime(start.year, start.month, 1),
        cycle * amount,
      );
      final lastDay = DateTime(month.year, month.month + 1, 0).day;
      final requestedDay = alarm.monthDay == -1 ? lastDay : alarm.monthDay!;
      final candidate = DateTime(
        month.year,
        month.month,
        requestedDay.clamp(1, lastDay) as int,
      );
      if (!candidate.isBefore(start) && isFuture(candidate)) {
        dates.add(candidate);
      }
    }
    return dates;
  }

  final occurrenceCount = switch (unit) {
    'days' => (3650 ~/ amount) + 1,
    'weeks' => (520 ~/ amount) + 1,
    'months' => (240 ~/ amount) + 1,
    'years' => (50 ~/ amount) + 1,
    _ => 0,
  };
  for (var index = 0; index < occurrenceCount && dates.length < 2000; index++) {
    final DateTime candidate;
    switch (unit) {
      case 'days':
        candidate = start.add(Duration(days: index * amount));
        break;
      case 'weeks':
        candidate = start.add(Duration(days: index * amount * 7));
        break;
      case 'months':
        candidate = _addMonthsClamped(start, index * amount);
        break;
      case 'years':
        candidate = _addYearsClamped(start, index * amount);
        break;
      default:
        continue;
    }
    if (isFuture(candidate)) dates.add(candidate);
  }
  return dates;
}

DateTime? _weekdayOfMonth(
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
  final result = DateTime(year, month, 1 + offset + (occurrence - 1) * 7);
  return result.month == month ? result : null;
}

DateTime _addWeekdays(DateTime date, int amount) {
  var result = date;
  var remaining = amount;
  while (remaining > 0) {
    result = result.add(const Duration(days: 1));
    if (result.weekday <= DateTime.friday) remaining--;
  }
  return result;
}

DateTime _addMonthsClamped(DateTime date, int months) {
  final monthIndex = date.month - 1 + months;
  final year = date.year + monthIndex ~/ 12;
  final month = monthIndex % 12 + 1;
  final day = date.day.clamp(1, DateTime(year, month + 1, 0).day) as int;
  return DateTime(year, month, day);
}

DateTime _addYearsClamped(DateTime date, int years) {
  final year = date.year + years;
  final day = date.day.clamp(1, DateTime(year, date.month + 1, 0).day) as int;
  return DateTime(year, date.month, day);
}

const Map<String, int> _weekdayNumbers = {
  'monday': DateTime.monday,
  'tuesday': DateTime.tuesday,
  'wednesday': DateTime.wednesday,
  'thursday': DateTime.thursday,
  'friday': DateTime.friday,
  'saturday': DateTime.saturday,
  'sunday': DateTime.sunday,
};
