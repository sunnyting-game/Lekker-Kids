import 'package:flutter/material.dart';
import '../../constants/app_strings.dart';
import '../../models/user_model.dart';
import '../../repositories/user_repository.dart';

/// Dialog for managing teacher and student placement to a school.
class SchoolPlacementDialog extends StatefulWidget {
  final String schoolId;
  final String schoolName;
  final String organizationId;

  const SchoolPlacementDialog({
    super.key,
    required this.schoolId,
    required this.schoolName,
    required this.organizationId,
  });

  @override
  State<SchoolPlacementDialog> createState() => _SchoolPlacementDialogState();
}

class _SchoolPlacementDialogState extends State<SchoolPlacementDialog> {
  final UserRepository _userRepository = UserRepository();
  
  // Store streams as instance variables - initialized once in initState
  late final Stream<List<UserModel>> _teachersStream;
  late final Stream<List<UserModel>> _studentsStream;
  
  bool _isSaving = false;
  String? _error;
  
  // Track changes: userId -> isAssigned
  final Map<String, bool> _teacherSelections = {};
  final Map<String, bool> _studentSelections = {};
  
  // Track initial state to compute diff on save
  final Map<String, bool> _initialTeacherSelections = {};
  final Map<String, bool> _initialStudentSelections = {};

  @override
  void initState() {
    super.initState();
    // Initialize streams once - they won't be recreated on rebuild
    _teachersStream = _userRepository.getTeachersStreamByOrg(widget.organizationId);
    _studentsStream = _userRepository.getStudentsStreamByOrg(widget.organizationId);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 500,
          maxHeight: 600,
        ),
        child: DefaultTabController(
          length: 2,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.home_work),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.schoolPlacementTitle,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            widget.schoolName,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              
              // Tab Bar
              const TabBar(
                tabs: [
                  Tab(text: AppStrings.schoolPlacementTeachersTab),
                  Tab(text: AppStrings.schoolPlacementStudentsTab),
                ],
              ),
              
              // Error display
              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Row(
                    children: [
                      Icon(Icons.error, color: Theme.of(context).colorScheme.error),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_error!)),
                    ],
                  ),
                ),
              
              // Tab Content
              Expanded(
                child: TabBarView(
                  children: [
                    _buildUserList(
                      stream: _teachersStream,
                      selections: _teacherSelections,
                      initialSelections: _initialTeacherSelections,
                      emptyMessage: AppStrings.schoolPlacementNoTeachersInOrg,
                    ),
                    _buildUserList(
                      stream: _studentsStream,
                      selections: _studentSelections,
                      initialSelections: _initialStudentSelections,
                      emptyMessage: AppStrings.schoolPlacementNoStudentsInOrg,
                    ),
                  ],
                ),
              ),
              
              // Actions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSaving ? null : () => Navigator.pop(context),
                      child: const Text(AppStrings.schoolPlacementCancelButton),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _isSaving ? null : _savePlacement,
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(AppStrings.schoolPlacementSaveButton),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserList({
    required Stream<List<UserModel>> stream,
    required Map<String, bool> selections,
    required Map<String, bool> initialSelections,
    required String emptyMessage,
  }) {
    return StreamBuilder<List<UserModel>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data ?? [];
        
        if (users.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.person_off, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                Text(emptyMessage, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        // Initialize selections if not already done
        for (final user in users) {
          if (!initialSelections.containsKey(user.uid)) {
            final isAssigned = user.schoolIds.contains(widget.schoolId);
            initialSelections[user.uid] = isAssigned;
            selections[user.uid] = isAssigned;
          }
        }

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            final isSelected = selections[user.uid] ?? false;

            return CheckboxListTile(
              value: isSelected,
              onChanged: _isSaving
                  ? null
                  : (value) {
                      setState(() {
                        selections[user.uid] = value ?? false;
                      });
                    },
              title: Text(user.name ?? user.username),
              subtitle: Text(user.email),
              secondary: CircleAvatar(
                child: Text((user.name ?? user.username)[0].toUpperCase()),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _savePlacement() async {
    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final futures = <Future<void>>[];

      // Process teacher changes
      for (final entry in _teacherSelections.entries) {
        final userId = entry.key;
        final isNowAssigned = entry.value;
        final wasAssigned = _initialTeacherSelections[userId] ?? false;

        if (isNowAssigned && !wasAssigned) {
          futures.add(_userRepository.addUserToSchool(userId, widget.schoolId));
        } else if (!isNowAssigned && wasAssigned) {
          futures.add(_userRepository.removeUserFromSchool(userId, widget.schoolId));
        }
      }

      // Process student changes
      for (final entry in _studentSelections.entries) {
        final userId = entry.key;
        final isNowAssigned = entry.value;
        final wasAssigned = _initialStudentSelections[userId] ?? false;

        if (isNowAssigned && !wasAssigned) {
          futures.add(_userRepository.addUserToSchool(userId, widget.schoolId));
        } else if (!isNowAssigned && wasAssigned) {
          futures.add(_userRepository.removeUserFromSchool(userId, widget.schoolId));
        }
      }

      await Future.wait(futures);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.schoolPlacementSaved)),
        );
      }
    } catch (e) {
      setState(() {
        _error = AppStrings.format(
          AppStrings.schoolPlacementFailed,
          [e.toString().replaceAll('Exception: ', '')],
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}
