import 'package:flutter/material.dart';
import '../../../../../constants/app_theme.dart';
import '../../../../../viewmodels/classroom_viewmodel.dart';
import '../../../../../models/user_model.dart';
import '../../../../../widgets/photo_gallery_popup.dart';

class PhotoCountBadge extends StatelessWidget {
  final int count;
  final UserModel student;
  final ClassroomViewModel viewModel;

  const PhotoCountBadge({
    super.key,
    required this.count,
    required this.student,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showPhotoGallery(context),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.paddingSmall,
          vertical: AppSpacing.paddingXSmall,
        ),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
        ),
        child: Text(
          '$count',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textWhite,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Future<void> _showPhotoGallery(BuildContext context) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    // Fetch full daily status with photo URLs (on-demand, not in stream)
    final dailyStatus = await viewModel.fetchDailyStatusForPhotos(student.uid);

    // Close loading indicator
    if (context.mounted) {
      Navigator.of(context).pop();
    }

    // Show photo gallery if we have photos
    if (context.mounted && dailyStatus != null && dailyStatus.photos.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => PhotoGalleryPopup(
          photos: dailyStatus.photos,
        ),
      );
    }
  }
}
