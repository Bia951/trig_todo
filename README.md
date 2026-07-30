<div align="center">

# Trig

**Turn todos into action.**

A clean, local-first task manager for organizing todos with lists, reminders,
deadlines, and notes.

[![Build](https://github.com/Bia951/trig_todo/actions/workflows/build.yml/badge.svg)](https://github.com/Bia951/trig_todo/actions/workflows/build.yml)
[![Flutter](https://img.shields.io/badge/Flutter-Material%203-02569B?logo=flutter)](https://flutter.dev/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

[Download a release](https://github.com/Bia951/trig_todo/releases) · [Report a bug](https://github.com/Bia951/trig_todo/issues)

</div>

## Why Trig?

Trig keeps task planning focused. It gives each todo enough structure to be
useful—without turning a simple checklist into a project-management system.
Everything is stored on your device, with no account required.

## Features

- Create custom lists with their own names, icons, colors, and ordering.
- Organize tasks into **Important**, **Pending**, and **Completed** sections.
- Add descriptions, notes, reminder times, deadlines, and advance warnings.
- Search across titles, descriptions, notes, and scheduled dates.
- Star, mute, complete, reorder, or move tasks between lists.
- Select multiple tasks for batch completion or deletion, with undo support.
- Use a responsive interface designed for both compact and wide screens.
- Follow the system light or dark theme, including Material You colors on
  supported Android devices.
- Keep data locally using Isar and platform-native storage.

## Platform support

| Platform | App support | Scheduled notifications |
| --- | :---: | :---: |
| Android | ✅ | ✅ |
| iOS | ✅ | ✅ |
| macOS | ✅ | ✅ |
| Windows | ✅ | ✅ |
| Linux | ✅ | — |

Prebuilt packages for supported release targets are available from
[GitHub Releases](https://github.com/Bia951/trig_todo/releases).

## Getting started

### Prerequisites

- [Flutter](https://docs.flutter.dev/get-started/install) on the stable channel
- A configured toolchain for the platform you want to run

Check your environment before continuing:

```bash
flutter doctor
```

### Run locally

```bash
git clone https://github.com/Bia951/trig_todo.git
cd trig_todo
flutter pub get
flutter run
```

To choose a specific target, list the available devices and pass one to
`flutter run`:

```bash
flutter devices
flutter run -d macos
```

## Development

Run static analysis and the test suite before submitting changes:

```bash
flutter analyze
flutter test
```

Create a release build with the standard Flutter command for your target:

```bash
flutter build apk
flutter build macos
flutter build windows
flutter build linux
```

Some build commands require the corresponding host operating system and native
toolchain.

## How data is stored

Trig is local-first and currently has no account system or cloud sync.

- Native platforms store todos in an Isar database and list metadata in local
  JSON files.
- Reminder notifications are scheduled locally on supported platforms.

Removing the app or clearing its application data may permanently remove your
todos. Back up important information separately.

## Project structure

```text
lib/
├── models/          Todo and list data models
├── providers/       Application state and task operations
├── repositories/    Native and in-memory persistence
├── screens/         Responsive application screens
├── services/        Reminder and notification scheduling
├── theme/           Material 3 light and dark themes
└── widgets/         Reusable interface components
```

Trig uses
[Provider](https://pub.dev/packages/provider) for application state and
[Isar](https://isar.dev/) for native persistence.

## Contributing

Issues and pull requests are welcome. For larger changes, please open an issue
first so the approach can be discussed before implementation.

## License

Trig is available under the [MIT License](LICENSE).
