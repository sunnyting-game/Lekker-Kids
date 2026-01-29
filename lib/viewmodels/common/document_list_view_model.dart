import 'package:flutter/material.dart';
import '../../models/document_model.dart';
import '../../models/signature_request_model.dart';
import '../../repositories/document_repository.dart';

class RequestWithDoc {
  final SignatureRequestModel request;
  final DocumentModel? document;

  RequestWithDoc(this.request, this.document);
}

class DocumentListViewModel extends ChangeNotifier {
  final DocumentRepository _repository;
  final String userId;

  DocumentListViewModel({
    required this.userId,
    DocumentRepository? repository,
  }) : _repository = repository ?? DocumentRepository();

  List<RequestWithDoc> _pending = [];
  List<RequestWithDoc> _signed = [];
  bool _isLoading = false;
  bool _hasLoaded = false; // Track if data has been loaded
  String? _error;

  List<RequestWithDoc> get pending => _pending;
  List<RequestWithDoc> get signed => _signed;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Fetch documents (only if not already loaded)
  Future<void> fetchDocuments() async {
    if (_hasLoaded) return; // Skip if already loaded
    await refresh();
  }

  /// Force refresh (called by FCM or manual refresh)
  Future<void> refresh() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final requests = await _repository.getRequestsForUser(userId);
      final results = <RequestWithDoc>[];
      
      for (var req in requests) {
        final doc = await _repository.getDocumentById(req.documentId);
        results.add(RequestWithDoc(req, doc));
      }

      _pending = results
          .where((r) => r.request.status == SignatureStatus.pending)
          .toList();
          
      _signed = results
          .where((r) => r.request.status == SignatureStatus.signed)
          .toList();
      
      _hasLoaded = true;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

