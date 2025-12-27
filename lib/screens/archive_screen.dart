import 'package:flutter/material.dart';
import 'package:notio/models/note.dart';
import 'package:notio/services/storage_service.dart';
import 'package:notio/widgets/note_card.dart';
import 'package:notio/utils/translations.dart';

class ArchiveScreen extends StatefulWidget {
  const ArchiveScreen({super.key});

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
  List<Note> _archivedNotes = [];

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  void _loadNotes() {
    setState(() {
      _archivedNotes = StorageService().getArchivedNotes();
    });
  }

  Future<void> _unarchiveNote(String id) async {
    await StorageService().unarchiveNote(id);
    _loadNotes();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('note_unarchived'.tr)), // Need this key
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Basic theme awareness

    return Scaffold(
      appBar: AppBar(
        title: Text('archived_notes'.tr),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
          child: _archivedNotes.isEmpty
              ? Center(
                  child: Text(
                    'no_archived_notes'.tr, // Need key
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _archivedNotes.length,
                  itemBuilder: (context, index) {
                    final note = _archivedNotes[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Dismissible(
                        key: Key(note.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.orange,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child:
                              const Icon(Icons.unarchive, color: Colors.white),
                        ),
                        onDismissed: (_) => _unarchiveNote(note.id),
                        child: NoteCard(
                          title: note.title.isEmpty ? 'Untitled' : note.title,
                          content: note.content,
                          date: '${note.createdAt.day}/${note.createdAt.month}',
                          onTap: () {
                            // View only or restore? For now just show "Unarchive to edit"
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Unarchive to edit")),
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
