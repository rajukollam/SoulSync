import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/status_model.dart';

/// Handles reading, uploading, and deleting Status updates.
///
/// Statuses are stored in a top-level `statuses` collection in Firestore;
/// their images live in Firebase Storage under `status_images/{uid}/`.
/// Visibility to connected/friend users is enforced by the app only ever
/// querying statuses for the current user's own connections (see
/// [ConnectionService.getConnections]) rather than by browsing all statuses.
class StatusService {
  StatusService({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  /// How long a status stays visible after it's posted.
  static const Duration expiryDuration = Duration(hours: 24);

  CollectionReference<Map<String, dynamic>> get _statuses =>
      _firestore.collection('statuses');

  // =========================
  // UPLOAD
  // =========================

  /// Uploads [file] to Firebase Storage and creates the matching Firestore
  /// status document. [onProgress] is called with a 0.0-1.0 value while the
  /// upload is in flight.
  Future<void> uploadStatus({
    required String uid,
    required File file,
    void Function(double progress)? onProgress,
  }) async {
    final now = DateTime.now();
    final fileName = '${now.millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref().child('status_images/$uid/$fileName');

    final uploadTask = ref.putFile(file);

    final subscription = uploadTask.snapshotEvents.listen((snapshot) {
      if (onProgress != null && snapshot.totalBytes > 0) {
        onProgress(snapshot.bytesTransferred / snapshot.totalBytes);
      }
    });

    try {
      await uploadTask;
    } finally {
      await subscription.cancel();
    }

    final imageUrl = await ref.getDownloadURL();

    await _statuses.add({
      'userId': uid,
      'imageUrl': imageUrl,
      'storagePath': ref.fullPath,
      'createdAt': Timestamp.fromDate(now),
      'expiresAt': Timestamp.fromDate(now.add(expiryDuration)),
    });
  }

  // =========================
  // READ
  // =========================

  /// Active (non-expired) statuses for [uid], oldest first so a viewer can
  /// page through them chronologically.
  Stream<List<StatusModel>> statusesForUser(String uid) {
    return _statuses
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) {
      final statuses =
          snapshot.docs.map(StatusModel.fromFirestore).toList();

      return statuses.where((status) => !status.isExpired).toList();
    });
  }

  // =========================
  // DELETE
  // =========================

  /// Deletes a status the user owns (Firestore doc + Storage file).
  Future<void> deleteStatus(StatusModel status) async {
    await _statuses.doc(status.id).delete();

    if (status.storagePath.isNotEmpty) {
      try {
        await _storage.ref(status.storagePath).delete();
      } catch (_) {
        // Already gone, or storage rules changed - the Firestore doc is
        // what the app reads from, so this is safe to ignore.
      }
    }
  }

  /// Best-effort cleanup of [uid]'s own expired statuses, so they don't
  /// linger in Storage/Firestore. Safe to call opportunistically (e.g. when
  /// the Status tab opens); failures are ignored.
  Future<void> deleteExpiredForUser(String uid) async {
    try {
      final snapshot =
          await _statuses.where('userId', isEqualTo: uid).get();

      final expired = snapshot.docs
          .map(StatusModel.fromFirestore)
          .where((status) => status.isExpired);

      for (final status in expired) {
        await deleteStatus(status);
      }
    } catch (_) {
      // Non-critical background cleanup - ignore errors.
    }
  }
}
