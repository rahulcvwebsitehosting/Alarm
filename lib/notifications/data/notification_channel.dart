import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:clock_app/theme/theme.dart';

const String foregroundNotificationChannelKey = 'foreground';
const String alarmNotificationChannelGroupKey = 'alarm';
const String reminderNotificationChannelKey = 'reminders';
const String stopwatchNotificationChannelKey = 'stopwatch';
const String alarmNotificationChannelKey = 'alarms_and_timers';
const String timerNotificationChannelKey = 'timers';

final NotificationChannel alarmNotificationChannel = NotificationChannel(
  icon: 'resource://drawable/alarm_icon',
  // channelGroupKey: alarmNotificationChannelGroupKey,
  channelKey: alarmNotificationChannelKey,
  channelName: 'Alarms and Timers',
  channelDescription: 'Notification channel for clock alarms and timers',
  defaultColor: defaultColorScheme.accent,
  locked: true,
  importance: NotificationImportance.Max,
  criticalAlerts: true,
  playSound: false,
  enableVibration: false,
  enableLights: false,
);


// final NotificationChannel foregroundNotificationChannel = NotificationChannel(
//   icon: 'resource://drawable/alarm_icon',
//   // channelGroupKey: alarmNotificationChannelGroupKey,
//   channelKey: foregroundNotificationChannelKey,
//   channelName: 'Foreground Service',
//   channelDescription: 'Notification channel for foreground service',
//   defaultColor: defaultColorScheme.accent,
//   locked: true,
//   importance: NotificationImportance.Low,
//   criticalAlerts: false,
//   playSound: false,
//   enableVibration: false,
//   enableLights: false,
// );


final NotificationChannel reminderNotificationChannel = NotificationChannel(
  icon: 'resource://drawable/alarm_icon',
  // channelGroupKey: alarmNotificationChannelGroupKey,
  channelKey: reminderNotificationChannelKey,
  channelName: 'Reminders',
  channelDescription:
      'Notification channel for sending reminders of upcoming alarms',
  defaultColor: defaultColorScheme.accent,
  locked: false,
  importance: NotificationImportance.Default,
  playSound: false,
  enableVibration: false,
  enableLights: false,
);

final NotificationChannel timerNotificationChannel = NotificationChannel(
  icon: 'resource://drawable/timer_icon',
  // channelGroupKey: alarmNotificationChannelGroupKey,
  channelKey: timerNotificationChannelKey,
  channelName: 'Timers',
  channelDescription: 'Notification channel for showing timer progress',
  defaultColor: defaultColorScheme.accent,
  locked: false,
  importance: NotificationImportance.Default,
  playSound: false,
  enableVibration: false,
  enableLights: false,
);

final NotificationChannel stopwatchNotificationChannel = NotificationChannel(
  icon: 'resource://drawable/stopwatch_icon',
  // channelGroupKey: alarmNotificationChannelGroupKey,
  channelKey: stopwatchNotificationChannelKey,
  channelName: 'Stopwatch',
  channelDescription: 'Notification channel for showing stopwatch progress',
  defaultColor: defaultColorScheme.accent,
  locked: false,
  importance: NotificationImportance.Default,
  playSound: false,
  enableVibration: false,
  enableLights: false,
);

// final NotificationChannelGroup alarmNotificationChannelGroup =
//     NotificationChannelGroup(
//   channelGroupKey: alarmNotificationChannelGroupKey,
//   channelGroupName: 'Alarm',
//
// );
