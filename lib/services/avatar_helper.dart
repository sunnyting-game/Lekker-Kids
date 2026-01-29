import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Service to handle avatar picking, cropping, and uploading
class AvatarHelper {
  final ImagePicker _picker;
  final FirebaseStorage _storage;

  AvatarHelper({
    ImagePicker? picker,
    FirebaseStorage? storage,
  })  : _picker = picker ?? ImagePicker(),
        _storage = storage ?? FirebaseStorage.instance;

  /// Pick and optionally crop an avatar image
  /// Returns the selected/cropped XFile or null if cancelled
  Future<XFile?> pickAvatar() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 90,
    );

    if (image == null) return null;

    // For web, skip cropper due to initialization issues
    // Just use the selected image directly (it will display as circular)
    if (kIsWeb) {
      return image;
    }

    // For mobile, use cropper with square aspect ratio
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: image.path,
      compressQuality: 90,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Avatar',
          aspectRatioPresets: [
            CropAspectRatioPreset.square,
          ],
        ),
        IOSUiSettings(
          title: 'Crop Avatar',
          aspectRatioPresets: [
            CropAspectRatioPreset.square,
          ],
        ),
      ],
    );

    if (croppedFile != null) {
      return XFile(croppedFile.path);
    }

    return null;
  }

  /// Upload avatar to Firebase Storage and return download URL
  /// [userId] - The user ID to use for the avatar filename
  /// [avatarFile] - The XFile containing the avatar image
  Future<String> uploadAvatar({
    required String userId,
    required XFile avatarFile,
  }) async {
    final storageRef = _storage
        .ref()
        .child('avatars')
        .child('$userId.jpg');

    // Read file bytes for web compatibility
    final bytes = await avatarFile.readAsBytes();
    await storageRef.putData(bytes);
    return await storageRef.getDownloadURL();
  }
}
