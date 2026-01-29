import 'package:flutter/material.dart';
import '../../../../constants/app_strings.dart';
import '../../../../constants/app_theme.dart';
import '../../../../models/photo_item.dart';
import '../../../../widgets/full_screen_image_viewer.dart';
import '../../../../widgets/shimmer_loading.dart';

/// Photo gallery section for the Home Tab
/// 
/// Displays today's photos using SliverGrid for optimal scroll performance.
/// Uses proper Sliver widgets for lazy loading only visible items.
class HomePhotoGallery extends StatelessWidget {
  final bool isLoading;
  final String? errorMessage;
  final List<PhotoItem> photos;

  const HomePhotoGallery({
    super.key,
    required this.isLoading,
    required this.errorMessage,
    required this.photos,
  });

  @override
  Widget build(BuildContext context) {
    // If loading, show shimmer grid
    if (isLoading) {
      return SliverPadding(
        padding: const EdgeInsets.all(AppSpacing.paddingLarge),
        sliver: SliverList(
          delegate: SliverChildListDelegate([
            Text(
              AppStrings.studentHomePhotoGalleryTitle,
              style: AppTextStyles.titleLarge,
            ),
            const SizedBox(height: AppSpacing.marginMedium),
            _buildShimmerGrid(),
          ]),
        ),
      );
    }

    if (errorMessage != null || photos.isEmpty) {
      return SliverPadding(
        padding: const EdgeInsets.all(AppSpacing.paddingLarge),
        sliver: SliverList(
          delegate: SliverChildListDelegate([
            Text(
              AppStrings.studentHomePhotoGalleryTitle,
              style: AppTextStyles.titleLarge,
            ),
            const SizedBox(height: AppSpacing.marginMedium),
            if (errorMessage != null)
              _buildErrorState(errorMessage!)
            else
              _buildEmptyState(),
          ]),
        ),
      );
    }

    // When we have photos, use proper MultiSliver pattern
    return SliverMainAxisGroup(
      slivers: [
        // Title
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.paddingLarge,
            AppSpacing.paddingLarge,
            AppSpacing.paddingLarge,
            AppSpacing.marginMedium,
          ),
          sliver: SliverToBoxAdapter(
            child: Text(
              AppStrings.studentHomePhotoGalleryTitle,
              style: AppTextStyles.titleLarge,
            ),
          ),
        ),
        // Photo Grid - using SliverGrid for lazy loading
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.paddingLarge),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
              childAspectRatio: 1,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final photo = photos[index];
                return _PhotoTile(
                  photoUrl: photo.url,
                  allPhotos: photos,
                  index: index,
                );
              },
              childCount: photos.length,
            ),
          ),
        ),
        // Bottom padding
        const SliverPadding(
          padding: EdgeInsets.only(bottom: AppSpacing.paddingLarge),
        ),
      ],
    );
  }

  Widget _buildShimmerGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        childAspectRatio: 1,
      ),
      itemCount: 8, // Show 8 shimmer placeholders
      itemBuilder: (context, index) {
        return const ShimmerLoading.rectangular(height: double.infinity);
      },
    );
  }

  Widget _buildErrorState(String error) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(color: AppColors.errorBorder),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.error,
            ),
            const SizedBox(height: 8),
            Text(
              'Failed to load photos',
              style: AppTextStyles.error,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(color: AppColors.disabledBackground),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 60,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 12),
            Text(
              'No photos yet',
              style: AppTextStyles.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final String photoUrl;
  final List<PhotoItem> allPhotos;
  final int index;

  const _PhotoTile({
    required this.photoUrl,
    required this.allPhotos,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => FullScreenImageViewer(
              photos: allPhotos.map((p) => p.url).toList(),
              initialIndex: index,
            ),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          photoUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const ShimmerLoading.rectangular(height: double.infinity);
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: AppColors.disabledBackground,
              child: Icon(
                Icons.broken_image,
                color: AppColors.textHint,
                size: 24,
              ),
            );
          },
        ),
      ),
    );
  }
}
