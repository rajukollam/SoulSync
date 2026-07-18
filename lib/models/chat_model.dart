class ChatModel {
  final String chatId;
  final List<String> members;

  final String lastMessage;
  final DateTime? lastMessageAt;

  final Map<String, dynamic> memberInfo;

  ChatModel({
    required this.chatId,
    required this.members,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.memberInfo,
  });

  factory ChatModel.fromFirestore(dynamic doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ChatModel(
      chatId: doc.id,
      members: List<String>.from(data['members'] ?? []),
      lastMessage: data['lastMessage'] ?? '',
      lastMessageAt: data['lastMessageAt']?.toDate(),
      memberInfo: Map<String, dynamic>.from(
        data['memberInfo'] ?? {},
      ),
    );
  }
}