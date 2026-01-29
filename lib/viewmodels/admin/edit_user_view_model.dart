import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../repositories/user_repository.dart';
import '../../services/cloud_functions_service.dart';
import '../../services/avatar_helper.dart';
import '../../models/user_model.dart';

/// ViewModel for editing an existing user
class EditUserViewModel extends ChangeNotifier {
  final CloudFunctionsService _cloudFunctions;
  final AvatarHelper _avatarHelper;
  final UserRepository _userRepository;
  final UserModel user;

  // Form state
  String username;
  String name;
  String password = '';
  
  // Avatar state
  XFile? selectedAvatar;
  String? currentAvatarUrl;
  
  // Loading states
  bool _isUpdating = false;
  bool get isUpdating => _isUpdating;
  
  bool _isUploadingAvatar = false;
  bool get isUploadingAvatar => _isUploadingAvatar;
  
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  EditUserViewModel({
    required this.user,
    CloudFunctionsService? cloudFunctions,
    AvatarHelper? avatarHelper,
    UserRepository? userRepository,
  })  : _cloudFunctions = cloudFunctions ?? CloudFunctionsService(),
        _avatarHelper = avatarHelper ?? AvatarHelper(),
        _userRepository = userRepository ?? UserRepository(),
        username = user.username,
        name = user.name ?? '',
        currentAvatarUrl = user.role == UserRole.student ? user.avatarUrl : null;

  /// Pick an avatar image
  Future<void> pickAvatar() async {
    try {
      final pickedFile = await _avatarHelper.pickAvatar();
      if (pickedFile != null) {
        selectedAvatar = pickedFile;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Error picking avatar: $e';
      notifyListeners();
    }
  }

  /// Upload the selected avatar
  Future<void> uploadAvatar() async {
    if (selectedAvatar == null) return;

    _isUploadingAvatar = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final downloadUrl = await _avatarHelper.uploadAvatar(
        userId: user.uid,
        avatarFile: selectedAvatar!,
      );

      // Update Firestore via repository
      await _userRepository.updateAvatarUrl(user.uid, downloadUrl);

      currentAvatarUrl = downloadUrl;
      selectedAvatar = null;
      _isUploadingAvatar = false;
      notifyListeners();
    } catch (e) {
      _isUploadingAvatar = false;
      _errorMessage = 'Error uploading avatar: $e';
      notifyListeners();
    }
  }

  /// Update user information
  Future<bool> updateUser() async {
    _isUpdating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _cloudFunctions.updateUser(
        uid: user.uid,
        username: username.trim() != user.username ? username.trim() : null,
        name: name.trim() != user.name ? name.trim() : null,
        password: password.isNotEmpty ? password : null,
      );

      _isUpdating = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isUpdating = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
