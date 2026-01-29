import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import 'package:path/path.dart' as path;
import '../repositories/student_repository.dart';
import '../constants/firestore_collections.dart';


/// Abstract interface for photo service
abstract class PhotoService {
  Future<String> uploadStudentPhoto({
    required XFile photoFile,
    required String studentId,
    required String date,
    required String teacherId,
  });

  Future<void> deletePhoto({
    required String photoUrl,
    required String studentId,
    required String date,
  });

  Stream<Map<String, List<Map<String, dynamic>>>> getPhotosByDateStream({
    required String studentId,
    required int daysBack,
  });
  
  Future<void> deleteOldPhotos({
    required String studentId,
    required int daysToKeep,
  });
}

class FirebasePhotoService implements PhotoService {
  final FirebaseStorage _storage;
  final FirebaseFirestore _firestore;
  final StudentRepository _repository;

  FirebasePhotoService({
    FirebaseStorage? storage,
    FirebaseFirestore? firestore,
    StudentRepository? repository,
  })  : _storage = storage ?? FirebaseStorage.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _repository = repository ?? StudentRepository();

  // Maximum file size: 5MB
  static const int maxFileSizeBytes = 5 * 1024 * 1024;

  // Upload photo to Firebase Storage and save reference to Firestore
  @override
  Future<String> uploadStudentPhoto({
    required XFile photoFile,
    required String studentId,
    required String date,
    required String teacherId,
  }) async {
    try {
      debugPrint('📸 Starting photo upload for student: $studentId, date: $date');
      
      // Generate unique filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = path.extension(photoFile.path).isEmpty ? '.jpg' : path.extension(photoFile.path);
      final filename = '$timestamp$extension';
      final storagePath = 'student_photos/$studentId/$date/$filename';
      debugPrint('☁️ Uploading to Storage: $storagePath');
      final ref = _storage.ref().child(storagePath);

      if (kIsWeb) {
        // WEB: Upload bytes directly
        debugPrint('🌐 Web platform detected');
        final bytes = await photoFile.readAsBytes();
        
        // Check file size
        final fileSize = bytes.length;
        debugPrint('📏 File size: ${fileSize / 1024} KB');
        if (fileSize > maxFileSizeBytes) {
          throw Exception('File size exceeds 5MB limit');
        }

        // Upload bytes with metadata
        final metadata = SettableMetadata(
          contentType: photoFile.mimeType ?? 'image/jpeg',
        );
        await ref.putData(bytes, metadata);
      } else {
        // MOBILE: Compress and upload file
        debugPrint('📱 Mobile platform detected');
        final file = File(photoFile.path);
        
        debugPrint('🗜️ Compressing image...');
        final compressedFile = await _compressImage(file);
        debugPrint('✅ Image compressed');
        
        // Check file size
        final fileSize = await compressedFile.length();
        debugPrint('📏 Compressed file size: ${fileSize / 1024} KB');
        if (fileSize > maxFileSizeBytes) {
          throw Exception('File size exceeds 5MB limit');
        }

        // Upload file
        await ref.putFile(compressedFile);
      }
      
      debugPrint('✅ Upload to Storage complete');
      
      // Get download URL
      final downloadUrl = await ref.getDownloadURL();
      debugPrint('🔗 Download URL obtained: $downloadUrl');

      // Save photo reference to Firestore
      debugPrint('💾 Saving photo reference to Firestore...');
      await _savePhotoReference(
        studentId: studentId,
        date: date,
        url: downloadUrl,
        uploadedBy: teacherId,
        timestamp: DateTime.now(),
      );
      debugPrint('✅ Photo reference saved to Firestore');

      // Sync photo count to users collection for denormalized display
      debugPrint('📊 Syncing photo count...');
      await _repository.incrementPhotoCount(studentId, date);
      debugPrint('✅ Photo count synced');

      return downloadUrl;
    } catch (e) {
      debugPrint('❌ Error uploading photo: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  // Compress image to reduce file size (Mobile only)
  Future<File> _compressImage(File file) async {
    try {
      final filePath = file.absolute.path;
      final lastIndex = filePath.lastIndexOf('.');
      final outPath = '${filePath.substring(0, lastIndex)}_compressed.jpg';

      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        outPath,
        quality: 70,
        minWidth: 1024,
        minHeight: 1024,
      );

      return result != null ? File(result.path) : file;
    } catch (e) {
      debugPrint('Error compressing image: $e');
      return file; // Return original if compression fails
    }
  }

  // Save photo reference to Firestore dailyStatus document
  Future<void> _savePhotoReference({
    required String studentId,
    required String date,
    required String url,
    required String uploadedBy,
    required DateTime timestamp,
  }) async {
    final docId = '${studentId}_$date';
    
    final photoData = {
      'url': url,
      'timestamp': Timestamp.fromDate(timestamp),
      'uploadedBy': uploadedBy,
      'studentId': studentId,
    };

    await _firestore.collection(FirestoreCollections.dailyStatus).doc(docId).set({
      'studentId': studentId,
      'date': date,
      'photos': FieldValue.arrayUnion([photoData]),
    }, SetOptions(merge: true));
  }

  // Delete photo from Storage and Firestore
  @override
  Future<void> deletePhoto({
    required String photoUrl,
    required String studentId,
    required String date,
  }) async {
    try {
      // Delete from Storage
      final ref = _storage.refFromURL(photoUrl);
      await ref.delete();

      // Remove from Firestore
      final docId = '${studentId}_$date';
      final doc = await _firestore
          .collection(FirestoreCollections.dailyStatus)
          .doc(docId)
          .get();
      
      if (doc.exists) {
        final data = doc.data()!;
        final photos = List<Map<String, dynamic>>.from(data['photos'] ?? []);
        photos.removeWhere((photo) => photo['url'] == photoUrl);
        
        await _firestore
            .collection(FirestoreCollections.dailyStatus)
            .doc(docId)
            .update({
          'photos': photos,
        });

        // Decrement photo count in users collection
        await _repository.decrementPhotoCount(studentId, date);
      }
    } catch (e) {
      debugPrint('Error deleting photo: $e');
      rethrow;
    }
  }

  // Get photos for a student within a date range (for album feature)
  @override
  Stream<Map<String, List<Map<String, dynamic>>>> getPhotosByDateStream({
    required String studentId,
    required int daysBack,
  }) {
    final now = DateTime.now();
    final dates = List.generate(daysBack, (index) {
      final date = now.subtract(Duration(days: index));
      return _formatDate(date);
    });

    // Create a stream that combines all dailyStatus documents for the date range
    return Stream.fromFuture(_getPhotosForDates(studentId, dates));
  }

  Future<Map<String, List<Map<String, dynamic>>>> _getPhotosForDates(
    String studentId,
    List<String> dates,
  ) async {
    final Map<String, List<Map<String, dynamic>>> photosByDate = {};

    // Create parallel fetch tasks for all dates
    final futures = dates.map((date) async {
      final docId = '${studentId}_$date';
      final doc = await _firestore.collection(FirestoreCollections.dailyStatus).doc(docId).get();

      if (doc.exists) {
        final data = doc.data();
        if (data != null && data['photos'] != null) {
          final photos = List<Map<String, dynamic>>.from(data['photos'] ?? []);
          if (photos.isNotEmpty) {
            return MapEntry(date, photos);
          }
        }
      }
      return null;
    }).toList();

    // Execute all fetches in parallel
    final results = await Future.wait(futures);

    // Build the map from non-null results
    for (final result in results) {
      if (result != null) {
        photosByDate[result.key] = result.value;
      }
    }

    return photosByDate;
  }


  // Delete photos older than specified days (for Cloud Function)
  @override
  Future<void> deleteOldPhotos({
    required String studentId,
    required int daysToKeep,
  }) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
      
      // Query dailyStatus documents for this student
      final snapshot = await _firestore
          .collection(FirestoreCollections.dailyStatus)
          .where('studentId', isEqualTo: studentId)
          .get();

      for (final doc in snapshot.docs) {
        final date = doc.data()['date'] as String?;
        if (date != null) {
          final docDate = DateTime.parse(date);
          
          // If the document date is older than cutoff, delete photos
          if (docDate.isBefore(cutoffDate)) {
            final photos = List<Map<String, dynamic>>.from(
              doc.data()['photos'] ?? [],
            );

            // Delete each photo from storage
            for (final photo in photos) {
              final photoUrl = photo['url'] as String;
              try {
                final ref = _storage.refFromURL(photoUrl);
                await ref.delete();
              } catch (e) {
                debugPrint('Error deleting photo from storage: $e');
              }
            }

            // Remove the document or clear the photos array
            await doc.reference.delete();
          }
        }
      }
    } catch (e) {
      debugPrint('Error deleting old photos: $e');
      rethrow;
    }
  }

  // Helper to format date as YYYY-MM-DD
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
