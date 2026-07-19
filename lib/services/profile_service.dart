import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  Future<Map<String, dynamic>?> getProfile(String uid) async {
    final doc = await _users.doc(uid).get();

    if (!doc.exists) return null;

    return {
      'uid': doc.id,
      ...doc.data()!,
    };
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> profileStream(String uid) {
    return _users.doc(uid).snapshots();
  }

  Future<void> updateProfile({
    required String uid,
    required String fullName,
    String? photoUrl,
    DateTime? dateOfBirth,
    String? bio,
  }) async {
    await _users.doc(uid).update({
      'fullName': fullName,
      'photoUrl': photoUrl ?? '',
      'dateOfBirth':
          dateOfBirth != null ? Timestamp.fromDate(dateOfBirth) : null,
      'bio': bio ?? '',
    });
  }

  Future<Map<String, dynamic>?> findPartnerByCode(String inviteCode) async {
    final result = await _users
        .where(
          'inviteCode',
          isEqualTo: inviteCode.trim().toUpperCase(),
        )
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
    if (currentUid == partnerUid) {
      throw Exception("You can't connect with yourself.");
    }

    final currentDoc = await _users.doc(currentUid).get();
    final partnerDoc = await _users.doc(partnerUid).get();

    if (!currentDoc.exists || !partnerDoc.exists) {
      throw Exception("User not found.");
    }

    final currentData = currentDoc.data()!;
    final partnerData = partnerDoc.data()!;

    if (currentData['isCoupled'] == true) {
      throw Exception("You are already connected.");
    }

    if (partnerData['isCoupled'] == true) {
      throw Exception("This user is already connected.");
    }

    final batch = _firestore.batch();

    final now = Timestamp.now();

    batch.update(_users.doc(currentUid), {
      'partnerId': partnerUid,
      'isCoupled': true,
      'relationshipDate': now,
    });

    batch.update(_users.doc(partnerUid), {
      'partnerId': currentUid,
      'isCoupled': true,
      'relationshipDate': now,
    });

    await batch.commit();
  }

  Future<Map<String, dynamic>?> getPartner(String uid) async {
    final profile = await getProfile(uid);

    if (profile == null) return null;

    final partnerId = profile['partnerId'];

    if (partnerId == null || partnerId.toString().isEmpty) {
      return null;
    }

    return await getProfile(partnerId);
  }
}