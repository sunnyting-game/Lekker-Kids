import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../viewmodels/common/document_list_view_model.dart';
import '../../common/document_viewer_page.dart';

class DocumentTab extends StatefulWidget {
  const DocumentTab({super.key});

  @override
  State<DocumentTab> createState() => _DocumentTabState();
}

class _DocumentTabState extends State<DocumentTab> {
  // Note: FCM callback is now registered in AuthWrapper (main.dart)
  // to persist across tab switches

  @override
  Widget build(BuildContext context) {
    return Consumer<DocumentListViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (viewModel.error != null) {
          return Center(child: Text('Error: ${viewModel.error}'));
        }

        return DefaultTabController(
          length: 2,
          child: Column(
            children: [
              const TabBar(
                labelColor: Colors.blue,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.blue,
                tabs: [
                  Tab(text: 'Action Required', icon: Icon(Icons.assignment_late_outlined)),
                  Tab(text: 'History', icon: Icon(Icons.history)),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildList(context, viewModel.pending, true, viewModel),
                    _buildList(context, viewModel.signed, false, viewModel),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildList(
    BuildContext context, 
    List<RequestWithDoc> items, 
    bool isPending,
    DocumentListViewModel viewModel, // Pass VM to refresh if needed
  ) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isPending ? Icons.check_circle_outline : Icons.history_edu, 
              size: 48, 
              color: Colors.grey[300]
            ),
            const SizedBox(height: 16),
            Text(
              isPending ? 'All caught up!' : 'No signed documents yet.',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final doc = item.document;
        final req = item.request;
        
        if (doc == null) return const SizedBox.shrink(); // Skip invalid

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.red,
              child: Icon(Icons.picture_as_pdf, color: Colors.white),
            ),
            title: Text(doc.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sent: ${_formatDate(req.createdAt)}'),
                if (!isPending && req.signedAt != null)
                  Text('Signed: ${_formatDate(req.signedAt!)}', 
                      style: const TextStyle(color: Colors.green, fontSize: 12)),
              ],
            ),
            trailing: isPending 
                ? const Chip(label: Text('Sign Now'), backgroundColor: Colors.orange, labelStyle: TextStyle(color: Colors.white))
                : const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DocumentViewerPage(
                    request: req,
                    document: doc,
                    onSigned: () {
                      // Refresh ViewModel to move document to History
                      viewModel.refresh();
                    },
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    // Simple formatter, preferably use intl package but keeping it dependency-light if not needed globally yet
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
