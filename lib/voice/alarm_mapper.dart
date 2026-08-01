import 'package:clock_app/alarm/types/alarm.dart';
import 'package:clock_app/alarm/types/schedules/daily_alarm_schedule.dart';
import 'package:clock_app/alarm/types/schedules/dates_alarm_schedule.dart';
import 'package:clock_app/alarm/types/schedules/once_alarm_schedule.dart';
import 'package:clock_app/alarm/types/schedules/weekly_alarm_schedule.dart';
import 'package:clock_app/common/utils/list_storage.dart';
import 'package:clock_app/settings/types/setting.dart';
import 'package:clock_app/voice/parsed_alarm.dart';
import 'package:flutter/material.dart';

Future<void> saveParsedAlarm(
  ParsedAlarm parsedAlarm,
  BuildContext context,
) async {
  assert(context.mounted);
  if (!parsedAlarm.isComplete) {
    throw const FormatException('An alarm time is required.');
  }

  final alarm = Alarm.fromTimeOfDay(
    TimeOfDay(hour: parsedAlarm.hour!, minute: parsedAlarm.minute!),
  );

  alarm.setSettingWithoutNotify(
    'Label',
    parsedAlarm.label.isEmpty ? 'Voice Alarm' : parsedAlarm.label,
  );

  final scheduleType = parsedAlarm.date == null
      ? _scheduleTypeFor(parsedAlarm.recurrence)
      : DatesAlarmSchedule;
  final typeSetting = alarm.getSetting('Type') as SelectSetting<Type>;
  typeSetting.setValueWithoutNotify(typeSetting.getIndexOfValue(scheduleType));

  if (scheduleType == DatesAlarmSchedule) {
    final datesSetting = alarm.getSetting('Dates') as DateTimeSetting;
    datesSetting.setValueWithoutNotify([parsedAlarm.date!]);
  }

  if (scheduleType == DailyAlarmSchedule ||
      scheduleType == WeeklyAlarmSchedule) {
    final weekdaySetting =
        alarm.getSetting('Week Days') as ToggleSetting<int>;
    final selectedDays = _selectedWeekdays(parsedAlarm);
    weekdaySetting.setValueWithoutNotify(
      List<bool>.generate(
        7,
        (index) => selectedDays.contains(index + DateTime.monday),
      ),
    );
  }

  await alarm.update('saveParsedAlarm(): Alarm added by voice agent');

  final alarms = await loadList<Alarm>('alarms');
  alarms.insert(0, alarm);
  await saveList<Alarm>('alarms', alarms);
}

Type _scheduleTypeFor(String recurrence) {
  switch (recurrence) {
    case 'daily':
      return DailyAlarmSchedule;
    case 'weekdays':
    case 'weekends':
    case 'weekly':
      return WeeklyAlarmSchedule;
    case 'once':
    default:
      return OnceAlarmSchedule;
  }
}

Set<int> _selectedWeekdays(ParsedAlarm parsedAlarm) {
  switch (parsedAlarm.recurrence) {
    case 'daily':
      return {
        DateTime.monday,
        DateTime.tuesday,
        DateTime.wednesday,
        DateTime.thursday,
        DateTime.friday,
        DateTime.saturday,
        DateTime.sunday,
      };
    case 'weekdays':
      return {
        DateTime.monday,
        DateTime.tuesday,
        DateTime.wednesday,
        DateTime.thursday,
        DateTime.friday,
      };
    case 'weekends':
      return {DateTime.saturday, DateTime.sunday};
    case 'weekly':
      final selected = parsedAlarm.days
          .map((day) => _weekdayNumbers[day])
          .whereType<int>()
          .toSet();
      return selected.isEmpty ? {DateTime.monday} : selected;
    default:
      return const {};
  }
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
