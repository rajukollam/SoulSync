import 'package:flutter/material.dart';

import '../../models/chat_model.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../core/utils/date_formatter.dart';
import 'chat_screen.dart';
import 'search_users_screen.dart';
import 'requests_screen.dart';
import 'widgets/conversation_tile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final AuthService _authService = AuthService();
  final ChatService _chatService = ChatService();
  final FirebaseFirestore _firestore =
    FirebaseFirestore.instance;

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

    return SafeArea(
      top: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              10,
            ),
            child: Row(
              children: [
                Expanded(
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
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                StreamBuilder<QuerySnapshot>(
  stream: _firestore
      .collection('friend_requests')
      .where(
        'toUserId',
        isEqualTo: currentUser.uid,
      )
      .where(
        'status',
        isEqualTo: 'pending',
      )
      .snapshots(),
  builder: (context, snapshot) {
    final count =
        snapshot.data?.docs.length ?? 0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          tooltip: 'Requests',
          icon: const Icon(
            Icons.mail_outline,
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RequestsScreen(),
              ),
            );
          },
        ),

        if (count > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding:
                  const EdgeInsets.all(5),
              decoration:
                  const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Text(
                count.toString(),
                style:
                    const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  },
),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
            ),
            child: InkWell(
              borderRadius:
                  BorderRadius.circular(16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const SearchUsersScreen(),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primaryContainer,
                  borderRadius:
                      BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      child: Icon(Icons.person_add),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add Friend',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Connect using an Invite Code',
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          Expanded(
                        child: StreamBuilder<List<ChatModel>>(
              stream: _chatService.chatList(currentUser.uid),
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

                if (filteredChats.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 60,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'No conversations yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Tap "Add Friend" to start chatting.',
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(
                    top: 4,
                    bottom: 20,
                  ),
                  itemCount: filteredChats.length,
                  itemBuilder: (
                    context,
                    index,
                  ) {
                    final chat =
                        filteredChats[index];

                    final partnerId =
                        chat.members.firstWhere(
                      (id) =>
                          id != currentUser.uid,
                    );

                    final info =
                        chat.memberInfo[partnerId]
                            as Map<String, dynamic>?;

                    final partnerName =
                        info?['fullName'] ??
                            'Unknown';

                    final partnerPhoto =
                        info?['photoUrl'] ?? '';

                    final time =
                        DateFormatter
                            .formatChatTime(
                      chat.lastMessageAt,
                    );

                    final unreadCount =
                        (chat.unreadCounts[
                                    currentUser.uid] ??
                                0)
                            as int;

                    return ConversationTile(
                      partnerId:
                          partnerId,
                      partnerName:
                          partnerName,
                      partnerPhoto:
                          partnerPhoto,
                      lastMessage:
                          chat.lastMessage,
                      time: time,
                      unreadCount:
                          unreadCount,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ChatScreen(
                              partnerId:
                                  partnerId,
                              partnerName:
                                  partnerName,
                              partnerPhoto:
                                  partnerPhoto,
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