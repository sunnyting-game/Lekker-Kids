import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/user_model.dart';
import '../../models/school_model.dart'; 
import '../../repositories/document_repository.dart';
import '../../repositories/user_repository.dart';
import '../../repositories/organization_repository.dart';

class SendDocumentViewModel extends ChangeNotifier {
  final DocumentRepository _documentRepository;
  final UserRepository _userRepository;
  final OrganizationRepository _organizationRepository;

  SendDocumentViewModel({
    DocumentRepository? documentRepository,
    UserRepository? userRepository,
    OrganizationRepository? organizationRepository,
  })  : _documentRepository = documentRepository ?? DocumentRepository(),
        _userRepository = userRepository ?? UserRepository(),
        _organizationRepository = organizationRepository ?? OrganizationRepository();

  // State
  PlatformFile? _selectedFile;
  String _documentTitle = '';
  
  bool _isLoading = false;
  String? _error;
  
  // Scoping
  String? _organizationId;
  List<SchoolModel> _schools = [];
  SchoolModel? _selectedSchool; 
  
  // Users
  List<UserModel> _allUsers = [];
  List<UserModel> _filteredUsers = []; 
  Set<String> _selectedUserIds = {};

  // Getters
  PlatformFile? get selectedFile => _selectedFile;
  String? get selectedFileName => _selectedFile?.name;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<SchoolModel> get schools => _schools;
  SchoolModel? get selectedSchool => _selectedSchool;
  List<UserModel> get filteredUsers => _filteredUsers;
  Set<String> get selectedUserIds => _selectedUserIds;
  int get selectedCount => _selectedUserIds.length;
  bool get isAllSelected => _filteredUsers.isNotEmpty && _selectedUserIds.length == _filteredUsers.length;

  // Initialization
  Future<void> init(String organizationId) async {
    _organizationId = organizationId;
    _setLoading(true);
    try {
      // 1. Fetch Schools
      final schoolsStream = _organizationRepository.getDayhomesStream(organizationId);
      _schools = await schoolsStream.first;

      // 2. Fetch All Organization Users
      final teachers = await _userRepository.getTeachersStreamByOrg(organizationId).first;
      final students = await _userRepository.getStudentsStreamByOrg(organizationId).first;
      
      _allUsers = [...teachers, ...students];
      _applyFilters();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // File Picking
  Future<void> pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: kIsWeb, // Important for Web
      );

      if (result != null && result.files.isNotEmpty) {
        _selectedFile = result.files.first;
        
        // Default title to filename without extension
        if (_documentTitle.isEmpty && _selectedFile!.name.isNotEmpty) {
          _documentTitle = _selectedFile!.name.replaceAll('.pdf', '');
        }
        _error = null;
        notifyListeners();
      }
    } catch (e) {
      _error = "Failed to pick file: $e";
      notifyListeners();
    }
  }

  void setTitle(String value) {
    _documentTitle = value;
    notifyListeners();
  }

  // Filter Logic
  void setSelectedSchool(SchoolModel? school) {
    _selectedSchool = school;
    _selectedUserIds.clear(); 
    _applyFilters();
  }

  void _applyFilters() {
    final school = _selectedSchool;
    if (school == null) {
      // Show all users in Organization
      _filteredUsers = List<UserModel>.from(_allUsers);
    } else {
      // Show users belonging to this school
      _filteredUsers = _allUsers.where((u) => u.schoolIds.contains(school.id)).toList();
    }
    notifyListeners();
  }

  // Selection Logic
  void toggleUser(String userId) {
    if (_selectedUserIds.contains(userId)) {
      _selectedUserIds.remove(userId);
    } else {
      _selectedUserIds.add(userId);
    }
    notifyListeners();
  }

  void toggleSelectAll() {
    if (isAllSelected) {
      _selectedUserIds.clear();
    } else {
      _selectedUserIds = _filteredUsers.map((u) => u.uid).toSet();
    }
    notifyListeners();
  }

  // Sending Actions
  Future<bool> sendDocument(String adminName) async {
    if (_selectedFile == null) {
      _error = "Please select a PDF file.";
      notifyListeners();
      return false;
    }
    if (_documentTitle.isEmpty) {
      _error = "Please enter a document title.";
      notifyListeners();
      return false;
    }
    if (_selectedUserIds.isEmpty) {
      _error = "Please select at least one recipient.";
      notifyListeners();
      return false;
    }

    _setLoading(true);
    try {
      // 1. Upload Document
      final doc = await _documentRepository.uploadAndCreate(
        file: _selectedFile!,
        title: _documentTitle,
        organizationId: _organizationId!,
        uploadedBy: adminName,
      );

      // 2. Assign to Users
      await _documentRepository.assignToUsers(
        documentId: doc.id,
        userIds: _selectedUserIds.toList(),
        schoolId: _selectedSchool?.id ?? 'organization', 
      );

      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
