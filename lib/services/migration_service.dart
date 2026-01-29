import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../constants/firestore_collections.dart';

/// Migration utility to sync existing user-school assignments to subcollections.
/// 
/// This is needed because users assigned before the subcollection sync was added
/// only have their schoolIds updated, but no document exists in
/// schools/{schoolId}/students or schools/{schoolId}/teachers.
/// 
/// Usage: Call `MigrationService.syncAllAssignments()` once from a button or
/// on app startup (with a flag to prevent re-running).
class MigrationService {
  final FirebaseFirestore _firestore;

  MigrationService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Sync all existing user-school assignments to subcollections.
  /// Returns the number of documents synced.
  Future<int> syncAllAssignments() async {
    int syncedCount = 0;

    // Get all users
    final usersSnapshot = await _firestore
        .collection(FirestoreCollections.users)
        .get();

    for (final userDoc in usersSnapshot.docs) {
      final userData = userDoc.data();
      final userId = userDoc.id;
      final schoolIds = (userData['schoolIds'] as List<dynamic>?)?.cast<String>() ?? [];
      final role = userData['role'] as String?;

      if (schoolIds.isEmpty) continue;

      final subcollection = role == 'teacher' ? 'teachers' : 'students';

      for (final schoolId in schoolIds) {
        // Check if document already exists in subcollection
        final existingDoc = await _firestore
            .collection(FirestoreCollections.schools)
            .doc(schoolId)
            .collection(subcollection)
            .doc(userId)
            .get();

        if (!existingDoc.exists) {
          // Create the document in the subcollection
          await _firestore
              .collection(FirestoreCollections.schools)
              .doc(schoolId)
              .collection(subcollection)
              .doc(userId)
              .set({
            'uid': userId,
            'email': userData['email'],
            'username': userData['username'],
            'name': userData['name'],
            'role': userData['role'],
            'avatarUrl': userData['avatarUrl'],
            'organizationId': userData['organizationId'],
            'createdAt': userData['createdAt'],
            // For students, also copy display fields if they exist
            if (role == 'student') ...{
              'todayStatus': userData['todayStatus'],
              'todayDate': userData['todayDate'],
              'todayDisplayStatus': userData['todayDisplayStatus'],
            },
          });

          syncedCount++;
          debugPrint('Synced $role $userId to school $schoolId');
        }
      }
    }

    debugPrint('Migration complete. Synced $syncedCount documents.');
    return syncedCount;
  }
}
