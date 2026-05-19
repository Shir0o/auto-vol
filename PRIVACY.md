# Privacy Policy

Vocus is designed to automate device volume from Google Calendar events.

## Data accessed

When you connect Google Calendar, Vocus may access:

- Calendar names and identifiers
- Event titles, descriptions, start times, and end times
- Calendar color metadata used to display schedules in the app

Vocus uses this data to decide when volume automation should run and which rule should apply.

## Data stored on device

Vocus may store app preferences locally on your device, including:

- Selected calendar IDs
- Automation settings
- Volume rules and event-specific overrides
- Cached upcoming event data used by background automation
- Temporary volume and Do Not Disturb snapshots used to restore prior settings

## Data sharing

Vocus does not sell calendar data, share it with third-party analytics services, or use it for advertising.

Calendar access is used only for app functionality. Google authentication is handled through Google Sign-In and Google Calendar APIs.

## Credentials

Contributors and self-hosted builds must use their own Google Cloud OAuth client IDs. Do not commit `.env` files, OAuth secrets, API keys, signing keys, or provisioning profiles.

## Removing access

You can disconnect Google Calendar in the app by signing out. You can also revoke Google account access from your Google Account security settings.

## Contact

For privacy or security concerns, contact the maintainer listed in [CODEOWNERS](.github/CODEOWNERS). For security vulnerabilities, follow [SECURITY.md](SECURITY.md).
