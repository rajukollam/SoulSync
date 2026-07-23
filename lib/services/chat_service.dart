import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/chat_model.dart';
import '../models/message_model.dart';

/// Handles 1:1 chat conversations between a user and their connected partner.
///
/// Chats are stored in a top-level `chats` collection. Each chat document's
/// id is derived deterministically from the two members' uids (sorted and
/// joined), so both people always land on the same conversation regardless
/// of who opened it first or who is "current" vs "partner" in the UI.
class ChatService {
  ChatService({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _chats =>
      _firestore.collection('chats');

  /// Deterministic chat id for a pair of users, order-independent.
  static String chatIdFor(String userA, String userB) {
    final ids = [userA, userB]..sort();
    return ids.join('_');
  }

  DocumentReference<Map<String, dynamic>> _chatDoc(String chatId) =>
      _chats.doc(chatId);

  CollectionReference<Map<String, dynamic>> _messagesRef(String chatId) =>
      _chatDoc(chatId).collection('messages');

  // =========================
  // CHAT LIST
  // =========================

  Stream<List<ChatModel>> chatList(String uid) {
    return _chats
        .where('members', arrayContains: uid)
        .snapshots()
        .map((snapshot) {
      final chats = snapshot.docs.map(ChatModel.fromFirestore).toList();

      // Newest conversation first. Chats with no messages yet (lastMessageAt
      // is null) are pushed to the bottom instead of being sorted randomly.
      chats.sort((a, b) {
        final aTime = a.lastMessageAt;
        final bTime = b.lastMessageAt;

        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;

        return bTime.compareTo(aTime);
      });

      return chats;
    });
  }

  // =========================
  // MESSAGES
  // =========================

  Stream<List<MessageModel>> messages({
    required String currentUserId,
    required String partnerId,
  }) {
    final chatId = chatIdFor(currentUserId, partnerId);

    return _messagesRef(chatId)
        .orderBy('sentAt', descending: true)
        .limit(200)
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
    required String currentUserId,
    required String partnerId,
    required String text,
  }) async {
    final trimmed = text.trim();

    if (trimmed.isEmpty) return;

    final chatId = chatIdFor(currentUserId, partnerId);
    final chatRef = _chatDoc(chatId);
    final messageRef = _messagesRef(chatId).doc();

    final batch = _firestore.batch();

    batch.set(
      chatRef,
      {
        'members': [currentUserId, partnerId],
        'lastMessage': trimmed,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastMessageSenderId': currentUserId,
        // Nested-map merge only touches the partner's counter, it doesn't
        // wipe out the rest of the unreadCounts map.
        'unreadCounts': {
          partnerId: FieldValue.increment(1),
        },
      },
      SetOptions(merge: true),
    );

   batch.set(
  messageRef,
  {
    'senderId': currentUserId,
    'text': trimmed,
    'sentAt': FieldValue.serverTimestamp(),

    // Sender has obviously received their own message.
    'deliveredTo': [currentUserId],

    // Sender has also seen their own message.
    'seenBy': [currentUserId],
  },
);

    await batch.commit();
  }
// =========================
// MARK RECEIVED MESSAGES DELIVERED
// =========================

Future<void> markReceivedMessagesDelivered({
  required String currentUserId,
  required String partnerId,
  required List<MessageModel> messages,
}) async {
  print("========== DELIVERED CALLED ==========");
  print("Current User: $currentUserId");

  final undelivered = messages.where(
    (message) =>
        message.senderId != currentUserId &&
        !message.isDeliveredTo(currentUserId),
  ).toList();

  print("Undelivered count: ${undelivered.length}");

  if (undelivered.isEmpty) {
    print("Nothing to update");
    return;
  }

  final chatId = chatIdFor(currentUserId, partnerId);
  final ref = _messagesRef(chatId);

  final batch = _firestore.batch();

  for (final message in undelivered) {
    print("Updating message: ${message.id}");

    batch.update(
      ref.doc(message.id),
      {
        'deliveredTo': FieldValue.arrayUnion([currentUserId]),
      },
    );
  }

  await batch.commit();

  print("Delivered updated successfully");
}
  // =========================
  // MARK RECEIVED MESSAGES SEEN
  // =========================


  Future<void> markReceivedMessagesSeen({
    required String currentUserId,
    required String partnerId,
    required List<MessageModel> messages,
  }) async {
    final unread = messages.where(
      (message) =>
          message.senderId != currentUserId &&
          !message.isSeenBy(currentUserId),
    );

    if (unread.isEmpty) return;

    final chatId = chatIdFor(currentUserId, partnerId);
    final ref = _messagesRef(chatId);

    final batch = _firestore.batch();

    for (final message in unread) {
      batch.update(
        ref.doc(message.id),
        {
          'seenBy': FieldValue.arrayUnion([currentUserId]),
        },
      );
    }

    await batch.commit();
  }

  // =========================
  // RESET UNREAD COUNT
  // =========================

  Future<void> resetUnreadCount({
    required String currentUserId,
    required String partnerId,
  }) async {
    final chatId = chatIdFor(currentUserId, partnerId);

    await _chatDoc(chatId).set(
      {
        'unreadCounts': {
          currentUserId: 0,
        },
      },
      SetOptions(merge: true),
    );
  }

  // =========================
  // ENSURE CHAT EXISTS
  // =========================

  /// Creates (or refreshes) the chat document for a newly-connected couple
  /// so it shows up immediately in the chat list, even before any message
  /// has been sent.
  Future<void> ensureChatExists({
    required String userAId,
    required Map<String, dynamic> userAInfo,
    required String userBId,
    required Map<String, dynamic> userBInfo,
  }) async {
    final chatId = chatIdFor(userAId, userBId);

    await _chatDoc(chatId).set(
      {
        'members': [userAId, userBId],
        'memberInfo': {
          userAId: userAInfo,
          userBId: userBInfo,
        },
        'lastMessage': '',
        'lastMessageAt': null,
        'unreadCounts': {
          userAId: 0,
          userBId: 0,
        },
      },
      SetOptions(merge: true),
    );
  }
}
