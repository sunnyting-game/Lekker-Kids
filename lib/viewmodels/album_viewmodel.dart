import 'package:flutter/foundation.dart';
import '../services/photo_service.dart';

/// ViewModel for the AlbumTab
/// Manages photo data with daily caching strategy:
/// - Loads data only on first entry or after midnight crossing
/// - Uses parallel fetching for better performance
/// - No real-time updates (cached until next day or manual refresh)
class AlbumViewModel extends ChangeNotifier {
  final PhotoService _photoService;
  final String userId;

  AlbumViewModel({
    required PhotoService photoService,
    required this.userId,
  }) : _photoService = photoService {
    loadPhotos();
  }

  // ============================================
  // State
  // ============================================
  Map<String, List<Map<String, dynamic>>> _photosByDate = {};
  bool _isLoading = false;
  String? _errorMessage;
  String? _lastLoadedDate;

  Map<String, List<Map<String, dynamic>>> get photosByDate => _photosByDate;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ============================================
  // Data Loading
  // ============================================

  /// Load photos for the last 14 days
  /// Only fetches if:
  /// 1. First time loading (never loaded before)
  /// 2. Date has changed (crossed midnight)
  Future<void> loadPhotos() async {
    final today = _getTodayDate();

    // Skip if already loaded today
    if (_lastLoadedDate == today && _photosByDate.isNotEmpty) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Use the existing PhotoService method but as Future
      final result = await _photoService.getPhotosByDateStream(
        studentId: userId,
        daysBack: 14,
      ).first;

      _photosByDate = result;
      _lastLoadedDate = today;
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to load photos: $e';
      notifyListeners();
    }
  }

  /// Manual refresh - forces reload regardless of date
  Future<void> refresh() async {
    _lastLoadedDate = null; // Clear cache
    await loadPhotos();
  }

  // ============================================
  // Helpers
  // ============================================

  String _getTodayDate() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
