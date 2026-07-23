import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfileModel {
  final String uid;

  final String fullName;
  final String email;
  final String photoUrl;
  final String bio;
  final String inviteCode;

  final DateTime? dateOfBirth;

  final String activeSoulConnectionId;

  // Presence fields
  final bool online;
  final DateTime? lastSeen;

  UserProfileModel({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.photoUrl,
    required this.bio,
    required this.inviteCode,
    required this.dateOfBirth,
    required this.activeSoulConnectionId,
    this.online = false,
    this.lastSeen,
  });

  factory UserProfileModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return UserProfileModel(
      uid: doc.id,
      fullName: data['fullName'] ?? '',
      email: data['email'] ?? '',
      photoUrl: data['photoUrl'] ?? '',
      bio: data['bio'] ?? '',
      inviteCode: data['inviteCode'] ?? '',
      dateOfBirth: (data['dateOfBirth'] as Timestamp?)?.toDate(),
      activeSoulConnectionId: data['activeSoulConnectionId'] ?? '',

      // Presence
      online: data['online'] ?? false,
      lastSeen: (data['lastSeen'] as Timestamp?)?.toDate(),
    );
  }
}