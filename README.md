# Vocus

Auto-volume utility for Google Calendar users.

Vocus automatically adjusts your device's media volume based on your Google Calendar schedule. It ensures your device is quiet during meetings and restores your volume afterwards.

## Status

This project is in early development. Expect APIs, UI, and platform support to change as the app matures.

## Supported platforms

Vocus currently supports Android and iOS only. Desktop and web Flutter scaffolds are intentionally not included because the app depends on mobile-specific Google Sign-In, background execution, notification, and device-volume APIs.

## Features

- **Automatic Volume Management**: Syncs with Google Calendar to determine when you're in a meeting.
- **Smart Rules**: Create keyword-based rules (e.g., "Focus", "Meeting") to set specific volume levels.
- **Volume Restore**: Remembers your volume before a meeting starts and restores it when the meeting ends.
- **Background Monitoring**: Uses a foreground service to maintain automation even when the app is backgrounded.
- **In-Event Overrides**: Supports `[vol:X]` or `!silent` patterns in event titles/descriptions for one-off overrides.

## Implementation Details

- Built with Flutter & Riverpod.
- Follows Test-Driven Development (TDD).
- Integrates with Google Calendar API.
- Uses `flutter_foreground_task` for reliable background execution.

## Getting started

1. Sign in with your Google account.
2. Select the calendars you want to monitor.
3. Enable "Auto-Volume" in settings.
4. (Optional) Define automation rules for specific event keywords.

## Local development

### Prerequisites

- Flutter stable with Dart SDK `>= 3.11.5`
- A Google Cloud project with OAuth client IDs for the platforms you want to run

### Configuration

To run the app locally, provide your own Google Cloud OAuth client IDs.

1. Copy `.env.example` to `.env`.
2. Fill in `GOOGLE_IOS_CLIENT_ID` and `GOOGLE_WEB_CLIENT_ID`.
3. The `.env` file is already added to `.gitignore` to prevent leaking secrets.

```bash
cp .env.example .env
flutter pub get
flutter run
```

You can also pass credentials with `--dart-define` at run/build time:

```bash
flutter run \
  --dart-define=GOOGLE_IOS_CLIENT_ID=<your-ios-client-id> \
  --dart-define=GOOGLE_WEB_CLIENT_ID=<your-web-client-id>
```

### Checks

Run tests with:

```bash
dart format .
flutter analyze
flutter test
```

CI runs formatting, analysis, and tests on every pull request.

## Privacy and OAuth

Vocus reads calendar data only to determine volume automation state. Contributors should use their own Google Cloud OAuth clients for local development and must not commit `.env` files or private credentials.

See [PRIVACY.md](PRIVACY.md) for the project privacy policy.

## Build and release

### Android

```bash
flutter build apk --release \
  --dart-define=GOOGLE_IOS_CLIENT_ID=<your-ios-client-id> \
  --dart-define=GOOGLE_WEB_CLIENT_ID=<your-web-client-id>
```

For Play Store distribution, build an app bundle instead:

```bash
flutter build appbundle --release \
  --dart-define=GOOGLE_IOS_CLIENT_ID=<your-ios-client-id> \
  --dart-define=GOOGLE_WEB_CLIENT_ID=<your-web-client-id>
```

Configure release signing locally or in CI. Do not commit keystores, signing passwords, provisioning profiles, or private keys.

### iOS

```bash
flutter build ipa --release \
  --dart-define=GOOGLE_IOS_CLIENT_ID=<your-ios-client-id> \
  --dart-define=GOOGLE_WEB_CLIENT_ID=<your-web-client-id>
```

Use Xcode or App Store Connect for signing, provisioning, TestFlight, and App Store submission.

### Release checklist

Before tagging a release:

1. Update `version` in [pubspec.yaml](pubspec.yaml).
2. Run `dart format .`, `flutter analyze`, and `flutter test`.
3. Verify Android and iOS OAuth redirect/client configuration.
4. Build release artifacts for the target platform.
5. Create a GitHub release with user-facing notes and any known limitations.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for setup, workflow, and pull request expectations.

## Security

Please report vulnerabilities through the process in [SECURITY.md](SECURITY.md). Do not open public issues for security-sensitive reports.

## License

Vocus is released under the [MIT License](LICENSE).
