import 'package:cloud_firestore/cloud_firestore.dart';

class PresenceService {
  PresenceService({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  Future<void> setOnline(String uid) async {
    print('🟢 setOnline called for $uid');

    await _users.doc(uid).set(
      {
        'online': true,
      },
      SetOptions(merge: true),
    );

    print('✅ online updated');
  }

  Future<void> setOffline(String uid) async {
    print('🔴 setOffline called for $uid');

    await _users.doc(uid).set(
      {
        'online': false,
        'lastSeen': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    print('✅ offline updated');
  }

  Future<void> setActiveChat({
    required String uid,
    required String chatId,
  }) async {
    await _users.doc(uid).set(
      {
        'activeChatId': chatId,
      },
      SetOptions(merge: true),
    );
  }

  Future<void> clearActiveChat(String uid) async {
    await _users.doc(uid).set(
      {
        'activeChatId': null,
      },
      SetOptions(merge: true),
    );
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> userPresence(String uid) {
    return _users.doc(uid).snapshots();
  }
}