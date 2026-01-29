import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'viewmodels/home_viewmodel.dart';
import 'viewmodels/album_viewmodel.dart';
import 'viewmodels/common/document_list_view_model.dart';
import 'repositories/user_repository.dart';
import 'services/student_service.dart';
import 'services/photo_service.dart';
import 'services/fcm_service.dart';
import 'models/user_model.dart';
import 'screens/login_page.dart';
import 'screens/portals/teacher_portal.dart';
import 'screens/portals/admin_portal.dart';
import 'screens/portals/student_portal.dart';
import 'screens/super_admin/super_admin_dashboard.dart';
import 'constants/app_strings.dart';
import 'constants/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Initialize FCM
    final fcmService = FcmService();
    await fcmService.initialize();
    
    // Note: FCM token storage is now handled in AuthProvider.signIn()
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
        ),
        ChangeNotifierProxyProvider<AuthProvider, HomeViewModel>(
          create: (context) {
            final authProvider = Provider.of<AuthProvider>(context, listen: false);
            final user = authProvider.currentUser;
            final userId = user?.uid ?? '';
            final schoolId = user?.schoolIds.isNotEmpty == true 
                ? user!.schoolIds.first 
                : '';
            final studentService = StudentService();
            if (schoolId.isNotEmpty) {
              studentService.setSchoolContext(schoolId);
            }
            return HomeViewModel(
              userRepository: UserRepository(),
              studentService: studentService,
              userId: userId,
            );
          },
          update: (context, authProvider, previous) {
            final user = authProvider.currentUser;
            final userId = user?.uid ?? '';
            final schoolId = user?.schoolIds.isNotEmpty == true 
                ? user!.schoolIds.first 
                : '';
            // Only create new instance if userId changed
            if (previous?.userId != userId) {
              final studentService = StudentService();
              if (schoolId.isNotEmpty) {
                studentService.setSchoolContext(schoolId);
              }
              return HomeViewModel(
                userRepository: UserRepository(),
                studentService: studentService,
                userId: userId,
              );
            }
            return previous!;
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, AlbumViewModel>(
          create: (context) {
            final authProvider = Provider.of<AuthProvider>(context, listen: false);
            final userId = authProvider.currentUser?.uid ?? '';
            return AlbumViewModel(
              photoService: FirebasePhotoService(),
              userId: userId,
            );
          },
          update: (context, authProvider, previous) {
            final userId = authProvider.currentUser?.uid ?? '';
            // Only create new instance if userId changed
            if (previous?.userId != userId) {
              return AlbumViewModel(
                photoService: FirebasePhotoService(),
                userId: userId,
              );
            }
            return previous!;
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, DocumentListViewModel>(
          create: (context) {
            final authProvider = Provider.of<AuthProvider>(context, listen: false);
            final userId = authProvider.currentUser?.uid ?? '';
            final vm = DocumentListViewModel(userId: userId);
            if (userId.isNotEmpty) {
              vm.fetchDocuments();
            }
            return vm;
          },
          update: (context, authProvider, previous) {
            final userId = authProvider.currentUser?.uid ?? '';
            
            // Create new ViewModel if:
            // 1. No previous instance
            // 2. UserId changed
            // 3. Previous was empty but now we have a valid userId
            if (previous == null || 
                previous.userId != userId ||
                (previous.userId.isEmpty && userId.isNotEmpty)) {
              final vm = DocumentListViewModel(userId: userId);
              if (userId.isNotEmpty) {
                vm.fetchDocuments();
              }
              return vm;
            }
            return previous;
          },
        ),
      ],
      child: MaterialApp(
        title: AppStrings.appName,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
          useMaterial3: true,
        ),
        home: const AuthWrapper(),
        routes: {
          '/super-admin': (context) => const SuperAdminDashboard(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    // Set up FCM document notification handler at app level
    // This persists across tab switches unlike per-tab registration
    FcmService().onDocumentNotification = _handleDocumentNotification;
  }

  void _handleDocumentNotification() {
    if (!mounted) return;
    
    // Defensive: ensure FcmService has current user ID
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUser != null) {
      FcmService().setCurrentUserId(authProvider.currentUser!.uid);
    }
    
    // Refresh the global DocumentListViewModel
    try {
      final viewModel = Provider.of<DocumentListViewModel>(context, listen: false);
      viewModel.refresh();
      debugPrint('FCM: Document refresh triggered from AuthWrapper');
    } catch (e) {
      debugPrint('FCM: Failed to refresh documents: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Show loading screen while checking auth state
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // If not authenticated, show login page
        if (!authProvider.isAuthenticated) {
          return const LoginPage();
        }

        // Route to appropriate portal based on user role
        final user = authProvider.currentUser;
        if (user == null) {
          return const LoginPage();
        }

        // Super Admin gets their own dashboard
        if (user.isSuperAdmin) {
          return const SuperAdminDashboard();
        }

        switch (user.role) {
          case UserRole.teacher:
            return const TeacherPortal();
          case UserRole.admin:
            return const AdminPortal();
          case UserRole.student:
            return const StudentPortal();
        }
      },
    );
  }
}
