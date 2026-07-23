import 'package:cloud_firestore/cloud_firestore.dart';

/// A single status update (an image shared with connected users for 24
/// hours), similar to WhatsApp's Status feature.
///
/// Stored in the top-level `statuses` Firestore collection. The image bytes
/// themselves live in Firebase Storage under `status_images/{userId}/...`;
/// [storagePath] keeps track of that location so the file can be removed
/// when the status is deleted or expires.
class StatusModel {
  final String id;
  final String userId;
  final String imageUrl;
  final String storagePath;
  final DateTime createdAt;
  final DateTime expiresAt;

  StatusModel({
    required this.id,
    required this.userId,
    required this.imageUrl,
    required this.storagePath,
    required this.createdAt,
    required this.expiresAt,
  });

  factory StatusModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return StatusModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      storagePath: data['storagePath'] ?? '',
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt:
          (data['expiresAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
