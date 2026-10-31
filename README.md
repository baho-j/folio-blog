# Folio

Folio is an offline blogging client built with Google Flutter for Android and iOS. Each post holds a title, a date of entry, a main body of text and an optional image, and every post is stored on the device, so the application works in full without a network connection.

## Features

- Create, view, edit and delete posts, with validation and a prompt before unsaved changes are discarded
- Browse every post, newest first, with a thumbnail, title, date and excerpt
- Search the title and body of all posts, with matches highlighted
- Select a group of posts with a long press and delete them together
- Attach a photo from the camera or the gallery, and replace or remove it later
- Recover a photo if Android ends the application while the camera is open
- Light and dark themes that follow the device

## Building

The project rebuilds on a standard Android Studio installation with the Flutter and Dart plugins, using Flutter 3.47 or later on the stable channel.

```bash
flutter pub get
flutter run
```

Building for iOS requires macOS and Xcode.

## Testing

Unit and widget tests run on the host, and integration tests run on a connected device against the real database.

```bash
flutter test
```

```bash
flutter test integration_test/app_test.dart
```

## Third-party code

The application depends on four packages, each identified in a comment at its import and justified in `docs/DECISIONS.md`.

| Package | Licence | Purpose | Justified in `docs/DECISIONS.md` under |
|---|---|---|---|
| `sqflite` | BSD-2-Clause | SQLite database | SQLite through sqflite for storage |
| `image_picker` | BSD-3-Clause | Camera and gallery | image_picker for camera and gallery |
| `path_provider` | BSD-3-Clause | Documents directory | path_provider and path for file locations |
| `path` | BSD-3-Clause | File path handling | path_provider and path for file locations |

## Documentation

| Document | Contents |
|---|---|
| `ARCHITECTURE.md` | Structure, layers, storage, screen flow and project plan |
| `docs/SPECIFICATION.md` | Functional and non-functional requirements, each with its acceptance check |
| `docs/DESIGN.md` | UML class and sequence diagrams, flow charts and the database schema |
| `docs/TESTING.md` | Test cases mapped to each requirement, with the recorded results |
| `docs/DECISIONS.md` | Major development decisions and the issues met during development |
