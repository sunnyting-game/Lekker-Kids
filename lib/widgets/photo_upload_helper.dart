import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../constants/app_strings.dart';
import '../../../constants/app_theme.dart';
import '../../../services/photo_service.dart';

class PhotoUploadHelper {
  final PhotoService _photoService = FirebasePhotoService();
  final ImagePicker _picker = ImagePicker();

  // Show photo source selection dialog
  Future<void> showPhotoSourceDialog({
    required BuildContext context,
    required String studentId,
    required String date,
    required String teacherId,
  }) async {
    await showModalBottomSheet(
      context: context,
      builder: (bottomSheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(AppStrings.cameraFromGallery),
              onTap: () async {
                // 1. Pick photo first (don't close sheet yet)
                // We pass the *original* context for the picker to use for SnackBars if needed
                // But we don't show the preview yet
                await _handlePhotoSelection(
                  context: context,
                  bottomSheetContext: bottomSheetContext,
                  source: ImageSource.gallery,
                  studentId: studentId,
                  date: date,
                  teacherId: teacherId,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(AppStrings.cameraFromCamera),
              onTap: () async {
                await _handlePhotoSelection(
                  context: context,
                  bottomSheetContext: bottomSheetContext,
                  source: ImageSource.camera,
                  studentId: studentId,
                  date: date,
                  teacherId: teacherId,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel),
              title: Text(AppStrings.cameraCancel),
              onTap: () => Navigator.pop(bottomSheetContext),
            ),
          ],
        ),
      ),
    );
  }

  // Helper to handle selection flow: Pick -> Pop Sheet -> Show Preview
  Future<void> _handlePhotoSelection({
    required BuildContext context,
    required BuildContext bottomSheetContext,
    required ImageSource source,
    required String studentId,
    required String date,
    required String teacherId,
  }) async {
    try {
      debugPrint('📱 Picking photo from ${source == ImageSource.camera ? "camera" : "gallery"}');
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      // 2. Close bottom sheet unconditionally after picker returns
      if (bottomSheetContext.mounted) {
        Navigator.pop(bottomSheetContext);
      }

      if (pickedFile == null) {
        debugPrint('⚠️ No photo selected');
        return;
      }

      debugPrint('✅ Photo selected: ${pickedFile.path}');

      // 3. Show preview using the original context
      // We wait a bit to let the bottom sheet closing animation finish
      await Future.delayed(const Duration(milliseconds: 300));

      if (context.mounted) {
        await _showPhotoPreview(
          context: context,
          photoFile: pickedFile,
          studentId: studentId,
          date: date,
          teacherId: teacherId,
        );
      } else {
        debugPrint('⚠️ Context no longer mounted after picking, cannot show preview');
      }
    } catch (e) {
      debugPrint('❌ Error in photo selection flow: $e');
      // Ensure sheet is closed if error occurs
      if (bottomSheetContext.mounted) {
        Navigator.pop(bottomSheetContext);
      }
      
      if (context.mounted) {
        _showSnackBar(
          context,
          AppStrings.cameraPermissionError,
          isError: true,
        );
      }
    }
  }


  // Show photo preview dialog
  Future<void> _showPhotoPreview({
    required BuildContext context,
    required XFile photoFile, // Accept XFile
    required String studentId,
    required String date,
    required String teacherId,
  }) async {
    debugPrint('🖼️ Showing photo preview');
    
    // For web, use Image.network with blob URL (photoFile.path)
    // For mobile, use Image.file
    final isWeb = kIsWeb;
    
    // Capture the parent context before showing dialog
    // This ensures we have a valid context for the upload flow
    final parentContext = context;
    
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppStrings.cameraPreviewTitle),
        content: SingleChildScrollView(
          child: isWeb
              ? Image.network(photoFile.path) 
              : Image.file(File(photoFile.path)),
        ),
        actions: [
          TextButton(
            onPressed: () {
              debugPrint('❌ User cancelled upload');
              Navigator.pop(dialogContext);
            },
            child: Text(AppStrings.cameraCancel),
          ),
          ElevatedButton(
            onPressed: () async {
              debugPrint('✅ User confirmed upload');
              Navigator.pop(dialogContext);
              // Use parentContext for upload, not the dialogContext which is now invalid
              if (parentContext.mounted) {
                await _uploadPhoto(
                  context: parentContext,
                  photoFile: photoFile,
                  studentId: studentId,
                  date: date,
                  teacherId: teacherId,
                );
              }
            },
            child: Text(AppStrings.cameraConfirmUpload),
          ),
        ],
      ),
    );
  }

  // Upload photo to Firebase
  Future<void> _uploadPhoto({
    required BuildContext context,
    required XFile photoFile, // Accept XFile
    required String studentId,
    required String date,
    required String teacherId,
  }) async {
    debugPrint('🚀 Initiating upload...');
    debugPrint('   Student ID: $studentId');
    debugPrint('   Date: $date');
    debugPrint('   Teacher ID: $teacherId');
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: AppSpacing.paddingLarge),
              Text(AppStrings.cameraUploading),
            ],
          ),
        ),
      ),
    );

    try {
      // Add timeout to prevent hanging forever
      await _photoService.uploadStudentPhoto(
        photoFile: photoFile,
        studentId: studentId,
        date: date,
        teacherId: teacherId,
      ).timeout(const Duration(seconds: 30));

      debugPrint('🎉 Upload completed successfully!');
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        _showSnackBar(context, AppStrings.cameraUploadSuccess);
      }
    } catch (e) {
      debugPrint('💥 Upload failed: $e');
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        
        String errorMessage = AppStrings.cameraUploadError;
        if (e.toString().contains('5MB')) {
          errorMessage = AppStrings.cameraFileSizeError;
        } else if (e is TimeoutException) {
          errorMessage = 'Upload timed out. Please check your connection.';
        }
        
        _showSnackBar(context, errorMessage, isError: true);
      }
    }
  }

  // Show snackbar message
  void _showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
      ),
    );
  }
}
