import 'package:notio/models/note.dart';
import 'package:collection/collection.dart';

abstract class NotesRepository {
  Future<List<Note>> getNotes();
  Future<Note?> getNoteById(String id);
  Future<void> saveNote(Note note);
  Future<bool> deleteNote(String id); // Changed return type to indicate success
  Future<List<Note>> searchNotes(String query);
  Future<List<Note>> getNotesByFolder(String folderId);
  // Add more methods for tags, archiving, etc.
}

// In-memory implementation of NotesRepository for demonstration
class LocalNotesRepository implements NotesRepository {
  // This is a simple in-memory list to simulate a database.
  // In a real app, you would use a persistent storage solution like Hive or sqflite.
  static final List<Note> _notes = [];

  @override
  Future<List<Note>> getNotes() async {
    // Simulate a network/database delay
    await Future.delayed(const Duration(milliseconds: 200));
    return List.from(_notes); // Return a copy to prevent external modification
  }

  @override
  Future<Note?> getNoteById(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    // The correct way
    return _notes.firstWhereOrNull((note) => note.id == id);
  }

  @override
  Future<void> saveNote(Note note) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final index = _notes.indexWhere((n) => n.id == note.id);
    if (index != -1) {
      _notes[index] = note; // Update existing note
    } else {
      _notes.add(note); // Add new note
    }
  }

  @override
  Future<bool> deleteNote(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final initialLength = _notes.length;
    _notes.removeWhere((note) => note.id == id);
    return _notes.length < initialLength; // True if a note was removed
  }

  @override
  Future<List<Note>> searchNotes(String query) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final lowerCaseQuery = query.toLowerCase();
    return _notes
        .where(
          (note) =>
              note.title.toLowerCase().contains(lowerCaseQuery) ||
              note.content.toLowerCase().contains(lowerCaseQuery),
        )
        .toList();
  }

  @override
  Future<List<Note>> getNotesByFolder(String folderId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _notes.where((note) => note.folderId == folderId).toList();
  }
}
