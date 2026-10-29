import 'package:folio/data/photo_picker.dart';

/// Photo picker that returns a prepared path instead of opening the platform picker.
class FakePhotoPicker implements PhotoPicker {
  /// The path the next pick returns, where null means the user cancelled.
  String? nextPath = 'picked.jpg';

  /// Set to make the next pick fail, as a refused permission does.
  bool failing = false;

  /// The photo recovered at the next start, as after Android ended the application.
  String? lostPath;

  /// Whether the last pick asked for the camera.
  bool? usedCamera;

  @override
  Future<String?> pick({required bool fromCamera}) async {
    usedCamera = fromCamera;
    if (failing) throw Exception('camera unavailable');
    return nextPath;
  }

  @override
  Future<String?> recoverLost() async => lostPath;
}
