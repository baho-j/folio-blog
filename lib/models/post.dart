import 'package:flutter/foundation.dart';

/// A blog item, held as an immutable value.
@immutable
class Post {
  /// Creates a post from all of its fields.
  const Post({
    this.id,
    required this.title,
    required this.body,
    required this.entryDate,
    this.imageName,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates an empty, unsaved post dated [now].
  factory Post.draft(DateTime now) =>
      Post(title: '', body: '', entryDate: dateOnly(now), createdAt: now, updatedAt: now);

  /// Rebuilds a post from a database row.
  factory Post.fromRow(Map<String, Object?> row) => Post(
    id: row['id'] as int?,
    title: row['title'] as String,
    body: row['body'] as String,
    entryDate: DateTime.fromMillisecondsSinceEpoch(row['entry_date'] as int),
    imageName: row['image_name'] as String?,
    createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(row['updated_at'] as int),
  );

  /// The longest title the application accepts.
  static const int maxTitleLength = 120;

  /// Database key, or null until the post has been saved.
  final int? id;

  /// Title shown in the list and at the top of the post.
  final String title;

  /// Main text of the post.
  final String body;

  /// Chosen by the user, unlike [createdAt] and [updatedAt].
  final DateTime entryDate;

  /// File name only, never a path, because absolute paths change on iOS.
  final String? imageName;

  /// Moment the post was first saved.
  final DateTime createdAt;

  /// Moment the post was last changed.
  final DateTime updatedAt;

  /// A null [imageName] keeps the current image, so [clearImage] removes it.
  Post copyWith({
    int? id,
    String? title,
    String? body,
    DateTime? entryDate,
    String? imageName,
    bool clearImage = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Post(
    id: id ?? this.id,
    title: title ?? this.title,
    body: body ?? this.body,
    entryDate: entryDate ?? this.entryDate,
    imageName: clearImage ? null : imageName ?? this.imageName,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  /// Converts the post to a database row, leaving out an unassigned id.
  Map<String, Object?> toRow() => {
    if (id != null) 'id': id,
    'title': title,
    'body': body,
    'entry_date': entryDate.millisecondsSinceEpoch,
    'image_name': imageName,
    'created_at': createdAt.millisecondsSinceEpoch,
    'updated_at': updatedAt.millisecondsSinceEpoch,
  };

  /// Returns the error message for [value] as a title, or null if it is valid.
  static String? validateTitle(String? value) {
    final title = value?.trim() ?? '';
    if (title.isEmpty) return 'Enter a title';
    if (title.length > maxTitleLength) {
      return 'Use $maxTitleLength characters or fewer';
    }
    return null;
  }

  /// Returns the error message for [value] as a body, or null if it is valid.
  static String? validateBody(String? value) =>
      (value?.trim() ?? '').isEmpty ? 'Write something for this post' : null;

  /// Returns the calendar day of [moment], with the time removed.
  static DateTime dateOnly(DateTime moment) => DateTime(moment.year, moment.month, moment.day);

  @override
  bool operator ==(Object other) =>
      other is Post &&
      other.id == id &&
      other.title == title &&
      other.body == body &&
      other.entryDate == entryDate &&
      other.imageName == imageName &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(id, title, body, entryDate, imageName, createdAt, updatedAt);
}
