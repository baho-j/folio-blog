# Software functional specification

This specification turns the user requirements for the Folio offline blogging client into functional and non-functional requirements, and pairs each functional requirement with the check that shows it has been met. Each requirement notes which of the user requirements in section 2 it comes from, and `docs/TESTING.md` follows the same order, so that each test result can be read against the need it proves.

## 1. Purpose and scope

Folio allows a single user to write and keep a personal blog on an Android or iOS phone. Each blog item, referred to in this document as a post, holds a title, a date of entry, a main body of text and an optional image. The application stores posts in a database on the device and performs every function without a network connection. Publishing to a remote server, user accounts and synchronisation between devices are outside the scope of this version.

## 2. User requirements

The user requirements for the application are as follows.

1. Accept text input for a blog item.
2. Manage blog items on the device.
3. Create, edit, view and delete blog items.
4. View individual blog items.
5. View the current list of blog items.
6. Search for text within the blog items and display either the first matching item or a list of matching items.
7. Delete a single blog item.
8. Select and delete a group of chosen blog items.
9. Each blog item has a title, a date of entry, a main body text and an image.
10. Store the blog items in a file or database on the device.
11. Attach a photo or image to a blog item from the photo gallery and the camera.
12. All functionality works offline.
13. Implemented with Google Flutter.
14. Code portable between Android and iOS.

## 3. Data definition

| Field | Type | Rules |
|---|---|---|
| Title | Text | Required, leading and trailing spaces removed, at most 120 characters |
| Date of entry | Date | Required, defaults to the current day, chosen with a date picker, cannot be later than the current day |
| Body | Text | Required, multi-line, no fixed limit |
| Image | Image file | Optional, taken with the camera or chosen from the gallery, one per post |

The image is optional so that a user can write a post before choosing a photo, or keep a post that has no picture. The field is present on every post and can be added, replaced or removed at any time.

## 4. Functional requirements

Each functional requirement is followed by the check used to accept it.

1. **Create a post.** The user can create a new post by entering a title, a date of entry and a body, and optionally attaching an image.
    - Check: A post saved with a title, date and body appears at the correct position in the list immediately.
    - Comes from user requirements 1, 3 and 9.
2. **Validate before saving.** The application validates the post before saving and shows a message beside any field that breaks the rules in section 3.
    - Check: Saving with an empty title or body shows an error on that field and does not save. A future date cannot be chosen.
    - Comes from user requirements 1 and 9.
3. **List the posts.** The application shows the list of all posts, newest date of entry first, each with its title, date, a short excerpt and a thumbnail when an image is attached.
    - Check: The list shows every stored post in descending order of date of entry. An empty collection shows an empty state with a button to write the first post.
    - Comes from user requirements 2 and 5.
4. **View a post.** The user can open any post from the list to view its full title, date, body and image.
    - Check: The detail screen shows exactly the stored title, date, body and image.
    - Comes from user requirement 4.
5. **Edit a post.** The user can edit every field of an existing post, and the changes are saved only when the user confirms.
    - Check: After editing and saving, the detail screen and the list both show the new values. Cancelling leaves the post unchanged.
    - Comes from user requirement 3.
6. **Delete a single post.** The user can delete a single post from its detail screen after confirming the action.
    - Check: After confirming, the post no longer appears in the list or in search results.
    - Comes from user requirements 3 and 7.
7. **Delete a group of posts.** The user can enter selection mode from the list, select any number of posts, select all posts, and delete the selected posts in one action after confirming.
    - Check: A long press on a post starts selection mode with that post selected. The app bar shows the number selected. Confirming deletes exactly the selected posts.
    - Comes from user requirement 8.
8. **Search.** The user can search the title and body of all posts. When one post matches, the application opens it. When several match, the application lists them with the matching text highlighted. When none match, the application says so.
    - Check: Searching for text found only in one post opens that post. Text found in several posts lists them all. Search ignores letter case, and the characters `%` and `_` are matched literally.
    - Comes from user requirement 6.
9. **Attach from the gallery.** The user can attach an image to a post from the photo gallery.
    - Check: An image chosen from the gallery or taken with the camera appears in the editor preview and is shown on the saved post.
    - Comes from user requirement 11.
10. **Attach from the camera.** The user can attach an image to a post by taking a photo with the camera.
    - Check: An image chosen from the gallery or taken with the camera appears in the editor preview and is shown on the saved post.
    - Comes from user requirement 11.
11. **Replace or remove an image.** The user can replace or remove the image attached to a post.
    - Check: Replacing an image shows the new one after saving. Removing an image leaves the post without one.
    - Comes from user requirements 3 and 11.
12. **Keep posts on the device.** Posts and their images are stored on the device and remain available after the application is closed, the device is restarted, or the application is updated.
    - Check: All posts and images are present after force-closing the application and after restarting the device.
    - Comes from user requirement 10.
13. **Delete images with their posts.** Deleting a post also deletes its image file from the device.
    - Check: After deleting a post with an image, its file is absent from the images folder.
    - Comes from user requirements 2 and 10.
14. **Protect unsaved changes.** When the user leaves the editor with unsaved changes, the application asks whether to discard them.
    - Check: Pressing back with unsaved changes shows a discard dialog. Pressing back with no changes closes the editor directly.
    - Comes from user requirement 3.

## 5. Non-functional requirements

1. **Work offline.** Every function in section 4 works with the device in airplane mode, and the release build does not request network access.
    - Comes from user requirement 12.
2. **Run on Android and iOS.** The application is built with Flutter from a single code base and runs on Android 7.0 (API 24) and later and on iOS 13 and later.
    - Comes from user requirements 13 and 14.
3. **Rebuild cleanly.** The project rebuilds without errors on a standard Android Studio installation, using only the dependencies declared in `pubspec.yaml`.
    - Comes from user requirement 13.
4. **Respond quickly.** The list and search results respond within 300 milliseconds for a collection of 500 posts.
    - Comes from user requirements 5 and 6.
5. **Save atomically.** Saving a post is atomic, so a failure part way through never leaves a post without its image file or an image file without its post.
    - Comes from user requirement 10.
6. **Stay readable and usable.** The interface supports light and dark themes, follows the device text size setting, and keeps touch targets at least 48 by 48 logical pixels.
    - Comes from user requirement 2.
7. **Confirm destructive actions.** Every destructive action asks for confirmation and states how many posts it affects.
    - Comes from user requirements 7 and 8.
