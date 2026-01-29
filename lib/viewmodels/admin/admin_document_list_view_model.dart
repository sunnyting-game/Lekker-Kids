import 'package:flutter/foundation.dart';
import 'dart:async';
import '../../models/document_model.dart';
import '../../models/signature_request_model.dart';
import '../../models/school_model.dart';
import '../../repositories/document_repository.dart';
import '../../repositories/organization_repository.dart';
import '../../repositories/user_repository.dart';

class DocumentStats {
  final DocumentModel document;
  final int totalRequests;
  final int signedCount;
  final List<SignatureRequestModel> requests;

  DocumentStats({
    required this.document,
    required this.requests,
  })  : totalRequests = requests.length,
        signedCount = requests.where((r) => r.status == SignatureStatus.signed).length;
        
  double get progress => totalRequests == 0 ? 0 : signedCount / totalRequests;
}

class AdminDocumentListViewModel extends ChangeNotifier {
  final DocumentRepository _documentRepository;
  final OrganizationRepository _organizationRepository;
  final UserRepository _userRepository;
  
  List<DocumentModel> _documents = [];
  final Map<String, List<SignatureRequestModel>> _requestsCache = {}; // docId -> requests
  final Map<String, String> _userNameCache = {}; // userId -> displayName
  List<SchoolModel> _schools = [];
  SchoolModel? _selectedSchool;

  bool _isLoading = true;
  String? _error;
  
  // Subscriptions
  StreamSubscription? _docSubscription;
  final Map<String, StreamSubscription> _requestSubscriptions = {};

  AdminDocumentListViewModel({
    DocumentRepository? documentRepository,
    OrganizationRepository? organizationRepository,
    UserRepository? userRepository,
  })  : _documentRepository = documentRepository ?? DocumentRepository(),
        _organizationRepository = organizationRepository ?? OrganizationRepository(),
        _userRepository = userRepository ?? UserRepository();

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<SchoolModel> get schools => _schools;
  SchoolModel? get selectedSchool => _selectedSchool;
  
  /// Get user name from cache, returns userId if not found
  String getUserName(String userId) => _userNameCache[userId] ?? userId;

  List<DocumentStats> get stats {
    final filteredStats = <DocumentStats>[];
    
    for (var doc in _documents) {
      var requests = _requestsCache[doc.id] ?? [];
      
      // Filter requests by school if selected
      if (_selectedSchool != null) {
        requests = requests.where((r) => r.schoolId == _selectedSchool!.id).toList();
      }
      
      // Only include document if it has relevant requests (or if looking at 'All' and it exists)
      // Actually, we usually want to show the document even if 0 requests for specific school? 
      // Maybe not. If I sent a doc ONLY to School A, and I filter by School B, it should probably be hidden or show 0/0.
      // Let's show it with 0/0 if no requests match.
      
      filteredStats.add(DocumentStats(document: doc, requests: requests));
    }
    return filteredStats;
  }

  Future<void> init(String organizationId) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Get Schools for filter
      _schools = await _organizationRepository.getDayhomesStream(organizationId).first;
      
      // 2. Listen to Documents
      _docSubscription?.cancel();
      _docSubscription = _documentRepository.getDocumentsByOrgStream(organizationId).listen(
        (docs) {
          _documents = docs;
          _subscribeToRequestsForDocs(docs);
          _isLoading = false;
          notifyListeners();
        },
        onError: (e) {
          _error = e.toString();
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void _subscribeToRequestsForDocs(List<DocumentModel> docs) {
    // Determine which docs need new subscriptions
    for (var doc in docs) {
      if (!_requestSubscriptions.containsKey(doc.id)) {
        _requestSubscriptions[doc.id] = _documentRepository
            .getSignatureRequestsForDocumentStream(doc.id)
            .listen((requests) async {
              _requestsCache[doc.id] = requests;
              
              // Fetch user names for any new userIds
              for (var req in requests) {
                if (!_userNameCache.containsKey(req.userId)) {
                  _fetchUserName(req.userId);
                }
              }
              
              notifyListeners();
            });
      }
    }
    
    // Cleanup old subscriptions (optional, if docs are deleted)
    // For now, keeping simple.
  }
  
  /// Fetch and cache user name for a given userId
  Future<void> _fetchUserName(String userId) async {
    try {
      final user = await _userRepository.getUserById(userId);
      if (user != null) {
        // Use name if available, fallback to email or username
        _userNameCache[userId] = user.name ?? user.email;
        notifyListeners();
      }
    } catch (e) {
      // Keep userId as fallback on error
      debugPrint('Failed to fetch user name for $userId: $e');
    }
  }

  void setSelectedSchool(SchoolModel? school) {
    _selectedSchool = school;
    notifyListeners();
  }

  @override
  void dispose() {
    _docSubscription?.cancel();
    for (var sub in _requestSubscriptions.values) {
      sub.cancel();
    }
    super.dispose();
  }
}
