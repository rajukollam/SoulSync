import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/message_model.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({super.key, required this.message, required this.isMine});

  final MessageModel message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final timestamp = message.sentAt == null
        ? 'Sending…'
        : DateFormat.jm().format(message.sentAt!);
    final bubbleColor = isMine ? AppColors.primary : AppColors.surfaceLight;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * .78),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.fromLTRB(14, 10, 12, 7),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMine ? 18 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            SelectableText(message.text, style: const TextStyle(color: Colors.white, height: 1.3)),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(timestamp, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                if (isMine) ...[
                  const SizedBox(width: 4),
                  Icon(message.seen ? Icons.done_all : Icons.done, size: 16,
                      color: message.seen ? Colors.lightBlueAccent : Colors.white70),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
