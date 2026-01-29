import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/firestore_collections.dart';
import '../models/organization_model.dart';
import '../models/school_model.dart';

/// Repository for Organization and Dayhome (School) operations.
class OrganizationRepository {
  final FirebaseFirestore _firestore;

  OrganizationRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ============================================================================
  // ORGANIZATION QUERIES
  // ============================================================================

  /// Stream of all organizations (for Super Admin).
  Stream<List<OrganizationModel>> getOrganizationsStream() {
    return _firestore
        .collection(FirestoreCollections.organizations)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => OrganizationModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Get a single organization by ID.
  Future<OrganizationModel?> getOrganizationById(String orgId) async {
    final doc = await _firestore
        .collection(FirestoreCollections.organizations)
        .doc(orgId)
        .get();
    if (doc.exists && doc.data() != null) {
      return OrganizationModel.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  // ============================================================================
  // DAYHOME (SCHOOL) QUERIES
  // ============================================================================

  /// Stream of Dayhomes (Schools) for a specific organization.
  Stream<List<SchoolModel>> getDayhomesStream(String organizationId) {
    return _firestore
        .collection(FirestoreCollections.schools)
        .where('organizationId', isEqualTo: organizationId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SchoolModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Get count of Dayhomes in an Organization.
  Future<int> getDayhomeCount(String organizationId) async {
    final snapshot = await _firestore
        .collection(FirestoreCollections.schools)
        .where('organizationId', isEqualTo: organizationId)
        .count()
        .get();
    return snapshot.count ?? 0;
  }
}
