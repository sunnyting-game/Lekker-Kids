import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../repositories/student_repository.dart';
import '../../../services/student_service.dart';
import '../../../viewmodels/classroom_viewmodel.dart';
import 'classroom/classroom_content.dart';

/// ClassroomTab - Refactored to use modular components
///
/// This file now serves as the entry point and dependency injector.
/// UI logic has been moved to [ClassroomContent] and its child widgets.
class ClassroomTab extends StatelessWidget {
  const ClassroomTab({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    final teacherId = user?.uid ?? '';
    
    // Get the user's first school ID for scoping
    // TODO: Use ContextService to get selected school when multi-school is implemented
    final schoolId = user?.schoolIds.isNotEmpty == true 
        ? user!.schoolIds.first 
        : '';

    if (schoolId.isEmpty) {
      return const Center(child: Text('No school assigned'));
    }

    // Create services with school context
    final studentService = StudentService()..setSchoolContext(schoolId);
    final studentRepository = StudentRepository()..setSchoolContext(schoolId);

    return ChangeNotifierProvider(
      create: (_) => ClassroomViewModel(
        studentService: studentService,
        repository: studentRepository,
        currentTeacherId: teacherId,
      ),
      child: const ClassroomContent(),
    );
  }
}
