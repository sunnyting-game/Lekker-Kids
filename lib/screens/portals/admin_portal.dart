import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/organization_repository.dart';
import '../../services/tenant_functions_service.dart';
import '../../services/migration_service.dart';
import '../../models/school_model.dart';
import 'school_placement_dialog.dart';
import 'admin/school_daily_attendance_dialog.dart';
import '../admin/teacher_page.dart';
import '../admin/student_page.dart';
import '../admin/documents/send_document_dialog.dart';
import '../admin/documents/admin_document_list_page.dart';
import 'admin/checklist_management_dialog.dart';

class AdminPortal extends StatefulWidget {
  const AdminPortal({super.key});

  @override
  State<AdminPortal> createState() => _AdminPortalState();
}

class _AdminPortalState extends State<AdminPortal> {
  final OrganizationRepository _orgRepository = OrganizationRepository();
  final TenantFunctionsService _tenantFunctions = TenantFunctionsService();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final organizationId = user.organizationId;

    if (organizationId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin Portal')),
        body: const Center(
          child: Text('No organization assigned to this admin account.'),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => authProvider.signOut(),
          child: const Icon(Icons.logout),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Organization Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              messenger.showSnackBar(
                const SnackBar(content: Text('Syncing placement...')),
              );
              try {
                final migrationService = MigrationService();
                final count = await migrationService.syncAllAssignments();
                messenger.hideCurrentSnackBar();
                messenger.showSnackBar(
                  SnackBar(content: Text('Synced $count placement')),
                );
              } catch (e) {
                messenger.hideCurrentSnackBar();
                messenger.showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            tooltip: 'Sync Placement',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.signOut();
            },
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: Column(
        children: [
          // Manage Staff/Students Section (Organization Level)
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TeacherPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.people),
                    label: const Text('Manage Teachers'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const StudentPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.school),
                    label: const Text('Manage Students'),
                  ),
                ),
              ],
            ),
          ),
          
          // File Cabinet Button
          Container(
             padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
             color: Colors.grey[100],
             child: SizedBox(
               width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminDocumentListPage(
                          organizationId: organizationId,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.folder_open),
                  label: const Text('File Cabinet (Document Signing)'),
                ),
             ),
          ),

          const Divider(height: 1),

          // Dayhomes Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Schools',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                FilledButton.icon(
                  onPressed: () => _showCreateSchoolDialog(context, organizationId, user.email),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Create School'),
                ),
              ],
            ),
          ),

          // Dayhomes List
          Expanded(
            child: StreamBuilder<List<SchoolModel>>(
              stream: _orgRepository.getDayhomesStream(organizationId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final dayhomes = snapshot.data!;

                if (dayhomes.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.home_work_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No schools yet', style: TextStyle(color: Colors.grey)),
                        SizedBox(height: 8),
                        Text('Create your first school to get started'),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: dayhomes.length,
                  itemBuilder: (context, index) {
                    final dayhome = dayhomes[index];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // School Info Row
                            Row(
                              children: [
                                CircleAvatar(
                                  child: Text(dayhome.name[0].toUpperCase()),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        dayhome.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        'ID: ${dayhome.id}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Action Buttons Row 1
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => SchoolPlacementDialog(
                                          schoolId: dayhome.id,
                                          schoolName: dayhome.name,
                                          organizationId: organizationId,
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.people, size: 18),
                                    label: const Text('Placement'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _showAttendanceDatePicker(
                                      context,
                                      dayhome.id,
                                      dayhome.name,
                                    ),
                                    icon: const Icon(Icons.calendar_month, size: 18),
                                    label: const Text('Attendance'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Checklist Button
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => ChecklistManagementDialog(
                                      organizationId: organizationId,
                                      schoolId: dayhome.id,
                                      schoolName: dayhome.name,
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.checklist, size: 18),
                                label: const Text('Checklist'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => SendDocumentDialog(
              organizationId: organizationId,
              adminName: user.name ?? 'Admin',
            ),
          );
        },
        icon: const Icon(Icons.send_and_archive),
        label: const Text('Send Document'),
      ),
    );
  }

  Future<void> _showCreateSchoolDialog(BuildContext context, String organizationId, String userEmail) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final result = await showDialog<CreateSchoolResult>(
      context: context,
      builder: (context) => _CreateSchoolDialog(
        tenantFunctions: _tenantFunctions,
        organizationId: organizationId,
        adminEmail: userEmail,
      ),
    );

    if (result != null && result.success) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('School "${result.schoolId}" created!')),
      );
    }
  }

  Future<void> _showAttendanceDatePicker(
    BuildContext context,
    String schoolId,
    String schoolName,
  ) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Select date to view attendance',
    );

    if (pickedDate != null && mounted) {
      final dateString =
          '${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}';

      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (context) => SchoolDailyAttendanceDialog(
          schoolId: schoolId,
          schoolName: schoolName,
          date: dateString,
        ),
      );
    }
  }
}

class _CreateSchoolDialog extends StatefulWidget {
  final TenantFunctionsService tenantFunctions;
  final String organizationId;
  final String adminEmail;

  const _CreateSchoolDialog({
    required this.tenantFunctions,
    required this.organizationId,
    required this.adminEmail,
  });

  @override
  State<_CreateSchoolDialog> createState() => _CreateSchoolDialogState();
}

class _CreateSchoolDialogState extends State<_CreateSchoolDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New School'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'School Name',
                hintText: 'e.g., North Campus',
                prefixIcon: Icon(Icons.home_work),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _createSchool,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }

  Future<void> _createSchool() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await widget.tenantFunctions.createSchool(
        name: _nameController.text.trim(),
        adminEmail: widget.adminEmail,
        organizationId: widget.organizationId,
      );

      if (result.success) {
        if (mounted) {
          Navigator.pop(context, result);
        }
      } else {
        setState(() {
          _error = 'Failed to create school';
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
