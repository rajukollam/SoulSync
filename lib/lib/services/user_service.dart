import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_profile_model.dart';

class UserService {
  UserService({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  // =========================
  // GET USER
  // =========================

  Future<UserProfileModel?> getUser(
    String uid,
  ) async {
    final doc = await _users.doc(uid).get();

    if (!doc.exists) {
      return null;
    }

    return UserProfileModel.fromFirestore(doc);
  }

  // =========================
  // USER STREAM
  // =========================

  Stream<UserProfileModel?> userStream(
    String uid,
  ) {
    return _users.doc(uid).snapshots().map(
      (doc) {
        if (!doc.exists) {
          return null;
        }

        return UserProfileModel.fromFirestore(doc);
      },
    );
  }

  // =========================
  // FIND USER BY INVITE CODE
  // =========================

  Future<UserProfileModel?> findByInviteCode(
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

    return UserProfileModel.fromFirestore(
      result.docs.first,
    );
  }

  // =========================
  // UPDATE PROFILE
  // =========================

  Future<void> updateProfile({
    required String uid,
    required String fullName,
    required String bio,
    required String photoUrl,
    DateTime? dateOfBirth,
  }) async {
    await _users.doc(uid).update(
      {
        'fullName': fullName,
        'bio': bio,
        'photoUrl': photoUrl,
        'dateOfBirth': dateOfBirth != null
            ? Timestamp.fromDate(dateOfBirth)
            : null,
      },
    );
  }

  // =========================
  // SET ACTIVE SOUL
  // =========================

  Future<void> setActiveSoul({
    required String uid,
    required String connectionId,
  }) async {
    await _users.doc(uid).update(
      {
        'activeSoulConnectionId': connectionId,
      },
    );
  }
}