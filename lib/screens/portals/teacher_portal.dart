import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../constants/app_strings.dart';
import '../../constants/app_theme.dart';
import 'teacher/classroom_tab.dart';
import 'teacher/attendance_tab.dart';
import 'teacher/weekly_plan_tab.dart';
import 'student/document_tab.dart';
import 'teacher/checklist_tab.dart';

class TeacherPortal extends StatefulWidget {
  const TeacherPortal({super.key});

  @override
  State<TeacherPortal> createState() => _TeacherPortalState();
}

class _TeacherPortalState extends State<TeacherPortal> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    ClassroomTab(),
    AttendanceTab(),
    WeeklyPlanTab(),
    DocumentTab(),
    ChecklistTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.teacherPortalTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.signOut();
            },
            tooltip: AppStrings.portalSignOut,
          ),
        ],
      ),
      body: _tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.class_),
            label: AppStrings.teacherNavClassroom,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle_outline),
            label: AppStrings.teacherNavAttendance,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: AppStrings.teacherNavWeeklyPlan,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description),
            label: AppStrings.teacherNavDocuments,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.checklist),
            label: AppStrings.teacherNavChecklist,
          ),
        ],
      ),
    );
  }
}
