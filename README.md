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
- Daily, weekday, weekend, weekly, date, and one-time schedules
- Live on-device speech transcription
- Fully local command parsing with no AI API, account, or API key
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

Supported phrasing includes numeric and spoken times, noon and midnight,
quarter/half-past expressions, relative alarms, daily/weekday/weekend rules,
selected weekdays, tomorrow, next weekdays, and calendar dates.

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
