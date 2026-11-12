# fesco-login-flutter

Flutter baseline for the FESCO employee login flow (phone → SMS OTP).

Design reference: Figma file `Dnkf3g1IvJR7QDjvVy6ZXl` (screens `1:710`, `1:943`, `1:574`, `1:1096`).

## Requirements

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable channel)

## Getting started

```bash
flutter pub get
flutter run
```

Web (no device):

```bash
flutter run -d chrome
```

Linux desktop:

```bash
flutter run -d linux
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
| `lib/main.dart` | `main()` entry |
| `lib/app.dart` | `MaterialApp.router` + FESCO theme |
| `lib/theme/` | Colors, typography, `ThemeData` |
| `lib/router/` | `go_router` paths and helpers |
| `lib/screens/login/` | Phone entry stub (`1:710`–`1:574`) |
| `lib/screens/otp/` | OTP confirmation stub (`1:1096`) |
| `lib/widgets/` | Shared scaffold/button stubs |
| `assets/` | Placeholder for exported Figma assets |

### Routes

| Name | Path | Figma |
|------|------|-------|
| `login-phone` | `/login` | `1:710` (UI phases `1:943`, `1:574` on same screen) |
| `login-otp` | `/login/otp?phone=…` | `1:1096` |

Phone UI phases are tracked via route name constants `login-phone-keyboard-empty` and `login-phone-keyboard-filled` (shown in debug label on screen; not separate URLs yet).

## Next steps (screens agent)

- Pixel UI: logo, background pattern, status bar, masks, OTP cells
- Export assets from Figma into `assets/` and register in `pubspec.yaml`
- Confirm OTP accent color hex from Figma
- Optional: dedicated dev routes per Figma frame for visual regression
