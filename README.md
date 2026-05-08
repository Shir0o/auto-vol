# Vocus

[![CI](https://github.com/Shir0o/auto-vol/actions/workflows/ci.yml/badge.svg)](https://github.com/Shir0o/auto-vol/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A small Flutter utility that automatically adjusts your device volume based on your Google Calendar events. Stay focused during meetings without thinking about it.

## Features

- **Google Calendar sync** — connect once, view your upcoming week.
- **Multi-calendar support** — pick which calendars drive automation.
- **Per-rule volume control** — match events by calendar + title pattern, set a target volume, and let the highest-priority rule win.
- **Default volume fallback** — set the level used when no event is active.
- **Schedule view** — Google-Calendar-style timeline grouped by day.
- **Android foreground service** — keeps automation running while the app is backgrounded.

## Status

Early development. Foundation in place (auth, calendar fetch, rule engine, rules UI, foreground service). See open issues for active work.

## Getting started

### Prerequisites

- Flutter (stable channel) shipping a Dart SDK `>= 3.11.5`. Verify with `flutter --version`.
- A Google Cloud OAuth client (iOS + Web) with the Calendar API enabled.

### Setup

```bash
git clone https://github.com/Shir0o/auto-vol.git
cd auto-vol
flutter pub get
flutter run \
  --dart-define=GOOGLE_IOS_CLIENT_ID=<your-ios-client-id> \
  --dart-define=GOOGLE_WEB_CLIENT_ID=<your-web-client-id>
```

If you omit the `--dart-define` flags, the maintainer's placeholder client IDs (set in [`lib/main.dart`](lib/main.dart)) are used — sign-in will not work outside the maintainer's project. Provide your own OAuth client IDs to develop locally.

### Running tests

```bash
flutter test
```

This project follows **Test-Driven Development** — write a failing test before adding behavior. See [`GEMINI.md`](GEMINI.md).

## Architecture

```
lib/
├── core/                  # cross-cutting (theme, providers, services, widgets)
└── features/
    ├── calendar/          # Google Sign-In + Calendar API fetch
    ├── schedule/          # timeline UI
    ├── settings/          # settings UI
    └── volume/            # rule engine + volume control + foreground service
```

State management is [Riverpod](https://riverpod.dev). Persistence is `shared_preferences`. Volume control uses [`flutter_volume_controller`](https://pub.dev/packages/flutter_volume_controller).

## Contributing

Contributions welcome — see [CONTRIBUTING.md](CONTRIBUTING.md).

## License

[MIT](LICENSE) © Tony Wang
