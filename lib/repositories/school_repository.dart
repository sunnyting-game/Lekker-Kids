import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/school_model.dart';
import '../models/school_member_model.dart';
import '../models/user_model.dart';
import 'tenant_aware_repository.dart';

/// Repository for school-scoped data operations.
/// All queries are automatically scoped to the current school context.
class SchoolRepository extends TenantAwareRepository {
  SchoolRepository({
    super.firestore,
    super.storage,
  });

  // ============================================================================
  // SCHOOL INFO
  // ============================================================================

  /// Get the current school.
  Future<SchoolModel?> getCurrentSchool() async {
    final doc = await schoolRef.get();
    if (doc.exists && doc.data() != null) {
      return SchoolModel.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  /// Stream of the current school.
  Stream<SchoolModel?> getCurrentSchoolStream() {
    return schoolRef.snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return SchoolModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    });
  }

  // ============================================================================
  // MEMBERS (Teachers, Parents, Admins)
  // ============================================================================

  /// Stream of all members in the current school.
  Stream<List<SchoolMemberModel>> getMembersStream() {
    return membersCollection
        .orderBy('invitedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SchoolMemberModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Stream of members by role.
  Stream<List<SchoolMemberModel>> getMembersByRoleStream(MemberRole role) {
    return membersCollection
        .where('role', isEqualTo: role.name)
        .orderBy('invitedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SchoolMemberModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Get teachers stream.
  Stream<List<SchoolMemberModel>> getTeachersStream() {
    return getMembersByRoleStream(MemberRole.teacher);
  }

  /// Get parents stream.
  Stream<List<SchoolMemberModel>> getParentsStream() {
    return getMembersByRoleStream(MemberRole.parent);
  }

  /// Get admins stream.
  Stream<List<SchoolMemberModel>> getAdminsStream() {
    return getMembersByRoleStream(MemberRole.admin);
  }

  // ============================================================================
  // STUDENTS (school-scoped)
  // ============================================================================

  /// Stream of all students in the current school.
  Stream<List<UserModel>> getStudentsStream() {
    return studentsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Get a student by ID.
  Future<UserModel?> getStudentById(String studentId) async {
    final doc = await studentsCollection.doc(studentId).get();
    if (doc.exists && doc.data() != null) {
      return UserModel.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  /// Stream of a single student.
  Stream<UserModel?> getStudentStream(String studentId) {
    return studentsCollection.doc(studentId).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    });
  }

  /// Add a student to the school.
  Future<void> addStudent(UserModel student) async {
    await studentsCollection.doc(student.uid).set(student.toMap());
  }

  /// Update a student.
  Future<void> updateStudent(String studentId, Map<String, dynamic> data) async {
    await studentsCollection.doc(studentId).update(data);
  }

  // ============================================================================
  // DAILY STATUS (school-scoped)
  // ============================================================================

  /// Get daily status document reference.
  DocumentReference<Map<String, dynamic>> getDailyStatusRef(
      String studentId, String date) {
    return dailyStatusCollection.doc('${studentId}_$date');
  }

  /// Get daily status for a student.
  Future<Map<String, dynamic>?> getDailyStatus(
      String studentId, String date) async {
    final doc = await getDailyStatusRef(studentId, date).get();
    return doc.data();
  }

  /// Stream of daily status.
  Stream<Map<String, dynamic>?> getDailyStatusStream(
      String studentId, String date) {
    return getDailyStatusRef(studentId, date).snapshots().map((doc) => doc.data());
  }

  /// Update daily status.
  Future<void> updateDailyStatus(
      String studentId, String date, Map<String, dynamic> data) async {
    await getDailyStatusRef(studentId, date).set(data, SetOptions(merge: true));
  }

  // ============================================================================
  // ATOMIC OPERATIONS (for student status updates)
  // ============================================================================

  /// Atomic check-in: Updates both student and dailyStatus.
  Future<void> checkInStudent(String studentId, String date) async {
    final batch = firestore.batch();
    
    // Update student status
    batch.update(studentsCollection.doc(studentId), {
      'todayStatus': 'CheckedIn',
      'todayDate': date,
    });
    
    // Update daily status
    batch.set(getDailyStatusRef(studentId, date), {
      'studentId': studentId,
      'date': date,
      'checkInTime': FieldValue.serverTimestamp(),
      'status': 'CheckedIn',
    }, SetOptions(merge: true));
    
    await batch.commit();
  }

  /// Atomic check-out.
  Future<void> checkOutStudent(String studentId, String date) async {
    final batch = firestore.batch();
    
    batch.update(studentsCollection.doc(studentId), {
      'todayStatus': 'CheckedOut',
      'todayDate': date,
    });
    
    batch.set(getDailyStatusRef(studentId, date), {
      'checkOutTime': FieldValue.serverTimestamp(),
      'status': 'CheckedOut',
    }, SetOptions(merge: true));
    
    await batch.commit();
  }

  /// Mark student as absent.
  Future<void> markAbsent(String studentId, String date) async {
    final batch = firestore.batch();
    
    batch.update(studentsCollection.doc(studentId), {
      'todayStatus': 'Absent',
      'todayDate': date,
      'todayDisplayStatus.isAbsent': true,
    });
    
    batch.set(getDailyStatusRef(studentId, date), {
      'status': 'Absent',
      'isAbsent': true,
    }, SetOptions(merge: true));
    
    await batch.commit();
  }

  /// Toggle meal status.
  Future<void> toggleMealStatus(String studentId, String date, bool newValue) async {
    final batch = firestore.batch();
    
    batch.update(studentsCollection.doc(studentId), {
      'todayDisplayStatus.mealStatus': newValue,
    });
    
    batch.set(getDailyStatusRef(studentId, date), {
      'mealStatus': newValue,
    }, SetOptions(merge: true));
    
    await batch.commit();
  }

  /// Toggle toilet status.
  Future<void> toggleToiletStatus(String studentId, String date, bool newValue) async {
    final batch = firestore.batch();
    
    batch.update(studentsCollection.doc(studentId), {
      'todayDisplayStatus.toiletStatus': newValue,
    });
    
    batch.set(getDailyStatusRef(studentId, date), {
      'toiletStatus': newValue,
    }, SetOptions(merge: true));
    
    await batch.commit();
  }

  /// Toggle sleep status.
  Future<void> toggleSleepStatus(String studentId, String date, bool newValue) async {
    final batch = firestore.batch();
    
    batch.update(studentsCollection.doc(studentId), {
      'todayDisplayStatus.sleepStatus': newValue,
    });
    
    batch.set(getDailyStatusRef(studentId, date), {
      'sleepStatus': newValue,
    }, SetOptions(merge: true));
    
    await batch.commit();
  }
}
