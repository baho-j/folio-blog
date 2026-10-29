# Software design document

This document describes the design of the Folio offline blogging client using UML class and sequence diagrams, a state diagram, flow charts and the database schema. It builds on the layered structure set out in `ARCHITECTURE.md` and realises the requirements in `docs/SPECIFICATION.md`.

## 1. Design approach

The design follows a layered architecture with a single direction of dependency, from the screens to a state object, from the state object to a repository interface, and from the repository to the database and the file system. Each layer can be understood and tested without the layers above it, and the repository interface means the screens can be exercised against an in-memory implementation without a device.

## 2. Class diagram

```mermaid
classDiagram
    class Post {
        +int? id
        +String title
        +String body
        +DateTime entryDate
        +String? imageName
        +DateTime createdAt
        +DateTime updatedAt
        +copyWith() Post
        +toRow() Map
        +fromRow(Map) Post
    }

    class PostRepository {
        <<interface>>
        +all() List~Post~
        +find(int id) Post?
        +save(Post post, String? pickedImagePath) Post
        +deleteMany(Set~int~ ids)
        +search(String text) List~Post~
        +imageFile(String name) File
    }

    class SqlitePostRepository {
        -Database db
        -ImageStore images
    }

    class PhotoPicker {
        +pick(bool fromCamera) String?
    }

    class BlogDatabase {
        +open() Database
        -onCreate(Database db, int version)
    }

    class ImageStore {
        -Directory folder
        +import(String sourcePath) String
        +fileFor(String name) File
        +delete(String name)
    }

    class PostStore {
        <<ChangeNotifier>>
        -PostRepository repository
        -PhotoPicker photos
        +List~Post~ posts
        +Set~int~ selected
        +bool selecting
        +load()
        +save(Post post, String? pickedImagePath)
        +delete(int id)
        +deleteSelected()
        +toggle(int id)
        +selectAll()
        +clearSelection()
        +search(String text) List~Post~
        +imageOf(Post post) File?
        +pickPhoto(bool fromCamera) String?
    }

    PostRepository <|.. SqlitePostRepository
    SqlitePostRepository --> BlogDatabase
    SqlitePostRepository --> ImageStore
    PostStore --> PostRepository
    PostStore --> PhotoPicker
    PostStore ..> Post
    PostRepository ..> Post
```

`Post` is an immutable value class, and every change produces a new instance through `copyWith`, which keeps the editor's draft separate from the stored post until the user saves. `PostStore` is the only object the screens depend on, and it notifies its listeners whenever the list, the selection or the loading state changes, so every screen that shows posts stays consistent without manual refreshing.

## 3. Database schema

```sql
CREATE TABLE posts (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  title       TEXT    NOT NULL,
  body        TEXT    NOT NULL,
  entry_date  INTEGER NOT NULL,
  image_name  TEXT,
  created_at  INTEGER NOT NULL,
  updated_at  INTEGER NOT NULL
);

CREATE INDEX idx_posts_entry_date ON posts (entry_date DESC);
```

Dates are stored as milliseconds since the Unix epoch, which sort correctly as integers and avoid any dependence on locale or time zone formatting in the database. The schema version is recorded through SQLite's `user_version`, so a later change to the table can be applied as a migration in `onUpgrade` without losing existing posts.

## 4. Sequence diagrams

### 4.1 Saving a post with a new image

```mermaid
sequenceDiagram
    actor User
    participant Editor as PostEditorScreen
    participant Store as PostStore
    participant Repo as SqlitePostRepository
    participant Images as ImageStore
    participant DB as SQLite

    User->>Editor: Tap Save
    Editor->>Editor: Validate fields
    Editor->>Store: save(draft, pickedImagePath)
    Store->>Repo: save(draft, pickedImagePath)
    Repo->>Images: import(pickedImagePath)
    Images-->>Repo: new image name
    Repo->>DB: INSERT or UPDATE in transaction
    DB-->>Repo: id
    Repo->>Images: delete(previous image name)
    Repo-->>Store: saved Post
    Store->>Store: Update list, notify listeners
    Store-->>Editor: saved Post
    Editor-->>User: Return to the previous screen
```

The new image is copied into the application's folder before the database row is written, and the previous image is deleted only after the row has been saved. If the database write fails, the newly copied file is deleted and the stored post is left exactly as it was, so a failure never leaves a post pointing at a missing file.

### 4.2 Deleting a group of posts

```mermaid
sequenceDiagram
    actor User
    participant List as PostListScreen
    participant Store as PostStore
    participant Repo as SqlitePostRepository
    participant Images as ImageStore
    participant DB as SQLite

    User->>List: Long press a post
    List->>Store: toggle(id)
    User->>List: Select more posts, tap Delete
    List->>User: Confirm deletion of n posts
    User->>List: Confirm
    List->>Store: deleteSelected()
    Store->>Repo: deleteMany(selected ids)
    Repo->>DB: SELECT image_name WHERE id IN (...)
    Repo->>DB: DELETE WHERE id IN (...) in transaction
    Repo->>Images: delete(each image name)
    Store->>Store: Remove from list, clear selection, notify
    List-->>User: Show "n posts deleted"
```

The image names are read before the rows are removed, and the files are deleted only after the transaction commits, so a failed deletion leaves both the posts and their images intact.

### 4.3 Searching

```mermaid
sequenceDiagram
    actor User
    participant Search as SearchScreen
    participant Store as PostStore
    participant Repo as SqlitePostRepository
    participant DB as SQLite

    User->>Search: Type text
    Search->>Search: Wait 250 ms after last keystroke
    Search->>Store: search(text)
    Store->>Repo: search(text)
    Repo->>DB: SELECT ... WHERE title LIKE ? ESCAPE '\' OR body LIKE ? ESCAPE '\'
    DB-->>Repo: matching rows
    Repo-->>Store: List of Post
    Store-->>Search: results
    alt exactly one result and user submitted
        Search->>User: Open post detail
    else several results
        Search->>User: Show list with highlighted matches
    else no results
        Search->>User: Show "No posts match"
    end
```

The short pause after the last keystroke keeps the screen responsive while the user is still typing, and opening a single match only when the user submits the search avoids the screen changing unexpectedly in the middle of typing.

## 5. State diagram of the post list

```mermaid
stateDiagram-v2
    [*] --> Loading
    Loading --> Empty: no posts
    Loading --> Browsing: posts loaded
    Empty --> Browsing: first post saved
    Browsing --> Selecting: long press
    Selecting --> Selecting: tap toggles a post
    Selecting --> Browsing: back or last post deselected
    Selecting --> Browsing: delete confirmed
    Browsing --> Empty: last post deleted
```

## 6. Flow chart for attaching an image

```mermaid
flowchart TD
    A[Tap image area in editor] --> B{Choose source}
    B -->|Camera| C[Open camera]
    B -->|Gallery| D[Open photo gallery]
    B -->|Remove| R[Clear image from draft]
    C --> E{Photo returned?}
    D --> E
    E -->|No, cancelled| F[Keep current image]
    E -->|Yes| G[Show preview in draft]
    G --> H{User saves?}
    H -->|Yes| I[Copy into app images folder and save post]
    H -->|No, discards| J[Leave stored post unchanged]
    C -.->|Android ended the app while camera was open| K[On return, retrieve lost photo and restore draft]
    K --> G
```

## 7. Screen design

| Screen | Layout | Actions |
|---|---|---|
| Post list | App bar with title and search action. Scrolling list of posts, each a row with a 64 pixel square thumbnail, title, date and two lines of excerpt. A floating button to write a new post | Tap opens a post. Long press starts selection mode. In selection mode the app bar shows the count, select all and delete |
| Post detail | Full-width image when present, followed by date, title and body in a readable column | Edit and delete in the app bar |
| Editor | Image area at the top showing the preview or a prompt to add a photo, then title field, date field that opens a date picker, and a multi-line body field | Save in the app bar. Tapping the image area opens a sheet with Camera, Gallery and Remove |
| Search | Search field in the app bar with focus on open, results below with the matching text highlighted | Tap a result to open it. Submitting with one result opens it directly |

The visual language is flat, with solid surfaces, a single accent colour, no gradients, and type sized for comfortable reading of longer posts. Empty states use a short message and a single action, and confirmation dialogs name the number of posts affected.
