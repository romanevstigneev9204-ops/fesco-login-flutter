# fesco-login-flutter

Flutter baseline for the FESCO login application.

## Requirements

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable channel)

## Getting started

```bash
flutter pub get
flutter run
```

## Quality checks

```bash
flutter analyze
flutter test
```

CI runs the same checks on push and pull requests via `.github/workflows/flutter_analyze.yml`.

## Project layout

| Path | Purpose |
|------|---------|
| `lib/main.dart` | App entry point and login placeholder UI |
| `test/widget_test.dart` | Widget smoke test |
