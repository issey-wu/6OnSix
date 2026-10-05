# 6 On Six

A Duolingo-style mobile app that teaches volleyball fundamentals: court
positions, roles, terminology, rotations, and the 5-1 system. Short lessons,
instant feedback, progression, streaks, and review, all fully offline so it
works in gyms with no signal.

Built with Flutter for iOS (primary) and Android. McMaster PROCTECH 4TR3
capstone by Issey Wu (development) and Yash Dubey (content, requirements,
testing, documentation).

> **Current phase:** fully offline. No accounts, no network, no analytics.
> Demo builds install from Xcode (free provisioning) or as a sideloaded APK.

## Prerequisites

| Tool | Version | Needed for |
|---|---|---|
| Flutter | **3.47.6** (Dart 3.13.5), exactly | everything |
| Git | any recent | everything |
| Xcode + CocoaPods | latest | iOS builds (macOS only) |
| Android Studio (Android SDK) + JDK 17 | latest | Android builds |

Use exactly Flutter **3.47.6**. Both development machines and CI use this
version; a different version can change formatting and lint results.

## Setup

### macOS

```sh
# 1. Install the pinned Flutter SDK
git clone https://github.com/flutter/flutter.git -b 3.47.6 ~/development/flutter
echo 'export PATH="$HOME/development/flutter/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
flutter --version        # must say 3.47.6

# 2. Check toolchains (Xcode, CocoaPods, Android SDK)
flutter doctor

# 3. Get the project
git clone <repo-url> 6OnSix
cd 6OnSix
flutter pub get
```

### Windows

```powershell
# 1. Install the pinned Flutter SDK
git clone https://github.com/flutter/flutter.git -b 3.47.6 C:\dev\flutter
# Add C:\dev\flutter\bin to your user PATH (System Properties > Environment
# Variables), then open a new terminal.
flutter --version        # must say 3.47.6

# 2. Check toolchains (Android Studio, Android SDK)
flutter doctor

# 3. Get the project
git clone <repo-url> 6OnSix
cd 6OnSix
flutter pub get
```

Windows notes:
- Turn on **Developer Mode** (Settings > System > For developers). Flutter
  needs symlink support once the project uses plugins.
- iOS builds and device testing are Mac-only. On Windows, build and run Android.
- Line endings are enforced as LF by `.gitattributes`; no Git config needed.
- Keep the repo out of OneDrive and other synced folders.

## Commands

```sh
flutter pub get          # install dependencies
dart format .            # format code
flutter analyze          # lints (must be clean)
flutter test             # unit and widget tests (must pass)
flutter run              # run on a connected device or simulator
open -b com.apple.dt.Devices  # macOS: open Xcode 27's Device Hub to view simulators
```

Run `dart format .`, `flutter analyze`, and `flutter test` before every commit.
CI runs the same checks, plus an Android debug build, on every push and pull
request to `main`.

## Project layout

```
lib/
  app/        # bootstrap, router, theme, config providers, logger
  core/       # shared domain models, repository interfaces, data implementations
  features/   # learning_path, lesson, glossary, progress, settings, dev_menu
test/         # mirrors lib/
docs/         # project context, decision log, historical reference PDFs
```

## More

- `CLAUDE.md`: architecture, data rules, and conventions.
- `docs/project-context.md`: background, timeline, and open questions.
- `docs/decisions.md`: every decision and why.
- `CHANGELOG.md`: notable changes.
