import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_message.dart';
import '../constants/firestore_collections.dart';
import '../repositories/student_repository.dart';
import 'package:flutter/foundation.dart';

class ChatService {
  final FirebaseFirestore _firestore;
  final StudentRepository _repository;

  ChatService({
    FirebaseFirestore? firestore,
    StudentRepository? repository,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _repository = repository ?? StudentRepository();

  // Generate chat ID - for group chat, use student ID
  // All teachers will chat with the student in the same chat room
  String getChatId(String userId1, String userId2) {
    // Determine which is the student ID
    // We'll pass studentId as userId2 from the UI
    return userId2; // This will be the student ID
  }

  // Send a message with unread flag sync
  Future<void> sendMessage({
    required String senderId,
    required String senderName,
    required String receiverId,
    required String message,
    required bool isSenderTeacher,
  }) async {
    try {
      final chatId = getChatId(senderId, receiverId);
      final messageData = ChatMessage(
        id: '', // Will be set by Firestore
        senderId: senderId,
        senderName: senderName,
        receiverId: receiverId,
        message: message,
        timestamp: DateTime.now(),
        isRead: false,
      );

      // Add message to chat
      await _firestore
          .collection(FirestoreCollections.chats)
          .doc(chatId)
          .collection(FirestoreCollections.messages)
          .add(messageData.toMap());

      // If student sends message to teacher, set hasUnreadFromStudent flag
      // This allows teacher's classroom view to show red dot
      if (!isSenderTeacher) {
        // Sender is student, so chatId is the student's ID
        await _repository.setHasUnreadFromStudent(chatId, true);
      }
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  // Backward compatible: Send message without isSenderTeacher flag
  // Will not trigger unread flag sync
  Future<void> sendMessageLegacy({
    required String senderId,
    required String senderName,
    required String receiverId,
    required String message,
  }) async {
    try {
      final chatId = getChatId(senderId, receiverId);
      final messageData = ChatMessage(
        id: '', // Will be set by Firestore
        senderId: senderId,
        senderName: senderName,
        receiverId: receiverId,
        message: message,
        timestamp: DateTime.now(),
        isRead: false,
      );

      await _firestore
          .collection(FirestoreCollections.chats)
          .doc(chatId)
          .collection(FirestoreCollections.messages)
          .add(messageData.toMap());
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  // Get messages stream between two users
  Stream<List<ChatMessage>> getMessagesStream(String userId1, String userId2) {
    final chatId = getChatId(userId1, userId2);

    return _firestore
        .collection(FirestoreCollections.chats)
        .doc(chatId)
        .collection(FirestoreCollections.messages)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ChatMessage.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Mark messages as read + clear unread flag
  Future<void> markAsRead({
    required String chatId,
    required String currentUserId,
    required bool isCurrentUserTeacher,
  }) async {
    try {
      // If teacher is reading, always clear the hasUnreadFromStudent flag
      // This should happen even if there are no new unread messages
      // chatId is the student's ID in our chat structure
      if (isCurrentUserTeacher) {
        await _repository.setHasUnreadFromStudent(chatId, false);
      }

      // Then mark individual messages as read
      final messagesSnapshot = await _firestore
          .collection(FirestoreCollections.chats)
          .doc(chatId)
          .collection(FirestoreCollections.messages)
          .where('receiverId', isEqualTo: currentUserId)
          .where('isRead', isEqualTo: false)
          .get();

      if (messagesSnapshot.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (var doc in messagesSnapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      // Silently fail - marking as read is not critical
      debugPrint('Failed to mark messages as read: $e');
    }
  }

  // Legacy mark as read (backward compatible)
  Future<void> markAsReadLegacy({
    required String chatId,
    required String currentUserId,
  }) async {
    try {
      final messagesSnapshot = await _firestore
          .collection(FirestoreCollections.chats)
          .doc(chatId)
          .collection(FirestoreCollections.messages)
          .where('receiverId', isEqualTo: currentUserId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in messagesSnapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      // Silently fail - marking as read is not critical
      debugPrint('Failed to mark messages as read: $e');
    }
  }

  // Get unread message count for a specific chat (legacy, for non-optimized views)
  Stream<int> getUnreadCountStream(String chatId, String currentUserId) {
    return _firestore
        .collection(FirestoreCollections.chats)
        .doc(chatId)
        .collection(FirestoreCollections.messages)
        .where('receiverId', isEqualTo: currentUserId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}

