import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/fcm_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  AuthProvider() {
    // Listen to auth state changes
    _authService.authStateChanges.listen((User? user) async {
      if (user != null) {
        _currentUser = await _authService.getUserData(user.uid);
        
        // Update FcmService with current user ID for token management
        FcmService().setCurrentUserId(user.uid);
        
        // Store/refresh FCM token when auth state is restored
        // This ensures token is updated even on app restart
        await _storeFcmToken();
      } else {
        _currentUser = null;
        
        // Clear user ID from FcmService on logout
        FcmService().setCurrentUserId(null);
      }
      notifyListeners();
    });
  }

  // Sign in
  Future<bool> signIn(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners(); // Only update once at start

    try {
      debugPrint('DEBUG AuthProvider: Starting sign in for username: $username');
      _currentUser = await _authService.signInWithUsername(username, password);
      _isLoading = false;
      debugPrint('DEBUG AuthProvider: Sign in successful, user: ${_currentUser?.username}');
      
      // Store FCM token for push notifications
      await _storeFcmToken();
      
      notifyListeners(); // Only update once at end
      return true;
    } catch (e) {
      // Extract clean error message (remove "Exception: " prefix if present)
      String errorMsg = e.toString();
      if (errorMsg.startsWith('Exception: ')) {
        errorMsg = errorMsg.substring(11);
      }
      _errorMessage = errorMsg;
      _isLoading = false;
      debugPrint('DEBUG AuthProvider: Sign in failed with error: $_errorMessage');
      notifyListeners(); // Only update once on error
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _authService.signOut();
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Store FCM token in Firestore for the current user
  Future<void> _storeFcmToken() async {
    if (_currentUser == null) return;
    
    try {
      final messaging = FirebaseMessaging.instance;
      final token = await messaging.getToken();
      if (token != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUser!.uid)
            .update({'fcmToken': token});
        debugPrint('FCM token stored for user: ${_currentUser!.uid}');
      }
    } catch (e) {
      debugPrint('Failed to store FCM token: $e');
    }
  }
}
