// Third-party: image_picker (BSD-3-Clause), opens the camera and the photo gallery
import 'package:image_picker/image_picker.dart';

/// Obtains photos from the camera and the gallery as temporary files.
class PhotoPicker {
  static const double _longestEdge = 1600;
  static const int _quality = 85;

  final ImagePicker _picker = ImagePicker();

  /// Returns the path of the chosen photo, or null if the user cancelled.
  Future<String?> pick({required bool fromCamera}) async {
    final file = await _picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: _longestEdge,
      maxHeight: _longestEdge,
      imageQuality: _quality,
    );
    return file?.path;
  }
}
