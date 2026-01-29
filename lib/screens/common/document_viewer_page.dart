import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // kIsWeb
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../../models/document_model.dart';
import '../../models/signature_request_model.dart';
import '../../repositories/document_repository.dart';

class DocumentViewerPage extends StatefulWidget {
  final SignatureRequestModel request;
  final DocumentModel document;
  final VoidCallback? onSigned; // Callback to refresh list if needed relating to nav

  const DocumentViewerPage({
    super.key,
    required this.request,
    required this.document,
    this.onSigned,
  });

  @override
  State<DocumentViewerPage> createState() => _DocumentViewerPageState();
}

class _DocumentViewerPageState extends State<DocumentViewerPage> {
  bool _isChecked = false;
  bool _isSigning = false;
  String? _localPath;
  bool _isLoadingPdf = true;

  @override
  void initState() {
    super.initState();
    // Download PDF for all documents on native (not just pending)
    if (!kIsWeb) {
      _downloadFile();
    } else {
      _isLoadingPdf = false;
    }
  }

  Future<void> _downloadFile() async {
    try {
      final response = await http.get(Uri.parse(widget.document.url));
      final bytes = response.bodyBytes;
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/${widget.document.id}.pdf');
      await file.writeAsBytes(bytes, flush: true);
      if (mounted) {
        setState(() {
          _localPath = file.path;
          _isLoadingPdf = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingPdf = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading PDF: $e')),
        );
      }
    }
  }

  Future<void> _handleSign() async {
    setState(() => _isSigning = true);
    try {
      final repo = DocumentRepository(); // Or inject via Provider
      await repo.signDocument(widget.request.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document signed successfully!')),
        );
        widget.onSigned?.call();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSigning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // If already signed, just show View-Only mode
    final isSigned = widget.request.status == SignatureStatus.signed;

    return Scaffold(
      appBar: AppBar(title: Text(widget.document.title)),
      body: Column(
        children: [
          // PDF Viewer Area
          Expanded(
            child: kIsWeb
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.picture_as_pdf, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        const Text(
                          'PDF viewing is handled in a new tab on Web.',
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () async {
                            final uri = Uri.parse(widget.document.url);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            }
                          },
                          icon: const Icon(Icons.open_in_new),
                          label: const Text('Open PDF'),
                        ),
                      ],
                    ),
                  )
                : _isLoadingPdf
                    ? const Center(child: CircularProgressIndicator())
                    : _localPath != null
                        ? PDFView(
                            filePath: _localPath,
                            enableSwipe: true,
                            swipeHorizontal: false,
                            autoSpacing: false,
                            pageFling: false,
                          )
                        : const Center(child: Text('Failed to load PDF')),
          ),

          // Signing Area (Only if pending)
          if (!isSigned) ...[
            const Divider(height: 1),
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CheckboxListTile(
                    value: _isChecked,
                    onChanged: (val) => setState(() => _isChecked = val ?? false),
                    title: const Text(
                      'I acknowledge that I have read and agree to the contents of this document.',
                      style: TextStyle(fontSize: 14),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: (_isChecked && !_isSigning) ? _handleSign : null,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isSigning
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Confirm & Sign'),
                  ),
                ],
              ),
            ),
          ] else ...[
             // Already signed banner
             Container(
               padding: const EdgeInsets.all(16),
               color: Colors.green[50],
               width: double.infinity,
               child: Column(
                 children: [
                   const Icon(Icons.check_circle, color: Colors.green),
                   const SizedBox(height: 8),
                   Text(
                     'Signed on ${widget.request.signedAt?.toString().split(' ')[0] ?? 'Unknown Date'}',
                     style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                   ),
                 ],
               ),
             ),
          ],
        ],
      ),
    );
  }
}
