import 'package:cloud_firestore/cloud_firestore.dart';
import 'today_display_status.dart';

class UserModel {
  final String uid;
  final String email; // [NEW] Real email for authentication
  final String username; // Legacy username field (kept for compatibility)
  final String? name; // Display name for teacher/student
  final UserRole role;
  final DateTime createdAt;
  final String? avatarUrl; // Avatar image URL for students
  final String? organizationId; // [NEW] Organization this user belongs to
  final List<String> schoolIds; // Schools (Dayhomes) this user belongs to
  final String? todayStatus; // Denormalized: "NotArrived" | "CheckedIn" | "CheckedOut" | "Absent"
  final String? todayDate; // Date of todayStatus (YYYY-MM-DD) for staleness check
  final TodayDisplayStatus? todayDisplayStatus; // Denormalized display fields
  final bool hasUnreadFromStudent; // For teacher's unread indicator
  final bool isSuperAdmin; // True if user has superAdmin custom claim

  UserModel({
    required this.uid,
    required this.email,
    required this.username,
    this.name,
    required this.role,
    required this.createdAt,
    this.avatarUrl,
    this.organizationId,
    this.schoolIds = const [],
    this.todayStatus,
    this.todayDate,
    this.todayDisplayStatus,
    this.hasUnreadFromStudent = false,
    this.isSuperAdmin = false,
  });

  /// Computed property: is the student present (checked in and not absent)?
  bool get isPresent {
    if (todayStatus == null) return false;
    return todayStatus == 'CheckedIn';
  }

  /// Computed property: is the student checked out?
  bool get isCheckedOut => todayStatus == 'CheckedOut';

  /// Computed property: is the student marked absent?
  bool get isAbsent => todayStatus == 'Absent';

  /// Computed property: has the student not arrived yet?
  bool get isNotArrived => todayStatus == null || todayStatus == 'NotArrived';

  // Convert UserModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'username': username,
      if (name != null) 'name': name,
      'role': role.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      if (organizationId != null) 'organizationId': organizationId,
      if (schoolIds.isNotEmpty) 'schoolIds': schoolIds,
      if (todayStatus != null) 'todayStatus': todayStatus,
      if (todayDate != null) 'todayDate': todayDate,
      if (todayDisplayStatus != null) 'todayDisplayStatus': todayDisplayStatus!.toMap(),
      'hasUnreadFromStudent': hasUnreadFromStudent,
    };
  }

  // Create UserModel from Firestore document
  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      email: map['email'] ?? '',
      username: map['username'] ?? '',
      name: map['name'],
      role: _parseRole(map['role']),
      createdAt: _parseCreatedAt(map['createdAt']),
      avatarUrl: map['avatarUrl'],
      organizationId: map['organizationId'],
      schoolIds: (map['schoolIds'] as List<dynamic>?)?.cast<String>() ?? [],
      todayStatus: map['todayStatus'],
      todayDate: map['todayDate'],
      todayDisplayStatus: map['todayDisplayStatus'] != null
          ? TodayDisplayStatus.fromMap(map['todayDisplayStatus'] as Map<String, dynamic>)
          : null,
      hasUnreadFromStudent: map['hasUnreadFromStudent'] ?? false,
    );
  }

  /// Create a copy with updated values
  /// Use clearTodayStatus: true to explicitly set todayStatus to null
  UserModel copyWith({
    String? uid,
    String? email,
    String? username,
    String? name,
    UserRole? role,
    DateTime? createdAt,
    String? avatarUrl,
    String? organizationId,
    List<String>? schoolIds,
    String? todayStatus,
    bool clearTodayStatus = false, // Flag to explicitly clear todayStatus
    String? todayDate,
    TodayDisplayStatus? todayDisplayStatus,
    bool? hasUnreadFromStudent,
    bool? isSuperAdmin,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      username: username ?? this.username,
      name: name ?? this.name,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      organizationId: organizationId ?? this.organizationId,
      schoolIds: schoolIds ?? this.schoolIds,
      todayStatus: clearTodayStatus ? null : (todayStatus ?? this.todayStatus),
      todayDate: todayDate ?? this.todayDate,
      todayDisplayStatus: todayDisplayStatus ?? this.todayDisplayStatus,
      hasUnreadFromStudent: hasUnreadFromStudent ?? this.hasUnreadFromStudent,
      isSuperAdmin: isSuperAdmin ?? this.isSuperAdmin,
    );
  }

  static DateTime _parseCreatedAt(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      return DateTime.parse(value);
    }
    return DateTime.now(); // Fallback
  }

  static UserRole _parseRole(String? roleString) {
    switch (roleString?.toLowerCase()) {
      case 'teacher':
        return UserRole.teacher;
      case 'admin':
        return UserRole.admin;
      case 'student':
        return UserRole.student;
      default:
        return UserRole.student;
    }
  }
}

enum UserRole {
  teacher,
  admin,
  student,
}
