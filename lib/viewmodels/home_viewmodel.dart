import 'dart:async';
import 'package:flutter/foundation.dart';
import '../repositories/user_repository.dart';
import '../services/student_service.dart';
import '../models/daily_status.dart';
import '../models/photo_item.dart';

/// ViewModel for the HomeTab
/// Manages state and business logic for banner images, daily status, and photos
/// 
/// This ViewModel subscribes to Firestore streams internally and exposes
/// simple state properties to the View, eliminating the need for StreamBuilder.
class HomeViewModel extends ChangeNotifier {
  final UserRepository _userRepository;
  final StudentService _studentService;
  final String userId;

  // Stream subscriptions for cleanup
  StreamSubscription<DailyStatus>? _dailyStatusSubscription;
  StreamSubscription<List<PhotoItem>>? _photosSubscription;

  HomeViewModel({
    required UserRepository userRepository,
    required StudentService studentService,
    required this.userId,
  })  : _userRepository = userRepository,
        _studentService = studentService {
    _initializeStreams();
  }

  // ============================================
  // Banner State
  // ============================================
  String? _bannerImageUrl;
  bool _isUploadingBanner = false;

  String? get bannerImageUrl => _bannerImageUrl;
  bool get isUploadingBanner => _isUploadingBanner;

  // ============================================
  // Daily Status State
  // ============================================
  DailyStatus? _dailyStatus;
  bool _isDailyStatusLoading = true;
  String? _dailyStatusError;

  DailyStatus? get dailyStatus => _dailyStatus;
  bool get isDailyStatusLoading => _isDailyStatusLoading;
  String? get dailyStatusError => _dailyStatusError;

  // ============================================
  // Photos State
  // ============================================
  List<PhotoItem> _photos = [];
  bool _isPhotosLoading = true;
  String? _photosError;

  List<PhotoItem> get photos => _photos;
  bool get isPhotosLoading => _isPhotosLoading;
  String? get photosError => _photosError;

  // ============================================
  // Unified Loading State
  // ============================================
  /// Returns true if any critical data is still loading
  bool get isLoading => _isDailyStatusLoading || _isPhotosLoading;

  // ============================================
  // Error State (for general errors like banner upload)
  // ============================================
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // ============================================
  // Initialization
  // ============================================
  void _initializeStreams() {
    // Load banner (this doesn't require school context)
    loadBanner();

    // Guard: Skip stream subscriptions if no school context
    // This happens when non-student users (admin/teacher) are logged in
    if (!_studentService.hasSchoolContext) {
      _isDailyStatusLoading = false;
      _isPhotosLoading = false;
      return;
    }

    // Subscribe to daily status stream
    final today = _studentService.getTodayDate();
    _dailyStatusSubscription = _studentService
        .getDailyStatusStream(userId, today)
        .listen(
      (status) {
        _dailyStatus = status;
        _isDailyStatusLoading = false;
        _dailyStatusError = null;
        notifyListeners();
      },
      onError: (error) {
        _isDailyStatusLoading = false;
        _dailyStatusError = 'Failed to load daily status: $error';
        notifyListeners();
      },
    );

    // Subscribe to photos stream
    _photosSubscription = _userRepository
        .getPhotosStream(userId, today)
        .listen(
      (photoList) {
        _photos = photoList;
        _isPhotosLoading = false;
        _photosError = null;
        notifyListeners();
      },
      onError: (error) {
        _isPhotosLoading = false;
        _photosError = 'Failed to load photos: $error';
        notifyListeners();
      },
    );
  }

  // ============================================
  // Banner Operations
  // ============================================
  
  /// Load banner image from repository
  Future<void> loadBanner() async {
    try {
      _bannerImageUrl = await _userRepository.getBannerImageUrl(userId);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load banner: $e';
      notifyListeners();
    }
  }

  /// Pick and upload banner image
  Future<void> updateBanner() async {
    try {
      _isUploadingBanner = true;
      _errorMessage = null;
      notifyListeners();

      final downloadUrl = await _userRepository.uploadBannerImage(userId);
      
      _bannerImageUrl = downloadUrl;
      _isUploadingBanner = false;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _isUploadingBanner = false;
      
      // Only set error if user actually selected an image
      if (!e.toString().contains('No image selected')) {
        _errorMessage = e.toString();
      }
      
      notifyListeners();
    }
  }

  /// Clear error message after displaying
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ============================================
  // Cleanup
  // ============================================
  @override
  void dispose() {
    _dailyStatusSubscription?.cancel();
    _photosSubscription?.cancel();
    super.dispose();
  }
}
