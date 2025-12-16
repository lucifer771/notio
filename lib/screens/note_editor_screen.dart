import 'package:flutter/material.dart';
import 'package:notio/models/note.dart';
import 'package:notio/models/tag.dart';
import 'package:notio/widgets/tag_selector.dart';
import 'package:uuid/uuid.dart';

class NoteEditorScreen extends StatefulWidget {
  final Note? note;
  final List<Tag> availableTags;
  final Function(Tag) onTagCreated;

  const NoteEditorScreen({
    super.key,
    this.note,
    required this.availableTags,
    required this.onTagCreated,
  });

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late List<String> _selectedTagIds;
  late DateTime _currentDate;
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(
      text: widget.note?.content ?? '',
    );
    _selectedTagIds = List.from(widget.note?.tags ?? []);
    _currentDate = widget.note?.updatedAt ?? DateTime.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _markAsDirty() {
    if (!_isDirty) {
      setState(() {
        _isDirty = true;
      });
    }
  }

  void _saveNote() {
    if (_titleController.text.isEmpty && _contentController.text.isEmpty) {
      Navigator.pop(context);
      return;
    }

    final now = DateTime.now();
    final note = Note(
      id: widget.note?.id ?? const Uuid().v4(),
      title: _titleController.text,
      content: _contentController.text,
      createdAt: widget.note?.createdAt ?? now,
      updatedAt: now,
      tags: _selectedTagIds,
      type: widget.note?.type ?? NoteType.text,
    );

    Navigator.pop(context, note);
  }

  Future<void> _deleteNote() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          'Delete Note?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This action cannot be undone.',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      Navigator.pop(context, 'DELETE_NOTE');
    }
  }

  void _showTagSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => TagSelector(
        availableTags: widget.availableTags,
        selectedTagIds: _selectedTagIds,
        onSelectionChanged: (ids) {
          setState(() {
            _selectedTagIds = ids;
            _isDirty = true;
          });
        },
        onTagCreated: (name, color) {
          final newTag = Tag(
            id: const Uuid().v4(),
            name: name,
            noteCount: 0,
            color: color,
          );
          widget.onTagCreated(newTag);
          setState(() {
            _selectedTagIds.add(newTag.id);
            _isDirty = true;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine tags to map IDs locally for display
    final displayedTags = widget.availableTags
        .where((tag) => _selectedTagIds.contains(tag.id))
        .toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: _saveNote,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.local_offer_outlined),
            onPressed: _showTagSelector,
            tooltip: 'Add Tags',
          ),
          if (widget.note != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: _deleteNote,
            ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton(
              onPressed: _saveNote,
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                'Done',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (displayedTags.isNotEmpty)
              Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: displayedTags.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final tag = displayedTags[index];
                    return Chip(
                      label: Text(
                        tag.name,
                        style: TextStyle(
                          color: Color(tag.color),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      backgroundColor: Color(tag.color).withValues(alpha: 0.15),
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      deleteIcon: Icon(
                        Icons.close,
                        size: 14,
                        color: Color(tag.color),
                      ),
                      onDeleted: () {
                        setState(() {
                          _selectedTagIds.remove(tag.id);
                        });
                      },
                    );
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TextField(
                controller: _titleController,
                onChanged: (_) => _markAsDirty(),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                decoration: InputDecoration(
                  hintText: 'Title',
                  hintStyle: Theme.of(context).textTheme.headlineMedium
                      ?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                  border: InputBorder.none,
                ),
                maxLines: 1,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                '${_currentDate.day}/${_currentDate.month}/${_currentDate.year}  ${_currentDate.hour}:${_currentDate.minute.toString().padLeft(2, '0')}  |  ${_contentController.text.length} characters',
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(color: Colors.grey[600]),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: TextField(
                  controller: _contentController,
                  onChanged: (_) => setState(() {}), // rebuild for char count
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[300],
                    height: 1.5,
                    fontSize: 18,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Start writing...',
                    hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[700],
                      fontSize: 18,
                    ),
                    border: InputBorder.none,
                  ),
                  maxLines: null,
                  expands: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
