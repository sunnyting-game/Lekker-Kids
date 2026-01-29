import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../services/super_admin_service.dart';
import '../../repositories/platform_repository.dart';
import '../../models/school_model.dart';
import '../../services/tenant_functions_service.dart';


/// ViewModel for Super Admin Dashboard
/// Manges platform stats, authorization, and school management
class SuperAdminDashboardViewModel extends ChangeNotifier {
  final SuperAdminService _superAdminService;
  final PlatformRepository _platformRepository;
  final TenantFunctionsService _tenantFunctions;

  // State
  bool _isLoading = true;
  bool _isAuthorized = false;
  PlatformStats? _stats;
  String? _error;

  // Getters
  bool get isLoading => _isLoading;
  bool get isAuthorized => _isAuthorized;
  PlatformStats? get stats => _stats;
  String? get error => _error;

  // Streams
  Stream<List<SchoolModel>> get schoolsStream => _platformRepository.getSchoolsStream();

  SuperAdminDashboardViewModel({
    SuperAdminService? superAdminService,
    PlatformRepository? platformRepository,
    TenantFunctionsService? tenantFunctions,
  })  : _superAdminService = superAdminService ?? SuperAdminService(),
        _platformRepository = platformRepository ?? PlatformRepository(),
        _tenantFunctions = tenantFunctions ?? TenantFunctionsService() {
    _checkAuthorization();
  }

  /// Initial authorization check and data load
  Future<void> _checkAuthorization() async {
    _isLoading = true;
    notifyListeners();

    try {
      final isSuperAdmin = await _superAdminService.isSuperAdmin();
      if (!isSuperAdmin) {
        _isAuthorized = false;
        _isLoading = false;
        notifyListeners();
        return;
      }

      _isAuthorized = true;
      await _refreshStats();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refreshes platform statistics
  Future<void> _refreshStats() async {
    try {
      final stats = await _platformRepository.getPlatformStats();
      _stats = stats;
    } catch (e) {
      // Keep existing stats on error, just log internally or show snackbar via UI
      debugPrint('Error refreshing stats: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Force a manual refresh (e.g. after school creation)
  Future<void> refresh() async {
    await _refreshStats();
  }

  /// Update school subscription status
  Future<void> updateSchoolSubscription(String schoolId, SubscriptionStatus newStatus) async {
    try {
      await _platformRepository.updateSchoolSubscription(schoolId, newStatus.name);
      // Stats might change if status changes affecting counts (e.g. trial -> active)
      await _refreshStats();
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a school
  Future<void> deleteSchool(String schoolId) async {
    try {
      await _platformRepository.deleteSchool(schoolId);
      await _refreshStats();
    } catch (e) {
      rethrow;
    }
  }

  /// Create a new school
  /// Returns success status and school ID or error message
  Future<CreateSchoolResult> createSchool({
    required String name,
    required String adminEmail,
  }) async {
    try {
      final result = await _tenantFunctions.createSchool(
        name: name,
        adminEmail: adminEmail,
      );
      
      if (result.success) {
        await _refreshStats();
      }
      
      return result;
    } catch (e) {
      return CreateSchoolResult(
        success: false, 
        schoolId: '', 
        invitationId: '', 
        adminInviteToken: ''
      ); // Error handling wrapping
    }
  }

  /// Get student count for a specific school
  Future<int> getSchoolStudentCount(String schoolId) {
    return _platformRepository.getStudentCount(schoolId);
  }
}
