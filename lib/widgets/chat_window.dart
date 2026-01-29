import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat_message.dart';
import '../models/user_model.dart';
import '../services/chat_service.dart';
import '../providers/auth_provider.dart';
import '../constants/app_theme.dart';
import '../constants/app_strings.dart';

class ChatWindow extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;
  final bool isGroupChat;

  const ChatWindow({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
    this.isGroupChat = false,
  });

  @override
  State<ChatWindow> createState() => _ChatWindowState();
}

class _ChatWindowState extends State<ChatWindow> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  String _currentUserId = '';
  bool _isTeacher = false;

  @override
  void initState() {
    super.initState();
    // Mark messages as read when chat window opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markMessagesAsRead();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Mark all messages as read and clear unread flag
  void _markMessagesAsRead() {
    if (_currentUserId.isEmpty) return;
    
    final chatId = widget.otherUserId; // Chat ID is the student's ID
    _chatService.markAsRead(
      chatId: chatId,
      currentUserId: _currentUserId,
      isCurrentUserTeacher: _isTeacher,
    );
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _sendMessage(String currentUserId, String currentUserName, bool isTeacher) {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    _chatService.sendMessage(
      senderId: currentUserId,
      senderName: currentUserName,
      receiverId: widget.otherUserId,
      message: message,
      isSenderTeacher: isTeacher,
    );

    _messageController.clear();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUserId = authProvider.currentUser?.uid ?? '';
    final currentUserName = authProvider.currentUser?.name ?? 
                           authProvider.currentUser?.username ?? '';
    final isTeacher = authProvider.currentUser?.role == UserRole.teacher ||
                      authProvider.currentUser?.role == UserRole.admin;

    // Update instance variables for use in _markMessagesAsRead
    _currentUserId = currentUserId;
    _isTeacher = isTeacher;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherUserName),
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _chatService.getMessagesStream(
                currentUserId,
                widget.otherUserId,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: AppTextStyles.error,
                    ),
                  );
                }

                final messages = snapshot.data ?? [];

                // Mark messages as read when messages are loaded
                if (messages.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _markMessagesAsRead();
                  });
                }

                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      AppStrings.chatEmptyMessage,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  );
                }

                // Scroll to bottom when messages load
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(AppSpacing.paddingMedium),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == currentUserId;

                    return _MessageBubble(
                      message: message,
                      isMe: isMe,
                    );
                  },
                );
              },
            ),
          ),
          // Message input
          Container(
            padding: const EdgeInsets.all(AppSpacing.paddingMedium),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: AppStrings.chatInputHint,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMedium,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.paddingMedium,
                          vertical: AppSpacing.paddingSmall,
                        ),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _sendMessage(
                        currentUserId,
                        currentUserName,
                        isTeacher,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.paddingSmall),
                  IconButton(
                    onPressed: () => _sendMessage(
                      currentUserId,
                      currentUserName,
                      isTeacher,
                    ),
                    icon: const Icon(Icons.send),
                    color: AppColors.primary,
                    tooltip: AppStrings.chatSendButton,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;

  const _MessageBubble({
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.paddingSmall),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.paddingMedium,
              vertical: AppSpacing.paddingSmall,
            ),
            decoration: BoxDecoration(
              color: isMe ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(
                      bottom: AppSpacing.paddingXSmall,
                    ),
                    child: Text(
                      message.senderName,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                        fontSize: 12.0,
                      ),
                    ),
                  ),
                Text(
                  message.message,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isMe ? AppColors.textWhite : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.paddingXSmall),
                Text(
                  _formatTime(message.timestamp),
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: 11.0,
                    color: isMe
                        ? AppColors.textWhite.withValues(alpha: 0.7)
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${timestamp.month}/${timestamp.day} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else {
      return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }
}
