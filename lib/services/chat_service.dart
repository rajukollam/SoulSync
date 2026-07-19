import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/message_model.dart';

class ChatService {
  ChatService({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  // =========================
  // MESSAGES
  // =========================

  Stream<List<MessageModel>> messages({
    required String connectionId,
  }) {
    return _messagesReference(connectionId)
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

  // =========================
  // SEND MESSAGE
  // =========================

  Future<void> sendMessage({
    required String connectionId,
    required String senderId,
    required String text,
  }) async {
    final trimmed = text.trim();

    if (trimmed.isEmpty) return;

    final conversationRef = _conversationReference(connectionId);

    final messageRef = conversationRef
        .collection('messages')
        .doc();

    final batch = _firestore.batch();

    batch.set(
      conversationRef,
      {
        'lastMessage': trimmed,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': senderId,
      },
      SetOptions(
        merge: true,
      ),
    );

    batch.set(
      messageRef,
      {
        'senderId': senderId,
        'text': trimmed,
        'sentAt': FieldValue.serverTimestamp(),
        'seenBy': [senderId],
      },
    );

    await batch.commit();
  }

  // =========================
  // MARK SEEN
  // =========================

  Future<void> markMessagesSeen({
    required String connectionId,
    required String currentUserId,
    required List<MessageModel> messages,
  }) async {
    final unread = messages.where(
      (message) =>
          message.senderId != currentUserId &&
          !message.isSeenBy(currentUserId),
    );

    if (unread.isEmpty) return;

    final batch = _firestore.batch();

    final ref = _messagesReference(connectionId);

    for (final message in unread) {
      batch.update(
        ref.doc(message.id),
        {
          'seenBy': FieldValue.arrayUnion(
            [currentUserId],
          ),
        },
      );
    }

    await batch.commit();
  }

  // =========================
  // REFERENCES
  // =========================

  DocumentReference<Map<String, dynamic>>
      _conversationReference(
    String connectionId,
  ) {
    return _firestore
        .collection('conversations')
        .doc(connectionId);
  }

  CollectionReference<Map<String, dynamic>>
      _messagesReference(
    String connectionId,
  ) {
    return _conversationReference(
      connectionId,
    ).collection('messages');
  }
}