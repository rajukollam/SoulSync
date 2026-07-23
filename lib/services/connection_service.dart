import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/connection_model.dart';
import 'chat_service.dart';
class ConnectionService {
  ConnectionService({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _connections =>
      _firestore.collection('connections');

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get _sharedSpaces =>
      _firestore.collection('shared_spaces');

  CollectionReference<Map<String, dynamic>> get _conversations =>
      _firestore.collection('conversations');

  // =========================
  // FIND USER BY INVITE CODE
  // =========================

  Future<Map<String, dynamic>?> findUserByInviteCode(
    String inviteCode,
  ) async {
    final result = await _users
        .where(
          'inviteCode',
          isEqualTo: inviteCode.trim().toUpperCase(),
        )
        .limit(1)
        .get();

    if (result.docs.isEmpty) {
      return null;
    }

    return {
      'uid': result.docs.first.id,
      ...result.docs.first.data(),
    };
  }

  // =========================
  // CREATE CONNECTION
  // =========================

  Future<String> createConnection({
    required String currentUserId,
    required String otherUserId,
  }) async {
    if (currentUserId == otherUserId) {
      throw Exception("You can't connect with yourself.");
    }

    final existing = await _connections
        .where(
          'users',
          arrayContains: currentUserId,
        )
        .get();

    for (final doc in existing.docs) {
      final users =
          List<String>.from(doc.data()['users'] ?? []);

      if (users.contains(otherUserId)) {
        return doc.id;
      }
    }

    final connectionRef = _connections.doc();

    final batch = _firestore.batch();

    batch.set(
      connectionRef,
      {
        'users': [
          currentUserId,
          otherUserId,
        ],

        'createdBy': currentUserId,

        'createdAt': FieldValue.serverTimestamp(),

        'lastMessage': '',

        'lastMessageTime': null,

        'lastMessageSenderId': '',

        'unreadCounts': {
          currentUserId: 0,
          otherUserId: 0,
        },

        'isPinned': false,

        'isMuted': false,

        'isArchived': false,
      },
    );

    batch.set(
      _conversations.doc(connectionRef.id),
      {
        'createdAt': FieldValue.serverTimestamp(),
      },
    );

    batch.set(
      _sharedSpaces.doc(connectionRef.id),
      {
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'memoriesCount': 0,
        'galleryCount': 0,
        'diaryCount': 0,
        'playlistCount': 0,
        'calendarEvents': 0,
      },
    );

    await batch.commit();
    // Load user information
final currentUserDoc = await _users.doc(currentUserId).get();
final otherUserDoc = await _users.doc(otherUserId).get();

final currentUserData = currentUserDoc.data()!;
final otherUserData = otherUserDoc.data()!;

await ChatService().ensureChatExists(
  userAId: currentUserId,
  userAInfo: {
    'fullName': currentUserData['fullName'] ?? '',
    'photoUrl': currentUserData['photoUrl'] ?? '',
  },
  userBId: otherUserId,
  userBInfo: {
    'fullName': otherUserData['fullName'] ?? '',
    'photoUrl': otherUserData['photoUrl'] ?? '',
  },
);

    return connectionRef.id;
  }

  // =========================
  // LOAD CONNECTIONS
  // =========================

  Stream<List<ConnectionModel>> getConnections(
    String currentUserId,
  ) {
    return _connections
        .where(
          'users',
          arrayContains: currentUserId,
        )
        .orderBy(
          'lastMessageTime',
          descending: true,
        )
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(ConnectionModel.fromFirestore)
              .toList(),
        );
  }

  // =========================
  // ACTIVE SOUL
  // =========================

  Future<void> setActiveSoul({
    required String currentUserId,
    required String connectionId,
  }) async {
    await _users.doc(currentUserId).update(
      {
        'activeSoulConnectionId': connectionId,
      },
    );
  }

  Future<String?> getActiveSoul(
    String currentUserId,
  ) async {
    final doc = await _users.doc(currentUserId).get();

    if (!doc.exists) {
      return null;
    }

    final data = doc.data();

    return data?['activeSoulConnectionId'];
  }

  // =========================
  // REMOVE CONNECTION
  // =========================

  Future<void> removeConnection(
    String connectionId,
  ) async {
    await _connections.doc(connectionId).delete();
  }
}