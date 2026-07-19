import 'package:cloud_firestore/cloud_firestore.dart';

class SharedSpaceModel {
  final String connectionId;

  final int memoriesCount;
  final int galleryCount;
  final int diaryCount;
  final int playlistCount;
  final int calendarEvents;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  SharedSpaceModel({
    required this.connectionId,
    required this.memoriesCount,
    required this.galleryCount,
    required this.diaryCount,
    required this.playlistCount,
    required this.calendarEvents,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SharedSpaceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return SharedSpaceModel(
      connectionId: doc.id,
      memoriesCount: data['memoriesCount'] ?? 0,
      galleryCount: data['galleryCount'] ?? 0,
      diaryCount: data['diaryCount'] ?? 0,
      playlistCount: data['playlistCount'] ?? 0,
      calendarEvents: data['calendarEvents'] ?? 0,
      createdAt: data['createdAt']?.toDate(),
      updatedAt: data['updatedAt']?.toDate(),
    );
  }
}