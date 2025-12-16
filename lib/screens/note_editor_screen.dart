import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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

  // New V2 Fields
  bool _isPinned = false;
  bool _isLocked = false;
  List<String> _imagePaths = [];
  String? _voicePath;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(
      text: widget.note?.content ?? '',
    );
    _selectedTagIds = List.from(widget.note?.tags ?? []);
    _currentDate = widget.note?.updatedAt ?? DateTime.now();

    _isPinned = widget.note?.isPinned ?? false;
    _isLocked = widget.note?.isLocked ?? false;
    _imagePaths = List.from(widget.note?.imagePaths ?? []);
    _voicePath = widget.note?.voicePath;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // No need for explicit dirty check if we save on exit/done always,
  // but let's keep the logic simple: Save on "Done" or Back.

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
      isPinned: _isPinned,
      isLocked: _isLocked,
      imagePaths: _imagePaths,
      voicePath: _voicePath,
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

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _imagePaths.add(image.path);
      });
    }
  }

  void _showTagSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: TagSelector(
          availableTags: widget.availableTags,
          selectedTagIds: _selectedTagIds,
          onSelectionChanged: (ids) {
            setState(() {
              _selectedTagIds = ids;
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
            });
          },
        ),
      ),
    );
  }

  void _showNoteOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E), // Dark theme
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Note Options',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildOptionTile(Icons.label_outline, 'Add Tag', () {
                    Navigator.pop(context);
                    _showTagSelector();
                  }),
                  _buildOptionTile(
                    _isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                    _isPinned ? 'Unpin Note' : 'Pin Note',
                    () {
                      setState(() => _isPinned = !_isPinned);
                      setModalState(() {});
                    },
                    isActive: _isPinned,
                  ),
                  _buildOptionTile(
                    _isLocked ? Icons.lock : Icons.lock_open,
                    _isLocked ? 'Unlock Note' : 'Lock Note',
                    () {
                      setState(() => _isLocked = !_isLocked);
                      setModalState(() {});
                    },
                    isActive: _isLocked,
                  ),
                  _buildOptionTile(Icons.image_outlined, 'Add Image', () {
                    Navigator.pop(context);
                    _pickImage();
                  }),
                  _buildOptionTile(Icons.mic_none, 'Add Voice Memo', () {}),
                  _buildOptionTile(Icons.share_outlined, 'Export', () {}),
                  _buildOptionTile(Icons.delete_outline, 'Delete', () {
                    Navigator.pop(context);
                    _deleteNote();
                  }, color: Colors.redAccent),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildOptionTile(
    IconData icon,
    String title,
    VoidCallback onTap, {
    Color? color,
    bool isActive = false,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF6C63FF).withOpacity(0.2)
              : Colors.grey[900],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: color ?? (isActive ? const Color(0xFF6C63FF) : Colors.white),
        ),
      ),
      title: Text(
        title,
        style: TextStyle(color: color ?? Colors.white, fontSize: 16),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Tags for display
    final displayedTags = widget.availableTags
        .where((tag) => _selectedTagIds.contains(tag.id))
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: _saveNote,
        ),
        actions: [
          if (_isPinned)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.push_pin, color: Color(0xFF6C63FF), size: 20),
            ),
          if (_isLocked)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.lock, color: Color(0xFF6C63FF), size: 20),
            ),

          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton(
              onPressed: _saveNote,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF6C63FF),
                backgroundColor: const Color(0xFF6C63FF).withValues(alpha: 0.1),
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
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tags Row
                    if (displayedTags.isNotEmpty)
                      Container(
                        height: 40,
                        margin: const EdgeInsets.only(bottom: 16),
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
                                  fontSize: 12,
                                ),
                              ),
                              backgroundColor: Color(
                                tag.color,
                              ).withValues(alpha: 0.15),
                              side: BorderSide.none,
                              padding: const EdgeInsets.all(0),
                              deleteIcon: Icon(
                                Icons.close,
                                size: 14,
                                color: Color(tag.color),
                              ),
                              onDeleted: () => setState(
                                () => _selectedTagIds.remove(tag.id),
                              ),
                            );
                          },
                        ),
                      ),

                    TextField(
                      controller: _titleController,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Title',
                        hintStyle: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                        border: InputBorder.none,
                      ),
                      maxLines: null,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_currentDate.day}/${_currentDate.month}/${_currentDate.year}  ${_currentDate.hour}:${_currentDate.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    const SizedBox(height: 16),

                    // Image Attachments
                    if (_imagePaths.isNotEmpty)
                      SizedBox(
                        height: 150,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _imagePaths.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                File(_imagePaths[index]),
                                height: 150,
                                width: 150,
                                fit: BoxFit.cover,
                              ),
                            );
                          },
                        ),
                      ),
                    if (_imagePaths.isNotEmpty) const SizedBox(height: 16),

                    TextField(
                      controller: _contentController,
                      style: TextStyle(
                        color: Colors.grey[300],
                        fontSize: 16,
                        height: 1.5,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Start writing...',
                        hintStyle: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 16,
                        ),
                        border: InputBorder.none,
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Toolbar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF161622),
                border: Border(
                  top: BorderSide(color: Colors.white.withOpacity(0.05)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildToolbarIcon(Icons.mic_none, () {}),
                  _buildToolbarIcon(Icons.auto_awesome, () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('AI Magic coming soon!')),
                    );
                  }, color: const Color(0xFFFFD700)),
                  _buildToolbarIcon(Icons.image_outlined, _pickImage),
                  _buildToolbarIcon(
                    Icons.local_offer_outlined,
                    _showTagSelector,
                  ),
                  _buildToolbarIcon(Icons.more_horiz, _showNoteOptions),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbarIcon(IconData icon, VoidCallback onTap, {Color? color}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF252538),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(icon, color: color ?? const Color(0xFF6C63FF), size: 24),
      ),
    );
  }
}
