import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/message_model.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../services/profile_service.dart';
import '../partner/connect_partner_screen.dart';
import 'widgets/message_bubble.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _composerController = TextEditingController();
  final _chatService = ChatService();
  final _authService = AuthService();
  final _profileService = ProfileService();
  late final Future<_ChatPartner?> _partnerFuture;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _partnerFuture = _loadPartner();
  }

  Future<_ChatPartner?> _loadPartner() async {
    final user = _authService.currentUser;
    if (user == null) return null;
    final profile = await _profileService.getProfile(user.uid);
    final partnerId = profile?['partnerId'] as String?;
    if (partnerId == null || partnerId.isEmpty) return null;

    final partnerProfile = await _profileService.getProfile(partnerId);
    return _ChatPartner(
      id: partnerId,
      name: partnerProfile?['fullName'] as String? ?? 'Your partner',
      photoUrl: (partnerProfile?['photoUrl'] ?? partnerProfile?['profilePhoto']) as String? ?? '',
    );
  }

  Future<void> _sendMessage(_ChatPartner partner) async {
    final text = _composerController.text.trim();
    final currentUser = _authService.currentUser;
    if (text.isEmpty || currentUser == null || _isSending) return;

    setState(() => _isSending = true);
    _composerController.clear();
    try {
      await _chatService.sendMessage(
        currentUserId: currentUser.uid,
        partnerId: partner.id,
        text: text,
      );
    } catch (_) {
      if (mounted) {
        _composerController.text = text;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message could not be sent. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  void dispose() {
    _composerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_ChatPartner?>(
      future: _partnerFuture,
      builder: (context, partnerSnapshot) {
        if (partnerSnapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (partnerSnapshot.hasError) {
          return const Scaffold(body: _ChatErrorState());
        }
        final partner = partnerSnapshot.data;
        if (partner == null) return const _NotConnectedChat();
        final currentUser = _authService.currentUser;
        if (currentUser == null) return const Scaffold(body: _ChatErrorState());

        return Scaffold(
          
appBar: AppBar(
            centerTitle: false,
            titleSpacing: 0,
            title: Row(children: [
              CircleAvatar(
                backgroundImage: partner.photoUrl.isEmpty ? null : NetworkImage(partner.photoUrl),
                child: partner.photoUrl.isEmpty ? const Icon(Icons.favorite_outline) : null,
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(partner.name, overflow: TextOverflow.ellipsis)),
            ]),
            actions: [
              PopupMenuButton<String>(
                onSelected: (value){
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$value feature coming soon 🚀')),
                  );
                },
                itemBuilder: (context)=> const[
                  PopupMenuItem(value:'profile',child:Text('👤 View Profile')),
                  PopupMenuItem(value:'pin',child:Text('📌 Pin Chat')),
                  PopupMenuItem(value:'block',child:Text('🚫 Block User')),
                  PopupMenuDivider(),
                  PopupMenuItem(value:'delete',child:Text('🗑 Delete Chat')),
                ],
              )
            ],
          ),
          body: Column(children: [
            Expanded(
              child: StreamBuilder<List<MessageModel>>(
                stream: _chatService.messages(currentUserId: currentUser.uid, partnerId: partner.id),
                builder: (context, snapshot) {
                  if (snapshot.hasError) return const _ChatErrorState();
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final messages = snapshot.data!;
                  _markReceivedMessagesSeen(currentUser.uid, partner.id, messages);
                  if (messages.isEmpty) return _EmptyChatState(name: partner.name);
                  return ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      return MessageBubble(message: message, isMine: message.senderId == currentUser.uid);
                    },
                  );
                },
              ),
            ),
            _MessageComposer(
              controller: _composerController,
              isSending: _isSending,
              onSend: () => _sendMessage(partner),
            ),
          ]),
        );
      },
    );
  }

  void _markReceivedMessagesSeen(String currentUserId, String partnerId, List<MessageModel> messages) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chatService.markReceivedMessagesSeen(
        currentUserId: currentUserId,
        partnerId: partnerId,
        messages: messages,
      ).catchError((_) {});
    });
  }
}

class _ChatPartner {
  const _ChatPartner({required this.id, required this.name, required this.photoUrl});
  final String id;
  final String name;
  final String photoUrl;
}

class _MessageComposer extends StatelessWidget {
  const _MessageComposer({required this.controller, required this.isSending, required this.onSend});
  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: const InputDecoration(hintText: 'Message your partner…', contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 12)),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              tooltip: 'Send message',
              onPressed: isSending ? null : onSend,
              icon: isSending
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.send_rounded),
            ),
          ]),
        ),
      );
}

class _EmptyChatState extends StatelessWidget {
  const _EmptyChatState({required this.name});
  final String name;
  @override
  Widget build(BuildContext context) => Center(child: Padding(
    padding: const EdgeInsets.all(32),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.favorite_outline, size: 48, color: AppColors.heart),
      const SizedBox(height: 16),
      Text('Start your conversation with $name', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      const Text('Your messages appear here in real time.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
    ]),
  ));
}

class _ChatErrorState extends StatelessWidget {
  const _ChatErrorState();
  @override
  Widget build(BuildContext context) => const Center(child: Padding(
    padding: EdgeInsets.all(32),
    child: Text('We could not load this conversation. Check your connection and try again.', textAlign: TextAlign.center),
  ));
}

class _NotConnectedChat extends StatelessWidget {
  const _NotConnectedChat();
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Chat')),
    body: Center(child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.favorite_border, size: 52, color: AppColors.heart),
        const SizedBox(height: 16),
        Text('Connect with your partner first', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        const Text('Once connected, you can share messages here in real time.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 20),
        FilledButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ConnectPartnerScreen())), icon: const Icon(Icons.favorite), label: const Text('Connect partner')),
      ]),
    )),
  );
}
