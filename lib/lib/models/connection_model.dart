import 'package:cloud_firestore/cloud_firestore.dart';

class ConnectionModel {
  final String connectionId;
  final List<String> users;

  final String createdBy;
  final DateTime? createdAt;

  final String lastMessage;
  final DateTime? lastMessageTime;
  final String lastMessageSenderId;

  final Map<String, dynamic> unreadCounts;

  final bool isPinned;
  final bool isMuted;
  final bool isArchived;

  ConnectionModel({
    required this.connectionId,
    required this.users,
    required this.createdBy,
    required this.createdAt,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.lastMessageSenderId,
    required this.unreadCounts,
    required this.isPinned,
    required this.isMuted,
    required this.isArchived,
  });

  factory ConnectionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ConnectionModel(
      connectionId: doc.id,
      users: List<String>.from(data['users'] ?? []),
      createdBy: data['createdBy'] ?? '',
      createdAt: data['createdAt']?.toDate(),
      lastMessage: data['lastMessage'] ?? '',
      lastMessageTime: data['lastMessageTime']?.toDate(),
      lastMessageSenderId: data['lastMessageSenderId'] ?? '',
      unreadCounts: Map<String, dynamic>.from(
        data['unreadCounts'] ?? {},
      ),
      isPinned: data['isPinned'] ?? false,
      isMuted: data['isMuted'] ?? false,
      isArchived: data['isArchived'] ?? false,
    );
  }
}