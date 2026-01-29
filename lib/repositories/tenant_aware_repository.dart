import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Base class for repositories that need tenant (school) context.
/// Provides common functionality for scoping data access to a specific school.
abstract class TenantAwareRepository {
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;
  String? _schoolId;

  TenantAwareRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : firestore = firestore ?? FirebaseFirestore.instance,
        storage = storage ?? FirebaseStorage.instance;

  /// Set the current school context.
  /// Must be called before using school-scoped methods.
  void setSchoolContext(String schoolId) {
    _schoolId = schoolId;
  }

  /// Clear the school context.
  void clearSchoolContext() {
    _schoolId = null;
  }

  /// Get the current school ID.
  /// Throws if no school context is set.
  String get schoolId {
    if (_schoolId == null) {
      throw StateError('No school context set. Call setSchoolContext first.');
    }
    return _schoolId!;
  }

  /// Check if a school context is set.
  bool get hasSchoolContext => _schoolId != null;

  // ============================================================================
  // COLLECTION REFERENCES (school-scoped)
  // ============================================================================

  /// Get reference to school document.
  DocumentReference<Map<String, dynamic>> get schoolRef =>
      firestore.collection('schools').doc(schoolId);

  /// Get reference to school's members collection.
  CollectionReference<Map<String, dynamic>> get membersCollection =>
      schoolRef.collection('members');

  /// Get reference to school's students collection.
  /// Students are stored as members with role='student'
  CollectionReference<Map<String, dynamic>> get studentsCollection =>
      schoolRef.collection('students');

  /// Get reference to school's dailyStatus collection.
  CollectionReference<Map<String, dynamic>> get dailyStatusCollection =>
      schoolRef.collection('dailyStatus');

  // ============================================================================
  // STORAGE PATHS (school-scoped)
  // ============================================================================

  /// Get storage path for school assets.
  String get schoolStoragePath => 'schools/$schoolId';

  /// Get storage path for student photos.
  String studentPhotosPath(String studentId, String date) =>
      '$schoolStoragePath/photos/$studentId/$date';

  /// Get storage path for student avatars.
  String studentAvatarPath(String studentId) =>
      '$schoolStoragePath/avatars/$studentId.jpg';

  /// Get storage path for banners.
  String bannerPath(String userId) =>
      '$schoolStoragePath/banners/$userId.jpg';
}
