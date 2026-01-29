import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../viewmodels/admin/admin_document_list_view_model.dart';
import '../../../models/school_model.dart';
import '../../../models/signature_request_model.dart';

class AdminDocumentListPage extends StatelessWidget {
  final String organizationId;

  const AdminDocumentListPage({
    super.key,
    required this.organizationId,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminDocumentListViewModel()..init(organizationId),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('File Cabinet'),
        ),
        body: Consumer<AdminDocumentListViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (viewModel.error != null) {
              return Center(child: Text('Error: ${viewModel.error}'));
            }

            return Column(
              children: [
                // Filter Header
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey[100],
                  child: DropdownButtonFormField<SchoolModel>(
                    decoration: const InputDecoration(
                      labelText: 'Filter by Dayhome',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      filled: true,
                      fillColor: Colors.white,
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
                ),
                
                // Document List
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: viewModel.stats.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final stat = viewModel.stats[index];
                      return Card(
                        elevation: 2,
                        child: ExpansionTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue[100],
                            child: const Icon(Icons.description, color: Colors.blue),
                          ),
                          title: Text(stat.document.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              LinearProgressIndicator(
                                value: stat.progress,
                                backgroundColor: Colors.grey[200],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  stat.progress == 1.0 ? Colors.green : Colors.orange,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${stat.signedCount} / ${stat.totalRequests} signed (${(stat.progress * 100).toInt()}%)',
                                style: TextStyle(color: Colors.grey[700], fontSize: 12),
                              ),
                              Text(
                                'Sent: ${_formatDate(stat.document.createdAt)}',
                                style: TextStyle(color: Colors.grey[500], fontSize: 11),
                              ),
                            ],
                          ),
                          children: [
                            // Details List (Simple table/list of users)
                            if (stat.requests.isEmpty)
                              const Padding(padding: EdgeInsets.all(16), child: Text("No recipients found for this selection.")),
                            
                            if (stat.requests.isNotEmpty)
                              Container(
                                constraints: const BoxConstraints(maxHeight: 300),
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: stat.requests.length,
                                  itemBuilder: (context, reqIndex) {
                                    final req = stat.requests[reqIndex];
                                    final isSigned = req.status == SignatureStatus.signed;
                                    return ListTile(
                                      dense: true,
                                      leading: Icon(
                                        isSigned ? Icons.check_circle : Icons.pending,
                                        color: isSigned ? Colors.green : Colors.orange,
                                        size: 20,
                                      ),
                                      title: Text(viewModel.getUserName(req.userId)),
                                      trailing: isSigned 
                                          ? Text(_formatDate(req.signedAt!), style: const TextStyle(fontSize: 10))
                                          : const Text('Pending', style: TextStyle(fontSize: 10, color: Colors.orange)),
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
