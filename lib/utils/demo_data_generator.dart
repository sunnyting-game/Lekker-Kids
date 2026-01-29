import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../repositories/user_repository.dart';
import '../services/cloud_functions_service.dart';
import '../services/tenant_functions_service.dart';

/// Result of Phase 1: Organization and School creation
class Phase1Result {
  final String organizationId;
  final String orgAdminUid;
  final String schoolId;
  final String adminEmail;
  final String password;

  Phase1Result({
    required this.organizationId,
    required this.orgAdminUid,
    required this.schoolId,
    required this.adminEmail,
    required this.password,
  });
}

/// Represents a demo user created by Phase 2
class DemoUser {
  final String uid;
  final String username;
  final String email;
  final String password;
  final String role;
  final String? shift; // For students: "9am-5pm" or "8:30am-4pm"

  DemoUser({
    required this.uid,
    required this.username,
    required this.email,
    required this.password,
    required this.role,
    this.shift,
  });
}

/// Result of Phase 2: User creation
class Phase2Result {
  final DemoUser teacher;
  final List<DemoUser> students;

  Phase2Result({
    required this.teacher,
    required this.students,
  });
}

/// Result of Phase 3: Attendance backfill
class Phase3Result {
  final int totalRecords;
  final int daysProcessed;
  final int weekendsSkipped;

  Phase3Result({
    required this.totalRecords,
    required this.daysProcessed,
    required this.weekendsSkipped,
  });
}

/// Demo Data Generator Utility
/// 
/// Creates demo organizations, schools, users, and attendance data
/// for client presentations.
class DemoDataGenerator {
  final TenantFunctionsService _tenantFunctions;
  final CloudFunctionsService _cloudFunctions;
  final UserRepository _userRepository;
  final FirebaseFirestore _firestore;

  static const String _defaultPassword = 'demo123';
  static const String _emailDomain = '@daycare.local';

  DemoDataGenerator({
    TenantFunctionsService? tenantFunctions,
    CloudFunctionsService? cloudFunctions,
    UserRepository? userRepository,
    FirebaseFirestore? firestore,
  })  : _tenantFunctions = tenantFunctions ?? TenantFunctionsService(),
        _cloudFunctions = cloudFunctions ?? CloudFunctionsService(),
        _userRepository = userRepository ?? UserRepository(),
        _firestore = firestore ?? FirebaseFirestore.instance;

  /// Phase 1: Create Organization and School
  /// 
  /// Takes an organization name (e.g., "Sunshine") and creates:
  /// - Organization: "Sunshine Demo" with ID "sunshine_demo"
  /// - Admin email: "sunshine_demo@daycare.local"
  /// - School: "Sunshine Demo Dayhome" under the organization
  Future<Phase1Result> createDemoOrgAndSchool({
    required String orgName,
  }) async {
    // Derive IDs and names
    final orgId = '${orgName.toLowerCase().replaceAll(' ', '_')}_demo';
    final adminEmail = '$orgId$_emailDomain';
    final displayOrgName = '$orgName Demo';
    final schoolName = '$orgName Demo Dayhome';

    debugPrint('=== Phase 1: Creating Demo Org and School ===');
    debugPrint('Org Name: $displayOrgName');
    debugPrint('Org ID: $orgId');
    debugPrint('Admin Email: $adminEmail');
    debugPrint('School Name: $schoolName');

    // Step 1: Create Organization
    debugPrint('Step 1: Creating organization...');
    final orgResult = await _tenantFunctions.createOrganization(
      name: displayOrgName,
      adminEmail: adminEmail,
      password: _defaultPassword,
    );

    if (!orgResult.success || orgResult.organizationId == null) {
      throw Exception('Failed to create organization: ${orgResult.organizationId}');
    }

    debugPrint('Organization created: ${orgResult.organizationId}');
    debugPrint('Org Admin UID: ${orgResult.uid}');

    // Step 2: Create School under this Organization
    debugPrint('Step 2: Creating school...');
    final schoolResult = await _tenantFunctions.createSchool(
      name: schoolName,
      adminEmail: adminEmail,
      organizationId: orgResult.organizationId,
    );

    if (!schoolResult.success || schoolResult.schoolId == null) {
      throw Exception('Failed to create school: ${schoolResult.schoolId}');
    }

    debugPrint('School created: ${schoolResult.schoolId}');
    debugPrint('=== Phase 1 Complete ===');

    return Phase1Result(
      organizationId: orgResult.organizationId!,
      orgAdminUid: orgResult.uid ?? '',
      schoolId: schoolResult.schoolId!,
      adminEmail: adminEmail,
      password: _defaultPassword,
    );
  }

  /// Phase 2: Create Teacher and Students
  /// 
  /// Creates 1 teacher and 6 students, assigns them to the school.
  /// - Teacher username: "{orgId}_teacher"
  /// - Student usernames: "{orgId}_student1" through "{orgId}_student6"
  /// - Students 1-3: Shift A (9am-5pm)
  /// - Students 4-6: Shift B (8:30am-4pm)
  Future<Phase2Result> createDemoUsers({
    required String organizationId,
    required String schoolId,
  }) async {
    debugPrint('=== Phase 2: Creating Demo Users ===');
    debugPrint('Organization ID: $organizationId');
    debugPrint('School ID: $schoolId');

    // Step 1: Create Teacher
    final teacherUsername = '${organizationId}_teacher';
    debugPrint('Creating teacher: $teacherUsername');

    final teacherResult = await _cloudFunctions.createUser(
      username: teacherUsername,
      password: _defaultPassword,
      name: 'Demo Teacher',
      role: UserRole.teacher,
      organizationId: organizationId,
    );

    debugPrint('Teacher created: ${teacherResult.uid}');

    // Step 2: Assign Teacher to School
    debugPrint('Assigning teacher to school...');
    await _userRepository.addUserToSchool(teacherResult.uid, schoolId);
    debugPrint('Teacher assigned to school');

    final teacher = DemoUser(
      uid: teacherResult.uid,
      username: teacherUsername,
      email: '$teacherUsername$_emailDomain',
      password: _defaultPassword,
      role: 'teacher',
    );

    // Step 3: Create 6 Students
    final students = <DemoUser>[];

    for (int i = 1; i <= 6; i++) {
      final studentUsername = '${organizationId}_student$i';
      final shift = i <= 3 ? '9am-5pm' : '8:30am-4pm';

      debugPrint('Creating student $i: $studentUsername (Shift: $shift)');

      final studentResult = await _cloudFunctions.createUser(
        username: studentUsername,
        password: _defaultPassword,
        name: 'Demo Student $i',
        role: UserRole.student,
        organizationId: organizationId,
      );

      debugPrint('Student $i created: ${studentResult.uid}');

      // Step 4: Assign Student to School
      debugPrint('Assigning student $i to school...');
      await _userRepository.addUserToSchool(studentResult.uid, schoolId);
      debugPrint('Student $i assigned to school');

      students.add(DemoUser(
        uid: studentResult.uid,
        username: studentUsername,
        email: '$studentUsername$_emailDomain',
        password: _defaultPassword,
        role: 'student',
        shift: shift,
      ));
    }

    debugPrint('=== Phase 2 Complete ===');
    debugPrint('Created 1 teacher and ${students.length} students');

    return Phase2Result(
      teacher: teacher,
      students: students,
    );
  }

  /// Phase 3: Backfill Attendance
  /// 
  /// Creates attendance records for the specified number of days.
  /// - Skips weekends (Saturday and Sunday)
  /// - Shift A (students 1-3): 9:00 AM - 5:00 PM
  /// - Shift B (students 4-6): 8:30 AM - 4:00 PM
  /// 
  /// Writes directly to Firestore with historical timestamps.
  Future<Phase3Result> backfillAttendance({
    required List<DemoUser> students,
    required String schoolId,
    int daysOfHistory = 30,
  }) async {
    debugPrint('=== Phase 3: Backfilling Attendance ===');
    debugPrint('School ID: $schoolId');
    debugPrint('Days of History: $daysOfHistory');
    debugPrint('Students: ${students.length}');

    final today = DateTime.now();
    final dailyStatusRef = _firestore.collection('schools').doc(schoolId).collection('dailyStatus');

    int totalRecords = 0;
    int daysProcessed = 0;
    int weekendsSkipped = 0;

    for (final student in students) {
      if (student.role != 'student') continue;

      debugPrint('Processing attendance for ${student.username}...');

      for (int dayOffset = 0; dayOffset < daysOfHistory; dayOffset++) {
        final date = today.subtract(Duration(days: dayOffset));

        // Skip weekends (Saturday = 6, Sunday = 7)
        if (date.weekday == DateTime.saturday || date.weekday == DateTime.sunday) {
          if (student == students.first) {
            weekendsSkipped++;
          }
          continue;
        }

        final dateString = _formatDate(date);

        // Determine shift times based on student's shift
        DateTime checkInTime;
        DateTime checkOutTime;

        if (student.shift == '9am-5pm') {
          checkInTime = DateTime(date.year, date.month, date.day, 9, 0);
          checkOutTime = DateTime(date.year, date.month, date.day, 17, 0);
        } else {
          // 8:30am-4pm
          checkInTime = DateTime(date.year, date.month, date.day, 8, 30);
          checkOutTime = DateTime(date.year, date.month, date.day, 16, 0);
        }

        // Create attendance record directly in Firestore
        final docId = '${student.uid}_$dateString';
        await dailyStatusRef.doc(docId).set({
          'studentId': student.uid,
          'date': dateString,
          'attendance': true,
          'isAbsent': false,
          'checkInTime': checkInTime.toIso8601String(),
          'checkOutTime': checkOutTime.toIso8601String(),
          'sessions': [
            {
              'checkIn': checkInTime.toIso8601String(),
              'checkOut': checkOutTime.toIso8601String(),
            }
          ],
        });

        totalRecords++;
        if (student == students.first) {
          daysProcessed++;
        }
      }

      debugPrint('Completed ${student.username}');
    }

    debugPrint('=== Phase 3 Complete ===');
    debugPrint('Total records created: $totalRecords');
    debugPrint('Days processed: $daysProcessed');
    debugPrint('Weekends skipped: $weekendsSkipped');

    return Phase3Result(
      totalRecords: totalRecords,
      daysProcessed: daysProcessed,
      weekendsSkipped: weekendsSkipped,
    );
  }

  /// Format date as YYYY-MM-DD
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
