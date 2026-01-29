import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/school_model.dart';

/// Repository for platform-wide operations (Super Admin only).
/// Provides queries across all schools.
class PlatformRepository {
  final FirebaseFirestore _firestore;

  PlatformRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ============================================================================
  // SCHOOL QUERIES
  // ============================================================================

  /// Stream of all schools.
  Stream<List<SchoolModel>> getSchoolsStream() {
    return _firestore
        .collection('schools')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SchoolModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Get a single school by ID.
  Future<SchoolModel?> getSchoolById(String schoolId) async {
    final doc = await _firestore.collection('schools').doc(schoolId).get();
    if (doc.exists && doc.data() != null) {
      return SchoolModel.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  /// Get school count.
  Future<int> getSchoolCount() async {
    final snapshot = await _firestore.collection('schools').count().get();
    return snapshot.count ?? 0;
  }

  /// Get member count for a school.
  Future<int> getMemberCount(String schoolId) async {
    final snapshot = await _firestore
        .collection('schools')
        .doc(schoolId)
        .collection('members')
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  /// Get student count for a school.
  Future<int> getStudentCount(String schoolId) async {
    // Optimized: Query users collection instead of subcollection
    final snapshot = await _firestore
        .collection('users')
        .where('schoolIds', arrayContains: schoolId)
        .where('role', isEqualTo: 'student')
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  // ============================================================================
  // SCHOOL MANAGEMENT
  // ============================================================================

  /// Update school subscription status.
  Future<void> updateSchoolSubscription(String schoolId, String status) async {
    await _firestore.collection('schools').doc(schoolId).update({
      'subscription.status': status,
    });
  }

  /// Delete a school (soft delete by updating status).
  Future<void> deleteSchool(String schoolId) async {
    await updateSchoolSubscription(schoolId, 'deleted');
    await _firestore.collection('schools').doc(schoolId).update({
      'deletedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Permanently delete a school and all subcollections.
  /// Use with caution - this is destructive.
  Future<void> permanentlyDeleteSchool(String schoolId) async {
    final schoolRef = _firestore.collection('schools').doc(schoolId);
    
    // Delete members subcollection
    final members = await schoolRef.collection('members').get();
    for (final doc in members.docs) {
      await doc.reference.delete();
    }
    
    // Delete students subcollection
    final students = await schoolRef.collection('students').get();
    for (final doc in students.docs) {
      await doc.reference.delete();
    }
    
    // Delete dailyStatus subcollection
    final statuses = await schoolRef.collection('dailyStatus').get();
    for (final doc in statuses.docs) {
      await doc.reference.delete();
    }
    
    // Delete school document
    await schoolRef.delete();
  }

  // ============================================================================
  // PLATFORM STATS
  // ============================================================================

  /// Get basic platform statistics.
  Future<PlatformStats> getPlatformStats() async {
    final schools = await _firestore.collection('schools').get();
    
    int totalSchools = schools.docs.length;
    int activeSchools = 0;
    int trialSchools = 0;
    int suspendedSchools = 0;
    
    for (final doc in schools.docs) {
      final status = doc.data()['subscription']?['status'];
      switch (status) {
        case 'active':
          activeSchools++;
          break;
        case 'trial':
          trialSchools++;
          break;
        case 'suspended':
        case 'canceled':
          suspendedSchools++;
          break;
      }
    }
    
    return PlatformStats(
      totalSchools: totalSchools,
      activeSchools: activeSchools,
      trialSchools: trialSchools,
      suspendedSchools: suspendedSchools,
    );
  }
}

/// Platform-wide statistics.
class PlatformStats {
  final int totalSchools;
  final int activeSchools;
  final int trialSchools;
  final int suspendedSchools;

  PlatformStats({
    required this.totalSchools,
    required this.activeSchools,
    required this.trialSchools,
    required this.suspendedSchools,
  });
}
