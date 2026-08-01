class ParsedAlarm {
  const ParsedAlarm({
    required this.hour,
    required this.minute,
    required this.recurrence,
    required this.days,
    required this.label,
    this.date,
    this.intervalValue,
    this.intervalUnit,
    this.monthDay,
    this.weekOfMonth,
  });

  final int? hour;
  final int? minute;
  final String recurrence;
  final List<String> days;
  final String label;
  final DateTime? date;
  final int? intervalValue;
  final String? intervalUnit;
  final int? monthDay;
  final int? weekOfMonth;

  bool get isComplete => hour != null && minute != null;

  factory ParsedAlarm.fromJson(Map<String, dynamic> json) {
    final int? parsedHour = _parseBoundedInt(json['hour'], 0, 23);
    final int? parsedMinute = _parseBoundedInt(json['minute'], 0, 59);
    const validRecurrences = {
      'once',
      'daily',
      'weekdays',
      'weekends',
      'weekly',
      'interval',
    };
    final recurrence =
        json['recurrence']?.toString().trim().toLowerCase() ?? 'once';
    final rawDays = json['days'];
    final label = json['label']?.toString().trim() ?? '';

    return ParsedAlarm(
      hour: parsedHour,
      minute: parsedMinute,
      recurrence: validRecurrences.contains(recurrence) ? recurrence : 'once',
      days: rawDays is List
          ? rawDays
              .map((day) => day.toString().trim().toLowerCase())
              .where((day) => day.isNotEmpty)
              .toList(growable: false)
          : const [],
      label: _toTitleCase(label),
      date: json['date'] == null
          ? null
          : DateTime.tryParse(json['date'].toString()),
      intervalValue: _parseBoundedInt(json['intervalValue'], 1, 365),
      intervalUnit: _parseIntervalUnit(json['intervalUnit']),
      monthDay: _parseSpecialBoundedInt(json['monthDay'], -1, 31),
      weekOfMonth: _parseSpecialBoundedInt(json['weekOfMonth'], -1, 5),
    );
  }

  ParsedAlarm copyWith({
    int? hour,
    int? minute,
    String? recurrence,
    List<String>? days,
    String? label,
    DateTime? date,
    int? intervalValue,
    String? intervalUnit,
    int? monthDay,
    int? weekOfMonth,
  }) {
    return ParsedAlarm(
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      recurrence: recurrence ?? this.recurrence,
      days: days ?? this.days,
      label: label ?? this.label,
      date: date ?? this.date,
      intervalValue: intervalValue ?? this.intervalValue,
      intervalUnit: intervalUnit ?? this.intervalUnit,
      monthDay: monthDay ?? this.monthDay,
      weekOfMonth: weekOfMonth ?? this.weekOfMonth,
    );
  }

  static int? _parseBoundedInt(dynamic value, int minimum, int maximum) {
    if (value == null) return null;
    final parsed = value is int ? value : int.tryParse(value.toString());
    if (parsed == null || parsed < minimum || parsed > maximum) return null;
    return parsed;
  }

  static int? _parseSpecialBoundedInt(
    dynamic value,
    int specialValue,
    int maximum,
  ) {
    if (value == null) return null;
    final parsed = value is int ? value : int.tryParse(value.toString());
    if (parsed == specialValue ||
        (parsed != null && parsed >= 1 && parsed <= maximum)) {
      return parsed;
    }
    return null;
  }

  static String? _parseIntervalUnit(dynamic value) {
    final unit = value?.toString().trim().toLowerCase();
    return const {'days', 'weekdays', 'weeks', 'months', 'years'}.contains(unit)
        ? unit
        : null;
  }

  static String _toTitleCase(String value) {
    return value
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }
}
