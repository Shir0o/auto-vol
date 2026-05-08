# Contributing to Vocus

Thanks for your interest! This guide covers the basics for contributing.

## Development setup

1. Install Flutter on the stable channel (Dart SDK `>= 3.11.5`). Verify with `flutter --version`.
2. Fork and clone the repo.
3. `flutter pub get`
4. Create your own Google Cloud OAuth client (iOS + Web) and pass the IDs at run/build time via `--dart-define`. Do **not** edit committed values in `lib/main.dart`:
   ```bash
   flutter run \
     --dart-define=GOOGLE_IOS_CLIENT_ID=<your-ios-client-id> \
     --dart-define=GOOGLE_WEB_CLIENT_ID=<your-web-client-id>
   ```

## Workflow

1. Open an issue for non-trivial changes so we can align on approach.
2. Create a branch from `main`: `git checkout -b feat/short-description`.
3. **Write a failing test first.** This project follows Test-Driven Development — see [`GEMINI.md`](GEMINI.md).
4. Implement the change.
5. Run the local checks listed below.
6. Open a PR against `main`.

## Local checks (must pass before opening a PR)

```bash
dart format .
flutter analyze
flutter test
```

CI runs the same checks on every PR.

## Commit messages

Follow conventional-commit style:

- `feat: add volume rules screen`
- `fix: prevent crash when calendar list is empty`
- `test: cover all-day filter edge case`
- `docs: update README architecture section`
- `refactor: extract rule matching helper`

Keep commits focused. Squash noise commits before opening a PR.

## Pull requests

- Reference the related issue (`Closes #123`).
- Describe **what** changed and **why**.
- Include screenshots for UI changes.
- Make sure CI is green.

## Code style

- Defer to `dart format` and the rules in [`analysis_options.yaml`](analysis_options.yaml).
- Prefer Riverpod providers over global singletons.
- Keep services free of Flutter widget dependencies so they stay easy to unit-test.

## Reporting bugs / requesting features

Open an issue with:

- What you expected
- What happened instead
- Steps to reproduce
- Device + OS + Flutter version (`flutter --version`)
