import 'package:flutter/material.dart';
import 'package:notio/models/note.dart';

class NoteEditScreen extends StatefulWidget {
  final Note? note; // Optional: if editing an existing note

  const NoteEditScreen({super.key, this.note});

  @override
  State<NoteEditScreen> createState() => _NoteEditScreenState();
}

class _NoteEditScreenState extends State<NoteEditScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    if (widget.note != null) {
      _titleController.text = widget.note!.title;
      _contentController.text = widget.note!.content;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _saveNote() {
    if (_formKey.currentState!.validate()) {
      final String id =
          widget.note?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
      final DateTime now = DateTime.now();

      final Note newOrUpdatedNote = Note(
        id: id,
        title: _titleController.text,
        content: _contentController.text,
        createdAt:
            widget.note?.createdAt ??
            now, // Keep original creation date if editing
        updatedAt: now,
        type: NoteType.text, // Default to text for now
      );

      Navigator.of(context).pop(newOrUpdatedNote);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.note == null ? 'Create New Note' : 'Edit Note'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _saveNote),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: 'Note Title',
                  border: InputBorder.none,
                ),
                style: Theme.of(context).textTheme.headlineSmall,
                validator: (value) =>
                    value!.isEmpty ? 'Title cannot be empty' : null,
              ),
              Expanded(
                child: TextFormField(
                  controller: _contentController,
                  decoration: const InputDecoration(
                    hintText: 'Note Content',
                    border: InputBorder.none,
                  ),
                  maxLines: null, // Allows for multiline input
                  expands:
                      true, // Allows the field to expand to fill available space
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
