import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>?> getProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();

    if (!doc.exists) return null;

    return doc.data();
  }

  Future<void> updateProfile({
    required String uid,
    required String fullName,
    String? photoUrl,
    DateTime? dateOfBirth,
    String? bio,
  }) async {
    await _firestore.collection('users').doc(uid).update({
      'fullName': fullName,
      'photoUrl': photoUrl ?? '',
      'dateOfBirth':
          dateOfBirth != null ? Timestamp.fromDate(dateOfBirth) : null,
      'bio': bio ?? '',
    });
  }

  Future<Map<String, dynamic>?> findPartnerByCode(String inviteCode) async {
    final result = await _firestore
        .collection('users')
        .where('inviteCode', isEqualTo: inviteCode.toUpperCase())
        .limit(1)
        .get();

    if (result.docs.isEmpty) return null;

    return {
      'uid': result.docs.first.id,
      ...result.docs.first.data(),
    };
  }

  Future<void> connectPartners({
    required String currentUid,
    required String partnerUid,
  }) async {
    final batch = _firestore.batch();

    final currentRef = _firestore.collection('users').doc(currentUid);
    final partnerRef = _firestore.collection('users').doc(partnerUid);

    final now = Timestamp.now();

    batch.update(currentRef, {
      'partnerId': partnerUid,
      'isCoupled': true,
      'relationshipDate': now,
    });

    batch.update(partnerRef, {
      'partnerId': currentUid,
      'isCoupled': true,
      'relationshipDate': now,
    });

    await batch.commit();
  }
}