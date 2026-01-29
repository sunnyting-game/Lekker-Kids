import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../constants/app_theme.dart';
import '../../../../../models/user_model.dart';
import '../../../../../providers/auth_provider.dart';
import '../../../../../widgets/photo_upload_helper.dart';

class CameraButton extends StatelessWidget {
  final UserModel student;
  final String date;

  const CameraButton({
    super.key,
    required this.student,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(
        Icons.camera_alt,
        color: AppColors.primary,
      ),
      onPressed: () {
        final authProvider = Provider.of<AuthProvider>(
          context,
          listen: false,
        );
        final teacherId = authProvider.currentUser?.uid ?? '';

        PhotoUploadHelper().showPhotoSourceDialog(
          context: context,
          studentId: student.uid,
          date: date,
          teacherId: teacherId,
        );
      },
      tooltip: 'Upload Photo',
    );
  }
}
