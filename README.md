<div align="center">
  <img src="icon.png" alt="Alarm app icon" width="120" />
  <h1>Alarm</h1>
  <p>Smart alarms, timers, clocks, and voice-powered scheduling.</p>
</div>

Alarm is a customizable Android alarm, clock, timer, and stopwatch app built
with Flutter. Its private, rule-based voice agent turns common spoken commands
into scheduled alarms without sending transcripts to an AI service.

## Highlights

- Create alarms by voice using natural language
- Daily, weekday, weekend, weekly, interval, monthly, yearly, date, and one-time schedules
- Live on-device speech transcription
- Fully local command parsing with no AI API, account, or API key
- Aurora glass interface with smooth, accessibility-aware motion
- Resolution-independent visuals that remain crisp on high-density and 4K displays
- Custom alarm labels, melodies, vibration, snooze rules, and dismissal tasks
- Multiple timers, presets, stopwatch laps, and world clocks
- Material You and customizable themes
- Home-screen clock widgets

## Offline voice alarms

The voice agent uses the device speech recognizer for transcription. A
deterministic parser then recognizes times, repeat rules, weekdays, dates, and
labels directly on the phone. There is no OpenRouter integration or cloud
language-model dependency.

```sh
flutter run --flavor dev
```

For a release APK:

```sh
flutter build apk --release --split-per-abi --flavor prod
```

Official GitHub releases use a persistent Android signing key stored in
encrypted Actions secrets, allowing future APK versions to install as updates.
Keep `android/key.properties` and `android/app/release-key.jks` private when
building signed releases locally.

Example voice requests:

- "Remind me every day at 7 AM to cook breakfast."
- "Wake me at 6:30 on weekdays."
- "Set an alarm for Saturday at 9 AM."
- "Remind me every other day at 8 PM to take medicine."
- "Every three business days at 7 AM, remind me to send the report."
- "Set an alarm on the first Monday of every month at 9 AM for planning."
- "Remind me on the last day of every month at 8 PM to close accounts."

Supported phrasing includes numeric, spoken, 24-hour, noon, midnight,
quarter/half-past, and minutes-to/past times; relative minutes, hours, days,
and weeks; daily, workday, weekday, weekend, selected-day, and exclusion rules;
calendar-day, business-day, weekly, monthly, quarterly, and yearly intervals;
alternating weekdays and weekends; day ranges such as Monday-Friday; nth or
last weekdays of a month; tomorrow, coming weekdays, and calendar dates.

The grammar recognizes hundreds of practical wording combinations while
remaining deterministic and offline. If a request cannot be represented
safely—such as every 90 minutes or a location-specific holiday calendar—the
agent explains the limitation instead of silently creating the wrong alarm.

## Development

Requirements:

- Flutter 3.22 or newer
- Android SDK

Install dependencies and run:

```sh
flutter pub get
flutter run --flavor dev
```

Run project checks:

```sh
dart format lib test
flutter analyze
flutter test
```

## Repository

Issues, releases, and source updates are maintained at:

https://github.com/rahulcvwebsitehosting/Alarm

## License

Distributed under the GNU General Public License v3.0. See [LICENSE](LICENSE).
