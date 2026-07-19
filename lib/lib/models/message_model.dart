import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;

  final String senderId;

  final String text;

  final DateTime? sentAt;

  final List<String> seenBy;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    required this.sentAt,
    required this.seenBy,
  });

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return MessageModel(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      text: data['text'] ?? '',
      sentAt: (data['sentAt'] as Timestamp?)?.toDate(),
      seenBy: List<String>.from(
        data['seenBy'] ?? [],
      ),
    );
  }

  bool isSeenBy(String uid) {
    return seenBy.contains(uid);
  }
}