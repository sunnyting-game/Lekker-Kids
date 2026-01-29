import 'package:cloud_firestore/cloud_firestore.dart';
import 'school_member_model.dart';

/// Represents a pending invitation to join a school or organization.
/// Stored in the `invitations` collection.
/// 
/// An invitation can be:
/// - School-scoped: Has schoolId/schoolName set, grants access to a specific school
/// - Organization-scoped: Has organizationId/organizationName set, grants access to an organization
/// - Both: Can have both if inviting to a specific school within an organization
class InvitationModel {
  final String id;
  final String email;
  final String? organizationId; // Organization this invitation is for (optional)
  final String? organizationName; // Cached for display in invite email
  final String schoolId; // School this invitation is for (can be empty for org-level invites)
  final String schoolName; // Cached for display in invite email
  final MemberRole role;
  final String token; // Unique token for invite link
  final InvitationStatus status;
  final String createdBy; // Admin UID who created the invite
  final DateTime createdAt;
  final DateTime? expiresAt;

  InvitationModel({
    required this.id,
    required this.email,
    this.organizationId,
    this.organizationName,
    required this.schoolId,
    required this.schoolName,
    required this.role,
    required this.token,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    this.expiresAt,
  });

  /// Check if this is an organization-level invitation (no specific school).
  bool get isOrganizationInvite => organizationId != null && schoolId.isEmpty;

  /// Check if this is a school-specific invitation.
  bool get isSchoolInvite => schoolId.isNotEmpty;

  factory InvitationModel.fromMap(Map<String, dynamic> map, String id) {
    return InvitationModel(
      id: id,
      email: map['email'] ?? '',
      organizationId: map['organizationId'],
      organizationName: map['organizationName'],
      schoolId: map['schoolId'] ?? '',
      schoolName: map['schoolName'] ?? '',
      role: MemberRole.fromString(map['role']),
      token: map['token'] ?? '',
      status: InvitationStatus.fromString(map['status']),
      createdBy: map['createdBy'] ?? '',
      createdAt: _parseTimestamp(map['createdAt']),
      expiresAt: map['expiresAt'] != null ? _parseTimestamp(map['expiresAt']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      if (organizationId != null) 'organizationId': organizationId,
      if (organizationName != null) 'organizationName': organizationName,
      'schoolId': schoolId,
      'schoolName': schoolName,
      'role': role.name,
      'token': token,
      'status': status.name,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      if (expiresAt != null) 'expiresAt': Timestamp.fromDate(expiresAt!),
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

  /// Check if invitation is still valid (pending and not expired).
  bool get isValid {
    if (status != InvitationStatus.pending) return false;
    if (expiresAt != null && DateTime.now().isAfter(expiresAt!)) return false;
    return true;
  }

  InvitationModel copyWith({
    String? id,
    String? email,
    String? organizationId,
    String? organizationName,
    String? schoolId,
    String? schoolName,
    MemberRole? role,
    String? token,
    InvitationStatus? status,
    String? createdBy,
    DateTime? createdAt,
    DateTime? expiresAt,
  }) {
    return InvitationModel(
      id: id ?? this.id,
      email: email ?? this.email,
      organizationId: organizationId ?? this.organizationId,
      organizationName: organizationName ?? this.organizationName,
      schoolId: schoolId ?? this.schoolId,
      schoolName: schoolName ?? this.schoolName,
      role: role ?? this.role,
      token: token ?? this.token,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}

/// Status of an invitation.
enum InvitationStatus {
  pending,
  accepted,
  expired,
  revoked;

  static InvitationStatus fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'pending':
        return InvitationStatus.pending;
      case 'accepted':
        return InvitationStatus.accepted;
      case 'expired':
        return InvitationStatus.expired;
      case 'revoked':
        return InvitationStatus.revoked;
      default:
        return InvitationStatus.pending;
    }
  }
}
