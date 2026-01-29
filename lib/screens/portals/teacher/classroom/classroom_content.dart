import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../constants/app_strings.dart';
import '../../../../constants/app_theme.dart';
import '../../../../viewmodels/classroom_viewmodel.dart';
import 'student_status_card.dart';
import 'widgets/date_header.dart';

class ClassroomContent extends StatelessWidget {
  const ClassroomContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ClassroomViewModel>(
      builder: (context, viewModel, _) {
        return Column(
          children: [
            // Date header
            DateHeader(date: viewModel.currentDate),
            // Student list
            Expanded(
              child: _buildStudentList(context, viewModel),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStudentList(BuildContext context, ClassroomViewModel viewModel) {
    if (viewModel.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (viewModel.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              viewModel.error!,
              style: AppTextStyles.error,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.paddingMedium),
            ElevatedButton(
              onPressed: viewModel.clearError,
              child: const Text('Dismiss'),
            ),
          ],
        ),
      );
    }

    final students = viewModel.students;

    if (students.isEmpty) {
      return Center(
        child: Text(
          AppStrings.classroomNoStudents,
          style: AppTextStyles.bodyLarge,
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.paddingMedium),
      itemCount: students.length,
      itemBuilder: (context, index) {
        final student = students[index];
        return StudentStatusCard(
          student: student,
          viewModel: viewModel,
        );
      },
    );
  }
}
