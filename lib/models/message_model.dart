import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String text;
  final DateTime? sentAt;

  /// Users who have received this message.
  final List<String> deliveredTo;

  /// Users who have opened/read this message.
  final List<String> seenBy;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    required this.sentAt,
    required this.deliveredTo,
    required this.seenBy,
  });

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return MessageModel(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      text: data['text'] ?? '',
      sentAt: (data['sentAt'] as Timestamp?)?.toDate(),
      deliveredTo: List<String>.from(
        data['deliveredTo'] ?? [],
      ),
      seenBy: List<String>.from(
        data['seenBy'] ?? [],
      ),
    );
  }

  bool isDeliveredTo(String uid) {
    return deliveredTo.contains(uid);
  }

  bool isSeenBy(String uid) {
    return seenBy.contains(uid);
  }
}