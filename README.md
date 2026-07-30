<div align="center">
  <img src="icon.png" alt="Alarm app icon" width="120" />
  <h1>Alarm</h1>
  <p>Smart alarms, timers, clocks, and voice-powered scheduling.</p>
</div>

Alarm is a customizable Android alarm, clock, timer, and stopwatch app built
with Flutter. It includes an AI voice agent that turns natural-language
requests into scheduled alarms.

## Highlights

- Create alarms by voice using natural language
- Daily, weekday, weekend, weekly, date, and one-time schedules
- Live on-device speech transcription
- Free-model alarm parsing through OpenRouter
- Custom alarm labels, melodies, vibration, snooze rules, and dismissal tasks
- Multiple timers, presets, stopwatch laps, and world clocks
- Material You and customizable themes
- Home-screen clock widgets

## Voice alarm setup

The voice agent uses `speech_to_text` for transcription and OpenRouter's
free-model router for alarm parsing. Keep the API key outside source control:

```sh
flutter run --flavor dev \
  --dart-define=OPENROUTER_API_KEY=your_openrouter_key
```

For a release APK:

```sh
flutter build apk --release --split-per-abi --flavor prod \
  --dart-define=OPENROUTER_API_KEY=your_openrouter_key
```

Example voice requests:

- "Remind me every day at 7 AM to cook breakfast."
- "Wake me at 6:30 on weekdays."
- "Set an alarm for Saturday at 9 AM."

The parser uses `openrouter/free`, which routes exclusively to currently
available free models, with a specific `:free` model as a fallback.

## Development

Requirements:

- Flutter 3.22 or newer
- Android SDK
- An OpenRouter API key for the optional voice-agent feature

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
