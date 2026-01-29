import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/user_model.dart';
import '../models/school_model.dart';
import '../models/school_member_model.dart';
import '../constants/app_strings.dart';
import '../constants/firestore_collections.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ============================================================================
  // NEW: Sign in with real email
  // ============================================================================

  /// Sign in with real email and password.
  /// Returns user data with school memberships.
  Future<AuthResult> signInWithEmail(String email, String password) async {
    try {
      debugPrint('DEBUG: Attempting to sign in with email: $email');
      
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.toLowerCase().trim(),
        password: password,
      );

      debugPrint('DEBUG: Sign in successful, UID: ${userCredential.user?.uid}');

      if (userCredential.user == null) {
        return AuthResult(success: false, error: 'Sign in failed');
      }

      final uid = userCredential.user!.uid;
      
      // Get user data
      final user = await getUserData(uid);
      if (user == null) {
        return AuthResult(success: false, error: AppStrings.errorUserNotConfigured);
      }

      // Get school memberships
      final memberships = await getSchoolMemberships(uid, user.schoolIds);

      return AuthResult(
        success: true,
        user: user,
        memberships: memberships,
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('DEBUG: FirebaseAuthException - Code: ${e.code}, Message: ${e.message}');
      return AuthResult(success: false, error: _handleAuthException(e));
    } catch (e) {
      debugPrint('DEBUG: Generic exception: $e');
      return AuthResult(success: false, error: AppStrings.errorUnexpected);
    }
  }

  /// Get school memberships for a user.
  Future<List<SchoolMembership>> getSchoolMemberships(String uid, List<String> schoolIds) async {
    final memberships = <SchoolMembership>[];

    for (final schoolId in schoolIds) {
      try {
        // Get school info
        final schoolDoc = await _firestore
            .collection('schools')
            .doc(schoolId)
            .get();

        if (!schoolDoc.exists) continue;

        final school = SchoolModel.fromMap(schoolDoc.data()!, schoolId);

        // Get member info
        final memberDoc = await _firestore
            .collection('schools')
            .doc(schoolId)
            .collection('members')
            .doc(uid)
            .get();

        if (!memberDoc.exists) continue;

        final member = SchoolMemberModel.fromMap(memberDoc.data()!, uid);

        memberships.add(SchoolMembership(school: school, member: member));
      } catch (e) {
        debugPrint('DEBUG: Error fetching membership for school $schoolId: $e');
      }
    }

    return memberships;
  }

  // ============================================================================
  // LEGACY: Sign in with username (for backward compatibility)
  // ============================================================================

  /// Sign in with username and password (legacy method).
  /// Converts username to email format for Firebase Auth.
  Future<UserModel?> signInWithUsername(String username, String password) async {
    try {
      final email = '${username.toLowerCase()}@daycare.local';
      
      debugPrint('DEBUG: Attempting to sign in with email: $email');
      
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      debugPrint('DEBUG: Sign in successful, UID: ${userCredential.user?.uid}');

      if (userCredential.user != null) {
        final userData = await getUserData(userCredential.user!.uid);
        
        // Store FCM token after successful login
        await _storeFcmToken(userCredential.user!.uid);
        
        return userData;
      }
      
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint('DEBUG: FirebaseAuthException - Code: ${e.code}, Message: ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint('DEBUG: Generic exception: $e');
      throw AppStrings.errorUnexpected;
    }
  }
  
  /// Store FCM token in Firestore for the user
  Future<void> _storeFcmToken(String uid) async {
    try {
      final messaging = FirebaseMessaging.instance;
      final token = await messaging.getToken();
      
      if (token != null) {
        await _firestore.collection(FirestoreCollections.users).doc(uid).update({
          'fcmToken': token,
        });
        debugPrint('FCM token stored for user: $uid');
      }
    } catch (e) {
      debugPrint('Error storing FCM token: $e');
      // Don't throw - token storage failure shouldn't block login
    }
  }

  // ============================================================================
  // COMMON: User data and utilities
  // ============================================================================

  /// Get user data from Firestore.
  Future<UserModel?> getUserData(String uid) async {
    try {
      debugPrint('DEBUG: Fetching user data from Firestore for UID: $uid');
      final doc = await _firestore.collection(FirestoreCollections.users).doc(uid).get();
      
      debugPrint('DEBUG: Document exists: ${doc.exists}');
      
      if (doc.exists && doc.data() != null) {
        final userData = UserModel.fromMap(doc.data()!, uid);
        debugPrint('DEBUG: User data loaded - Email: ${userData.email}, Schools: ${userData.schoolIds.length}');
        return userData;
      }
      
      // If doc missing, check for Super Admin claim
      final currentUser = _auth.currentUser;
      if (currentUser != null && currentUser.uid == uid) {
        final idTokenResult = await currentUser.getIdTokenResult(true);
        final isSuperAdmin = idTokenResult.claims?['superAdmin'] == true;
        
        if (isSuperAdmin) {
          debugPrint('DEBUG: User doc missing but is Super Admin. Returning transient user.');
          return UserModel(
            uid: uid,
            email: currentUser.email ?? '',
            username: (currentUser.email ?? '').split('@')[0],
            role: UserRole.admin,
            createdAt: DateTime.now(),
            schoolIds: [],
            isSuperAdmin: true,
          );
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('DEBUG: Error getting user data: $e');
      return null;
    }
  }

  /// Handle Firebase Auth exceptions.
  String _handleAuthException(FirebaseAuthException e) {
    debugPrint('DEBUG: Handling auth exception - Code: ${e.code}');
    switch (e.code) {
      case 'user-not-found':
        return AppStrings.errorInvalidCredentials;
      case 'wrong-password':
        return AppStrings.errorInvalidCredentials;
      case 'invalid-credential':
        return AppStrings.errorInvalidCredentials;
      case 'invalid-email':
        return AppStrings.errorInvalidUsername;
      case 'user-disabled':
        return AppStrings.errorAccountDisabled;
      case 'too-many-requests':
        return AppStrings.errorTooManyRequests;
      case 'network-request-failed':
        return AppStrings.errorNetworkFailed;
      default:
        return AppStrings.format(AppStrings.errorLoginFailed, [e.message ?? e.code]);
    }
  }

  /// Sign out.
  Future<void> signOut() async {
    await _auth.signOut();
  }
}

// ============================================================================
// RESULT CLASSES
// ============================================================================

/// Result of authentication attempt.
class AuthResult {
  final bool success;
  final String? error;
  final UserModel? user;
  final List<SchoolMembership>? memberships;

  AuthResult({
    required this.success,
    this.error,
    this.user,
    this.memberships,
  });

  /// Does user have multiple school memberships?
  bool get hasMultipleSchools => (memberships?.length ?? 0) > 1;

  /// Get single membership if user has only one school.
  SchoolMembership? get singleMembership => 
      memberships?.length == 1 ? memberships!.first : null;
}

/// Represents a user's membership in a school (combined school + role info).
class SchoolMembership {
  final SchoolModel school;
  final SchoolMemberModel member;

  SchoolMembership({required this.school, required this.member});

  String get schoolName => school.name;
  MemberRole get role => member.role;
}
