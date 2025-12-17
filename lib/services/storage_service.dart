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
        return UserProfile(
          id: 'legacy',
          name: legacyName,
          email: '',
          isGuest: true, // Treat as guest to restrict access
        );
      }
      return UserProfile.guest();
    }
    // Parse existing profile
    final profile = UserProfile.fromJson(jsonDecode(userJson));

    // Migration/Fix: If profile has no email/password but isGuest is false, treat as Guest
    if (!profile.isGuest && profile.email.isEmpty && profile.password == null) {
      return profile.copyWith(isGuest: true);
    }
    return profile;
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

  // Helper: Save a single note (add or update)
  Future<void> saveNote(Note note) async {
    final List<Note> currentNotes = getNotes();
    final int index = currentNotes.indexWhere((n) => n.id == note.id);

    if (index != -1) {
      // Update existing
      currentNotes[index] = note;
    } else {
      // Add new
      currentNotes.add(note);
    }
    await saveNotes(currentNotes);
  }

  // Helper: Delete a single note
  Future<void> deleteNote(String id) async {
    final List<Note> currentNotes = getNotes();
    currentNotes.removeWhere((n) => n.id == id);
    await saveNotes(currentNotes);
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
