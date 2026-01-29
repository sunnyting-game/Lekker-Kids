import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../viewmodels/album_viewmodel.dart';
import '../../../constants/app_strings.dart';
import '../../../constants/app_theme.dart';

class AlbumTab extends StatefulWidget {
  const AlbumTab({super.key});

  @override
  State<AlbumTab> createState() => _AlbumTabState();
}

class _AlbumTabState extends State<AlbumTab> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AlbumViewModel>(
      builder: (context, viewModel, child) {
        // Show loading indicator
        if (viewModel.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        // Show error state
        if (viewModel.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  viewModel.errorMessage!,
                  style: AppTextStyles.error,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.marginMedium),
                ElevatedButton(
                  onPressed: viewModel.refresh,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final photosByDate = viewModel.photosByDate;
        final today = _formatDate(DateTime.now());
        final todayPhotos = photosByDate[today] ?? [];

        return RefreshIndicator(
          onRefresh: viewModel.refresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.paddingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Today's Photos Section
                  _buildTodaySection(todayPhotos),
                  
                  const SizedBox(height: AppSpacing.marginLarge),
                  
                  // Album Section (past 14 days)
                  _buildAlbumSection(photosByDate, today),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTodaySection(List<Map<String, dynamic>> todayPhotos) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.albumTodayPhotosTitle,
          style: AppTextStyles.titleLarge,
        ),
        const SizedBox(height: AppSpacing.marginMedium),
        
        if (todayPhotos.isEmpty)
          _buildEmptyState(AppStrings.albumNoPhotosToday)
        else
          _buildPhotoGrid(todayPhotos, isToday: true),
      ],
    );
  }

  Widget _buildAlbumSection(
    Map<String, List<Map<String, dynamic>>> photosByDate,
    String today,
  ) {
    // Remove today from the album section
    final albumPhotos = Map<String, List<Map<String, dynamic>>>.from(photosByDate);
    albumPhotos.remove(today);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.albumSectionTitle,
          style: AppTextStyles.titleLarge,
        ),
        const SizedBox(height: AppSpacing.marginMedium),
        
        if (albumPhotos.isEmpty)
          _buildEmptyState(AppStrings.albumNoPhotos)
        else
          _buildDateSeparatedPhotos(albumPhotos),
      ],
    );
  }

  Widget _buildDateSeparatedPhotos(
    Map<String, List<Map<String, dynamic>>> photosByDate,
  ) {
    // Sort dates in descending order (most recent first)
    final sortedDates = photosByDate.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sortedDates.map((date) {
        final photos = photosByDate[date]!;
        final dateLabel = _getDateLabel(date);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date separator
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.marginMedium,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 1,
                      color: Colors.grey[300],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.paddingMedium,
                    ),
                    child: Text(
                      dateLabel,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 1,
                      color: Colors.grey[300],
                    ),
                  ),
                ],
              ),
            ),
            
            // Photos for this date
            _buildPhotoGrid(photos, isToday: false),
            
            const SizedBox(height: AppSpacing.marginMedium),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildPhotoGrid(
    List<Map<String, dynamic>> photos, {
    required bool isToday,
  }) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        childAspectRatio: 1,
      ),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        final photo = photos[index];
        final photoUrl = photo['url'] as String;
        
        return _buildPhotoTile(photoUrl, photos, index);
      },
    );
  }

  Widget _buildPhotoTile(
    String photoUrl,
    List<Map<String, dynamic>> allPhotos,
    int index,
  ) {
    return GestureDetector(
      onTap: () {
        _showFullScreenImage(photoUrl, allPhotos, index);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          photoUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: Colors.grey[300],
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[300],
              child: Icon(
                Icons.broken_image,
                color: Colors.grey[600],
                size: 40,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 60,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullScreenImage(
    String initialUrl,
    List<Map<String, dynamic>> allPhotos,
    int initialIndex,
  ) {
    final photoUrls = allPhotos
        .map((p) => p['url'] as String)
        .toList();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _FullScreenImageViewer(
          photos: photoUrls,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  String _getDateLabel(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final targetDate = DateTime(date.year, date.month, date.day);

      if (targetDate == today) {
        return AppStrings.albumToday;
      } else if (targetDate == yesterday) {
        return AppStrings.albumYesterday;
      } else {
        // Format as "Dec 10, 2025"
        return DateFormat('MMM d, yyyy').format(date);
      }
    } catch (e) {
      return dateString;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

// Full-screen image viewer widget
class _FullScreenImageViewer extends StatefulWidget {
  final List<String> photos;
  final int initialIndex;

  const _FullScreenImageViewer({
    required this.photos,
    required this.initialIndex,
  });

  @override
  State<_FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${_currentIndex + 1} / ${widget.photos.length}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.photos.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: Image.network(
                widget.photos[index],
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      color: Colors.white,
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
