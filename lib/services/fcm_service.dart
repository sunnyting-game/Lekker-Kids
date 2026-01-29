import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service to handle Firebase Cloud Messaging for document notifications
class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  
  // Track current user for token updates
  String? _currentUserId;
  
  // Callback to trigger when document-related notification is received
  VoidCallback? onDocumentNotification;

  /// Initialize FCM and request permissions
  Future<void> initialize() async {
    // Request permission (iOS/Web)
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('FCM: User granted permission');
    }

    // Get FCM token (for server-side targeting)
    String? token = await _messaging.getToken();
    debugPrint('FCM Token: $token');

    // Listen to token refresh
    _messaging.onTokenRefresh.listen(_handleTokenRefresh);
    
    // Listen to foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Listen to messages when app is opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }

  /// Handle messages when app is in foreground
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('FCM: Foreground message received from ${message.from}');
    debugPrint('FCM: Notification: ${message.notification?.toString()}');
    debugPrint('FCM: Data: ${message.data}');

    // Check if this is a document-related notification
    if (message.data['type'] == 'new_document' || 
        message.data['type'] == 'document_update') {
      debugPrint('FCM: Document notification detected, triggering refresh');
      onDocumentNotification?.call();
    }
  }

  /// Handle when user taps notification (app was in background)
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('FCM: Notification tapped');
    // Handle navigation or refresh based on notification
    if (message.data['type'] == 'new_document' || 
        message.data['type'] == 'document_update') {
      onDocumentNotification?.call();
    }
  }

  /// Subscribe to a topic (e.g., for organization-wide notifications)
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    debugPrint('FCM: Subscribed to topic: $topic');
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
    debugPrint('FCM: Unsubscribed from topic: $topic');
  }

  /// Set current user ID for token management
  /// Called by AuthProvider when user logs in/out
  void setCurrentUserId(String? userId) {
    _currentUserId = userId;
    debugPrint('FCM: User ID set to: $userId');
    
    // Update token immediately when user is set
    if (userId != null) {
      _updateCurrentToken();
    }
  }

  /// Handle token refresh events
  void _handleTokenRefresh(String newToken) async {
    debugPrint('FCM: Token refreshed to: $newToken');
    await _updateTokenInFirestore(newToken);
  }

  /// Update FCM token in Firestore
  Future<void> _updateTokenInFirestore(String token) async {
    if (_currentUserId == null) {
      debugPrint('FCM: No user ID set, skipping token update');
      return;
    }
    
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUserId)
          .update({'fcmToken': token});
      debugPrint('FCM: Token updated in Firestore for user: $_currentUserId');
    } catch (e) {
      debugPrint('FCM: Failed to update token in Firestore: $e');
    }
  }

  /// Get current token and store it in Firestore
  Future<void> _updateCurrentToken() async {
    try {
      String? token = await _messaging.getToken();
      if (token != null) {
        await _updateTokenInFirestore(token);
      }
    } catch (e) {
      debugPrint('FCM: Failed to get current token: $e');
    }
  }
}
