import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../viewmodels/home_viewmodel.dart';
import 'widgets/home_banner.dart';
import 'widgets/home_status_section.dart';
import 'widgets/home_photo_gallery.dart';
import '../../../../widgets/shimmer_loading.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  HomeViewModel? _viewModel;

  @override
  void initState() {
    super.initState();
    // Listen for errors from ViewModel and show SnackBar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _viewModel = Provider.of<HomeViewModel>(context, listen: false);
      _viewModel?.addListener(_errorListener);
    });
  }

  @override
  void dispose() {
    // Remove listener using cached reference - no context access
    _viewModel?.removeListener(_errorListener);
    _viewModel = null;
    super.dispose();
  }

  void _errorListener() {
    // Check if widget is still mounted before accessing context
    if (!mounted || _viewModel == null) return;
    
    // Use cached reference - no context access needed
    if (_viewModel!.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_viewModel!.errorMessage!),
          duration: const Duration(seconds: 3),
        ),
      );
      _viewModel!.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeViewModel>(
      builder: (context, viewModel, child) {
        // Show loading indicator while critical data is loading
        if (viewModel.isLoading) {
          return const Center(
            child: ShimmerList(itemCount: 4, itemHeight: 120),
          );
        }

        return CustomScrollView(
          slivers: [
            // Banner Section - wrapped in SliverToBoxAdapter
            SliverToBoxAdapter(
              child: HomeBanner(viewModel: viewModel),
            ),
            
            // Status Section - wrapped in SliverToBoxAdapter
            SliverToBoxAdapter(
              child: HomeStatusSection(status: viewModel.dailyStatus),
            ),
            
            // Photo Gallery Section - returns Sliver widget
            HomePhotoGallery(
              isLoading: viewModel.isPhotosLoading,
              errorMessage: viewModel.photosError,
              photos: viewModel.photos,
            ),
          ],
        );
      },
    );
  }
}
