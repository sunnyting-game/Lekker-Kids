import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../viewmodels/admin/send_document_view_model.dart';
import '../../../models/school_model.dart';

class SendDocumentDialog extends StatelessWidget {
  final String organizationId;
  final String adminName;

  const SendDocumentDialog({
    super.key,
    required this.organizationId,
    required this.adminName,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SendDocumentViewModel()..init(organizationId),
      child: Consumer<SendDocumentViewModel>(
        builder: (context, viewModel, child) {
          return AlertDialog(
            title: const Text('Send Document'),
            content: SizedBox(
              width: 500, // Fixed width for desktop/tablet
              child: viewModel.isLoading
                  ? const SizedBox(
                      height: 200,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Error Banner
                          if (viewModel.error != null)
                            Container(
                              padding: const EdgeInsets.all(8),
                              margin: const EdgeInsets.only(bottom: 16),
                              color: Colors.red[50],
                              child: Text(
                                viewModel.error!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),

                          // 1. File Selection
                          const Text('1. Upload Document (PDF)', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              ElevatedButton.icon(
                                onPressed: viewModel.pickFile,
                                icon: const Icon(Icons.upload_file),
                                label: const Text('Choose File'),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  viewModel.selectedFileName ?? 'No file selected',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // 2. Document Title
                          TextField(
                            decoration: const InputDecoration(
                              labelText: 'Document Title',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: viewModel.setTitle,
                            controller: TextEditingController(text: viewModel.selectedFileName)
                              ..selection = TextSelection.fromPosition(
                                TextPosition(offset: viewModel.selectedFileName?.length ?? 0)
                              ), // Hacky: keeps cursor at end if name auto-filled
                          ),
                          const SizedBox(height: 24),

                          // 3. Recipients
                          const Text('3. Select Recipients', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          
                          // Filter Dropdown
                          DropdownButtonFormField<SchoolModel>(
                            decoration: const InputDecoration(
                              labelText: 'Filter by Dayhome',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            value: viewModel.selectedSchool,
                            items: [
                              const DropdownMenuItem<SchoolModel>(
                                value: null,
                                child: Text('All Organization'),
                              ),
                              ...viewModel.schools.map((school) => DropdownMenuItem(
                                    value: school,
                                    child: Text(school.name),
                                  )),
                            ],
                            onChanged: viewModel.setSelectedSchool,
                          ),
                          const SizedBox(height: 12),

                          // Select All Checkbox
                          if (viewModel.filteredUsers.isNotEmpty)
                            CheckboxListTile(
                              title: const Text('Select All'),
                              value: viewModel.isAllSelected,
                              onChanged: (_) => viewModel.toggleSelectAll(),
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                            ),

                          const Divider(),

                          // User List
                          if (viewModel.filteredUsers.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text('No users found.', style: TextStyle(color: Colors.grey)),
                            )
                          else
                            Container(
                              height: 200, // Scrollable area for users
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: viewModel.filteredUsers.length,
                                itemBuilder: (context, index) {
                                  final user = viewModel.filteredUsers[index];
                                  final isSelected = viewModel.selectedUserIds.contains(user.uid);
                                  return CheckboxListTile(
                                    value: isSelected,
                                    onChanged: (_) => viewModel.toggleUser(user.uid),
                                    title: Text(user.name ?? 'Unknown User'),
                                    subtitle: Text('${user.role.name.toUpperCase()} • ${user.email}'),
                                    secondary: CircleAvatar(
                                      backgroundImage: user.avatarUrl != null
                                          ? NetworkImage(user.avatarUrl!)
                                          : null,
                                      child: user.avatarUrl == null
                                          ? Text(user.name?[0].toUpperCase() ?? '?')
                                          : null,
                                    ),
                                    dense: true,
                                  );
                                },
                              ),
                            ),
                          
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              '${viewModel.selectedCount} recipients selected', 
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: viewModel.isLoading
                    ? null
                    : () async {
                        final success = await viewModel.sendDocument(adminName);
                        if (success && context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Document sent successfully!')),
                          );
                        }
                      },
                child: const Text('Send'),
              ),
            ],
          );
        },
      ),
    );
  }
}
