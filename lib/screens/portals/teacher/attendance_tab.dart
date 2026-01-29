import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_strings.dart';
import '../../../constants/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/student_service.dart';
import '../../../viewmodels/attendance_view_model.dart';
import 'attendance/widgets/attendance_card.dart';

class AttendanceTab extends StatelessWidget {
  const AttendanceTab({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    
    // Get the user's first school ID for scoping
    final schoolId = user?.schoolIds.isNotEmpty == true 
        ? user!.schoolIds.first 
        : '';

    if (schoolId.isEmpty) {
      return const Center(child: Text('No school assigned'));
    }

    // Create service with school context
    final studentService = StudentService()..setSchoolContext(schoolId);

    return ChangeNotifierProvider(
      create: (_) => AttendanceViewModel(
        studentService: studentService,
      ),
      child: const _AttendanceContent(),
    );
  }
}

class _AttendanceContent extends StatelessWidget {
  const _AttendanceContent();

  @override
  Widget build(BuildContext context) {
    return Consumer<AttendanceViewModel>(
      builder: (context, viewModel, _) {
        return Column(
          children: [
            // Date header
            Container(
              padding: const EdgeInsets.all(AppSpacing.paddingMedium),
              color: AppColors.primaryLight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: AppSpacing.iconSmall,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppSpacing.paddingSmall),
                  Text(
                    viewModel.currentDate,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // Student list
            Expanded(
              child: _buildStudentList(viewModel),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStudentList(AttendanceViewModel viewModel) {
    final students = viewModel.students;

    if (students.isEmpty) {
      return Center(
        child: Text(
          AppStrings.attendanceNoStudents,
          style: AppTextStyles.bodyLarge,
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.paddingMedium),
      itemCount: students.length,
      itemBuilder: (context, index) {
        return AttendanceCard(
          student: students[index],
          viewModel: viewModel,
        );
      },
    );
  }
}
