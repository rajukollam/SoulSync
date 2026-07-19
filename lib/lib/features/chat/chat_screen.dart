import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/message_model.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../partner/connect_partner_screen.dart';
import 'widgets/message_bubble.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.partnerId,
    required this.partnerName,
    required this.partnerPhoto,
  });

  final String partnerId;
  final String partnerName;
  final String partnerPhoto;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _composerController = TextEditingController();
  final _chatService = ChatService();
  final _authService = AuthService();

  bool _isSending = false;

  Future<void> _sendMessage() async {
    final text = _composerController.text.trim();
    final currentUser = _authService.currentUser;

    if (text.isEmpty || currentUser == null || _isSending) return;

    setState(() => _isSending = true);

    _composerController.clear();

    try {
      await _chatService.sendMessage(
        currentUserId: currentUser.uid,
        partnerId: widget.partnerId,
        text: text,
      );
    } catch (_) {
      if (mounted) {
        _composerController.text = text;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Message could not be sent. Please try again.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  void dispose() {
    _composerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _authService.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: _ChatErrorState(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: widget.partnerPhoto.isEmpty
                  ? null
                  : NetworkImage(widget.partnerPhoto),
              child: widget.partnerPhoto.isEmpty
                  ? const Icon(Icons.favorite_outline)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.partnerName,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '$value feature coming soon 🚀',
                  ),
                ),
              );
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'profile',
                child: Text('👤 View Profile'),
              ),
              PopupMenuItem(
                value: 'pin',
                child: Text('📌 Pin Chat'),
              ),
              PopupMenuItem(
                value: 'block',
                child: Text('🚫 Block User'),
              ),
              PopupMenuDivider(),
              PopupMenuItem(
                value: 'delete',
                child: Text('🗑 Delete Chat'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _chatService.messages(
                currentUserId: currentUser.uid,
                partnerId: widget.partnerId,
              ),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const _ChatErrorState();
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final messages = snapshot.data!;

                _markReceivedMessagesSeen(
                  currentUser.uid,
                  widget.partnerId,
                  messages,
                );

                if (messages.isEmpty) {
                  return _EmptyChatState(
                    name: widget.partnerName,
                  );
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];

                    return MessageBubble(
                      message: message,
                      isMine: message.senderId == currentUser.uid,
                      isSeenByPartner: message.isSeenBy(widget.partnerId),
                    );
                  },
                );
              },
            ),
          ),
          _MessageComposer(
            controller: _composerController,
            isSending: _isSending,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }

  void _markReceivedMessagesSeen(
    String currentUserId,
    String partnerId,
    List<MessageModel> messages,
  ) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chatService
    .markReceivedMessagesSeen(
      currentUserId: currentUserId,
      partnerId: partnerId,
      messages: messages,
    )
    .then((_) {
      return _chatService.resetUnreadCount(
        currentUserId: currentUserId,
        partnerId: partnerId,
      );
    })
    .catchError((_) {});
          
    });
  }
}
class _MessageComposer extends StatelessWidget {
  const _MessageComposer({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              tooltip: 'Send',
              onPressed: isSending ? null : onSend,
              icon: isSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.send_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyChatState extends StatelessWidget {
  const _EmptyChatState({
    required this.name,
  });

  final String name;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.chat_bubble_outline_rounded,
              size: 54,
              color: AppColors.heart,
            ),
            const SizedBox(height: 18),
            Text(
              'Start chatting with $name',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            const Text(
              'Send your first message and begin the conversation.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatErrorState extends StatelessWidget {
  const _ChatErrorState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Text(
          'Unable to load this conversation.\nPlease try again.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _NotConnectedChat extends StatelessWidget {
  const _NotConnectedChat();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.favorite_border,
                size: 54,
                color: AppColors.heart,
              ),
              const SizedBox(height: 16),
              Text(
                'Connect with your partner first',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                'Once connected, you can start chatting instantly.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ConnectPartnerScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.favorite),
                label: const Text('Connect Partner'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}