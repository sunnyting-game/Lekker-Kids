import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/daily_status.dart';
import '../repositories/student_repository.dart';

/// Service for student-related operations within a school context.
/// 
/// This service MUST have school context set before use.
/// Call `setSchoolContext(schoolId)` before any operations.
/// 
/// Usage:
/// ```dart
/// final service = StudentService();
/// service.setSchoolContext(schoolId); // Required before any operations
/// final students = service.getStudentsWithDisplayDataStream();
/// ```
class StudentService {
  final FirebaseFirestore _firestore;
  final StudentRepository _repository;
  String? _schoolId;

  StudentService({
    FirebaseFirestore? firestore,
    StudentRepository? repository,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _repository = repository ?? StudentRepository();

  /// Set the school context for all operations.
  /// Must be called before using any stream or operation methods.
  void setSchoolContext(String schoolId) {
    _schoolId = schoolId;
    _repository.setSchoolContext(schoolId);
  }

  /// Clear the school context.
  void clearSchoolContext() {
    _schoolId = null;
    _repository.clearSchoolContext();
  }

  /// Check if school context is set.
  bool get hasSchoolContext => _schoolId != null;

  /// Get the current school ID or throw if not set.
  String get _requiredSchoolId {
    if (_schoolId == null) {
      throw StateError('No school context set. Call setSchoolContext first.');
    }
    return _schoolId!;
  }

  // Get today's date in YYYY-MM-DD format
  String getTodayDate() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  // ============================================================================
  // SCHOOL-SCOPED QUERIES
  // All queries are now scoped to the current school's students subcollection
  // ============================================================================

  /// Get students stream with display data fields (school-scoped)
  /// Returns RAW data - ViewModels handle staleness check and sorting
  Stream<List<UserModel>> getStudentsWithDisplayDataStream() {
    return _firestore
        .collection('schools')
        .doc(_requiredSchoolId)
        .collection('students')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Stream of all students (school-scoped)
  /// Used by: AttendanceTab, other non-classroom views
  Stream<List<UserModel>> getStudentsStream() {
    return getStudentsWithDisplayDataStream();
  }

  /// Legacy: getStudentsWithTodayStatusStream (alias for backward compatibility)
  Stream<List<UserModel>> getStudentsWithTodayStatusStream() {
    return getStudentsWithDisplayDataStream();
  }

  /// Get daily status for a student on a specific date (school-scoped)
  Future<DailyStatus?> getDailyStatus(String studentId, String date) async {
    final docId = '${studentId}_$date';
    final doc = await _firestore
        .collection('schools')
        .doc(_requiredSchoolId)
        .collection('dailyStatus')
        .doc(docId)
        .get();

    if (doc.exists) {
      return DailyStatus.fromMap(doc.data()!);
    }
    return null;
  }

  /// Stream of daily status for a student on a specific date (school-scoped)
  /// Used by: HomeTab (student portal), detail views
  Stream<DailyStatus> getDailyStatusStream(String studentId, String date) {
    final docId = '${studentId}_$date';
    return _firestore
        .collection('schools')
        .doc(_requiredSchoolId)
        .collection('dailyStatus')
        .doc(docId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return DailyStatus.fromMap(doc.data()!);
      }
      // Return default status if document doesn't exist
      return DailyStatus(
        studentId: studentId,
        date: date,
      );
    });
  }

  // ============================================================================
  // ATOMIC OPERATIONS: Delegated to StudentRepository
  // ============================================================================

  /// Atomic check-in
  Future<void> checkInStudent(String studentId, String date) async {
    await _repository.checkInStudent(studentId, date);
  }

  /// Atomic check-out
  Future<void> checkOutStudent(String studentId, String date) async {
    await _repository.checkOutStudent(studentId, date);
  }

  /// Atomic mark absent
  Future<void> markAbsent(String studentId, String date) async {
    await _repository.markAbsent(studentId, date);
  }

  /// Atomic toggle meal status (updates both collections)
  Future<void> toggleMealStatus(String studentId, String date, bool currentValue) async {
    await _repository.toggleMealStatus(studentId, date, currentValue);
  }

  /// Atomic toggle toilet status (updates both collections)
  Future<void> toggleToiletStatus(String studentId, String date, bool currentValue) async {
    await _repository.toggleToiletStatus(studentId, date, currentValue);
  }

  /// Atomic toggle sleep status (updates both collections)
  Future<void> toggleSleepStatus(String studentId, String date, bool currentValue) async {
    await _repository.toggleSleepStatus(studentId, date, currentValue);
  }

  // ============================================================================
  // LEGACY: Direct dailyStatus operations (for backward compatibility)
  // ============================================================================

  /// Update or create daily status (legacy, consider using atomic methods)
  Future<void> updateDailyStatus(DailyStatus status) async {
    final docId = status.documentId;
    await _firestore
        .collection('schools')
        .doc(_requiredSchoolId)
        .collection('dailyStatus')
        .doc(docId)
        .set(status.toMap(), SetOptions(merge: true));
  }

  // ============================================================================
  // BATCH QUERIES
  // ============================================================================

  /// Fetch all daily statuses for a specific date (school-scoped)
  /// Used by: Admin attendance view to show all students for a date
  Future<List<DailyStatus>> getDailyStatusesForDate(String date) async {
    return _repository.getDailyStatusesForDate(date);
  }
}
