import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../constants/app_strings.dart';
import '../../models/user_model.dart';
import '../../repositories/user_repository.dart';
import 'create_student_page.dart';
import 'edit_user_page.dart';

class StudentPage extends StatelessWidget {
  const StudentPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final organizationId = user?.organizationId;
    final UserRepository userRepository = UserRepository();

    if (organizationId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.adminStudentPageTitle)),
        body: const Center(child: Text('No organization context found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.adminStudentPageTitle),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateStudentPage(),
                ),
              );
            },
            icon: const Icon(Icons.add),
            tooltip: AppStrings.adminAddStudent,
          ),
        ],
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: userRepository.getStudentsStreamByOrg(organizationId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final students = snapshot.data ?? [];
          if (students.isEmpty) {
            return const Center(child: Text('No students found'));
          }

          return ListView.builder(
            itemCount: students.length,
            itemBuilder: (context, index) {
              final user = students[index];

              return ListTile(
                title: Text(user.name ?? user.username),
                subtitle: Text(user.username),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditUserPage(user: user),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
