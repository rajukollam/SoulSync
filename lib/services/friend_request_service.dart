import 'package:cloud_firestore/cloud_firestore.dart';
import 'connection_service.dart';

class FriendRequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _requests =>
      _firestore.collection('friend_requests');

  /// Send a new friend request
  Future<void> sendRequest({
    required String fromUserId,
    required String toUserId,
  }) async {
    final existing = await _requests
        .where('fromUserId', isEqualTo: fromUserId)
        .where('toUserId', isEqualTo: toUserId)
        .where('status', isEqualTo: 'pending')
        .get();

    if (existing.docs.isNotEmpty) {
      throw Exception("Request already sent.");
    }

    await _requests.add({
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Incoming requests
  Stream<QuerySnapshot> incomingRequests(String userId) {
    return _requests
        .where('toUserId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  /// NEW: Sent requests
  Stream<QuerySnapshot> sentRequests(String userId) {
    return _requests
        .where('fromUserId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  /// Accept request
  Future<void> acceptRequest({
    required String requestId,
    required String currentUserId,
    required String otherUserId,
  }) async {
    await _requests.doc(requestId).update({
      'status': 'accepted',
    });

    await ConnectionService().createConnection(
      currentUserId: currentUserId,
      otherUserId: otherUserId,
    );
  }

  /// Reject request
  Future<void> rejectRequest(String requestId) async {
    await _requests.doc(requestId).update({
      'status': 'rejected',
    });
  }

  /// NEW: Cancel request
  Future<void> cancelRequest(String requestId) async {
    await _requests.doc(requestId).delete();
  }
}