import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../constants/app_strings.dart';
import '../../constants/app_theme.dart';
import 'student/home_tab.dart';
import 'student/parent_chat_tab.dart';
import 'student/album_tab.dart';
import 'student/document_tab.dart';

class StudentPortal extends StatefulWidget {
  const StudentPortal({super.key});

  @override
  State<StudentPortal> createState() => _StudentPortalState();
}

class _StudentPortalState extends State<StudentPortal> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    HomeTab(),
    ParentChatTab(),
    AlbumTab(),
    DocumentTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.studentPortalTitle),
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
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: AppStrings.studentNavHome,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: AppStrings.studentNavParentChat,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.photo_album),
            label: AppStrings.studentNavAlbum,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description),
            label: AppStrings.studentNavDocument,
          ),
        ],
      ),
    );
  }
}
