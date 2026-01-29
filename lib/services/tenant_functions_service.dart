import 'package:cloud_functions/cloud_functions.dart';
import '../models/school_member_model.dart';

/// Service for calling multi-tenancy Cloud Functions.
class TenantFunctionsService {
  final FirebaseFunctions _functions;

  TenantFunctionsService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  /// Create an invitation for a user to join a school.
  /// Returns the invitation token for distribution.
  Future<InvitationResult> createInvitation({
    required String email,
    required MemberRole role,
    required String schoolId,
  }) async {
    try {
      final callable = _functions.httpsCallable('createInvitation');
      
      final result = await callable.call({
        'email': email,
        'role': role.name,
        'schoolId': schoolId,
      });

      final data = result.data as Map<String, dynamic>;
      
      return InvitationResult(
        success: data['success'] ?? false,
        invitationId: data['invitationId'],
        token: data['token'],
      );
    } on FirebaseFunctionsException catch (e) {
      throw _handleException(e);
    }
  }

  /// Accept an invitation and create/add user to school.
  /// Called during registration via invite link.
  Future<AcceptInvitationResult> acceptInvitation({
    required String token,
    required String password,
    String? displayName,
  }) async {
    try {
      final callable = _functions.httpsCallable('acceptInvitation');
      
      final result = await callable.call({
        'token': token,
        'password': password,
        if (displayName != null) 'displayName': displayName,
      });

      final data = result.data as Map<String, dynamic>;
      
      return AcceptInvitationResult(
        success: data['success'] ?? false,
        uid: data['uid'],
        schoolId: data['schoolId'],
        role: data['role'],
      );
    } on FirebaseFunctionsException catch (e) {
      throw _handleException(e);
    }
  }

  /// Create a new school (tenant). Super Admin only.
  Future<CreateSchoolResult> createSchool({
    required String name,
    required String adminEmail,
    String? organizationId,
    Map<String, dynamic>? config,
  }) async {
    try {
      final callable = _functions.httpsCallable('createSchool');
      
      final result = await callable.call({
        'name': name,
        'adminEmail': adminEmail,
        if (organizationId != null) 'organizationId': organizationId,
        if (config != null) 'config': config,
      });

      final data = result.data as Map<String, dynamic>;
      
      return CreateSchoolResult(
        success: data['success'] ?? false,
        schoolId: data['schoolId'],
        invitationId: data['invitationId'],
        adminInviteToken: data['adminInviteToken'],
      );
    } on FirebaseFunctionsException catch (e) {
      throw _handleException(e);
    }
  }

  String _handleException(FirebaseFunctionsException e) {
    switch (e.code) {
      case 'unauthenticated':
        return 'You must be logged in';
      case 'permission-denied':
        return 'You do not have permission to perform this action';
      case 'invalid-argument':
        return e.message ?? 'Invalid input';
      case 'not-found':
        return e.message ?? 'Resource not found';
      case 'already-exists':
        return e.message ?? 'Resource already exists';
      default:
        return e.message ?? 'An error occurred';
    }
  }

  /// Create a new organization (tenant group). Super Admin only.
  Future<CreateOrganizationResult> createOrganization({
    required String name,
    required String adminEmail,
    required String password,
  }) async {
    try {
      final callable = _functions.httpsCallable('createOrganization');
      
      final result = await callable.call({
        'name': name,
        'adminEmail': adminEmail,
        'password': password,
      });

      final data = result.data as Map<String, dynamic>;
      
      return CreateOrganizationResult(
        success: data['success'] ?? false,
        organizationId: data['organizationId'],
        uid: data['uid'],
      );
    } on FirebaseFunctionsException catch (e) {
      throw _handleException(e);
    }
  }
}

/// Result of creating an invitation.
class InvitationResult {
  final bool success;
  final String? invitationId;
  final String? token;

  InvitationResult({
    required this.success,
    this.invitationId,
    this.token,
  });
}

/// Result of accepting an invitation.
class AcceptInvitationResult {
  final bool success;
  final String? uid;
  final String? schoolId;
  final String? role;

  AcceptInvitationResult({
    required this.success,
    this.uid,
    this.schoolId,
    this.role,
  });
}

/// Result of creating a school.
class CreateSchoolResult {
  final bool success;
  final String? schoolId;
  final String? invitationId;
  final String? adminInviteToken;

  CreateSchoolResult({
    required this.success,
    this.schoolId,
    this.invitationId,
    this.adminInviteToken,
  });
}

/// Result of creating an organization.
class CreateOrganizationResult {
  final bool success;
  final String? organizationId;
  final String? uid;

  CreateOrganizationResult({
    required this.success,
    this.organizationId,
    this.uid,
  });
}
