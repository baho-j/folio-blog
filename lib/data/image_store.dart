import 'dart:io';

// Third-party: path (BSD-3-Clause), joins file paths the same way on both platforms
import 'package:path/path.dart' as p;
// Third-party: path_provider (BSD-3-Clause), locates the documents directory on each platform
import 'package:path_provider/path_provider.dart';

/// Keeps post images as files in the application's own images folder.
class ImageStore {
  /// Creates a store that keeps its files in [folder].
  ImageStore(this.folder);

  /// Name of the images folder in the documents directory.
  static const String folderName = 'images';

  /// Opens the store in the documents directory.
  static Future<ImageStore> open() async {
    final documents = await getApplicationDocumentsDirectory();
    return ImageStore(Directory(p.join(documents.path, folderName)));
  }

  /// Folder that holds the image files.
  final Directory folder;

  int _sequence = 0;

  /// Copies the file at [sourcePath] into the folder and returns its new name.
  Future<String> import(String sourcePath) async {
    await folder.create(recursive: true);
    final extension = p.extension(sourcePath).toLowerCase();
    final name = '${DateTime.now().microsecondsSinceEpoch}_${_sequence++}$extension';
    try {
      await File(sourcePath).copy(fileFor(name).path);
    } on FileSystemException {
      await delete(name);
      rethrow;
    }
    return name;
  }

  /// Returns the file for the stored image called [name].
  File fileFor(String name) => File(p.join(folder.path, name));

  /// Deletes the stored image called [name] if it exists.
  Future<void> delete(String name) async {
    final file = fileFor(name);
    if (await file.exists()) await file.delete();
  }
}
