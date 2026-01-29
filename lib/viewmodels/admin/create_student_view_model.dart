import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../repositories/user_repository.dart';
import '../../services/cloud_functions_service.dart';
import '../../services/avatar_helper.dart';
import '../../models/user_model.dart';

/// ViewModel for creating a new student
class CreateStudentViewModel extends ChangeNotifier {
  final CloudFunctionsService _cloudFunctions;
  final AvatarHelper _avatarHelper;
  final UserRepository _userRepository;

  // Form state
  String username = '';
  String name = '';
  String password = '';
  String? organizationId;
  
  // Avatar state
  XFile? selectedAvatar;
  
  // Loading states
  bool _isCreating = false;
  bool get isCreating => _isCreating;
  
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  CreateStudentViewModel({
    CloudFunctionsService? cloudFunctions,
    AvatarHelper? avatarHelper,
    UserRepository? userRepository,
  })  : _cloudFunctions = cloudFunctions ?? CloudFunctionsService(),
        _avatarHelper = avatarHelper ?? AvatarHelper(),
        _userRepository = userRepository ?? UserRepository();

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

  /// Create a new student with the provided form data
  Future<UserModel?> createStudent() async {
    _isCreating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Create user via Cloud Function
      final user = await _cloudFunctions.createUser(
        username: username.trim(),
        password: password,
        name: name.trim(),
        role: UserRole.student,
        organizationId: organizationId,
      );

      // Upload avatar if selected
      if (selectedAvatar != null) {
        try {
          final downloadUrl = await _avatarHelper.uploadAvatar(
            userId: user.uid,
            avatarFile: selectedAvatar!,
          );

          // Update user document with avatar URL via repository
          await _userRepository.updateAvatarUrl(user.uid, downloadUrl);
        } catch (e) {
          // Continue even if avatar upload fails
          _errorMessage = 'Student created but avatar upload failed: $e';
          notifyListeners();
        }
      }

      _isCreating = false;
      notifyListeners();
      return user;

    } catch (e) {
      _isCreating = false;
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
