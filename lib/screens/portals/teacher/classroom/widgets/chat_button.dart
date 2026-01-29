import 'package:flutter/material.dart';
import '../../../../../constants/app_theme.dart';
import '../../../../../models/user_model.dart';
import '../../../../../widgets/chat_window.dart';

class ChatButton extends StatelessWidget {
  final UserModel student;
  final bool hasUnread;

  const ChatButton({
    super.key,
    required this.student,
    required this.hasUnread,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(
            Icons.chat_bubble_outline,
            color: AppColors.primary,
          ),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ChatWindow(
                  otherUserId: student.uid,
                  otherUserName: student.name ?? student.username,
                ),
              ),
            );
          },
          tooltip: 'Chat with ${student.name ?? student.username}',
        ),
        // Red dot badge for unread messages
        if (hasUnread)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 1.5,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
