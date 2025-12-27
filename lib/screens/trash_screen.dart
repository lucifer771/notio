import 'package:flutter/material.dart';
import 'package:notio/models/note.dart';
import 'package:notio/services/storage_service.dart';
import 'package:notio/widgets/note_card.dart';
import 'package:notio/utils/translations.dart';

class TrashScreen extends StatefulWidget {
  const TrashScreen({super.key});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  List<Note> _trashedNotes = [];

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  void _loadNotes() {
    setState(() {
      _trashedNotes = StorageService().getTrashedNotes();
    });
  }

  Future<void> _restoreNote(String id) async {
    await StorageService().restoreNote(id);
    _loadNotes();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('note_restored'.tr)),
      );
    }
  }

  Future<void> _deletePermanently(String id) async {
    await StorageService().deleteNotePermanently(id);
    _loadNotes();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('note_deleted_permanently'.tr)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('trash'.tr),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: () {
              // Implement "Empty Trash" if desired
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Long press to delete permanently')),
              );
            },
          )
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).scaffoldBackgroundColor,
              const Color(0xFF0F0F1A),
            ],
          ),
        ),
        child: SafeArea(
          child: _trashedNotes.isEmpty
              ? Center(
                  child: Text(
                    'trash_empty'.tr,
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _trashedNotes.length,
                  itemBuilder: (context, index) {
                    final note = _trashedNotes[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Dismissible(
                        key: Key(note.id),
                        direction: DismissDirection.horizontal,
                        background: Container(
                          color: Colors.green,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(left: 20),
                          child: const Icon(Icons.restore, color: Colors.white),
                        ),
                        secondaryBackground: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete_forever,
                              color: Colors.white),
                        ),
                        confirmDismiss: (direction) async {
                          if (direction == DismissDirection.endToStart) {
                            // Delete Permanently confirmation?
                            return true; // Just do it for now
                          } else {
                            // Restore
                            return true;
                          }
                        },
                        onDismissed: (direction) {
                          if (direction == DismissDirection.endToStart) {
                            _deletePermanently(note.id);
                          } else {
                            _restoreNote(note.id);
                          }
                        },
                        child: NoteCard(
                          title: note.title.isEmpty ? 'Untitled' : note.title,
                          content: note.content,
                          date: '${note.createdAt.day}/${note.createdAt.month}',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("Restore to view/edit")),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
