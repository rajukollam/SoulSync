import 'package:cloud_firestore/cloud_firestore.dart';

class FriendRequestModel {
  final String id;
  final String fromUserId;
  final String toUserId;
  final String status;
  final Timestamp createdAt;

  FriendRequestModel({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.status,
    required this.createdAt,
  });

  factory FriendRequestModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return FriendRequestModel(
      id: doc.id,
      fromUserId: data['fromUserId'],
      toUserId: data['toUserId'],
      status: data['status'],
      createdAt: data['createdAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'status': status,
      'createdAt': createdAt,
    };
  }
}