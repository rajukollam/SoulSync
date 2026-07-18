import 'package:hive_flutter/hive_flutter.dart';

import '../models/love_profile.dart';

class StorageService {
  static const String boxName = 'love_profile_box';
  static const String profileKey = 'profile';

  /// Open the Hive box
  static Future<void> init() async {
    await Hive.openBox<LoveProfile>(boxName);
  }

  /// Save profile
  static Future<void> saveProfile(LoveProfile profile) async {
    final box = Hive.box<LoveProfile>(boxName);
    await box.put(profileKey, profile);
  }

  /// Get profile
  static LoveProfile? getProfile() {
    final box = Hive.box<LoveProfile>(boxName);
    return box.get(profileKey);
  }

  /// Check if profile exists
  static bool hasProfile() {
    final box = Hive.box<LoveProfile>(boxName);
    return box.containsKey(profileKey);
  }

  /// Delete profile
  static Future<void> deleteProfile() async {
    final box = Hive.box<LoveProfile>(boxName);
    await box.delete(profileKey);
  }

  /// Update profile
  static Future<void> updateProfile(LoveProfile profile) async {
    final box = Hive.box<LoveProfile>(boxName);
    await box.put(profileKey, profile);
  }
}