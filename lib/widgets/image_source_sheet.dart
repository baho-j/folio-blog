import 'package:flutter/material.dart';

/// What the user chose to do with the image of a post.
enum ImageAction {
  /// Take a new photo with the camera.
  camera,

  /// Choose an existing photo from the gallery.
  gallery,
}

/// Asks where a photo should come from.
Future<ImageAction?> showImageSourceSheet(BuildContext context) {
  return showModalBottomSheet<ImageAction>(
    context: context,
    builder: (_) => const ImageSourceSheet(),
  );
}

/// Bottom sheet listing the image actions.
class ImageSourceSheet extends StatelessWidget {
  /// Creates the sheet.
  const ImageSourceSheet({super.key});

  @override
  Widget build(BuildContext context) {
    void choose(ImageAction action) => Navigator.of(context).pop(action);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Take a photo'),
            onTap: () => choose(ImageAction.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Choose from gallery'),
            onTap: () => choose(ImageAction.gallery),
          ),
        ],
      ),
    );
  }
}
