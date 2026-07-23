import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Generates a random 6-character invite code
  String generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();

    return List.generate(
      6,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }

  /// Create new user
  Future<void> createUser({
    required String uid,
    required String fullName,
    required String email,
  }) async {
    await _firestore.collection('users').doc(uid).set({
      'fullName': fullName,
      'email': email,
      'inviteCode': generateInviteCode(),
      'partnerId': '',
      'relationshipDate': null,
      'isCoupled': false,
      'profilePhoto': '',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getUser(
    String uid,
  ) async {
    return await _firestore
        .collection('users')
        .doc(uid)
        .get();
  }

  Future<void> updateUser(
    String uid,
    Map<String, dynamic> data,
  ) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .update(data);
  }

  /// Find a user by invite code
  Future<QuerySnapshot<Map<String, dynamic>>> findUserByInviteCode(
    String code,
  ) async {
    return await _firestore
        .collection('users')
        .where('inviteCode', isEqualTo: code.toUpperCase())
        .limit(1)
        .get();
  }
}