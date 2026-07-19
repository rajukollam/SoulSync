import 'package:hive/hive.dart';

part 'love_profile.g.dart';

@HiveType(typeId: 0)
class LoveProfile extends HiveObject {
  @HiveField(0)
  String yourName;

  @HiveField(1)
  String partnerName;

  @HiveField(2)
  DateTime relationshipDate;

  @HiveField(3)
  String yourPhoto;

  @HiveField(4)
  String partnerPhoto;

  LoveProfile({
    required this.yourName,
    required this.partnerName,
    required this.relationshipDate,
    this.yourPhoto = '',
    this.partnerPhoto = '',
  });
}