import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:inner_garden/viewmodels/super_admin/super_admin_dashboard_viewmodel.dart';
import 'package:inner_garden/services/super_admin_service.dart';
import 'package:inner_garden/repositories/platform_repository.dart';
import 'package:inner_garden/services/tenant_functions_service.dart';
import 'package:inner_garden/models/school_model.dart';

// Generate mocks
@GenerateMocks([SuperAdminService, PlatformRepository, TenantFunctionsService])
import 'super_admin_dashboard_viewmodel_test.mocks.dart';

void main() {
  late SuperAdminDashboardViewModel viewModel;
  late MockSuperAdminService mockSuperAdminService;
  late MockPlatformRepository mockPlatformRepository;
  late MockTenantFunctionsService mockTenantFunctionsService;

  setUp(() {
    mockSuperAdminService = MockSuperAdminService();
    mockPlatformRepository = MockPlatformRepository();
    mockTenantFunctionsService = MockTenantFunctionsService();

    // Default setup for successful auth
    when(mockSuperAdminService.isSuperAdmin()).thenAnswer((_) async => true);
    when(mockPlatformRepository.getSchoolsStream())
        .thenAnswer((_) => Stream.value([]));
    when(mockPlatformRepository.getPlatformStats())
        .thenAnswer((_) async => PlatformStats(
              totalSchools: 10,
              activeSchools: 5,
              trialSchools: 3,
              suspendedSchools: 2,
            ));

    viewModel = SuperAdminDashboardViewModel(
      superAdminService: mockSuperAdminService,
      platformRepository: mockPlatformRepository,
      tenantFunctions: mockTenantFunctionsService,
    );
  });

  group('SuperAdminDashboardViewModel Tests', () {
    test('Initial authorization check - success', () async {
      // Allow async init to complete
      await Future.delayed(Duration.zero);

      expect(viewModel.isLoading, false);
      expect(viewModel.isAuthorized, true);
      expect(viewModel.stats?.totalSchools, 10);
      verify(mockSuperAdminService.isSuperAdmin()).called(1);
    });

    test('Initial authorization check - failure', () async {
      // Reset logic for this specific test
      when(mockSuperAdminService.isSuperAdmin()).thenAnswer((_) async => false);
      
      final unauthorizedViewModel = SuperAdminDashboardViewModel(
        superAdminService: mockSuperAdminService,
        platformRepository: mockPlatformRepository,
        tenantFunctions: mockTenantFunctionsService,
      );

      await Future.delayed(Duration.zero);

      expect(unauthorizedViewModel.isAuthorized, false);
      expect(unauthorizedViewModel.isLoading, false);
    });

    test('refreshStats - updates stats', () async {
      await Future.delayed(Duration.zero); // wait for init

      when(mockPlatformRepository.getPlatformStats())
        .thenAnswer((_) async => PlatformStats(
              totalSchools: 11,
              activeSchools: 6,
              trialSchools: 3,
              suspendedSchools: 2,
            ));

      await viewModel.refresh();

      expect(viewModel.stats?.totalSchools, 11);
      expect(viewModel.stats?.activeSchools, 6);
    });

    test('updateSchoolSubscription - success', () async {
      const schoolId = 'test-school';
      const newStatus = SubscriptionStatus.active;

      await viewModel.updateSchoolSubscription(schoolId, newStatus);

      verify(mockPlatformRepository.updateSchoolSubscription(schoolId, newStatus.name)).called(1);
      verify(mockPlatformRepository.getPlatformStats()).called(greaterThan(1)); // Initial + refresh
    });

    test('deleteSchool - success', () async {
      const schoolId = 'test-school';

      await viewModel.deleteSchool(schoolId);

      verify(mockPlatformRepository.deleteSchool(schoolId)).called(1);
      verify(mockPlatformRepository.getPlatformStats()).called(greaterThan(1));
    });

    test('createSchool - success', () async {
      const name = 'New School';
      const email = 'admin@school.com';
      
      when(mockTenantFunctionsService.createSchool(name: name, adminEmail: email))
          .thenAnswer((_) async => CreateSchoolResult(
              success: true, 
              schoolId: 'new-id',
              invitationId: 'inv-id',
              adminInviteToken: 'token'
          ));

      final result = await viewModel.createSchool(name: name, adminEmail: email);

      expect(result.success, true);
      expect(result.schoolId, 'new-id');
      verify(mockTenantFunctionsService.createSchool(name: name, adminEmail: email)).called(1);
      verify(mockPlatformRepository.getPlatformStats()).called(greaterThan(1));
    });
  });
}
