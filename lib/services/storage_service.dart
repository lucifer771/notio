import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:notio/models/note.dart';
import 'package:notio/models/tag.dart';
import 'package:notio/models/user_model.dart';

class StorageService {
  static const String keyUserProfile = 'user_profile';
  static const String keyNotes = 'notes';
  static const String keyTags = 'tags';
  static const String keyIntroSeen = 'seen_intro';

  // Singleton pattern
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // --- User Profile ---
  Future<void> saveUserProfile(UserProfile user) async {
    await _prefs.setString(keyUserProfile, jsonEncode(user.toJson()));
  }

  UserProfile getUserProfile() {
    final String? userJson = _prefs.getString(keyUserProfile);
    if (userJson == null) {
      // If no profile exists, check if we have a legacy userName from previous step
      final legacyName = _prefs.getString('user_name');
      if (legacyName != null) {
        return UserProfile(id: 'legacy', name: legacyName, email: '');
      }
      return UserProfile.guest();
    }
    return UserProfile.fromJson(jsonDecode(userJson));
  }

  // --- Intro Seen ---
  Future<void> setIntroSeen() async {
    await _prefs.setBool(keyIntroSeen, true);
  }

  bool isIntroSeen() {
    return _prefs.getBool(keyIntroSeen) ?? false;
  }

  // --- Notes ---
  Future<void> saveNotes(List<Note> notes) async {
    final List<String> notesJson = notes
        .map((note) => jsonEncode(note.toJson()))
        .toList();
    await _prefs.setStringList(keyNotes, notesJson);
  }

  List<Note> getNotes() {
    final List<String>? notesJson = _prefs.getStringList(keyNotes);
    if (notesJson == null) return [];
    return notesJson.map((str) => Note.fromJson(jsonDecode(str))).toList();
  }

  // --- Tags ---
  Future<void> saveTags(List<Tag> tags) async {
    final List<String> tagsJson = tags
        .map((tag) => jsonEncode(tag.toJson()))
        .toList();
    await _prefs.setStringList(keyTags, tagsJson);
  }

  List<Tag> getTags() {
    final List<String>? tagsJson = _prefs.getStringList(keyTags);
    if (tagsJson == null) return [];
    return tagsJson.map((str) => Tag.fromJson(jsonDecode(str))).toList();
  }
}
