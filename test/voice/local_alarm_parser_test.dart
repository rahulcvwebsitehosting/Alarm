import 'package:clock_app/voice/local_alarm_parser.dart';
import 'package:clock_app/voice/interval_dates.dart';
import 'package:clock_app/voice/parsed_alarm.dart';
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

    test('recognizes more than 150 common recurrence phrasings', () {
      const dailyPhrases = [
        'daily',
        'everyday',
        'every day',
        'each day',
        'each and every day',
        'every single day',
        'once a day',
        'once daily',
        'day after day',
        'all days',
        'all week',
        'seven days a week',
        '7 days a week',
        'nightly',
        'every morning',
        'each morning',
        'every evening',
        'each night',
      ];
      const weekdayPhrases = [
        'weekday',
        'weekdays',
        'every weekday',
        'each weekday',
        'workday',
        'work days',
        'working days',
        'business days',
        'school days',
        'office days',
        'during the week',
        'Monday to Friday',
        'Monday-Friday',
        'Mon-Fri',
      ];
      const weekendPhrases = [
        'weekend',
        'weekends',
        'every weekend',
        'each weekend',
        'weekends only',
        'on the weekend',
        'Saturday and Sunday',
        'Saturday through Sunday',
        'Sat-Sun',
        'every Saturday and Sunday',
      ];
      const wrappers = [
        'Remind me {rule} at 7am to eat soya',
        'Set an alarm {rule} at 7 am called Morning Routine',
        'Wake me {rule} at seven in the morning',
        'Please set 07:00 {rule} for exercise',
      ];

      void expectCorpus(List<String> phrases, String recurrence) {
        for (final phrase in phrases) {
          for (final wrapper in wrappers) {
            final command = wrapper.replaceFirst('{rule}', phrase);
            final alarm = LocalAlarmParser.parse(command, now: now);
            expect(
              alarm,
              isNotNull,
              reason: 'Failed to parse: $command',
            );
            expect(
              alarm!.recurrence,
              recurrence,
              reason: 'Wrong recurrence for: $command',
            );
            expect([alarm.hour, alarm.minute], [7, 0]);
          }
        }
      }

      expectCorpus(dailyPhrases, 'daily');
      expectCorpus(weekdayPhrases, 'weekdays');
      expectCorpus(weekendPhrases, 'weekends');
    });

    test('supports day ranges, aliases, and exclusions', () {
      final range = LocalAlarmParser.parse(
        'Tuesday through Thursday at 8 am for study',
        now: now,
      );
      final wrapRange = LocalAlarmParser.parse(
        'Friday to Monday at 8 am for medication',
        now: now,
      );
      final exceptSunday = LocalAlarmParser.parse(
        'Every day except Sunday at 7 am to exercise',
        now: now,
      );
      final exceptFriday = LocalAlarmParser.parse(
        'Weekdays excluding Friday at 7 am for work',
        now: now,
      );
      final saturdayOnly = LocalAlarmParser.parse(
        'Weekends but not Sunday at 9 am for hiking',
        now: now,
      );

      expect(range!.days, ['tuesday', 'wednesday', 'thursday']);
      expect(wrapRange!.days, ['monday', 'friday', 'saturday', 'sunday']);
      expect(exceptSunday!.days, [
        'monday',
        'tuesday',
        'wednesday',
        'thursday',
        'friday',
        'saturday',
      ]);
      expect(exceptFriday!.days, [
        'monday',
        'tuesday',
        'wednesday',
        'thursday',
      ]);
      expect(saturdayOnly!.days, ['saturday']);
      expect(
        [range.recurrence, wrapRange.recurrence],
        ['weekly', 'weekly'],
      );
    });

    test('distinguishes one-time weekdays from repeating weekdays', () {
      final oneTime = LocalAlarmParser.parse(
        'Set an alarm for Saturday at 9 am',
        now: now,
      );
      final plural = LocalAlarmParser.parse(
        'Set an alarm on Saturdays at 9 am',
        now: now,
      );
      final every = LocalAlarmParser.parse(
        'Set an alarm every Saturday at 9 am',
        now: now,
      );

      expect(oneTime!.recurrence, 'once');
      expect(oneTime.date, DateTime(2026, 8, 8));
      expect(oneTime.label, 'Voice Alarm');
      expect(plural!.recurrence, 'weekly');
      expect(plural.days, ['saturday']);
      expect(every!.recurrence, 'weekly');
    });

    test('parses calendar and business-day intervals', () {
      final commands = <String, List<Object>>{
        'Every other day at 7 am to stretch': [2, 'days'],
        'Every 3 days at 7 am to stretch': [3, 'days'],
        'Every 2nd day at 7 am to stretch': [2, 'days'],
        'Once every four days at 7 am to stretch': [4, 'days'],
        'Every 48 hours at 7 am to stretch': [2, 'days'],
        'Every 2880 minutes at 7 am to stretch': [2, 'days'],
        'Every other week at 7 am to plan': [2, 'weeks'],
        'Fortnightly at 7 am to plan': [2, 'weeks'],
        'Biweekly at 7 am to plan': [2, 'weeks'],
        'Every 3 weeks at 7 am to plan': [3, 'weeks'],
        'Every other weekday at 7 am to commute': [2, 'weekdays'],
        'Every 3 business days at 7 am to report': [3, 'weekdays'],
        'Every other month at 7 am to review': [2, 'months'],
        'Quarterly at 7 am to review': [3, 'months'],
        'Every 6 months at 7 am to review': [6, 'months'],
        'Annually on August 5 at 7 am to renew': [1, 'years'],
        'Every 2 years on August 5 at 7 am to renew': [2, 'years'],
      };

      for (final entry in commands.entries) {
        final alarm = LocalAlarmParser.parse(entry.key, now: now);
        expect(alarm, isNotNull, reason: entry.key);
        expect(alarm!.recurrence, 'interval', reason: entry.key);
        expect(alarm.intervalValue, entry.value[0], reason: entry.key);
        expect(alarm.intervalUnit, entry.value[1], reason: entry.key);
      }
    });

    test('parses alternating weekdays and weekends', () {
      final monday = LocalAlarmParser.parse(
        'Every other Monday at 8 am for therapy',
        now: now,
      );
      final weekend = LocalAlarmParser.parse(
        'Alternate weekends at 9 am for hiking',
        now: now,
      );
      final thirdFriday = LocalAlarmParser.parse(
        'Every third Friday at 6 pm for dinner',
        now: now,
      );

      expect([monday!.intervalValue, monday.intervalUnit], [2, 'weeks']);
      expect(monday.days, ['monday']);
      expect(weekend!.days, ['saturday', 'sunday']);
      expect(weekend.intervalValue, 2);
      expect(thirdFriday!.intervalValue, 3);
      expect(thirdFriday.days, ['friday']);
    });

    test('parses monthly day and nth-weekday rules', () {
      final fifteenth = LocalAlarmParser.parse(
        'On the 15th of every month at 7 am to pay rent',
        now: now,
      );
      final lastDay = LocalAlarmParser.parse(
        'Every month on the last day at 8 pm to close accounts',
        now: now,
      );
      final firstMonday = LocalAlarmParser.parse(
        'First Monday of every month at 9 am for planning',
        now: now,
      );
      final lastFriday = LocalAlarmParser.parse(
        'Every month on the last Friday at 6 pm for dinner',
        now: now,
      );

      expect(fifteenth!.monthDay, 15);
      expect(lastDay!.monthDay, -1);
      expect(firstMonday!.weekOfMonth, 1);
      expect(firstMonday.days, ['monday']);
      expect(lastFriday!.weekOfMonth, -1);
      expect(lastFriday.days, ['friday']);
    });

    test('parses expanded clock language', () {
      final commands = <String, List<int>>{
        'Every day at twenty past seven am to exercise': [7, 20],
        'Every day at ten minutes to eight am to exercise': [7, 50],
        'Every day at a quarter of eight am to exercise': [7, 45],
        'Every day at half seven am to exercise': [7, 30],
        'Every day at seven oh five am to exercise': [7, 5],
        'Every day seven thirty am to exercise': [7, 30],
        'Every day at 0730 to exercise': [7, 30],
        'Every day at 1930 hours to exercise': [19, 30],
        'Every day at 8 in the evening to exercise': [20, 0],
        'Every day at 8 in the night to exercise': [20, 0],
      };
      for (final entry in commands.entries) {
        final alarm = LocalAlarmParser.parse(entry.key, now: now);
        expect(alarm, isNotNull, reason: entry.key);
        expect([alarm!.hour, alarm.minute], entry.value, reason: entry.key);
        expect(alarm.recurrence, 'daily', reason: entry.key);
      }
    });

    test('parses expanded relative times and dates', () {
      final ninetyMinutes = LocalAlarmParser.parse(
        'Remind me after one hour and thirty minutes to stretch',
        now: now,
      );
      final fromNow = LocalAlarmParser.parse(
        'Remind me ninety minutes from now to stretch',
        now: now,
      );
      final daysLater = LocalAlarmParser.parse(
        'Three days from now at 7 am to submit report',
        now: now,
      );
      final weeksLater = LocalAlarmParser.parse(
        'After two weeks at 7 am to submit report',
        now: now,
      );
      final leapDay = LocalAlarmParser.parse(
        'On February 29 at 7 am to celebrate',
        now: now,
      );

      expect([ninetyMinutes!.hour, ninetyMinutes.minute], [14, 30]);
      expect([fromNow!.hour, fromNow.minute], [14, 30]);
      expect(daysLater!.date, DateTime(2026, 8, 4));
      expect(weeksLater!.date, DateTime(2026, 8, 15));
      expect(leapDay!.date, DateTime(2028, 2, 29));
    });

    test('rejects unsupported or ambiguous repeat rules explicitly', () {
      for (final command in [
        'Remind me every 90 minutes to drink water',
        'Remind me every 6 hours to drink water',
        'Remind me twice a day to drink water',
      ]) {
        expect(LocalAlarmParser.parse(command, now: now), isNull);
        expect(LocalAlarmParser.failureMessage, contains('shorter than one day'));
      }

      expect(
        LocalAlarmParser.parse(
          'Remind me every few days at 7 am to exercise',
          now: now,
        ),
        isNull,
      );
      expect(LocalAlarmParser.failureMessage, contains('exact repeat interval'));

      expect(
        LocalAlarmParser.parse(
          'Remind me every weekday except holidays at 7 am to commute',
          now: now,
        ),
        isNull,
      );
      expect(LocalAlarmParser.failureMessage, contains('Holiday calendars'));
    });
  });

  group('materializeIntervalDates', () {
    ParsedAlarm alarm({
      required int amount,
      required String unit,
      DateTime? date,
      List<String> days = const [],
      int? monthDay,
      int? weekOfMonth,
    }) {
      return ParsedAlarm(
        hour: 7,
        minute: 0,
        recurrence: 'interval',
        days: days,
        label: 'Test',
        date: date,
        intervalValue: amount,
        intervalUnit: unit,
        monthDay: monthDay,
        weekOfMonth: weekOfMonth,
      );
    }

    test('generates every-other-day dates', () {
      final dates = materializeIntervalDates(
        alarm(
          amount: 2,
          unit: 'days',
          date: DateTime(2026, 8, 3),
        ),
        now: DateTime(2026, 8, 1, 13),
      );

      expect(dates.take(4), [
        DateTime(2026, 8, 3),
        DateTime(2026, 8, 5),
        DateTime(2026, 8, 7),
        DateTime(2026, 8, 9),
      ]);
    });

    test('generates business-day intervals without weekends', () {
      final dates = materializeIntervalDates(
        alarm(
          amount: 2,
          unit: 'weekdays',
          date: DateTime(2026, 8, 3),
        ),
        now: DateTime(2026, 8, 1, 13),
      );

      expect(dates.take(4), [
        DateTime(2026, 8, 3),
        DateTime(2026, 8, 5),
        DateTime(2026, 8, 7),
        DateTime(2026, 8, 11),
      ]);
    });

    test('generates selected days every two weeks', () {
      final dates = materializeIntervalDates(
        alarm(
          amount: 2,
          unit: 'weeks',
          date: DateTime(2026, 8, 3),
          days: const ['monday', 'friday'],
        ),
        now: DateTime(2026, 8, 1, 13),
      );

      expect(dates.take(4), [
        DateTime(2026, 8, 3),
        DateTime(2026, 8, 7),
        DateTime(2026, 8, 17),
        DateTime(2026, 8, 21),
      ]);
    });

    test('generates last days and nth weekdays of each month', () {
      final lastDays = materializeIntervalDates(
        alarm(
          amount: 1,
          unit: 'months',
          date: DateTime(2026, 8, 1),
          monthDay: -1,
        ),
        now: DateTime(2026, 8, 1, 13),
      );
      final firstMondays = materializeIntervalDates(
        alarm(
          amount: 1,
          unit: 'months',
          date: DateTime(2026, 8, 1),
          days: const ['monday'],
          weekOfMonth: 1,
        ),
        now: DateTime(2026, 8, 1, 13),
      );

      expect(lastDays.take(3), [
        DateTime(2026, 8, 31),
        DateTime(2026, 9, 30),
        DateTime(2026, 10, 31),
      ]);
      expect(firstMondays.take(3), [
        DateTime(2026, 8, 3),
        DateTime(2026, 9, 7),
        DateTime(2026, 10, 5),
      ]);
    });
  });
}
