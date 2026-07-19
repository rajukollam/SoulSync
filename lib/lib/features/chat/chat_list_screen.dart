import 'package:flutter/material.dart';

import '../../models/chat_model.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import 'chat_screen.dart';
import 'widgets/conversation_tile.dart';
import '../../core/utils/date_formatter.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final AuthService _authService = AuthService();
  final ChatService _chatService = ChatService();

  final TextEditingController _searchController =
      TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _authService.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text('User not logged in'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              12,
              16,
              8,
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search chats...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(14),
                ),
              ),
              onChanged: (_) {
                setState(() {});
              },
            ),
          ),

          Expanded(
            child: StreamBuilder<List<ChatModel>>(
              stream: _chatService.chatList(
                currentUser.uid,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      snapshot.error.toString(),
                    ),
                  );
                }

                final chats = snapshot.data ?? [];

                if (chats.isEmpty) {
                  return const Center(
                    child: Text(
                      'No conversations yet ❤️',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }

                final filteredChats = chats.where((chat) {
                  final partnerId = chat.members.firstWhere(
                    (id) => id != currentUser.uid,
                  );

                  final info =
                      chat.memberInfo[partnerId]
                          as Map<String, dynamic>?;

                  final name =
                      (info?['fullName'] ?? '')
                          .toString()
                          .toLowerCase();

                  return name.contains(
                    _searchController.text
                        .trim()
                        .toLowerCase(),
                  );
                }).toList();

                return ListView.separated(
                  padding: const EdgeInsets.only(
                    bottom: 20,
                  ),
                  itemCount: filteredChats.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final chat = filteredChats[index];

                    final partnerId = chat.members.firstWhere(
                      (id) => id != currentUser.uid,
                    );

                    final info =
                        chat.memberInfo[partnerId]
                            as Map<String, dynamic>?;

                    final partnerName =
                        info?['fullName'] ?? 'Unknown';

                    final partnerPhoto = info?['photoUrl'] ?? '';

final time = DateFormatter.formatChatTime(
  chat.lastMessageAt,
);

final unreadCount =
    (chat.unreadCounts[currentUser.uid] ?? 0) as int;


return ConversationTile(
  partnerName: partnerName,
  partnerPhoto: partnerPhoto,
  lastMessage: chat.lastMessage,
  time: time,
  unreadCount: unreadCount,
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          partnerId: partnerId,
          partnerName: partnerName,
          partnerPhoto: partnerPhoto,
        ),
      ),
    );
  },
);
  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}