import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../constants/app_strings.dart';
import '../../models/user_model.dart';
import '../../repositories/user_repository.dart';
import 'create_teacher_page.dart';
import 'edit_user_page.dart';

class TeacherPage extends StatelessWidget {
  const TeacherPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final organizationId = user?.organizationId;
    final UserRepository userRepository = UserRepository();

    if (organizationId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.adminTeacherPageTitle)),
        body: const Center(child: Text('No organization context found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.adminTeacherPageTitle),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateTeacherPage(),
                ),
              );
            },
            icon: const Icon(Icons.add),
            tooltip: AppStrings.adminAddTeacher,
          ),
        ],
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: userRepository.getTeachersStreamByOrg(organizationId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final teachers = snapshot.data ?? [];
          if (teachers.isEmpty) {
            return const Center(child: Text('No teachers found'));
          }

          return ListView.builder(
            itemCount: teachers.length,
            itemBuilder: (context, index) {
              final user = teachers[index];

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
