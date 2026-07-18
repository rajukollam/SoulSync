import 'package:cloud_firestore/cloud_firestore.dart';

/// A text message stored at `chats/{chatId}/messages/{messageId}`.
class MessageModel {
  const MessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    required this.sentAt,
    required this.seen,
  });

  final String id;
  final String senderId;
  final String text;
  final DateTime? sentAt;
  final bool seen;

  factory MessageModel.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    return MessageModel(
      id: document.id,
      senderId: data['senderId'] as String? ?? '',
      text: data['text'] as String? ?? '',
      sentAt: (data['sentAt'] as Timestamp?)?.toDate(),
      seen: data['seen'] as bool? ?? false,
    );
  }
}
