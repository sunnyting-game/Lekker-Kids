import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a user's membership and role within a specific school.
/// Stored as a subcollection: schools/{schoolId}/members/{uid}
class SchoolMemberModel {
  final String uid;
  final String schoolId;
  final MemberRole role;
  final List<String>? childIds; // For parents: linked student UIDs
  final DateTime invitedAt;
  final String? displayName; // Cached from user for quick access

  SchoolMemberModel({
    required this.uid,
    required this.schoolId,
    required this.role,
    this.childIds,
    required this.invitedAt,
    this.displayName,
  });

  factory SchoolMemberModel.fromMap(Map<String, dynamic> map, String uid) {
    return SchoolMemberModel(
      uid: uid,
      schoolId: map['schoolId'] ?? '',
      role: MemberRole.fromString(map['role']),
      childIds: (map['childIds'] as List<dynamic>?)?.cast<String>(),
      invitedAt: _parseTimestamp(map['invitedAt']),
      displayName: map['displayName'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'schoolId': schoolId,
      'role': role.name,
      if (childIds != null) 'childIds': childIds,
      'invitedAt': Timestamp.fromDate(invitedAt),
      if (displayName != null) 'displayName': displayName,
    };
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      return DateTime.parse(value);
    }
    return DateTime.now();
  }

  /// Is this member an admin of the school?
  bool get isAdmin => role == MemberRole.admin;

  /// Is this member a teacher?
  bool get isTeacher => role == MemberRole.teacher;

  /// Is this member a parent?
  bool get isParent => role == MemberRole.parent;

  SchoolMemberModel copyWith({
    String? uid,
    String? schoolId,
    MemberRole? role,
    List<String>? childIds,
    DateTime? invitedAt,
    String? displayName,
  }) {
    return SchoolMemberModel(
      uid: uid ?? this.uid,
      schoolId: schoolId ?? this.schoolId,
      role: role ?? this.role,
      childIds: childIds ?? this.childIds,
      invitedAt: invitedAt ?? this.invitedAt,
      displayName: displayName ?? this.displayName,
    );
  }
}

/// Role of a member within a school.
enum MemberRole {
  admin,
  teacher,
  parent;

  static MemberRole fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'admin':
        return MemberRole.admin;
      case 'teacher':
        return MemberRole.teacher;
      case 'parent':
        return MemberRole.parent;
      default:
        return MemberRole.parent;
    }
  }
}
