import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/today_display_status.dart';
import '../models/daily_status.dart';
import 'tenant_aware_repository.dart';

/// Repository for atomic student operations within a school context.
/// 
/// This repository MUST have school context set before use.
/// All operations are scoped to the current school's students subcollection.
/// 
/// Usage:
/// ```dart
/// final repo = StudentRepository();
/// repo.setSchoolContext(schoolId); // Required before any operations
/// await repo.checkInStudent(studentId, date);
/// ```
class StudentRepository extends TenantAwareRepository {
  StudentRepository({
    super.firestore,
    super.storage,
  });

  // ============================================================================
  // ATOMIC STATUS TOGGLES
  // Updates both school/students and school/dailyStatus in a single batch
  // ============================================================================

  /// Toggle meal status atomically
  Future<void> toggleMealStatus(String studentId, String date, bool currentValue) async {
    final newValue = !currentValue;
    final batch = firestore.batch();

    // Update school's students collection (denormalized)
    final studentRef = studentsCollection.doc(studentId);
    batch.update(studentRef, {
      'todayDisplayStatus.mealStatus': newValue,
      'todayDate': date,
    });

    // Update school's dailyStatus collection (historical)
    final statusRef = dailyStatusCollection.doc('${studentId}_$date');
    batch.set(statusRef, {
      'studentId': studentId,
      'date': date,
      'mealStatus': newValue,
    }, SetOptions(merge: true));

    await batch.commit();
  }

  /// Toggle toilet status atomically
  Future<void> toggleToiletStatus(String studentId, String date, bool currentValue) async {
    final newValue = !currentValue;
    final batch = firestore.batch();

    // Update school's students collection (denormalized)
    final studentRef = studentsCollection.doc(studentId);
    batch.update(studentRef, {
      'todayDisplayStatus.toiletStatus': newValue,
      'todayDate': date,
    });

    // Update school's dailyStatus collection (historical)
    final statusRef = dailyStatusCollection.doc('${studentId}_$date');
    batch.set(statusRef, {
      'studentId': studentId,
      'date': date,
      'toiletStatus': newValue,
    }, SetOptions(merge: true));

    await batch.commit();
  }

  /// Toggle sleep status atomically
  Future<void> toggleSleepStatus(String studentId, String date, bool currentValue) async {
    final newValue = !currentValue;
    final batch = firestore.batch();

    // Update school's students collection (denormalized)
    final studentRef = studentsCollection.doc(studentId);
    batch.update(studentRef, {
      'todayDisplayStatus.sleepStatus': newValue,
      'todayDate': date,
    });

    // Update school's dailyStatus collection (historical)
    final statusRef = dailyStatusCollection.doc('${studentId}_$date');
    batch.set(statusRef, {
      'studentId': studentId,
      'date': date,
      'sleepStatus': newValue,
    }, SetOptions(merge: true));

    await batch.commit();
  }

  // ============================================================================
  // PHOTO COUNT SYNC
  // Called by PhotoService after upload/delete
  // ============================================================================

  /// Increment photo count atomically
  Future<void> incrementPhotoCount(String studentId, String date) async {
    final studentRef = studentsCollection.doc(studentId);
    
    await firestore.runTransaction((transaction) async {
      final studentDoc = await transaction.get(studentRef);
      
      if (!studentDoc.exists) return;
      
      final data = studentDoc.data()!;
      final currentStatus = data['todayDisplayStatus'] as Map<String, dynamic>? ?? {};
      final currentCount = currentStatus['photosCount'] as int? ?? 0;
      
      transaction.update(studentRef, {
        'todayDisplayStatus.photosCount': currentCount + 1,
        'todayDate': date,
      });
    });
  }

  /// Decrement photo count atomically
  Future<void> decrementPhotoCount(String studentId, String date) async {
    final studentRef = studentsCollection.doc(studentId);
    
    await firestore.runTransaction((transaction) async {
      final studentDoc = await transaction.get(studentRef);
      
      if (!studentDoc.exists) return;
      
      final data = studentDoc.data()!;
      final currentStatus = data['todayDisplayStatus'] as Map<String, dynamic>? ?? {};
      final currentCount = currentStatus['photosCount'] as int? ?? 0;
      
      // Don't go below 0
      final newCount = currentCount > 0 ? currentCount - 1 : 0;
      
      transaction.update(studentRef, {
        'todayDisplayStatus.photosCount': newCount,
        'todayDate': date,
      });
    });
  }

  // ============================================================================
  // UNREAD MESSAGE FLAG SYNC
  // Called by ChatService after send/read
  // ============================================================================

  /// Set unread flag for a student (when student sends message to teacher)
  Future<void> setHasUnreadFromStudent(String studentId, bool hasUnread) async {
    await studentsCollection
        .doc(studentId)
        .update({'hasUnreadFromStudent': hasUnread});
  }

  // ============================================================================
  // ATTENDANCE STATUS SYNC
  // ============================================================================

  /// Atomic check-in: Updates both students AND dailyStatus with session tracking
  Future<void> checkInStudent(String studentId, String date) async {
    final now = DateTime.now();
    final statusRef = dailyStatusCollection.doc('${studentId}_$date');
    final studentRef = studentsCollection.doc(studentId);

    await firestore.runTransaction((transaction) async {
      // Read current dailyStatus
      final statusDoc = await transaction.get(statusRef);

      // Get existing sessions or start with empty list
      List<Map<String, dynamic>> sessions = [];
      if (statusDoc.exists) {
        final data = statusDoc.data()!;
        sessions = List<Map<String, dynamic>>.from(data['sessions'] ?? []);
      }

      // Add new session
      sessions.add({
        'checkIn': now.toIso8601String(),
        // checkOut is null, will be set on check-out
      });

      // Update dailyStatus with new session
      transaction.set(statusRef, {
        'studentId': studentId,
        'date': date,
        'attendance': true,
        'checkInTime': now.toIso8601String(), // Latest for UI
        'isAbsent': false,
        'sessions': sessions,
      }, SetOptions(merge: true));

      // Update student's denormalized status
      transaction.update(studentRef, {
        'todayStatus': 'CheckedIn',
        'todayDate': date,
        'todayDisplayStatus': TodayDisplayStatus.empty().toMap(),
      });
    });
  }

  /// Atomic check-out: Updates both students AND dailyStatus with session tracking
  Future<void> checkOutStudent(String studentId, String date) async {
    final now = DateTime.now();
    final statusRef = dailyStatusCollection.doc('${studentId}_$date');
    final studentRef = studentsCollection.doc(studentId);

    await firestore.runTransaction((transaction) async {
      // Read current dailyStatus
      final statusDoc = await transaction.get(statusRef);

      if (!statusDoc.exists) {
        // No check-in record exists - shouldn't happen in normal flow
        // Just update the student status
        transaction.update(studentRef, {
          'todayStatus': 'CheckedOut',
          'todayDate': date,
        });
        return;
      }

      final data = statusDoc.data()!;
      List<Map<String, dynamic>> sessions =
          List<Map<String, dynamic>>.from(data['sessions'] ?? []);

      // Find and close the last open session
      if (sessions.isNotEmpty) {
        final lastSession = sessions.last;
        if (lastSession['checkOut'] == null) {
          // Close this session
          sessions[sessions.length - 1] = {
            ...lastSession,
            'checkOut': now.toIso8601String(),
          };
        }
        // If already closed, we don't create a new orphan checkout
      }

      // Update dailyStatus
      transaction.set(statusRef, {
        'studentId': studentId,
        'date': date,
        'attendance': true,
        'checkOutTime': now.toIso8601String(), // Latest for UI
        'sessions': sessions,
      }, SetOptions(merge: true));

      // Update student's denormalized status
      transaction.update(studentRef, {
        'todayStatus': 'CheckedOut',
        'todayDate': date,
      });
    });
  }

  /// Atomic mark absent: Updates both students AND dailyStatus
  Future<void> markAbsent(String studentId, String date) async {
    final batch = firestore.batch();

    // Update school's students collection
    final studentRef = studentsCollection.doc(studentId);
    batch.update(studentRef, {
      'todayStatus': 'Absent',
      'todayDate': date,
      'todayDisplayStatus.isAbsent': true,
    });

    // Update school's dailyStatus collection
    final statusRef = dailyStatusCollection.doc('${studentId}_$date');
    batch.set(statusRef, {
      'studentId': studentId,
      'date': date,
      'attendance': false,
      'isAbsent': true,
    }, SetOptions(merge: true));

    await batch.commit();
  }

  // ============================================================================
  // BATCH QUERIES
  // ============================================================================

  /// Fetch all daily statuses for a specific date (school-scoped)
  /// Used by: Admin attendance view to show all students for a date
  Future<List<DailyStatus>> getDailyStatusesForDate(String date) async {
    final snapshot = await dailyStatusCollection
        .where('date', isEqualTo: date)
        .get();

    return snapshot.docs
        .map((doc) => DailyStatus.fromMap(doc.data()))
        .toList();
  }
}
