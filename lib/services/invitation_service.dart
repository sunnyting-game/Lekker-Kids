import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/invitation_model.dart';
import '../models/school_member_model.dart';

/// Service for managing invitations.
/// 
/// Supports both school-level and organization-level invitations.
class InvitationService {
  final FirebaseFirestore _firestore;
  static const String _collection = 'invitations';

  InvitationService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Create a new invitation to a specific school.
  /// Returns the created invitation with generated token.
  Future<InvitationModel> createInvitation({
    required String email,
    required String schoolId,
    required String schoolName,
    required MemberRole role,
    required String createdBy,
    String? organizationId,
    String? organizationName,
    Duration? expiresIn,
  }) async {
    final token = _generateToken();
    final now = DateTime.now();
    
    final invitation = InvitationModel(
      id: '', // Will be set by Firestore
      email: email.toLowerCase().trim(),
      organizationId: organizationId,
      organizationName: organizationName,
      schoolId: schoolId,
      schoolName: schoolName,
      role: role,
      token: token,
      status: InvitationStatus.pending,
      createdBy: createdBy,
      createdAt: now,
      expiresAt: expiresIn != null ? now.add(expiresIn) : null,
    );

    final docRef = await _firestore.collection(_collection).add(invitation.toMap());
    
    return invitation.copyWith(id: docRef.id);
  }

  /// Create an organization-level invitation (not tied to a specific school).
  /// Used for inviting organization admins who manage all schools.
  Future<InvitationModel> createOrganizationInvitation({
    required String email,
    required String organizationId,
    required String organizationName,
    required MemberRole role,
    required String createdBy,
    Duration? expiresIn,
  }) async {
    final token = _generateToken();
    final now = DateTime.now();
    
    final invitation = InvitationModel(
      id: '', // Will be set by Firestore
      email: email.toLowerCase().trim(),
      organizationId: organizationId,
      organizationName: organizationName,
      schoolId: '', // Empty for org-level invites
      schoolName: '',
      role: role,
      token: token,
      status: InvitationStatus.pending,
      createdBy: createdBy,
      createdAt: now,
      expiresAt: expiresIn != null ? now.add(expiresIn) : null,
    );

    final docRef = await _firestore.collection(_collection).add(invitation.toMap());
    
    return invitation.copyWith(id: docRef.id);
  }

  /// Get invitation by token.
  Future<InvitationModel?> getInvitationByToken(String token) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('token', isEqualTo: token)
        .where('status', isEqualTo: InvitationStatus.pending.name)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    final doc = snapshot.docs.first;
    return InvitationModel.fromMap(doc.data(), doc.id);
  }

  /// Get pending invitations for a school.
  Stream<List<InvitationModel>> getPendingInvitationsStream(String schoolId) {
    return _firestore
        .collection(_collection)
        .where('schoolId', isEqualTo: schoolId)
        .where('status', isEqualTo: InvitationStatus.pending.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InvitationModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Get pending invitations for an organization.
  Stream<List<InvitationModel>> getPendingOrganizationInvitationsStream(String organizationId) {
    return _firestore
        .collection(_collection)
        .where('organizationId', isEqualTo: organizationId)
        .where('status', isEqualTo: InvitationStatus.pending.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InvitationModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Mark invitation as accepted.
  Future<void> markAccepted(String invitationId) async {
    await _firestore.collection(_collection).doc(invitationId).update({
      'status': InvitationStatus.accepted.name,
    });
  }

  /// Revoke an invitation.
  Future<void> revokeInvitation(String invitationId) async {
    await _firestore.collection(_collection).doc(invitationId).update({
      'status': InvitationStatus.revoked.name,
    });
  }

  /// Generate a secure random token.
  String _generateToken() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(32, (_) => chars[random.nextInt(chars.length)]).join();
  }
}
