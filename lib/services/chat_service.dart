import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/chat_model.dart';
import '../models/message_model.dart';
import 'profile_service.dart';

class ChatService {
  ChatService({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  final ProfileService _profileService = ProfileService();

  String getChatId(
    String firstUserId,
    String secondUserId,
  ) {
    final ids = [firstUserId, secondUserId]..sort();
    return '${ids.first}_${ids.last}';
  }

  // =========================
  // CHAT LIST
  // =========================

  Stream<List<ChatModel>> chatList(String currentUserId) {
    return _firestore
        .collection('chats')
        .where(
          'members',
          arrayContains: currentUserId,
        )
        .orderBy(
          'lastMessageAt',
          descending: true,
        )
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(ChatModel.fromFirestore)
              .toList(growable: false),
        );
  }

  // =========================
  // MESSAGES
  // =========================

  Stream<List<MessageModel>> messages({
    required String currentUserId,
    required String partnerId,
  }) {
    return _messagesReference(
      currentUserId,
      partnerId,
    )
        .orderBy(
          'sentAt',
          descending: true,
        )
        .limit(100)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(MessageModel.fromFirestore)
              .toList(growable: false),
        );
  }

  Future<void> sendMessage({
    required String currentUserId,
    required String partnerId,
    required String text,
  }) async {
    final trimmed = text.trim();

    if (trimmed.isEmpty) return;

    final currentProfile =
        await _profileService.getProfile(currentUserId);

    final partnerProfile =
        await _profileService.getProfile(partnerId);

    final chatRef = _chatReference(
      currentUserId,
      partnerId,
    );

    final messageRef = chatRef.collection('messages').doc();

    final batch = _firestore.batch();

    batch.set(
      chatRef,
      {
        'members': [currentUserId, partnerId]..sort(),

        'memberInfo': {
          currentUserId: {
            'uid': currentUserId,
            'fullName':
                currentProfile?['fullName'] ?? 'Unknown',
            'photoUrl':
                currentProfile?['photoUrl'] ?? '',
          },

          partnerId: {
            'uid': partnerId,
            'fullName':
                partnerProfile?['fullName'] ?? 'Unknown',
            'photoUrl':
                partnerProfile?['photoUrl'] ?? '',
          },
        },

        'lastMessage': trimmed,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(
        merge: true,
      ),
    );

        batch.set(
      messageRef,
      {
        'senderId': currentUserId,
        'text': trimmed,
        'sentAt': FieldValue.serverTimestamp(),
        'seen': false,
      },
    );

    await batch.commit();
  }

  Future<void> markReceivedMessagesSeen({
    required String currentUserId,
    required String partnerId,
    required List<MessageModel> messages,
  }) async {
    final unread = messages.where(
      (m) => !m.seen && m.senderId != currentUserId,
    );

    if (unread.isEmpty) return;

    final batch = _firestore.batch();

    final ref = _messagesReference(
      currentUserId,
      partnerId,
    );

    for (final message in unread) {
      batch.update(
        ref.doc(message.id),
        {
          'seen': true,
        },
      );
    }

    await batch.commit();
  }

  DocumentReference<Map<String, dynamic>> _chatReference(
    String currentUserId,
    String partnerId,
  ) {
    return _firestore
        .collection('chats')
        .doc(
          getChatId(
            currentUserId,
            partnerId,
          ),
        );
  }

  CollectionReference<Map<String, dynamic>> _messagesReference(
    String currentUserId,
    String partnerId,
  ) {
    return _chatReference(
      currentUserId,
      partnerId,
    ).collection('messages');
  }
}