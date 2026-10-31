# Test plan and results

This document records how Folio was tested and what was observed, and it follows the order of the requirements in `docs/SPECIFICATION.md`, so that each result can be read against the need it proves. Automated results come from the test runner's own output, and manual results are stated as the tester reported them.

## 1. Approach

Testing was carried out at three levels, because each one answers a different question. Unit and widget tests run on the host with an in-memory repository, which makes them fast and deterministic and allows every path through the screens to be covered, including failures that are hard to provoke on a device. Integration tests run on a phone against the real SQLite database and file system, and they apply the same repository contract that the in-memory implementation passes, which is what justifies trusting the host results for the real storage layer. Manual tests cover what no automated test can reach, namely the camera, the gallery, airplane mode, restarts and the system theme.

## 2. Environment

| Item | Value |
|---|---|
| Flutter | 3.47.9, stable channel |
| Host | Windows 11 |
| Android SDK | 36.0.0 |
| Test device | A001 phone, Android 16 (API 36) |
| iOS | Not available, see section 6 |

## 3. Automated results

| File | Level | Tests | Passed |
|---|---|---|---|
| `test/post_test.dart` | Unit | 13 | 13 |
| `test/date_text_test.dart` | Unit | 4 | 4 |
| `test/search_query_test.dart` | Unit | 14 | 14 |
| `test/image_store_test.dart` | Unit | 6 | 6 |
| `test/post_repository_test.dart` | Unit | 22 | 22 |
| `test/post_store_test.dart` | Unit | 11 | 11 |
| `test/app_test.dart` | Widget | 3 | 3 |
| `test/post_list_screen_test.dart` | Widget | 7 | 7 |
| `test/post_detail_screen_test.dart` | Widget | 5 | 5 |
| `test/post_editor_screen_test.dart` | Widget | 10 | 10 |
| `test/image_attachment_test.dart` | Widget | 13 | 13 |
| `test/search_screen_test.dart` | Widget | 10 | 10 |
| `test/selection_mode_test.dart` | Widget | 10 | 10 |
| `test/accessibility_test.dart` | Widget | 11 | 11 |
| `integration_test/app_test.dart`, repository group | Integration | 25 | 25 |
| `integration_test/app_test.dart`, user flows | Integration | 5 | 5 |
| | **Total** | **169** | **169** |

The full output of the runs behind this table is kept in `docs/test-output/unit-and-widget.txt` and `docs/test-output/integration.txt`, exactly as the test runner produced it. `flutter analyze` reported no issues. The integration run measured 18 milliseconds to list 500 posts and 1 millisecond to search them, both far inside the limit of 300 milliseconds, which suggests that the indexed `LIKE` approach leaves ample room for a personal collection.

## 4. Manual results

The tester carried out these checks on the A001 phone with the release build and reported that all of them worked as expected, confirming the dark theme specifically.

| Check | Reported result |
|---|---|
| Create a post with a camera photo and find it in the editor, the list and the post | Worked as expected |
| Create a post with a gallery photo and find it in the same three places | Worked as expected |
| Replace the photo of one post and remove the photo of another | Worked as expected |
| In airplane mode, create, edit, search, and delete one post and a group of posts | Worked as expected |
| Force-close and reopen the application, then restart the phone, and confirm that posts and images remain | Worked as expected |
| With "Don't keep activities" enabled, take a photo from the editor and confirm that a new draft opens holding it | Worked as expected |
| Review the light and dark themes and a large system text size | Worked as expected |

Inspection of the release package with `aapt` showed that it does not request the `INTERNET` permission, which confirms by a separate route what the airplane mode check showed in use.

## 5. Requirement coverage

### Functional requirements

| Requirement | Evidence | Result |
|---|---|---|
| Create a post | Editor widget tests, user flow integration tests, camera and gallery checks | Pass |
| Validate before saving | Model unit tests, editor widget tests | Pass |
| List the posts | Repository unit and integration tests, list widget tests | Pass |
| View a post | Detail widget tests | Pass |
| Edit a post | Editor widget tests, user flow integration tests | Pass |
| Delete a single post | Detail widget tests, user flow integration tests | Pass |
| Delete a group of posts | Store unit tests, selection widget tests, user flow integration tests | Pass |
| Search | Search query and repository unit tests, repository integration tests, search widget tests, user flow integration tests | Pass |
| Attach from the gallery | Image attachment widget tests, gallery check | Pass |
| Attach from the camera | Image attachment widget tests, camera check | Pass |
| Replace or remove an image | Repository unit and integration tests, image attachment widget tests, replace and remove check | Pass |
| Keep posts on the device | Repository and user flow integration tests, restart check | Pass |
| Delete images with their posts | Repository unit and integration tests, user flow integration tests | Pass |
| Protect unsaved changes | Editor and image attachment widget tests | Pass |

### Non-functional requirements

| Requirement | Evidence | Result |
|---|---|---|
| Work offline | Airplane mode check, release package inspection | Pass on Android |
| Run on Android and iOS | User flow integration tests, all manual checks | Partly verified, see section 6 |
| Rebuild cleanly | Debug and release packages built with `flutter build apk` | Pass on Android |
| Respond quickly | Repository integration tests | Pass, 18 and 1 milliseconds |
| Save atomically | Image store unit tests, repository integration tests | Pass |
| Stay readable and usable | Accessibility widget tests, theme and text size check | Pass |
| Confirm destructive actions | Detail and selection widget tests, user flow integration tests | Pass |

## 6. Limits of this testing

The application has not been built or run on iOS, because that requires macOS and Xcode and the work was done on Windows, so the portability of the code rests on Flutter's single code base and on the iOS usage descriptions being in place rather than on observation. On Android it ran on one phone at API 36, and although the minimum version is set to API 24, no older device was tried. Only the failure of a new post's insertion was forced in the atomic save test, since a failed update follows the same path through the code.

Two earlier integration runs logged a warning that a tap in the edit flow may have landed away from its target, although those tests passed and confirmed the edit in the database, and the recorded run logged no such warning. One other run failed the edit flow at the very end, with the message that a `SemanticsHandle` was still active after the test had finished, while every step of the test itself had succeeded. The same test passed in the recorded run and in the two earlier runs, the phone had no accessibility service enabled, and the cause was not established, so that test may be intermittent on this device.

## 7. Issues found during testing

The first integration run failed one of 30 tests, and the cause lay in the test rather than the application, as described under "Restart test kept the old screen state" in `docs/DECISIONS.md`. No defect in the application was found by the integration or manual tests.
