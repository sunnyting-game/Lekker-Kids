import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../widgets/chat_window.dart';
import '../../../providers/auth_provider.dart';

class ParentChatTab extends StatelessWidget {
  const ParentChatTab({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUserId = authProvider.currentUser?.uid ?? '';

    // For student portal, show chat directly
    // The chat is a group chat with all teachers
    return ChatWindow(
      otherUserId: currentUserId, // Use student's own ID as chat ID
      otherUserName: 'Teachers', // Display name for the chat
      isGroupChat: true, // Flag to indicate this is a group chat
    );
  }
}
