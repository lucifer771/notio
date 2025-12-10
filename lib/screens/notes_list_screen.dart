import 'package:flutter/material.dart';
import 'package:notio/models/note.dart';
import 'package:notio/notes_repository.dart';
import 'package:notio/screens/note_edit_screen.dart';
// Assume you have a state management solution like Provider or BLoC
// import 'package:provider/provider.dart';
// import 'package:notio/providers/notes_provider.dart'; // Or BLoC

class NotesListScreen extends StatefulWidget {
  const NotesListScreen({super.key});

  @override
  State<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends State<NotesListScreen> {
  final NotesRepository _notesRepository =
      LocalNotesRepository(); // Using the in-memory repository
  List<Note> _notes = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    setState(() => _isLoading = true);
    _notes = await _notesRepository.getNotes();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    // In a real app, you'd use a state management solution here (e.g., Provider, BLoC)
    // to manage _notes and _isLoading, and react to changes.

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Notes'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Implement search functionality
            },
          ),
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () {
              // Implement sorting options
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notes.isEmpty
          ? const Center(child: Text('No notes yet! Tap + to add one!'))
          : ListView.builder(
              itemCount: _notes.length,
              itemBuilder: (context, index) {
                final note = _notes[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: ListTile(
                    title: Text(note.title),
                    subtitle: Text(
                      note.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () async {
                      // Navigate to note editing screen
                      final updatedNote = await Navigator.of(context)
                          .push<Note>(
                            MaterialPageRoute(
                              builder: (_) => NoteEditScreen(note: note),
                            ),
                          );
                      if (updatedNote != null) {
                        await _notesRepository.saveNote(updatedNote);
                        _loadNotes(); // Reload notes to update UI
                      }
                    },
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () async {
                        final bool? confirmDelete = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Note'),
                            content: const Text(
                              'Are you sure you want to delete this note?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                        if (confirmDelete == true) {
                          await _notesRepository.deleteNote(note.id);
                          _loadNotes(); // Reload notes to update UI
                        }
                      },
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Marked as async
          // Navigate to a new note creation screen
          final newNote = await Navigator.of(context).push<Note>(
            MaterialPageRoute(builder: (_) => const NoteEditScreen()),
          );
          if (newNote != null) {
            await _notesRepository.saveNote(newNote);
            _loadNotes(); // Reload notes to update UI
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
