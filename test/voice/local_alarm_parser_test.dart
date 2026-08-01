import 'package:clock_app/voice/local_alarm_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 8, 1, 13);

  group('LocalAlarmParser', () {
    test('parses a daily alarm and task label', () {
      final alarm = LocalAlarmParser.parse(
        'Remind me every day at 7am to cook soya and eggs',
        now: now,
      );

      expect(alarm, isNotNull);
      expect(alarm!.hour, 7);
      expect(alarm.minute, 0);
      expect(alarm.recurrence, 'daily');
      expect(alarm.label, 'Cook Soya And Eggs');
    });

    test('parses weekday and weekend recurrence', () {
      final weekdayAlarm = LocalAlarmParser.parse(
        'Wake me at 6:30 on weekdays',
        now: now,
      );
      final weekendAlarm = LocalAlarmParser.parse(
        'Set an alarm at 9 am every weekend',
        now: now,
      );

      expect(weekdayAlarm!.recurrence, 'weekdays');
      expect(weekdayAlarm.hour, 6);
      expect(weekdayAlarm.minute, 30);
      expect(weekdayAlarm.label, 'Wake Up');
      expect(weekendAlarm!.recurrence, 'weekends');
    });

    test('parses selected weekdays', () {
      final alarm = LocalAlarmParser.parse(
        'Every Monday Wednesday and Friday at 8:15 pm for gym',
        now: now,
      );

      expect(alarm!.recurrence, 'weekly');
      expect(alarm.days, ['monday', 'wednesday', 'friday']);
      expect(alarm.hour, 20);
      expect(alarm.minute, 15);
      expect(alarm.label, 'Gym');
    });

    test('parses noon, midnight, and spoken clock phrases', () {
      expect(
        LocalAlarmParser.parse('Set an alarm at noon', now: now)!.hour,
        12,
      );
      expect(
        LocalAlarmParser.parse('Set an alarm at midnight', now: now)!.hour,
        0,
      );

      final quarterTo = LocalAlarmParser.parse(
        'Set an alarm at quarter to eight pm',
        now: now,
      );
      final halfPast = LocalAlarmParser.parse(
        'Set an alarm at half past six in the morning',
        now: now,
      );
      final spoken = LocalAlarmParser.parse(
        'Set an alarm at seven thirty in the morning',
        now: now,
      );

      expect([quarterTo!.hour, quarterTo.minute], [19, 45]);
      expect([halfPast!.hour, halfPast.minute], [6, 30]);
      expect([spoken!.hour, spoken.minute], [7, 30]);
    });

    test('parses relative alarms without a network service', () {
      final alarm = LocalAlarmParser.parse(
        'Remind me in twenty minutes to stretch',
        now: now,
      );

      expect(alarm!.hour, 13);
      expect(alarm.minute, 20);
      expect(alarm.date, DateTime(2026, 8, 1));
      expect(alarm.recurrence, 'once');
      expect(alarm.label, 'Stretch');
    });

    test('parses tomorrow and next weekday as one-time dates', () {
      final tomorrow = LocalAlarmParser.parse(
        'Tomorrow at 9 am remind me to call mom',
        now: now,
      );
      final nextMonday = LocalAlarmParser.parse(
        'Next Monday at 8 am to submit report',
        now: now,
      );

      expect(tomorrow!.date, DateTime(2026, 8, 2));
      expect(tomorrow.recurrence, 'once');
      expect(tomorrow.label, 'Call Mom');
      expect(nextMonday!.date, DateTime(2026, 8, 3));
      expect(nextMonday.recurrence, 'once');
      expect(nextMonday.label, 'Submit Report');
    });

    test('parses named and numeric calendar dates', () {
      final named = LocalAlarmParser.parse(
        'On August 5 at 14:20 remind me to pay rent',
        now: now,
      );
      final numeric = LocalAlarmParser.parse(
        'On 6/8/2026 at 7 pm for dinner',
        now: now,
      );

      expect(named!.date, DateTime(2026, 8, 5));
      expect([named.hour, named.minute], [14, 20]);
      expect(named.label, 'Pay Rent');
      expect(numeric!.date, DateTime(2026, 8, 6));
      expect(numeric.label, 'Dinner');
    });

    test('returns an incomplete command when time is omitted', () {
      final alarm = LocalAlarmParser.parse(
        'Remind me every weekday to charge my watch',
        now: now,
      );

      expect(alarm, isNotNull);
      expect(alarm!.isComplete, isFalse);
      expect(alarm.recurrence, 'weekdays');
      expect(alarm.label, 'Charge My Watch');
    });

    test('rejects an explicitly past time', () {
      final alarm = LocalAlarmParser.parse(
        'Today at 9 am to call mom',
        now: now,
      );

      expect(alarm, isNull);
      expect(LocalAlarmParser.failureMessage, contains('already passed'));
    });
  });
}
