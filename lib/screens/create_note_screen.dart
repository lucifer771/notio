import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:notio/models/note.dart';
import 'package:notio/screens/home_screen.dart'; // Using HomeScreen navigation if needed
import 'package:notio/services/storage_service.dart';
import 'package:uuid/uuid.dart';

class CreateNoteScreen extends StatefulWidget {
  final Note? note; // Optional: for editing existing note
  const CreateNoteScreen({super.key, this.note});

  @override
  State<CreateNoteScreen> createState() => _CreateNoteScreenState();
}

class _CreateNoteScreenState extends State<CreateNoteScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late DateTime _currentDate;

  // Note Properties
  bool _isPinned = false;
  bool _isLocked = false;
  List<String> _imagePaths = [];
  String? _voicePath;
  List<String> _tags = [];

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _currentDate = widget.note?.updatedAt ?? DateTime.now();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(
      text: widget.note?.content ?? '',
    );

    _isPinned = widget.note?.isPinned ?? false;
    _isLocked = widget.note?.isLocked ?? false;
    _imagePaths = List.from(widget.note?.imagePaths ?? []);
    _voicePath = widget.note?.voicePath;
    _tags = List.from(widget.note?.tags ?? []);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _saveNote() {
    // If empty, don't save unless it's an update (maybe user deleted logic)
    // For now, if both empty, discard new note.
    if (_titleController.text.isEmpty &&
        _contentController.text.isEmpty &&
        widget.note == null) {
      Navigator.pop(context);
      return;
    }

    final newNote = Note(
      id: widget.note?.id ?? const Uuid().v4(),
      title: _titleController.text,
      content: _contentController.text,
      createdAt: widget.note?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(), // update time
      tags: _tags,
      isPinned: _isPinned,
      isLocked: _isLocked,
      imagePaths: _imagePaths,
      voicePath: _voicePath,
    );

    // Save using persistent storage (mocked or real)
    // Assuming HomeScreen handles the saving upon return for now, OR we save directly here.
    // The previous implementation returned the note.
    StorageService().saveNote(newNote); // Direct save for real-time feel

    Navigator.pop(context, newNote);
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _imagePaths.add(image.path);
      });
    }
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
                    // Open Tag selector (simplified for now)
                  }),
                  _buildOptionTile(
                    _isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                    _isPinned ? 'Unpin Note' : 'Pin Note',
                    () {
                      setState(() => _isPinned = !_isPinned);
                      setModalState(() {}); // Update sheet UI
                      // Also update main screen
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
                    // Delete logic
                    if (widget.note != null) {
                      StorageService().deleteNote(widget.note!.id);
                    }
                    Navigator.pop(context); // Close sheet
                    Navigator.pop(context); // Close screen
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
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21), // Deep dark background
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
          // Status Icons
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
                backgroundColor: const Color(0xFF6C63FF).withOpacity(0.1),
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
                    // Magic AI feature (placeholder)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('AI Magic coming soon!')),
                    );
                  }, color: const Color(0xFFFFD700)),
                  _buildToolbarIcon(Icons.image_outlined, _pickImage),
                  _buildToolbarIcon(Icons.local_offer_outlined, () {}),
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
