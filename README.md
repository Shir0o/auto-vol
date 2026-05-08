# Vocus

Auto-Volume utility for Google Calendar users.

Vocus automatically adjusts your device's media volume based on your Google Calendar schedule. It ensures your device is quiet during meetings and restores your volume afterwards.

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

## Getting Started

1. Sign in with your Google account.
2. Select the calendars you want to monitor.
3. Enable "Auto-Volume" in settings.
4. (Optional) Define automation rules for specific event keywords.

## Development

Run tests with:
```bash
flutter test
```
