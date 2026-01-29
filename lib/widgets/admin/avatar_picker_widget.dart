import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:image_picker/image_picker.dart';
import '../../constants/app_theme.dart';

/// Reusable widget for displaying and selecting user avatars
class AvatarPickerWidget extends StatelessWidget {
  /// The currently selected avatar file (not yet uploaded)
  final XFile? selectedAvatar;
  
  /// The current avatar URL (from server)
  final String? currentAvatarUrl;
  
  /// Callback when user taps to pick a new avatar
  final VoidCallback onPickAvatar;
  
  /// Callback when user confirms upload of selected avatar
  final VoidCallback? onUploadAvatar;
  
  /// Whether the widget is in a loading state
  final bool isLoading;
  
  /// Whether upload is in progress
  final bool isUploading;
  
  /// Radius of the avatar circle
  final double radius;
  
  /// Whether to show upload button (for edit flow)
  /// If false, picked avatar is immediately ready (for create flow)
  final bool showUploadButton;

  const AvatarPickerWidget({
    super.key,
    this.selectedAvatar,
    this.currentAvatarUrl,
    required this.onPickAvatar,
    this.onUploadAvatar,
    this.isLoading = false,
    this.isUploading = false,
    this.radius = 50,
    this.showUploadButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: (isLoading || isUploading) ? null : onPickAvatar,
          child: Stack(
            alignment: Alignment.center,
            children: [
              _buildAvatar(),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.marginSmall),
        if (showUploadButton && selectedAvatar != null)
          ElevatedButton(
            onPressed: (isUploading || onUploadAvatar == null) ? null : onUploadAvatar,
            child: isUploading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Upload Avatar'),
          )
        else if (showUploadButton)
          TextButton.icon(
            onPressed: isLoading ? null : onPickAvatar,
            icon: const Icon(Icons.camera_alt),
            label: Text(currentAvatarUrl != null ? 'Change Avatar' : 'Add Avatar'),
          )
        else
          Text(
            'Tap to select avatar (optional)',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textHint,
            ),
          ),
      ],
    );
  }

  Widget _buildAvatar() {
    // Show selected avatar (not yet uploaded)
    if (selectedAvatar != null) {
      return FutureBuilder<Uint8List>(
        future: selectedAvatar!.readAsBytes(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return CircleAvatar(
              radius: radius,
              backgroundColor: AppColors.primaryLight,
              child: ClipOval(
                child: Image.memory(
                  snapshot.data!,
                  width: radius * 2,
                  height: radius * 2,
                  fit: BoxFit.cover,
                ),
              ),
            );
          }
          return _buildPlaceholder(Icons.image);
        },
      );
    }

    // Show current avatar from URL
    if (currentAvatarUrl != null && currentAvatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.primaryLight,
        backgroundImage: NetworkImage(currentAvatarUrl!),
      );
    }

    // Show placeholder
    return _buildPlaceholder(showUploadButton ? Icons.person : Icons.camera_alt);
  }

  Widget _buildPlaceholder(IconData icon) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primaryLight,
      child: Icon(
        icon,
        size: radius,
        color: AppColors.primary,
      ),
    );
  }
}
