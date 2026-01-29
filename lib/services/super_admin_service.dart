import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Service for Super Admin authentication and authorization.
class SuperAdminService {
  final FirebaseAuth _auth;

  SuperAdminService({FirebaseAuth? auth})
      : _auth = auth ?? FirebaseAuth.instance;

  /// Check if the current user is a Super Admin.
  /// Returns false if not authenticated or not a super admin.
  Future<bool> isSuperAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final idTokenResult = await user.getIdTokenResult(true);
      final isSuperAdmin = idTokenResult.claims?['superAdmin'] == true;
      debugPrint('DEBUG SuperAdmin: ${user.email} isSuperAdmin=$isSuperAdmin');
      return isSuperAdmin;
    } catch (e) {
      debugPrint('DEBUG SuperAdmin: Error checking claims: $e');
      return false;
    }
  }

  /// Stream that emits when super admin status might have changed.
  Stream<bool> get superAdminStream {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) return false;
      return await isSuperAdmin();
    });
  }

  /// Get current user UID (for audit logging).
  String? get currentUserId => _auth.currentUser?.uid;

  /// Get current user email.
  String? get currentUserEmail => _auth.currentUser?.email;
}
