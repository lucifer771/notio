import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:notio/models/note.dart';
import 'package:notio/models/tag.dart';
import 'package:notio/models/user_model.dart';
import 'package:notio/models/reminder.dart';

class StorageService {
  static const String keyUserProfile = 'user_profile';
  static const String keyAuthToken = 'auth_token';
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

  // --- Auth Token ---
  Future<void> saveAuthToken(String token) async {
    await _prefs.setString(keyAuthToken, token);
  }

  String? getAuthToken() {
    return _prefs.getString(keyAuthToken);
  }

  Future<void> clearAuthToken() async {
    await _prefs.remove(keyAuthToken);
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
    if (!profile.isGuest &&
        profile.email.isEmpty &&
        profile.appLockPin == null) {
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
    final List<String> notesJson =
        notes.map((note) => jsonEncode(note.toJson())).toList();
    await _prefs.setStringList(keyNotes, notesJson);
  }

  /// Returns ALL notes (active, archived, trashed) from storage directly.
  /// Use specific getters for filtering.
  List<Note> _getAllNotesRaw() {
    final List<String>? notesJson = _prefs.getStringList(keyNotes);
    if (notesJson == null) return [];
    return notesJson.map((str) => Note.fromJson(jsonDecode(str))).toList();
  }

  /// Returns only Active notes (not archived, not trashed)
  List<Note> getNotes() {
    return _getAllNotesRaw()
        .where((n) => !n.isArchived && !n.isTrashed)
        .toList();
  }

  /// Returns only Archived notes
  List<Note> getArchivedNotes() {
    return _getAllNotesRaw()
        .where((n) => n.isArchived && !n.isTrashed)
        .toList();
  }

  /// Returns only Trashed notes
  List<Note> getTrashedNotes() {
    return _getAllNotesRaw().where((n) => n.isTrashed).toList();
  }

  // Helper: Save a single note (add or update)
  Future<void> saveNote(Note note) async {
    final List<Note> currentNotes = _getAllNotesRaw();
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

  // Move to Trash
  Future<void> trashNote(String id) async {
    final notes = _getAllNotesRaw();
    final index = notes.indexWhere((n) => n.id == id);
    if (index != -1) {
      notes[index] = notes[index].copyWith(isTrashed: true, isArchived: false);
      await saveNotes(notes);
    }
  }

  // Restore from Trash or Archive
  Future<void> restoreNote(String id) async {
    final notes = _getAllNotesRaw();
    final index = notes.indexWhere((n) => n.id == id);
    if (index != -1) {
      notes[index] = notes[index].copyWith(isTrashed: false, isArchived: false);
      await saveNotes(notes);
    }
  }

  // Archive Note
  Future<void> archiveNote(String id) async {
    final notes = _getAllNotesRaw();
    final index = notes.indexWhere((n) => n.id == id);
    if (index != -1) {
      notes[index] = notes[index].copyWith(isArchived: true, isTrashed: false);
      await saveNotes(notes);
    }
  }

  // Unarchive Note (specific counterpart to archiveNote)
  Future<void> unarchiveNote(String id) async {
    final notes = _getAllNotesRaw();
    final index = notes.indexWhere((n) => n.id == id);
    if (index != -1) {
      notes[index] = notes[index].copyWith(isArchived: false, isTrashed: false);
      await saveNotes(notes);
    }
  }

  // Delete Permanently
  Future<void> deleteNotePermanently(String id) async {
    final notes = _getAllNotesRaw();
    notes.removeWhere((n) => n.id == id);
    await saveNotes(notes);
  }

  // --- Tags ---
  Future<void> saveTags(List<Tag> tags) async {
    final List<String> tagsJson =
        tags.map((tag) => jsonEncode(tag.toJson())).toList();
    await _prefs.setStringList(keyTags, tagsJson);
  }

  List<Tag> getTags() {
    final List<String>? tagsJson = _prefs.getStringList(keyTags);
    if (tagsJson == null) return [];
    return tagsJson.map((str) => Tag.fromJson(jsonDecode(str))).toList();
  }

  // --- Reminders ---
  Future<void> saveReminders(List<Reminder> reminders) async {
    final List<String> remindersJson =
        reminders.map((r) => jsonEncode(r.toJson())).toList();
    await _prefs.setStringList('reminders', remindersJson);
  }

  List<Reminder> getReminders() {
    final List<String>? remindersJson = _prefs.getStringList('reminders');
    if (remindersJson == null) return [];
    return remindersJson
        .map((str) => Reminder.fromJson(jsonDecode(str)))
        .toList();
  }

  Future<void> saveReminder(Reminder reminder) async {
    final List<Reminder> current = getReminders();
    final index = current.indexWhere((r) => r.id == reminder.id);
    if (index != -1) {
      current[index] = reminder;
    } else {
      current.add(reminder);
    }
    await saveReminders(current);
  }

  Future<void> deleteReminder(String id) async {
    final List<Reminder> current = getReminders();
    current.removeWhere((r) => r.id == id);
    await saveReminders(current);
  }

  // --- Theme ---
  final ValueNotifier<bool> themeNotifier =
      ValueNotifier<bool>(true); // Default dark

  bool get isDarkMode => _prefs.getBool('is_dark_mode') ?? true;

  Future<void> toggleTheme(bool isDark) async {
    themeNotifier.value = isDark;
    await _prefs.setBool('is_dark_mode', isDark);
  }

  // Load theme on startup
  void loadTheme() {
    themeNotifier.value = isDarkMode;
  }

  // --- Localization ---
  Future<void> saveLanguage(String language) async {
    await _prefs.setString('app_language', language);
  }

  String? getLanguage() {
    return _prefs.getString('app_language');
  }

  // --- Notifications ---
  Future<void> saveNotificationsEnabled(bool enabled) async {
    await _prefs.setBool('notifications_enabled', enabled);
  }

  bool getNotificationsEnabled() {
    return _prefs.getBool('notifications_enabled') ?? true;
  }
}
