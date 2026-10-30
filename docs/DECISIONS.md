# Development decisions and issues

This document records the major decisions taken while building Folio, the alternatives that were considered, and the reasons for each choice, followed by the significant issues met during development and how each was resolved.

## Decisions

### SQLite through sqflite for storage

The requirements allow posts to be stored in either a file or a database. A single JSON file was considered, since it needs no plugin, but every change would rewrite the whole file, a crash during that write could corrupt the entire collection, and search would require loading every post into memory. SQLite offers transactions, an index on the date of entry and `LIKE` queries in the database itself, so it was chosen, accessed through the `sqflite` plugin, which is the standard maintained way of using SQLite from Flutter on both Android and iOS.

### Image files stored by name outside the database

Images could have been stored as binary data inside the database, but large rows slow down every query that reads the table, including the list. They are therefore kept as files in an `images/` folder in the application's documents directory, and the database holds only the file name. Only the name is stored, rather than the full path, because on iOS the absolute path of an application's container can change between installations and updates, which would break any stored full path.

### image_picker for camera and gallery

Writing native camera and photo library code in Kotlin for Android and Swift for iOS was considered, as it would avoid a plugin, but it would roughly double the amount of platform code, require separate handling of permissions and activity results on each platform, and offer no benefit to the user. The `image_picker` plugin provides both sources through one interface, works without a network, and was chosen for that reason. Photos are limited to 1600 pixels on the longer edge at a quality of 85, which keeps typical files under one megabyte.

### ChangeNotifier for state management

Packages such as `provider`, `riverpod` and `bloc` were considered. The application has one shared collection, one selection set and four screens, which `ChangeNotifier` and `ListenableBuilder` from the Flutter SDK handle directly, so no state management package was added and the dependency list stays limited to what the features require.

### LIKE queries instead of full-text search

SQLite's FTS5 extension provides ranked full-text search, but it is not guaranteed to be compiled into the system SQLite on older Android versions, which would make search fail on some devices. A case-insensitive `LIKE` query over the title and body works on every supported device and is fast enough for the size of a personal blog. The characters `%`, `_` and the escape character itself are escaped so that they are matched as typed. SQLite folds case for ASCII letters only, so a search for a word with accented capitals will not match its lower-case form, which suits a personal blog written mainly in English.

### Image is optional on a post

The requirements list the image as one of the fields of a blog item. Making it mandatory would stop a user from saving a post until a photo is available, so the field exists on every post but may be empty, and it can be added, replaced or removed at any time.

### Date of entry chosen by the user

The date of entry is treated as content the user writes, so the editor provides a date picker that defaults to the current day. It is stored separately from the creation and update times, which the application records automatically and does not show for editing.

### No network permission in the release build

The main Android manifest does not declare the `INTERNET` permission. Flutter adds it only to the debug and profile manifests for development tools, so the release build is unable to use the network and the offline requirement is enforced by the platform as well as by the code.

### path_provider and path for file locations

The documents directory is in a different place on each platform and can only be found through native code, so `path_provider` is needed to locate it, while `path` joins file names safely and extracts extensions on both platforms. Both are small, maintained packages from the Dart and Flutter teams, `path` was already required by `sqflite`, and writing either by hand would add risk without adding any function the user could notice.

### Picked photos are copied when the post is saved

Copying a photo into the `images/` folder as soon as it was picked was considered, since the temporary file may be cleared by the operating system. That approach would leave an unused file behind every time a user changed their mind or discarded a draft, and would need a separate clean-up step. The editor therefore holds the temporary path for the short time the draft is open, and the repository copies the file as the first step of saving, before the database row is written, which keeps the rule that no file exists without a post and no post points at a missing file.

### Camera and gallery access behind PostStore

The screens could have called `image_picker` directly, but that would have given them a second dependency beside `PostStore` and made the editor impossible to test without a device. `PhotoPicker` in `lib/data/` wraps the plugin, and `PostStore` exposes it to the screens, so the widget tests can substitute a fake picker and exercise every path through attachment, including cancellation and refused permissions.

## Issues and resolutions

### Photos lost when Android ends the application during camera capture

On devices with little free memory, Android may end the application while the camera application is in the foreground, and the captured photo is then not returned in the usual way. Because the application restarts on the post list rather than in the editor, a check inside the editor would only run if the user happened to open it, so the post list calls `retrieveLostData` from `image_picker` at every start and, when a photo is returned, opens a new draft holding it. The text of the interrupted draft cannot be recovered, since it existed only in memory, but the picture is kept. The behaviour is tested by enabling the Android developer option "Don't keep activities", which ends the application as soon as the camera opens, and the result is recorded in `docs/TESTING.md`.

### Temporary files returned by the picker

The file returned by `image_picker` lives in a temporary or cache folder that the operating system may clear at any time, which would leave posts without their images. `ImageStore` copies every picked image into the application's own `images/` folder under a generated name before the post is saved, and the post refers only to that copy.

### Orphaned image files

Replacing or deleting images could leave unused files behind if the old file were deleted before the database write succeeded, or never deleted at all. The save and delete operations are ordered so that new files are copied first, database changes run in a transaction, and old files are removed only after the transaction commits, as shown in the sequence diagrams in `docs/DESIGN.md`.

### Minimum iOS version raised to 15

The specification first named iOS 13 as the oldest supported version, but the project created by the current Flutter release sets a deployment target of iOS 15, because the framework no longer supports anything older. The specification was corrected to match, since a stated minimum that the toolchain cannot build for would be a promise the project could not keep.
