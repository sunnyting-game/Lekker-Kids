import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../constants/app_theme.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../viewmodels/home_viewmodel.dart';

/// Banner section for the Home Tab
/// 
/// Displays a banner image (or gradient fallback) with an edit button
/// and user avatar at the bottom center.
class HomeBanner extends StatelessWidget {
  final HomeViewModel viewModel;

  const HomeBanner({
    super.key,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final bannerHeight = screenHeight / 3;

    return Container(
      height: bannerHeight,
      decoration: BoxDecoration(
        gradient: viewModel.bannerImageUrl == null
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary,
                  AppColors.primary.withValues(alpha: 0.7),
                ],
              )
            : null,
        image: viewModel.bannerImageUrl != null
            ? DecorationImage(
                image: NetworkImage(viewModel.bannerImageUrl!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: Stack(
        children: [
          // Edit button in top right
          Positioned(
            top: 16,
            right: 16,
            child: viewModel.isUploadingBanner
                ? Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                    ),
                    child: const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    ),
                  )
                : Material(
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: () => viewModel.updateBanner(),
                      customBorder: const CircleBorder(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: const Icon(
                          Icons.edit,
                          size: 24,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
          ),
          // Avatar at bottom center
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Consumer<AuthProvider>(
                builder: (context, authProvider, _) {
                  final avatarUrl = authProvider.currentUser?.avatarUrl;
                  return Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 3,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.primaryLight,
                      backgroundImage: avatarUrl != null
                          ? NetworkImage(avatarUrl)
                          : null,
                      child: avatarUrl == null
                          ? Icon(
                              Icons.person,
                              size: 50,
                              color: AppColors.primary,
                            )
                          : null,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
