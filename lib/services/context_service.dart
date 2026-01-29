import 'package:flutter/foundation.dart';
import '../models/school_model.dart';
import '../models/school_member_model.dart';

/// Service that holds the current tenant context (selected school and role).
/// This is used throughout the app to scope data access.
class ContextService extends ChangeNotifier {
  SchoolModel? _currentSchool;
  SchoolMemberModel? _currentMember;

  /// The currently selected school.
  SchoolModel? get currentSchool => _currentSchool;

  /// The current user's membership in the selected school.
  SchoolMemberModel? get currentMember => _currentMember;

  /// The current school ID (convenience getter).
  String? get currentSchoolId => _currentSchool?.id;

  /// The current user's role in the selected school.
  MemberRole? get currentRole => _currentMember?.role;

  /// Whether a school context is currently set.
  bool get hasContext => _currentSchool != null && _currentMember != null;

  /// Set the current school and member context.
  void setContext({
    required SchoolModel school,
    required SchoolMemberModel member,
  }) {
    _currentSchool = school;
    _currentMember = member;
    notifyListeners();
  }

  /// Clear the current context (e.g., on logout or school switch).
  void clearContext() {
    _currentSchool = null;
    _currentMember = null;
    notifyListeners();
  }

  /// Check if the current user is an admin in the selected school.
  bool get isAdmin => _currentMember?.isAdmin ?? false;

  /// Check if the current user is a teacher in the selected school.
  bool get isTeacher => _currentMember?.isTeacher ?? false;

  /// Check if the current user is a parent in the selected school.
  bool get isParent => _currentMember?.isParent ?? false;

  /// Check if a feature is enabled for the current school.
  bool isFeatureEnabled(String featureName) {
    return _currentSchool?.config.isFeatureEnabled(featureName) ?? true;
  }
}
