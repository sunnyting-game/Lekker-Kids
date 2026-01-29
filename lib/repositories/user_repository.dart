import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/firestore_collections.dart';
import '../models/photo_item.dart';
import '../models/user_model.dart';

/// Repository for user-related operations
/// Handles all Firebase Storage and Firestore operations for user data
class UserRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final ImagePicker _imagePicker;

  UserRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    ImagePicker? imagePicker,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance,
        _imagePicker = imagePicker ?? ImagePicker();

  // ============================================================================
  // USER LIST QUERIES (for Admin pages)
  // ============================================================================

  /// Stream of all teachers, ordered by creation date (newest first).
  Stream<List<UserModel>> getTeachersStream() {
    return _firestore
        .collection(FirestoreCollections.users)
        .where('role', isEqualTo: 'teacher')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Stream of all students, ordered by creation date (newest first).
  Stream<List<UserModel>> getStudentsStream() {
    return _firestore
        .collection(FirestoreCollections.users)
        .where('role', isEqualTo: 'student')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Stream of teachers for a specific organization.
  Stream<List<UserModel>> getTeachersStreamByOrg(String organizationId) {
    return _firestore
        .collection(FirestoreCollections.users)
        .where('role', isEqualTo: 'teacher')
        .where('organizationId', isEqualTo: organizationId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Stream of students for a specific organization.
  Stream<List<UserModel>> getStudentsStreamByOrg(String organizationId) {
    return _firestore
        .collection(FirestoreCollections.users)
        .where('role', isEqualTo: 'student')
        .where('organizationId', isEqualTo: organizationId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Get a single user by UID.
  Future<UserModel?> getUserById(String uid) async {
    final doc = await _firestore
        .collection(FirestoreCollections.users)
        .doc(uid)
        .get();
    if (doc.exists && doc.data() != null) {
      return UserModel.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  // ============================================================================
  // BANNER & AVATAR OPERATIONS
  // ============================================================================

  /// Get banner image URL from Firestore
  /// Returns null if no banner image exists
  /// Throws exception on error
  Future<String?> getBannerImageUrl(String userId) async {
    try {
      final doc = await _firestore
          .collection(FirestoreCollections.users)
          .doc(userId)
          .get();

      if (doc.exists && doc.data()?['bannerImage'] != null) {
        return doc.data()!['bannerImage'] as String;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to load banner image: $e');
    }
  }

  /// Pick and upload banner image
  /// Returns download URL on success
  /// Throws exception on error
  Future<String> uploadBannerImage(String userId) async {
    try {
      // Pick image from gallery
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image == null) {
        throw Exception('No image selected');
      }

      // Read image as bytes for cross-platform compatibility
      final bytes = await image.readAsBytes();

      // Upload to Firebase Storage
      final storageRef = _storage
          .ref()
          .child(FirestoreCollections.banners)
          .child('$userId.jpg');

      // Use putData instead of putFile for cross-platform support
      final uploadTask = await storageRef.putData(bytes);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      // Save URL to Firestore
      await _firestore
          .collection(FirestoreCollections.users)
          .doc(userId)
          .update({'bannerImage': downloadUrl});

      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload banner image: $e');
    }
  }

  /// Update user's avatar URL in Firestore
  Future<void> updateAvatarUrl(String userId, String avatarUrl) async {
    try {
      await _firestore
          .collection(FirestoreCollections.users)
          .doc(userId)
          .update({'avatarUrl': avatarUrl});
    } catch (e) {
      throw Exception('Failed to update avatar URL: $e');
    }
  }

  /// Get photos stream for a specific student and date
  /// Returns a stream of PhotoItem list, transforming raw Firestore data
  /// Returns empty list if document doesn't exist, has no photos, or on parsing error
  Stream<List<PhotoItem>> getPhotosStream(String studentId, String date) {
    final docId = '${studentId}_$date';
    return _firestore
        .collection(FirestoreCollections.dailyStatus)
        .doc(docId)
        .snapshots()
        .map((snapshot) {
          try {
            // Document doesn't exist
            if (!snapshot.exists) return <PhotoItem>[];
            
            // Get photos array from document
            final data = snapshot.data();
            final photos = data?['photos'] as List<dynamic>? ?? [];
            
            // Transform each photo map into PhotoItem
            return photos
                .map((photo) => PhotoItem.fromMap(photo as Map<String, dynamic>))
                .toList();
          } catch (e) {
            // If there's any parsing error, return empty list instead of failing
            return <PhotoItem>[];
          }
        });
  }

  // ============================================================================
  // SCHOOL ASSIGNMENT OPERATIONS
  // ============================================================================

  /// Add a user to a school (dayhome).
  /// Updates the user's schoolIds array AND syncs to the school's subcollection.
  Future<void> addUserToSchool(String userId, String schoolId) async {
    // Get the user data first
    final userDoc = await _firestore
        .collection(FirestoreCollections.users)
        .doc(userId)
        .get();

    if (!userDoc.exists) {
      throw Exception('User not found');
    }

    final userData = userDoc.data()!;
    final role = userData['role'] as String?;

    // Use a batch to update both locations atomically
    final batch = _firestore.batch();

    // 1. Update user's schoolIds array
    batch.update(
      _firestore.collection(FirestoreCollections.users).doc(userId),
      {'schoolIds': FieldValue.arrayUnion([schoolId])},
    );

    // 2. Copy user data to the appropriate school subcollection
    final subcollection = role == 'teacher' ? 'teachers' : 'students';
    final schoolUserRef = _firestore
        .collection(FirestoreCollections.schools)
        .doc(schoolId)
        .collection(subcollection)
        .doc(userId);

    // Copy relevant user fields to the subcollection
    batch.set(schoolUserRef, {
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

    await batch.commit();
  }

  /// Remove a user from a school (dayhome).
  /// Updates the user's schoolIds array AND removes from the school's subcollection.
  Future<void> removeUserFromSchool(String userId, String schoolId) async {
    // Get user role to know which subcollection to remove from
    final userDoc = await _firestore
        .collection(FirestoreCollections.users)
        .doc(userId)
        .get();

    final role = userDoc.data()?['role'] as String? ?? 'student';

    // Use a batch to update both locations atomically
    final batch = _firestore.batch();

    // 1. Remove from user's schoolIds array
    batch.update(
      _firestore.collection(FirestoreCollections.users).doc(userId),
      {'schoolIds': FieldValue.arrayRemove([schoolId])},
    );

    // 2. Delete from school's subcollection
    final subcollection = role == 'teacher' ? 'teachers' : 'students';
    final schoolUserRef = _firestore
        .collection(FirestoreCollections.schools)
        .doc(schoolId)
        .collection(subcollection)
        .doc(userId);

    batch.delete(schoolUserRef);

    await batch.commit();
  }
}
