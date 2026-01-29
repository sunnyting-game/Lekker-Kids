import 'package:cloud_functions/cloud_functions.dart';
import '../models/user_model.dart';
import '../constants/app_strings.dart';
import 'package:flutter/foundation.dart';

class CloudFunctionsService {
  final FirebaseFunctions _functions;

  CloudFunctionsService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  /// Create a new user account (admin only)
  /// Calls the adminCreateUser Cloud Function
  Future<UserModel> createUser({
    required String username,
    required String password,
    required UserRole role,
    String? name,
    String? organizationId,
  }) async {
    try {
      debugPrint('DEBUG CloudFunctions: Calling adminCreateUser');
      debugPrint('DEBUG CloudFunctions: Username: $username, Role: $role, OrgId: $organizationId');
      
      final callable = _functions.httpsCallable('adminCreateUser');
      
      final result = await callable.call({
        'username': username,
        'password': password,
        'role': role.toString().split('.').last,
        if (name != null) 'name': name,
        if (organizationId != null) 'organizationId': organizationId,
      });

      debugPrint('DEBUG CloudFunctions: Success - ${result.data}');

      final data = result.data as Map<String, dynamic>;
      
      return UserModel(
        uid: data['uid'],
        email: data['email'] ?? '', // Email from Cloud Function response
        username: data['username'],
        name: name,
        role: role,
        organizationId: organizationId,
        createdAt: DateTime.now(),
      );
    } on FirebaseFunctionsException catch (e) {
      debugPrint('DEBUG CloudFunctions: FirebaseFunctionsException - ${e.code}: ${e.message}');
      throw _handleFunctionsException(e);
    } catch (e) {
      debugPrint('DEBUG CloudFunctions: Generic exception: $e');
      throw AppStrings.format(AppStrings.errorLoadUserData, [e.toString()]);
    }
  }

  String _handleFunctionsException(FirebaseFunctionsException e) {
    switch (e.code) {
      case 'unauthenticated':
        return 'You must be logged in to create users';
      case 'permission-denied':
        return 'Only admins can create users';
      case 'invalid-argument':
        return 'Invalid input: ${e.message}';
      case 'internal':
        return e.message ?? 'An internal error occurred';
      default:
        return e.message ?? 'An error occurred while creating user';
    }
  }

  /// Update an existing user account (admin only)
  /// Calls the adminUpdateUser Cloud Function
  Future<void> updateUser({
    required String uid,
    String? username,
    String? password,
    String? name,
  }) async {
    try {
      debugPrint('DEBUG CloudFunctions: Calling adminUpdateUser for $uid');
      
      final callable = _functions.httpsCallable('adminUpdateUser');
      
      await callable.call({
        'uid': uid,
        if (username != null && username.isNotEmpty) 'username': username,
        if (password != null && password.isNotEmpty) 'password': password,
        if (name != null) 'name': name,
      });

      debugPrint('DEBUG CloudFunctions: Update success');
    } on FirebaseFunctionsException catch (e) {
      debugPrint('DEBUG CloudFunctions: FirebaseFunctionsException - ${e.code}: ${e.message}');
      throw _handleFunctionsException(e);
    } catch (e) {
      debugPrint('DEBUG CloudFunctions: Generic exception: $e');
      throw AppStrings.format(AppStrings.errorLoadUserData, [e.toString()]);
    }
  }
}
