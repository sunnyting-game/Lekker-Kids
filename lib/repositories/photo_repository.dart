import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/photo_item.dart';
import 'tenant_aware_repository.dart';

/// Repository for school-scoped photo operations.
class PhotoRepository extends TenantAwareRepository {
  PhotoRepository({
    super.firestore,
    super.storage,
  });

  // ============================================================================
  // PHOTO QUERIES
  // ============================================================================

  /// Get photos stream for a specific student and date.
  Stream<List<PhotoItem>> getPhotosStream(String studentId, String date) {
    final docRef = dailyStatusCollection.doc('${studentId}_$date');
    
    return docRef.snapshots().map((snapshot) {
      if (!snapshot.exists) return <PhotoItem>[];
      
      final photos = snapshot.data()?['photos'] as List<dynamic>? ?? [];
      return photos
          .map((photo) => PhotoItem.fromMap(photo as Map<String, dynamic>))
          .toList();
    });
  }

  /// Get photos for date range (for album view).
  Future<Map<String, List<PhotoItem>>> getPhotosByDateRange(
    String studentId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final startStr = _formatDate(startDate);
    final endStr = _formatDate(endDate);

    final snapshot = await dailyStatusCollection
        .where('studentId', isEqualTo: studentId)
        .where('date', isGreaterThanOrEqualTo: startStr)
        .where('date', isLessThanOrEqualTo: endStr)
        .get();

    final result = <String, List<PhotoItem>>{};
    
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final date = data['date'] as String?;
      final photos = data['photos'] as List<dynamic>? ?? [];
      
      if (date != null && photos.isNotEmpty) {
        result[date] = photos
            .map((p) => PhotoItem.fromMap(p as Map<String, dynamic>))
            .toList();
      }
    }
    
    return result;
  }

  // ============================================================================
  // PHOTO UPLOAD
  // ============================================================================

  /// Upload a photo for a student.
  Future<PhotoItem> uploadPhoto({
    required String studentId,
    required String date,
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    final timestamp = DateTime.now();
    final storagePath = '${studentPhotosPath(studentId, date)}/${timestamp.millisecondsSinceEpoch}_$fileName';
    
    // Upload to storage
    final ref = storage.ref().child(storagePath);
    await ref.putData(imageBytes);
    final url = await ref.getDownloadURL();
    
    // Create photo item
    final photo = PhotoItem(
      url: url,
      timestamp: timestamp,
      storagePath: storagePath,
    );
    
    // Add to Firestore
    final docRef = dailyStatusCollection.doc('${studentId}_$date');
    await docRef.set({
      'studentId': studentId,
      'date': date,
      'photos': FieldValue.arrayUnion([photo.toMap()]),
    }, SetOptions(merge: true));
    
    // Update photo count in student record
    await _incrementPhotoCount(studentId, date);
    
    return photo;
  }

  /// Delete a photo.
  Future<void> deletePhoto({
    required String studentId,
    required String date,
    required PhotoItem photo,
  }) async {
    // Delete from storage
    if (photo.storagePath != null) {
      try {
        await storage.ref().child(photo.storagePath!).delete();
      } catch (e) {
        // Storage path might not exist or be different format
      }
    }
    
    // Remove from Firestore array
    final docRef = dailyStatusCollection.doc('${studentId}_$date');
    await docRef.update({
      'photos': FieldValue.arrayRemove([photo.toMap()]),
    });
    
    // Update photo count
    await _decrementPhotoCount(studentId, date);
  }

  // ============================================================================
  // AVATAR OPERATIONS
  // ============================================================================

  /// Upload student avatar.
  Future<String> uploadAvatar({
    required String studentId,
    required Uint8List imageBytes,
  }) async {
    final path = studentAvatarPath(studentId);
    final ref = storage.ref().child(path);
    
    await ref.putData(imageBytes);
    final url = await ref.getDownloadURL();
    
    // Update student record
    await _updateStudentAvatar(studentId, url);
    
    return url;
  }

  // ============================================================================
  // PRIVATE HELPERS
  // ============================================================================

  Future<void> _incrementPhotoCount(String studentId, String date) async {
    final studentRef = schoolRef.collection('students').doc(studentId);
    await studentRef.update({
      'todayDisplayStatus.photosCount': FieldValue.increment(1),
    });
  }

  Future<void> _decrementPhotoCount(String studentId, String date) async {
    final studentRef = schoolRef.collection('students').doc(studentId);
    await studentRef.update({
      'todayDisplayStatus.photosCount': FieldValue.increment(-1),
    });
  }

  Future<void> _updateStudentAvatar(String studentId, String avatarUrl) async {
    final studentRef = schoolRef.collection('students').doc(studentId);
    await studentRef.update({'avatarUrl': avatarUrl});
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
